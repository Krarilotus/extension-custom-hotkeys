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
  local catalog=Catalog.new(entries)
  local view
  local router=Router.new(catalog,Catalog.defaults(catalog),{
    resolve=function() return scene:resolve(view) end,
    dispatch=function(id)
      if id=='hotkeys.open' then return view:open() end
      error('action.not-integrated: '..id)
    end,
    canRecover=function(c) return c and c.owner:sub(1,5)=='menu.' end,
    recover=function() return view:open() end,
    cancelLocalHold=function() end,
  })
  local store={load=function() return remote.interface.loadProfiles() end,
    save=function(_,document) return remote.interface.saveProfiles(document) end}
  local profiles,err=Profiles.new(catalog,store,router)
  assert(profiles,err)
  view=View.new(profiles,catalog,router,scene,platform,require('code/locale').new(language))
  local chain=require('code/native/chain').install(remote.interface.chain(),router,platform,
    function(event) return view:input(event) end)
  local runtime={lock=lock,platform=platform,scene=scene,catalog=catalog,router=router,
    profiles=profiles,view=view,chain=chain,pins={}}
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
      view:draw(view.labels('title'),s.x+6,s.y+5)
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
