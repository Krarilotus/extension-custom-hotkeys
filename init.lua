-- The framework loads all modules before enabling any Legacy patches.
-- Reject incompatible effective configuration at that boundary.
local ok,reason=require('code/preflight').check(configFinal,allActiveExtensions)
if not ok then
  local labels=require('code/activation_text').new(data.version.getGameLanguage())
  error(labels(reason)..' ['..tostring(reason)..']')
end
local launch=require('code/launch')
local M={}
local handlers={}
local prepared=launch.prepare('ucp/modules/custom-hotkeys',handlers)
-- Optional view providers register during enable(), before afterInit freezes
-- the runtime. Profiles remain owned here, even when a provider is absent.
function M:registerActionHandler(id,callback)
  assert(not handlers.frozen,'hotkeys.registration-closed')
  assert(id=='view.resolution-zoom-in' or id=='view.resolution-zoom-out',
    'hotkeys.unsupported-provider-action')
  assert(type(callback)=='function' and not handlers[id],'hotkeys.invalid-handler')
  handlers[id]=callback
end
function M:enable()
  assert(not self.started,'Custom Hotkeys is already enabled; restart required')
  self.started=true
  hooks.registerHookCallback('afterInit',function()
    handlers.frozen=true
    self.runtime=launch.start(prepared)
    log(INFO,'Custom Hotkeys initialized: '..json:encode(self.runtime.receipt))
  end)
end
function M:disable()
  error(require('code/activation_text').new(data.version.getGameLanguage())('restart'))
end
return M
