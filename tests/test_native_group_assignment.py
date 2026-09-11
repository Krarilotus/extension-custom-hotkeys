def test_native_group_assignment_preflights_members_before_mutating_groups(lua):
    lua.execute('''
      local memory={[0x1667fd4+0x334]=2,
        [0x13885e2+10*0x490]=1,[0x13885e2+11*0x490]=1}
      local ids={10,11};local calls={};local reads=0
      package.loaded.ffi={cast=function(kind,address)
        if kind=='void *' then return address end
        if kind=='int32_t *' or kind=='int16_t *' then return {[0]=memory[address]} end
        if address==0x522390 then return function(owner,tribe,index)
          assert(owner==0x1667f78 and tribe==1 and index>=0 and index<2)
          reads=reads+1;return ids[index+1] end end
        return function(...)
          calls[#calls+1]={address,...}
        end
      end}
      local world=require('code/native/world_actions').new({},nil)
      local a=world.adapter
      assert(a.validGroupMembers(1,1) and reads==2 and #calls==0)
      a.assignGroup(9,1)
      assert(#calls==2 and calls[1][1]==0x459bb0 and calls[1][2]==0x112b0b8)
      assert(calls[1][3]==9 and calls[2][1]==0x459c10)
      assert(calls[2][2]==0x112b0b8 and calls[2][3]==9 and calls[2][4]==1)
      for _,id in ipairs({0,-1,2500}) do
        ids[1]=id;assert(not a.validGroupMembers(1,1))
      end
      ids[1]=10;memory[0x13885e2+11*0x490]=2
      assert(not a.validGroupMembers(1,1))
      for _,count in ipairs({0,-1,2501,32767}) do
        memory[0x1667fd4+0x334]=count
        local before=reads
        assert(not a.validGroupMembers(1,1) and reads==before)
      end
      assert(#calls==2)
    ''')
