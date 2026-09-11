local Context=require('code/context')
local M={}
M.__index=M
local stances={['unit.stance.stand-ground']=0,['unit.stance.defensive']=1,['unit.stance.aggressive']=2}
local buildings={}
for _,b in ipairs(require('code/building_actions')) do buildings[b.name]=b end
local function integer(n,lo,hi) return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
function M.new(adapter) return setmetatable({adapter=adapter},M) end
function M:dispatch(id,context)
  local a=self.adapter
  if not context or context.state~='live-sp' or not context.authority
      or (context.owner~='game.build' and context.owner~='game.status')
      or not Context.same(context,Context.resolve(a.resolve())) then return false end
  local s=a.snapshot()
  if id=='game.save.open' or id=='game.load.open' then
    if not integer(s.mode,0,5) or s.mode==1 or s.mode==4 or s.scenarioRestriction~=0
        or s.playerDead~=0 or (s.synchronyMode~=0 and s.synchronyMode~=99)
        or s.textModal~=0 or s.modal~=-1 then return false end
    if id=='game.save.open' and s.synchronyMode==99 and s.sessionHost~=1 then return false end
    a.saveLoadDialog(id=='game.save.open' and 10 or 9)
    return true
  end
  if id=='camera.focus.lord' or id=='camera.cycle.lords' then
    local function valid(lord,player)
      return lord and integer(lord.id,1,2499) and lord.type==55 and lord.state==2
        and lord.owner==player and integer(lord.tile,0,159999)
    end
    if id=='camera.focus.lord' then
      local lord=a.lord(s.player)
      if not valid(lord,s.player) then return false end
      a.focusTile(lord.tile);return true
    end
    local player=a.lordIndex()
    if not integer(player,1,8) then return false end
    for _=1,8 do
      a.lordIndex(player%8+1)
      local lord=a.aliveLord(player)
      if valid(lord,player) then a.focusTile(lord.tile);return true end
      player=player%8+1
    end
    return true
  end
  if id=='view.rotate-left' or id=='view.rotate-right' or id=='view.toggle-zoom' then
    if s.rightHeld~=0 or s.pendingRotation~=8 then return false end
    if id=='view.toggle-zoom' then
      if not integer(s.zoom,0,1) then return false end
      a.zoom(1-s.zoom)
    else
      if not integer(s.rotation,0,6) or s.rotation%2~=0 then return false end
      a.rotate((s.rotation+(id=='view.rotate-left' and 2 or 6))%8)
    end
    return true
  end
  if id=='view.toggle-interface' then
    if s.screen~=14 then return false end
    a.toggleInterface();return true
  end
  if stances[id]~=nil then
    if s.screen~=14 or (s.tab~=61 and s.tab~=62) or s.selectedCount<=0
        or not integer(s.tribe,0,1249) or s.tribeOwner~=s.player then return false end
    a.stance(s.tribe,stances[id]);return true
  end
  local verb,name=id:match('^(camera%.return%.)(.+)$')
  if not verb then verb,name=id:match('^(menu%.%a+%.)(.+)$') end
  local spec=buildings[name]
  if spec and verb=='camera.return.' and spec.bookmark then
    local tile=a.bookmark(spec)
    if not integer(tile,0,159999) then return false end
    a.focusTile(tile)
    if s.screen==16 then a.buildScreen() end
    a.bookmark(spec,-1);return true
  end
  if spec and (verb=='menu.open.' or verb=='menu.focus.' and spec.bookmark) then
    local b=a.building(spec,s.player)
    if not b or not integer(b.id,1,1999) or b.owner~=s.player then return false end
    local matching=false
    for _,kind in ipairs(spec.types) do if b.type==kind then matching=true;break end end
    if not matching then return false end
    if verb=='menu.focus.' then
      local tile=a.viewportTile()
      if not integer(tile,0,159999) or not integer(b.x,0,397) or not integer(b.y,0,397) then return false end
      a.bookmark(spec,tile);a.focus(b.x+2,b.y+2)
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
