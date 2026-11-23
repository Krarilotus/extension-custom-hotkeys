local M={}
-- Registered native callbacks cannot be unregistered by winProcHandler 1.0.0.
-- Pin their state before initialization, including a partially failed startup.
local live={}
function M.prepare(modulePath,registry)
  local recorder,catalog,definitions,source,version,writer
  local access=modules.ui:access()
  local cffi=modules.cffi:cffi()
  local addresses=require('code/addresses')
  local bindings=require('code/address_bindings')
  for name,value in pairs(bindings.resolve(core,utils,access.game,cffi)) do addresses[name]=value end
  local legacy=require('code/ucp_storage').new(io)
  local ConfigFile=require('code/config_file')
  local files=ConfigFile.files(io,os)
  local chain,library=require('code/native/interface').open(core)
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
      nativeAddresses=function() return addresses end,
      extensionActions=function() return definitions end,
      dispatchExtension=function(id,phase,context,event) return registry.dispatch(id,phase,context,event) end,
      recorderInputGeneration=function() return recorder and recorder.read() or 0 end,
      installInputFrame=function(callback) return require('code/input_patch').install(core,callback) end,
      menuAddress=function(id)
        local p=access.manager.lookupMenu(id)
        if not p then return nil end
        return cffi.tonumber(cffi.cast('unsigned long',p))
      end,
      modalMenuAddress=function(id)
        local p=access.manager.lookupModalMenu(id)
        if not p then return nil end
        return cffi.tonumber(cffi.cast('unsigned long',p.pointerToMenu))
      end,
      modalBounds=function(id)
        local p=access.manager.lookupModalMenu(id)
        if not p then return nil end
        return {x=cffi.tonumber(p.x),y=cffi.tonumber(p.y),
          width=cffi.tonumber(p.width),height=cffi.tonumber(p.height)}
      end,
      bindingSource=function() return source end,
      stageBindings=function(changes)
        if not writer then return nil,'config.changed' end
        return writer.stage(changes)
      end,
      bindingsReplaced=function(success) if writer then writer.replaced(success) end end,
      gameLanguage=function() return data.version.getGameLanguage() end,
      logWarning=function(message) log(WARNING,'Custom Hotkeys: '..message) end}}
  })
  local prepared={state=state,library=library,
    connectRecorder=function(value) recorder=value end,
    configureActions=function(settings,userConfig)
      local Bindings=require('code/bindings')
      definitions=registry.freeze()
      catalog=require('code/catalog').production(definitions)
      for _,extension in ipairs(allActiveExtensions) do
        if extension.name==Bindings.owner then version=extension.version end
      end
      local deproxy=extensions.proxies.Deproxy
      writer=ConfigFile.writer(files,yaml.parse,CONFIG_FILE,version,sha.sha256,
        config.ConfigHandler.normalizeContentsValues,type(userConfig)=='table' and {
          sparse=deproxy(userConfig['config-sparse']),
          loadOrder=deproxy(userConfig['config-full']['load-order']),
          effective=deproxy(settings)} or nil)
      local explicit=Bindings.explicitTree(userConfig,config.ConfigHandler.normalizeContentsValues,
        extensions.proxies.Deproxy)
      source=Bindings.source(catalog,explicit,settings)
      for _,id in ipairs(source.ignored) do
        log(WARNING,'Custom Hotkeys: ignoring invalid binding for '..id..' in the UCP config')
      end
      local document,problem
      if Bindings.fresh(explicit) then document,problem=require('code/legacy_profiles').load(legacy,
        {decode=function(value) return json:decode(value) end},sha.sha256) end
      if document then
        source.legacy,problem=require('code/legacy_profiles').explicit(catalog,document)
      end
      if problem and problem~='store.missing' then
        log(WARNING,'Custom Hotkeys: saved 0.2 profiles not migrated ('..tostring(problem)..')')
      end
    end}
  live[#live+1]=prepared
  -- This state is created before luajit:enable applies its global defaults.
  assert(state:executeString("require('jit').off(); return true",'custom-hotkeys/jit-off',true)==true,
    'jit.off-failed')
  state:importHeaderFile('ucp/modules/ui/ui/headers/latest/ui.h')
  -- Resolve the UI owner's original entry points during module loading. Later
  -- enable-time Recorder hooks legitimately replace some of their prologues.
  assert(state:executeString("require('ui'); return true",'custom-hotkeys/ui-bindings',true)==true,
    'ui.bindings-unavailable')
  return prepared
end

function M.start(prepared,settings,userConfig)
  prepared.configureActions(settings,userConfig)
  local recorder=require('code/recorder').connect(modules,allActiveExtensions)
  prepared.connectRecorder(recorder)
  local state=prepared.state
  -- An error leaving the LuaJIT state takes the game down, so startup failures
  -- are caught inside it and leave the hotkeys off for this session.
  local receipt=state:executeString([[
    local ok,result=pcall(function()
      _G.customHotkeys=require('code/native/runtime').start(remote.interface.gameLanguage())
      return {installed=true,modal=customHotkeys.view.modalID,priority=customHotkeys.chain.priority,
        layout=customHotkeys.bindings.committed.active}
    end)
    if not ok then return {failed=tostring(result)} end
    return result
  ]],'custom-hotkeys/bootstrap',true)
  if type(receipt)=='table' and receipt.failed then
    log(ERROR,'Custom Hotkeys could not start, the hotkeys are off: '..receipt.failed)
    prepared.receipt={installed=false,failed=receipt.failed}
    return prepared
  end
  assert(type(receipt)=='table' and receipt.installed,'runtime.initialize')
  if recorder.observe then
    prepared.stopObserving=recorder.observe(function()
      assert(state:executeString('customHotkeys.router:barrier(); customHotkeys.worldActions:resetBookmarks(); return true',
        'custom-hotkeys/recorder-transition',true)==true,'hotkeys.recorder-cancellation')
    end)
  end
  prepared.receipt=receipt
  return prepared
end
return M
