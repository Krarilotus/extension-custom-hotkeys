-- One native input gesture at a time. The adapter feeds the game's existing
-- mouse-input boundary before its ordinary input frame; it never calls a
-- menu callback, command executor or world-coordinate conversion directly.
local Context=require('code/context')
local M={}
M.__index=M
function M.new(adapter)
  for _,name in ipairs({'resolve','position','bounds','busy','move','button','cancel'}) do
    assert(type(adapter[name])=='function','cursor.adapter')
  end
  return setmetatable({adapter=adapter},M)
end
local function integer(value)
  return type(value)=='number' and value==math.floor(value)
end
function M:valid(context,guard)
  local now=Context.resolve(self.adapter.resolve())
  return context~=nil and Context.same(context,now) and (not guard or guard(now)==true)
end
function M:moveTo(x,y,context)
  if self.pending or not self:valid(context) or self.adapter.busy() then return false end
  local width,height=self.adapter.bounds()
  if not integer(width) or not integer(height) or width<1 or height<1
      or not integer(x) or not integer(y) or x<0 or y<0 or x>=width or y>=height then
    return false
  end
  return self.adapter.move(x,y)~=false
end
function M:step(dx,dy,context)
  if not integer(dx) or not integer(dy) or math.abs(dx)>128 or math.abs(dy)>128 then return false end
  local x,y=self.adapter.position()
  local width,height=self.adapter.bounds()
  if not integer(x) or not integer(y) or not integer(width) or not integer(height)
      or width<17 or height<17 then return false end
  return self:moveTo(math.max(8,math.min(width-9,x+dx)),
    math.max(8,math.min(height-9,y+dy)),context)
end
function M:click(button,context,guard,ready)
  if self.pending or (button~='left' and button~='right')
      or not self:valid(context,guard) or self.adapter.busy() then return false end
  local x,y=self.adapter.position()
  if not integer(x) or not integer(y) then return false end
  self.pending={phase='aim',context=context,button=button,x=x,y=y,guard=guard,ready=ready}
  return true
end
function M:cancel()
  local pending=self.pending
  self.pending=nil
  -- Native reset must discard both edges, not generate an actionable release
  -- on the next screen. Never reset physical input if we had not pressed.
  if pending and (pending.phase=='release' or pending.phase=='drain') then self.adapter.cancel() end
end
function M:beforeFrame()
  local pending=self.pending
  if not pending then return end
  if not self:valid(pending.context,pending.guard) then self:cancel();return end
  if pending.phase=='aim' or pending.phase=='press' then
    if self.adapter.busy() then self:cancel();return end
    local x,y=self.adapter.position()
    if x~=pending.x or y~=pending.y then self:cancel();return end
    -- Let the ordinary native frame resolve hover/hit testing at the target
    -- before introducing a click edge. Fast Tab+Enter still gets an aim frame.
    if pending.phase=='aim' then pending.phase='press';return end
    if pending.ready and pending.ready()~=true then self:cancel();return end
    -- Mark ownership first, so an uncertain native failure cancels safely.
    pending.phase='release'
    self.adapter.button(pending.button,true)
  elseif pending.phase=='release' then
    pending.phase='drain'
    self.adapter.button(pending.button,false)
  else self.pending=nil end
end
return M
