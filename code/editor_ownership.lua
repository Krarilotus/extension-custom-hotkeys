local M={}
-- Focus loss suspends input without discarding the draft. A replaced modal or
-- parent ends this editor's ownership; never close the replacement modal.
function M.reconcile(view,snapshot)
  if not view.opened then return false end
  if snapshot.screen==view.parentScreen and snapshot.modal==view.modalID then return true end
  if view.restoreHover then view:restoreHover(snapshot) end
  view.opened=false
  view.text=nil
  view.router:barrier()
  view.controller:cancel()
  return false
end
return M
