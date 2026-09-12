local A=require('code/addresses')
local ffi=require('ffi')
local M={}
local function i(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local function short(address) return tonumber(ffi.cast('int16_t *',address)[0]) end
local function write(address,value) ffi.cast('int32_t *',address)[0]=value end
local function building(id)
  if id<1 or id>1999 then return nil end
  local offset=id*0x32c
  return {id=id,type=short(A.buildingType+offset),owner=short(A.buildingOwner+offset),
    x=short(A.buildingX+offset),y=short(A.buildingY+offset),
    state=short(A.buildingType+offset-2),uid=i(A.buildingOwner+offset+2)}
end
local viewport=ffi.cast('void *',A.viewport)
local focus=ffi.cast('void (__thiscall *)(void *,int,int)',A.focusPosition)
local focusTile=ffi.cast('void (__thiscall *)(void *,int)',A.focusTile)
local viewportTile=ffi.cast('int (__cdecl *)(void)',A.viewportTile)
local openBuilding=ffi.cast('int (__thiscall *)(void *,int)',A.openBuilding)
local buildScreen=ffi.cast('void (__thiscall *)(void *,int,int)',A.changeScreen)
local stance=ffi.cast('void (__thiscall *)(void *,int,int)',A.submitStance)
local toggleInterface=ffi.cast('void (__thiscall *)(void *)',A.toggleInterface)
local rotate=ffi.cast('void (__thiscall *)(void *,int)',A.rotateBuildings)
local zoom=ffi.cast('void (__thiscall *)(void *,int)',A.setZoom)
local aliveLord=ffi.cast('int (__thiscall *)(void *,int)',A.findAliveLord)
local saveLoadDialog=ffi.cast('void (__thiscall *)(void *,int)',A.openSaveLoad)
local clearGroup=ffi.cast('void (__thiscall *)(void *,int)',A.clearGroup)
local assignGroup=ffi.cast('void (__thiscall *)(void *,int,int)',A.assignGroup)
local tribeUnit=ffi.cast('int (__thiscall *)(void *,int,int)',A.tribeUnit)
local deselect=ffi.cast('void (__thiscall *)(void *)',A.submitDeselect)
local function lord(id)
  if id<1 or id>(A.unitCapacity-1) then return nil end
  local offset=id*0x490
  return {id=id,type=short(A.unitType+offset),state=short(A.unitState+offset),
    owner=short(A.unitOwner+offset),tile=i(A.unitTile+offset)}
end
function M.new(scene,view,pointer,pointerClick)
  local groups=require('code/native/groups')
  return require('code/world_actions').new({
    resolve=function() return scene:resolve(view) end,
    pointerAllowed=function(position) return pointer:insideWorld(position) end,
    pointerClick=pointerClick,
    deselect=function() deselect(ffi.cast('void *',A.units)) end,
    -- Local bookmarks end at load entry or leaving the world. Read only while
    -- bookmarks exist; Recorder's observer additionally covers direct restores.
    sameWorld=function()
      local screen=i(A.screen)
      return i(A.inGame)==1 and (screen==14 or screen==16) and i(A.primaryModal)~=9
    end,
    buildingByID=building,
    clearGroup=function(group) clearGroup(ffi.cast('void *',A.controlGroups),group) end,
    group=groups.inspect,groupMatches=groups.matches,recallGroup=groups.recall,
    toggleInterface=function() toggleInterface(ffi.cast('void *',A.gameCore)) end,
    saveLoadDialog=function(modal) saveLoadDialog(ffi.cast('void *',A.textDialog),modal) end,
    validGroupMembers=function(tribe,player)
      local count=short(A.tribeCount+tribe*A.tribeStride)
      if count<1 or count>A.unitCapacity then return false end
      for index=0,count-1 do
        local id=tribeUnit(ffi.cast('void *',A.tribes),tribe,index)
        if id<1 or id>(A.unitCapacity-1) or short(A.unitOwner+id*0x490)~=player then return false end
      end
      return true
    end,
    assignGroup=function(group,tribe)
      local owner=ffi.cast('void *',A.controlGroups)
      -- Original Ctrl+number sequence. Native assignment retains identity
      -- serials, excludes lords and removes members from other groups.
      clearGroup(owner,group);assignGroup(owner,group,tribe)
    end,
    rotate=function(value) rotate(ffi.cast('void *',A.buildingView),value) end,
    zoom=function(value)
      zoom(viewport,value)
      -- The original Z branch marks both render surfaces dirty after setup.
      write(A.refreshViewport,2);write(A.refreshSurface,1)
    end,
    snapshot=function()
      local s=scene:snapshot()
      s.player=i(A.localPlayer);s.selectedCount=i(A.selectedCount);s.tribe=i(A.tribes)
      s.ownedSelection=i(A.ownedSelection)
      s.building=i(A.selectedBuilding)
      s.placement=i(A.placement);s.patrol=i(A.patrol)
      s.unitMode=i(A.unitMode);s.unitModeAux=i(A.unitModeAux)
      s.rightHeld=i(A.mouseRightHeld);s.rotation=i(A.rotation)
      s.pendingRotation=i(A.pendingRotation);s.zoom=i(A.zoom)
      s.synchronyMode=i(A.synchronyMode);s.sessionHost=i(A.sessionHost)
      s.scenarioRestriction=i(A.scenarioRestriction)
      if s.player>=1 and s.player<=8 then s.playerDead=i(A.playerDead+s.player*0x39f4) end
      if s.tribe>=0 and s.tribe<A.tribeCapacity then s.tribeOwner=i(A.tribeOwner+s.tribe*A.tribeStride) end
      return s
    end,
    building=function(spec,player) return building(i(spec.reference+player*0x39f4)) end,
    lord=function(player) return lord(i(A.playerLord+player*0x39f4)) end,
    aliveLord=function(player)
      local count=i(A.units)
      if count<1 or count>A.unitCapacity then return nil end
      return lord(aliveLord(ffi.cast('void *',A.units),player))
    end,
    lordIndex=function(value) if value~=nil then write(A.lordCycleIndex,value) end;return i(A.lordCycleIndex) end,
    bookmark=function(spec,value)
      if value~=nil then write(spec.bookmark,value) end
      return i(spec.bookmark)
    end,
    viewportTile=function() return viewportTile() end,
    focus=function(x,y) focus(viewport,x,y) end,
    focusTile=function(tile) focusTile(viewport,tile) end,
    buildScreen=function() buildScreen(ffi.cast('void *',A.gameCore),14,0) end,
    openBuilding=function(id) return openBuilding(ffi.cast('void *',A.buttonSurface),id)~=0 end,
    signpostIndex=function(value) if value~=nil then write(A.signpostCycleIndex,value) end;return i(A.signpostCycleIndex) end,
    signpost=function(index) return building(i(A.signposts+index*4)) end,
    -- This is the native W/Q/E submission wrapper, not the direct stance setter.
    -- It queues type 0x46 through GameSynchronyState::queueCommand exactly once.
    stance=function(tribe,value) stance(ffi.cast('void *',A.tribes),tribe,value) end,
  })
end
return M
