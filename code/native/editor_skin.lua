-- Reuse SHC's Save/Load table skin and the UI owner's ordinary button skin.
-- Reference 492C90 calls 4692E0(selected,row,0); 492A90 calls 463A90(0,-1).
-- These draw primitives use ButtonState, never Save/Load entries or callbacks.
local ffi=require('ffi')
local tableCell=ffi.cast('void (__thiscall *)(void *,int,int,int)',0x4692e0)
local border=ffi.cast('unsigned short *',0xdf33b4)
local M={text=0xC2F0EB,selectedText=0xCCFAFF}
function M.row(index,selected)
  tableCell(game.Rendering.pencilRenderCore,selected and 1 or 0,index,0)
end
function M.button(selected)
  local r=game.Rendering;local state=r.ButtonState
  local interacting=state.interacting
  if selected then state.interacting=1 end
  local ok,err=pcall(r.renderButtonBackground,r.alphaAndButtonSurface,0,0)
  state.interacting=interacting
  if not ok then error(err) end
end
function M.border(x,y,right,bottom)
  game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore,x,y,right,bottom,border[0])
end
return M
