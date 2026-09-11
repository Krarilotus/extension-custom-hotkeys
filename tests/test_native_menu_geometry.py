def test_reader_uses_actual_item_owner_and_rejects_foreign_or_shifted_geometry(lua):
    lua.execute('''
      local array={}
      local pointer={}
      pointer.__sub=function(value,i) return setmetatable({address=value.address-i*80},pointer) end
      setmetatable(array,{__add=function(_,i) return setmetatable({address=1000+i*80},pointer) end})
      local anchor={[0]={menuItemArray=array,xPosition=388,yPosition=117,
        currentBuildMenuButtonShift_0x14=0}}
      array[0]={menuItemType=0x2000003,callbackParameter={parameter=3},
        firstItemTypeData={itemsToSkip=0},field9_0x28=0,
        iconDeactivated_0x36=0,field15_0x38=0,
        position={position={x=100,y=78}},itemWidth=300,itemHeight=27,
        menuItemActionHandler={simple=1234},ucId_0x30=0,menuPointer=anchor}
      array[1]={menuItemType=0x66,callbackParameter={parameter=0},
        firstItemTypeData={itemsToSkip=0},field9_0x28=0}
      local iterated={[0]={menuItemArray=array,xPosition=538,yPosition=132}}
      package.loaded.ffi={cast=function(kind,value)
        if kind=='Menu *' then assert(value==55);return iterated end
        if kind=='uintptr_t' and value==anchor then return 55 end
        if kind=='uint32_t *' then assert(value==1044);return {[0]=0} end
        if type(value)=='table' and value.address then return value.address end
        return value
      end}
      local reader=require('code/native/menu_reader').new()
      local s={tab=13,subtab=0,modal=5,sliding=0,width=1280,height=720}
      local rows=assert(reader:read(55,s))
      assert(#rows==1 and rows[1].x==488 and rows[1].y==195)
      assert(rows[1].x+rows[1].width/2==638)
      anchor[0].xPosition=558;anchor[0].yPosition=140
      rows=assert(reader:read(55,s,{menu=55,x=388,y=116}))
      assert(rows[1].x==488 and rows[1].y==194)
      local bad,why=reader:read(55,s,{menu=56,x=388,y=116})
      assert(not bad and why=='menu.owner')
      anchor[0].currentBuildMenuButtonShift_0x14=10
      local value,err=reader:read(55,s);assert(not value and err=='menu.shifted')
      anchor[0].currentBuildMenuButtonShift_0x14=0
      anchor[0].menuItemArray={}
      value,err=reader:read(55,s);assert(not value and err=='menu.owner')
      array[0].menuPointer=nil
      value,err=reader:read(55,s);assert(not value and err=='menu.owner')
    ''')


def test_options_origin_follows_active_composition_and_native_viewport(lua):
    lua.execute('''
      local options=require('code/options_context')
      local s={screen=14,modal=5,activeModalID=5,activeModalMenu=0xb971f0,
        textModal=5,textEditor=0,modal2=-1,modal3=-1,
        modalX=148,modalY=56,modalWidth=500,modalHeight=350,modalBorder=0x200,
        modalAnimation=0,modalClosing=0,viewOffsetX=240,viewOffsetY=60,
        width=1280,height=720}
      local o=assert(options.origin(s));assert(o.x==388 and o.y==116)
      s.modalBorder=2;o=assert(options.origin(s));assert(o.y==128)
      s.screen=16;s.modalBorder=0x200;s.viewOffsetX=0;s.viewOffsetY=0
      s.width=800;s.height=600
      o=assert(options.origin(s));assert(o.x==148 and o.y==56)
      for _,case in ipairs({{'modal',10},{'activeModalID',10},
          {'activeModalMenu',0xb965f0},{'modalClosing',1},{'modalAnimation',1},
          {'modalX',-1},{'modalWidth',1000},{'modalY',0.5},{'modalBorder',-1},
          {'textEditor',1},{'textModal',10},{'viewOffsetY',600}}) do
        local key,value=case[1],case[2];local old=s[key];s[key]=value
        assert(options.origin(s)==nil,key);s[key]=old
      end
      s.modalX=nil;assert(options.origin(s)==nil)
    ''')
