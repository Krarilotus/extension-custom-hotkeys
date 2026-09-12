-- Host-state adapter: use only Recorder's public input lifecycle contract.
local M={}
local idle={version=1,generation=0,blocked=false}
function M.connect(modules,extensions)
  local active=false
  for _,extension in ipairs(extensions) do
    if extension.name=='recorder' then active=true end
  end
  if not active then return {read=function() return idle end} end
  local recorder=modules.recorder
  assert(recorder,'recorder.module-unavailable')
  assert(recorder.inputStateVersion==1
    and type(recorder.getInputState)=='function'
    and type(recorder.observeInputTransitions)=='function','activation.recorder-api')
  local function read() return recorder:getInputState() end
  local state=read()
  assert(require('code/recorder_context').validate(state),'recorder.state-unavailable')
  return {read=read,observe=function(callback) return recorder:observeInputTransitions(callback) end}
end
return M
