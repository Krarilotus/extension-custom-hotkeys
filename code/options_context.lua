local A=require('code/addresses')
-- The ordinary pause/options modal has eight buttons and no text field.
-- Check its actual active composition copy, never a registered hidden menu.
local M={}
function M.owns(s)
  if type(s)~='table' or s.textEditor~=0 or not require('code/modal_context').background(s) then return false end
  if s.screen==41 then
    return s.modal==44 and s.activeModalID==44 and s.textModal==44
      and A.mainOptionsMenu~=nil and s.activeModalMenu==A.mainOptionsMenu
  end
  return (s.screen==14 or s.screen==16) and s.modal==5 and s.activeModalID==5
    and s.activeModalMenu==A.optionsMenu and s.textModal==5
end
function M.origin(s)
  if not M.owns(s) then return nil end
  return require('code/modal_origin').read(s)
end
return M
