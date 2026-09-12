local A=require('code/addresses')
-- Dedicated LuaJIT state: consume the UI owner's published primitives and
-- manager without changing the shared UI state or installing a second WndProc.
local ffi=require('ffi')
require('jit').off()
require('ui')
assert(ffi.sizeof('MenuItem')==80 and ffi.sizeof('Menu')==68,'ui.abi')
local Catalog=require('code/catalog')
local Profiles=require('code/profiles')
local Router=require('code/router')
local Platform=require('code/native/win32')
local Scene=require('code/native/scene')
local View=require('code/native/editor_view')
local M={}
function M.start(language)
  local lock=assert(require('code/native/profile_lock').acquire())
  local platform=Platform.new(tonumber(ffi.cast('int32_t *',A.gameWindow)[0]))
  local scene=Scene.new(platform,function() return remote.interface.recorderInputGeneration() end)
  local catalog=Catalog.production()
  local selectors=require('code/controls')
  local controls={}
  for _,control in ipairs(selectors) do controls[control.id]=control end
  local view,cursor,navigation,targeting,camera,worldActions,quickslot,lowering
  local router
  router=Router.new(catalog,Catalog.defaults(catalog),{
    resolve=function() if quickslot and quickslot.active then return nil end;return scene:resolve(view) end,
    dispatch=function(id,context)
      if (id=='game.quicksave' or id=='game.quickload') then router:barrier();return quickslot:start(context,id) end
      if id=='hotkeys.open' then return view:open() end
      if id=='menu.next' then return navigation:move(1,context) end
      if id=='menu.previous' then return navigation:move(-1,context) end
      if id=='menu.activate' or id=='game.menu.activate' then return navigation:activate(context) end
      if id:sub(1,10)=='grid.slot.' then
        return navigation:activateGrid(tonumber(id:sub(11)),selectors,context)
      end
      if id:sub(1,7)=='target.' then return targeting:dispatch(id,context) end
      if id=='view.lower-buildings' then cursor:cancel();return lowering:start(context) end
      if id:sub(1,11)=='camera.pan.' then cursor:cancel();return camera:start(id,context) end
      if controls[id] then return navigation:activateMatching(controls[id],context) end
      if id:sub(1,5)=='view.' or id:sub(1,11)=='unit.group.' or id:sub(1,13)=='camera.group.'
          or id=='game.save.open' or id=='game.load.open' then cursor:cancel() end
      return worldActions:dispatch(id,context)
    end,
    canRecover=function(c) return c and (c.owner:sub(1,5)=='menu.' or c.owner=='game.build' or c.owner=='game.status') end,
    recover=function() return view:open() end,
    cancelLocalHold=function(id)
      if id=='view.lower-buildings' and lowering then lowering:release()
      elseif camera then camera:release(id) end
    end,
    cancelPending=function()
      if navigation then navigation:cancel() end
      if lowering then lowering:release() end
      if quickslot then quickslot:cancel() end
      if cursor then cursor:cancel() end
    end,
  })
  local store={load=function() return remote.interface.loadProfiles() end,
    save=function(_,document) return remote.interface.saveProfiles(document) end}
  local profiles,err=Profiles.new(catalog,store,router)
  assert(profiles,err)
  view=View.new(profiles,catalog,router,scene,platform,require('code/locale').new(language,
    require('code/native/text').label))
  camera=require('code/native/camera').new(platform,router)
  worldActions=require('code/native/world_actions').new(scene,view)
  lowering=require('code/native/lowering').new(scene,view,platform,router)
  local pointer=require('code/native/pointer').new(platform,scene)
  cursor=require('code/cursor').new(require('code/native/mouse').new(scene,
    function()
      if quickslot and quickslot.active then return quickslot:context() end
      return scene:resolve(view)
    end,pointer))
  local reader=require('code/native/menu_reader').new()
  navigation=require('code/navigation').new(require('code/native/menu_adapter').new(scene,reader),cursor)
  targeting=require('code/targeting').new(cursor,navigation,function()
    -- setupViewport(0x4E66F0) stores its pixel rectangle here. The similarly
    -- named fields at +0x78/+0x88 are map offsets/tile counts, not screen pixels.
    local p=ffi.cast('int32_t *',A.viewportRectangle)
    local x,y,w,h=tonumber(p[0]),tonumber(p[1]),tonumber(p[2]),tonumber(p[3])
    local s=scene:snapshot()
    if x<0 or y<0 or w<64 or h<64 or x+w>s.width or y+h>s.height then return nil end
    return x,y,w,h,tostring(ffi.cast('int32_t *',A.cameraX)[0])..':'..
      tostring(ffi.cast('int32_t *',A.cameraY)[0])..':'..x..':'..y..':'..w..':'..h
  end)
  quickslot=require('code/native/quickslot').new(scene,view,worldActions,cursor,reader)
  local chain=require('code/native/chain').install(remote.interface.chain(),router,platform,
    function(event)
      if quickslot.active and (event.kind=='down' or event.kind=='char') then quickslot:cancel() end
      return view:input(event)
    end,function(message,_,lparam)
      if pointer:observe(message,lparam) then quickslot:cancel();navigation:cancel() end
    end)
  local inputFrame=require('code/native/input_frame').install(cursor,router,camera,quickslot,lowering,navigation)
  local runtime={lock=lock,platform=platform,scene=scene,catalog=catalog,router=router,
    profiles=profiles,view=view,chain=chain,cursor=cursor,navigation=navigation,
    inputFrame=inputFrame,lowering=lowering,quickslot=quickslot,pointer=pointer,targeting=targeting,camera=camera,worldActions=worldActions,pins={}}
  runtime.pins=require('code/native/main_menu').install(scene,view)
  return runtime
end
return M
