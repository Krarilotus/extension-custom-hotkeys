local M = {}

-- The framework completes all module loads before enabling Legacy's ports.
-- Invoke at module load, before requiring anything that installs native patches.
function M.check(config, activeExtensions)
  if type(config) ~= 'table' or type(activeExtensions) ~= 'table' then
    return nil, 'activation.config-unavailable'
  end
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
    -- Recorder's public lifecycle is checked after all modules initialize.
    -- Its presence alone does not distinguish ordinary recording from playback.
    if extension.name == 'ucp2-legacy' then
      local effective = config[extension.name .. '-' .. extension.version]
      if effective ~= nil and type(effective) ~= 'table' then
        return nil, 'activation.config-unavailable'
      end
      local options = effective and effective.o_keys
      if options ~= nil then
        if type(options) ~= 'table' or
            (options.enabled ~= nil and type(options.enabled) ~= 'boolean') then
          return nil, 'activation.config-unavailable'
        end
        -- Legacy enables a port only for enabled=true or an enabled direct child.
        -- Omitted settings are off; disabled/inactive configuration is no conflict.
        if options.enabled == true then return nil, 'activation.legacy-hotkeys' end
        for _, child in pairs(options) do
          if type(child) == 'table' and child.enabled == true then
            return nil, 'activation.legacy-hotkeys'
          end
        end
      end
    end
  end
  return true
end

return M
