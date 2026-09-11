local ffi=require('ffi')
local M={}
local installed
function M.install(cursor,router,camera,quicksave)
  assert(not installed,'input-frame.installed')
  local result={}
  local nativeMouse=ffi.cast('void *',0xf2c9b0)
  local function advance()
    if camera.count>0 then camera:beforeFrame(router:refresh()) end
    if quicksave and quicksave.active then quicksave:beforeFrame() end
    if cursor.pending then cursor:beforeFrame() end
  end
  result.callback=ffi.cast('void (__cdecl *)(void *)',function(mouse)
    if (not cursor.pending and camera.count==0 and not (quicksave and quicksave.active)) or mouse~=nativeMouse then return end
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
