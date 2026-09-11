local Context=require('code/context')
local M={}
M.__index=M
local directions={up=true,down=true,left=true,right=true}
function M.new(adapter)
  return setmetatable({adapter=adapter,held={},count=0},M)
end
function M:start(id,context)
  local direction=id:match('^camera%.pan%.([a-z]+)$') or id:match('^camera%.pan%.([a-z]+)%.alternate$')
  if not directions[direction] or not context or
      (context.owner~='game.build' and context.owner~='game.status') then return false end
  if self.held[id] then return false end
  self.held[id]={direction=direction,context=context};self.count=self.count+1
  self.adapter.set(direction,true)
  return true
end
function M:release(id)
  local held=self.held[id]
  if not held then return end
  self.held[id]=nil;self.count=self.count-1
  for _,other in pairs(self.held) do
    if other.direction==held.direction then return end
  end
  -- A native arrow may still own the same local input flag. Preserve it only
  -- when the adapter proves that its gesture is forwarded in this context.
  local native=self.adapter.nativeHeld and self.adapter.nativeHeld(held.direction,held.context)
  self.adapter.set(held.direction,native==true)
end
function M:beforeFrame(context)
  for id,held in pairs(self.held) do
    if not Context.same(held.context,context) then self:release(id)
    else self.adapter.set(held.direction,true) end
  end
end
return M
