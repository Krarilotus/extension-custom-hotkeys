local A=require('code/addresses')
local ffi=require('ffi')
local Encoding=require('code/native/encoding')
local M={}
local width=ffi.cast('int (__thiscall *)(void *, const char *, int)',A.textWidth)
function M.width(encoded,font) return tonumber(width(game.Rendering.textManager,encoded,font or 0x12)) end
function M.codepage()
  local value=tonumber(ffi.cast('int32_t *',game.Rendering.textManager)[4])
  -- The loaded TextManager owns encoding, including translated installations.
  -- Do not substitute the Windows locale or restrict it to original EXE enums.
  assert(value>0,'text.game-codepage')
  return value
end
function M.label(group,index)
  local text=game.Rendering.getTextStringInGroupAtOffset(game.Rendering.textManager,group,index)
  if text==nil then return nil end
  for length=0,4095 do
    if text[length]==0 then return Encoding.read(ffi.string(text,length),M.codepage()) end
  end
  return nil
end
return M
