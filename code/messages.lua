local M = {}
local kinds = {[0x100]='down',[0x101]='up',[0x102]='char',
  [0x104]='down',[0x105]='up',[0x106]='char',[0x103]='char',[0x107]='char'}
local barriers = {[0x6]=true,[0x7]=true,[0x8]=true,[0x1c]=true,[0x51]=true,
  [0x10d]=true,[0x10e]=true,[0x10f]=true,[0x82]=true}

-- Pure message adapter. The native owner provides the real HWND and key state.
-- Non-owned windows and unconsumed messages retain all original arguments and
-- CallNextProc's return value. No GetMainProc or SendInput recursion.
function M.new(router, nextProc, modifierState, ownsWindow)
  local failed = false
  local debts = {}
  local function stop()
    failed = true
    pcall(router.barrier,router)
  end
  return function(priority, hwnd, message, wparam, lparam)
    local kind = kinds[message]
    local raw = lparam % 4294967296
    local physical = math.floor(raw/65536)%256 + 256*(math.floor(raw/16777216)%2)
    local debt = debts[hwnd]
    -- Once dispatch has stopped, drain only gestures we already consumed.
    -- Retain character debt after key-up because TranslateMessage may have
    -- queued WM_CHAR behind it. A fresh down starts native ownership again.
    if failed then
      if debt and kind then
        if kind == 'down' and math.floor(raw/1073741824)%2 == 0 then
          debt[physical] = nil
        elseif debt[physical] then return 0 end
      end
      return nextProc(priority,hwnd,message,wparam,lparam)
    end
    local ownOk, owned = pcall(ownsWindow,hwnd)
    if not ownOk then
      stop()
      if debt and kind and debt[physical] then
        if kind == 'down' and math.floor(raw/1073741824)%2 == 0 then
          debt[physical] = nil
        else return 0 end
      end
    end
    if not ownOk or not owned then return nextProc(priority,hwnd,message,wparam,lparam) end
    if barriers[message] then
      local ok = pcall(router.barrier,router)
      if not ok then stop() end
    elseif kind then
      debts[hwnd] = debt or {}
      debt = debts[hwnd]
      if kind == 'down' and math.floor(raw/1073741824)%2 == 0 then debt[physical] = nil end
      local entered = false
      local ok, consumed = pcall(function()
        local modifiers = modifierState()
        local event = {kind=kind,scan=math.floor(raw/65536)%256,
          extended=math.floor(raw/16777216)%2==1,repeated=math.floor(raw/1073741824)%2==1,
          mods=modifiers.mods,altgr=modifiers.altgr,win=modifiers.win,
          composing=modifiers.composing}
        entered = true
        return router:handle(event)
      end)
      if not ok then
        stop()
        -- If routing began, a native action may already have happened.
        -- Never retry that activation via the original message handler.
        if entered or debt[physical] then debt[physical] = true; return 0 end
      end
      if ok and consumed then debt[physical] = true; return 0 end
    end
    return nextProc(priority,hwnd,message,wparam,lparam)
  end
end

return M
