local ffi=require('ffi')
local M={}
local function i(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local function short(address) return tonumber(ffi.cast('int16_t *',address)[0]) end
local function write(address,value) ffi.cast('int32_t *',address)[0]=value end
local function building(id)
  if id<1 or id>1999 then return nil end
  local offset=id*0x32c
  return {id=id,type=short(0xf98606+offset),owner=short(0xf9860a+offset),
    x=short(0xf98622+offset),y=short(0xf98624+offset)}
end
local viewport=ffi.cast('void *',0x21aebd8)
local focus=ffi.cast('void (__thiscall *)(void *,int,int)',0x4e8ca0)
local focusTile=ffi.cast('void (__thiscall *)(void *,int)',0x4e5e20)
local viewportTile=ffi.cast('int (__cdecl *)(void)',0x4b2a60)
local openBuilding=ffi.cast('int (__thiscall *)(void *,int)',0x463310)
local buildScreen=ffi.cast('void (__thiscall *)(void *,int,int)',0x46b340)
local stance=ffi.cast('void (__thiscall *)(void *,int,int)',0x522bf0)
local toggleInterface=ffi.cast('void (__thiscall *)(void *)',0x471aa0)
local rotate=ffi.cast('void (__thiscall *)(void *,int)',0x4f70e0)
local zoom=ffi.cast('void (__thiscall *)(void *,int)',0x4e7770)
local aliveLord=ffi.cast('int (__thiscall *)(void *,int)',0x5377f0)
local saveLoadDialog=ffi.cast('void (__thiscall *)(void *,int)',0x4968a0)
local clearGroup=ffi.cast('void (__thiscall *)(void *,int)',0x459bb0)
local assignGroup=ffi.cast('void (__thiscall *)(void *,int,int)',0x459c10)
local tribeUnit=ffi.cast('int (__thiscall *)(void *,int,int)',0x522390)
local function lord(id)
  if id<1 or id>2499 then return nil end
  local offset=id*0x490
  return {id=id,type=short(0x13885da+offset),state=short(0x13885d8+offset),
    owner=short(0x13885e2+offset),tile=i(0x1388620+offset)}
end
function M.new(scene,view)
  local groups=require('code/native/groups')
  return require('code/world_actions').new({
    resolve=function() return scene:resolve(view) end,
    group=groups.inspect,groupMatches=groups.matches,recallGroup=groups.recall,
    toggleInterface=function() toggleInterface(ffi.cast('void *',0x1fe7d10)) end,
    saveLoadDialog=function(modal) saveLoadDialog(ffi.cast('void *',0x11265a8),modal) end,
    validGroupMembers=function(tribe,player)
      local count=short(0x1667fd4+tribe*0x334)
      if count<1 or count>2500 then return false end
      for index=0,count-1 do
        local id=tribeUnit(ffi.cast('void *',0x1667f78),tribe,index)
        if id<1 or id>2499 or short(0x13885e2+id*0x490)~=player then return false end
      end
      return true
    end,
    assignGroup=function(group,tribe)
      local owner=ffi.cast('void *',0x112b0b8)
      -- Original Ctrl+number sequence. Native assignment retains identity
      -- serials, excludes lords and removes members from other groups.
      clearGroup(owner,group);assignGroup(owner,group,tribe)
    end,
    rotate=function(value) rotate(ffi.cast('void *',0x1a93208),value) end,
    zoom=function(value)
      zoom(viewport,value)
      -- The original Z branch marks both render surfaces dirty after setup.
      write(0xf983f8,2);write(0xb48ee4,1)
    end,
    snapshot=function()
      local s=scene:snapshot()
      s.player=i(0x1a275dc);s.selectedCount=i(0x1387f58);s.tribe=i(0x1667f78)
      s.ownedSelection=i(0x1fe7bec)
      s.rightHeld=i(0xf2c9f8);s.rotation=i(0x1fe7aa4)
      s.pendingRotation=i(0x1fe7aa8);s.zoom=i(0x21aec68)
      s.synchronyMode=i(0x191dd80);s.sessionHost=i(0x191def8)
      s.scenarioRestriction=i(0x1fe7d7c)
      if s.player>=1 and s.player<=8 then s.playerDead=i(0x115e03c+s.player*0x39f4) end
      if s.tribe>=0 and s.tribe<1250 then s.tribeOwner=i(0x1667fa4+s.tribe*0x334) end
      return s
    end,
    building=function(spec,player) return building(i(spec.reference+player*0x39f4)) end,
    lord=function(player) return lord(i(0x115dff0+player*0x39f4)) end,
    aliveLord=function(player)
      local count=i(0x1387f38)
      if count<1 or count>2500 then return nil end
      return lord(aliveLord(ffi.cast('void *',0x1387f38),player))
    end,
    lordIndex=function(value) if value~=nil then write(0xb39348,value) end;return i(0xb39348) end,
    bookmark=function(spec,value)
      if value~=nil then write(spec.bookmark,value) end
      return i(spec.bookmark)
    end,
    viewportTile=function() return viewportTile() end,
    focus=function(x,y) focus(viewport,x,y) end,
    focusTile=function(tile) focusTile(viewport,tile) end,
    buildScreen=function() buildScreen(ffi.cast('void *',0x1fe7d10),14,0) end,
    openBuilding=function(id) return openBuilding(ffi.cast('void *',0xf2c7bc),id)~=0 end,
    signpostIndex=function(value) if value~=nil then write(0xdf5538,value) end;return i(0xdf5538) end,
    signpost=function(index) return building(i(0x117f0a4+index*4)) end,
    -- This is the native W/Q/E submission wrapper, not the direct stance setter.
    -- It queues type 0x46 through GameSynchronyState::queueCommand exactly once.
    stance=function(tribe,value) stance(ffi.cast('void *',0x1667f78),tribe,value) end,
  })
end
return M
