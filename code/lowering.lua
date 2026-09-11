local Context=require('code/context')
local M={}
M.__index=M
function M.new(adapter) return setmetatable({adapter=adapter,active=false},M) end
function M:start(context)
  if self.active or not context or context.state~='live-sp'
      or (context.owner~='game.build' and context.owner~='game.status')
      or not Context.same(context,Context.resolve(self.adapter.resolve()))
      or not self.adapter.available() then return false end
  -- Own the input before native entry, so uncertain calls can be cancelled.
  self.active=true;self.context=context
  self.adapter.setV(true)
  self.adapter.lower(3)
  return true
end
function M:beforeFrame(context)
  if not self.active then return end
  if not Context.same(self.context,context) then self:release();return end
  -- Native modifier polling clears V when a different rebound key is held.
  -- Reassert only our local input flag, after that poll and before native input.
  self.adapter.setV(true)
end
function M:release()
  if not self.active then return end
  self.active=false
  local context=self.context
  self.context=nil
  -- Clear our flag even if proving another native owner fails during focus loss.
  self.adapter.setV(false)
  local native=self.adapter.nativeVHeld(context)==true
  if native then self.adapter.setV(true) end
  if not native and not self.adapter.otherNativeHold(context) then self.adapter.lower(4) end
end
return M
