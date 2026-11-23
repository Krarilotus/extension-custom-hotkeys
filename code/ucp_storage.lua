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
  -- Nothing moves while a slot is unreadable. The newer slot moves last and
  -- the move rolls back on failure, so an older generation never stays as
  -- the only readable slot.
  retire=function(latest)
    local present = {}
    for _, name in ipairs(latest == 'a' and {slots[2], slots[1]} or slots) do
      local path = prefix .. name
      local file, _, errno = ucpIO.open(path, 'rb')
      if file then file:close(); present[#present + 1] = path
      elseif errno ~= 2 then return nil, 'store.retire' end
    end
    for i, path in ipairs(present) do
      ucpOS.remove(path .. '.migrated')
      if not ucpOS.rename(path, path .. '.migrated') then
        for j = i - 1, 1, -1 do
          if not ucpOS.rename(present[j] .. '.migrated', present[j]) then return nil, 'store.retire-rollback' end
        end
        return nil, 'store.retire'
      end
    end
    return true
  end}
end
return M
