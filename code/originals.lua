-- Audited reference keyboard branches. Remaining native shortcuts must be
-- inventoried before distributing the complete catalog/profile schema.
local entries={}
local function add(action,scan,mods,extended,retain)
  entries[#entries+1]={action=action,binding={scan=scan,extended=extended or false,mods=mods},retain=retain}
end
for _,building in ipairs(require('code/building_actions')) do
  if building.scan then
    add('menu.focus.'..building.name,building.scan,0)
    add('menu.open.'..building.name,building.scan,1)
    add('camera.return.'..building.name,building.scan,2)
    add('camera.return.'..building.name,building.scan,3)
  end
end
for mods=0,3 do
  add('view.toggle-interface',15,mods)
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
