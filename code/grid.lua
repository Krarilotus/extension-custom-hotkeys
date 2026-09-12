-- Positions come from the current native panel, including disabled buttons.
-- A disabled slot stays empty to input; it never shifts the remaining hotkeys.
local M={}
local categories={castle=true,industry=true,farms=true,town=true,weapons=true,food=true}
function M.select(rows,selectors,slot)
  if type(rows)~='table' or type(slot)~='number' or slot<1 or slot>12
      or slot~=math.floor(slot) then return nil end
  local commands={}
  for _,row in ipairs(rows) do
    for _,selector in ipairs(selectors) do
      local category=selector.id:match('^menu%.build%.(.+)$')
      if not categories[category] and row.kind==(selector.kind or 3)
          and row.action==selector.action and row.parameter==selector.parameter
          and row.help==selector.help then
        commands[#commands+1]=row;break
      end
    end
  end
  table.sort(commands,function(a,b) return a.y==b.y and a.x<b.x or a.y<b.y end)
  -- Overlapping controls have no unambiguous visual slot.
  for i=2,#commands do
    if commands[i].x==commands[i-1].x and commands[i].y==commands[i-1].y then return nil end
  end
  local row=commands[slot]
  if not row or row.disabled then return nil end
  return row.address
end
return M
