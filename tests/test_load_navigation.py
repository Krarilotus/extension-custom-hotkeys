from test_gameplay import setup


def load_setup(lua):
    setup(lua)
    lua.execute("""
      Load=require('code/load_context')
      s.modal=9;s.textModal=9;s.activeModalID=9;s.activeModalMenu=0xb97688
      s.loadArray=0x601a88;s.textIndex=4;s.textState=1
      s.loadCount=2;s.loadRows=16;s.loadOffset=0;s.loadSelected=0
      s.loadIdentity=string.rep(string.char(0),8)
      s.modalX=280;s.modalY=92;s.modalWidth=720;s.modalHeight=408
      s.modalBorder=0x200;s.modalAnimation=32;s.modalClosing=0;s.width=1280;s.height=720
    """)


def test_load_owner_has_only_navigation_and_rejects_text_and_session_changes(lua):
    load_setup(lua)
    lua.execute("""
      local world=assert(Gameplay.resolve(s,9));assert(world.owner=='game.load')
      local raw=facts(world.owner,world.state);raw.modal='9'
      local c=Catalog.new(require('code/entries'),require('code/originals'))
      for _,id in ipairs({'menu.next','menu.previous','game.menu.activate'}) do
        assert(Context.allows(c.actions[id],Context.resolve(raw)),id)
      end
      for id in pairs(c.actions) do
        if id~='menu.next' and id~='menu.previous' and id~='game.menu.activate' then
          assert(not Context.allows(c.actions[id],Context.resolve(raw)),id)
        end
      end
      for field,value in pairs({modal=10,activeModalID=10,activeModalMenu=0xb96290,
          loadArray=0x6022f8,textModal=10,textIndex=2,textState=3,textEditor=1,
          modal2=11,modal3=27,synchronyMode=1,focused=false,composing=true,
          loadCount=501,loadRows=17,loadOffset=2,loadSelected=2,loadIdentity='',
          delay=0,newPlayer=1,screen=17,saveRelated=1,halted=1}) do
        local old=s[field];s[field]=value
        assert(not Gameplay.resolve(s,9),field);s[field]=old
      end
      s.loadCount=0;s.loadSelected=-1;s.loadIdentity='';assert(Gameplay.resolve(s,9))
    """)


def test_load_navigation_filters_empty_rows_disabled_load_and_scroll_edges(lua):
    load_setup(lua)
    lua.execute("""
      local rows={}
      for i=0,15 do rows[#rows+1]={action=0x4948c0,kind=3,parameter=i} end
      for _,p in ipairs({-1,-2,2,17}) do
        rows[#rows+1]={action=0x4943b0,kind=p<0 and 2 or 3,parameter=p}
      end
      rows[#rows+1]={action=0x492de0,kind=3,parameter=0}
      rows[#rows+1]={action=0x492de0,kind=3,parameter=1}
      rows[#rows+1]={action=0x469f10,kind=3,parameter=0}
      rows[#rows+1]={action=0x492ba0,kind=6,parameter=0}
      assert(#Load.controls(rows,s)==6)
      s.loadSelected=-1;assert(#Load.controls(rows,s)==5)
      s.loadCount=0;s.loadIdentity='';assert(#Load.controls(rows,s)==3)
      s.loadCount=20;s.loadIdentity=string.rep(string.char(0),80)
      assert(#Load.controls(rows,s)==20)
      s.loadOffset=4;assert(#Load.controls(rows,s)==20)
      s.loadOffset=2;assert(#Load.controls(rows,s)==21)
      s.modalAnimation=0;assert(not Load.controls(rows,s))
      s.modalAnimation=32;s.modalClosing=1;assert(not Load.controls(rows,s))
      s.modalClosing=0;s.modalWidth=2000;assert(not Load.controls(rows,s))
    """)


def test_load_list_change_cancels_queued_release_before_loading_other_entry(lua):
    load_setup(lua)
    lua.execute("""
      local function resolve()
        local world=Gameplay.resolve(s,9)
        if not world then return nil end
        local raw=facts(world.owner,world.state);raw.selection=world.selection
        return raw
      end
      local edges,resets=0,0
      local cursor=require('code/cursor').new({resolve=resolve,
        position=function() return 100,100 end,bounds=function() return 1280,720 end,
        busy=function() return false end,move=function() end,
        button=function() edges=edges+1 end,cancel=function() resets=resets+1 end})
      for _,field in ipairs({'loadOffset','loadSelected','loadIdentity'}) do
        s.loadCount=20;s.loadOffset=0;s.loadSelected=0;s.loadIdentity=string.rep(string.char(0),80)
        assert(cursor:click('left',Context.resolve(resolve())))
        cursor:beforeFrame();cursor:beforeFrame()
        local before=edges
        s[field]=field=='loadIdentity' and string.rep(string.char(1),80) or 1
        cursor:beforeFrame();assert(not cursor.pending and edges==before)
      end
      assert(resets==3)
    """)
