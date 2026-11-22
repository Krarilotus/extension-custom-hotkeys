import pytest
import yaml

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
    - name: custom-hotkeys
      version: 0.2.19
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
    - name: custom-hotkeys
      version: 0.2.19
"""

CHANGES = '''
  changes={{path={'bindings','custom-hotkeys','game','quicksave'},value=key(65,1)},
    {path={'bindings','zoom','in'},value=nil,inherited={wheel='down',mods=1}},
    {path={'bindings','custom-hotkeys','unit','group','recall','1'},value=false}}
'''


@pytest.fixture
def writer(lua):
    install(lua)
    lua.execute(CHANGES)
    return lua


def outside(text):
    """Lines that do not belong to a custom-hotkeys block."""
    kept, skipping = [], None
    for line in text.splitlines():
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
    result = writer.eval('function(text) return ConfigFile.edit(text,parse,changes) end')(LAUNCHER)
    assert result is not None
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
    # Strings the parser could coerce elsewhere stay untouched bytes.
    assert document['config-sparse']['modules']['other-module']['config']['language']['contents'] == \
        {'suggested-value': 'no'}


def test_missing_module_block_inline_empty_maps_and_crlf(writer):
    edit = writer.eval('function(text) return ConfigFile.edit(text,parse,changes) end')
    text = LAUNCHER.replace("""    custom-hotkeys:
      config: {}
""", "")
    result = edit(text)
    assert yaml.safe_load(result)['config-sparse']['modules']['custom-hotkeys']['config']['bindings']
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


def test_flow_style_or_unexpected_documents_are_refused(writer):
    edit = writer.eval('function(text) return ConfigFile.edit(text,parse,changes) end')
    for text in ('config-sparse: {modules: {}}\nconfig-full: {modules: {}}\n',
                 'config-full:\n  modules: {}\n',
                 '- not a map\n',
                 'config-sparse:\n  modules: [1]\nconfig-full:\n  modules: {}\n'):
        result, problem = edit(text)
        assert result is None and problem.startswith('config.'), (text, problem)


def test_replace_keeps_the_old_file_when_writing_fails(writer, tmp_path):
    target = tmp_path / 'ucp-config.yml'
    target.write_text(LAUNCHER)
    writer.globals().target = str(target)
    writer.execute('''
      local files=ConfigFile.files(io,os)
      assert(ConfigFile.save(files,parse,target,changes))
      local failing=ConfigFile.files({open=function(path,mode)
        if mode=='wb' then return nil end
        return io.open(path,mode) end},os)
      before=files.read(target)
      local ok,err=ConfigFile.save(failing,parse,target,{{path={'layout'},value='grid'}})
      assert(not ok and err=='config.write' and files.read(target)==before)
      ok,err=ConfigFile.save(files,parse,target..'.missing',changes)
      assert(not ok and err=='config.read')
    ''')
    assert sorted(p.name for p in tmp_path.iterdir()) == ['ucp-config.yml']
