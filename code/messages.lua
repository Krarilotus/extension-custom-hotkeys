local M = {}
local Mouse=require('code/mouse_messages')
local Binding=require('code/binding')
local kinds = {[0x100]='down',[0x101]='up',[0x102]='char',
  [0x104]='down',[0x105]='up',[0x106]='char',[0x103]='char',[0x107]='char'}
local barriers = {[0x6]=true,[0x7]=true,[0x8]=true,[0x1c]=true,[0x51]=true,
  [0x10d]=true,[0x10e]=true,[0x10f]=true,[0x82]=true}

-- Pure message adapter. The native owner provides the real HWND and key state.
-- Non-owned windows and unconsumed messages retain all original arguments and
-- CallNextProc's return value. No GetMainProc or SendInput recursion.
function M.new(router, nextProc, modifierState, ownsWindow, exclusiveInput)
  local failed = false
  local debts = {}
  local function stop()
    failed = true
    pcall(router.barrier,router)
  end
  local function pointerFlags(wparam,debt)
    for name,code in pairs(Binding.buttons) do
      local target=debt[code]
      if type(target)=='string' then
        local held=router.held and router.held[code]
        wparam=Mouse.flags(wparam,name,target,not failed and held~=nil
          and not held.blocked and held.forwarded~=nil)
      end
    end
    return wparam
  end
  return function(priority, hwnd, message, wparam, lparam)
    local button,mouseKind,double=Mouse.decode(message,wparam)
    local kind = mouseKind or kinds[message]
    local raw = lparam % 4294967296
    local physical = button and Binding.buttons[button]
      or math.floor(raw/65536)%256 + 256*(math.floor(raw/16777216)%2)
    local repeated=not button and math.floor(raw/1073741824)%2~=0
    local debt = debts[hwnd]
    -- Once dispatch has stopped, drain only gestures we already consumed.
    -- Retain character debt after key-up because TranslateMessage may have
    -- queued WM_CHAR behind it. A fresh down starts native ownership again.
    if failed then
      if message==0x200 and debt then wparam=pointerFlags(wparam,debt) end
      if debt and kind then
        if kind == 'down' and not repeated then
          debt[physical] = nil
        elseif debt[physical] then return 0 end
      end
      return nextProc(priority,hwnd,message,wparam,lparam)
    end
    local ownOk, owned = pcall(ownsWindow,hwnd)
    if not ownOk then
      stop()
      if debt and kind and debt[physical] then
        if kind == 'down' and not repeated then
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
      if kind == 'down' and not repeated then debt[physical] = nil end
      local entered = false
      local ok, consumed,forwarded = pcall(function()
        local modifiers = modifierState()
        local event = {kind=kind,scan=button and 0 or math.floor(raw/65536)%256,button=button,
          extended=not button and math.floor(raw/16777216)%2==1,repeated=repeated,
          mods=modifiers.mods,altgr=modifiers.altgr,win=modifiers.win,
          composing=modifiers.composing,value=wparam,position=button and lparam or nil}
        entered = true
        local routed,target=router:handle(event)
        if routed then return true,target end
        -- Editor mouse controls retain their native UI handler. Mouse capture
        -- is already exclusive in the router, before this keyboard-only path.
        if not button and exclusiveInput and exclusiveInput(event)==true then return true end
        -- An exclusive editor may close before its release/character arrives.
        -- Keep that gesture suppressed until the next fresh down.
        return debt[physical]~=nil
      end)
      if not ok then
        stop()
        -- If routing began, a native action may already have happened.
        -- Never retry that activation via the original message handler.
        if entered or debt[physical] then debt[physical] = true; return 0 end
      end
      if ok and consumed then
        debt[physical]=kind=='down' and forwarded or true
        if forwarded then
          local translated,flags=Mouse.forward(message,wparam,button,forwarded,kind,double)
          return nextProc(priority,hwnd,translated,flags,lparam)
        end
        return 0
      end
    end
    if message==0x200 and debt then
      wparam=pointerFlags(wparam,debt)
    end
    return nextProc(priority,hwnd,message,wparam,lparam)
  end
end

return M
