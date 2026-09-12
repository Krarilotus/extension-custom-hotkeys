local M={}
-- Registered native callbacks cannot be unregistered by winProcHandler 1.0.0.
-- Pin their state before initialization, including a partially failed startup.
local live={}
function M.start(modulePath)
  local compatible,recorder=pcall(require('code/recorder').connect,modules,allActiveExtensions)
  if not compatible then
    error(require('code/activation_text').new(data.version.getGameLanguage())('activation.recorder-api'))
  end
  local catalog=require('code/catalog').production()
  local profiles=require('code/profiles')
  local codec={encode=function(value) return json:encode(value) end,
    decode=function(value) return json:decode(value) end}
  local function profileStore(namespace)
    return require('code/store').new(require('code/ucp_storage').new(io,namespace),
      codec,sha.sha256,function(value) return profiles.validate(catalog,value) end)
  end
  local store,exchange=profileStore(),profileStore('exchange')
  local chain,library=require('code/native/interface').open(core)
  local access=modules.ui:access()
  local cffi=modules.cffi:cffi()
  local state=modules.luajit:createState({name='custom-hotkeys',
    requireHandler=function(_,path)
      local base
      if path:match('^code/[%w/_-]+$') then base=modulePath
      elseif path:match('^ui[/%.]?[%w/_-]*$') then base='ucp/modules/ui'
      else error('require.namespace') end
      local normalized=path:gsub('%.','/')
      local f=io.open(base..'/'..normalized..'.lua','r')
      if not f then f=assert(io.open(base..'/'..normalized..'/init.lua','r')) end
      local text=f:read('*all');f:close();return text
    end,
    interface={env=_ENV,extra={manager=access.manager,chain=function() return chain end,
      recorderInputState=recorder.read,
      installInputFrame=function(callback) return require('code/input_patch').install(core,callback) end,
      menuAddress=function(id)
        local p=access.manager.lookupMenu(id)
        if not p then return nil end
        return cffi.tonumber(cffi.cast('unsigned long',p))
      end,
      loadProfiles=function() return store:load() end,
      saveProfiles=function(document) return store:save(document) end,
      loadExchange=function() return exchange:load() end,
      saveExchange=function(document)
        local previous,err=exchange:load()
        if not previous and err~='store.missing' then return nil,err end
        return exchange:save(document)
      end,
      gameLanguage=function() return data.version.getGameLanguage() end}}
  })
  live[#live+1]={state=state,library=library,store=store}
  local image=state:executeString("return require('code/native/identity').file()",
    'custom-hotkeys/identity',true)
  assert(require('code/executable').check(image,io,sha.sha256))
  state:importHeaderFile('ucp/modules/ui/ui/headers/latest/ui.h')
  local receipt=state:executeString([[
    _G.customHotkeys=require('code/native/runtime').start(remote.interface.gameLanguage())
    return {installed=true,modal=customHotkeys.view.modalID,priority=customHotkeys.chain.priority,
      profile=customHotkeys.profiles.committed.active}
  ]],'custom-hotkeys/bootstrap',true)
  assert(type(receipt)=='table' and receipt.installed,'runtime.initialize')
  if recorder.observe then
    live[#live].stopObserving=recorder.observe(function()
      assert(state:executeString('customHotkeys.router:barrier(); return true',
        'custom-hotkeys/recorder-transition',true)==true,'hotkeys.recorder-cancellation')
    end)
  end
  return {state=state,library=library,store=store,receipt=receipt}
end
return M
