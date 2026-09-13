-- Current UCP 3.0.7 public io.open boundary. Fixed installation-local files are
-- outside the immutable module ZIP; launcher imports never write these files.
local M = {}
local allowed = {['profiles-a.json']=true,['profiles-b.json']=true}
function M.new(ucpIO,role)
  assert(type(ucpIO.open)=='function', 'store.io-unavailable')
  assert(role==nil or role=='exchange','store.role')
  local prefix=role=='exchange' and 'ucp/custom-hotkeys-exchange-' or 'ucp/custom-hotkeys-'
  return {open=function(_,name,mode)
    assert(allowed[name] and (mode=='rb' or mode=='wb'), 'store.path')
    local file,err,errno=ucpIO.open(prefix..name,mode)
    -- The normal-file branch of luaIOCustomOpen uses luaL_fileresult.
    -- Only ENOENT means absent; permissions and other failures are not defaults.
    if not file then return nil,errno==2 and 'missing' or 'io' end
    return file
  end}
end
return M
