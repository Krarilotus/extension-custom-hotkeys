local Binding=require('code/binding')
local Catalog=require('code/catalog')
local Text=require('code/text_edit')
local M={}

local languages={'en','de','fr','ru','hu','tr','ch','es','fa'}
local owners={world={'game.build','game.status'}, panel={'game.build','game.status'},
  editor={'editor.map'}, modal={'game.options','game.load','menu.options','menu.load','extension.modal'}}
local states={world={'live-sp','live-mp'},panel={'live-sp','live-mp'},
  editor={'editor'},modal={'menu','live-sp','live-mp','editor'}}
local fields={id=true,label=true,category=true,context=true,default=true,callback=true,
  submit=true,release=true,sound=true}

local function localized(values)
  assert(type(values)=='table','action.locale')
  local result={}
  for _,language in ipairs(languages) do
    local value=values[language]
    assert(type(value)=='string' and #value<=120 and value:find('%S')
      and Text.valid(value) and not value:find('[%z\1-\31\127]'),'action.locale: '..language)
    result[language]=value
  end
  return result
end

function M.new()
  local definitions,handlers,frozen={},{},false
  return {
    register=function(spec)
      assert(not frozen,'action.registration-closed')
      assert(type(spec)=='table' and Catalog.extensionId(spec.id),'action.extension-id')
      assert(not handlers[spec.id],'action.duplicate: '..spec.id)
      for field in pairs(spec) do assert(fields[field],'action.field: '..tostring(field)) end
      local context=spec.context
      assert(type(context)=='table' and owners[context.kind],'action.context')
      local kind=context.kind
      local scope=context[kind=='panel' and 'tab' or 'id']
      for field in pairs(context) do
        assert(field=='kind' or (kind=='panel' and field=='tab')
          or (kind=='modal' and field=='id'),'action.context-field')
      end
      if kind=='panel' or kind=='modal' then
        assert(type(scope)=='number' and scope>=0 and scope%1==0 and scope<=2147483647,'action.context-id')
      end
      local command=spec.submit~=nil
      assert(command and type(spec.submit)=='function' and spec.callback==nil
        or not command and type(spec.callback)=='function','action.callback')
      assert(not command or kind=='world' or kind=='panel','action.command-context')
      assert(spec.release==nil or not command and type(spec.release)=='function','action.release')
      assert(spec.sound==nil or spec.sound=='click' or type(spec.sound)=='function','action.sound')
      local binding=spec.default
      if binding~=nil and binding~=false then
        binding=assert(Binding.validate(binding))
        assert(not binding.wheel or not spec.release,'binding.unsupported')
      end
      definitions[#definitions+1]={id=spec.id,contexts=owners[kind],states=states[kind],
        panels=kind=='panel' and {tostring(scope)} or nil,
        modals=kind=='modal' and {tostring(scope)} or nil,
        command=command,behavior=spec.release and 'hold-local' or 'press',
        default=binding,extension=true,labels=localized(spec.label),category=localized(spec.category),clickSound=spec.sound=='click'}
      handlers[spec.id]={press=spec.submit or spec.callback,release=spec.release,
        command=command,sound=type(spec.sound)=='function' and spec.sound or nil}
      return true
    end,
    freeze=function()
      frozen=true
      table.sort(definitions,function(a,b) return a.id<b.id end)
      return definitions
    end,
    dispatch=function(id,phase,context,event,canSubmit)
      local handler=handlers[id]
      if not handler or handler.failed or (handler.command and not canSubmit()) then return false end
      if phase=='release' and handler.starting then
        handler.cancelled=true
        return true
      end
      if phase=='release' and not handler.held then return false end
      local fn=phase=='release' and handler.release or handler.press
      if phase=='release' then handler.held=false end
      handler.starting=phase=='press' and handler.release~=nil
      local ok,result=pcall(fn,context,event)
      if handler.starting then
        handler.starting=false
        handler.held=not ok or result==true
        if handler.cancelled and handler.held then
          handler.held=false
          local released,problem=pcall(handler.release)
          if not released then ok,result=false,problem end
        end
        handler.cancelled=false
      end
      local accepted=ok and result==true
      if accepted and phase=='press' and handler.sound then ok,result=pcall(handler.sound) end
      if not ok then
        if handler.held then pcall(handler.release);handler.held=false end
        handler.failed=true
        return false,tostring(result)
      end
      return accepted
    end,
  }
end
return M
