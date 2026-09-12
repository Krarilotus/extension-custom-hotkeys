-- Shared keyboard/mouse editor controller. A native UI view owns rendering,
-- focus and text input; this controller never manufactures native focus facts.
local M = {}
local Binding=require('code/binding')
M.__index = M

function M.new(profiles, catalog, router, labels, fold, pageSize)
  assert(type(labels) == 'function' and type(fold) == 'function', 'editor.locale')
  assert(type(pageSize) == 'number' and pageSize >= 1 and pageSize <= 30
    and pageSize == math.floor(pageSize), 'editor.page-size')
  profiles:begin()
  local self=setmetatable({profiles=profiles,catalog=catalog,router=router,
    labels=labels,fold=fold,pageSize=pageSize,query='',group=nil,
    selected=1,first=1,closed=false,capturing=false},M)
  self.groups={};local seen={}
  for _,action in ipairs(catalog.editorOrdered or catalog.ordered) do
    local group=action.group or action.id:match('^([^.]+)')
    if not seen[group] then seen[group]=true;self.groups[#self.groups+1]=group end
  end
  self:filter('',nil)
  return self
end

function M:filter(query, group)
  if type(query) ~= 'string' or #query > 120 then return nil,'editor.search' end
  self.query,self.group=query,group
  self.reassignment=nil
  local needle=self.fold(query)
  self.rows={}
  for _,action in ipairs(self.catalog.editorOrdered or self.catalog.ordered) do
    local actionGroup=action.group or action.id:match('^([^.]+)')
    local label=self.labels(action.label)
    if (not group or group==actionGroup) and self.fold(label):find(needle,1,true) then
      self.rows[#self.rows+1]={id=action.id,label=label,group=actionGroup}
    end
  end
  self.selected,self.first=1,1
  self.cachedView=nil
  return true
end

function M:navigate(delta)
  if self.closed or self.capturing or #self.rows==0 then return false end
  if type(delta)~='number' or delta~=math.floor(delta) then return false end
  self.reassignment=nil
  self.selected=math.max(1,math.min(#self.rows,self.selected+delta))
  if self.selected<self.first then self.first=self.selected end
  if self.selected>=self.first+self.pageSize then self.first=self.selected-self.pageSize+1 end
  self.cachedView=nil
  return true
end

function M:choose(row)
  if type(row)~='number' or row~=math.floor(row) or not self.rows[row] then return false end
  return self:navigate(row-self.selected)
end

-- Native scrollbar offsets are zero-based; keep the selected row visible.
function M:scroll(offset)
  if self.closed or self.capturing or type(offset)~='number'
      or offset~=math.floor(offset) then return false end
  local first=math.max(0,math.min(math.max(0,#self.rows-self.pageSize),offset))+1
  if first==self.first then return true end
  self.first=first
  self.selected=math.max(first,math.min(self.selected,math.min(#self.rows,first+self.pageSize-1)))
  self.reassignment=nil;self.cachedView=nil
  return true
end

function M:perform(operation,...)
  if self.closed or self.capturing then return nil,'editor.busy' end
  self.reassignment=nil
  local ok,err,detail=operation(self.profiles,...)
  self.error,self.detail=err,detail
  self.cachedView=nil
  return ok,err,detail
end

function M:selectProfile(name) return self:perform(self.profiles.select,name) end
function M:createProfile(name) return self:perform(self.profiles.create,name) end
function M:importProfile(name,document) return self:perform(self.profiles.import,name,document) end
function M:exportProfile() return self:perform(self.profiles.export) end

function M:capture()
  if self.closed or self.capturing or not self.rows[self.selected] then return false end
  local action=self.rows[self.selected].id
  self.capturing=true
  self.error,self.detail,self.reassignment=nil,nil,nil
  self.cachedView=nil
  self.router:startCapture(function(binding,err)
    if self.closed then return end
    self.cachedView=nil
    if binding then
      self.capturing=false
      local draft=self.profiles.draft
      local previous=draft.profiles[draft.active].bindings[action]
      local ok,problem,detail=self:perform(self.profiles.bind,action,binding)
      if not ok and (problem=='binding.conflict' or problem=='binding.native-conflict')
          and type(detail)=='table' then
        local other=detail[1]==action and detail[2] or (detail[2]==action and detail[1])
        if other then self.reassignment={action=action,binding=binding,other=other,
          replacement=previous,draft=draft} end
      end
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
  self.reassignment=nil
  self.cachedView=nil
end

-- A failed capture offers an explicit atomic swap. Native conflicts still
-- require a usable replacement, and any third collision rejects both edits.
function M:reassign()
  local candidate=self.reassignment
  if not candidate or candidate.draft~=self.profiles.draft then return false end
  return self:perform(self.profiles.reassign,candidate.action,candidate.binding,
    candidate.other,candidate.replacement)
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
  self.cachedView=nil
  return ok,err
end

function M:cancel()
  self.profiles:cancel()
  self.closed,self.capturing=true,false
  self.cachedView=nil
end

function M:view()
  if self.cachedView then return self.cachedView end
  local document=self.profiles.draft or self.profiles.committed
  local profile=document.profiles[document.active]
  local rows,names={},{}
  for name in pairs(document.profiles) do names[#names+1]=name end
  table.sort(names)
  for i=self.first,math.min(#self.rows,self.first+self.pageSize-1) do
    local row=self.rows[i]
    local b=profile.bindings[row.id]
    rows[#rows+1]={index=i,id=row.id,label=row.label,group=row.group,
      sectionStart=i==self.first or self.rows[i-1].group~=row.group,
      selected=i==self.selected,binding=b and assert(Binding.validate(b)) or false}
  end
  local preset=profile.preset and self.catalog.presets and self.catalog.presets[profile.preset]
  local activeLabel=preset and document.active==preset.name and self.labels('preset.'..preset.id) or document.active
  self.cachedView={rows=rows,profiles=names,active=document.active,activeLabel=activeLabel,first=self.first,
    total=#self.rows,capturing=self.capturing,error=self.error,detail=self.detail,
    closed=self.closed}
  return self.cachedView
end

return M
