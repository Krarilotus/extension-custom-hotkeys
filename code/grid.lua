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
  -- Native building icons have different heights. Their top edge is not a
  -- grid row: e.g. the short ox tether would sort before the taller woodcutter.
  -- Group vertically overlapping rectangles, then read each band left to right.
  local ordered,index={},1
  while index<=#commands do
    local band={commands[index]}
    local bottom=commands[index].y+(commands[index].height or 1)
    index=index+1
    while index<=#commands and commands[index].y<bottom do
      local row=commands[index];band[#band+1]=row
      bottom=math.max(bottom,row.y+(row.height or 1));index=index+1
    end
    table.sort(band,function(a,b) return a.x==b.x and a.y<b.y or a.x<b.x end)
    for _,row in ipairs(band) do ordered[#ordered+1]=row end
  end
  commands=ordered
  -- Overlapping controls have no unambiguous visual slot.
  for i=2,#commands do
    if commands[i].x==commands[i-1].x and commands[i].y==commands[i-1].y then return nil end
  end
  local row=commands[slot]
  if not row or row.disabled then return nil end
  return row.address
end
return M
