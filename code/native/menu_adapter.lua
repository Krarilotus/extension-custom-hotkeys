-- Reads only the active native menu; Navigation owns deferred activation.
local ffi=require('ffi')
local Load=require('code/load_context')
local Options=require('code/options_context')
local M={}
function M.new(scene,reader)
  return {
    gridControls=function(context)
      if not context or (context.owner~='game.build' and context.owner~='game.status') then return nil end
      local s=scene:snapshot()
      if tostring(s.screen)~=context.screen or s.modal~=-1 or not require('code/modal_context').background(s) then return nil end
      return reader:read(remote.interface.menuAddress(s.screen),s,nil,true)
    end,
    controls=function(context)
      if not context or (context.owner:sub(1,5)~='menu.' and context.owner~='game.build'
          and context.owner~='game.status' and context.owner~='game.options' and context.owner~='game.load') then return nil end
      local s=scene:snapshot()
      if context.owner=='game.load' then
        if tostring(s.screen)~=context.screen or not Load.owns(s) then return nil end
        local origin=Load.origin(s)
        if not origin then return nil end
        return Load.controls(reader:read(s.activeModalMenu,s,origin),s)
      end
      if context.owner=='game.options' then
        if tostring(s.screen)~=context.screen or not Options.owns(s) then return nil end
        local origin=Options.origin(s)
        if not origin then return nil end
        return reader:read(s.activeModalMenu,s,origin)
      end
      if tostring(s.screen)~=context.screen or s.modal~=-1 or not require('code/modal_context').background(s) then return nil end
      return reader:read(remote.interface.menuAddress(s.screen),s)
    end,
    point=function(row) return row.x+math.floor(row.width/2),row.y+math.floor(row.height/2) end,
    hit=function(address) return ffi.cast('MenuItem *',address)[0].hovering~=0 end,
    invoke=function(row)
      -- MenuItem::handleMouseInteraction passes this parameter to the same
      -- cdecl callback for kinds2/3/4. Keep native eligibility/submission code;
      -- selecting a building never writes its placement ID or moves the cursor.
      ffi.cast('MenuItem *',row.address)[0].menuItemActionHandler.simple(row.parameter)
    end,
  }
end
return M
