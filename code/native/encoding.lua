local ffi=require('ffi')
ffi.cdef[[
int __stdcall MultiByteToWideChar(unsigned int,unsigned long,const char *,int,wchar_t *,int);
int __stdcall WideCharToMultiByte(unsigned int,unsigned long,const wchar_t *,int,char *,int,const char *,int *);
unsigned int __stdcall GetACP(void);
]]
local kernel=ffi.load('kernel32')
local M={}
local function convert(text,source,target)
  if text=='' then return '' end
  local flags=(source==65001 or source==54936) and 8 or 0
  local count=kernel.MultiByteToWideChar(source,flags,text,#text,nil,0)
  if count<=0 then return nil,'text.encoding' end
  local wide=ffi.new('wchar_t[?]',count)
  if kernel.MultiByteToWideChar(source,flags,text,#text,wide,count)~=count then return nil,'text.encoding' end
  local used=ffi.new('int[1]')
  local output=ffi.new('char[?]',count*4+1)
  local unicode=target==65001 or target==54936
  local defaultUsed=not unicode and used or nil
  local bytes=kernel.WideCharToMultiByte(target,unicode and 0x80 or 0x400,
    wide,count,output,count*4,nil,defaultUsed)
  if bytes<=0 or used[0]~=0 then return nil,'text.encoding' end
  return ffi.string(output,bytes)
end
function M.display(text,codepage)
  -- The Persian game fonts use the Arabic yeh slot of Windows-1256.
  if codepage==1256 then text=text:gsub('ی','ي') end
  return convert(text,65001,codepage)
end
function M.read(text,codepage) return convert(text,codepage,65001) end
function M.character(value)
  if type(value)~='number' or value<32 or value>255 or value==127 then return nil end
  return convert(string.char(value),kernel.GetACP(),65001)
end
return M
