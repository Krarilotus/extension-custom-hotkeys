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
return M
