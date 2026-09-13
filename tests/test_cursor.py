def setup(lua):
    lua.execute('''
      Cursor=require('code/cursor'); Navigation=require('code/navigation')
      raw=facts('menu','menu'); current=Context.resolve(raw)
      x,y,busy=100,100,false; changes={}; cancelled=0
      native={resolve=function() return raw end,position=function() return x,y end,
        bounds=function() return 800,600 end,busy=function() return busy end,
        move=function(a,b) x,y=a,b end,
        button=function(button,down) changes[#changes+1]={button,down} end,
        cancel=function() cancelled=cancelled+1 end}
      cursor=Cursor.new(native)
    ''')


def test_one_gesture_across_native_frames(lua):
    setup(lua)
    lua.execute('''
      assert(cursor:click('left',current))
      assert(not cursor:click('left',current)); assert(#changes==0)
      cursor:beforeFrame();assert(#changes==0)
      cursor:beforeFrame(); assert(#changes==1 and changes[1][2])
      assert(not cursor:step(32,0,current))
      cursor:beforeFrame(); assert(#changes==2 and not changes[2][2])
      assert(not cursor:click('left',current))
      cursor:beforeFrame();cursor:beforeFrame();assert(#changes==2)
      assert(cursor:click('right',current))
    ''')


def test_modal_focus_replay_changes_cancel_without_release_action(lua):
    setup(lua)
    lua.execute('''
      for _,change in ipairs({function() raw.modal='covered' end,
        function() raw.focused=false end,function() raw.state='replay' end,
        function() raw.generation=2 end,function() raw.text=true end}) do
        raw=facts('menu','menu');current=Context.resolve(raw)
        local before=#changes
        assert(cursor:click('left',current));cursor:beforeFrame();cursor:beforeFrame();change()
        cursor:beforeFrame();assert(cursor.pending==nil and #changes==before+1)
      end
      assert(cancelled==5)
    ''')


def test_physical_mouse_and_changed_target_retire_unpressed_gesture(lua):
    setup(lua)
    lua.execute('''
      assert(cursor:click('left',current));busy=true;cursor:beforeFrame()
      assert(cursor.pending==nil and cancelled==0 and #changes==0)
      assert(not cursor:click('left',current));busy=false
      assert(cursor:click('left',current));x=x+1;cursor:beforeFrame()
      assert(cursor.pending==nil and cancelled==0 and #changes==0)
      assert(cursor:step(-128,128,current));assert(x==8 and y==228)
      assert(not cursor:moveTo(-1,100,current))
    ''')


def test_navigation_rechecks_native_rows_before_press(lua):
    setup(lua)
    lua.execute('''
      rows={{address=10,x=20,y=30,kind=3,parameter=1,action=200},
        {address=11,x=70,y=30,kind=3,parameter=2,action=200}}
      nav=Navigation.new({controls=function() return rows end,
        point=function(r) return r.x,r.y end},cursor)
      assert(nav:move(1,current));assert(x==20 and nav.address==10)
      assert(nav:move(-1,current));assert(x==70 and nav.address==11)
      assert(nav:activate(current));rows[2].action=201
      cursor:beforeFrame();assert(#changes==0)
      rows[2]=nil;assert(not nav:activate(current))
      assert(nav:move(1,current));assert(nav:activate(current))
      rows={};cursor:beforeFrame();assert(#changes==0)
    ''')


def test_native_hover_must_accept_aim_before_press(lua):
    setup(lua)
    lua.execute('''
      local hovered=false
      assert(cursor:click('left',current,nil,function() return hovered end))
      cursor:beforeFrame();cursor:beforeFrame()
      assert(#changes==0 and cancelled==0 and cursor.pending==nil)
      assert(cursor:click('left',current,nil,function() return hovered end))
      cursor:beforeFrame();hovered=true;cursor:beforeFrame()
      assert(#changes==1 and changes[1][2])
      raw.text=true;cursor:beforeFrame();assert(cancelled==1 and #changes==1)
    ''')


def test_queued_pointer_acknowledgement_precedes_aim_and_click(lua):
    setup(lua)
    lua.execute('''
      local settled=false
      native.settled=function() return settled end
      assert(cursor:moveTo(300,500,current));assert(cursor:click('left',current))
      x,y=100,100 -- Older native mouse coordinates arrive before our move.
      cursor:beforeFrame();cursor:beforeFrame()
      assert(cursor.pending and #changes==0 and cancelled==0)
      x,y=300,500;settled=true
      cursor:beforeFrame();assert(#changes==0)
      cursor:beforeFrame();assert(#changes==1)
      cursor:beforeFrame();assert(#changes==2)
      cursor:beforeFrame();assert(not cursor.pending)
      settled=false;assert(cursor:click('left',current))
      for i=1,8 do cursor:beforeFrame() end
      assert(not cursor.pending and #changes==2 and cancelled==0)
    ''')


def test_waiting_for_pointer_ack_never_weakens_context_or_physical_guards(lua):
    setup(lua)
    lua.execute('''
      native.settled=function() return false end
      assert(cursor:click('left',current));raw.text=true;cursor:beforeFrame()
      assert(not cursor.pending and #changes==0)
      raw.text=false;assert(cursor:click('left',current));busy=true;cursor:beforeFrame()
      assert(not cursor.pending and #changes==0)
      busy=false;assert(cursor:click('left',current));raw.generation=2;cursor:beforeFrame()
      assert(not cursor.pending and #changes==0)
    ''')


def test_semantic_control_requires_unique_active_identity_and_rechecks_help(lua):
    setup(lua)
    lua.execute('''
      local selector={action=200,parameter=51,help=65578}
      rows={{address=10,x=20,y=30,kind=3,parameter=51,action=200,help=65578},
        {address=11,x=70,y=30,kind=3,parameter=51,action=200,help=65600}}
      nav=Navigation.new({controls=function() return rows end,
        point=function(r) return r.x,r.y end},cursor)
      assert(nav:activateMatching(selector,current))
      assert(nav.address==10 and #changes==0)
      rows[1].help=65600;cursor:beforeFrame();assert(not cursor.pending and #changes==0)
      assert(not nav:activateMatching(selector,current))
      rows[1].help=65578;rows[2].help=65578
      assert(not nav:activateMatching(selector,current) and #changes==0)
      rows[2]=nil;assert(nav:activateMatching(selector,current))
      rows={};cursor:beforeFrame();assert(not cursor.pending and #changes==0)
    ''')
