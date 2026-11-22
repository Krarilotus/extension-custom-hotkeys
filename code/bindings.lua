-- One sparse dictionary per UCP config: custom-hotkeys.config.bindings.<module>.<action>
-- holds explicit chords and explicit clears (false). Absent actions inherit a
-- plugin suggestion, then the layout or provider default, on every launch.
local Catalog = require('code/catalog')
local Binding = require('code/binding')
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

local function same(a, b)
  if a == b then return true end
  return type(a) == 'table' and type(b) == 'table' and Binding.same(a, b)
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
-- config-full, which also contains plugin suggestions.
function M.explicitTree(userConfig, normalize)
  local ok, tree = pcall(function() return userConfig['config-sparse'].modules[M.owner].config end)
  if not ok or type(tree) ~= 'table' then return {} end
  local result = copy(tree)
  normalize(result)
  return result
end

-- Reads this launch's catalog actions from the explicit (user) and effective
-- config trees. The effective tree repeats explicit values, so only actions
-- without an explicit entry carry a plugin suggestion.
function M.source(catalog, explicitTree, effectiveTree)
  local result = {explicit={}, suggested={}, ignored={}}
  explicitTree = type(explicitTree) == 'table' and explicitTree or {}
  effectiveTree = type(effectiveTree) == 'table' and effectiveTree or {}
  for _, action in ipairs(catalog.ordered) do
    local path = M.path(action.id)
    local mine = lookup(explicitTree.bindings, path)
    if mine ~= nil then
      result.explicit[action.id] = entry(mine)
      if result.explicit[action.id] == nil then result.ignored[#result.ignored + 1] = action.id end
    else
      result.suggested[action.id] = entry(lookup(effectiveTree.bindings, path))
    end
  end
  if type(explicitTree.layout) == 'string' then result.layout = explicitTree.layout
  elseif type(effectiveTree.layout) == 'string' then result.suggestedLayout = effectiveTree.layout end
  return result
end

function M.layoutOf(catalog, document, suggestedLayout)
  local layout = document.layout or suggestedLayout
  if catalog.presets and catalog.presets[layout] then return layout end
  return catalog.presets and M.defaultLayout or nil
end

-- Explicit values win over inherited ones. Inherited suggestions apply in
-- stable ID order where they still fit; a conflicting one leaves its action unbound.
function M.resolve(catalog, layout, suggested, explicit)
  local preset = catalog.presets and catalog.presets[layout]
  local bindings = copy(preset and preset.bindings or Catalog.defaults(catalog))
  for _, action in ipairs(catalog.ordered) do
    local value = explicit[action.id]
    if value ~= nil then bindings[action.id] = copy(value) end
  end
  local aside = {}
  for _ = 0, #catalog.ordered do
    local valid, problem, detail = Catalog.validate(catalog, bindings)
    if valid then bindings = valid; break end
    local ids = type(detail) == 'table' and detail or {detail}
    local loser = ids[1]
    -- A native conflict is resolved only by unbinding the action on the native chord.
    if problem == 'binding.conflict' and explicit[loser] ~= nil and explicit[ids[2]] == nil then
      loser = ids[2]
    end
    assert(loser and bindings[loser], problem)
    if explicit[loser] ~= nil then aside[#aside + 1] = loser end
    bindings[loser] = false
  end
  assert(Catalog.validate(catalog, bindings), 'bindings.resolve')
  for _, action in ipairs(catalog.ordered) do
    local id, value = action.id, suggested[action.id]
    if explicit[id] == nil and value ~= nil and not same(value, bindings[id]) then
      bindings[id] = copy(value)
      local valid = Catalog.validate(catalog, bindings)
      if valid then bindings = valid else bindings[id] = false end
    end
  end
  return assert(Catalog.validate(catalog, bindings)), aside
end

-- store:save(changes) writes the listed explicit entries into the active
-- config; `inherited` is the plugin suggestion an effective entry falls back to.
function M.new(catalog, source, store, router)
  local self = setmetatable({catalog=catalog, store=store, router=router,
    suggested=source.suggested or {}, suggestedLayout=source.suggestedLayout}, M)
  local document = {layout=source.layout, explicit=copy(source.explicit or {})}
  local migration
  if source.legacy then
    migration = {}
    for id, value in pairs(source.legacy.explicit) do
      if document.explicit[id] == nil then
        document.explicit[id] = copy(value)
        migration[#migration + 1] = {path=M.configPath(id), value=copy(value), inherited=self.suggested[id]}
      end
    end
    if document.layout == nil and source.legacy.layout ~= M.layoutOf(catalog, {}, self.suggestedLayout) then
      document.layout = source.legacy.layout
      migration[#migration + 1] = {path={'layout'}, value=document.layout, inherited=self.suggestedLayout}
    end
  end
  self.committed = self:derive(document)
  assert(router:apply(self.committed.bindings, {nativeAliases=self.committed.active == M.defaultLayout}))
  if migration then
    local saved, problem = true, nil
    if #migration > 0 then saved, problem = store:save(migration) end
    self.migration = {saved=saved == true, problem=problem}
  end
  return self
end

function M:derive(document)
  local active = M.layoutOf(self.catalog, document, self.suggestedLayout)
  local bindings, aside = M.resolve(self.catalog, active, self.suggested, document.explicit)
  return {layout=document.layout, explicit=document.explicit, active=active, bindings=bindings, aside=aside}
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

local function edit(self, operation)
  if not self.draft then return nil, 'profiles.no-draft' end
  local candidate = copy(self.draft)
  local ok, err = operation(candidate)
  if not ok then return nil, err end
  local valid, problem, detail = Catalog.validate(self.catalog, candidate.bindings)
  if not valid then return nil, problem, detail end
  candidate.bindings = valid
  self.draft = candidate
  return true
end

local function assign(d, id, binding)
  d.explicit[id] = copy(binding)
  d.bindings[id] = copy(binding)
end

function M:bind(action, binding)
  return edit(self, function(d)
    if not self.catalog.actions[action] then return nil, 'profile.unknown-action' end
    assign(d, action, binding)
    return true
  end)
end

-- Reassignment is atomic so neither binding is lost when a conflict is rejected.
function M:reassign(action, binding, displaced, replacement)
  return edit(self, function(d)
    if not self.catalog.actions[action] or not self.catalog.actions[displaced]
        or action == displaced then return nil, 'profile.unknown-action' end
    assign(d, action, binding)
    assign(d, displaced, replacement)
    return true
  end)
end

-- Reset returns an action, or the whole active layout, to inheritance.
function M:reset(action)
  if action and not self.catalog.actions[action] then return nil, 'profile.unknown-action' end
  return edit(self, function(d)
    local inherited = M.resolve(self.catalog, d.active, self.suggested, {})
    if action then
      d.explicit[action] = nil
      d.bindings[action] = inherited[action]
    else
      for _, item in ipairs(self.catalog.ordered) do d.explicit[item.id] = nil end
      d.bindings = inherited
    end
    return true
  end)
end

function M:select(layout)
  return edit(self, function(d)
    if not (self.catalog.presets and self.catalog.presets[layout]) then return nil, 'profiles.unknown' end
    d.layout = layout
    local derived = self:derive(d)
    d.active, d.bindings = derived.active, derived.bindings
    return true
  end)
end

function M:changes(before, after)
  local list = {}
  for _, action in ipairs(self.catalog.ordered) do
    local id = action.id
    if not same(before.explicit[id], after.explicit[id]) then
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
  local changes = self:changes(self.committed, self.draft)
  if #changes > 0 then
    local ok, problem = self.store:save(changes)
    if not ok then return nil, problem end
  end
  self.draft.bindings = valid
  assert(self.router:apply(valid, {nativeAliases=self.draft.active == M.defaultLayout}))
  self.committed = self.draft
  self.draft = nil
  return true
end

return M
