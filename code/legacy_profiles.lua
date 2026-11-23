-- Reads the installation-local profile slots written by Custom Hotkeys 0.2.x
-- (schemas 1-3) once, so their active profile can move into the UCP config.
local Catalog = require('code/catalog')
local Binding = require('code/binding')
local M = {}
local LIMIT = 1024 * 1024

local function read(boundary, codec, sha256, slot)
  local file, err = boundary:open('profiles-' .. slot .. '.json', 'rb')
  if not file then return nil, err == 'missing' and 'missing' or 'io' end
  local ok, bytes, readError = pcall(file.read, file, LIMIT + 1)
  local closed, status = pcall(file.close, file)
  if not ok or readError or not closed or not status then return nil, 'io' end
  if type(bytes) ~= 'string' or #bytes > LIMIT then return nil, 'invalid' end
  local decoded, envelope = pcall(codec.decode, bytes)
  if not decoded or type(envelope) ~= 'table' or envelope.schema ~= 1
      or type(envelope.generation) ~= 'number' or envelope.generation < 1
      or envelope.generation > 9007199254740990
      or envelope.generation ~= math.floor(envelope.generation)
      or type(envelope.payload) ~= 'string' or type(envelope.sha256) ~= 'string' then
    return nil, 'invalid'
  end
  local digest = sha256(string.format('%.0f', envelope.generation) .. '\n' .. envelope.payload)
  if envelope.sha256 ~= digest then return nil, 'invalid' end
  local valid, document = pcall(codec.decode, envelope.payload)
  if not valid or type(document) ~= 'table' then return nil, 'invalid' end
  return {document=document, generation=envelope.generation, digest=digest}
end

-- The newer of the two alternating slots; an unreadable one is never assumed older.
function M.load(boundary, codec, sha256)
  local a, ae = read(boundary, codec, sha256, 'a')
  local b, be = read(boundary, codec, sha256, 'b')
  if ae == 'io' or be == 'io' then return nil, 'store.read' end
  if not a and not b then
    return nil, (ae == 'missing' and be == 'missing') and 'store.missing' or 'store.corrupt'
  end
  if a and b and a.generation == b.generation and a.digest ~= b.digest then
    return nil, 'store.ambiguous'
  end
  return ((a and (not b or a.generation >= b.generation)) and a or b).document
end

-- An old snapshot cannot tell inherited chords from chosen ones, so every
-- provider entry and every built-in chord that differs from the layout
-- becomes explicit. Reset returns any of them to inheritance.
function M.explicit(catalog, document)
  local schema = document.schema
  if schema ~= 1 and schema ~= 2 and schema ~= 3 then return nil, 'profiles.format' end
  local profile = type(document.profiles) == 'table' and document.profiles[document.active]
  if type(profile) ~= 'table' or type(profile.bindings) ~= 'table' then return nil, 'profiles.active' end
  local presets = catalog.presets or {}
  local layout = presets[profile.preset] and profile.preset or 'game-default'
  local base = presets[layout] and presets[layout].bindings or Catalog.defaults(catalog)
  local explicit = {}
  local function take(id, value)
    if value ~= false then value = Binding.validate(value) end
    if value == nil then return end
    if Catalog.extensionId(id) then explicit[id] = value
    elseif catalog.actions[id] and not Binding.equal(value, base[id])
        -- Before schema 3 an unbound group recall still passed the game's own key.
        and not (schema < 3 and value == false and id:match('^unit%.group%.recall%.%d$')) then
      explicit[id] = value
    end
  end
  for id, value in pairs(profile.bindings) do take(id, value) end
  -- 0.2 parked a provider chord here while its action was missing or unbound.
  if type(profile.unavailable) == 'table' then
    for id, value in pairs(profile.unavailable) do
      if not profile.bindings[id] then take(id, value) end
    end
  end
  return {layout=layout, explicit=explicit}
end

return M
