-- One sparse dictionary per UCP config: custom-hotkeys.config.bindings.<module>.<action>
-- holds explicit chords and explicit clears (false). Absent actions inherit a
-- plugin suggestion, then the layout or provider default, on every launch.
local Catalog = require('code/catalog')
local Binding = require('code/binding')
local Context = require('code/context')
local M = {}
M.__index = M
M.owner = 'custom-hotkeys'
M.defaultLayout = 'game-default'

local function copy(value)
  if type(value) ~= 'table' then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

-- Config path below `bindings`. Provider IDs follow ext.<module>.<action>;
-- built-in actions belong to this module.
function M.path(id)
  local provider, action = id:match('^ext%.([^.]+)%.([^.]+)$')
  if provider then return {provider, action} end
  local path = {M.owner}
  for part in id:gmatch('[^.]+') do path[#path + 1] = part end
  return path
end

-- Path below custom-hotkeys.config.
function M.configPath(id)
  local path = {'bindings'}
  for _, key in ipairs(M.path(id)) do path[#path + 1] = key end
  return path
end

local function lookup(tree, path)
  for _, key in ipairs(path) do
    if type(tree) ~= 'table' then return nil end
    tree = tree[key]
  end
  return tree
end

local function entry(value)
  if value == false then return false end
  return Binding.validate(value) or nil
end

-- The launcher stores user values in config-sparse; the framework loads
-- config-full, which also contains plugin suggestions and required values.
function M.explicitTree(userConfig, normalize, deproxy)
  local ok, tree = pcall(function() return userConfig['config-sparse'].modules[M.owner].config end)
  if not ok or type(tree) ~= 'table' then return {} end
  local result = deproxy(tree)
  normalize(result)
  return result
end

-- Reads this launch's catalog actions from the explicit (user) and effective
-- config trees. The effective tree repeats explicit values, so only actions
-- without an explicit entry carry a plugin suggestion. An effective value that
-- differs from the explicit one is a launcher-required value.
function M.source(catalog, explicitTree, effectiveTree)
  local result = {explicit={}, suggested={}, locked={}, ignored={}}
  explicitTree = type(explicitTree) == 'table' and explicitTree or {}
  effectiveTree = type(effectiveTree) == 'table' and effectiveTree or {}
  for _, action in ipairs(catalog.ordered) do
    local id, path = action.id, M.path(action.id)
    local mine, effective = lookup(explicitTree.bindings, path), entry(lookup(effectiveTree.bindings, path))
    if mine == nil then
      result.suggested[id] = effective
    elseif effective ~= nil and not Binding.equal(effective, entry(mine)) then
      result.explicit[id], result.locked[id] = effective, true
    else
      result.explicit[id] = entry(mine)
      if result.explicit[id] == nil then result.ignored[#result.ignored + 1] = id end
    end
  end
  local mine, effective = explicitTree.layout, effectiveTree.layout
  if type(mine) == 'string' then
    result.layout = type(effective) == 'string' and effective or mine
    result.layoutLocked = result.layout ~= mine
  elseif type(effective) == 'string' then result.suggestedLayout = effective end
  return result
end

-- Legacy entries apply only where the config has no entry of its own,
-- including entries of modules that are not enabled now.
function M.unclaimed(legacy, explicitTree)
  if not legacy then return nil end
  explicitTree = type(explicitTree) == 'table' and explicitTree or {}
  local result = {explicit={}, layout=explicitTree.layout == nil and legacy.layout or nil}
  for id, value in pairs(legacy.explicit) do
    if lookup(explicitTree.bindings, M.path(id)) == nil then result.explicit[id] = value end
  end
  return result
end

function M.layoutOf(catalog, document, suggestedLayout)
  local layout = document.layout or suggestedLayout
  if catalog.presets and catalog.presets[layout] then return layout end
  return catalog.presets and M.defaultLayout or nil
end

-- Layers rank required > explicit > suggested > layout or provider default;
-- within a rank the earlier action in catalog order (built-ins in declaration
-- order, then providers by ID) comes first. A colliding action lower in that
-- order is unbound, and an action on a native chord whose owner still needs
-- it yields. Unbound actions are then retried in that order, repeatedly,
-- because the action that displaced them, or a native key's owner, may have
-- moved since; a retried action may displace one below it. Explicit and
-- required entries that stay unbound are returned as set aside.
function M.resolve(catalog, layout, suggested, explicit, locked)
  locked = locked or {}
  local preset = catalog.presets and catalog.presets[layout]
  local bindings = copy(preset and preset.bindings or Catalog.defaults(catalog))
  local rank, wanted, index = {}, {}, {}
  for position, action in ipairs(catalog.ordered) do
    local id = action.id
    if explicit[id] ~= nil then bindings[id], rank[id] = copy(explicit[id]), locked[id] and 4 or 3
    elseif suggested[id] ~= nil then bindings[id], rank[id] = copy(suggested[id]), 2
    else rank[id] = 1 end
    wanted[id], index[id] = bindings[id], position
  end
  local function before(a, b) return rank[a] > rank[b] or (rank[a] == rank[b] and index[a] < index[b]) end
  local losers, lost = {}, {}
  local function unbind(id)
    bindings[id] = false
    if not lost[id] then lost[id] = true; losers[#losers + 1] = id end
  end
  for _ = 0, #catalog.ordered do
    local valid, problem, detail = Catalog.validate(catalog, bindings)
    if valid then bindings = valid; break end
    local ids = type(detail) == 'table' and detail or {detail}
    local loser = ids[1]
    if problem == 'binding.conflict' and before(loser, ids[2]) then loser = ids[2] end
    assert(loser and bindings[loser], problem)
    unbind(loser)
  end
  bindings = assert(Catalog.validate(catalog, bindings), 'bindings.resolve')
  for _ = 1, #catalog.ordered do
    table.sort(losers, before)
    local changed = false
    for _, id in ipairs(losers) do
      if bindings[id] == false and wanted[id] then
        bindings[id] = copy(wanted[id])
        local valid, problem, detail = Catalog.validate(catalog, bindings)
        local other = type(detail) == 'table' and (detail[1] == id and detail[2] or detail[1]) or nil
        if not valid and problem == 'binding.conflict' and other and before(id, other) then
          local kept = bindings[other]
          bindings[other] = false
          valid = Catalog.validate(catalog, bindings)
          if valid then unbind(other) else bindings[other] = kept end
        end
        if valid then bindings, changed = valid, true else bindings[id] = false end
      end
    end
    if not changed then break end
  end
  local aside = {}
  table.sort(losers, before)
  for _, id in ipairs(losers) do
    if bindings[id] == false and rank[id] >= 3 and wanted[id] then aside[#aside + 1] = id end
  end
  return bindings, aside
end

local function document(value) return {layout=value.layout, explicit=copy(value.explicit)} end

-- store:save(changes) writes the listed explicit entries into the active
-- config; `inherited` is the plugin suggestion an effective entry falls back to.
function M.new(catalog, source, store, router)
  local self = setmetatable({catalog=catalog, store=store, router=router,
    suggested=source.suggested or {}, suggestedLayout=source.suggestedLayout,
    locked=source.locked or {}, layoutLocked=source.layoutLocked}, M)
  self.saved = {layout=source.layout, explicit=copy(source.explicit or {})}
  local current = document(self.saved)
  if source.legacy then
    for id, value in pairs(source.legacy.explicit) do
      if current.explicit[id] == nil then current.explicit[id] = copy(value) end
    end
    if current.layout == nil and source.legacy.layout ~= M.layoutOf(catalog, {}, self.suggestedLayout) then
      current.layout = source.legacy.layout
    end
  end
  self.committed = self:derive(current)
  if source.legacy then
    -- Entries not written now stay pending against the saved baseline, so the
    -- next successful Apply writes them.
    local changes = self:changes(self.saved, current)
    local saved, problem = true, nil
    if #changes > 0 then saved, problem = store:save(changes) end
    if saved then self.saved = document(current) end
    self.migration = {saved=saved == true, problem=problem}
  end
  assert(router:apply(self.committed.bindings, {nativeAliases=self.committed.active == M.defaultLayout}))
  return self
end

function M:derive(value)
  local active = M.layoutOf(self.catalog, value, self.suggestedLayout)
  local bindings, aside = M.resolve(self.catalog, active, self.suggested, value.explicit, self.locked)
  return {layout=value.layout, explicit=value.explicit, active=active, bindings=bindings, aside=aside}
end

function M:begin()
  self.router:barrier()
  self.draft = copy(self.committed)
  return copy(self.draft)
end

function M:cancel()
  self.draft = nil
  self.router:barrier()
end

-- Player edits are checked strictly against the current bindings, so a
-- conflict reaches the editor as a swap offer; the draft is then derived
-- from the sparse choices exactly as on the next launch.
local function edit(self, operation)
  if not self.draft then return nil, 'profiles.no-draft' end
  local candidate = copy(self.draft)
  local ok, err = operation(candidate)
  if not ok then return nil, err end
  local valid, problem, detail = Catalog.validate(self.catalog, candidate.bindings)
  if not valid then return nil, problem, detail end
  self.draft = self:derive(candidate)
  return true
end

local function assign(self, d, id, binding)
  if self.locked[id] then return false end
  -- A chord the player assigns replaces a parked preference for it.
  for _, other in ipairs(d.aside) do
    if other ~= id and not self.locked[other] and binding and Binding.equal(d.explicit[other], binding)
        and Context.overlap(self.catalog.actions[id], self.catalog.actions[other]) then
      d.explicit[other] = nil
    end
  end
  d.explicit[id] = copy(binding)
  d.bindings[id] = copy(binding)
  return true
end

function M:bind(action, binding)
  return edit(self, function(d)
    if not self.catalog.actions[action] then return nil, 'profile.unknown-action' end
    if not assign(self, d, action, binding) then return nil, 'binding.locked' end
    return true
  end)
end

-- Reassignment is atomic so neither binding is lost when a conflict is rejected.
function M:reassign(action, binding, displaced, replacement)
  return edit(self, function(d)
    if not self.catalog.actions[action] or not self.catalog.actions[displaced]
        or action == displaced then return nil, 'profile.unknown-action' end
    if not (assign(self, d, action, binding) and assign(self, d, displaced, replacement)) then
      return nil, 'binding.locked'
    end
    return true
  end)
end

-- Reset returns an action, or every action, to inheritance.
function M:reset(action)
  if action and not self.catalog.actions[action] then return nil, 'profile.unknown-action' end
  if action and self.locked[action] then return nil, 'binding.locked' end
  return edit(self, function(d)
    for _, item in ipairs(self.catalog.ordered) do
      if (not action or item.id == action) and not self.locked[item.id] then d.explicit[item.id] = nil end
    end
    d.bindings = M.resolve(self.catalog, d.active, self.suggested, d.explicit, self.locked)
    return true
  end)
end

function M:select(layout)
  if self.layoutLocked then return nil, 'binding.locked' end
  return edit(self, function(d)
    if not (self.catalog.presets and self.catalog.presets[layout]) then return nil, 'profiles.unknown' end
    d.layout = layout
    d.bindings = self:derive(d).bindings
    return true
  end)
end

function M:changes(before, after)
  local ids = {}
  for id in pairs(before.explicit) do ids[#ids + 1] = id end
  for id in pairs(after.explicit) do if before.explicit[id] == nil then ids[#ids + 1] = id end end
  table.sort(ids)
  local list = {}
  for _, id in ipairs(ids) do
    if not Binding.equal(before.explicit[id], after.explicit[id]) then
      list[#list + 1] = {path=M.configPath(id), value=copy(after.explicit[id]), inherited=self.suggested[id]}
    end
  end
  if before.layout ~= after.layout then
    list[#list + 1] = {path={'layout'}, value=after.layout, inherited=self.suggestedLayout}
  end
  return list
end

function M:apply()
  if not self.draft then return nil, 'profiles.no-draft' end
  local valid, err = Catalog.validate(self.catalog, self.draft.bindings)
  if not valid then return nil, err end
  self.router:barrier()
  local changes = self:changes(self.saved, self.draft)
  if #changes > 0 then
    local ok, problem = self.store:save(changes)
    if not ok then return nil, problem end
  end
  self.saved = document(self.draft)
  assert(self.router:apply(valid, {nativeAliases=self.draft.active == M.defaultLayout}))
  self.committed = self.draft
  self.draft = nil
  return true
end

return M
