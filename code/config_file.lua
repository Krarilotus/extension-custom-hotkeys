-- Writes explicit Custom Hotkeys entries into the active UCP config file. The
-- launcher owns that file and UCP 3.0.7 has no config writer, so only the
-- custom-hotkeys block of config-sparse (launcher user values) and config-full
-- (what the framework loads) is replaced. Every other line stays byte-identical,
-- and the framework's YAML parser must read back exactly the intended document
-- before the file is replaced.
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
-- its line, the last line of its block and its inline remainder, or nil and
-- the indentation of the existing children.
local function find(lines, first, last, parent, key)
  local depth
  for i = first, last do
    local line = lines[i]
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
            if not skip(lines[j]) then
              if indent(lines[j]) <= n then break end
              stop = j
            end
          end
          return {line=i, stop=stop, indent=n, rest=remainder}
        end
      end
    end
  end
  return nil, depth or parent + 2
end

local function empty(block) return block.stop == block.line and (block.rest == '' or block.rest == '{}') end

local function splice(lines, section, module)
  local top = find(lines, 1, #lines, -1, section)
  if not top or top.rest ~= '' then return nil, 'config.layout' end
  local modules = find(lines, top.line + 1, top.stop, top.indent, 'modules')
  if not modules then return nil, 'config.layout' end
  local block, first, stop = {}, nil, nil
  if empty(modules) then
    lines[modules.line] = string.rep(' ', modules.indent) .. 'modules:'
    emit(block, OWNER, module, modules.indent + 2)
    first, stop = modules.line + 1, modules.line
  elseif modules.rest ~= '' then return nil, 'config.layout'
  else
    local owner, depth = find(lines, modules.line + 1, modules.stop, modules.indent, OWNER)
    emit(block, OWNER, module, owner and owner.indent or depth)
    if owner then first, stop = owner.line, owner.stop
    else first, stop = modules.stop + 1, modules.stop end
  end
  for _ = first, stop do table.remove(lines, first) end
  for i, line in ipairs(block) do table.insert(lines, first + i - 1, line) end
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

-- changes: {path={...below custom-hotkeys.config}, value=<explicit or nil>, inherited=<suggestion>}
function M.edit(text, parse, changes)
  local ok, document = pcall(parse, text)
  if not ok or type(document) ~= 'table' then return nil, 'config.parse' end
  local newline = text:find('\r\n', 1, true) and '\r\n' or '\n'
  local lines = {}
  for line in (text:gsub('\r\n', '\n') .. '\n'):gmatch('(.-)\n') do lines[#lines + 1] = line end
  if lines[#lines] == '' then lines[#lines] = nil end
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
    local emitted, problem = pcall(splice, lines, section[1], module)
    if not emitted or not problem then return nil, emitted and 'config.layout' or 'config.value' end
  end
  local result = table.concat(lines, newline) .. newline
  local parsed, reread = pcall(parse, result)
  if not parsed or not equal(reread, expected) then return nil, 'config.verify' end
  return result
end

-- File access through the framework's io.open, replacing the file only after
-- its successor was written and read back completely.
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
  return {read=read, replace=function(path, text)
    local staged, previous = path .. '.custom-hotkeys.tmp', path .. '.custom-hotkeys.old'
    if not write(staged, text) then os.remove(staged); return nil, 'config.write' end
    os.remove(previous)
    if not os.rename(path, previous) then os.remove(staged); return nil, 'config.write' end
    if not os.rename(staged, path) then os.rename(previous, path); return nil, 'config.write' end
    os.remove(previous)
    return true
  end}
end

function M.save(files, parse, path, changes)
  local text = files.read(path)
  if not text then return nil, 'config.read' end
  local result, problem = M.edit(text, parse, changes)
  if not result then return nil, problem end
  return files.replace(path, result)
end

return M
