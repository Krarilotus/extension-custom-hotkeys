local M = {}

-- The framework completes all module loads before enabling Legacy's ports.
-- Invoke at module load, before requiring anything that installs native patches.
function M.check(config, activeExtensions)
  if type(config) ~= 'table' or type(activeExtensions) ~= 'table' then
    return nil, 'activation.config-unavailable'
  end
  local found = false
  local activeConfigKeys = {}
  local count = 0
  for key in pairs(activeExtensions) do
    if type(key) ~= 'number' or key < 1 or key ~= math.floor(key) then
      return nil, 'activation.config-unavailable'
    end
    count = count + 1
  end
  for index = 1, count do
    if activeExtensions[index] == nil then return nil, 'activation.config-unavailable' end
  end
  for _, extension in ipairs(activeExtensions) do
    if type(extension) ~= 'table' or type(extension.name) ~= 'string'
        or type(extension.version) ~= 'string' then return nil, 'activation.config-unavailable' end
    local configKey = extension.name .. '-' .. extension.version
    activeConfigKeys[configKey] = true
    -- Recorder's public lifecycle is checked after all modules initialize.
    -- Its presence alone does not distinguish ordinary recording from playback.
    if extension.name == 'ucp2-legacy' then
      found = true
      local effective = config[configKey]
      if type(effective) ~= 'table' or type(effective.o_keys) ~= 'table'
          or effective.o_keys.enabled ~= false then return nil, 'activation.legacy-hotkeys' end
    end
  end
  -- Check stale Legacy entries too. Active entries have an exact owner,
  -- including companion plugins whose names start with ucp2-legacy-.
  for key, effective in pairs(config) do
    if type(key) == 'string' and not activeConfigKeys[key] and key:match('^ucp2%-legacy%-') then
      if not found or type(effective) ~= 'table' or type(effective.o_keys) ~= 'table'
          or effective.o_keys.enabled ~= false then return nil, 'activation.legacy-hotkeys' end
    end
  end
  return true
end

return M
