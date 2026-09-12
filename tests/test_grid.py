def test_visual_slots_preserve_disabled_positions_and_ignore_other_controls(lua):
    lua.execute('''
      local Grid=require('code/grid')
      local selectors={
        {id='menu.build.castle',action=1,parameter=10,help=10},
        {id='build.select.first',action=2,parameter=1,help=1},
        {id='unit.control.siege',action=2,parameter=2,help=2},
        {id='build.select.third',action=2,parameter=3,help=3}}
      local rows={
        {address=20,x=30,y=100,kind=3,action=2,parameter=2,help=2},
        {address=10,x=0,y=100,kind=3,action=2,parameter=1,help=1,disabled=true},
        {address=99,x=0,y=0,kind=3,action=1,parameter=10,help=10},
        {address=30,x=0,y=130,kind=3,action=2,parameter=3,help=3},
        {address=98,x=0,y=50,kind=3,action=99,parameter=1,help=1}}
      assert(Grid.select(rows,selectors,1)==nil)
      assert(Grid.select(rows,selectors,2)==20 and Grid.select(rows,selectors,3)==30)
      assert(Grid.select(rows,selectors,4)==nil)
      rows[2].disabled=false;assert(Grid.select(rows,selectors,1)==10)
      rows[1].x=0;assert(Grid.select(rows,selectors,1)==nil)
    ''')


def test_grid_reuses_native_activation_revalidation(lua):
    lua.execute('''
      local Navigation=require('code/navigation')
      local row={address=100,x=10,y=20,width=20,height=20,kind=3,action=2,parameter=1,help=1}
      local selector={id='build.select.first',action=2,parameter=1,help=1}
      local controls={row};local clicks=0;local validate
      local cursor={moveTo=function() return true end,
        click=function(_,button,context,guard) clicks=clicks+1;validate=guard;return true end}
      local nav=Navigation.new({gridControls=function() return {row} end,
        controls=function() return controls end,point=function(r) return r.x,r.y end},cursor)
      local context=Context.resolve(facts())
      assert(nav:activateGrid(1,{selector},context));assert(clicks==1)
      assert(validate(context));controls={};assert(not validate(context))
      assert(not nav:activateGrid(1,{selector},context));assert(clicks==1)
      controls={row};cursor.pending=true
      assert(not nav:activateGrid(1,{selector},context));assert(clicks==1)
    ''')


def test_different_icon_heights_keep_visual_left_to_right_order(lua):
    lua.execute('''
      local Grid=require('code/grid');local selectors={};local rows={}
      for i,geometry in ipairs({{0,110,20},{30,100,40},{60,90,60},{90,140,20}}) do
        selectors[i]={id='build.select.'..i,action=2,parameter=i,help=i}
        rows[i]={address=i,x=geometry[1],y=geometry[2],height=geometry[3],
          kind=3,action=2,parameter=i,help=i}
      end
      for slot=1,4 do assert(Grid.select(rows,selectors,slot)==slot) end
      rows[2].disabled=true
      assert(Grid.select(rows,selectors,2)==nil)
      assert(Grid.select(rows,selectors,3)==3)
    ''')
