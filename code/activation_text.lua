local messages={
 english={
  ['activation.legacy-hotkeys']='Disable UCP2-Legacy hotkeys (o_keys), then restart the game to use Custom Hotkeys.',
  ['activation.recorder-api']='Custom Hotkeys requires the Recorder input lifecycle API before these extensions can be enabled together.',
  ['activation.config-unavailable']='Custom Hotkeys could not verify the active configuration. Correct the launch configuration and restart.',
  restart='Changing Custom Hotkeys activation requires a clean game restart.'},
 german={
  ['activation.legacy-hotkeys']='UCP2-Legacy-Tastenkürzel (o_keys) deaktivieren und das Spiel für Custom Hotkeys neu starten.',
  ['activation.recorder-api']='Custom Hotkeys benötigt zuerst die Eingabe-Lebenszyklus-API des Recorders, um beide Erweiterungen gemeinsam zu aktivieren.',
  ['activation.config-unavailable']='Custom Hotkeys konnte die aktive Konfiguration nicht prüfen. Startkonfiguration korrigieren und neu starten.',
  restart='Eine Änderung der Aktivierung von Custom Hotkeys erfordert einen Spielneustart.'},
 french={
  ['activation.legacy-hotkeys']='Désactivez les raccourcis UCP2-Legacy (o_keys), puis redémarrez le jeu pour utiliser Custom Hotkeys.',
  ['activation.recorder-api']="Custom Hotkeys nécessite l'API du cycle de vie des entrées de Recorder avant de pouvoir activer les deux extensions.",
  ['activation.config-unavailable']='Custom Hotkeys ne peut pas vérifier la configuration active. Corrigez la configuration et redémarrez.',
  restart="Modifier l'activation de Custom Hotkeys nécessite un redémarrage du jeu."},
 italian={
  ['activation.legacy-hotkeys']='Disattiva i tasti UCP2-Legacy (o_keys), poi riavvia il gioco per usare Custom Hotkeys.',
  ['activation.recorder-api']="Custom Hotkeys richiede l'API del ciclo di vita degli input di Recorder per attivare insieme le due estensioni.",
  ['activation.config-unavailable']='Custom Hotkeys non può verificare la configurazione attiva. Correggi la configurazione e riavvia.',
  restart="La modifica dell'attivazione di Custom Hotkeys richiede un riavvio del gioco."},
 spanish={
  ['activation.legacy-hotkeys']='Desactiva las teclas UCP2-Legacy (o_keys) y reinicia el juego para usar Custom Hotkeys.',
  ['activation.recorder-api']='Custom Hotkeys necesita la API del ciclo de entrada de Recorder antes de activar ambas extensiones.',
  ['activation.config-unavailable']='Custom Hotkeys no puede verificar la configuración activa. Corrige la configuración y reinicia.',
  restart='Cambiar la activación de Custom Hotkeys requiere reiniciar el juego.'},
 polish={
  ['activation.legacy-hotkeys']='Wyłącz skróty UCP2-Legacy (o_keys), a następnie uruchom grę ponownie, aby użyć Custom Hotkeys.',
  ['activation.recorder-api']='Custom Hotkeys wymaga API cyklu wejścia modułu Recorder przed wspólnym włączeniem obu rozszerzeń.',
  ['activation.config-unavailable']='Custom Hotkeys nie może sprawdzić aktywnej konfiguracji. Popraw konfigurację i uruchom grę ponownie.',
  restart='Zmiana aktywacji Custom Hotkeys wymaga ponownego uruchomienia gry.'},
}
local M={}
function M.new(language)
  local chosen=messages[type(language)=='string' and language:lower() or 'english'] or messages.english
  return function(key) return chosen[key] or messages.english[key] or key end
end
return M
