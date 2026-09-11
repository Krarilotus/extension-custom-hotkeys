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
  return require('code/modal_origin').read(s)
end
return M
