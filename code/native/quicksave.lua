local ffi=require('ffi')
local Context=require('code/context')
local Gameplay=require('code/gameplay')
local NativeGameplay=require('code/native/gameplay')
local Origin=require('code/modal_origin')
local M={}
local NAME='Custom Hotkeys Quick'
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local text=ffi.cast('void *',0x1652740)
local setName=ffi.cast('void (__thiscall *)(void *,int,const char *)',0x469800)
local enter=ffi.cast('void (__thiscall *)(void *)',0x469870)
local function name()
  -- Native entry2 has250 bytes. Never use an unbounded ffi.string on game data.
  local value=ffi.string(ffi.cast('const char *',0x1652740+0x150+2*250),250)
  return value:match('^([^%z]*)%z')
end
function M.new(scene,view,world,cursor,reader)
  local ownReturn=false
  local function snapshot(token)
    local s=NativeGameplay.snapshot(scene:snapshot())
    if not s or not Gameplay.live(s,true) or s.screen~=token.screen or s.mode~=token.mode
        or s.player~=token.player or s.synchronyMode~=token.synchronyMode
        or s.platformGeneration~=token.platformGeneration or s.width~=token.width or s.height~=token.height
        or s.modal2~=-1 or s.modal3~=-1 or s.textEditor~=0
        or read(0x1fe7d7c)~=0 or (s.synchronyMode==99 and read(0x191def8)~=1) then return nil end
    s.textIndex=read(0x1652740);s.textState=read(0x11265a8)
    s.operation=read(0x1126600)
    if s.modal==-1 and s.textModal==0 then return s,'done' end
    if s.modal==14 and s.textModal==14 and s.activeModalID==14 and s.operation==32 then
      return s,'progress'
    end
    if s.modal==10 and s.textModal==10 and s.activeModalID==10
        and s.activeModalMenu==0xb96290 and read(0xb96290)==0x6022f8
        and s.textIndex==2 and s.textState==3 and read(0x1652744)==1
        and read(0x165274c)==1 and Origin.read(s) then return s,'name' end
    if s.modal==11 and s.textModal==11 and s.activeModalID==11
        and s.activeModalMenu==0xb97ad8 and read(0xb97ad8)==0x602c08
        and s.textIndex==9 and s.textState==3 and s.operation==30
        and name()==NAME and Origin.read(s) then return s,'confirm' end
  end
  local adapter={}
  function adapter.open(context)
    local s=NativeGameplay.snapshot(scene:snapshot())
    if not s or not Context.same(context,Context.resolve(scene:resolve(view))) then return nil end
    if not world:dispatch('game.save.open',context) then return nil end
    return {screen=s.screen,mode=s.mode,player=s.player,synchronyMode=s.synchronyMode,
      platformGeneration=s.platformGeneration,width=s.width,height=s.height}
  end
  function adapter.observe(token)
    local s,kind=snapshot(token)
    if ownReturn and read(0x1652748)==0 then ownReturn=false end
    if kind=='name' and ownReturn and name()~=NAME then return nil end
    return kind
  end
  function adapter.submitName(token)
    local _,kind=snapshot(token)
    if kind~='name' or read(0x1652748)~=0 then return false end
    assert(#NAME<250 and not NAME:find('%z'),'quicksave.name')
    setName(text,2,NAME)
    if name()~=NAME then return false end
    ownReturn=true
    enter(text)
    return true
  end
  function adapter.context(token)
    local s,kind=snapshot(token)
    if kind~='confirm' then return nil end
    -- This private gesture context exists only for our proven non-editable
    -- overwrite confirmation. Save's editable name field never becomes eligible.
    return {verified=true,focused=true,text=false,composing=false,transition=false,
      owner='quicksave.confirm',screen=tostring(s.screen),panel='',modal='11',
      focus='',selection='',targeting='',state='live-sp',authority=false,
      generation=token.platformGeneration}
  end
  local function rows(token)
    local s,kind=snapshot(token)
    if kind~='confirm' then return nil end
    return reader:read(s.activeModalMenu,s,Origin.read(s))
  end
  local navigation=require('code/navigation').new({
    controls=function() return rows(adapter.token()) end,
    point=function(row) return row.x+math.floor(row.width/2),row.y+math.floor(row.height/2) end,
    hit=function(address) return ffi.cast('MenuItem *',address)[0].hovering~=0 end,
  },cursor)
  function adapter.confirm(token)
    return navigation:activateMatching({action=0x494950,parameter=22,kind=3},
      Context.resolve(adapter.context(token)))
  end
  function adapter.pending() return cursor.pending~=nil end
  function adapter.cancel()
    navigation:cancel()
    if ownReturn then
      -- Remove only our pending Return before forwarding a user's new input.
      -- This is local input debt, never a game/session state write.
      ffi.cast('int32_t *',0x1652748)[0]=0
      ownReturn=false
    end
  end
  local workflow=require('code/quicksave').new(adapter)
  function adapter.token() return workflow.token end
  function workflow:context() return self.active and adapter.context(self.token) or nil end
  return workflow
end
return M
