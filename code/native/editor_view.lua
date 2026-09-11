local ffi=require('ffi')
local Controller=require('code/editor')
local Text=require('code/text_edit')
local Encoding=require('code/native/encoding')
local Binding=require('code/binding')
local M={}
M.__index=M
local rows=7
function M.new(profiles,catalog,router,scene,platform,labels)
  local self=setmetatable({profiles=profiles,catalog=catalog,router=router,scene=scene,
    platform=platform,labels=labels,opened=false,focus=1,pins={},codepage=1252},M)
  local manager=remote.interface.manager
  self.menuID=manager.getAvailableMenuID(2040)
  self.modalID=manager.getAvailableModalMenuID(2041)
  local function pin(value) self.pins[#self.pins+1]=value;return value end
  self.resetMouse=ffi.cast('void (__thiscall *)(void *)',remote.interface.core.AOBScan(
    '33 C0 39 81 D8 01 00 00 89 81 D8 01 00 00 75 ? 89 41 28 89 41 2C 89 41 30'))
  self.controls={}
  local action=pin(ffi.cast('void (__cdecl *)(int)',function(id)
    local ok,err=pcall(self.activate,self,id)
    if not ok then self.error='editor.failure';log(ERROR,tostring(err));self.router:barrier() end
  end))
  local render=pin(ffi.cast('void (__cdecl *)(int)',function(id)
    local ok,err=pcall(self.renderButton,self,id)
    if not ok then log(ERROR,tostring(err)) end
  end))
  local items={{menuItemType=0x01000000,menuItemActionHandler={simple=action},
    menuItemRenderFunction={simple=render}}}
  local function button(id,x,y,width,label)
    self.controls[#self.controls+1]={id=id,label=label}
    items[#items+1]={menuItemType=0x02000003,menuItemRenderFunctionType=1,
      position={position={x=x,y=y}},itemWidth=width,itemHeight=26,
      callbackParameter={parameter=id}}
  end
  button(101,20,48,300,'profile');button(102,328,48,32,'<');button(103,368,48,32,'>')
  button(104,408,48,212,'new');button(105,20,86,430,'search');button(106,458,86,162,'groups')
  for row=1,rows do button(row,20,128+(row-1)*26,600,'') end
  button(107,20,324,140,'capture');button(108,168,324,140,'clear')
  button(109,316,324,148,'reset');button(110,472,324,148,'resetProfile')
  button(111,20,362,36,'<');button(112,64,362,36,'>')
  button(113,328,362,140,'apply');button(114,480,362,140,'cancel')
  items[#items+1]={menuItemType=0x66}
  self.menu=api.ui.Menu:createMenu({menuID=self.menuID,
    menuItems=pin(ffi.new('MenuItem[?]',#items,items))})
  self.modal=api.ui.ModalMenu:createModalMenu({modalMenuID=self.modalID,width=648,height=440,
    x=-1,y=-1,borderStyle=512,backgroundColor=0,menu=self.menu,
    menuModalRenderFunction=function(x,y,width,height)
      local ok,err=pcall(self.render,self,x,y,width,height)
      if not ok then log(ERROR,tostring(err)) end
    end})
  return self
end
function M:owns()
  local s=self.scene:snapshot()
  require('code/editor_ownership').reconcile(self,s)
  return self.opened and self.platform:focused() and s.modal==self.modalID
    and s.modal2==-1 and s.modal3==-1 and s.textModal==0 and s.textEditor==0
    and s.delay==-1 and s.newPlayer==0 and s.screen==self.parentScreen
end
function M:open()
  local c=self.scene:resolve(self)
  if self.opened or not c or (c.owner:sub(1,5)~='menu.' and c.owner~='game.build'
      and c.owner~='game.status') then return false end
  self.controller=Controller.new(self.profiles,self.catalog,self.router,self.labels,string.lower,rows)
  self.focus,self.text,self.error,self.opened=7,nil,nil,true
  self.parentScreen=self.scene.current.screen
  game.UI.activateModalMenu(game.UI.MenuModalComposition1,self.modalID,false)
  self.resetMouse(game.Input.mouseState)
  return true
end
function M:close(apply)
  if not self:owns() then return false end
  if self.controller.capturing then self.controller:cancelCapture() end
  if apply and not self.controller:apply() then return false end
  if not apply then self.controller:cancel() end
  self.router:barrier();self.opened=false;self.text=nil
  game.UI.activateModalMenu(game.UI.MenuModalComposition1,-1,false)
  self.resetMouse(game.Input.mouseState)
  return true
end
function M:activate(id)
  if not self:owns() then return false end
  if self.controller.capturing then
    if id==114 then self.controller:cancelCapture() end
    return true
  end
  if self.text then self:finishText(false) end
  for i,c in ipairs(self.controls) do if c.id==id then self.focus=i;break end end
  self.error=nil
  local e=self.controller
  if id<=rows then e:choose(e.first+id-1)
  elseif id==101 or id==102 or id==103 then
    local v=e:view();local current=1
    for i,name in ipairs(v.profiles) do if name==v.active then current=i end end
    e:selectProfile(v.profiles[(current+(id==102 and -2 or 0))%#v.profiles+1])
  elseif id==104 or id==105 then
    self.router:barrier();self.text={kind=id==104 and 'profile' or 'search',
      edit=Text.new(id==105 and e.query or '')};self.text.edit:selectAll()
  elseif id==106 then
    local groups,seen={false},{}
    for _,a in ipairs(self.catalog.ordered) do local g=a.id:match('^([^.]+)')
      if not seen[g] then seen[g]=true;groups[#groups+1]=g end end
    local current=1;for i,g in ipairs(groups) do if g==e.group then current=i end end
    e:filter(e.query,groups[current%#groups+1] or nil)
  elseif id==107 then e:capture()
  elseif id==108 then e:clear()
  elseif id==109 then e:resetAction()
  elseif id==110 then e:resetProfile()
  elseif id==111 then e:navigate(-rows)
  elseif id==112 then e:navigate(rows)
  elseif id==113 then self:close(true)
  elseif id==114 then self:close(false) end
  return true
end
function M:finishText(accept)
  local text=self.text
  if not text then return end
  self.text=nil;self.router:barrier()
  if accept then
    if text.kind=='profile' then self.controller:createProfile(text.edit:value())
    else self.controller:filter(text.edit:value(),self.controller.group) end
  end
end
function M:input(event)
  if not self:owns() then return false end
  -- Preserve system/window shortcuts. AltGr characters are handled as text,
  -- never as shortcut chords. IME messages themselves keep the native path.
  if event.win or Binding.system(event)
      or (event.value==27 and event.mods and event.mods%2==1)
      or (event.mods and event.mods>=4 and not event.altgr) then return false end
  if event.kind=='char' then
    if self.text then local char=Encoding.character(event.value)
      if char then local ok,err=self.text.edit:insert(char);if not ok then self.error=err end end end
    return true
  end
  if event.kind~='down' then return true end
  if event.composing then return false end
  if self.text then
    local edit=self.text.edit
    local shift=event.mods and math.floor(event.mods/2)%2==1
    if event.value==13 then self:finishText(true)
    elseif event.value==27 then self:finishText(false)
    elseif event.value==8 then edit:delete(true)
    elseif event.value==46 then edit:delete(false)
    elseif event.value==37 then edit:move(edit.caret-1,shift)
    elseif event.value==39 then edit:move(edit.caret+1,shift)
    elseif event.value==36 then edit:move(0,shift)
    elseif event.value==35 then edit:move(#edit.chars,shift)
    elseif event.value==65 and event.mods==1 then edit:selectAll() end
    return true
  end
  if event.repeated or event.altgr then return true end
  -- Fixed editor navigation is separate from configurable physical bindings.
  if event.value==9 then
    self.focus=(self.focus+(event.mods==2 and -2 or 0))%#self.controls+1
  elseif event.value==38 then self.controller:navigate(-1)
  elseif event.value==40 then self.controller:navigate(1)
  elseif event.value==33 then self.controller:navigate(-rows)
  elseif event.value==34 then self.controller:navigate(rows)
  elseif event.value==13 then self:activate(self.controls[self.focus].id)
  elseif event.value==27 then self:activate(114) end
  return true
end
function M:bindingName(binding)
  if not binding then return self.labels('unbound') end
  local name=self.platform:keyName(binding) or '?'
  if binding.mods%2==1 then name='Ctrl+'..name end
  if math.floor(binding.mods/2)%2==1 then name='Shift+'..name end
  if binding.mods>=4 then name='Alt+'..name end
  return name
end
function M:draw(text,x,y,color,font)
  local encoded=Encoding.display(text,self.codepage) or '?'
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager,encoded,x,y,0,
    color or 0xB8EEFB,font or 0x12,false,0)
end
function M:renderButton(id)
  if not self.opened then return end
  local e=self.controller;local v=e:view();local label,selected='',false
  if id<=rows then
    local row=v.rows[id]
    if row then label=row.label..'    '..self:bindingName(row.binding);selected=row.selected end
  else
    for i,c in ipairs(self.controls) do if c.id==id then
      label=(c.label=='<' or c.label=='>') and c.label or self.labels(c.label)
      selected=i==self.focus;break end end
    if id==101 then label=self.labels('profile')..': '..v.active end
    if id==105 then label=self.labels('search')..': '..e.query end
    if id==106 then label=self.labels('groups')..': '..(e.group or self.labels('all')) end
    if self.text and ((id==104 and self.text.kind=='profile') or (id==105 and self.text.kind=='search')) then
      label=self.text.edit:value()..'|';selected=true
    end
  end
  if label=='' then return end
  local s=game.Rendering.ButtonState
  local old=game.Rendering.pDrawBufferChoiceValue[0]
  game.Rendering.pDrawBufferChoiceValue[0]=0
  local ok,err=pcall(function()
    game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore,s.x,s.y,
      s.x+s.width,s.y+s.height,selected and 8 or 0x14)
    self:draw(label,s.x+6,s.y+5,selected and 0xFFFFFF or 0xB8EEFB)
  end)
  game.Rendering.pDrawBufferChoiceValue[0]=old
  if not ok then error(err) end
end
function M:render(x,y,width,height)
  if not self.opened then return end
  game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore,x+6,y+6,x+width-6,y+height-6,0x14)
  self:draw(self.labels('title'),x+20,y+18,0xCCFAFF,0xF)
  local e=self.controller
  local message=self.text and self.labels('editing') or (e.capturing and self.labels('press'))
  local err=self.error or e.error
  if err then message=self.labels(err:find('conflict',1,true) and 'conflict' or 'invalid') end
  if message then self:draw(message,x+20,y+407,0xCCFAFF) end
  self:draw(tostring(e.selected)..' / '..tostring(#e.rows),x+118,y+368)
end
return M
