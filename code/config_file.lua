-- Writes explicit Custom Hotkeys entries into the active UCP config file. The
-- launcher owns that file and UCP 3.0.7 has no config writer, so only the
-- custom-hotkeys block of config-sparse (launcher user values) and config-full
-- (what the framework loads) is rewritten from its parsed content. Every other
-- line stays byte-identical, and the framework's YAML parser must read back
-- exactly the intended document before the file is staged for replacement.
local M = {}
local OWNER = 'custom-hotkeys'
-- Launcher qualifier for user values in config-sparse, plain value in config-full.
local SECTIONS = {{'config-sparse', 'suggested-value'}, {'config-full', 'value'}}

local function copy(value)
  if type(value) ~= 'table' then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

local function equal(a, b)
  if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end
  for key, value in pairs(a) do if not equal(value, b[key]) then return false end end
  for key in pairs(b) do if a[key] == nil then return false end end
  return true
end

local function scalar(value)
  local kind = type(value)
  if kind == 'boolean' then return tostring(value) end
  if kind == 'number' and value == math.floor(value) and value > -2^31 and value < 2^31 then
    return string.format('%d', value)
  end
  if kind == 'string' and not value:find('[%z\1-\31\127]') then
    return '"' .. value:gsub('[\\"]', '\\%0') .. '"'
  end
  error('config.value')
end

local function name(key)
  if type(key) ~= 'string' then error('config.key') end
  if key:match('^%a[%w_-]*$') then return key end
  return scalar(key)
end

local function emit(out, key, value, depth)
  local prefix = string.rep(' ', depth) .. name(key) .. ':'
  if type(value) ~= 'table' then out[#out + 1] = prefix .. ' ' .. scalar(value); return end
  local keys = {}
  for item in pairs(value) do
    if type(item) ~= 'string' then error('config.key') end
    keys[#keys + 1] = item
  end
  table.sort(keys)
  if #keys == 0 then out[#out + 1] = prefix .. ' {}'; return end
  out[#out + 1] = prefix
  for _, item in ipairs(keys) do emit(out, item, value[item], depth + 2) end
end

local function indent(line) return #line:match('^ *') end
local function skip(line) return line:match('^%s*$') or line:match('^%s*#') end

-- Finds a block-style key among the children of lines[first..last]. Returns
-- its line, the last line of its block and its inline value without a
-- trailing comment, or nil and the indentation of the existing children.
local function find(lines, first, last, parent, key)
  local depth
  for i = first, last do
    local line = lines[i].text
    if not skip(line) then
      local n = indent(line)
      if n <= parent then break end
      depth = depth or n
      if n == depth then
        local rest = line:sub(n + 1)
        local found, remainder = rest:match('^([%w_.-]+):%s*(.-)%s*$')
        if not found then found, remainder = rest:match('^"([^"]*)":%s*(.-)%s*$') end
        if found == key then
          local stop = i
          for j = i + 1, last do
            if not skip(lines[j].text) then
              if indent(lines[j].text) <= n then break end
              stop = j
            end
          end
          return {line=i, stop=stop, indent=n, rest=remainder:match('^#') and '' or remainder}
        end
      end
    end
  end
  return nil, depth or parent + 2
end

local function empty(block) return block.stop == block.line and (block.rest == '' or block.rest == '{}') end

local function splice(lines, section, module, newline)
  local top = find(lines, 1, #lines, -1, section)
  if not top or top.rest ~= '' then return nil, 'config.layout' end
  local modules = find(lines, top.line + 1, top.stop, top.indent, 'modules')
  if not modules then return nil, 'config.layout' end
  local block, first, stop = {}, nil, nil
  if empty(modules) then
    lines[modules.line].text = string.rep(' ', modules.indent) .. 'modules:'
    emit(block, OWNER, module, modules.indent + 2)
    first, stop = modules.line + 1, modules.line
  elseif modules.rest ~= '' then return nil, 'config.layout'
  else
    local owner, depth = find(lines, modules.line + 1, modules.stop, modules.indent, OWNER)
    emit(block, OWNER, module, owner and owner.indent or depth)
    if owner then first, stop = owner.line, owner.stop
    else first, stop = modules.stop + 1, modules.stop end
  end
  local ending = lines[first] and lines[first].ending or newline
  for _ = first, stop do table.remove(lines, first) end
  for i, text in ipairs(block) do table.insert(lines, first + i - 1, {text=text, ending=ending}) end
  return true
end

local function assign(tree, path, value)
  local node, trail = tree, {}
  for i = 1, #path - 1 do
    local key = path[i]
    if type(node[key]) ~= 'table' then
      if value == nil then return end
      node[key] = {}
    end
    trail[#trail + 1] = {node, key}
    node = node[key]
  end
  node[path[#path]] = value
  if value ~= nil then return end
  for i = #trail, 1, -1 do
    local parent, key = trail[i][1], trail[i][2]
    if next(parent[key]) ~= nil then break end
    parent[key] = nil
  end
end

-- The launcher lists every active extension in config-full's load order and
-- gives it a module entry; without both, this config does not run this module.
local function runs(document, version)
  local full = document['config-full']
  if document.active == false then return false end
  if type(full) ~= 'table' or type(full.modules) ~= 'table' or type(full.modules[OWNER]) ~= 'table'
      or type(full['load-order']) ~= 'table' then return false end
  for _, item in ipairs(full['load-order']) do
    if type(item) == 'table' and item.extension == OWNER and tostring(item.version) == version then return true end
  end
  return false
end

-- changes: {path={...below custom-hotkeys.config}, value=<explicit or nil>, inherited=<suggestion>}
function M.edit(text, parse, changes, version)
  local ok, document = pcall(parse, text)
  if not ok or type(document) ~= 'table' then return nil, 'config.parse' end
  if not runs(document, version) then return nil, 'config.inactive' end
  local lines, newline = {}, text:find('\r\n', 1, true) and '\r\n' or '\n'
  for body, ending in text:gmatch('([^\r\n]*)(\r?\n?)') do
    if body == '' and ending == '' then break end
    lines[#lines + 1] = {text=body, ending=ending}
  end
  local expected = copy(document)
  for _, section in ipairs(SECTIONS) do
    local part = expected[section[1]]
    if type(part) ~= 'table' or (part.modules ~= nil and type(part.modules) ~= 'table') then
      return nil, 'config.layout'
    end
    part.modules = part.modules or {}
    local module = part.modules[OWNER] or {}
    if type(module) ~= 'table' or (module.config ~= nil and type(module.config) ~= 'table') then
      return nil, 'config.layout'
    end
    module.config = module.config or {}
    for _, change in ipairs(changes) do
      local value = change.value
      if value == nil and section[1] == 'config-full' then value = change.inherited end
      assign(module.config, change.path, value ~= nil and {contents={[section[2]]=copy(value)}} or nil)
    end
    part.modules[OWNER] = module
    local emitted, problem = pcall(splice, lines, section[1], module, newline)
    if not emitted or not problem then return nil, emitted and 'config.layout' or 'config.value' end
  end
  local out = {}
  for i, line in ipairs(lines) do
    out[i] = line.text .. ((line.ending ~= '' or i < #lines) and (line.ending ~= '' and line.ending or newline) or '')
  end
  local result = table.concat(out)
  local parsed, reread = pcall(parse, result)
  if not parsed or not equal(reread, expected) then return nil, 'config.verify' end
  return result
end

-- File access through the framework's io.open.
function M.files(io, os)
  local function read(path)
    local file = io.open(path, 'rb')
    if not file then return nil end
    local ok, text = pcall(file.read, file, '*a')
    file:close()
    return ok and type(text) == 'string' and text or nil
  end
  local function write(path, text)
    local file = io.open(path, 'wb')
    if not file then return false end
    local wrote, written = pcall(file.write, file, text)
    local flushed, flushStatus = false, nil
    if wrote and written then flushed, flushStatus = pcall(file.flush, file) end
    local closed, closeStatus = pcall(file.close, file)
    return flushed and flushStatus and closed and closeStatus and read(path) == text
  end
  return {read=read, write=write, remove=os.remove}
end

-- Edits the config file this launch was started with. `loaded` holds what
-- this launch read: the startup config-sparse and config-full load order
-- (the framework changes neither) and the effective Custom Hotkeys config it
-- was enabled with. The file must still match them when the writer opens it.
-- Afterwards only the revision seen then, or the one this writer last
-- installed, may be replaced; anything else was saved by someone else.
-- stage() writes the result next to the config and returns both paths for one
-- atomic replacement, whose outcome is reported back through replaced().
function M.writer(files, parse, path, version, digest, normalize, loaded)
  local text = files.read(path)
  local self = {}
  local ok, same = pcall(function()
    local current = parse(text)
    local full = current['config-full']
    local config = full.modules[OWNER].config
    if config ~= nil and type(config) ~= 'table' then return false end
    local effective = copy(config or {})
    normalize(effective)
    return equal(current['config-sparse'], loaded.sparse) and equal(full['load-order'], loaded.loadOrder)
      and equal(effective, loaded.effective or {})
  end)
  if text and loaded and ok and same then self.revision = digest(text) end
  function self.stage(changes)
    text = files.read(path)
    if not text then return nil, 'config.read' end
    if not self.revision or digest(text) ~= self.revision then return nil, 'config.changed' end
    local result, problem = M.edit(text, parse, changes, version)
    if not result then return nil, problem end
    local staged = path .. '.custom-hotkeys.tmp'
    if not files.write(staged, result) then files.remove(staged); return nil, 'config.write' end
    if files.read(path) ~= text then files.remove(staged); return nil, 'config.changed' end
    self.pending = digest(result)
    return {staged=staged, target=path}
  end
  function self.replaced(success)
    if success and self.pending then self.revision = self.pending end
    self.pending = nil
  end
  return self
end

return M
