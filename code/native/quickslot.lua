local ffi=require('ffi')
local Context=require('code/context')
local Gameplay=require('code/gameplay')
local NativeGameplay=require('code/native/gameplay')
local Origin=require('code/modal_origin')
local Load=require('code/load_context')
local Plan=require('code/quickload_plan')
local M={}
local NAME='Custom Hotkeys Quick'
local function read(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local text=ffi.cast('void *',0x1652740)
local setName=ffi.cast('void (__thiscall *)(void *,int,const char *)',0x469800)
local hit=ffi.cast('int (__thiscall *)(void *,int,int,int,int)',0x4680c0)
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
    if not s or s.inputBlocked or s.inputGeneration~=token.inputGeneration
        or not Gameplay.live(s,true) or s.screen~=token.screen or s.mode~=token.mode
        or s.player~=token.player or s.synchronyMode~=token.synchronyMode
        or s.platformGeneration~=token.platformGeneration or s.width~=token.width or s.height~=token.height
        or s.modal2~=-1 or s.modal3~=-1 or s.textEditor~=0
        or read(0x1fe7d7c)~=0 or (s.synchronyMode==99 and read(0x191def8)~=1) then return nil end
    s.textIndex=read(0x1652740);s.textState=read(0x11265a8)
    s.operation=read(0x1126600)
    if s.modal==-1 and s.textModal==0 then return s,'done' end
    if s.modal==14 and s.textModal==14 and s.activeModalID==14 and s.operation==(token.action=='game.quickload' and 31 or 32) then
      return s,'progress'
    end
    if token.action=='game.quickload' then
      if Load.origin(s) then return s,'load' end
      return nil
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
  function adapter.open(context,action)
    local s=NativeGameplay.snapshot(scene:snapshot())
    if not s or not Context.same(context,Context.resolve(scene:resolve(view))) then return nil end
    if not world:dispatch(action=='game.quickload' and 'game.load.open' or 'game.save.open',context) then return nil end
    return {action=action or 'game.quicksave',screen=s.screen,mode=s.mode,player=s.player,synchronyMode=s.synchronyMode,
      platformGeneration=s.platformGeneration,inputGeneration=s.inputGeneration,width=s.width,height=s.height}
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
    if kind~='confirm' and kind~='load' then return nil end
    -- Only the verified Load list and overwrite confirmation own this private
    -- gesture context. Save's editable name field never becomes eligible.
    return {verified=true,focused=true,text=false,composing=false,transition=false,
      owner='quickslot.'..kind,screen=tostring(s.screen),panel='',modal=tostring(s.modal),
      focus='',selection=kind=='load' and Load.identity(s) or '',targeting='',state='live-sp',authority=false,
      generation=token.platformGeneration}
  end
  local function rows(token)
    local s,kind=snapshot(token)
    if kind~='confirm' and kind~='load' then return nil end
    local result=reader:read(s.activeModalMenu,s,Origin.read(s))
    if kind=='confirm' then return result end
    local filtered=Load.controls(result,s)
    if not filtered then return nil end
    for _,row in ipairs(result) do
      if row.action==0x492ba0 and row.kind==6 and row.parameter==0
          and row.height>=64 and row.width>=10 and row.width<=64 then
        filtered[#filtered+1]=row
      end
    end
    return filtered
  end
  local function point(row)
    local x=row.x+math.floor(row.width/2)
    if row.kind==6 then
      local token=adapter.token()
      if not token or not token.step then return nil end
      return x,row.y+(token.step.direction<0 and 1 or row.height-2)
    end
    return x,row.y+math.floor(row.height/2)
  end
  local navigation=require('code/navigation').new({
    controls=function() return rows(adapter.token()) end,
    point=point,
    hit=function(address)
      for _,row in ipairs(rows(adapter.token()) or {}) do
        if row.address==address then
          if row.kind~=6 then return ffi.cast('MenuItem *',address)[0].hovering~=0 end
          -- Native scrollbar hover is only set after a press. Prove its rectangle
          -- with the same read-only native hit test before introducing that press.
          return hit(ffi.cast('void *',0xf2c9b0),row.x,row.y,row.width,row.height)~=0
        end
      end
      return false
    end,
  },cursor)
  function adapter.confirm(token)
    return navigation:activateMatching({action=0x494950,parameter=22,kind=3},
      Context.resolve(adapter.context(token)))
  end
  local function slotName(identity,index)
    local a,b,c,d=identity:byte(index*4+1,index*4+4)
    local nativeIndex=a+b*256+c*65536+d*16777216
    if nativeIndex>499 then return nil end
    local data=ffi.string(ffi.cast('const char *',0x11bf130+0xbc8+nativeIndex*1001),1001)
    return data:match('^([^%z]*)%z')
  end
  function adapter.loadStep(token)
    local s,kind=snapshot(token)
    if kind~='load' or token.committed then return false end
    if not token.list then
      token.list=s.loadIdentity
      for index=0,s.loadCount-1 do
        local value=slotName(token.list,index)
        if not value then return false end
        if value:lower()==NAME:lower() then
          if token.index then return false end
          token.index=index
        end
      end
      if not token.index then return false end
    end
    if token.list~=s.loadIdentity then return false end
    local selectedName=slotName(token.list,token.index)
    if not selectedName or selectedName:lower()~=NAME:lower() then return false end
    if token.step then
      if token.step.offset and s.loadOffset~=token.step.offset
          or token.step.selected and s.loadSelected~=token.step.selected then return false end
    end
    token.step=Plan.next(s,token.index)
    if not token.step then return false end
    if token.step.commit then token.committed=true end
    return navigation:activateMatching(token.step,Context.resolve(adapter.context(token)))
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
  local workflow=require('code/quickslot').new(adapter)
  function adapter.token() return workflow.token end
  function workflow:context() return self.active and adapter.context(self.token) or nil end
  return workflow
end
return M
