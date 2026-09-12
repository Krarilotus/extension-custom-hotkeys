import pytest


@pytest.fixture
def profiles(lua):
    lua.execute('''
      saved=nil; failed=false
      store={load=function() return saved,'store.missing' end,
        save=function(_,document)
          if failed then return nil,'store.write' end
          saved=document; return true
        end}
      profiles=assert(Profiles.new(catalog,store,router))
    ''')
    return lua


def test_apply_restart_precedence_and_named_profiles(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:create('My layout'))
      assert(profiles:bind('unit.move',key(20)))
      assert(profiles:apply()); assert(saved.active=='My layout')
      local launcher=Catalog.defaults(catalog); launcher['unit.move']=key(21)
      profiles=assert(Profiles.new(catalog,store,router,launcher))
      assert(profiles.committed.profiles['My layout'].bindings['unit.move'].scan==20)
      assert(profiles.committed.profiles.Default.bindings['unit.move'].scan==50)
    ''')


def test_failed_save_and_cancel_keep_old_bindings(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:bind('unit.move',key(20)))
      failed=true; assert(not profiles:apply())
      assert(router.bindings['unit.move'].scan==50)
      assert(profiles.draft.profiles.Default.bindings['unit.move'].scan==20)
      profiles:cancel(); assert(not profiles.draft)
      assert(profiles.committed.profiles.Default.bindings['unit.move'].scan==50)
    ''')


def test_conflict_is_non_destructive_and_reassign_is_atomic(profiles):
    profiles.execute('''
      profiles:begin()
      assert(not profiles:bind('unit.move',key(30)))
      assert(profiles.draft.profiles.Default.bindings['unit.move'].scan==50)
      assert(profiles:reassign('unit.move',key(30),'camera.left',key(50)))
      assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==50)
    ''')


def test_unbind_reset_and_portable_import(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:bind('unit.move',false))
      assert(profiles:reset('unit.move'))
      assert(profiles:bind('camera.left',key(31)))
      local exported=profiles:export()
      assert(profiles:import('Imported',exported))
      assert(not profiles:import('Imported',exported))
      exported.profiles.Default.bindings['unit.move']=false
      assert(profiles.draft.profiles.Imported.bindings['unit.move'].scan==50)
      assert(profiles:reset()); assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==30)
    ''')


@pytest.mark.parametrize('mutation', [
    "d.schema=3", "d.profiles.Default.bindings['unknown']=false",
    "d.profiles.Default.bindings['unit.move']=nil", "d.active='missing'",
    "d.profiles['']=d.profiles.Default", "d.command='execute me'",
    "d.profiles.Default.bindings['unit.move']={scan=30,mods=0,extended=false,script='x'}",
])
def test_import_rejects_invalid_without_changing_profiles(profiles, mutation):
    profiles.execute(f'''
      profiles:begin(); local d=profiles:export(); {mutation}
      assert(not profiles:import('Bad',d))
      assert(not profiles.draft.profiles.Bad)
    ''')
