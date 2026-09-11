local en={title='Custom Hotkeys',profile='Profile',new='New profile',search='Search',
  groups='Group',all='All',capture='Change key',clear='Clear key',reset='Reset action',
  resetProfile='Reset profile',apply='Apply',cancel='Cancel',unbound='Unbound',
  press='Press a key combination. Escape cancels.',editing='Enter accepts; Escape cancels.',
  invalid='This change is not available. Check the binding or profile name.',
  conflict='This key overlaps another action.',text='Text',default='Default',
  ['hotkeys.open']='Open hotkey settings', ['menu.next']='Next control',
  ['menu.previous']='Previous control', ['menu.activate']='Activate control',
  ['menu.back']='Back', ['editor.capture']='Change selected binding'}
local de={title='Eigene Tastenkürzel',profile='Profil',new='Neues Profil',search='Suche',
  groups='Gruppe',all='Alle',capture='Taste ändern',clear='Taste löschen',reset='Aktion zurücksetzen',
  resetProfile='Profil zurücksetzen',apply='Übernehmen',cancel='Abbrechen',unbound='Unbelegt',
  press='Tastenkombination drücken. Escape bricht ab.',editing='Enter bestätigt; Escape bricht ab.',
  invalid='Änderung nicht möglich. Tastenkürzel oder Profilnamen prüfen.',
  conflict='Dieses Tastenkürzel überschneidet sich mit einer anderen Aktion.',text='Text',
  default='Standard', ['hotkeys.open']='Tastenkürzel öffnen', ['menu.next']='Nächstes Bedienelement',
  ['menu.previous']='Vorheriges Bedienelement', ['menu.activate']='Bedienelement aktivieren',
  ['menu.back']='Zurück', ['editor.capture']='Gewähltes Tastenkürzel ändern'}
local M={}
function M.new(language)
  local chosen=language=='german' and de or en
  return function(key) return chosen[key] or en[key] or key end
end
return M
