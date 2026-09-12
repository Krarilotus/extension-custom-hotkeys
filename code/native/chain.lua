local ffi = require('ffi')
local jit = require('jit')
local Messages = require('code/messages')
local M = {}
local installed

-- The supported winProcHandler ABI is x86 stdcall. Keep this callback and its
-- private LuaJIT state alive until process exit: the owner has no unregister API.
local signature = 'int32_t (__stdcall *)(int32_t, void *, uint32_t, uint32_t, int32_t)'

function M.install(interface, router, platform, exclusiveInput, mouseInput)
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
    assert(not result.failure, 'chain.failed')
    return platform:modifiers()
  end,
  function(hwnd) return platform:owns(hwnd) end, exclusiveInput)
  -- Keep one protected observer instead of allocating a closure per message.
  local function observe(message,wparam,lparam)
    if platform:observe(message) then router:barrier() end
    -- Real mouse input takes ownership before the native handler sees it.
    if mouseInput and message>=0x200 and message<=0x20e then mouseInput(message,wparam,lparam) end
  end
  result.callback = ffi.cast(signature, function(priority, hwnd, message, wparam, lparam)
    -- HWNDs are numeric keys here; separately boxed pointer cdata must not
    -- split gesture debt into a different Lua table on every callback.
    local window = tonumber(ffi.cast('uintptr_t',hwnd))
    if platform:owns(window) then
      local ok, err = pcall(observe,message,wparam,lparam)
      if not ok then result.failure=tostring(err); router.blocked=true end
    end
    -- No Lua error may escape the C callback. An uncertain downstream failure
    -- is consumed once, never retried through another native handler.
    local ok, value = pcall(handle,priority,window,message,wparam,lparam)
    if ok then return value end
    result.failure=tostring(value)
    router.blocked=true
    pcall(router.barrier,router)
    return 0
  end)
  -- Observe focus cancellation before graphicsApiReplacer (-100000), which
  -- can consume WM_KILLFOCUS/WM_SETFOCUS/WM_ACTIVATEAPP. Mouse messages pass
  -- unchanged to its normal coordinate conversion; this adapter never uses
  -- their coordinates. Forward the actual collision-resolved priority.
  result.priority = tonumber(register(result.callback,-110000))
  assert(result.priority ~= -2147483648, 'chain.registration-failed')
  -- A pathological occupied range must not silently put cancellation after
  -- the graphics owner. The callback remains pinned even on rejected setup.
  installed=result
  if result.priority >= -100000 then
    router.blocked=true
    result.failure='chain.priority-unavailable'
    error(result.failure)
  end
  return result
end

return M
