local M = {}

-- GetKeyboardState belongs to the window's input thread and advances with its
-- message queue. A toggle bit is never evidence that a modifier is held.
function M.snapshot(keys, composing)
  local function down(vk) return keys[vk] >= 128 end
  local ctrl = down(0x11) or down(0xa2) or down(0xa3)
  local shift = down(0x10) or down(0xa0) or down(0xa1)
  local alt = down(0x12) or down(0xa4) or down(0xa5)
  return {mods=(ctrl and 1 or 0)+(shift and 2 or 0)+(alt and 4 or 0),
    -- Windows layouts can synthesize Ctrl for AltGr. Preserve every Right-Alt
    -- chord for native text handling, including the brief prefix before Ctrl.
    altgr=down(0xa5), win=down(0x5b) or down(0x5c), composing=composing}
end

return M
