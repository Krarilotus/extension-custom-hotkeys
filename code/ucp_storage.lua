-- The installation-local profile slots of Custom Hotkeys 0.2.x, read-only
-- through UCP 3.0.7's public io.open, and the marker that their active profile
-- was imported into a UCP config once.
local M = {}
local prefix = 'ucp/custom-hotkeys-'
local allowed = {['profiles-a.json']=true, ['profiles-b.json']=true}
local marker = prefix .. '0.2-imported'
function M.new(ucpIO)
  assert(type(ucpIO.open) == 'function', 'store.io-unavailable')
  return {open=function(_, name, mode)
    assert(allowed[name] and mode == 'rb', 'store.path')
    local file, _, errno = ucpIO.open(prefix .. name, mode)
    -- The normal-file branch of luaIOCustomOpen uses luaL_fileresult.
    -- Only ENOENT means absent; permissions and other failures are not defaults.
    if not file then return nil, errno == 2 and 'missing' or 'io' end
    return file
  end,
  imported=function()
    local file = ucpIO.open(marker, 'rb')
    if file then file:close() end
    return file ~= nil
  end,
  markImported=function()
    local file = ucpIO.open(marker, 'wb')
    if not file then return nil, 'store.marker' end
    local ok = pcall(file.write, file, 'The Custom Hotkeys 0.2 profile was imported into a UCP config.\n')
    file:close()
    if not ok then return nil, 'store.marker' end
    return true
  end}
end
return M
