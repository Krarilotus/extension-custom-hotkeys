-- One writer in the interactive Windows session. Files remain owned by UCP IO.
local ffi=require('ffi')
ffi.cdef[[
void * __stdcall CreateMutexW(void *, int, const wchar_t *);
unsigned long __stdcall GetLastError(void);
int __stdcall CloseHandle(void *);
]]
local kernel=ffi.load('kernel32')
local M={}
function M.acquire()
  -- Deliberately excludes all simultaneous Custom Hotkeys profile writers in
  -- this session, even from different installs. No path aliases can evade it.
  local name='Local\\UCP.CustomHotkeys.ProfileWriter.v1'
  local wide=ffi.new('wchar_t[?]',#name+1)
  for i=1,#name do wide[i-1]=name:byte(i) end
  local handle=kernel.CreateMutexW(nil,0,wide)
  local status=kernel.GetLastError()
  if handle==nil then return nil,'store.lock-unavailable' end
  if status==183 then kernel.CloseHandle(handle);return nil,'store.already-open' end
  -- Keep this handle for the module/process lifetime, including failed writes.
  return ffi.gc(handle,kernel.CloseHandle)
end
return M
