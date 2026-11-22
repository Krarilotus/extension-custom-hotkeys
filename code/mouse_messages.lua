-- Windows button messages stay in the existing CallNextProc chain. Coordinates
-- are unchanged for graphicsApiReplacer; no posted messages or synthetic input.
local M={}
local messages={
  [0x201]={'left','down'},[0x202]={'left','up'},[0x203]={'left','down',true},
  [0x204]={'right','down'},[0x205]={'right','up'},[0x206]={'right','down',true},
  [0x207]={'middle','down'},[0x208]={'middle','up'},[0x209]={'middle','down',true},
  [0x20b]={'x','down'},[0x20c]={'x','up'},[0x20d]={'x','down',true},
}
local bits={left=1,right=2,middle=16,x1=32,x2=64}
local function has(value,bit) return math.floor(value/bit)%2==1 end
function M.decode(message,wparam)
  local definition=messages[message]
  if not definition then return nil end
  local button=definition[1]
  if button=='x' then
    local id=math.floor(wparam/65536)%65536
    if id~=1 and id~=2 then return nil end
    button='x'..id
  end
  return button,definition[2],definition[3] or false
end
-- WM_MOUSEWHEEL carries Ctrl/Shift at the time of the gesture, unlike a later
-- keyboard snapshot. Alt comes from the input owner's modifier snapshot.
function M.wheel(wparam,snapshotMods)
  local delta=math.floor(wparam/65536)%65536
  if delta>=32768 then delta=delta-65536 end
  local flags=wparam%65536
  local mods=(math.floor(flags/8)%2)+(math.floor(flags/4)%2)*2
  if type(snapshotMods)=='number' and snapshotMods>=4 then mods=mods+4 end
  if delta==0 then return nil,mods,0 end
  return delta>0 and 'up' or 'down',mods,delta
end
function M.flags(wparam,from,to,down)
  local value=wparam%65536
  if has(value,bits[from]) then value=value-bits[from] end
  if down and not has(value,bits[to]) then value=value+bits[to] end
  return value
end
function M.forward(message,wparam,from,to,kind,double)
  local base=to=='left' and 0x201 or 0x204
  return base+(kind=='up' and 1 or double and 2 or 0),M.flags(wparam,from,to,kind=='down')
end
return M
