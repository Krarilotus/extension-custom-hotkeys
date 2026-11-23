import pytest


@pytest.fixture
def profiles(lua):
    lua.execute('''
      config=memoryConfig()
      profiles=config:open(catalog,router)
    ''')
    return lua


def test_apply_writes_only_explicit_changes_and_restart_reads_them(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:bind('unit.move',key(20)))
      assert(profiles:apply())
      assert(#config.saves==1 and #config.saves[1]==1)
      local change=config.saves[1][1]
      assert(table.concat(change.path,'.')=='bindings.custom-hotkeys.unit.move' and change.value.scan==20)
      assert(router.bindings['unit.move'].scan==20)
      profiles=config:open(catalog,router)
      assert(profiles.committed.explicit['unit.move'].scan==20)
      assert(profiles.committed.explicit['camera.left']==nil)
      assert(profiles.committed.bindings['camera.left'].scan==30)
      profiles:begin(); assert(profiles:apply()); assert(#config.saves==1)
    ''')


def test_failed_save_and_cancel_keep_old_bindings(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:bind('unit.move',key(20)))
      config.failed=true; local ok,err=profiles:apply(); assert(not ok and err=='config.write')
      assert(router.bindings['unit.move'].scan==50)
      assert(profiles.draft.bindings['unit.move'].scan==20)
      profiles:cancel(); assert(not profiles.draft)
      assert(profiles.committed.bindings['unit.move'].scan==50 and #config.saves==0)
    ''')


def test_conflict_is_non_destructive_and_reassign_makes_both_explicit(profiles):
    profiles.execute('''
      profiles:begin()
      local ok,err,detail=profiles:bind('unit.move',key(30))
      assert(not ok and err=='binding.conflict')
      assert(profiles.draft.bindings['unit.move'].scan==50 and profiles.draft.explicit['unit.move']==nil)
      assert(profiles:reassign('unit.move',key(30),'camera.left',key(50)))
      assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==50 and #config.saves[1]==2)
    ''')


def test_clear_is_explicit_and_reset_returns_to_inheritance(profiles):
    profiles.execute('''
      profiles:begin(); assert(profiles:bind('unit.move',false)); assert(profiles:apply())
      assert(config.saves[1][1].value==false and router.bindings['unit.move']==false)
      profiles=config:open(catalog,router)
      assert(profiles.committed.bindings['unit.move']==false)
      profiles:begin(); assert(profiles:reset('unit.move'))
      assert(profiles:bind('camera.left',key(31)))
      assert(profiles:apply())
      local removed
      for _,change in ipairs(config.saves[2]) do
        if change.path[#change.path]=='move' then removed=change end
      end
      assert(removed and removed.value==nil)
      profiles:begin(); assert(profiles:reset()); assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==30 and router.bindings['unit.move'].scan==50)
      assert(next(config.tree.bindings['custom-hotkeys'].unit)==nil)
    ''')


def test_suggestions_apply_only_where_nothing_explicit(lua):
    lua.execute('''
      local source=Bindings.source(catalog,
        {bindings={['custom-hotkeys']={unit={move=key(21)}}}},
        {bindings={['custom-hotkeys']={unit={move=key(21)},camera={left=key(21)},
          market={buy=key(33)}}}})
      assert(source.explicit['unit.move'].scan==21 and source.suggested['unit.move']==nil)
      assert(source.suggested['market.buy'].scan==33)
      local b=Bindings.new(catalog,source,memoryConfig(),router)
      assert(b.committed.bindings['market.buy'].scan==33)
      -- A suggestion whose chord is explicitly taken leaves its own action unbound.
      assert(b.committed.bindings['camera.left']==false)
      b:begin();assert(b:bind('market.buy',key(34)));assert(b:reset('market.buy'))
      assert(b.draft.bindings['market.buy'].scan==33 and b.draft.explicit['market.buy']==nil)
    ''')


def test_explicit_conflict_keeps_the_entry_but_sets_its_route_aside(lua):
    lua.execute('''
      local tree={bindings={['custom-hotkeys']={unit={move=key(30)}}}}
      local b=Bindings.new(catalog,Bindings.source(catalog,tree,tree),memoryConfig(),router)
      assert(b.committed.bindings['unit.move'].scan==30)
      assert(b.committed.bindings['camera.left']==false and #b.committed.aside==0)
      tree.bindings['custom-hotkeys'].camera={left=key(30)}
      b=Bindings.new(catalog,Bindings.source(catalog,tree,tree),memoryConfig(),router)
      assert(#b.committed.aside==1 and b.committed.explicit[b.committed.aside[1]].scan==30)
      tree.bindings['custom-hotkeys'].unit.move={scan=30,mods=0,extended=false,script='x'}
      local source=Bindings.source(catalog,tree,tree)
      assert(source.ignored[1]=='unit.move' and source.explicit['unit.move']==nil)
    ''')


def test_action_ids_never_share_a_config_path_prefix(lua):
    lua.execute('''
      local c=Catalog.production()
      local paths={}
      for _,action in ipairs(c.ordered) do paths[table.concat(Bindings.configPath(action.id),'.')]=true end
      for path in pairs(paths) do
        local prefix=path:match('^(.*)%.[^.]+$')
        while prefix do assert(not paths[prefix],path); prefix=prefix:match('^(.*)%.[^.]+$') end
      end
    ''')
