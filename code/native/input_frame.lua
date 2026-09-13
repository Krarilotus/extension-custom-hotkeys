local A=require('code/addresses')
local ffi=require('ffi')
local M={}
local installed
function M.install(cursor,router,camera,quickslot,lowering,navigation,worldActions)
  assert(not installed,'input-frame.installed')
  local result={}
  local nativeMouse=ffi.cast('void *',A.mouseState)
  local function advance()
    if worldActions and worldActions.hasBookmarks then worldActions:observeLifetime() end
    if navigation and navigation.pending then navigation:beforeFrame() end
    if camera.count>0 or (lowering and lowering.active) or router.pointerHolds>0 then
      local context=router:refresh()
      if camera.count>0 then camera:beforeFrame(context) end
      if lowering and lowering.active then lowering:beforeFrame(context) end
    end
    if quickslot and quickslot.active then quickslot:beforeFrame() end
    if cursor.pending then cursor:beforeFrame() end
  end
  result.callback=ffi.cast('void (__cdecl *)(void *)',function(mouse)
    if (not cursor.pending and camera.count==0 and not (quickslot and quickslot.active)
        and not (lowering and lowering.active) and not (navigation and navigation.pending)
        and not (worldActions and worldActions.hasBookmarks) and router.pointerHolds==0) or mouse~=nativeMouse then return end
    local ok,err=pcall(advance)
    if not ok then
      result.failure=tostring(err);router.blocked=true
      pcall(cursor.cancel,cursor);pcall(router.barrier,router)
    end
  end)
  -- Pin before patching even if the external patch API reports failure.
  installed=result
  result.address=remote.interface.installInputFrame(tonumber(ffi.cast('uintptr_t',result.callback)))
  return result
end
return M
