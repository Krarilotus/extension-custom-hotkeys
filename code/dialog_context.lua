local A=require('code/addresses')
-- These inspected dialogs contain buttons/sliders, not text editors. Check
-- their active composition and the UI registry identity, never a hidden menu.
local M={}
function M.owns(s)
  if type(s)~='table' or s.textEditor~=0 or not require('code/modal_context').background(s) then return false end
  if s.screen==41 then
    return s.modal==44 and s.activeModalID==44 and s.textModal==44
      and A.mainOptionsMenu~=nil and s.activeModalMenu==A.mainOptionsMenu
  end
  if (s.screen==14 or s.screen==16) and s.modal==2025 then
    -- Automarket 1.1 uses UI modal 2025 with native MenuItems, including its
    -- save/close callbacks and sliders. Reuse those controls and protocol owner.
    return s.activeModalID==2025 and s.textModal==0
      and A.automarketMenu~=nil and s.activeModalMenu==A.automarketMenu
  end
  return (s.screen==14 or s.screen==16) and s.modal==5 and s.activeModalID==5
    and s.activeModalMenu==A.optionsMenu and s.textModal==5
end
function M.origin(s)
  if not M.owns(s) then return nil end
  return require('code/modal_origin').read(s)
end
return M
