-- The ordinary pause/options modal has eight buttons and no text field.
-- Check its actual active composition copy, never a registered hidden menu.
local M={}
function M.owns(s)
  return type(s)=='table' and (s.screen==14 or s.screen==16)
    and s.modal==5 and s.activeModalID==5 and s.activeModalMenu==0xb971f0
    and s.textModal==5 and s.textEditor==0 and s.modal2==-1 and s.modal3==-1
end
function M.origin(s)
  if not M.owns(s) then return nil end
  for _,key in ipairs({'modalX','modalY','modalWidth','modalHeight','modalBorder',
      'modalClosing','modalAnimation','viewOffsetX','viewOffsetY','width','height'}) do
    if type(s[key])~='number' or s[key]~=math.floor(s[key]) then return nil end
  end
  if s.modalClosing~=0 or s.modalAnimation~=0 or s.modalBorder<0
      or s.modalBorder>0xffff then return nil end
  -- renderMenuModal adds native viewport offsets on screens14/16. Border bit2
  -- consumes a twelve-pixel top strip before positioning the input menu.
  local x=s.modalX+s.viewOffsetX
  local y=s.modalY+s.viewOffsetY
  if math.floor(s.modalBorder/2)%2==1 then y=y+12 end
  if s.modalWidth<=0 or s.modalHeight<=0 or x<0 or y<0
      or x+s.modalWidth>s.width or y+s.modalHeight>s.height then return nil end
  return {menu=s.activeModalMenu,x=x,y=y}
end
return M
