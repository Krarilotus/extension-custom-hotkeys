def setup(lua):
    lua.execute('''
      Gameplay=require('code/gameplay')
      s={screen=14,mode=0,synchronyMode=0,inGame=1,syncStatus=0,saveRelated=0,
        paused=0,halted=0,sliding=0,modal=-1,modal2=-1,modal3=-1,textModal=0,
        textEditor=0,newPlayer=0,delay=-1,focused=true,composing=false,player=1,
        playerDead=0,playerDisabled=0,selectedCount=0,selectedLast=0,
        selectionBits=string.rep(string.char(0),400),building=0,nextBuilding=0,
        unit=0,nextUnit=0,tribe=0,placement=0,rotation=0,cameraX=0,cameraY=0,zoom=0,patrol=0,
        unitMode=1,unitModeAux=1}
    ''')


def test_gameplay_requires_all_native_facts_and_rejects_unintegrated_sessions(lua):
    setup(lua)
    lua.execute('''
      local original=assert(Gameplay.resolve(s))
      assert(original.state=='live-sp' and original.authority and original.owner=='game.build')
      for key,value in pairs(s) do
        s[key]=nil;assert(not Gameplay.resolve(s),key);s[key]=value
      end
      for _,mode in ipairs({1,2,666,999}) do
        s.synchronyMode=mode;assert(not Gameplay.resolve(s))
      end
      s.synchronyMode=99;assert(Gameplay.resolve(s))
      s.mode=1;assert(not Gameplay.resolve(s))
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
      s.modal=2041;assert(not Gameplay.resolve(s))
      assert(Gameplay.resolve(s,2041));s.modal2=2;assert(not Gameplay.resolve(s,2041))
      s.modal2=-1;s.screen=17;assert(not Gameplay.resolve(s,2041))
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
