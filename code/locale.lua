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
en.mainHelp1='Change keyboard shortcuts.';en.mainHelp2='Create, import and export profiles.'
de.mainHelp1='Tastenkürzel anpassen.';de.mainHelp2='Profile erstellen und austauschen.'
en['view.rotate-left']='Rotate view left';de['view.rotate-left']='Ansicht nach links drehen'
en['view.rotate-right']='Rotate view right';de['view.rotate-right']='Ansicht nach rechts drehen'
en['view.toggle-zoom']='Toggle zoom';de['view.toggle-zoom']='Zoom umschalten'
en['view.lower-buildings']='Lower buildings';de['view.lower-buildings']='Gebäude absenken'
en['view.toggle-interface']='Show or hide toolbar';de['view.toggle-interface']='Werkzeugleiste ein-/ausblenden'
en['group.view']='View';de['group.view']='Ansicht'
en.swap='Swap keys';de.swap='Tauschen'
en.import='Import profile';en.export='Export profile';en.exported='Profile exported.'
en.importName='Enter a new profile name. Enter accepts; Escape cancels.'
en.fileError='Profile file unavailable. Check the import/export files.'
de.import='Profil importieren';de.export='Profil exportieren';de.exported='Profil exportiert.'
de.importName='Neuen Profilnamen eingeben. Enter bestätigt; Escape bricht ab.'
de.fileError='Profildatei nicht verfügbar. Import-/Exportdateien prüfen.'
en.open='Open: ';en.choose='Choose: ';de.open='Öffnen: ';de.choose='Wählen: '
en.focusOpen='Focus and open: ';en.returnFrom='Return from: '
de.focusOpen='Zeigen und öffnen: ';de.returnFrom='Zurück von: '
for group,names in pairs({hotkeys={'Hotkeys','Tastenkürzel'},menu={'Menus','Menüs'},
  game={'Game','Spiel'},target={'Targeting','Zielen'},camera={'Camera','Kamera'},
  unit={'Units','Einheiten'},build={'Construction','Bauen'}}) do
  en['group.'..group]=names[1];de['group.'..group]=names[2]
end
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
function M.new(language,nativeText)
  language=type(language)=='string' and language:lower() or 'english'
  local chosen=language=='german' and de or en
  if language=='french' or language=='italian' or language=='spanish' or language=='polish' then
    chosen=require('code/locales/'..language)
    for i,direction in ipairs({'up','down','left','right'}) do
      chosen['camera.pan.'..direction]=chosen.pan..chosen.directions[i]
      chosen['target.'..direction]=chosen.target..chosen.directions[i]
      chosen['target.fine.'..direction]=chosen.fine..chosen.directions[i]
    end
  end
  local controls,buildings,cache={},{},{}
  for _,control in ipairs(require('code/controls')) do controls[control.id]=control end
  for _,building in ipairs(require('code/building_actions')) do
    for _,verb in ipairs({'menu.focus.','menu.open.','camera.return.'}) do
      buildings[verb..building.name]={text=building.text,verb=verb,name=building.name}
    end
  end
  return function(key)
    if cache[key] then return cache[key] end
    local control=controls[key]
    local building=buildings[key]
    if building and not chosen[key] then
      local label=nativeText and nativeText(8,building.text)
      label=label or building.name:gsub('-',' ')
      local prefix=building.verb=='menu.focus.' and chosen.focusOpen
        or (building.verb=='camera.return.' and chosen.returnFrom or chosen.open)
      cache[key]=prefix..label
    elseif control then
      local label=nativeText and nativeText(control.textGroup,control.text)
      label=label or key:match('([^.]+)$'):gsub('-',' ')
      local prefix=control.verb=='open' and chosen.open or chosen.choose
      cache[key]=prefix..label
    else cache[key]=chosen[key] or en[key] or key end
    return cache[key]
  end
end
return M
