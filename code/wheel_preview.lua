-- The PR #14 wheel preview used these two public IDs. Keep its providers and
-- profiles interoperable while all other modules use the generic registry.
local M={ids={
  ['view.resolution-zoom-in']='ext.resolution-based-zoom.in',
  ['view.resolution-zoom-out']='ext.resolution-based-zoom.out',
}}
-- Existing preview translations need human review.
local labels={
  en={'Zoom in','Zoom out'},de={'Vergrößern','Verkleinern'},fr={'Zoom avant','Zoom arrière'},
  ru={'Приблизить','Отдалить'},hu={'Nagyítás','Kicsinyítés'},tr={'Yakınlaştır','Uzaklaştır'},
  ch={'放大','缩小'},es={'Acercar','Alejar'},fa={'بزرگ‌نمایی','کوچک‌نمایی'},
}
function M.register(registry,id,callback)
  local current=assert(M.ids[id],'action.unknown: '..tostring(id))
  assert(type(callback)=='function','action.callback')
  local zoomIn=id=='view.resolution-zoom-in'
  local category,label={},{}
  for language,pair in pairs(labels) do
    category[language]='Resolution Based Zoom'
    label[language]=pair[zoomIn and 1 or 2]
  end
  return registry.register{
    id=current,label=label,category=category,context={kind='world'},
    default={wheel=zoomIn and 'up' or 'down',mods=1},callback=callback,
  }
end
return M
