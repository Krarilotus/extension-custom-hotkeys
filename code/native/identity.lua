-- Identify the running image before any version-specific address is read.
local ffi=require('ffi')
ffi.cdef[[
  void * __stdcall GetModuleHandleW(const wchar_t *);
  unsigned long __stdcall GetModuleFileNameW(void *, wchar_t *, unsigned long);
  unsigned long __stdcall GetCurrentDirectoryW(unsigned long, wchar_t *);
  int __stdcall CompareStringOrdinal(const wchar_t *, int, const wchar_t *, int, int);
  int __stdcall WideCharToMultiByte(unsigned int, unsigned long, const wchar_t *,
    int, char *, int, const char *, int *);
]]
local kernel=ffi.load('kernel32')
local M={}
function M.file()
  assert(ffi.os=='Windows' and ffi.arch=='x86','executable.abi')
  local module=kernel.GetModuleHandleW(nil)
  assert(tonumber(ffi.cast('uintptr_t',module))==0x400000,'executable.base')
  local path,dir=ffi.new('wchar_t[32768]'),ffi.new('wchar_t[32768]')
  local length=tonumber(kernel.GetModuleFileNameW(module,path,32768))
  local cwd=tonumber(kernel.GetCurrentDirectoryW(32768,dir))
  assert(length>0 and length<32768 and cwd>0 and cwd<32768,'executable.path')
  local slash=length-1
  while slash>=0 and path[slash]~=92 do slash=slash-1 end
  assert(slash==cwd and kernel.CompareStringOrdinal(path,slash,dir,cwd,1)==2,
    'executable.directory')
  local name=ffi.new('char[1024]')
  local bytes=kernel.WideCharToMultiByte(65001,0,path+slash+1,length-slash-1,name,1024,nil,nil)
  assert(bytes>0,'executable.name')
  return ffi.string(name,bytes)
end
return M
