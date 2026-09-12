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
  local buckets={}
  for _,id in ipairs(M.order) do buckets[id]={} end
  for _,action in ipairs(catalog.ordered) do
    action.group=group(action.id)
    local bucket=buckets[action.group]
    bucket[#bucket+1]=action
  end
  catalog.editorOrdered={}
  for _,id in ipairs(M.order) do
    for _,action in ipairs(buckets[id]) do
      catalog.editorOrdered[#catalog.editorOrdered+1]=action
    end
  end
end
return M
