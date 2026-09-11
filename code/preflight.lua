local M = {}

-- The framework completes all module loads before enabling Legacy's ports.
-- Invoke at module load, before requiring anything that installs native patches.
function M.check(config, activeExtensions)
  if type(config) ~= 'table' or type(activeExtensions) ~= 'table' then
    return nil, 'activation.config-unavailable'
  end
  local found = false
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
    -- Recorder owns playback, seek and state restoration. Native SP mode is
    -- not evidence of live input authority. Until its public synchronous
    -- ownership/generation contract is integrated, reject this combination
    -- before either module enables instead of adding competing lifecycle hooks.
    if extension.name == 'recorder' then return nil, 'activation.recorder-api' end
    if extension.name == 'ucp2-legacy' then
      found = true
      local effective = config[extension.name .. '-' .. extension.version]
      if type(effective) ~= 'table' or type(effective.o_keys) ~= 'table'
          or effective.o_keys.enabled ~= false then return nil, 'activation.legacy-hotkeys' end
    end
  end
  -- Reject a stale/imported extra Legacy version too, even when it is absent
  -- from the extension list. Never guess which contradictory input wins.
  for key, effective in pairs(config) do
    if type(key) == 'string' and key:match('^ucp2%-legacy%-') then
      if not found or type(effective) ~= 'table' or type(effective.o_keys) ~= 'table'
          or effective.o_keys.enabled ~= false then return nil, 'activation.legacy-hotkeys' end
    end
  end
  return true
end

return M
