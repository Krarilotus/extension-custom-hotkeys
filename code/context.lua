local M = {}
local states = {menu=true, ['live-sp']=true, ['live-mp']=true, replay=true}
local identityFields = {'owner','screen','panel','modal','focus','selection',
  'targeting','state','authority','generation'}

---@class HotkeyContext
---@field owner string
---@field screen string
---@field panel string
---@field modal string
---@field focus string
---@field selection string
---@field targeting string
---@field state 'menu'|'live-sp'|'live-mp'|'replay'
---@field authority boolean
---@field generation integer

-- The native adapter must prove every field, including explicit false values.
-- A menu ID alone, an imported symbol name or a cached gameplay flag is insufficient.
function M.resolve(facts)
  if type(facts) ~= 'table' or facts.verified ~= true
      or facts.focused ~= true or facts.text ~= false or facts.composing ~= false
      or facts.transition ~= false or not states[facts.state]
      or type(facts.owner) ~= 'string' or facts.owner == ''
      or type(facts.screen) ~= 'string' or type(facts.panel) ~= 'string'
      or type(facts.modal) ~= 'string' or type(facts.focus) ~= 'string'
      or type(facts.selection) ~= 'string' or type(facts.targeting) ~= 'string'
      or type(facts.authority) ~= 'boolean'
      or type(facts.generation) ~= 'number'
      or facts.generation < 0 or facts.generation ~= math.floor(facts.generation)
      or facts.generation > 9007199254740991 then return nil end
  local c = {}
  for _, key in ipairs(identityFields) do c[key] = facts[key] end
  return c
end

function M.same(a, b)
  if not a or not b then return a == b end
  for _, key in ipairs(identityFields) do
    if a[key] ~= b[key] then return false end
  end
  return true
end

-- panel carries the existing native tab:subtab identity. Restrict only the
-- tab here; active-control traversal still validates visibility and substates.
function M.panel(context)
  return context and context.panel:match('^([^:]+):')
end

function M.allows(action, context)
  if not context or not action.contexts[context.owner] then return false end
  if not action.states[context.state] then return false end
  if action.panels and not action.panels[M.panel(context)] then return false end
  if action.command and (not context.authority
      or (context.state ~= 'live-sp' and context.state ~= 'live-mp')) then return false end
  return true
end

function M.overlap(a, b)
  if a.panels and b.panels then
    local shared=false
    for panel in pairs(a.panels) do if b.panels[panel] then shared=true;break end end
    if not shared then return false end
  end
  for owner in pairs(a.contexts) do
    if b.contexts[owner] then
      for state in pairs(a.states) do
        if b.states[state] then return true end
      end
    end
  end
  return false
end

return M
