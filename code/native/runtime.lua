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
function M.start(entries,language)
  local lock=assert(require('code/native/profile_lock').acquire())
  local platform=Platform.new(tonumber(ffi.cast('int32_t *',0xf983e4)[0]))
  local scene=Scene.new(platform)
  local catalog=Catalog.new(entries,require('code/originals'))
  local controls={}
  for _,control in ipairs(require('code/controls')) do controls[control.id]=control end
  local view,cursor,navigation,targeting,camera,worldActions,quicksave
  local router
  router=Router.new(catalog,Catalog.defaults(catalog),{
    resolve=function() if quicksave and quicksave.active then return nil end;return scene:resolve(view) end,
    dispatch=function(id,context)
      if id=='game.quicksave' then router:barrier();return quicksave:start(context) end
      if id=='hotkeys.open' then return view:open() end
      if id=='menu.next' then return navigation:move(1,context) end
      if id=='menu.previous' then return navigation:move(-1,context) end
      if id=='menu.activate' or id=='game.menu.activate' then return navigation:activate(context) end
      if id:sub(1,7)=='target.' then return targeting:dispatch(id,context) end
      if id:sub(1,11)=='camera.pan.' then cursor:cancel();return camera:start(id,context) end
      if controls[id] then return navigation:activateMatching(controls[id],context) end
      if id:sub(1,5)=='view.' or id:sub(1,11)=='unit.group.' or id:sub(1,13)=='camera.group.'
          or id=='game.save.open' or id=='game.load.open' then cursor:cancel() end
      return worldActions:dispatch(id,context)
    end,
    canRecover=function(c) return c and (c.owner:sub(1,5)=='menu.' or c.owner=='game.build' or c.owner=='game.status') end,
    recover=function() return view:open() end,
    cancelLocalHold=function(id) if camera then camera:release(id) end end,
    cancelPending=function()
      if quicksave then quicksave:cancel() end
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
  local pointer=require('code/native/pointer').new(platform,scene)
  cursor=require('code/cursor').new(require('code/native/mouse').new(scene,
    function()
      if quicksave and quicksave.active then return quicksave:context() end
      return scene:resolve(view)
    end,pointer))
  local reader=require('code/native/menu_reader').new()
  navigation=require('code/navigation').new({
    controls=function(context)
      if not context or (context.owner:sub(1,5)~='menu.' and context.owner~='game.build'
          and context.owner~='game.status' and context.owner~='game.options' and context.owner~='game.load') then return nil end
      local s=scene:snapshot()
      if context.owner=='game.load' then
        local load=require('code/load_context')
        if tostring(s.screen)~=context.screen or not load.owns(s) then return nil end
        local origin=load.origin(s)
        if not origin then return nil end
        return load.controls(reader:read(s.activeModalMenu,s,origin),s)
      end
      if context.owner=='game.options' then
        if tostring(s.screen)~=context.screen or not require('code/options_context').owns(s) then return nil end
        local origin=require('code/options_context').origin(s)
        if not origin then return nil end
        return reader:read(s.activeModalMenu,s,origin)
      end
      if tostring(s.screen)~=context.screen or s.modal~=-1 or s.modal2~=-1 or s.modal3~=-1 then return nil end
      return reader:read(remote.interface.menuAddress(s.screen),s)
    end,
    point=function(row) return row.x+math.floor(row.width/2),row.y+math.floor(row.height/2) end,
    hit=function(address) return ffi.cast('MenuItem *',address)[0].hovering~=0 end,
  },cursor)
  targeting=require('code/targeting').new(cursor,navigation,function()
    -- setupViewport(0x4E66F0) stores its pixel rectangle here. The similarly
    -- named fields at +0x78/+0x88 are map offsets/tile counts, not screen pixels.
    local p=ffi.cast('int32_t *',0x233a300)
    local x,y,w,h=tonumber(p[0]),tonumber(p[1]),tonumber(p[2]),tonumber(p[3])
    local s=scene:snapshot()
    if x<0 or y<0 or w<64 or h<64 or x+w>s.width or y+h>s.height then return nil end
    return x,y,w,h,tostring(ffi.cast('int32_t *',0x21aec50)[0])..':'..
      tostring(ffi.cast('int32_t *',0x21aec54)[0])..':'..x..':'..y..':'..w..':'..h
  end)
  quicksave=require('code/native/quicksave').new(scene,view,worldActions,cursor,reader)
  local chain=require('code/native/chain').install(remote.interface.chain(),router,platform,
    function(event)
      if quicksave.active and (event.kind=='down' or event.kind=='char') then quicksave:cancel() end
      return view:input(event)
    end,function(message,_,lparam)
      if pointer:observe(message,lparam) then quicksave:cancel();navigation:cancel() end
    end)
  local inputFrame=require('code/native/input_frame').install(cursor,router,camera,quicksave)
  local runtime={lock=lock,platform=platform,scene=scene,catalog=catalog,router=router,
    profiles=profiles,view=view,chain=chain,cursor=cursor,navigation=navigation,
    inputFrame=inputFrame,quicksave=quicksave,pointer=pointer,targeting=targeting,camera=camera,worldActions=worldActions,pins={}}
  local main=api.ui.Menu:fromPointer(remote.interface.menuAddress(41),41)
  local count=main.menuItemsCount
  assert(count>=1 and count<=4096,'menu.main-size')
  -- Preserve all current entries (including another extension's additions).
  -- Explicit allocation avoids the UI count-constructor/reallocation defects.
  local items=ffi.new('MenuItem[?]',count+3)
  ffi.copy(items,main.menuItems,count*ffi.sizeof('MenuItem'))
  local action=ffi.cast('void (__cdecl *)(int)',function()
    local ok,problem=pcall(view.open,view)
    if not ok then log(ERROR,tostring(problem)) end
  end)
  local render=ffi.cast('void (__cdecl *)(int)',function()
    -- Painting remains visible when another window has focus. Eligibility is
    -- checked separately when the native control attempts an action.
    local s=scene:snapshot()
    if s.screen~=41 or s.modal~=-1 or s.modal2~=-1 or s.modal3~=-1 then return end
    local s=game.Rendering.ButtonState
    local old=game.Rendering.pDrawBufferChoiceValue[0]
    game.Rendering.pDrawBufferChoiceValue[0]=0
    local ok,problem=pcall(function()
      game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore,s.x,s.y,s.x+s.width,s.y+s.height,0x14)
      view:draw(view.labels('title'),s.x+6,s.y+5,nil,nil,s.width-12,'main-entry')
      if items[count+1].hovering~=0 then
        -- The native main menu already owns this help rectangle (item1,
        -- menu-local155,490,335x85). Paint only while our entry owns hover.
        local x=tonumber(main.pMenu.xPosition)+155
        local y=tonumber(main.pMenu.yPosition)+490
        game.Rendering.drawColorBox(game.Rendering.pencilRenderCore,x,y,x+334,y+84,0)
        view:draw(view.labels('mainHelp1'),x+6,y+8,nil,nil,323,'main-help-1')
        view:draw(view.labels('mainHelp2'),x+6,y+32,nil,nil,323,'main-help-2')
      end
    end)
    game.Rendering.pDrawBufferChoiceValue[0]=old
    if not ok then log(ERROR,tostring(problem)) end
  end)
  items[count]={menuItemType=0x01000000,menuItemActionHandler={simple=action},
    menuItemRenderFunction={simple=render},menuPointer=main.pMenu}
  items[count+1]={menuItemType=0x02000003,menuItemRenderFunctionType=1,
    -- The knight's native Bink animation repaints the right column. Use the
    -- gap below the last main button and above the original y=490 hit area.
    position={position={x=155,y=462}},itemWidth=335,itemHeight=24,
    callbackParameter={parameter=1},menuPointer=main.pMenu}
  items[count+2].menuItemType=0x66
  -- Group callbacks must be resolved by the native constructor, as for the
  -- UI owner's explicit-array menu creation. Keep the current menu object.
  game.UI.Menu(main.pMenu,items)
  runtime.pins={main,items,action,render}
  return runtime
end
return M
