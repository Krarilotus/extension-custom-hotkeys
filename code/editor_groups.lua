-- Presentation only: player tasks, independent of action IDs, translated names,
-- bindings and dispatch contexts. Preserve native/control order inside each task.
local M={order={'navigation','saving','camera','selection','buildings',
  'construction','commands','siege','grid','targeting'}}
local exact={
  ['hotkeys.open']='navigation',['menu.next']='navigation',
  ['menu.previous']='navigation',['menu.activate']='navigation',
  ['menu.decrease']='navigation',['menu.increase']='navigation',
  ['game.menu.activate']='navigation',['view.toggle-interface']='navigation',
  ['unit.control.patrol']='commands',
}
local function group(id)
  if exact[id] then return exact[id] end
  if id:match('^game%.') then return 'saving' end
  if id:match('^unit%.group%.') or id:match('^camera%.group%.') then return 'selection' end
  if id:match('^camera%.return%.') or id:match('^menu%.focus%.')
      or id:match('^menu%.open%.') then return 'buildings' end
  if id:match('^camera%.') or id:match('^view%.') then return 'camera' end
  if id:match('^menu%.build%.') or id:match('^build%.select%.') then return 'construction' end
  if id:match('^unit%.stance%.') then return 'commands' end
  if id:match('^pointer%.') then return 'commands' end
  if id:match('^unit%.control%.') then return 'siege' end
  if id:match('^grid%.slot%.') then return 'grid' end
  if id:match('^target%.') then return 'targeting' end
  error('editor.group-missing: '..id)
end
function M.attach(catalog)
  local buckets,extensions={},{}
  for _,id in ipairs(M.order) do buckets[id]={} end
  for _,action in ipairs(catalog.ordered) do
    local bucket
    if action.extension then
      -- Categories are presentation data. Use the module namespace plus the
      -- English category as the grouping key and keep labels separate.
      action.group=action.id:match('^(ext%.[^.]+)')..':'..action.category.en
      catalog.extensionLabels=catalog.extensionLabels or {}
      catalog.extensionLabels[action.id]=action.labels
      catalog.extensionLabels['group.'..action.group]=action.category
      bucket=extensions
    else
      action.group=group(action.id)
      bucket=buckets[action.group]
    end
    bucket[#bucket+1]=action
  end
  catalog.editorOrdered={}
  for _,id in ipairs(M.order) do
    for _,action in ipairs(buckets[id]) do
      catalog.editorOrdered[#catalog.editorOrdered+1]=action
    end
  end
  table.sort(extensions,function(a,b)
    if a.group==b.group then return a.id<b.id end
    return a.group<b.group
  end)
  for _,action in ipairs(extensions) do catalog.editorOrdered[#catalog.editorOrdered+1]=action end
end
return M
