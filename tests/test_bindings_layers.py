def test_apply_routes_exactly_what_the_next_launch_derives(lua):
    # An inherited action that lost its chord to an explicit one gets it
    # back as soon as the explicit entry moves away.
    lua.execute('''
      local config=memoryConfig()
      config.tree={bindings={['custom-hotkeys']={unit={move=key(30)}}}}
      local profiles=config:open(catalog,router)
      assert(profiles.committed.bindings['camera.left']==false)
      profiles:begin();assert(profiles:bind('unit.move',false));assert(profiles:apply())
      assert(router.bindings['camera.left'].scan==30)
      local restarted=config:open(catalog,router)
      for id,binding in pairs(restarted.committed.bindings) do
        assert(Binding.equal(binding,profiles.committed.bindings[id]),id)
      end
    ''')


def test_a_set_aside_entry_returns_once_its_chord_is_free_and_a_swap_replaces_it(lua):
    lua.execute('''
      local config=memoryConfig()
      config.tree={bindings={['custom-hotkeys']={unit={move=key(30)},camera={left=key(30)}}}}
      local b=config:open(catalog,router)
      assert(#b.committed.aside==1 and b.committed.aside[1]=='unit.move')
      assert(b.committed.bindings['unit.move']==false)
      b:begin();assert(b:bind('market.buy',key(30)))
      assert(b.draft.explicit['unit.move'].scan==30)
      assert(b:bind('camera.left',key(31)))
      assert(b.draft.bindings['unit.move'].scan==30 and #b.draft.aside==0)
      local c=Catalog.new({
        {id='game.a',contexts={'game'},states={'live-sp'},command=false,default=key(10)},
        {id='game.b',contexts={'game'},states={'live-sp'},command=false,default=key(11)},
        {id='game.c',contexts={'game'},states={'live-sp'},command=false,default=key(12)}})
      local tree={bindings={['custom-hotkeys']={game={a=key(30),b=key(30)}}}}
      b=Bindings.new(c,Bindings.source(c,tree,tree),memoryConfig(),Router.new(c,Catalog.defaults(c),adapter))
      assert(b.committed.aside[1]=='game.b')
      b:begin();assert(b:reassign('game.c',key(30),'game.a',key(12)))
      assert(b.draft.bindings['game.c'].scan==30 and b.draft.bindings['game.b'].scan==11)
      assert(b.draft.explicit['game.b']==nil)
    ''')


def test_suggestions_resolve_together_before_layout_defaults_and_reset_always_inherits(lua):
    lua.execute('''
      local source=Bindings.source(catalog,{},{bindings={['custom-hotkeys']={
        unit={move=key(30)},camera={left=false}}}})
      local b=Bindings.new(catalog,source,memoryConfig(),router)
      assert(b.committed.bindings['unit.move'].scan==30 and b.committed.bindings['camera.left']==false)
      local tree={bindings={['custom-hotkeys']={unit={move=key(30)}}}}
      b=Bindings.new(catalog,Bindings.source(catalog,tree,tree),memoryConfig(),router)
      b:begin();assert(b:bind('camera.left',key(31)));assert(b:bind('unit.move',key(32)))
      assert(b:reset('camera.left') and b.draft.bindings['camera.left'].scan==30)
      assert(b:bind('unit.move',key(30))==nil)
      assert(b:reset('unit.move') and b.draft.bindings['unit.move'].scan==50)
    ''')


def test_launcher_required_values_win_and_cannot_be_edited(lua):
    # The launcher writes a required value into config-full only.
    lua.execute('''
      local source=Bindings.source(catalog,
        {bindings={['custom-hotkeys']={unit={move=key(21)}}},layout='grid'},
        {bindings={['custom-hotkeys']={unit={move=key(22)}}},layout='custom'})
      assert(source.locked['unit.move'] and source.explicit['unit.move'].scan==22)
      assert(source.layoutLocked and source.layout=='custom')
      local config=memoryConfig()
      local b=Bindings.new(catalog,source,config,router)
      assert(b.committed.bindings['unit.move'].scan==22)
      b:begin()
      assert(select(2,b:bind('unit.move',key(23)))=='binding.locked')
      assert(select(2,b:reset('unit.move'))=='binding.locked')
      assert(select(2,b:select('grid'))=='binding.locked')
      assert(b:reset() and b.draft.explicit['unit.move'].scan==22)
      assert(b:apply() and #config.saves==0)
    ''')


def test_config_wrapper_and_owner_names_are_not_provider_ids(lua):
    lua.execute('''
      assert(Catalog.extensionId('ext.zoom.in'))
      for _,id in ipairs({'ext.contents.in','ext.zoom.contents','ext.custom-hotkeys.in',
          'ext.constructor.in','ext.zoom.constructor'}) do
        assert(not Catalog.extensionId(id),id)
      end
    ''')



def test_parked_provider_chords_migrate_and_only_fresh_configs_import(lua):
    lua.execute('''
      local Legacy=require('code/legacy_profiles')
      local c=Catalog.production()
      local doc={schema=3,active='Mine',profiles={Mine={preset='game-default',
        bindings={['ext.zoom.in']=false,['ext.zoom.out']=false,['ext.gone.act']=key(40)},
        unavailable={['ext.zoom.in']={wheel='up',mods=1}}}}}
      local migrated=Legacy.explicit(c,doc)
      assert(migrated.explicit['ext.zoom.in'].wheel=='up' and migrated.explicit['ext.zoom.out']==false)
      assert(Bindings.fresh({}) and Bindings.fresh({bindings={}}))
      assert(not Bindings.fresh({bindings={gone={act=false}}}) and not Bindings.fresh({layout='grid'}))
    ''')


def test_a_failed_migration_write_is_written_by_the_next_apply(lua):
    lua.execute('''
      local c=Catalog.production()
      local config=memoryConfig();config.failed=true
      local source=Bindings.source(c,{},{})
      source.legacy={layout='game-default',explicit={['game.quicksave']=key(65,1),['ext.gone.act']=key(40)}}
      local r=Router.new(c,Catalog.defaults(c),adapter)
      local b=Bindings.new(c,source,config,r)
      assert(not b.migration.saved and r.bindings['game.quicksave'].scan==65)
      config.failed=false
      b:begin();assert(b:bind('game.quickload',key(66,1)));assert(b:apply())
      local written={}
      for _,change in ipairs(config.saves[1]) do written[table.concat(change.path,'.')]=true end
      assert(written['bindings.custom-hotkeys.game.quicksave'] and written['bindings.gone.act'])
      assert(written['bindings.custom-hotkeys.game.quickload'])
    ''')


def test_a_required_value_outranks_explicit_entries_and_survives_a_swap(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='game.a',contexts={'game'},states={'live-sp'},command=false,default=key(10)},
        {id='game.b',contexts={'game'},states={'live-sp'},command=false,default=key(11)},
        {id='game.c',contexts={'game'},states={'live-sp'},command=false,default=key(12)}})
      local source=Bindings.source(c,{bindings={['custom-hotkeys']={game={a=key(14),b=key(13)}}}},
        {bindings={['custom-hotkeys']={game={a=key(14),b=key(14)}}}})
      assert(source.locked['game.b'])
      local config=memoryConfig()
      local b=Bindings.new(c,source,config,Router.new(c,Catalog.defaults(c),adapter))
      assert(b.committed.bindings['game.b'].scan==14 and b.committed.bindings['game.a']==false)
      b:begin();assert(b:reassign('game.c',key(14),'game.a',key(12))==nil)
      assert(b.draft.explicit['game.b'].scan==14)
      assert(b:bind('game.a',key(15)) and b:apply())
      for _,change in ipairs(config.saves[1]) do assert(change.path[#change.path]~='b') end
    ''')


def test_an_action_displaced_by_a_loser_gets_its_chord_back(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='world.default',contexts={'game'},states={'live-sp','editor'},command=false,default=key(20)},
        {id='both.suggested',contexts={'game','editor'},states={'live-sp','editor'},command=false,default=false},
        {id='editor.explicit',contexts={'editor'},states={'live-sp','editor'},command=false,default=false}})
      local bindings,aside=Bindings.resolve(c,nil,{['both.suggested']=key(20)},{['editor.explicit']=key(20)})
      assert(bindings['world.default'].scan==20 and bindings['both.suggested']==false)
      assert(bindings['editor.explicit'].scan==20 and #aside==0)
    ''')


def chain_catalog(lua):
    lua.execute('''
      local both={'live-sp','editor'}
      chain=Catalog.new({
        {id='cc',contexts={'game'},states=both,command=false,default=key(46)},
        {id='ss',contexts={'game','editor'},states=both,command=false,default=false},
        {id='ee',contexts={'editor'},states=both,command=false,default=false},
        {id='aa',contexts={'game'},states=both,command=false,default=key(44)},
        {id='bb',contexts={'game'},states=both,command=false,default=key(45)}},
        {{action='bb',binding=key(44)},{action='cc',binding=key(45)}})
    ''')


def test_a_native_replacement_chain_settles_once_its_last_owner_returns(lua):
    # c loses 46 to a suggestion that then yields to an editor-only explicit
    # entry; b needs c moved off 45 and a needs b moved off 44.
    chain_catalog(lua)
    lua.execute('''
      local bindings,aside=Bindings.resolve(chain,nil,{ss=key(46)},{ee=key(46)})
      assert(bindings.cc.scan==46 and bindings.bb.scan==45 and bindings.aa.scan==44)
      assert(bindings.ss==false and bindings.ee.scan==46 and #aside==0)
    ''')


def test_required_values_never_stop_startup(lua):
    chain_catalog(lua)
    lua.execute('''
      local bindings,aside=Bindings.resolve(chain,nil,{ss=key(46)},{ee=key(46),aa=key(44)},{aa=true})
      assert(bindings.aa.scan==44 and bindings.bb.scan==45 and #aside==0)
      bindings,aside=Bindings.resolve(chain,nil,{},{aa=key(47),bb=key(47)},{aa=true,bb=true})
      assert(bindings.aa.scan==47 and bindings.bb==false and aside[1]=='bb')
    ''')


def test_equal_layers_keep_catalog_order_after_a_retry(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='first',contexts={'game'},states={'live-sp','editor'},command=false,default=key(60)},
        {id='second',contexts={'game'},states={'live-sp','editor'},command=false,default=key(60)},
        {id='wide',contexts={'game','editor'},states={'live-sp','editor'},command=false,default=false},
        {id='narrow',contexts={'editor'},states={'live-sp','editor'},command=false,default=false}})
      local bindings=Bindings.resolve(c,nil,{wide=key(60)},{narrow=key(60)})
      assert(bindings.first.scan==60 and bindings.second==false and bindings.wide==false)
    ''')


def test_a_parked_required_value_survives_a_new_assignment_of_its_chord(lua):
    lua.execute('''
      local c=Catalog.new({
        {id='game.a',contexts={'game'},states={'live-sp'},command=false,default=key(10)},
        {id='game.b',contexts={'game'},states={'live-sp'},command=false,default=key(11)},
        {id='game.c',contexts={'game'},states={'live-sp'},command=false,default=key(12)}})
      local source=Bindings.source(c,{bindings={['custom-hotkeys']={game={a=key(20),b=key(21)}}}},
        {bindings={['custom-hotkeys']={game={a=key(33),b=key(33)}}}})
      local b=Bindings.new(c,source,memoryConfig(),Router.new(c,Catalog.defaults(c),adapter))
      assert(b.committed.aside[1]=='game.b' and b.committed.bindings['game.a'].scan==33)
      b:begin();assert(b:reassign('game.c',key(33),'game.a',key(12))==nil)
      assert(b.draft.explicit['game.b'].scan==33)
    ''')


def test_a_retry_displaces_every_lower_blocker_together(lua):
    lua.execute('''
      local both={'live-sp','editor','menu'}
      local c=Catalog.new({
        {id='t.wide',contexts={'game','editor'},states=both,command=false,default=false},
        {id='o.all',contexts={'game','editor','menu'},states=both,command=false,default=false},
        {id='m.menu',contexts={'menu'},states=both,command=false,default=false},
        {id='x.game',contexts={'game'},states=both,command=false,default=key(46)},
        {id='y.editor',contexts={'editor'},states=both,command=false,default=key(46)}})
      local bindings=Bindings.resolve(c,nil,{['t.wide']=key(46)},{['o.all']=key(46),['m.menu']=key(46)},{['m.menu']=true})
      assert(bindings['t.wide'].scan==46 and bindings['x.game']==false and bindings['y.editor']==false)
      assert(bindings['m.menu'].scan==46 and bindings['o.all']==false)
    ''')


def test_two_actions_swapping_native_keys_return_together(lua):
    lua.execute('''
      local both={'live-sp','editor'}
      local c=Catalog.new({
        {id='aa.swap',contexts={'game'},states=both,command=false,default=key(45)},
        {id='bb.swap',contexts={'game'},states=both,command=false,default=key(44)},
        {id='ss.wide',contexts={'game','editor'},states=both,command=false,default=false},
        {id='ee.editor',contexts={'editor'},states=both,command=false,default=false}},
        {{action='aa.swap',binding=key(44)},{action='bb.swap',binding=key(45)}})
      local bindings=Bindings.resolve(c,nil,{['ss.wide']=key(44)},{['ee.editor']=key(44)})
      assert(bindings['aa.swap'].scan==45 and bindings['bb.swap'].scan==44)
      assert(bindings['ss.wide']==false and bindings['ee.editor'].scan==44)
    ''')


def test_a_higher_claim_wins_over_a_lower_action_and_its_native_dependent(lua):
    lua.execute('''
      local states={'live-sp','editor','menu'}
      local c=Catalog.new({
        {id='e2.editor-menu',contexts={'editor','menu'},states=states,command=false,default=false},
        {id='e1.game-editor',contexts={'game','editor'},states=states,command=false,default=false},
        {id='s1.game',contexts={'game'},states=states,command=false,default=key(59,2)},
        {id='s2.game',contexts={'game'},states=states,command=false,default=false},
        {id='rq.menu',contexts={'menu'},states=states,command=false,default=false}},
        {{action='s1.game',binding=key(59,2)}})
      local bindings,aside=Bindings.resolve(c,nil,{['s1.game']=key(65),['s2.game']=key(59,2)},
        {['e1.game-editor']=key(65),['e2.editor-menu']=key(65),['rq.menu']=key(65)},{['rq.menu']=true})
      assert(bindings['e1.game-editor'].scan==65 and bindings['rq.menu'].scan==65)
      assert(bindings['e2.editor-menu']==false and aside[1]=='e2.editor-menu')
    ''')
