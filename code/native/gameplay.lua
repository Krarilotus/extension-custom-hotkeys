local A=require('code/addresses')
local ffi=require('ffi')
local Resolve=require('code/gameplay')
local M={}
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
function M.snapshot(s)
  if s.screen~=14 and s.screen~=16 then return nil end
  s.synchronyMode=read(A.synchronyMode);s.player=read(A.localPlayer)
  s.inGame=read(A.inGame);s.syncStatus=read(A.syncStatus);s.saveRelated=read(A.saveRelated)
  s.paused=read(A.paused);s.halted=read(A.halted)
  if s.player<1 or s.player>8 then return nil end
  s.playerDead=read(A.playerDead+s.player*0x39f4)
  s.playerDisabled=read(A.playerDisabled+s.player*0x39f4)
  s.selectedCount=read(A.selectedCount);s.selectedLast=read(A.selectedLast)
  -- The native selected bitset is identity, not a cached world-coordinate map.
  -- The separate owned-selection flag remains stale after native deselection.
  s.selectionBits=ffi.string(ffi.cast('const char *',A.selectionBits),400)
  s.building=read(A.selectedBuilding);s.nextBuilding=read(A.nextBuilding)
  s.unit=read(A.selectedUnit);s.nextUnit=read(A.nextUnit)
  s.placement=read(A.placement);s.rotation=read(A.rotation)
  s.pendingRotation=read(A.pendingRotation)
  s.cameraX=read(A.cameraX);s.cameraY=read(A.cameraY);s.zoom=read(A.zoom)
  s.patrol=read(A.patrol)
  -- Native unit-action handler 0x446920 changes both interaction fields.
  -- Neither is implied by the selected units or patrol; their exact relationship
  -- outside that handler is not assumed by this read-only identity check.
  s.unitMode=read(A.unitMode);s.unitModeAux=read(A.unitModeAux)
  s.tribe=read(A.tribes)
  return s
end
function M.resolve(s,ownedModal)
  s=M.snapshot(s)
  return s and Resolve.resolve(s,ownedModal) or nil
end
return M
