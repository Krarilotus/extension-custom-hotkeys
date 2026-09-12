def setup_resolver(lua):
    lua.execute('''
      bindingCalls={}
      local function resolve(pattern,...)
        assert(type(pattern)=='string' and select('#',...)==0)
        bindingCalls[#bindingCalls+1]={pattern=pattern}
        if #bindingCalls==failureAt then error('AOB not found: '..pattern) end
        return 1000,100,200
      end
      core={AOBScan=resolve,
        insertCode=function() error('must not patch during resolution') end}
      utils={AOBExtract=resolve,
        intToBytes=function() return {1,2,3,4} end,
        bytesToAOBString=function() return '01 02 03 04' end}
      bindingGame={Input={mouseState=11,isMouseInsideBox=12},
        Rendering={alphaAndButtonSurface=13}}
      bindingFFI={tonumber=tonumber,cast=function(_,value) return value end}
    ''')


def test_all_native_patterns_use_existing_owner_apis_and_ui_exports(lua):
    setup_resolver(lua)
    lua.execute('''
      local addresses=require('code/address_bindings').resolve(core,utils,bindingGame,bindingFFI)
      assert(#bindingCalls==155)
      local count=0;for _ in pairs(addresses) do count=count+1 end
      assert(count==171)
      assert(addresses.mouseState==11 and addresses.mouseInsideBox==12 and addresses.buttonSurface==13)
    ''')


def test_each_binding_failure_stops_before_publishing_addresses_or_installing_hooks(lua):
    setup_resolver(lua)
    lua.execute('''
      configFinal={};allActiveExtensions={}
      hooks={registerHookCallback=function() error('must not register on resolution failure') end}
      modules={ui={access=function() return {game=bindingGame} end},
        cffi={cffi=function() return bindingFFI end},
        luajit={createState=function() error('must not create callbacks on resolution failure') end}}
      for index=1,155 do
        failureAt=index;bindingCalls={}
        package.loaded['code/addresses']={}
        local ok,err=pcall(dofile,source_root..'/init.lua')
        assert(not ok and err:find('AOB not found:',1,true),tostring(err))
        assert(#bindingCalls==index)
        assert(next(package.loaded['code/addresses'])==nil,'partial bindings published')
      end
    ''')
