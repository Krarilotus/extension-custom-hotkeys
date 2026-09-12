---@class HotkeyBinding
---@field scan integer Set-1 physical position, 1..127
---@field extended boolean E0 prefix
---@field mods integer Ctrl=1, Shift=2, Alt=4
local M = {}
local function integer(n, lo, hi)
  return type(n) == 'number' and n == math.floor(n) and n >= lo and n <= hi
end

-- These gestures belong to Windows even while the binding editor captures.
-- Recovery is reserved by validate(), but remains owned by this extension.
function M.system(value)
  local s,m=value.scan,value.mods
  if not integer(m,0,7) then return false end
  local ctrl,alt=m%2==1,m>=4
  return (alt and (s==15 or s==62 or s==1 or s==57))
    or (ctrl and s==1) or (ctrl and alt and (s==83 or s==15))
end

-- Set-1 scan code plus the E0 bit. Ctrl=1, Shift=2, Alt=4; sides are aliases.
-- E1/Pause and modifier-only bindings are deliberately unsupported.
---@param value unknown
---@return HotkeyBinding? binding
---@return string? error
function M.validate(value)
  if type(value) ~= 'table' then return nil, 'binding.type' end
  for key in pairs(value) do
    if key ~= 'scan' and key ~= 'extended' and key ~= 'mods' then
      return nil, 'binding.field'
    end
  end
  if not integer(value.scan, 1, 127) or type(value.extended) ~= 'boolean'
      or not integer(value.mods, 0, 7) then return nil, 'binding.invalid' end
  local s, e, m = value.scan, value.extended, value.mods
  if s == 29 or s == 56 or s == 42 or s == 54 or s == 91 or s == 92
      or s == 93 or s == 69 or s == 70 or s == 84 then
    return nil, 'binding.unsupported'
  end
  if M.system(value) or M.recovery(value) then
    return nil, 'binding.reserved'
  end
  return {scan = s, extended = e, mods = m}
end

function M.physical(scan, extended)
  return scan + (extended and 128 or 0)
end

function M.key(binding)
  return M.physical(binding.scan, binding.extended) + 256 * binding.mods
end

function M.same(a, b)
  return a ~= nil and b ~= nil and M.key(a) == M.key(b)
end

function M.recovery(event)
  return event.scan == 88 and event.extended == false and event.mods == 3
end

return M
