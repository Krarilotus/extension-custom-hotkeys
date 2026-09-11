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
        if kind=='uint32_t *' then assert(value==1044);return {[0]=0} end
        if type(value)=='table' and value.address then return value.address end
        return value
      end}
      local reader=require('code/native/menu_reader').new()
      local s={tab=13,subtab=0,modal=5,sliding=0,width=1280,height=720}
      local rows=assert(reader:read(55,s))
      assert(#rows==1 and rows[1].x==488 and rows[1].y==195)
      assert(rows[1].x+rows[1].width/2==638)
      anchor[0].currentBuildMenuButtonShift_0x14=10
      local value,err=reader:read(55,s);assert(not value and err=='menu.shifted')
      anchor[0].currentBuildMenuButtonShift_0x14=0
      anchor[0].menuItemArray={}
      value,err=reader:read(55,s);assert(not value and err=='menu.owner')
      array[0].menuPointer=nil
      value,err=reader:read(55,s);assert(not value and err=='menu.owner')
    ''')
