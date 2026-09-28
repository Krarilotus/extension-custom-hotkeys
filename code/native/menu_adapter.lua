-- Reads only the active native menu; Navigation owns deferred activation.
local A=require('code/addresses')
local ffi=require('ffi')
local Load=require('code/load_context')
local Dialog=require('code/dialog_context')
local M={}
function M.new(scene,reader)
  local step=ffi.new('int[1]')
  local sliderOffset=ffi.offsetof('MenuItem','secondItemTypeData')
  return {
    gridControls=function(context)
      if not context or (context.owner~='game.build' and context.owner~='game.build.slide'
          and context.owner~='game.status') then return nil end
      local s=scene:snapshot()
      if tostring(s.screen)~=context.screen or s.modal~=-1 or not require('code/modal_context').background(s) then return nil end
      -- Direct callbacks use the native tab immediately; the toolbar slide is
      -- visual. Grid still reads the current tab's native disabled state.
      return reader:read(remote.interface.menuAddress(s.screen),s,nil,true,true)
    end,
    controls=function(context,direct)
      if not context or (context.owner:sub(1,5)~='menu.' and context.owner~='game.build'
          and context.owner~='game.build.slide'
          and context.owner~='game.status' and context.owner~='game.options' and context.owner~='game.load') then return nil end
      local s=scene:snapshot()
      if context.owner=='game.load' or context.owner=='menu.load' then
        if tostring(s.screen)~=context.screen or not Load.owns(s) then return nil end
        local origin=Load.origin(s)
        if not origin then return nil end
        return Load.controls(reader:read(s.activeModalMenu,s,origin),s)
      end
      if context.owner=='game.options' or context.owner=='menu.options' then
        if tostring(s.screen)~=context.screen or not Dialog.owns(s) then return nil end
        local origin=Dialog.origin(s)
        if not origin then return nil end
        return reader:read(s.activeModalMenu,s,origin)
      end
      if tostring(s.screen)~=context.screen or s.modal~=-1 or not require('code/modal_context').background(s) then return nil end
      return reader:read(remote.interface.menuAddress(s.screen),s,nil,false,
        direct and (context.owner=='game.build' or context.owner=='game.build.slide'
          or context.owner=='game.status'))
    end,
    point=function(row) return row.x+math.floor(row.width/2),row.y+math.floor(row.height/2) end,
    hit=function(address) return ffi.cast('MenuItem *',address)[0].hovering~=0 end,
    invoke=function(row,context)
      -- MenuItem::handleMouseInteraction passes this parameter to the same
      -- cdecl callback for kinds2/3/4. Keep native eligibility/submission code;
      -- selecting a building never writes its placement ID or moves the cursor.
      local fast=context and (context.owner=='game.build' or context.owner=='game.build.slide')
          and row.action==A.buildCategoryAction
      local before=fast and scene:snapshot() or nil
      fast=before and before.screen==14 and before.delay==-1 and before.modal==-1
          and before.focused and not before.composing and before.textModal==0
          and before.textEditor==0 and tostring(before.tab)..':'..before.subtab==context.panel
          and require('code/modal_context').background(before)
      ffi.cast('MenuItem *',row.address)[0].menuItemActionHandler.simple(row.parameter)
      if fast then
        local after=scene:snapshot()
        -- The native callback has already accepted the category and scheduled
        -- GameCore's 150 ms local menu switch. Bring only that UI switch to the
        -- next frame; GameCore still commits the tab and its native controls.
        if after.screen==14 and after.tab==before.tab and after.subtab==before.subtab
            and after.delay==150 and after.modal==-1
            and after.focused and not after.composing and after.textModal==0
            and after.textEditor==0 and require('code/modal_context').background(after) then
          ffi.cast('int32_t *',A.screenDelay)[0]=1
        end
      end
    end,
    adjust=function(row,delta)
      -- MenuItem input passes its own slider state to the handler. Rendering
      -- reads that same state; separate value buffers leave the thumb stale.
      local item=ffi.cast('MenuItem *',row.address)[0]
      local state=ffi.cast('int *',ffi.cast('uint8_t *',row.address)+sliderOffset)
      local handler=item.menuItemActionHandler.slider
      handler(row.parameter,1,state,state+1,state+2)
      local lo,hi,current=tonumber(state[0]),tonumber(state[1]),tonumber(state[2])
      if lo>hi or current<lo or current>hi then return end
      -- Event7 lets the owner set its step (e.g. Automarket). The type-data
      -- field at +0x20 is the thumb's pixel width, not an increment.
      step[0]=1;handler(row.parameter,7,state,state+1,step)
      if step[0]<1 then return end
      state[2]=math.max(lo,math.min(hi,current+delta*tonumber(step[0])))
      if state[2]~=current then
        handler(row.parameter,2,state,state+1,state+2)
        -- Reflect native rejection/normalization, including session authority.
        handler(row.parameter,1,state,state+1,state+2)
      end
    end,
  }
end
return M
