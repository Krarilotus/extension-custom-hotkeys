def test_storage_uses_fixed_install_local_files_and_distinguishes_missing(lua):
    lua.execute('''
      local B=require('code/ucp_storage')
      local calls={}
      local io={open=function(path,mode)
        calls[#calls+1]={path,mode};return nil,'localized error',2
      end}
      local boundary=B.new(io)
      local f,e=boundary:open('profiles-a.json','rb')
      assert(f==nil and e=='missing')
      assert(calls[1][1]=='ucp/custom-hotkeys-profiles-a.json' and calls[1][2]=='rb')
      io.open=function() return nil,'missing-looking text',13 end
      f,e=boundary:open('profiles-b.json','rb');assert(f==nil and e=='io')
      io.open=function() return nil,'no numeric errno' end
      f,e=boundary:open('profiles-b.json','rb');assert(f==nil and e=='io')
      assert(not pcall(boundary.open,boundary,'../other.json','wb'))
      assert(not pcall(boundary.open,boundary,'profiles-a.json','a'))
    ''')
