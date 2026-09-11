def test_executable_gate_rejects_other_images_and_bad_reads(lua):
    lua.execute('''
      local check=require('code/executable').check
      local closed=false
      local io={open=function(name,mode)
        assert(name=='game.exe' and mode=='rb')
        return {read=function() return 'image' end,close=function() closed=true;return true end}
      end}
      local ok,err=check('game.exe',io,function() return 'other' end)
      assert(not ok and err=='executable.unsupported' and closed)
      assert(not check('../game.exe',io,function() error('must not hash') end))
      assert(check('game.exe',io,function(bytes)
        assert(bytes=='image')
        return '3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a'
      end))
    ''')


def test_input_patch_checks_shared_site_before_writing(lua):
    lua.execute('''
      local patch=require('code/input_patch')
      local writes=0
      local bytes={0xe9,0,0,0,0}
      local core={readBytes=function(address,size)
        assert(address==0x468100 and size==5);return bytes end,
        insertCode=function(address,size,code,returnTo,original)
          writes=writes+1
          assert(address==0x468100 and size==5 and original=='after' and returnTo==nil)
          assert(code[1]==0x9c and code[2]==0x60 and code[3]==0xfc and code[4]==0x51)
          assert(code[6][1]==0x78 and code[6][4]==0x12)
          return 0x10000000
        end}
      assert(not pcall(patch.install,core,0x12345678));assert(writes==0)
      bytes={0x83,0xec,0x08,0x53,0x55}
      assert(patch.install(core,0x12345678)==0x10000000 and writes==1)
      assert(not pcall(patch.install,core,0x12345678));assert(writes==1)
    ''')
