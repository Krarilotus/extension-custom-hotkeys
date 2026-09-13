import pytest
from test_editor import setup


def prepare(lua, visible=1):
    setup(lua)
    lua.globals().initial_visibility = visible
    lua.execute('''
      package.loaded.ffi={}
      package.loaded['code/native/text']={}
      package.loaded['code/native/encoding']={}
      local View=require('code/native/editor_view')
      snapshot={screen=14,modal=-1,inputGeneration=4}
      visibility=initial_visibility;displayCalls={}
      game={Input={mouseState=0},UI={MenuModalComposition1=0,
        activateModalMenu=function(_,id) snapshot.modal=id end}}
      view=setmetatable({profiles=profiles,catalog=catalog,router=router,labels=function(id) return id end,
        scene={current=snapshot,resolve=function() return {owner='game.build'} end,
          snapshot=function() return snapshot end},
        modalID=2041,resetMouse=function() end,setPage=function() end,
        owns=function(self) return self.opened end,
        displayVisible=function(id) assert(id==21);return visibility end,
        setDisplay=function(id,value)
          assert(id==21);displayCalls[#displayCalls+1]=value;visibility=value end},View)
    ''')


def test_editor_hides_world_hover_and_restores_native_visibility_once(lua):
    prepare(lua)
    lua.execute('''
      assert(view:open() and visibility==0)
      assert(#displayCalls==1 and displayCalls[1]==0)
      assert(view:close(false) and visibility==1)
      view:restoreHover(snapshot)
      assert(#displayCalls==2 and displayCalls[2]==1)
      assert(not view:close(false))
    ''')


def test_editor_preserves_disabled_hover_and_focus_loss_keeps_draft(lua):
    prepare(lua, 0)
    lua.execute('''
      assert(view:open())
      snapshot.focused=false
      assert(require('code/editor_ownership').reconcile(view,snapshot))
      assert(view.opened and #displayCalls==0)
      assert(view:close(false) and visibility==0 and #displayCalls==0)
    ''')


@pytest.mark.parametrize('change,restored', [
    ('snapshot.modal=11', True),
    ('snapshot.screen=41;snapshot.modal=-1', False),
    ('snapshot.inputGeneration=5;snapshot.modal=-1', False),
])
def test_replacement_restores_only_same_world_owner(lua, change, restored):
    prepare(lua)
    lua.execute('''assert(view:open())''')
    lua.execute(change)
    lua.execute('''
      assert(not require('code/editor_ownership').reconcile(view,snapshot))
      assert(not view.opened and not view.restoreHoverDisplay)
    ''')
    assert lua.globals().visibility == int(restored)
