-- Audited reference keyboard branches. Remaining native shortcuts must be
-- inventoried before distributing the complete catalog/profile schema.
local entries={}
local function add(action,scan,mods,extended,retain)
  entries[#entries+1]={action=action,binding={scan=scan,extended=extended or false,mods=mods},retain=retain}
end
add('menu.focus.armory',30,0)
add('menu.open.armory',30,1)
add('camera.return.armory',30,2)
add('camera.return.armory',30,3)
for mods=0,3 do
  add('camera.cycle.signposts',31,mods)
  add('unit.stance.stand-ground',16,mods)
  add('unit.stance.defensive',17,mods)
  add('unit.stance.aggressive',18,mods)
  for direction,scan in pairs({up=72,down=80,left=75,right=77}) do
    -- Arrow input remains a familiar native alternative unless assigned to
    -- another action. A collision still requires an assigned pan replacement.
    add('camera.pan.'..direction,scan,mods,true,true)
  end
end
return entries
