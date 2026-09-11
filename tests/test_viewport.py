def test_native_graphics_inverse_mapping(lua):
    lua.execute('''
      local p=require('code/viewport').point
      local x,y,gx,gy=p(561,203,1280,720,1280,720)
      assert(x==561 and y==203 and gx==561 and gy==203)
      x,y,gx,gy=p(400,300,800,600,1280,720)
      assert(x==640 and y==360 and gx==400 and gy==300)
      x,y,gx,gy=p(1279,719,1280,720,800,600)
      assert(x==799 and y==524 and gx==1279 and gy==719)
      assert(not p(-1,10,800,600,1280,720))
      assert(not p(0,0,800,600,0,720))
    ''')
