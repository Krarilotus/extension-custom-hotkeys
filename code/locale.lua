local en={title='Custom Hotkeys',profile='Profile',new='New profile',search='Search',
  groups='Group',all='All',capture='Change key',clear='Clear key',reset='Reset action',
  resetProfile='Reset profile',apply='Apply',cancel='Cancel',unbound='Unbound',
  press='Press a key or mouse button. Escape cancels.',editing='Enter accepts; Escape cancels.',
  invalid='This change is not available. Check the binding or profile name.',
  conflict='This key overlaps another action.',text='Text',default='Default',
  ['hotkeys.open']='Open hotkey settings', ['menu.next']='Next control',
  ['menu.previous']='Previous control', ['menu.activate']='Activate control',
  ['menu.back']='Back', ['editor.capture']='Change selected binding',
  ['menu.decrease']='Decrease slider', ['menu.increase']='Increase slider'}
local de={title='Eigene Tastenkürzel',profile='Profil',new='Neues Profil',search='Suche',
  groups='Gruppe',all='Alle',capture='Taste ändern',clear='Taste löschen',reset='Aktion zurücksetzen',
  resetProfile='Profil zurücksetzen',apply='Übernehmen',cancel='Abbrechen',unbound='Unbelegt',
  press='Taste oder Maustaste drücken. Escape bricht ab.',editing='Enter bestätigt; Escape bricht ab.',
  invalid='Änderung nicht möglich. Tastenkürzel oder Profilnamen prüfen.',
  conflict='Dieses Tastenkürzel überschneidet sich mit einer anderen Aktion.',text='Text',
  default='Standard', ['hotkeys.open']='Tastenkürzel öffnen', ['menu.next']='Nächstes Bedienelement',
  ['menu.previous']='Vorheriges Bedienelement', ['menu.activate']='Bedienelement aktivieren',
  ['menu.back']='Zurück', ['editor.capture']='Gewähltes Tastenkürzel ändern'}
en.profiles='Profiles';de.profiles='Profile'
de['menu.decrease']='Regler verringern';de['menu.increase']='Regler erhöhen'
en.bindings='Hotkeys';de.bindings='Tastenkürzel'
en.action='Action';de.action='Aktion'
en.binding='Key';de.binding='Taste'
en['group.navigation']='Menus'
en['group.saving']='Save / load'
en['group.selection']='Control groups'
en['group.buildings']='Building panels'
en['group.construction']='Construction'
en['group.commands']='Unit orders'
en['group.siege']='Siege engines'
en['group.targeting']='Targeting'
en['nativeKey']='%s (game)'
en['nativeAgain']='%s again (game)'
de['group.navigation']='Menüs'
de['group.saving']='Speichern / Laden'
de['group.selection']='Einheitengruppen'
de['group.buildings']='Gebäudemenüs'
de['group.construction']='Bauen'
de['group.commands']='Einheitenbefehle'
de['group.siege']='Belagerung'
de['group.targeting']='Zielen'
de['nativeKey']='%s (Spiel)'
de['nativeAgain']='%s erneut (Spiel)'
local M={}
en['mouse.left']='Left mouse';de['mouse.left']='Linke Maustaste'
en['mouse.right']='Right mouse';de['mouse.right']='Rechte Maustaste'
en['mouse.middle']='Middle mouse';de['mouse.middle']='Mittlere Maustaste'
en['mouse.x1']='Mouse button 4';de['mouse.x1']='Maustaste 4'
en['mouse.x2']='Mouse button 5';de['mouse.x2']='Maustaste 5'
en['pointer.primary']='Classic selection / order';de['pointer.primary']='Klassische Auswahl / Befehl'
en['pointer.secondary']='Classic cancel / context';de['pointer.secondary']='Klassischer Abbruch / Kontext'
en['pointer.select']='Select or confirm target';de['pointer.select']='Auswählen oder Ziel bestätigen'
en['pointer.order']='Contextual order or cancel';de['pointer.order']='Kontextbefehl oder abbrechen'
en['pointer.select-add']='Add to selection';de['pointer.select-add']='Zur Auswahl hinzufügen'
en['pointer.order-queued']='Queue contextual order';de['pointer.order-queued']='Kontextbefehl einreihen'
en.gridSlot='Panel grid slot ';de.gridSlot='Rasterplatz im Menü '
en['group.grid']='Grid';de['group.grid']='Raster'
en['preset.game-default']='Game Default';de['preset.game-default']='Spielstandard'
en['preset.modern-rts']='Modern RTS';de['preset.modern-rts']='Moderne RTS-Steuerung'
en['preset.grid']='Grid';de['preset.grid']='Raster'
en.assignGroup='Assign selection to group ';de.assignGroup='Auswahl zu Gruppe zuweisen: '
en.recallGroup='Select group ';de.recallGroup='Gruppe auswählen: '
en.focusGroup='Focus group ';de.focusGroup='Gruppe zeigen: '
en.assignBookmark='Assign camera position ';de.assignBookmark='Kameraposition speichern: '
en.recallBookmark='Go to camera position ';de.recallBookmark='Kameraposition zeigen: '
en['unit.group.next']='Select next group';de['unit.group.next']='Nächste Gruppe auswählen'
en['unit.group.previous']='Select previous group';de['unit.group.previous']='Vorherige Gruppe auswählen'
en.nativeGroup='Native group or building shortcut ';de.nativeGroup='Originales Gruppen-/Gebäudekürzel '
for group=0,9 do
  en['unit.group.native.'..group]='Native group or building shortcut '..group
  de['unit.group.native.'..group]='Originales Gruppen-/Gebäudekürzel '..group
end
en['game.save.open']='Open Save dialog';de['game.save.open']='Speicherdialog öffnen'
en['game.load.open']='Open Load dialog';de['game.load.open']='Ladedialog öffnen'
en.mainHelp1='Change keyboard shortcuts.';en.mainHelp2='Create, import and export profiles.'
de.mainHelp1='Tastenkürzel anpassen.';de.mainHelp2='Profile erstellen und austauschen.'
en['view.rotate-left']='Rotate view left';de['view.rotate-left']='Ansicht nach links drehen'
en['view.rotate-right']='Rotate view right';de['view.rotate-right']='Ansicht nach rechts drehen'
en['view.toggle-zoom']='Toggle zoom';de['view.toggle-zoom']='Zoom umschalten'
en['view.lower-buildings']='Lower buildings';de['view.lower-buildings']='Gebäude absenken'
en['camera.focus.lord']='Focus your lord';de['camera.focus.lord']='Eigenen Burgherrn zeigen'
en['camera.cycle.lords']='Cycle living lords';de['camera.cycle.lords']='Lebende Burgherren durchgehen'
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
en['game.quickload']='Quickload'
de['game.quickload']='Schnellladen'
en['game.quicksave']='Quicksave'
de['game.quicksave']='Schnellspeichern'
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
  for slot=1,12 do chosen['grid.slot.'..slot]=(chosen.gridSlot or en.gridSlot)..slot end
  for group=0,9 do
    chosen['unit.group.assign.'..group]=(chosen.assignGroup or en.assignGroup)..group
    chosen['unit.group.recall.'..group]=(chosen.recallGroup or en.recallGroup)..group
    chosen['camera.group.'..group]=(chosen.focusGroup or en.focusGroup)..group
    chosen['camera.bookmark.assign.'..group]=chosen.assignBookmark..group
    chosen['camera.bookmark.recall.'..group]=chosen.recallBookmark..group
    chosen['unit.group.native.'..group]=(chosen.nativeGroup or en.nativeGroup)..group
  end
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
