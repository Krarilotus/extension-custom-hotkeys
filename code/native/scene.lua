local A=require('code/addresses')
local ffi=require('ffi')
local Dialog=require('code/dialog_context')
local Load=require('code/load_context')
local Modal=require('code/modal_context')
local M={}
M.__index=M
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
-- Only proven non-authoring menu parents are enabled at this integration stage.
-- World, lobby, save/name and other modal owners require their own completed
-- positive native eligibility records before entering this table.
local menus={}
for _,screen in ipairs(require('code/menu_screens')) do menus[screen[1]]=screen[2] end
function M.new(platform,recorderInputGeneration)
  assert(type(recorderInputGeneration)=='function','recorder.input-reader')
  return setmetatable({platform=platform,generation=0,recorderInputGeneration=recorderInputGeneration},M)
end
function M:snapshot()
  local s={screen=read(A.screen),tab=read(A.tab),subtab=read(A.subtab),
    delay=read(A.screenDelay),newPlayer=read(A.newPlayer),mode=read(A.gameMode),
    modal=read(A.primaryModal),modal2=read(A.secondaryModal),modal3=read(A.tertiaryModal),
    activeModalID=read(A.activeModalID),activeModalMenu=read(A.activeModalMenu),
    modalX=read(A.modalX),modalY=read(A.modalY),
    modalWidth=read(A.modalWidth),modalHeight=read(A.modalHeight),modalBorder=read(A.modalBorder),
    modalAnimation=read(A.modalAnimation),modalClosing=read(A.modalClosing),
    textModal=read(A.textModal),textEditor=read(A.textEditor),
    width=read(A.screenWidth),height=read(A.screenHeight),sliding=read(A.toolbarSliding),
    focused=self.platform:focused(),composing=self.platform.composing,
    platformGeneration=self.platform.generation,
    inputGeneration=self.recorderInputGeneration()}
  -- Send/Request can clear the primary modal while leaving the text manager's
  -- last ally dialog ID behind. Preserve every actual text or modal owner.
  if (s.screen==14 or s.screen==16) and s.mode~=1 and s.modal==-1
      and s.textEditor==0 and s.textModal>=121 and s.textModal<=124
      and Modal.background(s) then s.textModal=0 end
  if s.modal==9 and s.activeModalMenu==A.loadMenu then
    s.loadArray=read(A.loadMenu);s.textIndex=read(A.textEntries);s.textState=read(A.textDialog)
    if s.loadArray~=0 and s.loadArray~=A.loadItems then
      s.loadPrefix=require('code/native/menu_reader').matchesPrefix(A.loadMenu,A.loadItems,6,true)
    end
    s.loadCount=read(A.loadCount);s.loadOffset=read(A.loadOffset)
    s.loadSelected=read(A.loadSelected);s.loadRows=read(A.loadRows)
    if s.loadCount>=0 and s.loadCount<=500 then
      s.loadIdentity=ffi.string(ffi.cast('const char *',A.loadIndices),s.loadCount*4)
    end
  end
  return s
end
function M:resolve(editor)
  local s=self:snapshot()
  if editor then require('code/editor_ownership').reconcile(editor,s) end
  local signature=table.concat({s.screen,s.tab,s.subtab,s.delay,s.newPlayer,s.mode,
    s.modal,Modal.secondary(s),s.modal3,s.activeModalID,s.activeModalMenu,s.textModal,s.textEditor,s.platformGeneration,
    s.inputGeneration},':')
  if signature~=self.signature then self.signature=signature;self.generation=self.generation+1 end
  self.current=s
  local options,load=Dialog.owns(s),Load.owns(s)
  if not s.focused or self.platform.composing or s.delay~=-1 or s.newPlayer~=0
      or (s.textModal~=0 and not options and not load) or s.textEditor~=0 or not Modal.background(s) then return nil end
  local ownedModal=editor and editor.opened and editor.parentScreen==s.screen and editor.modalID or nil
  if not ownedModal and options then ownedModal=s.modal end
  if not ownedModal and load then ownedModal=9 end
  -- Only the two map viewports in GameMode2::GM_EDITOR own camera keys.
  local mapEditor=s.mode==1 and (s.screen==12 or s.screen==14) and s.modal==-1 and s.sliding==0
  local world=s.mode~=1 and require('code/native/gameplay').resolve(s,ownedModal) or nil
  if not world and not menus[s.screen] and not mapEditor then return nil end
  local owner,focus=world and world.owner or mapEditor and 'editor.map' or 'menu.'..menus[s.screen],''
  if not world and options then owner='menu.options' end
  if not world and load then owner='menu.load' end
  if editor and editor.opened and s.modal==editor.modalID then
    owner=editor.controller.capturing and 'hotkeys.capture' or 'hotkeys.editor'
    focus=tostring(editor.focus)
    if editor.text then return nil end
  elseif s.modal~=-1 and not options and not load then return nil end
  return {verified=true,focused=true,text=false,composing=false,transition=false,
    owner=owner,screen=tostring(s.screen),panel=tostring(s.tab)..':'..s.subtab,
    modal=s.modal==-1 and '' or tostring(s.modal),focus=focus,
    selection=world and world.selection or '',targeting=world and world.targeting or '',
    state=world and world.state or (mapEditor and 'editor') or 'menu',authority=world and world.authority or false,
    generation=self.generation}
end
return M
