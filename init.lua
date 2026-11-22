-- The framework loads all modules before enabling any Legacy patches.
-- Reject incompatible effective configuration at that boundary.
local ok,reason=require('code/preflight').check(configFinal,allActiveExtensions)
if not ok then
  local labels=require('code/activation_text').new(data.version.getGameLanguage())
  error(labels(reason)..' ['..tostring(reason)..']')
end
local launch=require('code/launch')
local registry=require('code/extension_actions').new()
local prepared=launch.prepare('ucp/modules/custom-hotkeys',registry)
local M={}
function M:registerAction(spec)
  return registry.register(spec)
end
function M:enable(config)
  assert(not self.started,'Custom Hotkeys is already enabled; restart required')
  self.started=true
  hooks.registerHookCallback('afterInit',function()
    self.runtime=launch.start(prepared,config and config.bindings)
    if self.runtime.receipt.installed then
      log(INFO,'Custom Hotkeys initialized: '..json:encode(self.runtime.receipt))
    end
  end)
end
function M:disable()
  error(require('code/activation_text').new(data.version.getGameLanguage())('restart'))
end
return M
