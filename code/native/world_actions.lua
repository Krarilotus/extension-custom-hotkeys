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
function M.new(scene,view)
  return require('code/world_actions').new({
    resolve=function() return scene:resolve(view) end,
    snapshot=function()
      local s=scene:snapshot()
      s.player=i(0x1a275dc);s.selectedCount=i(0x1387f58);s.tribe=i(0x1667f78)
      if s.tribe>=0 and s.tribe<1250 then s.tribeOwner=i(0x1667fa4+s.tribe*0x334) end
      return s
    end,
    armory=function(player) return building(i(0x115bf04+player*0x39f4)) end,
    bookmark=function(value) if value~=nil then write(0x1fea06c,value) end;return i(0x1fea06c) end,
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
