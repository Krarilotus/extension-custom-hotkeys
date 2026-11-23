local ffi = require('ffi')
local jit = require('jit')
local Messages = require('code/messages')
local Mouse = require('code/mouse_messages')
local Binding = require('code/binding')
local M = {}
local installed

-- The supported winProcHandler ABI is x86 stdcall. Keep this callback and its
-- private LuaJIT state alive until process exit: the owner has no unregister API.
local signature = 'int32_t (__stdcall *)(int32_t, void *, uint32_t, uint32_t, int32_t)'

function M.install(interface, router, platform, exclusiveInput, mouseInput, isReady)
  assert(not installed, 'chain.already-installed')
  assert(ffi.os == 'Windows' and ffi.arch == 'x86', 'chain.unsupported-abi')
  assert(type(interface) == 'table', 'chain.interface-required')
  for _, name in ipairs({'RegisterProc','CallNextProc'}) do
    local address=interface[name]
    assert(type(address)=='number' and address>0 and address<4294967296
      and address==math.floor(address), 'chain.invalid-address')
  end
  -- Native dispatch can synchronously re-enter Lua through menu callbacks.
  -- This adapter runs in its own state with tracing disabled, avoiding a
  -- callback into compiled LuaJIT code. Measure this native path separately.
  jit.off()
  local nextProc = ffi.cast(signature, interface.CallNextProc)
  local register = ffi.cast('int32_t (__stdcall *)(void *, int32_t)', interface.RegisterProc)
  local result = {router=router, platform=platform}
  local handle = Messages.new(router, function(priority, hwnd, message, wparam, lparam)
    return nextProc(priority, ffi.cast('void *',hwnd), message, wparam, lparam)
  end, function()
    return platform:modifiers()
  end,
  function(hwnd) return platform:owns(hwnd) end, exclusiveInput)
  -- Keep one protected observer instead of allocating a closure per message.
  local function observe(message,wparam,lparam)
    if platform:observe(message) then router:barrier() end
    if mouseInput and message>=0x200 and message<=0x20e then
      local button,kind=Mouse.decode(message,wparam)
      local held=kind=='up' and router.held[Binding.buttons[button]]
      -- A consumed shortcut release, or a further notch of a consumed wheel
      -- gesture, belongs to the router. Treating it as native pointer
      -- takeover aborts the quickslot gesture it just started.
      local continues=message==0x20a and router:ownsWheel(Mouse.wheel(wparam,platform:modifiers().mods))
      if not (held and held.consumed and not held.forwarded) and not continues then
        mouseInput(message,wparam,lparam)
      end
    end
  end
  result.callback = ffi.cast(signature, function(priority, hwnd, message, wparam, lparam)
    -- HWNDs are numeric keys here; separately boxed pointer cdata must not
    -- split gesture debt into a different Lua table on every callback.
    local window = tonumber(ffi.cast('uintptr_t',hwnd))
    if not result.failure and isReady() and platform:owns(window) then
      local ok, err = pcall(observe,message,wparam,lparam)
      if not ok then
        result.failure=tostring(err)
        router:block('window observation',err)
        pcall(router.barrier,router)
      end
    end
    if result.failure or not isReady() then
      local ok,value=pcall(nextProc,priority,hwnd,message,wparam,lparam)
      return ok and value or 0
    end
    -- No Lua error may escape the C callback. An uncertain downstream failure
    -- is consumed once, never retried through another native handler.
    local ok, value = pcall(handle,priority,window,message,wparam,lparam)
    if ok then return value end
    result.failure=tostring(value)
    router:block('window dispatch',value)
    pcall(router.barrier,router)
    return 0
  end)
  -- Observe focus cancellation before graphicsApiReplacer (-100000), which
  -- can consume WM_KILLFOCUS/WM_SETFOCUS/WM_ACTIVATEAPP. Remapped mouse buttons
  -- retain the original coordinates for its normal conversion. Forward the
  -- actual collision-resolved priority.
  result.priority = tonumber(register(result.callback,-110000))
  assert(result.priority ~= -2147483648, 'chain.registration-failed')
  -- A pathological occupied range must not silently put cancellation after
  -- the graphics owner. The callback remains pinned even on rejected setup.
  installed=result
  if result.priority >= -100000 then
    result.failure='chain.priority-unavailable'
    router:block('window registration',result.failure)
    error(result.failure)
  end
  return result
end

return M
