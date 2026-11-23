import pytest


@pytest.fixture
def presets(lua):
    lua.execute('''
      catalog=Catalog.new(require('code/entries'),require('code/originals'))
      require('code/presets').attach(catalog)
      router=Router.new(catalog,Catalog.defaults(catalog),adapter)
      config=memoryConfig()
      profiles=config:open(catalog,router)
    ''')
    return lua


def test_three_distinct_valid_presets_and_physical_grid(presets):
    presets.execute('''
      assert(profiles.committed.active=='game-default' and profiles.committed.layout==nil)
      assert(#catalog.presetOrder==3)
      local classic=catalog.presets['game-default'].bindings
      local modern=catalog.presets['modern-rts'].bindings
      local grid=catalog.presets.grid.bindings
      assert(classic['unit.stance.defensive'].scan==17)
      assert(classic['camera.cycle.signposts'].scan==31)
      assert(classic['menu.focus.armory'].mods==0)
      assert(classic['view.toggle-interface'].mods==0)
      assert(classic['camera.pan.up'].scan==72 and classic['camera.pan.up'].extended)
      assert(modern['camera.pan.up'].scan==17)
      assert(grid['menu.build.food'].scan==21 and not grid['menu.build.food'].extended)
      assert(grid['grid.slot.1'].scan==30 and grid['grid.slot.12'].scan==49)
      for _,p in ipairs(catalog.presetOrder) do assert(Catalog.validate(catalog,p.bindings)) end
    ''')


def test_layout_choice_is_saved_and_explicit_entries_survive_a_layout_switch(presets):
    presets.execute('''
      profiles:begin();assert(profiles:select('grid'))
      assert(profiles:bind('grid.slot.1',false));assert(profiles:reset('grid.slot.1'))
      assert(profiles.draft.bindings['grid.slot.1'].scan==30)
      assert(profiles:bind('grid.slot.2',false));assert(profiles:apply())
      assert(config.tree.layout=='grid')
      profiles=config:open(catalog,router)
      assert(profiles.committed.active=='grid' and profiles.committed.bindings['grid.slot.2']==false)
      profiles:begin();assert(profiles:select('game-default'))
      assert(profiles.draft.bindings['grid.slot.1']==false and profiles.draft.explicit['grid.slot.2']==false)
      assert(profiles:reset())
      assert(profiles.draft.bindings['camera.pan.up'].scan==72 and profiles.draft.explicit['grid.slot.2']==nil)
    ''')


def test_unknown_layout_cannot_change_router_or_config(presets):
    presets.execute('''
      profiles:begin();local ok,err=profiles:select('untrusted')
      assert(not ok and err=='profiles.unknown');profiles:cancel()
      assert(#config.saves==0 and router.bindings['camera.pan.up'].scan==72)
      config.tree.layout='untrusted'
      assert(config:open(catalog,router).committed.active=='game-default')
    ''')


def test_game_default_preserves_native_aliases_until_action_is_rebound(presets):
    presets.execute('''
      current=facts('game.build');current.panel='61:0'
      assert(not router:handle(event(17,'down',2)))
      assert(not router:handle(event(17,'up',2)))
      profiles:begin();assert(profiles:bind('unit.stance.defensive',key(17,4)))
      assert(profiles:apply())
      assert(router:handle(event(17,'down',2)))
      assert(router:handle(event(17,'up',2)))
      assert(#calls==0)
      profiles:begin();assert(profiles:reset('unit.stance.defensive'));assert(profiles:apply())
      assert(not router:handle(event(17,'down',2)))
      assert(not router:handle(event(17,'up',2)))
      profiles:begin();assert(profiles:select('modern-rts'));assert(profiles:apply())
      assert(router:handle(event(17,'down',2)))
      assert(router:handle(event(17,'up',2)))
      assert(#calls==0)
    ''')
