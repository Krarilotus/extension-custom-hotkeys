local A=require('code/addresses')
local M={}
function M.next(s,index)
  if type(index)~='number' or index~=math.floor(index) or index<0 or index>=s.loadCount then return nil end
  local relative=index-s.loadOffset
  local distance=relative<0 and -relative or relative-s.loadRows+1
  if relative<0 or relative>=s.loadRows then
    local direction=relative<0 and -1 or 1
    local page=distance>=s.loadRows-1
    local step=page and s.loadRows-1 or 1
    return {action=page and A.loadScrollAction or A.loadAction,kind=page and 6 or 2,
      parameter=page and 0 or (direction<0 and -1 or -2),direction=direction,
      offset=math.max(0,math.min(s.loadCount-s.loadRows,s.loadOffset+direction*step))}
  end
  if s.loadSelected~=relative then
    return {action=A.loadRowAction,kind=3,parameter=relative,selected=relative}
  end
  return {action=A.loadAction,kind=3,parameter=2,commit=true}
end
return M
