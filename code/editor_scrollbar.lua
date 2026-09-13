-- Native MenuItem type6 protocol, shared by original Save/Load scrollbars.
local M={}
function M.update(editor,operation,value,enabled)
  if not editor or not enabled then return 0,0,0 end
  local maximum=math.max(0,#editor.rows-editor.pageSize)
  local offset=editor.first-1
  if not editor.capturing then
    if operation==2 or operation==3 then editor:scroll(value)
    elseif operation==5 then editor:scroll(offset-1)
    elseif operation==6 then editor:scroll(offset+1) end
  end
  if operation==7 then return 0,maximum,math.max(1,editor.pageSize-1) end
  return 0,maximum,editor.first-1
end
return M
