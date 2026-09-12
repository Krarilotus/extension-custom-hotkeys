local A=require('code/addresses')
local ffi=require('ffi')
local Traversal=require('code/menu_traversal')
local M={}
M.__index=M
local function n(value) return tonumber(value) end
function M.new(manager)
  return setmetatable({manager=manager},M)
end
function M:read(menuAddress, state, origin,includeDisabled)
  if not menuAddress or menuAddress==0 then return nil,'menu.missing' end
  local menu=ffi.cast('Menu *',menuAddress)
  local array=menu[0].menuItemArray
  if array==nil then return nil,'menu.missing' end
  local count
  for i=0,4095 do if n(array[i].menuItemType)==0x66 then count=i+1;break end end
  if not count then return nil,'menu.sentinel' end
  local active,err=Traversal.active(function(index)
    local r=array[index-1]
    return {type=n(ffi.cast('uint32_t',r.menuItemType)),parameter=n(r.callbackParameter.parameter),
      skip=n(r.firstItemTypeData.itemsToSkip),condition=n(r.field9_0x28),
      disabled=n(r.iconDeactivated_0x36),inactive=n(r.field15_0x38)}
  end,count,state,includeDisabled)
  if not active then return nil,err end
  local rows={}
  for _,index in ipairs(active) do
    local r=array[index-1]
    -- Native input and rendering use each item's owner, which may differ from
    -- the active registry Menu when multiple Menu objects share the array.
    local owner=r.menuPointer
    if owner==nil or owner[0].menuItemArray~=array then return nil,'menu.owner' end
    if n(owner[0].currentBuildMenuButtonShift_0x14)~=0 then return nil,'menu.shifted' end
    local baseX,baseY=n(owner[0].xPosition),n(owner[0].yPosition)
    if origin then
      if origin.menu~=menuAddress or n(ffi.cast('uintptr_t',owner))~=menuAddress then
        return nil,'menu.owner'
      end
      baseX,baseY=origin.x,origin.y
    end
    local x=baseX+n(r.position.position.x)
    local y=baseY+n(r.position.position.y)
    local width,height=n(r.itemWidth),n(r.itemHeight)
    local action=n(ffi.cast('uintptr_t',r.menuItemActionHandler.simple))
    -- 0x440410 only clears the interaction return flag. Its rectangle is the
    -- bottom help/cost display, not a selectable action.
    if action~=0 and action~=A.ignoreMenuAction and width>0 and height>0 and width<=state.width and height<=state.height
        and x>=0 and y>=0 and x+width<=state.width and y+height<=state.height then
      rows[#rows+1]={index=index,address=n(ffi.cast('uintptr_t',array+index-1)),
        x=x,y=y,width=width,height=height,parameter=n(r.callbackParameter.parameter),
        action=action,
        help=n(ffi.cast('uint32_t *',ffi.cast('uint8_t *',array+index-1)+0x2c)[0]),
        control=n(r.ucId_0x30),kind=n(r.menuItemType)%0x800000,
        disabled=n(r.iconDeactivated_0x36)~=0}
    end
  end
  return rows
end
return M
