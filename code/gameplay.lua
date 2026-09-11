local M={}
local function integer(value,lo,hi)
  return type(value)=='number' and value==math.floor(value) and value>=lo and value<=hi
end
-- Positive live-SP gate. Multiplayer modal/session behavior is a separate
-- integration gate; neither generic game mode 3 nor a selection flag proves it.
function M.resolve(s,ownedModal)
  if (s.screen~=14 and s.screen~=16) or s.mode==1
      or not integer(s.mode,0,6) or (s.synchronyMode~=0 and s.synchronyMode~=99)
      or s.inGame~=1 or s.syncStatus~=0 or s.saveRelated~=0 or s.paused~=0
      or s.halted~=0 or s.sliding~=0 or (s.modal~=-1 and (ownedModal==nil or s.modal~=ownedModal))
      or s.modal2~=-1 or s.modal3~=-1
      or s.textModal~=0 or s.textEditor~=0 or s.newPlayer~=0 or s.delay~=-1
      or s.focused~=true or s.composing~=false
      or not integer(s.player,1,8) or s.playerDead~=0 or s.playerDisabled~=0
      or not integer(s.selectedCount,0,2500) or not integer(s.selectedLast,0,2499)
      or not integer(s.tribe,0,1249)
      or type(s.selectionBits)~='string' or #s.selectionBits~=400
      or not integer(s.building,0,1999) or s.building~=s.nextBuilding
      or not integer(s.unit,0,2499) or s.unit~=s.nextUnit
      or not integer(s.placement,0,65535) or not integer(s.rotation,0,6) or s.rotation%2~=0
      or not integer(s.cameraX,-1000000,1000000) or not integer(s.cameraY,-1000000,1000000)
      or not integer(s.zoom,0,1) or not integer(s.patrol,0,1) then return nil end
  return {owner=s.screen==14 and 'game.build' or 'game.status',state='live-sp',authority=true,
    selection=table.concat({s.player,s.building,s.unit,s.tribe,s.selectedCount,s.selectedLast},':')..':'..s.selectionBits,
    -- Camera position changes during a local pan hold. Queued world clicks
    -- carry their own projection guard; a pan must not cancel itself.
    targeting=table.concat({s.placement,s.rotation,s.zoom,s.patrol},':')}
end
return M
