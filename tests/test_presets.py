import pytest


@pytest.fixture
def presets(lua):
    lua.execute('''
      catalog=Catalog.new(require('code/entries'),require('code/originals'))
      require('code/presets').attach(catalog)
      router=Router.new(catalog,Catalog.defaults(catalog),adapter)
      saved=nil
      store={load=function() return saved,'store.missing' end,
        save=function(_,document) saved=document;return true end}
      profiles=assert(Profiles.new(catalog,store,router))
    ''')
    return lua


def test_three_distinct_valid_presets_and_physical_grid(presets):
    presets.execute('''
      local d=profiles.committed
      assert(d.schema==3 and d.active=='Game Default')
      local count=0;for _ in pairs(d.profiles) do count=count+1 end;assert(count==3)
      local classic=d.profiles['Game Default'].bindings
      local modern=d.profiles['Modern RTS'].bindings
      local grid=d.profiles.Grid.bindings
      assert(classic['unit.stance.defensive'].scan==17)
      assert(classic['camera.cycle.signposts'].scan==31)
      assert(classic['menu.focus.armory'].mods==0)
      assert(classic['view.toggle-interface'].mods==0)
      assert(classic['camera.pan.up'].scan==72 and classic['camera.pan.up'].extended)
      assert(modern['camera.pan.up'].scan==17)
      assert(grid['menu.build.food'].scan==21 and not grid['menu.build.food'].extended)
      assert(grid['grid.slot.1'].scan==30 and grid['grid.slot.12'].scan==49)
      for _,p in pairs(d.profiles) do assert(Catalog.validate(catalog,p.bindings)) end
    ''')


def test_copy_reset_export_and_restart_keep_preset(presets):
    presets.execute('''
      profiles:begin();assert(profiles:select('Grid'));assert(profiles:create('My grid'))
      assert(profiles:bind('grid.slot.1',false));assert(profiles:reset('grid.slot.1'))
      assert(profiles.draft.profiles['My grid'].bindings['grid.slot.1'].scan==30)
      assert(profiles:bind('grid.slot.1',false));assert(profiles:reset())
      local portable=profiles:export();assert(portable.profiles['My grid'].preset=='grid')
      assert(profiles:import('Portable grid',portable));assert(profiles:apply())
      profiles=assert(Profiles.new(catalog,store,router,Catalog.defaults(catalog)))
      assert(profiles.committed.active=='Portable grid')
      profiles:begin();assert(profiles:reset())
      assert(profiles.draft.profiles['Portable grid'].bindings['grid.slot.1'].scan==30)
      assert(profiles.committed.profiles['Game Default'].bindings['grid.slot.1']==false)
    ''')


def test_v1_migration_preserves_old_bindings_names_and_active(presets):
    presets.execute('''
      local old=Catalog.defaults(catalog)
      for slot=1,12 do old['grid.slot.'..slot]=nil end
      old['game.quicksave']=false
      local d={schema=1,active='Grid',profiles={Grid={bindings=old}}}
      local migrated=assert(Profiles.validate(catalog,d))
      assert(migrated.schema==3 and migrated.active=='Grid')
      assert(migrated.profiles.Grid.bindings['game.quicksave']==false)
      assert(migrated.profiles.Grid.bindings['grid.slot.1']==false)
      assert(migrated.profiles['Grid (2)'].preset=='grid')
      assert(d.schema==1 and d.profiles.Grid.bindings['grid.slot.1']==nil)
      migrated.profiles.Grid.bindings['grid.slot.1']=nil
      assert(not Profiles.validate(catalog,migrated))
      old['game.quicksave']=nil;assert(not Profiles.validate(catalog,d))
    ''')


def test_unknown_preset_cannot_change_router_or_store(presets):
    presets.execute('''
      profiles:begin();local d=profiles:export()
      d.profiles[d.active].preset='untrusted'
      assert(not profiles:import('Invalid',d));assert(saved==nil)
      assert(router.bindings['camera.pan.up'].scan==72)
    ''')


def test_game_default_preserves_native_aliases_until_action_is_rebound(presets):
    presets.execute('''
      current=facts('game.build')
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
      profiles:begin();assert(profiles:select('Modern RTS'));assert(profiles:apply())
      assert(router:handle(event(17,'down',2)))
      assert(router:handle(event(17,'up',2)))
      assert(#calls==0)
    ''')
