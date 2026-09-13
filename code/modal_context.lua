local M={}
-- Native MenuModalType130 is the persistent Extreme tactical-powers HUD.
-- It coexists with construction/unit panels; other secondary dialogs own input.
function M.background(s)
  return s.modal2==-1 and (s.modal3==-1
    or (s.modal3==130 and (s.screen==14 or s.screen==16)))
end
return M
