import pytest


def setup_resolver(lua):
    lua.execute('''
      bindingCalls={}
      local function resolve(pattern,name)
        assert(type(pattern)=='string' and name:match('^custom%-hotkeys%.'))
        bindingCalls[#bindingCalls+1]={pattern=pattern,name=name}
        if #bindingCalls==failureAt then error(failureKind..': '..name) end
        return 1000,100,200
      end
      core={AOBScanUnique=resolve,
        AOBScan=function() error('unvalidated scanner') end,
        insertCode=function() error('must not patch during resolution') end}
      utils={AOBExtractUnique=resolve,
        AOBExtract=function() error('unvalidated extractor') end,
        intToBytes=function() return {1,2,3,4} end,
        bytesToAOBString=function() return '01 02 03 04' end}
      bindingGame={Input={mouseState=11,isMouseInsideBox=12},
        Rendering={alphaAndButtonSurface=13}}
      bindingFFI={tonumber=tonumber,cast=function(_,value) return value end}
    ''')


def test_all_native_patterns_use_unique_owner_apis_and_ui_exports(lua):
    setup_resolver(lua)
    lua.execute('''
      local addresses=require('code/address_bindings').resolve(core,utils,bindingGame,bindingFFI)
      assert(#bindingCalls==155)
      local names={}
      for _,call in ipairs(bindingCalls) do
        assert(not names[call.name],call.name);names[call.name]=true
      end
      local count=0;for _ in pairs(addresses) do count=count+1 end
      assert(count==171)
      assert(addresses.mouseState==11 and addresses.mouseInsideBox==12 and addresses.buttonSurface==13)
    ''')


@pytest.mark.parametrize('failure', ['missing', 'ambiguous'])
def test_each_binding_failure_stops_before_publishing_addresses_or_installing_hooks(lua, failure):
    setup_resolver(lua)
    lua.globals().failureKind = failure
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
        assert(not ok and err:find(failureKind..': custom-hotkeys.',1,true),tostring(err))
        assert(#bindingCalls==index)
        assert(next(package.loaded['code/addresses'])==nil,'partial bindings published')
      end
    ''')
