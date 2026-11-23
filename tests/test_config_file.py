import yaml
import pytest

from ucp_config_model import install

# The launcher's yaml stringify output: indented sequences, `{}` for empty maps.
LAUNCHER = """meta:
  version: 1.0.0
active: true
config-sparse:
  modules:
    other-module:
      config:
        language:
          contents:
            suggested-value: "no"
    custom-hotkeys:
      config: {}
  plugins: {}
  load-order:
    - extension: custom-hotkeys
      version: 0.3.0
config-full:
  modules:
    custom-hotkeys:
      config:
        bindings:
          zoom:
            in:
              contents:
                value:
                  wheel: up
                  mods: 1
    other-module:
      config:
        version-text:
          contents:
            value: "1.10"
  plugins: {}
  load-order:
    - extension: other-module
      version: 1.0.0
    - extension: custom-hotkeys
      version: 0.3.0
"""

CHANGES = '''
  changes={{path={'bindings','custom-hotkeys','game','quicksave'},value=key(65,1)},
    {path={'bindings','zoom','in'},value=nil,inherited={wheel='down',mods=1}},
    {path={'bindings','custom-hotkeys','unit','group','recall','1'},value=false}}
  function edit(text,version) return ConfigFile.edit(text,parse,changes,version or '0.3.0') end
'''


@pytest.fixture
def writer(lua):
    install(lua)
    lua.execute(CHANGES)
    return lua


def outside(text):
    """Lines that do not belong to a custom-hotkeys block, with their endings."""
    kept, skipping = [], None
    for line in text.splitlines(keepends=True):
        depth = len(line) - len(line.lstrip(' '))
        if skipping is not None and line.strip() and depth <= skipping:
            skipping = None
        if skipping is None and line.strip() == 'custom-hotkeys:':
            skipping = depth
            continue
        if skipping is None:
            kept.append(line)
    return kept


def test_only_the_hotkeys_blocks_change_and_every_other_line_is_kept(writer):
    result = writer.eval('edit')(LAUNCHER)
    assert isinstance(result, str)
    assert outside(result) == outside(LAUNCHER)
    document = yaml.safe_load(result)
    sparse = document['config-sparse']['modules']['custom-hotkeys']['config']['bindings']
    assert sparse['custom-hotkeys']['game']['quicksave'] == {
        'contents': {'suggested-value': {'scan': 65, 'mods': 1, 'extended': False}}}
    assert sparse['custom-hotkeys']['unit']['group']['recall']['1'] == {'contents': {'suggested-value': False}}
    assert 'zoom' not in sparse
    full = document['config-full']['modules']['custom-hotkeys']['config']['bindings']
    assert full['zoom']['in'] == {'contents': {'value': {'wheel': 'down', 'mods': 1}}}
    assert full['custom-hotkeys']['game']['quicksave']['contents']['value']['scan'] == 65
    assert document['config-sparse']['modules']['other-module']['config']['language']['contents'] == \
        {'suggested-value': 'no'}


def test_missing_module_block_inline_empty_maps_comments_and_line_endings(writer):
    edit = writer.eval('edit')
    text = LAUNCHER.replace("    custom-hotkeys:\n      config: {}\n", "")
    assert yaml.safe_load(edit(text))['config-sparse']['modules']['custom-hotkeys']['config']['bindings']
    text = LAUNCHER.replace("""  modules:
    other-module:
      config:
        language:
          contents:
            suggested-value: "no"
    custom-hotkeys:
      config: {}
""", "  modules: {}\n")
    assert yaml.safe_load(edit(text))['config-sparse']['modules']['custom-hotkeys']
    result = edit(LAUNCHER.replace('\n', '\r\n'))
    assert '\r\n' in result and '\n' not in result.replace('\r\n', '')
    mixed = LAUNCHER.replace('active: true\n', 'active: true\r\n').replace('config-sparse:\n', 'config-sparse: # user values\n')
    result = edit(mixed)
    assert 'active: true\r\nconfig-sparse: # user values\n' in result
    assert outside(result) == outside(mixed)
    assert edit(LAUNCHER.rstrip('\n')).endswith('0.3.0')


def test_a_config_that_does_not_run_this_module_or_is_not_block_style_is_refused(writer):
    edit = writer.eval('edit')
    inactive = LAUNCHER.replace("    - extension: custom-hotkeys\n      version: 0.3.0\n", "", 2)
    for text, version in ((inactive, None), (LAUNCHER, '0.2.19'),
                          (LAUNCHER.split('config-full:')[0], None),
                          ('config-sparse: {modules: {}}\nconfig-full: {modules: {custom-hotkeys: {}},'
                           ' load-order: [{extension: custom-hotkeys, version: 0.3.0}]}\n', None),
                          ('- not a map\n', None)):
        result, problem = edit(text, version)
        assert result is None and problem.startswith('config.'), (text, problem)
    assert edit(inactive)[1] == 'config.inactive'


def test_stage_writes_beside_the_config_and_refuses_a_file_changed_meanwhile(writer, tmp_path):
    target = tmp_path / 'ucp-config.yml'
    target.write_text(LAUNCHER)
    writer.globals().target = str(target)
    writer.execute('''
      local files=ConfigFile.files(io,os)
      local staged=assert(ConfigFile.stage(files,parse,target,changes,'0.3.0'))
      assert(staged.target==target and staged.staged==target..'.custom-hotkeys.tmp')
      assert(files.read(target)~=files.read(staged.staged))
      os.remove(staged.staged)
      local racing={read=function(path)
        local text=files.read(path)
        if path==target and staged.seen then return text..'# saved by the launcher\\n' end
        staged.seen=true
        return text
      end,write=files.write,remove=files.remove}
      local ok,err=ConfigFile.stage(racing,parse,target,changes,'0.3.0')
      assert(not ok and err=='config.changed')
      local failing={read=files.read,write=function() return false end,remove=files.remove}
      ok,err=ConfigFile.stage(failing,parse,target,changes,'0.3.0')
      assert(not ok and err=='config.write')
      ok,err=ConfigFile.stage(files,parse,target..'.missing',changes,'0.3.0')
      assert(not ok and err=='config.read')
    ''')
    assert sorted(p.name for p in tmp_path.iterdir()) == ['ucp-config.yml']
    assert target.read_text() == LAUNCHER


def test_a_result_that_reads_back_differently_is_refused(writer):
    writer.globals().launcher = LAUNCHER
    writer.execute('''
      for _,lose in ipairs({
        function(d) d.active=false end,
        function(d) d['config-full'].modules['custom-hotkeys'].config.bindings.zoom=nil end,
        function(d) d['config-sparse'].modules['other-module']=nil end}) do
        local calls=0
        local lossy=function(text)
          calls=calls+1
          local d=parse(text)
          if calls==2 then lose(d) end
          return d
        end
        local ok,err=ConfigFile.edit(launcher,lossy,{{path={'layout'},value='grid'}},'0.3.0')
        assert(not ok and err=='config.verify')
      end
    ''')
