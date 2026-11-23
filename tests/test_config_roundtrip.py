"""Merge gate: in-game Apply, launcher saves, config switching, provider removal, export."""
import pytest
import yaml

from ucp_config_model import Launcher, install

BASE = ['custom-hotkeys', 'zoom']


def chord(scan, mods=1):
    return {'scan': scan, 'mods': mods, 'extended': False}


def plugin(scan_in, scan_out):
    return {'custom-hotkeys.bindings.zoom.in': chord(scan_in),
            'custom-hotkeys.bindings.zoom.out': chord(scan_out)}


P1, P2 = plugin(24, 25), plugin(26, 27)


@pytest.fixture
def game(lua, tmp_path):
    install(lua)
    lua.execute('''
      local labels={en='Zoom',de='Zoom',fr='Zoom',ru='Zoom',hu='Zoom',tr='Zoom',ch='Zoom',es='Zoom',fa='Zoom'}
      local registry=require('code/extension_actions').new()
      for _,name in ipairs({'in','out'}) do
        registry.register({id='ext.zoom.'..name,label=labels,category=labels,context={kind='world'},
          default={wheel=name=='in' and 'up' or 'down',mods=1},callback=function() return true end})
      end
      withZoom=Catalog.production(registry.freeze())
      withoutZoom=Catalog.production()
      function start(path,provider,legacy)
        local c=provider==false and withoutZoom or withZoom
        session=launch(path,c,Router.new(c,Catalog.defaults(c),adapter),legacy)
        -- The runtime records a written import once per installation.
        if session.migration and session.migration.saved then legacyImported=true end
        return session
      end
      function scan(id)
        local b=session.committed.bindings[id]
        if b==false then return false end
        return b and b.scan
      end
      function apply(edit)
        session:begin();assert(edit(session));assert(session:apply())
      end
    ''')
    return lua, tmp_path


def sparse_entries(path):
    config = yaml.safe_load(path.read_text())['config-sparse']['modules']['custom-hotkeys']['config']
    return (config or {}).get('bindings', {})


def test_config_switch_provider_removal_and_export_round_trip(game):
    lua, tmp = game
    a, b, exported, c = (tmp / n for n in ('a.yml', 'b.yml', 'export.yml', 'c.yml'))
    start = lua.eval('start')
    scan = lua.eval('scan')

    # Config A inherits plugin P1; one explicit in-game override is written into A.
    Launcher(BASE + ['p1'], P1).save(a)
    start(str(a))
    assert scan('ext.zoom.in') == 24 and scan('ext.zoom.out') == 25
    lua.execute("apply(function(s) return s:bind('ext.zoom.out',key(30,4)) end)")
    assert sparse_entries(a) == {'zoom': {'out': {'contents': {'suggested-value': chord(30, 4)}}}}
    # The launcher keeps the edit when it saves A again.
    Launcher.load(a, P1).save(a)
    start(str(a))
    assert scan('ext.zoom.in') == 24 and scan('ext.zoom.out') == 30

    # Config B selects plugin P2: inheritance follows B, A's explicit edit stays in A.
    Launcher(BASE + ['p2'], P2).save(b)
    start(str(b))
    assert scan('ext.zoom.in') == 26 and scan('ext.zoom.out') == 27
    start(str(a))
    assert scan('ext.zoom.in') == 24 and scan('ext.zoom.out') == 30
    # Switching A itself to P2 changes only the inherited chord.
    loaded = Launcher.load(a, P2)
    loaded.active = BASE + ['p2']
    loaded.save(a)
    start(str(a))
    assert scan('ext.zoom.in') == 26 and scan('ext.zoom.out') == 30

    # An explicit clear and the chord survive a launcher save and a launch
    # without the provider, including an unrelated in-game Apply.
    lua.execute("apply(function(s) return s:bind('ext.zoom.in',false) end)")
    loaded = Launcher.load(a, P2)
    loaded.active = ['custom-hotkeys', 'p2']
    loaded.save(a)
    start(str(a), False)
    assert scan('ext.zoom.in') is None
    lua.execute("apply(function(s) return s:bind('game.quicksave',key(65,1)) end)")
    assert sparse_entries(a)['zoom']['in']['contents']['suggested-value'] is False
    loaded = Launcher.load(a, P2)
    loaded.active = BASE + ['p2']
    loaded.save(a)
    start(str(a))
    assert scan('ext.zoom.in') is False and scan('ext.zoom.out') == 30 and scan('game.quicksave') == 65

    # Reset returns an action to inheritance in the same config. The explicit
    # value had replaced the plugin suggestion in config-full, so the provider
    # default applies until the launcher next saves this config.
    lua.execute("apply(function(s) return s:reset('ext.zoom.in') end)")
    assert 'in' not in sparse_entries(a)['zoom']
    start(str(a))
    assert lua.eval("session.committed.bindings['ext.zoom.in'].wheel") == 'up'
    Launcher.load(a, P2).save(a)
    start(str(a))
    assert scan('ext.zoom.in') == 26

    # Export A and reload it as another config.
    Launcher.load(a, P2).save(exported)
    Launcher.load(exported, P2).save(c)
    start(str(c))
    assert scan('ext.zoom.in') == 26 and scan('ext.zoom.out') == 30 and scan('game.quicksave') == 65
    assert not list(tmp.glob('*.custom-hotkeys.*'))


def test_layout_is_a_config_value_too(game):
    lua, tmp = game
    a = tmp / 'a.yml'
    Launcher(BASE, {'custom-hotkeys.layout': 'grid'}).save(a)
    lua.eval('start')(str(a))
    assert lua.eval('session.committed.active') == 'grid'
    lua.execute("apply(function(s) return s:select('modern-rts') end)")
    assert yaml.safe_load(a.read_text())['config-sparse']['modules']['custom-hotkeys']['config']['layout'] == \
        {'contents': {'suggested-value': 'modern-rts'}}
    lua.execute("apply(function(s) return s:select('grid') end)")
    lua.eval('start')(str(a))
    assert lua.eval('session.committed.active') == 'grid'


def test_a_0_2_profile_is_imported_once_even_after_the_launcher_drops_the_module(game):
    lua, tmp = game
    a = tmp / 'a.yml'
    Launcher(BASE).save(a)
    lua.execute("""
      legacy={layout='grid',explicit={['game.quicksave']=key(65,1),['ext.zoom.in']=false}}
      start(target_a,nil,legacy)
      assert(session.committed.active=='grid' and scan('game.quicksave')==65 and legacyImported)
      apply(function(s) return s:reset('game.quicksave') end)
    """.replace('target_a', repr(str(a))))
    # Disabling Custom Hotkeys in the launcher drops its entries; re-enabling brings none back.
    loaded = Launcher.load(a)
    loaded.active, loaded.explicit = ['zoom'], ['zoom']
    loaded.save(a)
    loaded = Launcher.load(a)
    loaded.active, loaded.explicit = BASE, BASE
    loaded.save(a)
    lua.execute("""
      start(target_a,nil,legacy)
      assert(not session.migration and scan('game.quicksave')==31 and session.committed.active=='game-default')
    """.replace('target_a', repr(str(a))))
