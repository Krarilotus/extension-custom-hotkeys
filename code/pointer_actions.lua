-- Decide semantics only; native mouse handling and command submission own effects.
local M={}
function M.resolve(id,s)
  if id=='pointer.primary' then return 'left',false end
  if id=='pointer.secondary' then return 'right',false end
  if id=='pointer.order' then
    return s.selectedCount>0 and s.placement==0 and 'left' or 'right',false
  end
  if id=='pointer.select' then
    local selectOnly=s.selectedCount>0 and s.placement==0 and s.patrol==0
      and s.unitMode==1 and s.unitModeAux==1
    return 'left',selectOnly
  end
end
return M
