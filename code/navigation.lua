-- Focus only controls returned by the active native interaction traversal.
-- Activation is a native cursor gesture, with eligibility checked again at
-- the input frame. Cached rows never authorize a hidden or disabled control.
local Context=require('code/context')
local M={}
M.__index=M
function M.new(adapter,cursor)
  return setmetatable({adapter=adapter,cursor=cursor},M)
end
function M:current(context)
  if not Context.same(self.context,context) then self.context=context;self.address=nil end
  local rows=self.adapter.controls(context)
  if not rows then self.address=nil;return nil end
  return rows
end
function M:move(delta,context)
  if delta~=1 and delta~=-1 then return false end
  local rows=self:current(context)
  if not rows or #rows==0 then return false end
  local index=delta==1 and 0 or 1
  for i,row in ipairs(rows) do if row.address==self.address then index=i;break end end
  local row=rows[(index+delta-1)%#rows+1]
  local x,y=self.adapter.point(row)
  if not x or not self.cursor:moveTo(x,y,context) then return false end
  self.address=row.address
  return true
end
function M:activate(context)
  local rows=self:current(context)
  if not rows or not self.address then return false end
  local expected
  for _,row in ipairs(rows) do if row.address==self.address then expected=row;break end end
  if not expected then self.address=nil;return false end
  local x,y=self.adapter.point(expected)
  if not x or not self.cursor:moveTo(x,y,context) then return false end
  local address=self.address
  local kind,parameter,action,help=expected.kind,expected.parameter,expected.action,expected.help
  return self.cursor:click('left',context,function(now)
    local current=self.adapter.controls(now)
    if not current then return false end
    for _,row in ipairs(current) do
      if row.address==address then
        local currentX,currentY=self.adapter.point(row)
        return currentX==x and currentY==y and row.kind==kind
          and row.parameter==parameter and row.action==action and row.help==help
      end
    end
    return false
  end,function() return not self.adapter.hit or self.adapter.hit(address)==true end)
end
function M:activateMatching(selector,context)
  if self.cursor.pending then return false end
  local rows=self:current(context)
  if not rows then return false end
  local found
  for _,row in ipairs(rows) do
    if row.action==selector.action and row.parameter==selector.parameter
        and (selector.help==nil or row.help==selector.help)
        and row.kind==(selector.kind or 3) then
      -- Ambiguous controls are not resolved by arbitrary traversal order.
      if found then return false end
      found=row.address
    end
  end
  if not found then return false end
  self.address=found
  return self:activate(context)
end
function M:activateGrid(slot,selectors,context)
  if self.cursor.pending or not self.adapter.gridControls then return false end
  local rows=self.adapter.gridControls(context)
  local address=require('code/grid').select(rows,selectors,slot)
  if not address then return false end
  self.context=context;self.address=address
  -- Normal activation re-reads enabled controls, then checks identity and hit
  -- testing again at the native input frame before submitting the click.
  return self:activate(context)
end
function M:cancel() self.address=nil;self.context=nil;self.cursor:cancel() end
return M
