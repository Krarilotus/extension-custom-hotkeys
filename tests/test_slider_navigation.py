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


def test_native_slider_reuses_display_state_owner_step_and_authority(lua):
    lua.execute('''
      local current,submits,readonly=98,0,false
      local state={[0]=0,[1]=0,[2]=0}
      local function pointer(offset)
        return setmetatable({}, {
          __index=function(_,key) return state[offset+key] end,
          __newindex=function(_,key,value) state[offset+key]=value end,
          __add=function(_,value) return pointer(offset+value) end})
      end
      local item={menuItemActionHandler={}}
      item.menuItemActionHandler.slider=function(parameter,event,lo,hi,value)
        assert(parameter==30)
        if event==1 then lo[0]=0;hi[0]=100;value[0]=current
        elseif event==7 then assert(value[0]==1);value[0]=5
        else
          assert(event==2 and state[2]==value[0]);submits=submits+1
          if not readonly then current=value[0] end
        end
      end
      package.loaded.ffi={new=function() return {[0]=0} end,
        offsetof=function(name,field)
          assert(name=='MenuItem' and field=='secondItemTypeData');return 60 end,
        cast=function(kind,address)
          if kind=='MenuItem *' then assert(address==77);return {[0]=item} end
          if kind=='uint8_t *' then return address end
          assert(kind=='int *' and address==137);return pointer(0)
        end}
      local adapter=require('code/native/menu_adapter').new({}, {})
      adapter.adjust({address=77,parameter=30},1);assert(current==100 and state[2]==100 and submits==1)
      adapter.adjust({address=77,parameter=30},1);assert(submits==1)
      adapter.adjust({address=77,parameter=30},-1);assert(current==95 and state[2]==95 and submits==2)
      readonly=true;adapter.adjust({address=77,parameter=30},-1)
      assert(current==95 and state[2]==95 and submits==3)
      current=-1;adapter.adjust({address=77,parameter=30},1);assert(submits==3)
    ''')
