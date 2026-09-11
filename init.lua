-- The framework loads all modules before enabling any Legacy patches.
-- Reject incompatible effective configuration at that boundary.
local ok,reason=require('code/preflight').check(configFinal,allActiveExtensions)
if not ok then
  local labels=require('code/activation_text').new(data.version.getGameLanguage())
  error(labels(reason)..' ['..tostring(reason)..']')
end
local M={}
function M:enable()
  assert(not self.started,'Custom Hotkeys is already enabled; restart required')
  self.started=true
  hooks.registerHookCallback('afterInit',function()
    self.runtime=require('code/launch').start('ucp/modules/custom-hotkeys')
    log(INFO,'Custom Hotkeys initialized: '..json:encode(self.runtime.receipt))
  end)
end
function M:disable()
  error(require('code/activation_text').new(data.version.getGameLanguage())('restart'))
end
return M
