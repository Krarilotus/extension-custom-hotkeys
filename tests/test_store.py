import hashlib
import json
from pathlib import Path

import pytest


@pytest.fixture
def disk(lua, tmp_path):
    lua_type = lua.eval('type')
    def to_python(value):
        if lua_type(value) == 'table':
            return {k: to_python(v) for k, v in value.items()}
        return value

    def no_duplicates(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('duplicate key')
            result[key] = value
        return result

    lua.globals().encode_json = lambda value: json.dumps(to_python(value), sort_keys=True, separators=(',', ':'))
    lua.globals().decode_json = lambda value: lua.table_from(json.loads(value, object_pairs_hook=no_duplicates), recursive=True)
    lua.globals().sha256 = lambda value: hashlib.sha256(value.encode('utf8')).hexdigest()
    lua.globals().store_dir = tmp_path.as_posix()
    lua.execute('''
      Store=require('code/store')
      fault=nil
      boundary={open=function(_,name,mode)
        if fault=='open' and mode=='wb' then return nil,'io' end
        if fault=='read' and mode=='rb' then return nil,'io' end
        local f,err,errno=io.open(store_dir..'/'..name,mode)
        if not f then return nil,errno==2 and 'missing' or 'io' end
        return {
          read=function(_,n) return f:read(n) end,
          write=function(_,bytes)
            if fault=='write' then f:write(bytes:sub(1,30)); return nil,'disk full' end
            return f:write(bytes)
          end,
          flush=function()
            if fault=='flush' then return nil,'flush failed' end
            return f:flush()
          end,
          close=function()
            local result=f:close()
            if fault=='close' then return nil,'close failed' end
            return result
          end,
        }
      end}
      codec={encode=function(t) return encode_json(t) end,decode=function(s) return decode_json(s) end}
      function openStore()
        return Store.new(boundary,codec,sha256,function(d) return Profiles.validate(catalog,d) end)
      end
      storage=openStore()
      local d,err=storage:load(); assert(not d and err=='store.missing')
      document=Profiles.initial(catalog)
    ''')
    return lua, tmp_path


def test_real_file_restart_and_latest_generation(disk):
    lua, _ = disk
    lua.execute('''
      assert(storage:save(document))
      document.profiles.Default.bindings['unit.move']=key(20)
      assert(storage:save(document))
      local restarted=openStore()
      local loaded=assert(restarted:load())
      assert(restarted.generation==2)
      assert(loaded.profiles.Default.bindings['unit.move'].scan==20)
    ''')


def test_portable_profile_exchange_uses_separate_files_and_import_is_draft_only(disk):
    lua, path = disk
    (path / 'ucp').mkdir()
    lua.execute('''
      local Storage=require('code/ucp_storage')
      local nativeIO={open=function(name,mode) return io.open(store_dir..'/'..name,mode) end}
      local function exchange()
        return Store.new(Storage.new(nativeIO,'exchange'),codec,sha256,
          function(d) return Profiles.validate(catalog,d) end)
      end
      local source=assert(Profiles.new(catalog,storage,router))
      source:begin();assert(source:create('Travel'));assert(source:bind('unit.move',key(20)))
      local exported=exchange();local _,err=exported:load();assert(err=='store.missing')
      assert(exported:save(source:export()))
      source:cancel();assert(source.committed.active=='Default')
      local imported=assert(exchange():load())
      source:begin();assert(source:import('Imported',imported))
      assert(source.draft.profiles.Imported.bindings['unit.move'].scan==20)
      assert(not source.committed.profiles.Imported and #calls==0)
      source:cancel();assert(not source.committed.profiles.Imported)
    ''')
    assert (path / 'ucp/custom-hotkeys-exchange-profiles-a.json').exists()
    assert not (path / 'ucp/custom-hotkeys-profiles-a.json').exists()
    assert not (path / 'profiles-a.json').exists()


def test_every_torn_prefix_recovers_last_usable_file(disk):
    lua, path = disk
    lua.execute('''
      assert(storage:save(document))
      document.profiles.Default.bindings['unit.move']=key(20)
      assert(storage:save(document))
    ''')
    alternate = path / 'profiles-b.json'
    full = alternate.read_bytes()
    previous = (path / 'profiles-a.json').read_bytes()
    for length in range(len(full)):
        alternate.write_bytes(full[:length])
        lua.execute("local s=openStore(); local d=assert(s:load()); assert(s.generation==1)")
        assert (path / 'profiles-a.json').read_bytes() == previous


@pytest.mark.parametrize('fault', ['open','write','flush','close'])
def test_io_failure_preserves_previous_file_and_active_profile(disk, fault):
    lua, path = disk
    lua.execute('assert(storage:save(document))')
    before = (path / 'profiles-a.json').read_bytes()
    lua.globals().fault = fault
    lua.execute('''
      document.profiles.Default.bindings['unit.move']=key(20)
      local ok,err=storage:save(document); assert(not ok and err=='store.write')
    ''')
    assert (path / 'profiles-a.json').read_bytes() == before
    lua.globals().fault = None
    lua.execute('assert(openStore():load())')


def test_unreadable_does_not_silently_restore_defaults(disk):
    lua, _ = disk
    lua.execute('''
      fault='read'
      local d,err=openStore():load(); assert(not d and err=='store.read')
    ''')


def test_corrupt_digest_and_payload_are_not_executed(disk):
    lua, path = disk
    lua.execute('assert(storage:save(document))')
    file = path / 'profiles-a.json'
    envelope = json.loads(file.read_text())
    envelope['payload'] = 'os.execute("untrusted")'
    file.write_text(json.dumps(envelope))
    lua.execute("local d,err=openStore():load(); assert(not d and err=='store.corrupt')")


def test_generation_tampering_is_detected(disk):
    lua, path = disk
    lua.execute('assert(storage:save(document))')
    file = path / 'profiles-a.json'
    envelope = json.loads(file.read_text())
    envelope['generation'] = 999999
    file.write_text(json.dumps(envelope))
    lua.execute("local d,err=openStore():load(); assert(not d and err=='store.corrupt')")


def test_invalid_store_must_not_be_overwritten(disk):
    lua, path = disk
    file = path / 'profiles-a.json'
    file.write_text('broken profile')
    lua.execute('''
      local s=openStore(); assert(not s:load())
      local ok,err=s:save(document); assert(not ok and err=='store.not-loaded')
    ''')
    assert file.read_text() == 'broken profile'
