local M={}
local Options=require('code/options_context')
local Load=require('code/load_context')
local function integer(value,lo,hi)
  return type(value)=='number' and value==math.floor(value) and value>=lo and value<=hi
end
-- Shared session/world validation. This does not authorize an input owner;
-- callers must separately prove the actual modal/text/control ownership.
function M.live(s,allowPaused)
  if (s.screen~=14 and s.screen~=16) or s.mode==1
      or not integer(s.mode,0,6) or (s.synchronyMode~=0 and s.synchronyMode~=99)
      or s.inGame~=1 or s.syncStatus~=0 or s.saveRelated~=0
      or (s.paused~=0 and not (allowPaused and s.paused==1))
      or s.halted~=0 or s.sliding~=0
      or s.newPlayer~=0 or s.delay~=-1
      or s.focused~=true or s.composing~=false
      or not integer(s.player,1,8) or s.playerDead~=0 or s.playerDisabled~=0
      or not integer(s.selectedCount,0,2500) or not integer(s.selectedLast,0,2499)
      or not integer(s.tribe,0,1249)
      or type(s.selectionBits)~='string' or #s.selectionBits~=400
      or not integer(s.building,0,1999) or s.building~=s.nextBuilding
      or not integer(s.unit,0,2499) or s.unit~=s.nextUnit
      or not integer(s.placement,0,65535) or not integer(s.rotation,0,6) or s.rotation%2~=0
      or not integer(s.cameraX,-1000000,1000000) or not integer(s.cameraY,-1000000,1000000)
      or s.pendingRotation~=8 or not integer(s.zoom,0,1) or not integer(s.patrol,0,1)
      or not integer(s.unitMode,-2147483648,2147483647)
      or not integer(s.unitModeAux,-2147483648,2147483647) then return false end
  return true
end
-- Positive live-SP gate; native mode alone does not prove replay/MP eligibility.
function M.resolve(s,ownedModal)
  local options=ownedModal==5 and Options.owns(s)
  local load=ownedModal==9 and Load.owns(s)
  if (ownedModal==5 and not options) or (ownedModal==9 and not load)
      or not M.live(s,options or load)
      or (s.modal~=-1 and (ownedModal==nil or s.modal~=ownedModal))
      or s.modal2~=-1 or s.modal3~=-1
      or (s.textModal~=0 and not options and not load) or s.textEditor~=0 then return nil end

  return {owner=options and 'game.options' or load and 'game.load' or (s.screen==14 and 'game.build' or 'game.status'),state='live-sp',authority=true,
    selection=load and Load.identity(s) or table.concat({s.player,s.building,s.unit,s.tribe,s.selectedCount,s.selectedLast},':')..':'..s.selectionBits,
    -- Camera position changes during a local pan hold. Queued world clicks
    -- carry their own projection guard; a pan must not cancel itself.
    -- These native mode values are identity, not permission to invoke an
    -- action. A changed mode invalidates any gesture aimed in the old mode.
    targeting=table.concat({s.placement,s.rotation,s.zoom,s.patrol,s.unitMode,s.unitModeAux},':')}
end
return M
