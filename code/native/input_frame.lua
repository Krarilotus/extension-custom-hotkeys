local ffi=require('ffi')
local M={}
local installed
function M.install(cursor,router)
  assert(not installed,'input-frame.installed')
  local result={}
  result.callback=ffi.cast('void (__cdecl *)(void *)',function(mouse)
    if tonumber(ffi.cast('uintptr_t',mouse))~=0xf2c9b0 or not cursor.pending then return end
    local ok,err=pcall(cursor.beforeFrame,cursor)
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
