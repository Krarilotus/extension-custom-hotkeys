local ffi=require('ffi')
local M={}
function M.new(scene,resolve,pointer)
  local mouse=ffi.cast('uint8_t *',0xf2c9b0)
  local raw=ffi.cast('int16_t *',mouse+0x1f4)
  local native=ffi.cast('void (__thiscall *)(void *, short, short, int)',0x468030)
  local reset=ffi.cast('void (__thiscall *)(void *)',0x4689d0)
  local codes={left={1,2},right={3,4}}
  local adapter={}
  function adapter.resolve() return resolve() end
  function adapter.position() return tonumber(raw[0]),tonumber(raw[1]) end
  function adapter.bounds()
    local s=scene:snapshot();return s.width,s.height
  end
  function adapter.busy()
    return mouse[0x1fa]~=0 or ffi.cast('int32_t *',mouse+0x40)[0]~=0
      or ffi.cast('int32_t *',mouse+0x44)[0]~=0 or ffi.cast('int32_t *',mouse+0x48)[0]~=0
      or ffi.cast('int32_t *',mouse+0x1d8)[0]~=0
  end
  function adapter.move(x,y)
    local ok,gx,gy=pointer:move(x,y)
    if not ok then return false end
    -- Use the native input boundary immediately as well as the queued normal
    -- pointer message, so a fast confirm observes the same reachable pixel.
    native(mouse,gx,gy,0)
    return true
  end
  function adapter.button(button,down) native(mouse,raw[0],raw[1],codes[button][down and 1 or 2]) end
  function adapter.cancel()
    local pending=ffi.cast('int32_t *',mouse+0x1d8)[0]~=0
    reset(mouse)
    -- The first reset only clears a pending-reset marker when it was set.
    if pending then reset(mouse) end
  end
  return adapter
end
return M
