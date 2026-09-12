local M={}
function M.validate(state)
  return type(state)=='table' and state.version==1 and type(state.blocked)=='boolean'
    and type(state.generation)=='number' and state.generation>=0
    and state.generation<=9007199254740991 and state.generation==math.floor(state.generation)
end
return M
