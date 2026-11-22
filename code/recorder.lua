-- Optional lifecycle notifications, not a tester-build compatibility gate.
local M={}
function M.connect(modules,extensions)
  local active=false
  for _,extension in ipairs(extensions) do
    if extension.name=='recorder' then active=true end
  end
  local recorder=active and modules.recorder
  local adapter={read=function() return 0 end,canSubmit=function() return not active end}
  if not recorder or recorder.inputStateVersion~=1 then return adapter end
  if type(recorder.getInputState)=='function' then
    function adapter.read()
      local state=recorder:getInputState()
      local generation=type(state)=='table' and state.generation
      if type(generation)=='number' and generation>=0 and generation<=9007199254740991
          and generation==math.floor(generation) then return generation end
      return 0
    end
    -- This gate only applies to new provider commands. Existing actions keep
    -- their established tester/playback behavior.
    function adapter.canSubmit()
      local ok,state=pcall(recorder.getInputState,recorder)
      return ok and type(state)=='table' and state.version==1 and state.blocked==false
    end
  end
  if type(recorder.observeInputTransitions)=='function' then
    function adapter.observe(callback) return recorder:observeInputTransitions(callback) end
  end
  return adapter
end
return M
