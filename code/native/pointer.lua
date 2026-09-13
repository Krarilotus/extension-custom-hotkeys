local ffi=require('ffi')
local A=require('code/addresses')
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
  local position=cx+65536*cy
  -- A repeated move to an already observed position needs no new message.
  -- Otherwise normal queued WM_MOUSEMOVE must acknowledge this move before
  -- native click input is allowed to use its coordinates.
  if self.last~=position or self.expected~=nil then self.expected=position end
  if user.SetCursorPos(self.point[0].x,self.point[0].y)==0
      or user.GetCursorPos(self.actual)==0 or self.actual[0].x~=self.point[0].x
      or self.actual[0].y~=self.point[0].y then self.expected=nil;return false end
  return true,gx,gy
end
function M:settled() return self.expected==nil end
function M:insideWorld(position)
  local s=self.scene:snapshot()
  if not self.platform:focused() or user.GetClientRect(self.platform.window,self.rect)==0 then return false end
  local p=ffi.cast('int32_t *',A.viewportRectangle)
  local x,y,w,h=tonumber(p[0]),tonumber(p[1]),tonumber(p[2]),tonumber(p[3])
  if x<0 or y<0 or w<1 or h<1 or x+w>s.width or y+h>s.height then return false end
  local function contains(left,top,width,height)
    if width<1 or height<1 then return false end
    if position==nil then
      local mouse=ffi.cast('int16_t *',A.mouseState+0x1f4)
      return mouse[0]>=left and mouse[1]>=top and mouse[0]<left+width and mouse[1]<top+height
    end
    local rect=self.rect[0]
    local ax,ay=Viewport.point(left,top,s.width,s.height,tonumber(rect.right),tonumber(rect.bottom))
    local bx,by=Viewport.point(left+width-1,top+height-1,s.width,s.height,tonumber(rect.right),tonumber(rect.bottom))
    if not ax or not bx then return false end
    local px,py=position%65536,math.floor(position/65536)%65536
    return px>=ax and py>=ay and px<=bx and py<=by
  end
  if not contains(x,y,w,h) then return false end
  -- Nonblocking HUDs still own their own pointer rectangle.
  if s.modal3==130 then
    local b=remote.interface.modalBounds(s.modal3)
    if not b or contains(b.x,b.y,b.width,b.height) then return false end
  end
  return true
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
