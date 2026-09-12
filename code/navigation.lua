-- Focus only controls returned by the active native interaction traversal.
-- Simple buttons invoke their native handler at the input frame without moving
-- the pointer. Sliders retain their positional native gesture semantics.
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
  if self.pending or self.cursor.pending then return false end
  local rows=self:current(context)
  if not rows or not self.address then return false end
  local expected
  for _,row in ipairs(rows) do if row.address==self.address then expected=row;break end end
  if not expected then self.address=nil;return false end
  if self.adapter.invoke and (expected.kind==2 or expected.kind==3 or expected.kind==4) then
    if not self.cursor:valid(context) or self.cursor.adapter.busy() then return false end
    self.pending={context=context,address=expected.address,kind=expected.kind,
      parameter=expected.parameter,action=expected.action,help=expected.help}
    return true
  end
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
function M:adjust(delta,context)
  if (delta~=1 and delta~=-1) or self.pending or self.cursor.pending or not self.adapter.adjust then return false end
  for _,row in ipairs(self:current(context) or {}) do
    if row.address==self.address and row.kind==5 then
      if not self.cursor:valid(context) or self.cursor.adapter.busy() then return false end
      self.pending={context=context,address=row.address,kind=row.kind,parameter=row.parameter,
        action=row.action,help=row.help,delta=delta}
      return true
    end
  end
  return false
end
function M:beforeFrame()
  local pending=self.pending
  -- Retire before calling game code: callbacks can re-enter the input chain.
  self.pending=nil
  if not pending or not self.cursor:valid(pending.context) or self.cursor.adapter.busy() then return end
  for _,row in ipairs(self.adapter.controls(pending.context) or {}) do
    if row.address==pending.address and row.kind==pending.kind and row.action==pending.action
        and row.parameter==pending.parameter and row.help==pending.help then
      if pending.delta then self.adapter.adjust(row,pending.delta) else self.adapter.invoke(row) end
      return
    end
  end
end
function M:activateMatching(selector,context)
  if self.pending or self.cursor.pending then return false end
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
  if self.pending or self.cursor.pending or not self.adapter.gridControls then return false end
  local rows=self.adapter.gridControls(context)
  local address=require('code/grid').select(rows,selectors,slot)
  if not address then return false end
  self.context=context;self.address=address
  -- Re-read enabled controls and their identity again at the native input frame.
  return self:activate(context)
end
function M:cancel() self.pending=nil;self.address=nil;self.context=nil;self.cursor:cancel() end
return M
