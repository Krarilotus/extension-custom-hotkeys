"""Test models of the two owners of ucp-config.yml.

Launcher: UCP3-GUI 1.0.17 preview 8903d4fb. import-button-callback.ts
constructUserConfigObjects (user values = contents leaves of config-sparse),
state/change.ts generateAndSetFullConfig (full = defined, then user values) and
config-files.ts serializeUCPConfig (sparse leaves get suggested-value, full
leaves get value; explicitly activated extensions get sparse module and
load-order entries, all active ones get full entries) and load-order.ts
serializeLoadOrder ({extension, version}).

Framework: UCP 3.0.7 main.lua passes config-full.modules.<name>.config through
config/init.lua normalizeContentsValues to the module's enable().
"""
import copy
import hashlib
import yaml


def collect(tree, url, out):
    if isinstance(tree, dict) and 'contents' in tree:
        contents = tree['contents']
        for key in ('value', 'required-value', 'suggested-value'):
            if key in contents:
                out[url] = contents[key]
                break
    elif isinstance(tree, dict):
        for key, value in tree.items():
            collect(value, f'{url}.{key}', out)


class Launcher:
    """Launcher state for one config: active extensions, plugin suggestions, user values."""

    VERSIONS = {'custom-hotkeys': '0.3.0'}

    def __init__(self, active, defined=None, user=None, explicit=None):
        self.active = list(active)
        self.explicit = list(explicit if explicit is not None else active)
        self.defined = dict(defined or {})
        self.user = dict(user or {})

    @classmethod
    def load(cls, path, defined=None):
        document = yaml.safe_load(path.read_text(encoding='utf-8'))
        user = {}
        for part in ('modules', 'plugins'):
            for name, entry in (document['config-sparse'].get(part) or {}).items():
                collect((entry or {}).get('config') or {}, name, user)
        active = [item['extension'] for item in document['config-full']['load-order']]
        explicit = [item['extension'] for item in document['config-sparse']['load-order']]
        return cls(active, defined, user, [n for n in explicit if n in active])

    def full(self):
        return {**self.defined, **self.user}

    def serialize(self):
        def part(values, field, extensions):
            result = {'modules': {}, 'plugins': {}, 'load-order': [
                {'extension': n, 'version': self.VERSIONS.get(n, '1.0.0')} for n in extensions]}
            for name in extensions:
                result['modules'][name] = {'config': {}}
            for url, value in values.items():
                name, *path = url.split('.')
                if name not in self.active:
                    continue
                node = result['modules'].setdefault(name, {'config': {}})['config']
                for key in path[:-1]:
                    node = node.setdefault(key, {})
                node[path[-1]] = {'contents': {field: copy.deepcopy(value)}}
            return result
        return {'meta': {'version': '1.0.0'}, 'active': True,
                'config-sparse': part(self.user, 'suggested-value', self.explicit),
                'config-full': part(self.full(), 'value', self.active)}

    def save(self, path):
        path.write_text(yaml.safe_dump(self.serialize(), sort_keys=False), encoding='utf-8')


NORMALIZE = '''
  function normalize(config)
    for k,v in pairs(config) do
      if type(v)=='table' then
        local contents=v.contents
        if contents==nil then normalize(v)
        elseif type(contents)=='table' then
          local value=nil
          if contents.value~=nil then value=contents.value
          elseif contents['required-value']~=nil then value=contents['required-value']
          elseif contents['suggested-value']~=nil then value=contents['suggested-value'] end
          config[k]=value
        end
      end
    end
  end
'''


def install(lua):
    """Lua globals: parse (YAML), normalize (framework) and launch (framework + runtime)."""
    def to_lua(value):
        if isinstance(value, dict):
            return lua.table_from({k: to_lua(v) for k, v in value.items()})
        if isinstance(value, list):
            return lua.table_from([to_lua(v) for v in value])
        return value
    lua.globals().parse_yaml = lambda text: to_lua(yaml.safe_load(text))
    lua.globals().digest = lambda text: hashlib.sha256(text.encode('utf8')).hexdigest()
    lua.execute(NORMALIZE + '''
      ConfigFile=require('code/config_file')
      function parse(text) return parse_yaml(text) end
      local function copy(v)
        if type(v)~='table' then return v end
        local r={} for k,x in pairs(v) do r[k]=copy(x) end return r
      end
      -- What a launch read from a config document, for the writer's baseline.
      function loadedOf(document)
        local effective=copy(document['config-full'].modules['custom-hotkeys'].config or {})
        normalize(effective)
        return {sparse=copy(document['config-sparse']),
          loadOrder=copy(document['config-full']['load-order']),effective=effective}
      end
      -- One game launch with the config at `path`: the framework reads the
      -- file, the runtime builds the bindings and Apply writes back to it.
      function launch(path,catalog,router,legacy)
        local file=assert(io.open(path,'rb'));local text=file:read('*a');file:close()
        local document=parse(text)
        local effective=copy(document['config-full'].modules['custom-hotkeys'].config or {})
        normalize(effective)
        local explicit=Bindings.explicitTree(document,normalize,copy)
        local source=Bindings.source(catalog,explicit,effective)
        if legacy and Bindings.fresh(explicit) then source.legacy=legacy end
        -- The native side replaces the file with MoveFileEx; os.rename cannot
        -- replace an existing file on Windows.
        local writer=ConfigFile.writer(ConfigFile.files(io,os),parse,path,'0.3.0',digest,
          normalize,loadedOf(document))
        local store={save=function(_,changes)
          local staged,problem=writer.stage(changes)
          if not staged then return nil,problem end
          os.remove(staged.target)
          local ok=assert(os.rename(staged.staged,staged.target))
          writer.replaced(true)
          return ok
        end}
        return Bindings.new(catalog,source,store,router)
      end
    ''')
