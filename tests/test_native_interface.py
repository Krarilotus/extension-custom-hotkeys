import pytest


def test_owner_c_exports_are_resolved_without_reinitializing_library(lua):
    lua.execute('''
      local names={}
      local library={getProcAddress=function(_,name)
        names[#names+1]=name
        return name=='_RegisterProc@8' and 123 or 456
      end}
      local api,pin=require('code/native/interface').open({openLibraryHandle=function(path)
        assert(path=='ucp/modules/winProcHandler/winProcHandler.dll'); return library
      end})
      assert(pin==library and api.RegisterProc==123 and api.CallNextProc==456)
      assert(#names==2 and names[1]=='_RegisterProc@8' and names[2]=='_CallNextProc@20')
    ''')


@pytest.mark.parametrize('address', ['nil','false','0','-1','4294967296','1.5'])
def test_missing_or_invalid_owner_export_rejects_before_registration(lua,address):
    lua.execute(f'''
      local ok=pcall(require('code/native/interface').open,{{openLibraryHandle=function()
        return {{getProcAddress=function() return {address} end}}
      end}})
      assert(not ok)
    ''')
