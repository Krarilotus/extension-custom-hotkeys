local A=require('code/addresses')
local ffi=require('ffi')
local Context=require('code/context')
local M={}
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local lower=ffi.cast('void (__thiscall *)(void *,int)',A.lowerBuildings)
function M.new(scene,view,platform,router)
  return require('code/lowering').new({
    resolve=function() return scene:resolve(view) end,
    available=function()
      local units=read(A.units)
      return read(A.mouseRightHeld)==0 and read(A.lowerHeld)==0
        and units>=1 and units<=2500
    end,
    setV=function(value) ffi.cast('int32_t *',A.lowerHeld)[0]=value and 1 or 0 end,
    lower=function(mode) lower(ffi.cast('void *',A.buildingView),mode) end,
    nativeVHeld=function(context)
      if not Context.same(context,router:readContext()) then return false end
      local held=router.held[47]
      return held and not held.consumed and not held.blocked and platform:keyDown(0x56)
    end,
    otherNativeHold=function(context)
      if not Context.same(context,router:readContext()) then return false end
      -- Preserve the original right-mouse/Ctrl+Down restore exclusions only
      -- while their input still belongs to this active world. Stale raw flags
      -- after focus loss or a modal transition cannot retain our lowered view.
      if read(A.mouseRightHeld)~=0 then return true end
      for _,scan in ipairs({80,208}) do
        local held=router.held[scan]
        if held and not held.consumed and not held.blocked
            and read(A.controlHeld)~=0 and read(A.downHeld)~=0
            and platform:keyDown(0x11) and platform:keyDown(0x28) then return true end
      end
      return false
    end,
  })
end
return M
