def test_control_catalog_has_unique_semantics_and_no_authoring_or_raw_dispatch(lua):
    lua.execute('''
      local seen={}
      local catalog=Catalog.new(require('code/entries'),require('code/originals'))
      assert(Catalog.validate(catalog,Catalog.defaults(catalog)))
      for _,control in ipairs(require('code/controls')) do
        assert(not seen[control.id]);seen[control.id]=true
        assert(control.action==0x444410 or control.action==0x444b80)
        assert(control.textGroup==8 and control.text>0 and control.help>0)
        local action=catalog.actions[control.id]
        assert(action.command and action.behavior=='press' and not action.default)
        local active=facts('game.build');active.panel=(control.panels and control.panels[1] or '10')..':0'
        assert(Context.allows(action,Context.resolve(active)))
        if action.panels then active.panel='999:0';assert(not Context.allows(action,Context.resolve(active))) end
        assert(not Context.allows(action,Context.resolve(facts('game.status'))))
        assert(not Context.allows(action,Context.resolve(facts('game.build','replay'))))
      end
      assert(seen['menu.build.industry'] and seen['build.select.woodsman'])
      assert(seen['build.select.granary'] and seen['unit.control.catapult'])
      assert(not seen['build.select.people-archers'] and not seen['build.select.people-arab-bow'])
    ''')


def test_control_labels_use_cached_native_game_language_text(lua):
    lua.execute('''
      local count=0
      local labels=require('code/locale').new('german',function(group,index)
        if group==6 and index==0 then return 'german' end
        count=count+1;assert(group==8 and index==42);return 'Holzfäller' end)
      assert(labels('build.select.woodsman')=='Wählen: Holzfäller')
      assert(labels('build.select.woodsman')=='Wählen: Holzfäller' and count==1)
      assert(labels('title')=='Eigene Tastenkürzel')
    ''')
