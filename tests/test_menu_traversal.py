def test_native_tab_blocks_hidden_controls_and_stops_at_active_end(lua):
    lua.execute('''
      local T=require('code/menu_traversal')
      local rows={
        {type=0x64,parameter=1,skip=2}, {type=3}, {type=3},
        {type=0x64,parameter=2,skip=2}, {type=3}, {type=0x65,parameter=2},
        {type=3}, {type=0x66}}
      local function read(i)
        local r=rows[i];r.parameter=r.parameter or 0;r.skip=r.skip or 0
        r.condition=r.condition or 0;r.disabled=0;r.inactive=0;return r
      end
      local active=assert(T.active(read,#rows,{tab=2,subtab=0,modal=-1,sliding=0}))
      assert(#active==1 and active[1]==5)
    ''')


def test_modal_sliding_and_disabled_rows_do_not_become_candidates(lua):
    lua.execute('''
      local T=require('code/menu_traversal')
      local rows={
        {type=0x80000003},{type=3,disabled=1},{type=3,inactive=1},
        {type=0},{type=1},{type=9},{type=3},{type=8},{type=3},{type=0x66}}
      local function read(i)
        local r=rows[i];r.parameter=0;r.skip=0;r.condition=0
        r.disabled=r.disabled or 0;r.inactive=r.inactive or 0;return r
      end
      assert(#assert(T.active(read,#rows,{tab=0,subtab=0,modal=25,sliding=0}))==0)
      local active=assert(T.active(read,#rows,{tab=0,subtab=0,modal=-1,sliding=1}))
      assert(#active==1 and active[1]==7)
    ''')


def test_subtab_alternative_is_selected_without_activating_hidden_siblings(lua):
    lua.execute('''
      local T=require('code/menu_traversal')
      local rows={{type=0x08000003},{type=0x04000003,condition=1},
        {type=0x04000003,condition=2},{type=0x66}}
      local function read(i)
        local r=rows[i];r.parameter=0;r.skip=0;r.condition=r.condition or 0
        r.disabled=0;r.inactive=0;return r
      end
      local active=assert(T.active(read,#rows,{tab=0,subtab=2,modal=-1,sliding=0}))
      assert(#active==1 and active[1]==3)
    ''')


def test_corrupt_group_skip_fails_without_reading_past_array(lua):
    lua.execute('''
      local T=require('code/menu_traversal')
      local function read(i)
        assert(i<=2)
        return {type=i==1 and 0x21000000 or 0x66,parameter=0,skip=4096,
          condition=0,disabled=0,inactive=0}
      end
      local result=T.active(read,2,{tab=0,subtab=0,modal=-1,sliding=0})
      assert(result==nil)
    ''')


def test_grid_inventory_includes_disabled_but_never_hidden_controls(lua):
    lua.execute('''
      local T=require('code/menu_traversal')
      local rows={{type=0x64,parameter=1,skip=1},{type=3},
        {type=0x64,parameter=2,skip=3},{type=3,disabled=1},
        {type=3,inactive=1},{type=3},{type=0x66}}
      local function read(i)
        local r=rows[i];r.parameter=r.parameter or 0;r.skip=r.skip or 0
        r.condition=0;r.disabled=r.disabled or 0;r.inactive=r.inactive or 0;return r
      end
      local state={tab=2,subtab=0,modal=-1,sliding=0}
      local active=assert(T.active(read,#rows,state))
      assert(#active==1 and active[1]==6)
      local grid=assert(T.active(read,#rows,state,true))
      assert(#grid==2 and grid[1]==4 and grid[2]==6)
    ''')
