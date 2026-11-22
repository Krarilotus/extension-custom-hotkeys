local M={}
-- Native MenuModalType130 is the persistent Extreme tactical-powers HUD.
-- It coexists with construction/unit panels; other secondary dialogs own input.
function M.secondary(s)
  -- The AI lord video is a background overlay on the ordinary game viewport.
  if s.modal2==19 and (s.screen==14 or s.screen==16) and s.mode~=1
      and s.modal==-1 and s.textModal==0 and s.textEditor==0 then return -1 end
  return s.modal2
end
function M.background(s)
  return M.secondary(s)==-1 and (s.modal3==-1
    or (s.modal3==130 and (s.screen==14 or s.screen==16)))
end
-- Extended modal IDs are allocated through ui.manager. Require the current
-- registered Menu pointer and the actual foreground input composition.
function M.extensionOwns(s,registered)
  if s.modal<1000 or not registered[s.modal] or not M.background(s)
      or s.activeModalID~=s.modal or s.textModal~=0 or s.textEditor~=0 then return false end
  local origin=require('code/modal_origin').read(s)
  local menu=origin and registered[s.modal]()
  return menu~=nil and menu==origin.menu
end
return M
