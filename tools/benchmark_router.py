"""Component-only input benchmark; native FFI/UI/command costs are excluded."""
from pathlib import Path
import importlib
import json
import platform

ROOT = Path(__file__).resolve().parents[1]
results = []
for engine in ('lua54', 'luajit21'):
    lua = importlib.import_module('lupa.' + engine).LuaRuntime(unpack_returned_tuples=True)
    lua.globals().source_root = ROOT.as_posix()
    lua.execute('''
      package.path=source_root..'/?.lua;'..package.path
      local Catalog=require('code/catalog')
      local Router=require('code/router')
      local entries={}
      for i=1,400 do
        entries[i]={id='sample.'..i,contexts={'owner.'..i},states={'live-sp'},
          command=false,default={scan=50,extended=false,mods=0}}
      end
      local catalog=Catalog.new(entries)
      local context={verified=true,focused=true,text=false,composing=false,
        transition=false,owner='owner.1',screen='world',panel='',modal='',focus='',
        selection='',targeting='',authority=true,state='live-sp',generation=1}
      local calls=0
      local router=Router.new(catalog,Catalog.defaults(catalog),{
        resolve=function() return context end,dispatch=function() calls=calls+1 end,
        cancelLocalHold=function() end,canRecover=function() return false end,
        recover=function() error('not expected') end})
      function measure(count,text)
        context.text=text
        local down={kind='down',scan=50,extended=false,mods=0,repeated=false,
          composing=false,win=false,altgr=false}
        local up={kind='up',scan=50,extended=false,mods=0,repeated=false,
          composing=false,win=false,altgr=false}
        local beforeCalls=calls
        collectgarbage('collect')
        local start=os.clock()
        for i=1,count do router:handle(down); router:handle(up) end
        local seconds=os.clock()-start
        assert(calls-beforeCalls==(text and 0 or count))
        return seconds
      end
    ''')
    for text_owned in (False, True):
        lua.globals().measure(1000, text_owned)
        count = 25000
        seconds = lua.globals().measure(count, text_owned)
        results.append({'runtime': engine, 'text_owned': text_owned,
                        'actions_sharing_key_in_disjoint_contexts': 400,
                        'messages': count * 2, 'cpu_seconds': seconds,
                        'microseconds_per_message': seconds * 1e6 / (count * 2)})
print(json.dumps({'platform': platform.platform(),
                  'scope': 'component CPU time; excludes native input, rendering and submission',
                  'results': results}, indent=2))
