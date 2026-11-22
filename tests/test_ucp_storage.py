def test_storage_reads_fixed_install_local_files_and_distinguishes_missing(lua):
    lua.execute('''
      local B=require('code/ucp_storage')
      local calls={}
      local io={open=function(path,mode)
        calls[#calls+1]={path,mode};return nil,'localized error',2
      end}
      local boundary=B.new(io,os)
      local f,e=boundary:open('profiles-a.json','rb')
      assert(f==nil and e=='missing')
      assert(calls[1][1]=='ucp/custom-hotkeys-profiles-a.json' and calls[1][2]=='rb')
      io.open=function() return nil,'missing-looking text',13 end
      f,e=boundary:open('profiles-b.json','rb');assert(f==nil and e=='io')
      io.open=function() return nil,'no numeric errno' end
      f,e=boundary:open('profiles-b.json','rb');assert(f==nil and e=='io')
      assert(not pcall(boundary.open,boundary,'../other.json','rb'))
      assert(not pcall(boundary.open,boundary,'profiles-a.json','wb'))
    ''')


def test_retire_renames_existing_slots_and_keeps_a_recovery_copy(lua):
    lua.execute('''
      local B=require('code/ucp_storage')
      local present={['ucp/custom-hotkeys-profiles-b.json']=true}
      local renamed={}
      local io={open=function(path) if present[path] then return {close=function() end} end end}
      local fs={remove=function() end,rename=function(from,to) renamed[#renamed+1]=from..'>'..to;return true end}
      assert(B.new(io,fs).retire())
      assert(#renamed==1 and renamed[1]=='ucp/custom-hotkeys-profiles-b.json>ucp/custom-hotkeys-profiles-b.json.migrated')
      fs.rename=function() return nil,'denied' end
      local ok,err=B.new(io,fs).retire();assert(not ok and err=='store.retire')
    ''')
