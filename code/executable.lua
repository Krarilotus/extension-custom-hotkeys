local M={}
local reference='3bb0a8c1e72331b3a30a5aa93ed94beca0081b476b04c1960e26d5b45387ac5a'
function M.check(name,boundary,sha256)
  if type(name)~='string' or name=='' or name:find('[/\\:%z]') then
    return nil,'executable.name'
  end
  local file=boundary.open(name,'rb')
  if not file then return nil,'executable.read' end
  local ok,bytes=pcall(file.read,file,32*1024*1024+1)
  local closed,status=pcall(file.close,file)
  if not ok or not closed or not status or type(bytes)~='string'
      or #bytes>32*1024*1024 then return nil,'executable.read' end
  if sha256(bytes)~=reference then return nil,'executable.unsupported' end
  return true
end
return M
