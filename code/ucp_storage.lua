-- The installation-local profile slots of Custom Hotkeys 0.2.x, read-only
-- through UCP 3.0.7's public io.open.
local M = {}
local prefix = 'ucp/custom-hotkeys-'
local allowed = {['profiles-a.json']=true, ['profiles-b.json']=true}
function M.new(ucpIO)
  assert(type(ucpIO.open) == 'function', 'store.io-unavailable')
  return {open=function(_, name, mode)
    assert(allowed[name] and mode == 'rb', 'store.path')
    local file, _, errno = ucpIO.open(prefix .. name, mode)
    -- The normal-file branch of luaIOCustomOpen uses luaL_fileresult.
    -- Only ENOENT means absent; permissions and other failures are not defaults.
    if not file then return nil, errno == 2 and 'missing' or 'io' end
    return file
  end}
end
return M
