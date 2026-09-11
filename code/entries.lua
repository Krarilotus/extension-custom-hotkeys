-- Native integration catalog grows here before the first public profile schema
-- is released. These are implemented actions, never synthetic fixture commands.
local parents={'menu.main','menu.custom-scenarios','menu.campaigns','menu.missions'}
return {{id='hotkeys.open',contexts=parents,
  states={'menu'},command=false,default={scan=88,extended=false,mods=0}},
  {id='menu.next',contexts=parents,states={'menu'},command=false,
    default={scan=15,extended=false,mods=0}},
  {id='menu.previous',contexts=parents,states={'menu'},command=false,
    default={scan=15,extended=false,mods=2}},
  {id='menu.activate',contexts=parents,states={'menu'},command=false,
    default={scan=28,extended=false,mods=0}}}
