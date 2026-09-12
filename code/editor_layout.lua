-- One geometry source for native hit boxes, painting and keyboard focus.
local M={width=760,height=552,rows=16,rowHeight=20,listY=114,listWidth=692,
  bodyFont=19,buttonFont=18,titleFont=17}
function M.controls(page)
  local result={}
  local function add(id,x,y,w,label,h)
    result[#result+1]={id=id,x=x,y=y,width=w,height=h or 26,label=label}
  end
  if page=='profiles' then
    add(118,584,18,156,'bindings')
    add(101,28,100,568,'profile');add(102,608,100,56,'<');add(103,676,100,56,'>')
    add(104,28,158,340,'new');add(116,28,204,340,'import')
    add(117,388,204,344,'export');add(110,28,264,340,'resetProfile')
  else
    add(118,494,18,246,'profile')
    add(105,20,60,470,'search');add(106,502,60,238,'groups')
    for row=1,M.rows do add(row,20,M.listY+(row-1)*M.rowHeight,M.listWidth,'',M.rowHeight) end
    add(107,20,448,150,'capture');add(108,180,448,116,'clear')
    add(109,306,448,154,'reset');add(115,470,448,150,'swap')
  end
  add(113,454,506,138,'apply');add(114,604,506,136,'cancel')
  return result
end
return M
