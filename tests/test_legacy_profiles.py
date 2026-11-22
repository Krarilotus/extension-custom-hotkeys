import hashlib
import json

import pytest


def envelope(document, generation):
    payload = json.dumps(document, sort_keys=True, separators=(',', ':'))
    digest = hashlib.sha256(f'{generation}\n{payload}'.encode('utf8')).hexdigest()
    return json.dumps({'schema': 1, 'generation': generation, 'payload': payload, 'sha256': digest})


@pytest.fixture
def disk(lua, tmp_path):
    lua.globals().decode_json = lambda value: lua.table_from(json.loads(value), recursive=True)
    lua.globals().sha256 = lambda value: hashlib.sha256(value.encode('utf8')).hexdigest()
    lua.globals().store_dir = tmp_path.as_posix()
    lua.execute('''
      Legacy=require('code/legacy_profiles')
      fault=nil
      boundary={open=function(_,name,mode)
        if fault=='read' then return nil,'io' end
        local f,err,errno=io.open(store_dir..'/'..name,mode)
        if not f then return nil,errno==2 and 'missing' or 'io' end
        return f
      end}
      codec={decode=function(s) return decode_json(s) end}
      function loadLegacy() return Legacy.load(boundary,codec,sha256) end
    ''')
    return lua, tmp_path


def profile(bindings, preset='game-default', schema=3, unavailable=None):
    entry = {'bindings': bindings, 'preset': preset}
    if unavailable:
        entry['unavailable'] = unavailable
    return {'schema': schema, 'active': 'Mine', 'profiles': {'Mine': entry, 'Other': {'bindings': {}}}}


def test_newest_generation_wins_and_a_torn_successor_falls_back(disk):
    lua, path = disk
    (path / 'profiles-a.json').write_text(envelope(profile({'a': 1}), 1))
    (path / 'profiles-b.json').write_text(envelope(profile({'b': 2}), 2))
    lua.execute("assert(loadLegacy().profiles.Mine.bindings.b==2)")
    full = (path / 'profiles-b.json').read_bytes()
    for length in range(0, len(full), 7):
        (path / 'profiles-b.json').write_bytes(full[:length])
        lua.execute("assert(loadLegacy().profiles.Mine.bindings.a==1)")


def test_missing_corrupt_unreadable_and_ambiguous_slots(disk):
    lua, path = disk
    lua.execute("local d,err=loadLegacy(); assert(not d and err=='store.missing')")
    (path / 'profiles-a.json').write_text('broken profile')
    lua.execute("local d,err=loadLegacy(); assert(not d and err=='store.corrupt')")
    data = json.loads(envelope(profile({}), 1))
    data['payload'] = 'os.execute("untrusted")'
    (path / 'profiles-a.json').write_text(json.dumps(data))
    lua.execute("local d,err=loadLegacy(); assert(not d and err=='store.corrupt')")
    (path / 'profiles-a.json').write_text(envelope(profile({'a': 1}), 3))
    (path / 'profiles-b.json').write_text(envelope(profile({'b': 1}), 3))
    lua.execute("local d,err=loadLegacy(); assert(not d and err=='store.ambiguous')")
    lua.execute("fault='read'; local d,err=loadLegacy(); assert(not d and err=='store.read')")


def test_only_chords_that_differ_from_the_layout_and_provider_entries_become_explicit(lua):
    lua.execute('''
      local Legacy=require('code/legacy_profiles')
      local c=Catalog.production()
      local grid=c.presets.grid.bindings
      local bindings={}
      for id,value in pairs(grid) do bindings[id]=value end
      bindings['game.quicksave']=key(65,1)
      bindings['grid.slot.1']=false
      bindings['ext.zoom.in']={wheel='up',mods=1}
      bindings['retired.action']=key(66)
      local doc={schema=3,active='Mine',profiles={Mine={preset='grid',bindings=bindings,
        unavailable={['ext.zoom.out']=false,['ext.gone.act']=key(67)}}}}
      local migrated=assert(Legacy.explicit(c,doc))
      assert(migrated.layout=='grid')
      local count=0;for _ in pairs(migrated.explicit) do count=count+1 end
      assert(count==5,count)
      assert(migrated.explicit['game.quicksave'].scan==65 and migrated.explicit['grid.slot.1']==false)
      assert(migrated.explicit['ext.zoom.in'].wheel=='up' and migrated.explicit['ext.zoom.out']==false)
      assert(migrated.explicit['ext.gone.act'].scan==67)
      doc.profiles.Mine.preset=nil
      assert(Legacy.explicit(c,doc).layout=='game-default')
      doc.schema=5;assert(not Legacy.explicit(c,doc))
    ''')


def test_schema_1_unbound_group_recall_keeps_the_native_number(lua):
    lua.execute('''
      local Legacy=require('code/legacy_profiles')
      local c=Catalog.production()
      local bindings={['unit.group.recall.1']=false,['game.quicksave']=false}
      local migrated=Legacy.explicit(c,{schema=1,active='Default',profiles={Default={bindings=bindings}}})
      assert(migrated.explicit['unit.group.recall.1']==nil and migrated.explicit['game.quicksave']==false)
    ''')


def test_migration_writes_into_the_config_once_and_config_entries_win(lua):
    lua.execute('''
      local Legacy=require('code/legacy_profiles')
      local c=Catalog.production()
      local doc={schema=3,active='Mine',profiles={Mine={preset='grid',
        bindings={['game.quicksave']=key(65,1),['game.quickload']=key(66,1)},
        unavailable={['ext.gone.act']=key(67)}}}}
      local config=memoryConfig()
      config.tree={bindings={['custom-hotkeys']={game={quickload=key(68,1)}}}}
      local source=Bindings.source(c,config.tree,config.tree)
      source.legacy=Legacy.explicit(c,doc)
      local r=Router.new(c,Catalog.defaults(c),adapter)
      local b=Bindings.new(c,source,config,r)
      assert(b.migration.saved and #config.saves==1)
      assert(config.tree.layout=='grid' and config.tree.bindings['custom-hotkeys'].game.quicksave.scan==65)
      assert(config.tree.bindings['custom-hotkeys'].game.quickload.scan==68)
      assert(config.tree.bindings.gone.act.scan==67)
      assert(b.committed.active=='grid' and r.bindings['game.quicksave'].scan==65)
      config.failed=true
      local again=Bindings.source(c,{},{});again.legacy=source.legacy
      assert(not Bindings.new(c,again,config,r).migration.saved)
    ''')
