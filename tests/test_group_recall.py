def test_native_group_scan_checks_holes_serials_and_all_dereferenced_ids(lua):
    lua.execute('''
      local memory={[0x1387f38]=2500};local calls={}
      local base=0x112b0b8+3*0x4e20
      for index=0,2499 do memory[base+index*8]=-1 end
      local function member(index,id,serial,owner,tile)
        memory[base+index*8]=id;memory[base+index*8+4]=serial
        memory[0x13885e4+id*0x490]=serial;memory[0x13885e2+id*0x490]=owner
        memory[0x13885d8+id*0x490]=2;memory[0x1388620+id*0x490]=tile
      end
      package.loaded.ffi={cast=function(kind,address)
        if kind=='void *' then return address end
        if kind=='int32_t *' or kind=='int16_t *' or kind=='uint8_t *' then
          return setmetatable({},{__index=function() return memory[address] or 0 end,
            __newindex=function(_,_,value) memory[address]=value end})
        end
        return function(...) calls[#calls+1]={address,...};return 0 end
      end}
      local groups=require('code/native/groups')
      assert(not groups.inspect(3,1))
      member(2,23,404,1,1234)
      local first=assert(groups.inspect(3,1));assert(first.id==23 and first.tile==1234)
      memory[base+2499*8]=2500;assert(not groups.inspect(3,1))
      memory[base+2499*8]=-1
      member(2499,24,405,2,2345);assert(not groups.inspect(3,1))
      memory[base+2499*8+4]=404 -- reused ID; native selection prunes this serial mismatch
      assert(groups.inspect(3,1).id==23)
      memory[0x1388620+23*0x490]=160000;assert(not groups.inspect(3,1))
      memory[0x1388620+23*0x490]=1234
      memory[0x13885d8+23*0x490]=0;assert(not groups.inspect(3,1))
      memory[0x13885d8+23*0x490]=2
      for _,address in ipairs({0x13887ec,0x13888a4,0x138887a}) do
        memory[address+23*0x490]=1;assert(not groups.inspect(3,1))
        memory[address+23*0x490]=0
      end
      memory[0x1387f38]=2501;assert(not groups.inspect(3,1))
      assert(not groups.inspect(-1,1) and not groups.inspect(10,1))
      assert(#calls==0) -- eligibility scanning is read-only
      memory[0x1387f58]=1;memory[0x1fe7d34]=48
      groups.recall(3)
      assert(#calls==3 and calls[1][1]==0x536c70 and calls[1][2]==0x1387f38)
      assert(calls[2][1]==0x535fd0 and calls[2][2]==0x1387f38 and calls[2][3]==3)
      assert(calls[3][1]==0x46b340 and calls[3][2]==0x1fe7d10)
      assert(calls[3][3]==14 and calls[3][4]==0)
      assert(memory[0x1fe7d48]==48 and memory[0x1fe7d34]==61)
      assert(memory[0x1fe7bec]==1 and memory[0x1387f48]==1 and memory[0x1387f4c]==1)
      assert(memory[0x1388490]==0 and memory[0xb48ee4]==1)
      memory[0x1387f58]=0;groups.recall(3);assert(#calls==5)
    ''')


def test_group_cycle_wraps_skips_empty_groups_and_submits_only_the_chosen_group(lua):
    lua.execute('''
      local raw=facts('game.build');local c=Context.resolve(raw)
      local available={[1]=true,[8]=true};local scanned={};local recalled={}
      local world=require('code/world_actions').new({resolve=function() return raw end,
        snapshot=function() return {player=1} end,
        group=function(group)
          scanned[#scanned+1]=group
          if available[group] then return {tile=group} end end,
        groupMatches=function() return false end,
        recallGroup=function(group) recalled[#recalled+1]=group end})
      assert(world:dispatch('unit.group.next',c));assert(recalled[1]==1 and #scanned==1)
      scanned={};assert(world:dispatch('unit.group.previous',c))
      assert(recalled[2]==8 and #scanned==3 and scanned[1]==0 and scanned[2]==9)
      assert(world:dispatch('unit.group.next',c));assert(recalled[3]==1)
      available={};scanned={}
      assert(not world:dispatch('unit.group.next',c))
      assert(#scanned==10 and #recalled==3 and world.groupCursor==1)
      raw.modal='10';scanned={}
      assert(not world:dispatch('unit.group.previous',c) and #scanned==0)
    ''')


def test_group_recall_and_camera_focus_are_distinct_and_recheck_context(lua):
    lua.execute('''
      local raw=facts('game.build');local c=Context.resolve(raw)
      local calls={};local valid=true;local matching=false
      local world=require('code/world_actions').new({resolve=function() return raw end,
        snapshot=function() return {player=1} end,
        group=function(group,player)
          assert(group==3 and player==1);if valid then return {id=23,tile=1234} end end,
        groupMatches=function() return matching end,
        focusTile=function(tile) calls[#calls+1]={'focus',tile} end,
        recallGroup=function(group) calls[#calls+1]={'recall',group} end})
      assert(world:dispatch('camera.group.3',c))
      assert(calls[1][1]=='focus' and calls[1][2]==1234)
      assert(world:dispatch('unit.group.recall.3',c))
      assert(calls[2][1]=='recall' and calls[2][2]==3)
      matching=true;assert(world:dispatch('unit.group.recall.3',c))
      assert(calls[3][1]=='focus') -- same selection: no duplicate selection command
      valid=false
      assert(not world:dispatch('unit.group.recall.3',c))
      assert(not world:dispatch('camera.group.3',c));valid=true
      for field,value in pairs({text=true,modal='10',state='replay',authority=false,
          owner='game.options',selection='changed',focused=false,generation=2}) do
        local old=raw[field];raw[field]=value
        assert(not world:dispatch('unit.group.recall.3',c))
        assert(not world:dispatch('camera.group.3',c));raw[field]=old
      end
      assert(#calls==3)
    ''')
