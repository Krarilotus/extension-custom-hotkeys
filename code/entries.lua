-- Native integration catalog grows here before the first public profile schema
-- is released. These are implemented actions, never synthetic fixture commands.
return {{id='hotkeys.open',label='hotkeys.open',
  contexts={'menu.main','menu.custom-scenarios','menu.campaigns','menu.missions'},
  states={'menu'},command=false,default={scan=88,extended=false,mods=0}}}
