def setup(lua):
    lua.execute('''
      current=facts('game.build');current.screen='14';c=Context.resolve(current)
      s={player=1,building=7,selectedCount=0,screen=16,tab=44}
      object={id=7,uid=123,type=107,state=2,owner=1,x=90,y=80}
      calls={};tile=456;live=true
      a={resolve=function() return current end,snapshot=function() return s end,
        buildingByID=function(id) assert(id==7);return object end,
        clearGroup=function(g) calls[#calls+1]={'clear',g} end,
        openBuilding=function(id) calls[#calls+1]={'open',id};return true end,
        focus=function(x,y) calls[#calls+1]={'focus',x,y} end,
        focusTile=function(t) calls[#calls+1]={'tile',t} end,
        viewportTile=function() return tile end,sameWorld=function() return live end,
        group=function() return nil end}
      w=require('code/world_actions').new(a)
    ''')


def test_building_assignment_recall_focus_and_uid_reuse(lua):
    setup(lua)
    lua.execute('''
      assert(w:dispatch('unit.group.assign.1',c))
      assert(#calls==1 and calls[1][1]=='clear' and calls[1][2]==1)
      s.building=0
      assert(w:dispatch('unit.group.recall.1',c,true))
      assert(#calls==2 and calls[2][1]=='open' and calls[2][2]==7)
      s.building=7
      assert(w:dispatch('unit.group.recall.1',c,true))
      assert(#calls==3 and calls[3][1]=='focus')
      -- A new object in the same slot/position must never inherit the bookmark.
      object={id=7,uid=124,type=107,state=2,owner=1,x=90,y=80}
      assert(w:dispatch('unit.group.recall.1',c,true)=='native' and #calls==3)
      assert(not w.buildingGroups[1])
    ''')


def test_foreign_removed_and_changed_objects_do_not_recall(lua):
    setup(lua)
    lua.execute('''
      for _,field in ipairs({'owner','state','uid','x','y','type'}) do
        object={id=7,uid=123,type=107,state=2,owner=1,x=90,y=80}
        assert(w:dispatch('unit.group.assign.2',c))
        local saved=object
        object={id=7,uid=123,type=107,state=2,owner=1,x=90,y=80}
        object[field]=object[field]+1
        local before=#calls
        assert(not w:dispatch('camera.group.2',c))
        assert(#calls==before and not w.buildingGroups[2])
      end
      object.owner=2;assert(not w:dispatch('unit.group.assign.2',c))
    ''')


def test_camera_bookmarks_are_local_and_expire_on_world_replacement(lua):
    setup(lua)
    lua.execute('''
      assert(w:dispatch('camera.bookmark.assign.4',c))
      tile=999
      assert(w:dispatch('camera.bookmark.recall.4',c))
      assert(#calls==1 and calls[1][1]=='tile' and calls[1][2]==456)
      current.text=true
      assert(not w:dispatch('camera.bookmark.recall.4',c) and #calls==1)
      current.text=false
      assert(w:dispatch('unit.group.assign.1',c))
      w:observeLifetime();assert(w.hasBookmarks)
      live=false;w:observeLifetime()
      assert(not w.hasBookmarks and not next(w.cameraBookmarks) and not next(w.buildingGroups))
      assert(not w:dispatch('camera.bookmark.recall.4',c))
      live=true;tile=100;assert(w:dispatch('camera.bookmark.assign.4',c))
      w:resetBookmarks();assert(not w:dispatch('camera.bookmark.recall.4',c))
    ''')
