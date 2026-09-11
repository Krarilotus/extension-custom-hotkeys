local ffi=require('ffi')
local Viewport=require('code/viewport')
ffi.cdef[[
  typedef struct { long x; long y; } HotkeysPoint;
  typedef struct { long left; long top; long right; long bottom; } HotkeysRect;
  int __stdcall GetClientRect(void *,HotkeysRect *);
  int __stdcall ClientToScreen(void *,HotkeysPoint *);
  int __stdcall GetCursorPos(HotkeysPoint *);
  int __stdcall SetCursorPos(int,int);
]]
local user=ffi.load('user32')
local M={}
M.__index=M
function M.new(platform,scene)
  return setmetatable({platform=platform,scene=scene,rect=ffi.new('HotkeysRect[1]'),
    point=ffi.new('HotkeysPoint[1]'),actual=ffi.new('HotkeysPoint[1]')},M)
end
function M:move(x,y)
  if not self.platform:focused() or user.GetClientRect(self.platform.window,self.rect)==0 then return false end
  local s=self.scene:snapshot();local rect=self.rect[0]
  local cx,cy,gx,gy=Viewport.point(x,y,s.width,s.height,tonumber(rect.right),tonumber(rect.bottom))
  if not cx then return false end
  self.point[0].x,self.point[0].y=cx,cy
  if user.ClientToScreen(self.platform.window,self.point)==0 then return false end
  -- Keep the visible cursor and normal WM_MOUSEMOVE hit-testing path aligned.
  -- The identical resulting message is ours; real movement relinquishes focus.
  self.expected=cx+65536*cy
  if user.SetCursorPos(self.point[0].x,self.point[0].y)==0
      or user.GetCursorPos(self.actual)==0 or self.actual[0].x~=self.point[0].x
      or self.actual[0].y~=self.point[0].y then self.expected=nil;return false end
  return true,gx,gy
end
function M:observe(message,lparam)
  if message==0x200 then
    local position=tonumber(lparam)%4294967296
    local own=position==self.expected or position==self.last
    self.last=position
    if position==self.expected then self.expected=nil end
    return not own
  end
  -- A button, wheel or other real pointer gesture takes over immediately.
  self.expected=nil
  return true
end
return M
