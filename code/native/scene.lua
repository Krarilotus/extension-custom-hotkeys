local ffi=require('ffi')
local M={}
M.__index=M
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
-- Only proven non-authoring menu parents are enabled at this integration stage.
-- World, lobby, save/name and other modal owners require their own completed
-- positive native eligibility records before entering this table.
local menus={[41]='main',[44]='custom-scenarios',[42]='campaigns',[38]='missions'}
function M.new(platform)
  return setmetatable({platform=platform,generation=0},M)
end
function M:snapshot()
  return {screen=read(0x1fe7d1c),tab=read(0x1fe7d20),subtab=read(0x1fe7d24),
    delay=read(0x1fe7d14),newPlayer=read(0x1fe7e64),mode=read(0x1fe7d78),
    modal=read(0x1fe7cbc),modal2=read(0x24036a4),modal3=read(0x1667f24),
    textModal=read(0x1126604),textEditor=read(0x2403b00),
    width=read(0xf98350),height=read(0xf98354),sliding=read(0xf2b3a8),
    focused=self.platform:focused(),platformGeneration=self.platform.generation}
end
function M:resolve(editor)
  local s=self:snapshot()
  local signature=table.concat({s.screen,s.tab,s.subtab,s.delay,s.newPlayer,s.mode,
    s.modal,s.modal2,s.modal3,s.textModal,s.textEditor,s.platformGeneration},':')
  if signature~=self.signature then self.signature=signature;self.generation=self.generation+1 end
  self.current=s
  if not s.focused or self.platform.composing or s.delay~=-1 or s.newPlayer~=0
      or s.textModal~=0 or s.textEditor~=0 or s.modal2~=-1 or s.modal3~=-1
      or not menus[s.screen] then return nil end
  local owner,focus='menu.'..menus[s.screen],''
  if editor and editor.opened and s.modal==editor.modalID then
    owner=editor.controller.capturing and 'hotkeys.capture' or 'hotkeys.editor'
    focus=tostring(editor.focus)
    if editor.text then return nil end
  elseif s.modal~=-1 then return nil end
  return {verified=true,focused=true,text=false,composing=false,transition=false,
    owner=owner,screen=tostring(s.screen),panel=tostring(s.tab)..':'..s.subtab,
    modal=s.modal==-1 and '' or tostring(s.modal),focus=focus,selection='',targeting='',
    state='menu',authority=false,generation=self.generation}
end
return M
