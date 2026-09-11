local ffi=require('ffi')
local Resolve=require('code/gameplay')
local M={}
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
function M.resolve(s,ownedModal)
  if s.screen~=14 and s.screen~=16 then return nil end
  s.synchronyMode=read(0x191dd80);s.player=read(0x1a275dc)
  s.inGame=read(0x1fe7db4);s.syncStatus=read(0x191e300);s.saveRelated=read(0x191e424)
  s.paused=read(0x1fea054);s.halted=read(0x1fe7de0)
  if s.player<1 or s.player>8 then return nil end
  s.playerDead=read(0x115e03c+s.player*0x39f4)
  s.playerDisabled=read(0x115e008+s.player*0x39f4)
  s.selectedCount=read(0x1387f58);s.selectedLast=read(0x1387f44)
  -- The native selected bitset is identity, not a cached world-coordinate map.
  -- The separate owned-selection flag remains stale after native deselection.
  s.selectionBits=ffi.string(ffi.cast('const char *',0x1387fac),400)
  s.building=read(0x112655c);s.nextBuilding=read(0x1126560)
  s.unit=read(0x1126564);s.nextUnit=read(0x1126568)
  s.placement=read(0x1fe7aec);s.rotation=read(0x1fe7aa4)
  s.cameraX=read(0x21aec50);s.cameraY=read(0x21aec54);s.zoom=read(0x21aec68)
  s.patrol=read(0x1667f94)
  -- Native unit-action handler 0x446920 changes both interaction fields.
  -- Neither is implied by the selected units or patrol; their exact relationship
  -- outside that handler is not assumed by this read-only identity check.
  s.unitMode=read(0x1387f48);s.unitModeAux=read(0x1387f4c)
  s.tribe=read(0x1667f78)
  return Resolve.resolve(s,ownedModal)
end
return M
