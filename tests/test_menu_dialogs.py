from test_gameplay import setup
from test_load_navigation import load_setup


def test_main_options_uses_current_registered_menu_and_no_text_or_world_actions(lua):
    setup(lua)
    lua.execute('''
      local A=require('code/addresses');A.mainOptionsMenu=12345
      local Options=require('code/dialog_context')
      s.screen=41;s.modal=44;s.activeModalID=44;s.textModal=44;s.activeModalMenu=12345
      assert(Options.owns(s))
      for field,value in pairs({activeModalMenu=12346,activeModalID=5,modal=5,
        textModal=25,textEditor=1,modal2=27,screen=35}) do
        local old=s[field];s[field]=value;assert(not Options.owns(s),field);s[field]=old
      end
      local c=Catalog.production();local context=Context.resolve(facts('menu.options','menu'))
      assert(Context.allows(c.actions['menu.next'],context))
      assert(Context.allows(c.actions['menu.activate'],context))
      assert(not Context.allows(c.actions['target.confirm'],context))
      assert(not Context.allows(c.actions['hotkeys.open'],context))
    ''')


def test_main_load_reuses_verified_list_and_excludes_name_fields(lua):
    load_setup(lua)
    lua.execute('''
      s.screen=41;s.textIndex=9;assert(Load.owns(s))
      s.textIndex=2;assert(not Load.owns(s))
      s.textIndex=4;assert(not Load.owns(s))
      s.textIndex=9;s.textState=3;assert(not Load.owns(s))
      s.textState=1;s.textEditor=1;assert(not Load.owns(s))
    ''')


def test_automarket_dialog_uses_registry_and_owns_only_menu_navigation(lua):
    setup(lua)
    lua.execute('''
      local A=require('code/addresses');A.automarketMenu=23456
      local Dialog=require('code/dialog_context')
      s.screen=16;s.modal=2025;s.activeModalID=2025;s.textModal=0;s.activeModalMenu=23456
      assert(Dialog.owns(s))
      local c=assert(Gameplay.resolve(s,2025));assert(c.owner=='game.options')
      local context=Context.resolve(facts(c.owner,c.state))
      local catalog=Catalog.production()
      assert(Context.allows(catalog.actions['menu.next'],context))
      assert(Context.allows(catalog.actions['game.menu.activate'],context))
      for _,id in ipairs({'target.confirm','grid.slot.1','camera.pan.up','pointer.primary',
        'unit.group.recall.1','game.quicksave'}) do
        assert(not Context.allows(catalog.actions[id],context),id)
      end
      for field,value in pairs({activeModalMenu=23457,activeModalID=5,modal=-1,
        textModal=25,textEditor=1,modal2=19,screen=41}) do
        local old=s[field];s[field]=value;assert(not Dialog.owns(s),field);s[field]=old
      end
      A.automarketMenu=nil;assert(not Dialog.owns(s))
    ''')
