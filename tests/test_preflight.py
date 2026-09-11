import pytest


@pytest.mark.parametrize('value', ['true', 'nil', '0', "'false'", '{contents={value=false}}'])
def test_rejects_enabled_missing_and_non_normalized_legacy(lua, value):
    lua.execute(f'''
      local P=require('code/preflight')
      local cfg={{['ucp2-legacy-2.15.0']={{o_keys={{enabled={value}}}}}}}
      local active={{{{name='ucp2-legacy',version='2.15.0'}}}}
      local ok,err=P.check(cfg,active)
      assert(not ok and err=='activation.legacy-hotkeys')
    ''')


def test_absent_or_explicitly_disabled_legacy(lua):
    lua.execute('''
      local P=require('code/preflight')
      assert(P.check({},{}))
      assert(P.check({['ucp2-legacy-2.15.0']={o_keys={enabled=false},other=true}},
        {{name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check(nil,{}))
      assert(not P.check({['ucp2-legacy-2.15.0']={o_keys={enabled=false}}},{}))
    ''')


def test_sparse_or_malformed_extension_list_cannot_hide_legacy(lua):
    lua.execute('''
      local P=require('code/preflight')
      assert(not P.check({}, {[2]={name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check({}, {legacy={name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check({}, {[0]={name='ucp2-legacy',version='2.15.0'}}))
    ''')


def test_recorder_requires_verified_public_input_ownership_contract(lua):
    lua.execute('''
      local P=require('code/preflight')
      for _,version in ipairs({'0.48.4','0.50.3','99.0.0'}) do
        local ok,err=P.check({},{{name='recorder',version=version}})
        assert(not ok and err=='activation.recorder-api')
      end
      assert(P.check({},{{name='unrelated-extension',version='1.0.0'}}))
    ''')
