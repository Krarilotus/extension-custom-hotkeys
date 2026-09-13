local A=require('code/addresses')
local ffi=require('ffi')
local Context=require('code/context')
local fields={right=A.panRight,left=A.panLeft,down=A.panDown,up=A.panUp}
local keys={right={0x27,77},left={0x25,75},down={0x28,80},up={0x26,72}}
local M={}
function M.new(platform,router)
  return require('code/camera').new({set=function(direction,down)
    -- Same local held-input fields written by the native arrow-key branches.
    -- ScrollingHandler retains speed, edge/bounds and viewport behavior.
    ffi.cast('int32_t *',assert(fields[direction]))[0]=down and 1 or 0
  end,nativeHeld=function(direction,context)
    if not Context.same(context,router:readContext()) then return false end
    local key=keys[direction]
    -- Both E0 arrows and NumLock-off keypad arrows can own the original flag.
    -- A consumed/reassigned/quarantined gesture cannot retain native ownership.
    for _,scan in ipairs({key[2],key[2]+128}) do
      local held=router.held[scan]
      if held and not held.consumed and not held.blocked and platform:keyDown(key[1]) then return true end
    end
    return false
  end})
end
return M
