local Binding = require('code/binding')
local Context = require('code/context')
local M = {}

function M.extensionId(id)
  return type(id)=='string' and #id<=120
    and id:match('^ext%.[a-z][a-z0-9_-]*%.[a-z][a-z0-9_-]*$')~=nil
end

local function set(values, valid)
  if type(values) ~= 'table' or #values == 0 then return nil end
  local result = {}
  for k, value in pairs(values) do
    if type(k) ~= 'number' or k < 1 or k > #values or k ~= math.floor(k)
        or type(value) ~= 'string' or value == '' or result[value]
        or (valid and not valid[value]) then return nil end
    result[value] = true
  end
  return result
end

function M.new(entries, nativeBindings)
  local actions, ordered = {}, {}
  for _, entry in ipairs(entries) do
    assert(type(entry.id) == 'string' and entry.id:match('^[a-z][a-z0-9._-]+$'), 'action.id')
    assert(not actions[entry.id], 'action.duplicate')
    local contexts = set(entry.contexts)
    local states = set(entry.states, {menu=true, ['live-sp']=true, ['live-mp']=true, editor=true, replay=true})
    assert(contexts and states and type(entry.command) == 'boolean', 'action.context')
    assert(not entry.command or not (states.menu or states.editor or states.replay), 'action.command-state')
    local behavior = entry.behavior or 'press'
    assert(behavior == 'press' or behavior == 'hold-local', 'action.behavior')
    assert(not entry.command or behavior == 'press', 'action.command-repeat')
    local default
    if entry.default then default = assert(Binding.validate(entry.default)) end
    local panels=entry.panels and assert(set(entry.panels),'action.panels') or nil
    local a = {id=entry.id, contexts=contexts, states=states, panels=panels,
      command=entry.command, behavior=behavior, default=default, label=entry.label or entry.id,
      introduced=entry.introduced or 1,extension=entry.extension,
      labels=entry.labels,category=entry.category,
      modals=entry.modals and assert(set(entry.modals),'action.modals') or nil}
    actions[a.id], ordered[#ordered+1] = a, a
  end
  local originals = {}
  for _, entry in ipairs(nativeBindings or {}) do
    local action=actions[entry.action]
    if entry.unavailable==true then
      assert(not action and type(entry.action)=='string','native.unavailable')
      action={contexts=assert(set(entry.contexts)),states=assert(set(entry.states))}
    else assert(action, 'native.action') end
    local binding = assert(Binding.validate(entry.binding))
    assert(entry.retain==nil or type(entry.retain)=='boolean','native.retain')
    originals[#originals+1] = {action=entry.action, definition=action,binding=binding,
      unavailable=entry.unavailable==true,retain=entry.retain==true or entry.unavailable==true,
      forward=entry.forward==true}
  end
  return {actions=actions, ordered=ordered, originals=originals}
end

function M.defaults(catalog)
  local result = {}
  for _, action in ipairs(catalog.ordered) do
    result[action.id] = action.default and assert(Binding.validate(action.default)) or false
  end
  return result
end

function M.validate(catalog, bindings)
  if type(bindings) ~= 'table' then return nil, 'profile.bindings' end
  local normalized, occupied = {}, {}
  for id in pairs(bindings) do
    if not catalog.actions[id] then return nil, 'profile.unknown-action', id end
  end
  for _, action in ipairs(catalog.ordered) do
    local value = bindings[action.id]
    if value == nil then return nil, 'profile.missing-action', action.id end
    if value == false then normalized[action.id] = false
    else
      local binding, err = Binding.validate(value)
      if not binding then return nil, err, action.id end
      if binding.wheel and (action.behavior=='hold-local' or action.id:sub(1,8)=='pointer.') then
        return nil,'binding.unsupported',action.id
      end
      normalized[action.id] = binding
    end
  end
  for _, action in ipairs(catalog.ordered) do
    local binding = normalized[action.id]
    if binding then
      for _, other in ipairs(occupied) do
        if Binding.same(binding, other.binding) and Context.overlap(action, other.action) then
          return nil, 'binding.conflict', {action.id, other.action.id}
        end
      end
      for _, original in ipairs(catalog.originals) do
        if original.action ~= action.id and Binding.same(binding, original.binding)
            and Context.overlap(action, original.definition, true) then
          -- A native binding may only be displaced after its replacement is assigned.
          local replacement = normalized[original.action]
          if original.unavailable or replacement == nil or replacement == false or Binding.same(replacement, original.binding) then
            return nil, 'binding.native-conflict', {action.id, original.action}
          end
        end
      end
      occupied[#occupied+1] = {action=action, binding=binding}
    end
  end
  return normalized
end

-- Both the framework and private LuaJIT state construct this same definition.
-- Mutable binding/router instances remain private to their owning state.
-- A provider default joins each layout only where its chord is still free.
function M.production(extensions)
  local entries={}
  for _,entry in ipairs(require('code/entries')) do entries[#entries+1]=entry end
  for _,entry in ipairs(extensions or {}) do entries[#entries+1]=entry end
  local catalog=M.new(entries,require('code/originals'))
  local defaults={}
  for _,action in ipairs(catalog.ordered) do
    if action.extension then defaults[action.id],action.default=action.default,nil end
  end
  require('code/presets').attach(catalog)
  local custom=M.defaults(catalog)
  for _,action in ipairs(catalog.ordered) do
    local binding=defaults[action.id]
    if binding then
      custom[action.id]=binding
      local valid=M.validate(catalog,custom)
      if valid then action.default=valid[action.id] else custom[action.id]=false end
      for _,preset in ipairs(catalog.presetOrder) do
        preset.bindings[action.id]=binding
        valid=M.validate(catalog,preset.bindings)
        preset.bindings[action.id]=valid and valid[action.id] or false
      end
    end
  end
  require('code/editor_groups').attach(catalog)
  return catalog
end

return M
