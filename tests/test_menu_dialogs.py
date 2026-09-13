from test_gameplay import setup
from test_load_navigation import load_setup
import pytest


@pytest.mark.parametrize('modal', [5, 6, 7, 11, 12, 13, 44])
def test_native_button_dialogs_own_navigation_and_never_text_fields(lua, modal):
    setup(lua)
    lua.globals().modal = modal
    lua.execute('''
      local Dialog=require('code/dialog_context')
      Dialog.bind(function(id) return id*100 end)
      s.modal=modal;s.activeModalID=modal;s.textModal=modal;s.activeModalMenu=modal*100
      assert(Dialog.owns(s));assert(Gameplay.resolve(s,modal).owner=='game.options')
      s.textEditor=1;assert(not Dialog.owns(s));s.textEditor=0
      s.activeModalMenu=s.activeModalMenu+1;assert(not Dialog.owns(s))
      s.activeModalMenu=modal*100;s.modal2=19;assert(not Dialog.owns(s));s.modal2=-1
      for _,text in ipairs({10,25,27,35,36}) do
        s.modal=text;s.activeModalID=text;s.textModal=text;s.activeModalMenu=text*100
        assert(not Dialog.owns(s))
      end
    ''')


def test_main_options_uses_current_registered_menu_and_no_text_or_world_actions(lua):
    setup(lua)
    lua.execute('''
      local Options=require('code/dialog_context')
      Options.bind(function(id) return id==44 and 12345 or nil end)
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
      local Dialog=require('code/dialog_context')
      Dialog.bind(function(id) return id==2025 and 23456 or nil end)
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
      Dialog.bind(function() return nil end);assert(not Dialog.owns(s))
    ''')
