local A=require('code/addresses')
-- The verified SHC1.41 Load dialog has a list, sorting and buttons, no text field.
-- Save10, confirmation11 and the map/lobby editors are different owners.
local M={}
local function integer(n,lo,hi)
  return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi
end
function M.owns(s)
  local valid=type(s)=='table' and (s.screen==14 or s.screen==16)
    and s.modal==9 and s.activeModalID==9 and s.activeModalMenu==A.loadMenu
    and s.loadArray==A.loadItems and s.textModal==9 and s.textEditor==0
    and s.modal2==-1 and s.modal3==-1 and s.textIndex==4 and s.textState==1
    and integer(s.loadCount,0,500) and s.loadRows==16
    and integer(s.loadOffset,0,math.max(0,s.loadCount-1))
    and integer(s.loadSelected,-1,15)
    and (s.loadSelected==-1 or s.loadOffset+s.loadSelected<s.loadCount)
    and type(s.loadIdentity)=='string' and #s.loadIdentity==s.loadCount*4
  if not valid then return false end
  for i=1,#s.loadIdentity,4 do
    local a,b,c,d=s.loadIdentity:byte(i,i+3)
    if a+b*256+c*65536+d*16777216>499 then return false end
  end
  return true
end
function M.origin(s)
  if not M.owns(s) then return nil end
  return require('code/modal_origin').read(s)
end
function M.identity(s)
  return table.concat({s.loadCount,s.loadOffset,s.loadSelected},':')..':'..s.loadIdentity
end
function M.controls(rows,s)
  if not M.origin(s) or not rows then return nil end
  local out={}
  for _,row in ipairs(rows) do
    local p=row.parameter
    if row.action==A.loadRowAction and row.kind==3 and integer(p,0,15) then
      if s.loadOffset+p<s.loadCount then out[#out+1]=row end
    elseif row.action==A.loadAction then
      if row.kind==3 and (p==17 or (p==2 and s.loadSelected~=-1))
          or row.kind==2 and ((p==-1 and s.loadOffset>0)
            or (p==-2 and s.loadOffset<math.max(0,s.loadCount-s.loadRows))) then
        out[#out+1]=row
      end
    elseif row.action==A.loadSortAction and row.kind==3 and (p==0 or p==1) then
      out[#out+1]=row
    end
    -- Scrollbar dragging and any newly injected/unverified controls stay mouse-only.
  end
  return out
end
return M
