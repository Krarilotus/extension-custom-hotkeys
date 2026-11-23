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


def test_the_import_marker_is_one_fixed_file(lua, tmp_path):
    lua.globals().root = tmp_path.as_posix()
    (tmp_path / 'ucp').mkdir()
    lua.execute('''
      local B=require('code/ucp_storage')
      local boundary=B.new({open=function(path,mode) return io.open(root..'/'..path,mode) end})
      assert(not boundary.imported())
      assert(boundary.markImported())
      assert(boundary.imported())
    ''')
    assert [p.name for p in (tmp_path / 'ucp').iterdir()] == ['custom-hotkeys-0.2-imported']
