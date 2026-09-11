local Binding = require('code/binding')
local Context = require('code/context')
local Catalog = require('code/catalog')
local M = {}
M.__index = M

-- Native adapter owns eligibility resolution, validated action submission and
-- cancellation of local holds. It must not generate messages through GetMainProc.
function M.new(catalog, bindings, adapter)
  assert(type(adapter.resolve) == 'function' and type(adapter.dispatch) == 'function'
    and type(adapter.recover) == 'function' and type(adapter.canRecover) == 'function'
    and type(adapter.cancelLocalHold) == 'function', 'adapter.required')
  local self = setmetatable({catalog=catalog, adapter=adapter, held={}, charBlocked={}, blocked=false}, M)
  assert(self:apply(bindings))
  return self
end

function M:barrier()
  if self.adapter.cancelPending then self.adapter.cancelPending() end
  for _, held in pairs(self.held) do
    held.blocked = true
    self:cancelHold(held)
  end
  self:cancelCapture()
  self.context = nil
end

function M:cancelCapture()
  local callback = self.capture
  self.capture = nil
  if callback then
    local ok = pcall(callback, nil, 'capture.cancel')
    if not ok then self.blocked = true end
  end
end

function M:cancelHold(held)
  if not held.localHold then return end
  local action = held.localHold
  held.localHold = nil
  -- Cancellation only releases local input ownership, including when the old
  -- screen is already gone. It must never submit a simulation command.
  local wasDispatching = self.dispatching
  self.dispatching = true
  local ok = pcall(self.adapter.cancelLocalHold, action)
  self.dispatching = wasDispatching
  if not ok then self.blocked = true end
end

function M:apply(bindings)
  local normalized, err, detail = Catalog.validate(self.catalog, bindings)
  if not normalized then return nil, err, detail end
  self:barrier()
  self.bindings, self.index = normalized, {}
  for id, binding in pairs(normalized) do
    if binding then
      local key = Binding.key(binding)
      self.index[key] = self.index[key] or {}
      table.insert(self.index[key], self.catalog.actions[id])
    end
  end
  return true
end

function M:startCapture(callback)
  self:barrier()
  self.capture = callback
end

function M:readContext()
  local ok, facts = pcall(self.adapter.resolve)
  return ok and Context.resolve(facts) or nil
end

function M:refresh()
  local current = self:readContext()
  if not current or current.owner ~= 'hotkeys.capture' then self:cancelCapture() end
  if not Context.same(self.context, current) then
    if self.adapter.cancelPending then self.adapter.cancelPending() end
    -- A change cancels gestures, but preserves down/up forwarding ownership.
    for _, held in pairs(self.held) do held.blocked = true; self:cancelHold(held) end
    self.context = current
  end
  return current
end

function M:handle(event)
  if self.dispatching then
    return event.kind == 'down' or event.kind == 'up' or event.kind == 'char'
  end
  if event.kind == 'barrier' then self:barrier(); return false end
  if type(event.scan) ~= 'number' or event.scan < 1 or event.scan > 127
      or event.scan ~= math.floor(event.scan) or type(event.extended) ~= 'boolean' then
    self:barrier(); return false
  end
  local physical = Binding.physical(event.scan, event.extended)
  local context = self:refresh()
  local held = self.held[physical]
  if event.kind == 'up' then
    if held then self:cancelHold(held) end
    if held then self.charBlocked[physical] = held.consumed or held.blocked end
    self.held[physical] = nil
    return held ~= nil and held.consumed == true
  end
  if event.kind == 'char' then
    return (held ~= nil and (held.consumed or held.blocked)) or self.charBlocked[physical] == true
  end
  if event.kind ~= 'down' then return false end
  -- Windows may deliver the release to another focused window. Only a fresh
  -- native down (previous-state bit clear) may retire a quarantined gesture.
  -- Repeated downs still belong to the old gesture across every barrier.
  if held and held.blocked and event.repeated == false then
    self:cancelHold(held)
    self.held[physical] = nil
    held = nil
  end
  if held then
    if held.system then return false end
    return held.consumed or held.blocked
  end
  held = {consumed=false, blocked=false}
  self.held[physical] = held
  self.charBlocked[physical] = nil
  -- Unknown held keys on focus regain must never become a new activation.
  if event.repeated ~= false then held.blocked = true; return false end
  if event.win ~= false or event.altgr ~= false or event.composing ~= false then return false end
  if type(event.mods) ~= 'number' or event.mods ~= math.floor(event.mods)
      or event.mods < 0 or event.mods > 7 then return false end
  if Binding.system(event) then
    held.system = true
    if self.capture then self.capture(nil, 'binding.reserved') end
    return false
  end
  if not context then return false end
  if self.capture then
    if context.owner ~= 'hotkeys.capture' then self:cancelCapture(); return false end
    local binding, err = Binding.validate({scan=event.scan, extended=event.extended, mods=event.mods})
    held.consumed = true
    local callback = self.capture
    if event.scan == 1 and event.mods == 0 then
      self:barrier()
    elseif binding then
      self.capture = nil
      self:barrier(); callback(binding)
    else callback(nil, err) end
    return true
  end
  if Binding.recovery(event) then
    local now = self:readContext()
    if not Context.same(context, now) or self.adapter.canRecover(now) ~= true then
      self:barrier(); return false
    end
    held.consumed = true
    self.dispatching = true
    local ok = pcall(self.adapter.recover, now)
    self.dispatching = false
    self:barrier()
    if not ok then self.blocked = true end
    return true
  end
  if self.blocked then return false end
  local candidates = self.index[physical + 256 * event.mods] or {}
  local chosen
  for _, action in ipairs(candidates) do
    if Context.allows(action, context) then
      if chosen then return false end
      chosen = action
    end
  end
  if not chosen then
    for _, original in ipairs(self.catalog.originals) do
      if Binding.key(original.binding) == physical + 256 * event.mods
          and Context.allows(self.catalog.actions[original.action], context)
          and not Binding.same(self.bindings[original.action] or nil, original.binding) then
        if not Context.same(context, self:readContext()) then self:barrier(); return false end
        held.consumed = true
        return true
      end
    end
    return false
  end
  local now = self:readContext()
  if not Context.same(context, now) or not Context.allows(chosen, now) then
    self:barrier(); held.blocked = true; return false
  end
  -- Consume even a rejected native action: forwarding its original key would
  -- invoke a second, unrelated native shortcut. Never retry an uncertain call.
  held.consumed = true
  if chosen.behavior == 'hold-local' then held.localHold = chosen.id end
  self.dispatching = true
  local ok = pcall(self.adapter.dispatch, chosen.id, now)
  self.dispatching = false
  if not ok then self.blocked = true; self:barrier() end
  return true
end

return M
