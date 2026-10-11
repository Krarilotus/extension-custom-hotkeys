import pytest


@pytest.mark.parametrize(('value', 'expected'), [
    ('true', (None, 'activation.legacy-hotkeys')),
    ('nil', True),
    ('0', (None, 'activation.config-unavailable')),
    ("'false'", (None, 'activation.config-unavailable')),
    ('{contents={value=false}}', (None, 'activation.config-unavailable')),
])
def test_checks_enabled_and_non_normalized_legacy(lua, value, expected):
    result = lua.execute(f'''
      local P=require('code/preflight')
      local cfg={{['ucp2-legacy-2.15.0']={{o_keys={{enabled={value}}}}}}}
      local active={{{{name='ucp2-legacy',version='2.15.0'}}}}
      return P.check(cfg,active)
    ''')
    assert result == expected


def test_absent_or_explicitly_disabled_legacy(lua):
    lua.execute('''
      local P=require('code/preflight')
      assert(P.check({},{}))
      assert(P.check({['ucp2-legacy-2.15.0']={o_keys={enabled=false},other=true}},
        {{name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check(nil,{}))
      assert(P.check({['ucp2-legacy-2.15.0']={o_keys={enabled=false}}},{}))
    ''')


def test_omitted_legacy_options_are_off_as_in_legacy_enable(lua):
    lua.execute('''
      local P=require('code/preflight')
      local active={{name='ucp2-legacy',version='2.15.1'}}
      assert(P.check({},active))
      assert(P.check({['ucp2-legacy-2.15.1']={}},active))
      assert(P.check({['ucp2-legacy-2.15.1']={o_keys={}}},active))
      assert(P.check({['ucp2-legacy-2.15.1']={o_keys={enabled=false}}},active))
      -- Inactive configuration cannot enable a Legacy port.
      assert(P.check({['ucp2-legacy-2.15.0']={o_keys={enabled=true}}},active))
      local ok,err=P.check({['ucp2-legacy-2.15.1']={o_keys={
        enabled=false,child={enabled=true}}}},active)
      assert(not ok and err=='activation.legacy-hotkeys')
    ''')


def test_sparse_or_malformed_extension_list_cannot_hide_legacy(lua):
    lua.execute('''
      local P=require('code/preflight')
      assert(not P.check({}, {[2]={name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check({}, {legacy={name='ucp2-legacy',version='2.15.0'}}))
      assert(not P.check({}, {[0]={name='ucp2-legacy',version='2.15.0'}}))
    ''')


def test_recorder_contract_is_checked_after_module_initialization(lua):
    lua.execute('''
      local P=require('code/preflight')
      for _,version in ipairs({'0.48.4','0.50.3','99.0.0'}) do
        assert(P.check({},{{name='recorder',version=version}}))
      end
      assert(P.check({},{{name='unrelated-extension',version='1.0.0'}}))
    ''')
