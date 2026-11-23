-- Replaces a file by a staged copy in one rename on the same volume, so the
-- target is never missing. Paths resolve like the framework's fopen.
local ffi=require('ffi')
ffi.cdef[[
int __stdcall MoveFileExA(const char *, const char *, unsigned long);
int __stdcall DeleteFileA(const char *);
]]
local kernel=ffi.load('kernel32')
local REPLACE_EXISTING,WRITE_THROUGH=1,8
return function(staged,target)
  if kernel.MoveFileExA(staged,target,REPLACE_EXISTING+WRITE_THROUGH)~=0 then return true end
  kernel.DeleteFileA(staged)
  return nil,'config.write'
end
