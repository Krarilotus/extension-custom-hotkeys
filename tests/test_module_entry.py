import pytest


def test_module_rejects_conflict_before_registering_or_starting_native_code(lua):
    lua.execute('''
      configFinal={['ucp2-legacy-2.15.1']={o_keys={enabled=true}}}
      allActiveExtensions={{name='ucp2-legacy',version='2.15.1'}}
      data={version={getGameLanguage=function() return 'german' end}}
      hooks={registerHookCallback=function() error('must not register') end}
      package.preload['code/launch']=function() error('must not load native code') end
      local ok,err=pcall(dofile,source_root..'/init.lua')
      assert(not ok and err:find('o_keys',1,true) and err:find('activation.legacy-hotkeys',1,true))
    ''')


def test_module_starts_once_after_native_initialization(lua):
    lua.execute('''
      configFinal={};allActiveExtensions={};INFO=1
      data={version={getGameLanguage=function() return 'english' end}}
      local callbacks,starts={},0
      hooks={registerHookCallback=function(name,callback)
        assert(name=='afterInit');callbacks[#callbacks+1]=callback end}
      package.loaded['code/launch']={prepare=function(path) return path end,start=function(path)
        assert(path=='ucp/modules/custom-hotkeys');starts=starts+1
        return {receipt={installed=true}} end}
      json={encode=function() return 'receipt' end};log=function() end
      local module=dofile(source_root..'/init.lua')
      assert(starts==0 and #callbacks==0)
      module:enable();assert(starts==0 and #callbacks==1)
      assert(not pcall(module.enable,module));assert(#callbacks==1)
      callbacks[1]();assert(starts==1 and module.runtime.receipt.installed)
      assert(not pcall(module.disable,module))
    ''')


def test_bootstrap_uses_ucp_game_language_only_after_init(lua):
    lua.execute('''
      configFinal={};allActiveExtensions={};INFO=1;core={}
      local initialized,languageReads,callback=false,0,nil
      data={version={getGameLanguage=function()
        assert(initialized,'language read before game text initialization')
        languageReads=languageReads+1;return 'german' end}}
      hooks={registerHookCallback=function(name,fn)
        assert(name=='afterInit');callback=fn end}
      sha={sha256=function() return 'hash' end}
      json={encode=function() return 'receipt' end};log=function() end
      package.loaded['code/native/interface']={open=function() return {},{} end}
      package.loaded['code/native/identity']={file=function() return 'game.exe' end}
      package.loaded['ui']={}
      package.loaded['code/executable']={check=function() return true end}
      package.loaded['code/native/runtime']={start=function(language)
        assert(language=='german')
        return {view={modalID=2041},chain={priority=-110000},
          profiles={committed={active='Game Default'}}} end}
      modules={ui={access=function() return {manager={}} end},
        cffi={cffi=function() return {} end},luajit={createState=function(_,options)
          remote={interface=options.interface.extra}
          return {importHeaderFile=function() end,executeString=function(_,code)
            return assert((loadstring or load)(code))() end} end}}
      local module=dofile(source_root..'/init.lua')
      module:enable();assert(languageReads==0)
      initialized=true;callback()
      assert(languageReads==1 and module.runtime.receipt.installed)
    ''')


@pytest.mark.parametrize('language,encoding', [
    ('english', 'cp1252'), ('american', 'cp1252'), ('german', 'cp1252'),
    ('french', 'cp1252'), ('italian', 'cp1252'), ('SPANISH', 'cp1252'), ('polish', 'cp1250'),
])
def test_activation_resolution_instructions_are_localized(lua, language, encoding):
    labels = lua.eval("require('code/activation_text').new")(language)
    for key in ['activation.legacy-hotkeys', 'activation.recorder-api',
                'activation.config-unavailable', 'restart']:
        text = labels(key)
        assert text != key
        text.encode(encoding)
    assert 'o_keys' in labels('activation.legacy-hotkeys')
