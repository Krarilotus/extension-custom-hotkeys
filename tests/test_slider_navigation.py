import pytest
from test_button_activation import setup


@pytest.mark.parametrize('change', ['', 'raw.text=true', 'raw.modal="other"',
    'rows[1].action=201', 'nav:cancel()', 'busy=true'])
def test_slider_step_is_deferred_once_and_canceled_on_owner_change(lua, change):
    setup(lua)
    lua.execute('''
      rows[1].kind=5;nav.context=context;nav.address=10
      nav.adapter.adjust=function(row,delta)
        assert(row.kind==5 and delta==-1);calls=calls+1;nav:beforeFrame()
      end
      assert(nav:adjust(-1,context));assert(not nav:adjust(1,context));assert(calls==0)
    ''')
    lua.execute(change)
    lua.execute('nav:beforeFrame();nav:beforeFrame()')
    assert lua.globals().calls == (0 if change else 1)


def test_native_slider_reuses_bounds_and_handler_with_clamped_native_step(lua):
    lua.execute('''
      local current,step,queries,submits=98,5,0,0
      local item={firstItemTypeData={itemsToSkip=5},menuItemActionHandler={}}
      item.menuItemActionHandler.slider=function(parameter,event,lo,hi,value)
        assert(parameter==30)
        if event==1 then lo[0]=0;hi[0]=100;value[0]=current;queries=queries+1
        else assert(event==2);current=value[0];submits=submits+1 end
      end
      package.loaded.ffi={new=function() return {[0]=0} end,
        cast=function(kind,address) assert(kind=='MenuItem *' and address==77);return {[0]=item} end}
      local adapter=require('code/native/menu_adapter').new({}, {})
      adapter.adjust({address=77,parameter=30},1);assert(current==100 and submits==1)
      adapter.adjust({address=77,parameter=30},1);assert(submits==1)
      adapter.adjust({address=77,parameter=30},-1);assert(current==95 and submits==2)
      current=-1;adapter.adjust({address=77,parameter=30},1);assert(submits==2)
      assert(queries==4)
    ''')
