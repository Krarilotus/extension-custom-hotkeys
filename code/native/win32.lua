local ffi = require('ffi')
local Keyboard = require('code/keyboard')
local Binding = require('code/binding')
local M = {}
M.__index = M

ffi.cdef[[
  int __stdcall GetKeyboardState(unsigned char *);
  void * __stdcall GetForegroundWindow(void);
  void * __stdcall GetFocus(void);
  unsigned long __stdcall GetWindowThreadProcessId(void *, unsigned long *);
  unsigned long __stdcall GetCurrentThreadId(void);
  unsigned long __stdcall GetCurrentProcessId(void);
  void * __stdcall GetKeyboardLayout(unsigned long);
  int __stdcall GetKeyNameTextW(long, wchar_t *, int);
  int __stdcall WideCharToMultiByte(unsigned int, unsigned long, const wchar_t *,
    int, char *, int, const char *, int *);
]]
local user = ffi.load('user32')
local kernel = ffi.load('kernel32')

function M.new(window)
  assert(window ~= nil and window ~= 0, 'window.required')
  local hwnd = ffi.cast('void *', window)
  local pid = ffi.new('unsigned long[1]')
  local thread = user.GetWindowThreadProcessId(hwnd, pid)
  assert(thread ~= 0 and pid[0] == kernel.GetCurrentProcessId()
    and thread == kernel.GetCurrentThreadId(), 'window.wrong-owner')
  return setmetatable({window=hwnd, thread=tonumber(thread), keys=ffi.new('unsigned char[256]'),
    layout=user.GetKeyboardLayout(0), generation=0, composing=false}, M)
end

function M:owns(window)
  return ffi.cast('void *', window) == self.window
end

function M:focused()
  return kernel.GetCurrentThreadId() == self.thread
    and user.GetForegroundWindow() == self.window and user.GetFocus() == self.window
end

-- Call before routing the original message. The caller also cancels gestures
-- when this returns true. Composition remains blocked after focus loss until a
-- native END message; losing focus is not proof that composition has completed.
function M:observe(message)
  local changed = false
  if message == 0x10d or message == 0x10f then self.composing=true; changed=true end
  if message == 0x10e then self.composing=false; changed=true end
  if message == 0x6 or message == 0x7 or message == 0x8 or message == 0x1c
      or message == 0x51 or message == 0x82 then changed=true end
  if message == 0x51 then self.layout=user.GetKeyboardLayout(0) end
  if changed then self.generation=self.generation+1 end
  return changed
end

function M:modifiers()
  -- Focus loss is routine. Keep routing releases/debts without treating a
  -- non-focused keyboard snapshot as a permanent adapter failure.
  if not self:focused() then return {composing=self.composing} end
  assert(user.GetKeyboardState(self.keys) ~= 0, 'keyboard.unavailable')
  return Keyboard.snapshot(self.keys, self.composing)
end

-- UTF-8 labels for the active Windows layout. The native view must convert
-- this result to the game's verified encoding; it must not treat UTF-8 as ANSI.
function M:keyName(binding)
  assert(Binding.validate(binding), 'binding.invalid')
  assert(kernel.GetCurrentThreadId() == self.thread, 'window.wrong-thread')
  local wide = ffi.new('wchar_t[128]')
  local count = user.GetKeyNameTextW(binding.scan*65536
    +(binding.extended and 16777216 or 0), wide, 128)
  if count <= 0 then return nil, 'keyboard.name-unavailable' end
  local utf8 = ffi.new('char[512]')
  local bytes = kernel.WideCharToMultiByte(65001, 0, wide, count, utf8, 512, nil, nil)
  if bytes <= 0 then return nil, 'keyboard.encoding' end
  return ffi.string(utf8, bytes)
end

return M
