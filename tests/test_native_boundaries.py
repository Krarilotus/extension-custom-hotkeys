def test_input_patch_checks_shared_site_before_writing(lua):
    lua.execute('''
      -- A relocated game must patch the discovered entry, not the reference.
      require('code/addresses').inputFrame=0x678900
      local patch=require('code/input_patch')
      local writes=0
      local bytes={0xe9,0,0,0,0}
      local core={readBytes=function(address,size)
        assert(address==0x678900 and size==9);return bytes end,
        insertCode=function(address,size,code,returnTo,original)
          writes=writes+1
          assert(address==0x678900 and size==6 and original=='after' and returnTo==nil)
          assert(code[1]==0x9c and code[2]==0x60 and code[3]==0xfc and code[4]==0x56)
          assert(code[6][1]==0x78 and code[6][4]==0x12)
          return 0x10000000
        end}
      assert(not pcall(patch.install,core,0x12345678));assert(writes==0)
      bytes={0xff,0x15,0,0,0,0,0x8b,0x4e,0x14}
      assert(patch.install(core,0x12345678)==0x10000000 and writes==1)
      assert(not pcall(patch.install,core,0x12345678));assert(writes==1)
    ''')
