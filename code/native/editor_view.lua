local A=require('code/addresses')
local ffi=require('ffi')
local Controller=require('code/editor')
local Text=require('code/text_edit')
local Encoding=require('code/native/encoding')
local Binding=require('code/binding')
local Layout=require('code/text_layout')
local NativeText=require('code/native/text')
local Geometry=require('code/editor_layout')
local Scrollbar=require('code/editor_scrollbar')
local M={}
M.__index=M
local rows=Geometry.rows
function M.new(profiles,catalog,router,scene,platform,labels)
  local self=setmetatable({profiles=profiles,catalog=catalog,router=router,scene=scene,
    platform=platform,labels=labels,opened=false,focus=1,pins={},textCache={},keyNames={},
    codepage=NativeText.codepage()},M)
  local manager=remote.interface.manager
  self.menuID=manager.getAvailableMenuID(2040)
  self.modalID=manager.getAvailableModalMenuID(2041)
  local function pin(value) self.pins[#self.pins+1]=value;return value end
  self.resetMouse=ffi.cast('void (__thiscall *)(void *)',A.resetMouse)
  self.displayVisible=ffi.cast('int (__cdecl *)(int)',A.displayElementVisible)
  self.setDisplay=ffi.cast('void (__cdecl *)(int,int)',A.setDisplayElement)
  self.controls={}
  local action=pin(ffi.cast('void (__cdecl *)(int)',function(id)
    local ok,err=pcall(self.activate,self,id)
    if not ok then self.error='editor.failure';log(ERROR,tostring(err));self.router:barrier() end
  end))
  local render=pin(ffi.cast('void (__cdecl *)(int)',function(id)
    local ok,err=pcall(self.renderButton,self,id)
    if not ok then log(ERROR,tostring(err)) end
  end))
  self.tables={};self.pages={}
  local scroll=pin(ffi.cast('void (__cdecl *)(int,int,int *,int *,int *)',function(_,operation,minimum,maximum,current)
    local ok,err=pcall(function()
      local enabled=self.opened and self.page=='bindings' and not self.text
      if operation==2 or operation==3 or operation==5 or operation==6 then
        enabled=enabled and self:owns() and not self.platform.composing
      end
      local low,high,value=Scrollbar.update(self.controller,operation,tonumber(current[0]),
        enabled)
      minimum[0],maximum[0],current[0]=low,high,value
      if enabled and self.controls[self.focus].id<=rows then
        self.focus=4+self.controller.selected-self.controller.first
      end
    end)
    if not ok then minimum[0],maximum[0],current[0]=0,0,0;log(ERROR,tostring(err)) end
  end))
  for _,page in ipairs({'bindings','profiles'}) do
    local controls=Geometry.controls(page);self.pages[page]=controls
    local items={{menuItemType=0x01000000,menuItemActionHandler={simple=action},
      menuItemRenderFunction={simple=render}}}
    for _,c in ipairs(controls) do
      items[#items+1]={menuItemType=0x02000003,menuItemRenderFunctionType=1,
        position={position={x=c.x,y=c.y}},itemWidth=c.width,itemHeight=c.height,
        callbackParameter={parameter=c.id}}
    end
    if page=='bindings' then
      -- Original type6 input owns wheel, track paging and thumb dragging.
      -- Load's renderer492C60 only consumes ButtonState and supplied thumb data.
      items[#items+1]={menuItemType=6,position={position={x=722,y=Geometry.listY}},
        itemWidth=18,itemHeight=rows*Geometry.rowHeight,
        menuItemActionHandler={scrollbar=scroll},callbackParameter={parameter=0},
        menuItemRenderFunction={scrollbar=ffi.cast('void (__cdecl *)(int,int,int,int,bool)',A.renderScrollbar)},
        firstItemTypeData={itemsToSkip=20},menuItemRenderFunctionType=4}
    end
    items[#items+1]={menuItemType=0x66}
    self.tables[page]=pin(ffi.new('MenuItem[?]',#items,items))
  end
  self.page='bindings';self.controls=self.pages.bindings
  self.menu=api.ui.Menu:createMenu({menuID=self.menuID,menuItems=self.tables.bindings})
  self.modal=api.ui.ModalMenu:createModalMenu({modalMenuID=self.modalID,width=Geometry.width,height=Geometry.height,
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
    and require('code/modal_context').background(s) and s.textModal==0 and s.textEditor==0
    and s.delay==-1 and s.newPlayer==0 and s.screen==self.parentScreen
end
function M:open()
  local c=self.scene:resolve(self)
  if self.opened or not c or (c.owner:sub(1,5)~='menu.' and c.owner~='game.build'
      and c.owner~='game.status') then return false end
  self.controller=Controller.new(self.profiles,self.catalog,self.router,self.labels,string.lower,rows)
  self:setPage('bindings')
  self.focus,self.text,self.error,self.opened=4,nil,nil,true
  self.parentScreen=self.scene.current.screen
  game.UI.activateModalMenu(game.UI.MenuModalComposition1,self.modalID,false)
  -- Native display21 is the world hover banner. Preserve its native enable
  -- state while this editor covers the world, rather than painting over it.
  if (self.parentScreen==14 or self.parentScreen==16) and self.displayVisible(21)~=0 then
    self.hoverGeneration=self.scene.current.inputGeneration
    self.restoreHoverDisplay=true
    self.setDisplay(21,0)
  end
  self.resetMouse(game.Input.mouseState)
  return true
end
function M:close(apply)
  if not self:owns() then return false end
  if self.controller.capturing then self.controller:cancelCapture() end
  if apply and not self.controller:apply() then return false end
  if not apply then self.controller:cancel() end
  self:restoreHover(self.scene:snapshot())
  self.router:barrier();self.opened=false;self.text=nil
  game.UI.activateModalMenu(game.UI.MenuModalComposition1,-1,false)
  self.resetMouse(game.Input.mouseState)
  return true
end
function M:restoreHover(snapshot)
  local restore=self.restoreHoverDisplay
  self.restoreHoverDisplay=false
  -- A replacement world/view initializes its own displays. Do not overwrite
  -- that state with visibility remembered before a load or Recorder restore.
  if restore and snapshot.screen==self.parentScreen
      and snapshot.inputGeneration==self.hoverGeneration and self.displayVisible(21)==0 then
    self.setDisplay(21,1)
  end
end
function M:setPage(page)
  assert(self.tables[page],'editor.page')
  self.router:barrier()
  self.page=page;self.controls=self.pages[page];self.text=nil;self.focus=1
  local x,y=self.menu.menu.xPosition,self.menu.menu.yPosition
  game.UI.Menu(self.menu.pMenu,self.tables[page])
  self.menu.menu.xPosition,self.menu.menu.yPosition=x,y
  self.menu.menuItems=self.tables[page]
  self.resetMouse(game.Input.mouseState)
end
function M:visible(id)
  if type(id)~='number' then return false end
  if id<=rows and not (self.controller and self.controller.rows[self.controller.first+id-1]) then return false end
  if id==115 and not (self.controller and self.controller.reassignment) then return false end
  for _,control in ipairs(self.controls) do if control.id==id then return true end end
  return false
end
function M:activate(id)
  if not self:owns() or not self:visible(id) then return false end
  if self.controller.capturing then
    if id==114 then self.controller:cancelCapture() end
    return true
  end
  if self.text then self:finishText(self.text.kind=='search') end
  for i,c in ipairs(self.controls) do if c.id==id then self.focus=i;break end end
  self.error,self.notice=nil,nil
  local e=self.controller
  if id<=rows then e:choose(e.first+id-1);e:capture()
  elseif id==118 then self:setPage(self.page=='bindings' and 'profiles' or 'bindings')
  elseif id==101 or id==102 or id==103 then
    local v=e:view();local current=1
    for i,name in ipairs(v.profiles) do if name==v.active then current=i end end
    e:selectProfile(v.profiles[(current+(id==102 and -2 or 0))%#v.profiles+1])
  elseif id==104 or id==105 then
    self.router:barrier();self.text={kind=id==104 and 'profile' or 'search',
      previous=e.query,edit=Text.new(id==105 and e.query or '')};self.text.edit:selectAll()
  elseif id==106 then
    local groups={false}
    for _,group in ipairs(e.groups) do groups[#groups+1]=group end
    local current=1;for i,g in ipairs(groups) do if g==e.group then current=i end end
    e:filter(e.query,groups[current%#groups+1] or nil)
  elseif id==115 then e:reassign()
  elseif id==116 then
    local document,err=remote.interface.loadExchange()
    if not document then self.error=err
    else
      self.router:barrier()
      self.text={kind='import',document=document,edit=Text.new(document.active)}
      self.text.edit:selectAll()
    end
  elseif id==117 then
    local ok,err=remote.interface.saveExchange(e:exportProfile())
    if ok then self.notice='exported' else self.error=err end
  elseif id==109 then e:resetAction()
  elseif id==110 then e:resetProfile()
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
    elseif text.kind=='import' then self.controller:importProfile(text.edit:value(),text.document)
    else self.controller:filter(text.edit:value(),self.controller.group);self.focus=4 end
  elseif text.kind=='search' then self.controller:filter(text.previous,self.controller.group)
  end
end
function M:filterSearch()
  if self.text and self.text.kind=='search' then
    local query=self.text.edit:value()
    if query~=self.controller.query then self.controller:filter(query,self.controller.group) end
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
      if char then local ok,err=self.text.edit:insert(char);if not ok then self.error=err end
        self:filterSearch() end end
    return true
  end
  if event.kind~='down' then return true end
  if event.composing then return false end
  if self.text then
    local edit=self.text.edit
    local shift=event.mods and math.floor(event.mods/2)%2==1
    if event.value==9 and self.text.kind=='search' then
      self:finishText(true);self.focus=shift and 1 or 3
    elseif event.value==13 then self:finishText(true)
    elseif event.value==27 then self:finishText(false)
    elseif event.value==8 then edit:delete(true)
    elseif event.value==46 then edit:delete(false)
    elseif event.value==37 then edit:move(edit.caret-1,shift)
    elseif event.value==39 then edit:move(edit.caret+1,shift)
    elseif event.value==36 then edit:move(0,shift)
    elseif event.value==35 then edit:move(#edit.chars,shift)
    elseif event.value==65 and event.mods==1 then edit:selectAll() end
    self:filterSearch()
    return true
  end
  if event.repeated or event.altgr then return true end
  -- Fixed editor navigation is separate from configurable physical bindings.
  if event.value==9 then
    repeat self.focus=(self.focus+(event.mods==2 and -2 or 0))%#self.controls+1
    until self:visible(self.controls[self.focus].id)
    local id=self.controls[self.focus].id
    if id<=rows then self.controller:choose(self.controller.first+id-1) end
  elseif self.page=='bindings' and (event.value==38 or event.value==40 or event.value==33 or event.value==34
      or event.value==36 or event.value==35) then
    local delta=({[38]=-1,[40]=1,[33]=-rows,[34]=rows,[36]=-#self.controller.rows,[35]=#self.controller.rows})[event.value]
    self.controller:navigate(delta)
    self.focus=3+self.controller.selected-self.controller.first+1
  elseif self.page=='bindings' and event.value==46 and self.controls[self.focus].id<=rows then self.controller:clear()
  elseif event.value==13 then self:activate(self.controls[self.focus].id)
  elseif event.value==27 then self:activate(114) end
  return true
end
function M:bindingName(binding)
  if not binding then return self.labels('unbound') end
  if self.nameLayout~=self.platform.layout then self.nameLayout=self.platform.layout;self.keyNames={} end
  local key=Binding.key(binding)
  if self.keyNames[key] then return self.keyNames[key] end
  local name=binding.button and self.labels('mouse.'..binding.button) or self.platform:keyName(binding) or '?'
  if binding.mods%2==1 then name='Ctrl+'..name end
  if math.floor(binding.mods/2)%2==1 then name='Shift+'..name end
  if binding.mods>=4 then name='Alt+'..name end
  self.keyNames[key]=name
  return name
end
function M:drawEncoded(encoded,x,y,color,font)
  game.Rendering.renderTextToScreenConst(game.Rendering.textManager,encoded,x,y,0,
    color or 0xB8EEFB,font or 0x12,false,0)
end
function M:layout(slot,text,width,font,edit)
  font=font or 0x12
  local cached=self.textCache[slot]
  local caret,anchor=edit and edit.caret,edit and edit.anchor
  if cached and cached.text==text and cached.width==width and cached.font==font
      and cached.caret==caret and cached.anchor==anchor then return cached.result end
  local encoded=Encoding.display(text,self.codepage) or '?'
  local measure=function(value) return NativeText.width(value,font) end
  local result
  if edit then
    -- Only representable single-byte text reaches the native fonts. Character
    -- offsets therefore match encoded offsets; clamp on conversion failure.
    result=Layout.field(encoded,caret,anchor,width,measure)
  else
    local fitted=Layout.fit(encoded,width,measure)
    result={text=fitted,width=measure(fitted)}
  end
  self.textCache[slot]={text=text,width=width,font=font,caret=caret,anchor=anchor,result=result}
  return result
end
function M:draw(text,x,y,color,font,width,slot)
  local result=self:layout(slot or 'title',text,width or 608,font)
  self:drawEncoded(result.text,x,y+2,color,font)
end
function M:renderButton(id)
  -- The registered render callback above owns the protected FFI boundary.
  if not self.opened or not self:visible(id) then return end
  local e=self.controller;local v=e:view();local label,selected,binding='',false,nil
  local section
  if id<=rows then
    local row=v.rows[id]
    if row then
      label=row.label;selected=row.selected
      binding=self:bindingName(row.binding)
      if row.sectionStart then section=self.labels('group.'..row.group) end
    end
  else
    for i,c in ipairs(self.controls) do if c.id==id then
      label=(c.label=='<' or c.label=='>') and c.label or self.labels(c.label)
      selected=i==self.focus;break end end
    if id==101 or (id==118 and self.page=='bindings') then label=self.labels('profile')..': '..v.activeLabel end
    if id==105 then label=e.query end
    if id==106 then label=self.labels('groups')..': '..(e.group and self.labels('group.'..e.group) or self.labels('all')) end
    if self.text and ((id==104 and self.text.kind=='profile') or (id==105 and self.text.kind=='search')
        or (id==116 and self.text.kind=='import')) then
      label=self.text.edit:value();selected=true
    end
  end
  local editing=self.text and ((id==104 and self.text.kind=='profile')
    or (id==105 and self.text.kind=='search') or (id==116 and self.text.kind=='import')) and self.text.edit or nil
  if label=='' and not editing and id~=105 then return end
  local s=game.Rendering.ButtonState
  -- Inherit the native menu renderer's surface. Forcing texture surface0 hides
  -- table/button graphics during gameplay, whose menu renderer owns surface1.
  local isRow=id<=rows
  local skin=require('code/native/editor_skin')
  local color=selected and skin.selectedText or skin.text
  if isRow then
    skin.row(e.first+id-2,selected)
  elseif id==105 then
    skin.field()
  else
    skin.button(selected)
  end
  local font=(isRow or id==105) and Geometry.bodyFont or Geometry.buttonFont
  local labelWidth=s.width-16
  local keyLayout
  if binding then
    keyLayout=self:layout('key-'..id,binding,174,Geometry.bodyFont)
    labelWidth=s.width-350
    skin.border(s.x+s.width-190,s.y+2,s.x+s.width-6,s.y+s.height-2)
  end
  local result=self:layout(id,label,labelWidth,font,editing)
  local textX=s.x+(isRow and 152 or 8)
  if isRow and section then
    if id>1 then skin.border(s.x,s.y,s.x+s.width,s.y) end
    self:draw(section,s.x+8,s.y+3,color,Geometry.bodyFont,132,'section-'..id)
  end
  local textY=s.y+(isRow and 5 or 7)
  if result.selectionEnd then
    skin.border(s.x+8+result.selectionStart,textY,
      s.x+8+result.selectionEnd,s.y+s.height-3)
  end
  if isRow or editing or id==105 then
    self:drawEncoded(result.text,textX,textY,color,font)
  else skin.caption(result.text,color) end
  if keyLayout then
    self:drawEncoded(keyLayout.text,s.x+s.width-14-keyLayout.width,s.y+6,color,Geometry.bodyFont)
  end
  if result.caret then self:drawEncoded('|',s.x+8+result.caret,textY,0xFFFFFF,font) end
end
function M:render(x,y,width,height)
  if not self.opened then return end
  -- The native modal already paints its framed, dimmed background.
  -- Keep that game-owned surface instead of covering it with a custom palette.
  self:draw(self.labels(self.page=='profiles' and 'profiles' or 'title'),x+20,y+18,0xCCFAFF,Geometry.titleFont,450,'title')
  local e=self.controller
  if self.page=='bindings' then
    require('code/native/editor_skin').border(x+18,y+84,x+width-18,y+Geometry.listY+rows*Geometry.rowHeight+2)
    self:draw(self.labels('search')..':',x+20,y+54,nil,Geometry.bodyFont,76,'search-label')
    self:draw(self.labels('groups'),x+28,y+88,0xCCFAFF,Geometry.bodyFont,132,'column-group')
    self:draw(self.labels('action'),x+172,y+88,0xCCFAFF,Geometry.bodyFont,330,'column-action')
    self:draw(self.labels('binding'),x+530,y+88,0xCCFAFF,Geometry.bodyFont,170,'column-binding')
    self:draw(tostring(#e.rows>0 and e.selected or 0)..' / '..tostring(#e.rows),x+20,y+511,nil,Geometry.bodyFont,100,'count')
  end
  local message=(e.capturing and self.labels('press')) or (self.notice and self.labels(self.notice))
  local err=self.error or e.error
  if err then
    message=self.labels(err:find('conflict',1,true) and 'conflict'
      or (err:sub(1,6)=='store.' and 'fileError' or 'invalid'))
    if e.reassignment then message=message..' '..self.labels(e.reassignment.other) end
  end
  if message then self:draw(message,x+20,y+482,0xCCFAFF,Geometry.bodyFont,width-40,'message') end
end
return M
