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
  add('view.rotate-left',45,mods)
  add('view.rotate-right',46,mods)
  add('view.toggle-zoom',44,mods)
  -- Lowering has an independently owned native hold/release path. Until its
  -- replacement is implemented, preserve it and forbid assigning over it.
  entries[#entries+1]={action='view.lower-buildings',unavailable=true,
    contexts={'game.build','game.status'},states={'live-sp'},
    binding={scan=47,extended=false,mods=mods}}
  for direction,scan in pairs({up=72,down=80,left=75,right=77}) do
    -- Arrow input remains a familiar native alternative unless assigned to
    -- another action. A collision still requires an assigned pan replacement.
    if mods==0 or mods==2 then add('camera.pan.'..direction,scan,mods,true,true)
    elseif direction=='down' then
      entries[#entries+1]={action='view.lower-buildings',unavailable=true,
        contexts={'game.build','game.status'},states={'live-sp'},
        binding={scan=scan,extended=true,mods=mods}}
    else
      local action=direction=='up' and 'view.toggle-zoom' or 'view.rotate-'..direction
      add(action,scan,mods,true,true)
    end
  end
end
return entries
