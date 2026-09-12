local A=require('code/addresses')
-- Reuse SHC's Save/Load table skin and the UI owner's ordinary button skin.
-- Reference 492C90 calls 4692E0(selected,row,0); 492A90 calls 463A90(0,-1).
-- These draw primitives use ButtonState, never Save/Load entries or callbacks.
local ffi=require('ffi')
local tableCell=ffi.cast('void (__thiscall *)(void *,int,int,int)',A.renderTableCell)
local border=ffi.cast('unsigned short *',A.tableBorderColor)
local M={text=0xC2F0EB,selectedText=0xCCFAFF}
function M.row(index,selected)
  tableCell(game.Rendering.pencilRenderCore,selected and 1 or 0,index,0)
end
local function background(style,selected)
  local r=game.Rendering;local state=r.ButtonState
  local interacting=state.interacting
  state.interacting=style==-1 and 0 or (selected and 1 or interacting)
  -- Native -1 chooses the current menu/game surface and restores it afterward.
  local ok,err=pcall(r.renderButtonBackground,r.alphaAndButtonSurface,style,-1)
  state.interacting=interacting
  if not ok then error(err) end
end
function M.button(selected) background(0,selected) end
function M.field()
  -- Original text-input renderer47CCA0 uses basic-button style-1, target-1,
  -- with hover disabled. Keep its recessed field without owning native text state.
  background(-1,false)
end
function M.caption(encoded,color)
  -- Original Save/Load button492B46: font18, center alignment1, x+width/2,
  -- y+7 on the 30px native button. Let TextManager center the actual glyphs.
  local r=game.Rendering;local s=r.ButtonState
  r.renderTextToScreenConst(r.textManager,encoded,s.x+math.floor(s.width/2),
    s.y+7,1,color,18,false,0)
end
function M.border(x,y,right,bottom)
  game.Rendering.drawBorderBox(game.Rendering.pencilRenderCore,x,y,right,bottom,border[0])
end
return M
