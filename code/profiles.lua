local Catalog = require('code/catalog')
local M = {}
M.__index = M

local function copy(value)
  if type(value) ~= 'table' then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

local function name(value)
  return type(value) == 'string' and #value > 0 and #value <= 120
    and require('code/text_edit').valid(value)
    and not value:find('[%z\1-\31\127]') and value:find('%S') ~= nil
end

local function fields(value, allowed)
  if type(value) ~= 'table' then return false end
  for key in pairs(value) do if not allowed[key] then return false end end
  return true
end

function M.validate(catalog, document)
  if not fields(document, {schema=true, active=true, profiles=true})
      or (document.schema ~= 1 and document.schema ~= 2) or not name(document.active)
      or type(document.profiles) ~= 'table' then return nil, 'profiles.format' end
  local result, count = {schema=2, active=document.active, profiles={}}, 0
  for key, profile in pairs(document.profiles) do
    count = count + 1
    if count > (document.schema==1 and 32 or 64) or not name(key)
        or not fields(profile, {bindings=true,preset=document.schema==2}) then
      return nil, 'profiles.name'
    end
    if profile.preset~=nil and (type(profile.preset)~='string' or not catalog.presets
        or not catalog.presets[profile.preset]) then return nil,'profiles.preset' end
    local candidate=copy(profile.bindings)
    if document.schema==1 and type(candidate)=='table' then
      for _,action in ipairs(catalog.ordered) do
        -- Only known additions may be absent from an older schema. They start
        -- unbound so an upgrade cannot activate an unexpected command.
        if action.introduced>1 and candidate[action.id]==nil then candidate[action.id]=false end
      end
    end
    local bindings, err, detail = Catalog.validate(catalog, candidate)
    if not bindings then return nil, err, detail end
    result.profiles[key] = {bindings=bindings,preset=profile.preset}
  end
  if not result.profiles[result.active] then return nil, 'profiles.active' end
  if document.schema==1 and catalog.presetOrder then
    for _,preset in ipairs(catalog.presetOrder) do
      local title,suffix=preset.name,1
      while result.profiles[title] do
        suffix=suffix+1;title=preset.name..' ('..suffix..')'
      end
      result.profiles[title]={preset=preset.id,bindings=copy(preset.bindings)}
    end
  end
  return result
end

function M.initial(catalog, launcherBindings)
  local bindings = assert(Catalog.validate(catalog, launcherBindings or Catalog.defaults(catalog)))
  if not catalog.presetOrder then
    return {schema=2, active='Default', profiles={Default={bindings=bindings}}}
  end
  local d={schema=2,active='Game Default',profiles={}}
  for _,preset in ipairs(catalog.presetOrder) do
    d.profiles[preset.name]={preset=preset.id,bindings=copy(preset.bindings)}
  end
  if launcherBindings then d.active='Launcher';d.profiles.Launcher={bindings=bindings} end
  return d
end

function M.new(catalog, store, router, launcherBindings)
  local self = setmetatable({catalog=catalog, store=store, router=router}, M)
  local document, err = store:load()
  if not document then
    if err ~= 'store.missing' then return nil, err end
    document = M.initial(catalog, launcherBindings)
  end
  local valid, problem = M.validate(catalog, document)
  if not valid then return nil, problem end
  self.committed = valid
  local active=valid.profiles[valid.active]
  assert(router:apply(active.bindings,{nativeAliases=active.preset=='game-default'}))
  return self
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

function M:edit(operation)
  if not self.draft then return nil, 'profiles.no-draft' end
  local candidate = copy(self.draft)
  local ok, err = operation(candidate)
  if not ok then return nil, err end
  local valid, problem, detail = M.validate(self.catalog, candidate)
  if not valid then return nil, problem, detail end
  self.draft = valid
  return true
end

function M:select(profileName)
  return self:edit(function(d)
    if not d.profiles[profileName] then return nil, 'profiles.unknown' end
    d.active = profileName
    return true
  end)
end

function M:create(profileName)
  return self:edit(function(d)
    if not name(profileName) or d.profiles[profileName] then return nil, 'profiles.name' end
    d.profiles[profileName] = copy(d.profiles[d.active])
    d.active = profileName
    return true
  end)
end

function M:bind(action, binding)
  return self:edit(function(d)
    if not self.catalog.actions[action] then return nil, 'profile.unknown-action' end
    d.profiles[d.active].bindings[action] = copy(binding)
    return true
  end)
end

-- Reassignment is atomic so neither binding is lost when a conflict is rejected.
function M:reassign(action, binding, displaced, replacement)
  return self:edit(function(d)
    if not self.catalog.actions[action] or not self.catalog.actions[displaced]
        or action == displaced then return nil, 'profile.unknown-action' end
    d.profiles[d.active].bindings[action] = copy(binding)
    d.profiles[d.active].bindings[displaced] = copy(replacement)
    return true
  end)
end

function M:reset(action)
  return self:edit(function(d)
    local profile=d.profiles[d.active]
    local defaults=profile.preset and self.catalog.presets[profile.preset].bindings
      or Catalog.defaults(self.catalog)
    if action then
      if not self.catalog.actions[action] then return nil,'profile.unknown-action' end
      profile.bindings[action]=copy(defaults[action])
    else profile.bindings=copy(defaults) end
    return true
  end)
end

function M:import(profileName, document)
  local valid, err = M.validate(self.catalog, document)
  if not valid then return nil, err end
  return self:edit(function(d)
    if not name(profileName) or d.profiles[profileName] then return nil, 'profiles.name' end
    d.profiles[profileName] = copy(valid.profiles[valid.active])
    d.active = profileName
    return true
  end)
end

function M:export()
  local document = self.draft or self.committed
  return {schema=2, active=document.active,
    profiles={[document.active]=copy(document.profiles[document.active])}}
end

function M:apply()
  if not self.draft then return nil, 'profiles.no-draft' end
  local valid, err = M.validate(self.catalog, self.draft)
  if not valid then return nil, err end
  self.router:barrier()
  local ok, problem = self.store:save(valid)
  if not ok then return nil, problem end
  local active=valid.profiles[valid.active]
  assert(self.router:apply(active.bindings,{nativeAliases=active.preset=='game-default'}))
  self.committed = valid
  self.draft = nil
  return true
end

return M
