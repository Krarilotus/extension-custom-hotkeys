import pytest


@pytest.mark.parametrize('language,encoding', [
    ('english', 'cp1252'), ('american', 'cp1252'), ('german', 'cp1252'),
    ('french', 'cp1252'), ('italian', 'cp1252'), ('SPANISH', 'cp1252'), ('polish', 'cp1250'),
    ('russian', 'cp1251'), ('hungarian', 'cp1250'), ('turkish', 'cp1254'),
    ('chinese', 'gbk'), ('persian', 'cp1256'),
])
def test_actual_framework_languages_cover_actions_controls_and_native_font_bytes(lua, language, encoding):
    lua.globals().language = language
    labels = lua.eval("require('code/locale').new(language,function() return 'Native label' end)")
    entries = lua.eval("(require('code/entries'))")
    for action in entries.values():
        label = labels(action['id'])
        assert label != action['id']
        (label.replace('\u06cc', '\u064a') if encoding == 'cp1256' else label).encode(encoding)
    for key in ['title', 'profile', 'new', 'search', 'groups', 'all', 'capture', 'swap',
                'clear', 'reset', 'resetProfile', 'apply', 'cancel', 'unbound', 'press',
                'editing', 'invalid', 'conflict', 'group.hotkeys', 'group.camera', 'group.build',
                'import', 'export', 'exported', 'importName', 'fileError',
                'mainHelp1', 'mainHelp2']:
        label = labels(key)
        assert label != key, (language, key)
        (label.replace('\u06cc', '\u064a') if encoding == 'cp1256' else label).encode(encoding)
    for group in lua.eval("require('code/editor_groups').order").values():
        key = 'group.' + group
        assert labels(key) != key
        (labels(key).replace('\u06cc', '\u064a') if encoding == 'cp1256' else labels(key)).encode(encoding)
    for key in ['nativeKey', 'nativeAgain']:
        assert labels(key) != key
        (labels(key).replace('\u06cc', '\u064a') if encoding == 'cp1256' else labels(key)).encode(encoding)


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


def test_every_game_catalog_defines_all_keys_without_english_fallback(lua):
    lua.execute('''
      local locale=require('code/locale')
      local function chosen(fn)
        for i=1,20 do
          local name,value=debug.getupvalue(fn,i)
          if name=='chosen' then return value end
        end
        error('locale catalog missing')
      end
      local english=chosen(locale.new('english'))
      for _,language in ipairs({'american','german','french','italian','spanish','polish',
        'russian','hungarian','turkish','chinese','persian'}) do
        local catalog=chosen(locale.new(language))
        for key in pairs(english) do
          assert(type(catalog[key])=='string' and #catalog[key]>0,language..':'..key)
        end
        assert(catalog.nativeKey:match('%%s') and catalog.nativeAgain:match('%%s'))
      end
    ''')


def test_loaded_game_translation_takes_priority_and_unknown_marker_uses_ucp_language(lua):
    lua.execute('''
      local Locale=require('code/locale')
      for _,marker in ipairs({'russian','RU',' ru_RU ','ru-ru'}) do
        local labels=Locale.new('german',function(group,index)
          assert(group==6 and index==0); return marker
        end)
        assert(labels('title')==Locale.new('russian')('title'))
      end
      for _,marker in ipairs({'', 'unrecognized', ' --- '}) do
        assert(Locale.new('german',function() return marker end)('title')
          ==Locale.new('german')('title'))
      end
      assert(Locale.new('unrecognized')('title')==Locale.new('english')('title'))
    ''')
