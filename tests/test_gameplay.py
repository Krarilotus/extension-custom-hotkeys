def setup(lua):
    lua.execute('''
      Gameplay=require('code/gameplay')
      s={screen=14,mode=0,synchronyMode=0,inGame=1,syncStatus=0,saveRelated=0,
        paused=0,halted=0,sliding=0,modal=-1,modal2=-1,modal3=-1,textModal=0,
        textEditor=0,newPlayer=0,delay=-1,focused=true,composing=false,player=1,
        playerDead=0,playerDisabled=0,selectedCount=0,selectedLast=0,
        selectionBits=string.rep(string.char(0),400),building=0,nextBuilding=0,
        unit=0,nextUnit=0,tribe=0,placement=0,rotation=0,cameraX=0,cameraY=0,zoom=0,patrol=0,
        unitMode=1,unitModeAux=1,pendingRotation=8}
    ''')


def test_gameplay_requires_all_native_facts_and_rejects_finished_sessions(lua):
    setup(lua)
    lua.execute('''
      local original=assert(Gameplay.resolve(s))
      assert(original.state=='live-sp' and original.authority and original.owner=='game.build')
      for key,value in pairs(s) do
        s[key]=nil;assert(not Gameplay.resolve(s),key);s[key]=value
      end
      for _,mode in ipairs({2,666,999}) do
        s.synchronyMode=mode;assert(not Gameplay.resolve(s))
      end
      s.synchronyMode=99;assert(Gameplay.resolve(s))
      s.synchronyMode=1;s.mode=1;assert(Gameplay.resolve(s).state=='live-mp')
    ''')


def test_gameplay_text_pause_authority_and_transition_gates(lua):
    setup(lua)
    lua.execute('''
      for _,field in ipairs({'paused','halted','sliding','syncStatus','saveRelated',
        'textModal','textEditor','newPlayer','playerDead','playerDisabled'}) do
        s[field]=1;assert(not Gameplay.resolve(s),field);s[field]=0
      end
      s.nextBuilding=1;assert(not Gameplay.resolve(s));s.nextBuilding=0
      s.nextUnit=1;assert(not Gameplay.resolve(s));s.nextUnit=0
      for _,pending in ipairs({0,2,4,6,-1,9}) do
        s.pendingRotation=pending;assert(not Gameplay.resolve(s))
      end
      s.pendingRotation=8
      s.modal=2041;assert(not Gameplay.resolve(s))
      assert(Gameplay.resolve(s,2041));s.modal2=2;assert(not Gameplay.resolve(s,2041))
      s.modal2=-1;s.screen=17;assert(not Gameplay.resolve(s,2041))
    ''')


def test_extreme_hud_and_resolved_unit_capacity_preserve_real_modal_ownership(lua):
    setup(lua)
    lua.execute('''
      local A=require('code/addresses')
      A.unitCapacity=10000;A.selectionBytes=1250
      s.selectionBits=string.rep(string.char(0),1250)
      s.selectedLast=9000;s.unit=9000;s.nextUnit=9000
      s.modal3=130
      assert(Gameplay.resolve(s).owner=='game.build')
      s.screen=16;assert(Gameplay.resolve(s).owner=='game.status')
      s.textModal=1;assert(not Gameplay.resolve(s));s.textModal=0
      s.modal=11;assert(not Gameplay.resolve(s));s.modal=-1
      s.modal2=5;assert(not Gameplay.resolve(s));s.modal2=-1
      s.modal3=131;assert(not Gameplay.resolve(s));s.modal3=130
      s.selectedLast=10000;assert(not Gameplay.resolve(s))
    ''')


def test_multiplayer_catalog_and_text_ownership_keep_native_save_load_restrictions(lua):
    setup(lua)
    lua.execute('''
      s.synchronyMode=1;s.mode=1
      local resolved=assert(Gameplay.resolve(s))
      local context=Context.resolve(facts(resolved.owner,resolved.state))
      local catalog=Catalog.production()
      local singlePlayer={['game.quicksave']=true,['game.quickload']=true,
        ['game.save.open']=true,['game.load.open']=true}
      for id,action in pairs(catalog.actions) do
        if action.states['live-sp'] then
          assert((action.states['live-mp']==true)==not singlePlayer[id],id)
        end
      end
      for _,id in ipairs({'hotkeys.open','camera.pan.up','target.confirm',
          'unit.stance.defensive','menu.build.industry'}) do
        assert(Context.allows(catalog.actions[id],context),id)
      end
      for _,field in ipairs({'textModal','textEditor','paused','halted','syncStatus',
          'playerDead','playerDisabled','newPlayer'}) do
        s[field]=1;assert(not Gameplay.resolve(s),field);s[field]=0
      end
      s.focused=false;assert(not Gameplay.resolve(s));s.focused=true
      s.modal=2041;assert(not Gameplay.resolve(s))
    ''')


def test_options_owns_only_its_verified_active_modal_and_has_no_world_actions(lua):
    setup(lua)
    lua.execute('''
      s.modal=5;s.textModal=5;s.activeModalID=5;s.activeModalMenu=0xb971f0
      s.paused=1
      local resolved=assert(Gameplay.resolve(s,5))
      assert(resolved.owner=='game.options')
      local raw=facts(resolved.owner,resolved.state);raw.screen='14';raw.modal='5'
      local context=Context.resolve(raw)
      local c=Catalog.new(require('code/entries'),require('code/originals'))
      assert(Context.allows(c.actions['menu.next'],context))
      assert(Context.allows(c.actions['game.menu.activate'],context))
      for _,id in ipairs({'camera.pan.up','target.confirm','menu.open.market',
        'menu.build.industry','unit.stance.defensive','hotkeys.open'}) do
        assert(not Context.allows(c.actions[id],context),id)
      end
      for field,value in pairs({activeModalID=10,activeModalMenu=0,textModal=10,
          textEditor=1,modal2=11,modal3=27,synchronyMode=2,focused=false,
          composing=true,delay=0,newPlayer=1,screen=17}) do
        local old=s[field];s[field]=value
        assert(not Gameplay.resolve(s,5),field);s[field]=old
      end
    ''')


def test_selection_and_projection_identity_changes_without_stale_owned_flag(lua):
    setup(lua)
    lua.execute('''
      local initial=Gameplay.resolve(s)
      s.ownedSelected=1;assert(Gameplay.resolve(s).selection==initial.selection)
      s.selectionBits=string.char(1)..s.selectionBits:sub(2)
      assert(Gameplay.resolve(s).selection~=initial.selection)
      s.cameraX=1;assert(Gameplay.resolve(s).targeting==initial.targeting)
      s.cameraX=0;s.placement=25;assert(Gameplay.resolve(s).targeting~=initial.targeting)
      for _,rotation in ipairs({0,2,4,6}) do s.rotation=rotation;assert(Gameplay.resolve(s)) end
      s.rotation=3;assert(not Gameplay.resolve(s))
    ''')


def test_unit_order_mode_transition_cancels_queued_target_without_release(lua):
    setup(lua)
    lua.execute('''
      local Cursor=require('code/cursor')
      local function resolve()
        local world=Gameplay.resolve(s)
        if not world then return nil end
        local raw=facts(world.owner,world.state)
        raw.selection,raw.targeting=world.selection,world.targeting
        return raw
      end
      local edges,resets=0,0
      local cursor=Cursor.new({resolve=resolve,position=function() return 100,100 end,
        bounds=function() return 800,600 end,busy=function() return false end,
        move=function() end,button=function() edges=edges+1 end,
        cancel=function() resets=resets+1 end})
      assert(cursor:click('left',Context.resolve(resolve())))
      cursor:beforeFrame();cursor:beforeFrame();assert(edges==1)
      s.unitMode=5;s.unitModeAux=5
      cursor:beforeFrame();assert(not cursor.pending and edges==1 and resets==1)
      local before=Context.resolve(resolve())
      s.unitModeAux=22;assert(not Context.same(before,Context.resolve(resolve())))
      before=Context.resolve(resolve())
      s.unitMode=22;assert(not Context.same(before,Context.resolve(resolve())))
    ''')
