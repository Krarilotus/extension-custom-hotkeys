-- Presets are local binding data. All dispatch still uses the shared catalog,
-- context resolver and native action owners. Never mutate a stored user profile.
local Catalog=require('code/catalog')
local M={}
local function key(scan,mods,extended)
  return {scan=scan,mods=mods or 0,extended=extended or false}
end
function M.attach(catalog)
  local modern=Catalog.defaults(catalog)
  modern['pointer.primary']=false;modern['pointer.secondary']=false
  modern['pointer.select']={button='left',mods=0}
  modern['pointer.order']={button='right',mods=0}
  modern['pointer.select-add']={button='left',mods=2}
  modern['pointer.order-queued']={button='right',mods=2}
  local classic=Catalog.defaults(catalog)
  for direction,scan in pairs({up=72,left=75,down=80,right=77}) do
    classic['camera.pan.'..direction]=key(scan,0,true)
  end
  classic['menu.focus.armory']=key(30)
  classic['camera.cycle.signposts']=key(31)
  classic['unit.stance.defensive']=key(17)
  classic['view.toggle-interface']=key(15)
  classic['menu.next']=key(81,1,true)
  classic['menu.previous']=key(73,1,true)
  local grid=Catalog.defaults(catalog)
  for _,bindings in ipairs({classic,modern,grid}) do
    for direction,scan in pairs({up=72,left=75,down=80,right=77}) do
      bindings['target.'..direction]=key(scan)
      bindings['target.fine.'..direction]=key(scan,2)
    end
    bindings['target.center']=key(76)
    bindings['target.confirm']=key(28,0,true)
    bindings['target.cancel']=key(83)
  end
  for direction,scan in pairs({up=72,left=75,down=80,right=77}) do
    grid['camera.pan.'..direction]=key(scan,0,true)
  end
  -- Six physical top-row positions: QWERTY on US, QWERTZ on German.
  for i,name in ipairs({'castle','industry','farms','town','weapons','food'}) do
    grid['menu.build.'..name]=key(15+i)
  end
  for i,scan in ipairs({30,31,32,33,34,35,44,45,46,47,48,49}) do
    grid['grid.slot.'..i]=key(scan)
  end
  for id,scan in pairs({['unit.stance.stand-ground']=16,['unit.stance.defensive']=17,
      ['unit.stance.aggressive']=18,['menu.focus.granary']=34,['menu.focus.keep']=35,
      ['view.toggle-zoom']=44,['view.rotate-left']=45,['view.rotate-right']=46,
      ['view.lower-buildings']=47,['menu.focus.barracks']=48,
      ['menu.focus.mercenary-post']=49,['menu.focus.tunnelers-guild']=20}) do
    grid[id]=key(scan,4)
  end
  local definitions={
    {id='game-default',name='Game Default',bindings=classic},
    {id='modern-rts',name='Modern RTS',bindings=modern},
    {id='grid',name='Grid',bindings=grid},
  }
  catalog.presets={}
  for _,preset in ipairs(definitions) do
    preset.bindings=assert(Catalog.validate(catalog,preset.bindings))
    catalog.presets[preset.id]=preset
  end
  catalog.presetOrder=definitions
  return catalog
end
return M
