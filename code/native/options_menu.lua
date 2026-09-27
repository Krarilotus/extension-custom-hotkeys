-- Extend the game's two Options roots. Recorder extends Pause (modal 5), not
-- either Options root (12/44), so its replay control keeps its own position.
local ffi=require('ffi')
local Skin=require('code/native/editor_skin')
local M={}
local layouts={
  [12]={parameters={25,4,5,17},positions={[25]=100,[4]=135,[5]=170,[17]=250},buttonY=205},
  [44]={parameters={25,4,5,45,17,2,9},
    positions={[25]=120,[4]=152,[5]=184,[45]=216,[17]=280,[2]=88,[9]=312},buttonY=248},
}

local function extend(id,scene,view)
  local layout=layouts[id]
  local pointer=assert(remote.interface.modalMenuAddress(id),'hotkeys.options-menu-missing')
  local menu=api.ui.Menu:fromPointer(pointer,id)
  local count=menu.menuItemsCount
  -- Native menu groups are callbacks, not buttons. Check the current menu
  -- composition before moving its existing rows or installing a new group.
  assert(count==#layout.parameters+(id==44 and 2 or 1),'hotkeys.options-menu-shape')
  local original=menu.menuItems
  local back
  local seen={}
  for i=0,count-1 do
    local row=original[i]
    if tonumber(row.menuItemType)==0x02000003 then
      local parameter=tonumber(row.callbackParameter.parameter)
      assert(layout.positions[parameter] and not seen[parameter],'hotkeys.options-menu-control')
      seen[parameter]=true
      if parameter==17 then back=i end
    else
      assert(tonumber(row.menuItemType)==0x01000000,'hotkeys.options-menu-group')
    end
  end
  for _,parameter in ipairs(layout.parameters) do assert(seen[parameter],'hotkeys.options-menu-control') end
  assert(back,'hotkeys.options-menu-back')
  local items=ffi.new('MenuItem[?]',count+4)
  for i=0,count-1 do
    local target=i<back and i or i+3
    items[target]=original[i]
    if tonumber(items[target].menuItemType)==0x02000003 then
      local parameter=tonumber(items[target].callbackParameter.parameter)
      items[target].position.position.y=layout.positions[parameter]
    end
  end
  local action=ffi.cast('void (__cdecl *)(int)',function()
    local ok,problem=pcall(view.open,view)
    if not ok then log(ERROR,tostring(problem)) end
  end)
  local render=ffi.cast('void (__cdecl *)(int)',function()
    local snapshot=scene:snapshot()
    if snapshot.modal~=id or snapshot.activeModalID~=id or snapshot.activeModalMenu~=pointer then return end
    local ok,problem=pcall(function()
      local hover=tonumber(items[back+1].hovering)~=0
      Skin.button(false)
      local label=view:layout('options-hotkeys',view.labels('title'),284,18).text
      Skin.caption(label,hover and Skin.selectedText or Skin.text,hover and 2 or 4)
    end)
    if not ok then log(ERROR,tostring(problem)) end
  end)
  items[back]={menuItemType=0x01000000,menuItemActionHandler={simple=action},
    menuItemRenderFunction={simple=render},menuPointer=menu.pMenu}
  items[back+1]={menuItemType=0x02000003,menuItemRenderFunctionType=1,
    position={position={x=100,y=layout.buttonY}},itemWidth=300,itemHeight=27,
    callbackParameter={parameter=1},menuPointer=menu.pMenu}
  -- Restore the original Options group for Back and its following controls.
  items[back+2]=original[0]
  items[count+3].menuItemType=0x66
  game.UI.Menu(menu.pMenu,items)
  return {menu,items,action,render}
end

function M.install(scene,view)
  return {extend(12,scene,view),extend(44,scene,view)}
end
return M
