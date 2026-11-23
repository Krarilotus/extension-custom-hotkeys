-- The installation-local profile slots of Custom Hotkeys 0.2.x, read through
-- UCP 3.0.7's public io.open. After migration they are renamed, not deleted,
-- so a player can restore them for an older release.
local M = {}
local prefix = 'ucp/custom-hotkeys-'
local slots = {'profiles-a.json', 'profiles-b.json'}
local allowed = {['profiles-a.json']=true, ['profiles-b.json']=true}
function M.new(ucpIO, ucpOS)
  assert(type(ucpIO.open) == 'function', 'store.io-unavailable')
  return {open=function(_, name, mode)
    assert(allowed[name] and mode == 'rb', 'store.path')
    local file, _, errno = ucpIO.open(prefix .. name, mode)
    -- The normal-file branch of luaIOCustomOpen uses luaL_fileresult.
    -- Only ENOENT means absent; permissions and other failures are not defaults.
    if not file then return nil, errno == 2 and 'missing' or 'io' end
    return file
  end,
  -- Both slots move or neither does, so an older generation never stays alone.
  retire=function()
    local moved = {}
    for _, name in ipairs(slots) do
      local path = prefix .. name
      local file = ucpIO.open(path, 'rb')
      if file then
        file:close()
        ucpOS.remove(path .. '.migrated')
        if not ucpOS.rename(path, path .. '.migrated') then
          for _, done in ipairs(moved) do ucpOS.rename(done .. '.migrated', done) end
          return nil, 'store.retire'
        end
        moved[#moved + 1] = path
      end
    end
    return true
  end}
end
return M
