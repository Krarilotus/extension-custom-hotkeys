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
for id,names in pairs({
  ['menu.focus.armory']={'Focus and open armory','Waffenkammer zeigen und öffnen'},
  ['menu.open.armory']={'Open armory panel','Waffenkammer öffnen'},
  ['camera.return.armory']={'Return from armory','Von Waffenkammer zurück'},
  ['camera.cycle.signposts']={'Cycle signposts','Wegweiser durchgehen'},
  ['unit.stance.stand-ground']={'Stand ground','Stellung halten'},
  ['unit.stance.defensive']={'Defensive stance','Defensive Haltung'},
  ['unit.stance.aggressive']={'Aggressive stance','Aggressive Haltung'},
}) do en[id]=names[1];de[id]=names[2] end
en['game.menu.activate']='Activate gameplay control'
de['game.menu.activate']='Bedienelement im Spiel aktivieren'
en['target.center']='Center targeting cursor';de['target.center']='Zielcursor zentrieren'
en['target.confirm']='Confirm target';de['target.confirm']='Ziel bestätigen'
en['target.cancel']='Cancel target or selection';de['target.cancel']='Ziel oder Auswahl abbrechen'
for key,names in pairs({up={'up','oben'},down={'down','unten'},left={'left','links'},right={'right','rechts'}}) do
  en['camera.pan.'..key]='Pan camera '..names[1]
  de['camera.pan.'..key]='Kamera nach '..names[2]
  en['target.'..key]='Move target '..names[1]
  de['target.'..key]='Zielcursor nach '..names[2]
  en['target.fine.'..key]='Move target '..names[1]..' precisely'
  de['target.fine.'..key]='Zielcursor fein nach '..names[2]
end
function M.new(language)
  local chosen=language=='german' and de or en
  return function(key) return chosen[key] or en[key] or key end
end
return M
