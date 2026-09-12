import pytest


def setup(lua):
    lua.execute('''
      local Cursor=require('code/cursor')
      local Navigation=require('code/navigation')
      raw=facts('game.build','live-sp');context=Context.resolve(raw)
      busy=false;calls=0
      rows={{address=10,x=700,y=600,width=32,height=32,kind=3,
        action=200,parameter=51,help=65578}}
      cursor=Cursor.new({resolve=function() return raw end,
        position=function() return 200,200 end,bounds=function() return 1280,720 end,
        busy=function() return busy end,
        move=function() error('building activation moved cursor') end,
        button=function() error('building activation simulated click') end,cancel=function() end})
      nav=Navigation.new({controls=function() return rows end,
        gridControls=function() return rows end,
        invoke=function(row)
          calls=calls+1;assert(row.action==200 and row.parameter==51)
          nav:beforeFrame() -- synchronous re-entry cannot repeat the callback
        end},cursor)
      selector={id='build.select.woodcutter',action=200,parameter=51,help=65578}
    ''')


@pytest.mark.parametrize('grid', [False, True])
def test_native_button_preserves_world_pointer_and_invokes_once(lua, grid):
    setup(lua)
    lua.globals().grid = grid
    lua.execute('''
      if grid then assert(nav:activateGrid(1,{selector},context))
      else assert(nav:activateMatching(selector,context)) end
      assert(calls==0 and nav.pending and not cursor.pending)
      assert(not nav:activateMatching(selector,context))
      nav:beforeFrame();nav:beforeFrame()
      assert(calls==1 and not nav.pending and not cursor.pending)
      local x,y=cursor.adapter.position();assert(x==200 and y==200)
    ''')


@pytest.mark.parametrize('change', [
    "raw.text=true", "raw.focused=false", "raw.modal='dialog'",
    "raw.generation=2", "raw.panel='other'", "busy=true", "rows={}",
    "rows[1].action=201", "rows[1].parameter=52", "rows[1].help=65600",
    "rows[1].kind=6", "nav:cancel()",
])
def test_native_button_rechecks_owner_and_control_before_callback(lua, change):
    setup(lua)
    lua.execute("assert(nav:activateMatching(selector,context));" + change)
    lua.execute('nav:beforeFrame();assert(calls==0 and not nav.pending and not cursor.pending)')
