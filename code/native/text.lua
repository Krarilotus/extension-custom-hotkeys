local ffi=require('ffi')
local Encoding=require('code/native/encoding')
local M={}
local width=ffi.cast('int (__thiscall *)(void *, const char *, int)',0x471690)
function M.width(encoded,font) return tonumber(width(game.Rendering.textManager,encoded,font or 0x12)) end
function M.codepage()
  local value=tonumber(ffi.cast('int32_t *',game.Rendering.textManager)[4])
  -- These are the original supported font/codepage paths. Additional patched
  -- encodings need their font owner's contract, never an assumed ANSI fallback.
  assert(value==1250 or value==1252,'text.game-codepage')
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
