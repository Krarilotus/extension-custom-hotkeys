-- Two alternating verified files through the existing UCP I/O boundary. The last
-- good file is never truncated when committing its successor. No world/save data.
local M = {}
M.__index = M
local LIMIT = 1024 * 1024

function M.new(ioBoundary, codec, sha256, validate)
  return setmetatable({io=ioBoundary, codec=codec, hash=sha256, validate=validate,
    generation=0, slot=nil, loaded=false}, M)
end

function M:read(slot)
  local file, err = self.io:open('profiles-' .. slot .. '.json', 'rb')
  if not file then return nil, err == 'missing' and 'missing' or 'io' end
  local ok, bytes, readError = pcall(file.read, file, LIMIT + 1)
  local closed, status = pcall(file.close, file)
  if not ok or readError or not closed or not status then return nil, 'io' end
  if bytes == nil then return nil, 'invalid' end
  if type(bytes) ~= 'string' then return nil, 'io' end
  if #bytes > LIMIT then return nil, 'invalid' end
  local decoded, envelope = pcall(self.codec.decode, bytes)
  if not decoded or type(envelope) ~= 'table' or envelope.schema ~= 1
      or type(envelope.generation) ~= 'number' or envelope.generation < 1
      or envelope.generation > 9007199254740990
      or envelope.generation ~= math.floor(envelope.generation)
      or type(envelope.payload) ~= 'string' or type(envelope.sha256) ~= 'string' then
    return nil, 'invalid'
  end
  local digest = self.hash(string.format('%.0f',envelope.generation) .. '\n' .. envelope.payload)
  if envelope.sha256 ~= digest then return nil, 'invalid' end
  local valid, document = pcall(self.codec.decode, envelope.payload)
  if not valid then return nil, 'invalid' end
  local checked, normalized = pcall(self.validate, document)
  if not checked or not normalized then return nil, 'invalid' end
  return {document=normalized, generation=envelope.generation, digest=digest, slot=slot}
end

function M:load()
  local a, ae = self:read('a')
  local b, be = self:read('b')
  -- An unreadable newer file cannot safely be assumed older than the other one.
  if ae == 'io' or be == 'io' then return nil, 'store.read' end
  if not a and not b then
    if ae == 'missing' and be == 'missing' then
      self.generation, self.slot, self.loaded = 0, nil, true
      return nil, 'store.missing'
    end
    return nil, 'store.corrupt'
  end
  if a and b and a.generation == b.generation and a.digest ~= b.digest then
    return nil, 'store.ambiguous'
  end
  local latest = (a and (not b or a.generation >= b.generation)) and a or b
  self.generation, self.slot, self.loaded = latest.generation, latest.slot, true
  return latest.document
end

function M:save(document)
  if not self.loaded then return nil, 'store.not-loaded' end
  local valid = self.validate(document)
  if not valid then return nil, 'store.invalid' end
  if self.generation >= 9007199254740990 then return nil, 'store.generation' end
  local payload = self.codec.encode(valid)
  local generation = self.generation + 1
  local digest = self.hash(string.format('%.0f',generation) .. '\n' .. payload)
  local bytes = self.codec.encode({schema=1, generation=generation, payload=payload, sha256=digest})
  if #bytes > LIMIT then return nil, 'store.size' end
  local slot = self.slot == 'a' and 'b' or 'a'
  local file = self.io:open('profiles-' .. slot .. '.json', 'wb')
  if not file then return nil, 'store.write' end
  local ok, wrote = pcall(file.write, file, bytes)
  local flushed, flushStatus = false, nil
  if ok and wrote then flushed, flushStatus = pcall(file.flush, file) end
  local closed, closeStatus = pcall(file.close, file)
  if not ok or not wrote or not flushed or not flushStatus or not closed or not closeStatus then
    -- An I/O failure has an uncertain commit outcome; prohibit further writes
    -- until reopening the store resolves which complete generation is readable.
    self.loaded = false
    return nil, 'store.write'
  end
  local verified = self:read(slot)
  if not verified or verified.generation ~= generation or verified.digest ~= digest then
    self.loaded = false
    return nil, 'store.verify'
  end
  self.generation, self.slot = generation, slot
  return true
end

return M
