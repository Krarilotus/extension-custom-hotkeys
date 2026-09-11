local M={}
M.__index=M
local directions={up={0,-1},down={0,1},left={-1,0},right={1,0}}
function M.new(cursor,navigation,rectangle)
  return setmetatable({cursor=cursor,navigation=navigation,rectangle=rectangle},M)
end
function M:inside()
  local x,y=self.cursor.adapter.position()
  local left,top,width,height=self.rectangle()
  return left~=nil and x>=left and y>=top and x<left+width and y<top+height
end
function M:dispatch(id,context)
  if not context or (context.owner~='game.build' and context.owner~='game.status') then return false end
  local left,top,width,height=self.rectangle()
  if not left then return false end
  if id=='target.confirm' or id=='target.cancel' then
    return self.cursor:click(id=='target.confirm' and 'left' or 'right',context,
      function() return self:inside() end)
  end
  if self.cursor.pending then return false end
  local x,y=self.cursor.adapter.position()
  if id=='target.center' then x,y=left+math.floor(width/2),top+math.floor(height/2)
  else
    local direction=id:match('^target%.([a-z]+)$') or id:match('^target%.fine%.([a-z]+)$')
    local step=id:find('.fine.',1,true) and 1 or 24
    local d=directions[direction]
    if not d then return false end
    x,y=x+d[1]*step,y+d[2]*step
  end
  -- Stay away from edge-scroll strips; movement itself never selects or orders.
  x=math.max(left+24,math.min(left+width-25,x))
  y=math.max(top+24,math.min(top+height-25,y))
  self.navigation:cancel()
  return self.cursor:moveTo(x,y,context)
end
return M
