-- Native integration catalog grows here before the first public profile schema
-- is released. These are implemented actions, never synthetic fixture commands.
local parents={'menu.main','menu.custom-scenarios','menu.campaigns','menu.missions'}
local all={'menu.main','menu.custom-scenarios','menu.campaigns','menu.missions','game.build','game.status'}
local world={'game.build','game.status'}
local entries={{id='hotkeys.open',contexts=all,
  states={'menu','live-sp'},command=false,default={scan=88,extended=false,mods=0}},
  {id='menu.next',contexts=all,states={'menu','live-sp'},command=false,
    default={scan=15,extended=false,mods=0}},
  {id='menu.previous',contexts=all,states={'menu','live-sp'},command=false,
    default={scan=15,extended=false,mods=2}},
  {id='menu.activate',contexts=parents,states={'menu'},command=false,
    default={scan=28,extended=false,mods=0}},
  {id='game.menu.activate',contexts=world,states={'live-sp'},command=true,
    default={scan=28,extended=false,mods=0}}}
for _,id in ipairs({'target.up','target.down','target.left','target.right',
    'target.fine.up','target.fine.down','target.fine.left','target.fine.right','target.center',
    'target.confirm','target.cancel'}) do
  entries[#entries+1]={id=id,contexts=world,states={'live-sp'},
    command=id=='target.confirm',default=false}
end
return entries
