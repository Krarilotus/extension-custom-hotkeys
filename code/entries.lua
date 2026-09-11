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
for _,pan in ipairs({{'up',17},{'left',30},{'down',31},{'right',32}}) do
  entries[#entries+1]={id='camera.pan.'..pan[1],contexts=world,states={'live-sp'},
    command=false,behavior='hold-local',default={scan=pan[2],extended=false,mods=0}}
end
for _,action in ipairs({{'camera.cycle.signposts',31,4},
    {'unit.stance.stand-ground',16,0},{'unit.stance.defensive',17,4},
    {'unit.stance.aggressive',18,0}}) do
  entries[#entries+1]={id=action[1],contexts=world,states={'live-sp'},command=action[1]:sub(1,5)=='unit.',
    default={scan=action[2],extended=false,mods=action[3]}}
end
for _,building in ipairs(require('code/building_actions')) do
  for _,verb in ipairs(building.bookmark and {'menu.focus.','menu.open.','camera.return.'} or {'menu.open.'}) do
    local mods=verb=='menu.focus.' and (building.focusMods or 0) or (verb=='menu.open.' and 1 or 2)
    entries[#entries+1]={id=verb..building.name,contexts=world,states={'live-sp'},command=false,
      default=building.scan and {scan=building.scan,extended=false,mods=mods} or false}
  end
end
for _,control in ipairs(require('code/controls')) do
  entries[#entries+1]={id=control.id,contexts={'game.build'},states={'live-sp'},
    command=true,default=false}
end
return entries
