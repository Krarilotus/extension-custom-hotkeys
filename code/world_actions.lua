local Context=require('code/context')
local M={}
M.__index=M
local stances={['unit.stance.stand-ground']=0,['unit.stance.defensive']=1,['unit.stance.aggressive']=2}
local function integer(n,lo,hi) return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
function M.new(adapter) return setmetatable({adapter=adapter},M) end
function M:dispatch(id,context)
  local a=self.adapter
  if not context or context.state~='live-sp' or not context.authority
      or (context.owner~='game.build' and context.owner~='game.status')
      or not Context.same(context,Context.resolve(a.resolve())) then return false end
  local s=a.snapshot()
  if stances[id]~=nil then
    if s.screen~=14 or (s.tab~=61 and s.tab~=62) or s.selectedCount<=0
        or not integer(s.tribe,0,1249) or s.tribeOwner~=s.player then return false end
    a.stance(s.tribe,stances[id]);return true
  end
  if id=='camera.return.armory' then
    local tile=a.bookmark()
    if not integer(tile,0,159999) then return false end
    a.focusTile(tile)
    if s.screen==16 then a.buildScreen() end
    a.bookmark(-1);return true
  end
  if id=='menu.open.armory' or id=='menu.focus.armory' then
    local b=a.armory(s.player)
    if not b or not integer(b.id,1,1999) or b.type~=11 or b.owner~=s.player then return false end
    if id=='menu.focus.armory' then
      a.bookmark(a.viewportTile());a.focus(b.x+2,b.y+2)
    end
    return a.openBuilding(b.id)
  end
  if id=='camera.cycle.signposts' then
    local index=a.signpostIndex()
    if not integer(index,0,7) then return false end
    local b=a.signpost(index)
    if b and integer(b.id,1,1999) and b.type==52 then a.focus(b.x+1,b.y+1) end
    -- The original focuses the current entry, then advances over empty slots.
    -- Never scan unbounded memory if no signposts remain.
    for step=1,8 do
      index=(index+1)%8
      local next=a.signpost(index)
      if next and integer(next.id,1,1999) and next.type==52 then break end
    end
    a.signpostIndex(index);return true
  end
  return false
end
return M
