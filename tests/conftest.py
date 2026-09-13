from pathlib import Path
import pytest
import importlib

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(params=['lua54', 'luajit21'])
def lua(request):
    runtime = importlib.import_module('lupa.' + request.param).LuaRuntime(unpack_returned_tuples=True)
    runtime.globals().source_root = ROOT.as_posix()
    runtime.execute("package.path = source_root .. '/?.lua;' .. package.path")
    import json
    addresses = json.loads((ROOT / 'tests/fixtures/reference_addresses.json').read_text())
    runtime.globals().reference_addresses = runtime.table_from(addresses)
    runtime.execute("package.loaded['code/addresses'] = reference_addresses")
    runtime.execute(''' 
      Binding = require('code/binding')
      Catalog = require('code/catalog')
      Context = require('code/context')
      Router = require('code/router')
      Profiles = require('code/profiles')
      require('code/dialog_context').bind(function(id)
        return id==5 and reference_addresses.optionsMenu or nil
      end)
      function key(scan, mods, extended)
        return {scan=scan, mods=mods or 0, extended=extended or false}
      end
      function facts(owner, state)
        return {verified=true, focused=true, text=false, composing=false,
          transition=false, owner=owner or 'game', screen='world', panel='build',
          modal='', focus='', selection='unit', targeting='', authority=true,
          state=state or 'live-sp', generation=1}
      end
      function event(scan, kind, mods)
        return {scan=scan, kind=kind or 'down', mods=mods or 0, extended=false,
          repeated=false, altgr=false, win=false, composing=false}
      end
      function repeat_event(scan, mods)
        local e=event(scan,'down',mods); e.repeated=true; return e
      end
      function fixture()
        catalog = Catalog.new({
          {id='camera.left', contexts={'game'}, states={'live-sp','live-mp'},
           command=false, default=key(30)},
          {id='unit.move', contexts={'game'}, states={'live-sp','live-mp'},
           command=true, default=key(50)},
          {id='market.buy', contexts={'market'}, states={'live-sp','live-mp'},
           command=true, default=key(48)},
          {id='menu.back', contexts={'menu'}, states={'menu'},
           command=false, default=key(1)}})
        current=facts(); calls={}; recovered=0
        adapter={resolve=function() return current end,
          dispatch=function(id) calls[#calls+1]=id end,
          cancelLocalHold=function() end,
          canRecover=function(c) return c.owner=='game' or c.owner=='menu' end,
          recover=function() recovered=recovered+1 end}
        router=Router.new(catalog, Catalog.defaults(catalog), adapter)
      end
      fixture()
    ''')
    return runtime
