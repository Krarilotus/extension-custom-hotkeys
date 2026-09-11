-- Shared keyboard/mouse editor controller. A native UI view owns rendering,
-- focus and text input; this controller never manufactures native focus facts.
local M = {}
M.__index = M

function M.new(profiles, catalog, router, labels, fold, pageSize)
  assert(type(labels) == 'function' and type(fold) == 'function', 'editor.locale')
  assert(type(pageSize) == 'number' and pageSize >= 1 and pageSize <= 30
    and pageSize == math.floor(pageSize), 'editor.page-size')
  profiles:begin()
  local self=setmetatable({profiles=profiles,catalog=catalog,router=router,
    labels=labels,fold=fold,pageSize=pageSize,query='',group=nil,
    selected=1,first=1,closed=false,capturing=false},M)
  self:filter('',nil)
  return self
end

function M:filter(query, group)
  if type(query) ~= 'string' or #query > 120 then return nil,'editor.search' end
  self.query,self.group=query,group
  local needle=self.fold(query)
  self.rows={}
  for _,action in ipairs(self.catalog.ordered) do
    local actionGroup=action.id:match('^([^.]+)')
    local label=self.labels(action.label)
    if (not group or group==actionGroup) and self.fold(label):find(needle,1,true) then
      self.rows[#self.rows+1]={id=action.id,label=label,group=actionGroup}
    end
  end
  self.selected,self.first=1,1
  return true
end

function M:navigate(delta)
  if self.closed or self.capturing or #self.rows==0 then return false end
  if type(delta)~='number' or delta~=math.floor(delta) then return false end
  self.selected=math.max(1,math.min(#self.rows,self.selected+delta))
  if self.selected<self.first then self.first=self.selected end
  if self.selected>=self.first+self.pageSize then self.first=self.selected-self.pageSize+1 end
  return true
end

function M:choose(row)
  if type(row)~='number' or row~=math.floor(row) or not self.rows[row] then return false end
  return self:navigate(row-self.selected)
end

function M:perform(operation,...)
  if self.closed or self.capturing then return nil,'editor.busy' end
  local ok,err,detail=operation(self.profiles,...)
  self.error,self.detail=err,detail
  return ok,err,detail
end

function M:selectProfile(name) return self:perform(self.profiles.select,name) end
function M:createProfile(name) return self:perform(self.profiles.create,name) end

function M:capture()
  if self.closed or self.capturing or not self.rows[self.selected] then return false end
  local action=self.rows[self.selected].id
  self.capturing=true
  self.router:startCapture(function(binding,err)
    if self.closed then return end
    if binding then
      self.capturing=false
      self:perform(self.profiles.bind,action,binding)
    elseif err=='capture.cancel' then
      self.capturing=false
      self.error,self.detail=nil,nil
    else self.error,self.detail=err,nil end
  end)
  return true
end

function M:cancelCapture()
  self.router:barrier()
  self.capturing=false
  self.error,self.detail=nil,nil
end

function M:clear()
  local row=self.rows[self.selected]
  if not row then return false end
  return self:perform(self.profiles.bind,row.id,false)
end

function M:resetAction()
  local row=self.rows[self.selected]
  if not row then return false end
  return self:perform(self.profiles.reset,row.id)
end

function M:resetProfile() return self:perform(self.profiles.reset) end

function M:apply()
  local ok,err=self:perform(self.profiles.apply)
  if ok then self.closed=true end
  return ok,err
end

function M:cancel()
  self.profiles:cancel()
  self.closed,self.capturing=true,false
end

function M:view()
  local document=self.profiles.draft or self.profiles.committed
  local profile=document.profiles[document.active]
  local rows,names={},{}
  for name in pairs(document.profiles) do names[#names+1]=name end
  table.sort(names)
  for i=self.first,math.min(#self.rows,self.first+self.pageSize-1) do
    local row=self.rows[i]
    local b=profile.bindings[row.id]
    rows[#rows+1]={index=i,id=row.id,label=row.label,group=row.group,
      selected=i==self.selected,binding=b and {scan=b.scan,extended=b.extended,mods=b.mods} or false}
  end
  return {rows=rows,profiles=names,active=document.active,first=self.first,
    total=#self.rows,capturing=self.capturing,error=self.error,detail=self.detail,
    closed=self.closed}
end

return M
