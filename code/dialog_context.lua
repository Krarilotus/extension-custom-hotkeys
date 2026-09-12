-- These inspected dialogs contain buttons/sliders, not text editors. Check
-- their active composition and the UI registry identity, never a hidden menu.
local M={}
-- Original button/slider dialogs: pause, video, sound, confirmation, options,
-- gameplay and main options. Save/name/chat/editor dialogs are text owners.
local standard={ [5]=true,[6]=true,[7]=true,[11]=true,[12]=true,[13]=true,[44]=true }
local menus={}
function M.bind(lookup)
  menus={}
  for id in pairs(standard) do menus[id]=lookup(id) end
  menus[2025]=lookup(2025) -- optional Automarket owner
end
function M.owns(s)
  if type(s)~='table' or s.textEditor~=0 or not require('code/modal_context').background(s) then return false end
  local menu=menus[s.modal]
  local parent=s.screen==41 or s.screen==14 or s.screen==16
  return parent and menu~=nil and s.activeModalID==s.modal and s.activeModalMenu==menu
    and ((standard[s.modal] and s.textModal==s.modal)
      or (s.modal==2025 and s.screen~=41 and s.textModal==0))
end
function M.origin(s)
  if not M.owns(s) then return nil end
  return require('code/modal_origin').read(s)
end
return M
