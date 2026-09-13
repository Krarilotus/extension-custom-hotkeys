-- A bounded input workflow, never a save implementation. Native controls own
-- filename resolution, overwrite policy, serialization and session transitions.
local M={}
M.__index=M
function M.new(adapter)
  return setmetatable({adapter=adapter,active=false},M)
end
function M:start(context,action)
  if self.active then return false end
  local token=self.adapter.open(context,action)
  if not token then return false end
  self.token,self.phase,self.frames=token,action=='game.quickload' and 'load' or 'name',0
  self.limit=action=='game.quickload' and 900 or 90
  self.active=true
  return true
end
function M:cancel()
  if not self.active then return end
  self.active=false
  self.adapter.cancel()
  self.token,self.phase=nil,nil
end
function M:beforeFrame()
  if not self.active then return end
  self.frames=self.frames+1
  local kind=self.adapter.observe(self.token)
  if not kind or self.frames>self.limit then self:cancel();return end
  if kind=='progress' or kind=='done' then self:cancel();return end
  if self.phase=='load' then
    if kind~='load' then self:cancel();return end
    if not self.adapter.pending() and not self.adapter.loadStep(self.token) then self:cancel() end
  elseif self.phase=='name' then
    if kind~='name' then self:cancel();return end
    -- Mark before the native call: an uncertain failure is never retried.
    self.phase='submitted'
    if not self.adapter.submitName(self.token) then self:cancel() end
  elseif self.phase=='submitted' then
    if kind=='confirm' then
      self.phase='confirming'
      if not self.adapter.confirm(self.token) then self:cancel() end
    elseif kind~='name' then self:cancel() end
  elseif self.phase=='confirming' then
    if kind~='confirm' or not self.adapter.pending() then self:cancel() end
  end
end
return M
