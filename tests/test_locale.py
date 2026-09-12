import pytest


@pytest.mark.parametrize('language,encoding', [
    ('english', 'cp1252'), ('american', 'cp1252'), ('german', 'cp1252'),
    ('french', 'cp1252'), ('italian', 'cp1252'), ('SPANISH', 'cp1252'), ('polish', 'cp1250'),
])
def test_actual_framework_languages_cover_actions_controls_and_native_font_bytes(lua, language, encoding):
    lua.globals().language = language
    labels = lua.eval("require('code/locale').new(language,function() return 'Native label' end)")
    entries = lua.eval("(require('code/entries'))")
    for action in entries.values():
        label = labels(action['id'])
        assert label != action['id']
        label.encode(encoding)
    for key in ['title', 'profile', 'new', 'search', 'groups', 'all', 'capture', 'swap',
                'clear', 'reset', 'resetProfile', 'apply', 'cancel', 'unbound', 'press',
                'editing', 'invalid', 'conflict', 'group.hotkeys', 'group.camera', 'group.build',
                'import', 'export', 'exported', 'importName', 'fileError',
                'mainHelp1', 'mainHelp2']:
        label = labels(key)
        assert label != key, (language, key)
        label.encode(encoding)
    for group in lua.eval("require('code/editor_groups').order").values():
        key = 'group.' + group
        assert labels(key) != key
        labels(key).encode(encoding)
    for key in ['nativeKey', 'nativeAgain', 'nativeGroupHint']:
        assert labels(key) != key
        labels(key).encode(encoding)


def test_profile_import_rejects_malformed_utf8_names(lua):
    lua.execute('''
      local document=Profiles.initial(catalog)
      for _,bad in ipairs({string.char(192,175),string.char(237,160,128),
        string.char(244,144,128,128),string.char(195)}) do
        document.active=bad
        document.profiles={[bad]={bindings=Catalog.defaults(catalog)}}
        assert(not Profiles.validate(catalog,document))
      end
    ''')
