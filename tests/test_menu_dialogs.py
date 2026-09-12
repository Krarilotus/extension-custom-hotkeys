from test_gameplay import setup
from test_load_navigation import load_setup


def test_main_options_uses_current_registered_menu_and_no_text_or_world_actions(lua):
    setup(lua)
    lua.execute('''
      local A=require('code/addresses');A.mainOptionsMenu=12345
      local Options=require('code/options_context')
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
