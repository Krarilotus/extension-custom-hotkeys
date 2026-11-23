local A=require('code/addresses')
-- Dedicated LuaJIT state: consume the UI owner's published primitives and
-- manager without changing the shared UI state or installing a second WndProc.
local ffi=require('ffi')
require('jit').off()
require('ui')
assert(ffi.sizeof('MenuItem')==80 and ffi.sizeof('Menu')==68,'ui.abi')
local Catalog=require('code/catalog')
local Bindings=require('code/bindings')
local Router=require('code/router')
local Platform=require('code/native/win32')
local Scene=require('code/native/scene')
local View=require('code/native/editor_view')
local M={}
function M.start(language)
  require('code/dialog_context').bind(remote.interface.modalMenuAddress)
  local lock,lockProblem=require('code/native/profile_lock').acquire()
  if not lock then
    remote.interface.logWarning('Profiles are read-only in this process ('..tostring(lockProblem)..')')
  end
  local platform=Platform.new(tonumber(ffi.cast('int32_t *',A.gameWindow)[0]))
  local catalog=Catalog.production(remote.interface.extensionActions())
  local scene=Scene.new(platform,function() return remote.interface.recorderInputGeneration() end)
  local function extensionAction(id,phase,context,event)
    local info=context and {owner=context.owner,panel=context.panel,modal=context.modal,
      screen=context.screen,state=context.state,authority=context.authority}
    local _,problem=remote.interface.dispatchExtension(id,phase,info,event)
    if problem then remote.interface.logWarning(id..': '..problem) end
  end
  local selectors=require('code/controls')
  local controls={}
  for _,control in ipairs(selectors) do controls[control.id]=control end
  local view,cursor,navigation,targeting,camera,worldActions,quickslot,lowering
  local router,ready
  router=Router.new(catalog,Catalog.defaults(catalog),{
    report=function(where,problem)
      remote.interface.logWarning('Hotkeys switched off at '..where..': '..tostring(problem))
    end,
    resolve=function()
      if quickslot and quickslot.active then return nil end
      return scene:resolve(view)
    end,
    dispatch=function(id,context,nativeBinding,event)
      if catalog.actions[id].extension then return extensionAction(id,'press',context,event) end
      if (id=='game.quicksave' or id=='game.quickload') then router:barrier();return quickslot:start(context,id) end
      if id=='hotkeys.open' then return view:open() end
      if id=='menu.next' then return navigation:move(1,context) end
      if id=='menu.previous' then return navigation:move(-1,context) end
      if id=='menu.decrease' then return navigation:adjust(-1,context) end
      if id=='menu.increase' then return navigation:adjust(1,context) end
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
      return worldActions:dispatch(id,context,nativeBinding,event)
    end,
    canRecover=function(c) return c and (c.owner:sub(1,5)=='menu.' or c.owner=='game.build' or c.owner=='game.status') end,
    recover=function() return view:open() end,
    cancelLocalHold=function(id)
      if catalog.actions[id].extension then extensionAction(id,'release')
      elseif id=='view.lower-buildings' and lowering then lowering:release()
      elseif camera then camera:release(id) end
    end,
    cancelPending=function()
      if navigation then navigation:cancel() end
      if lowering then lowering:release() end
      if quickslot then quickslot:cancel() end
      if cursor then cursor:cancel() end
    end,
    cancelPointerHold=function() if cursor then cursor.adapter.cancel() end end,
    exclusive=function() return quickslot~=nil and quickslot.active==true end,
  })
  local replace=require('code/native/replace_file')
  local source=remote.interface.bindingSource()
  local store={save=function(_,changes)
    if not lock then return nil,lockProblem end
    local staged,problem=remote.interface.stageBindings(changes)
    if not staged then return nil,problem end
    local ok,err=replace(staged.staged,staged.target)
    remote.interface.bindingsReplaced(ok==true)
    return ok,err
  end}
  local built,bindings=pcall(Bindings.new,catalog,source,store,router)
  if not built then
    remote.interface.logWarning('Using layout defaults without saving ('..tostring(bindings)..')')
    source={}
    bindings=Bindings.new(catalog,source,{save=function() return nil,'config.unavailable' end},router)
  end
  for _,id in ipairs(bindings.committed.aside) do
    remote.interface.logWarning('Saved binding for '..id..' set aside: its chord is taken')
  end
  if bindings.migration and bindings.migration.saved then
    local marked,problem=remote.interface.markLegacyImported()
    if not marked then remote.interface.logWarning('0.2 import not recorded ('..tostring(problem)..')') end
  elseif bindings.migration then
    remote.interface.logWarning('0.2 profile not written to the UCP config ('..tostring(bindings.migration.problem)
      ..'); the 0.2 files are unchanged, and a later start imports them into a config without Custom Hotkeys entries')
  end
  view=View.new(bindings,catalog,router,scene,platform,require('code/locale').new(language,
    require('code/native/text').label,catalog.extensionLabels))
  camera=require('code/native/camera').new(platform,router)
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
  worldActions=require('code/native/world_actions').new(scene,view,pointer,function(button,context)
    return targeting:dispatch(button=='left' and 'target.confirm' or 'target.cancel',context)
  end)
  quickslot=require('code/native/quickslot').new(scene,view,worldActions,cursor,reader)
  local inputFrame=require('code/native/input_frame').install(cursor,router,camera,quickslot,lowering,navigation,worldActions)
  local chain=require('code/native/chain').install(remote.interface.chain(),router,platform,
    function(event)
      if quickslot.active and (event.kind=='down' or event.kind=='char') then quickslot:cancel() end
      return view:input(event)
    end,function(message,_,lparam)
      if pointer:observe(message,lparam) then quickslot:cancel();navigation:cancel() end
    end,function() return ready end)
  local runtime={lock=lock,platform=platform,scene=scene,catalog=catalog,router=router,
    bindings=bindings,view=view,chain=chain,cursor=cursor,navigation=navigation,
    inputFrame=inputFrame,lowering=lowering,quickslot=quickslot,pointer=pointer,targeting=targeting,camera=camera,worldActions=worldActions,pins={}}
  runtime.pins=require('code/native/options_menu').install(scene,view,function() return ready end)
  ready=true
  return runtime
end
return M
