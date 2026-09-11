def test_proportional_clipping_keeps_labels_inside_buttons(lua):
    lua.execute('''
      local Layout=require('code/text_layout')
      local function width(s)
        local total=0
        for i=1,#s do total=total+(s:sub(i,i)=='W' and 12 or 4) end
        return total
      end
      assert(Layout.fit('WWWWWWW',40,width)=='WW...')
      assert(Layout.fit('WW',24,width)=='WW')
      assert(Layout.fit('WWWW',8,width)=='')
      for limit=0,80 do assert(width(Layout.fit('WWW narrow label',limit,width))<=limit) end
    ''')


def test_text_field_scrolls_to_actual_caret_and_bounds_selection(lua):
    lua.execute('''
      local Layout=require('code/text_layout')
      local function width(s) return #s*5 end
      local result=Layout.field('abcdefghijklmnopqrst',18,4,40,width)
      assert(result.first==11 and result.last==18 and result.text=='lmnopqr')
      assert(result.caret==35 and result.selectionStart==0 and result.selectionEnd==35)
      result=Layout.field('abcdefghijklmnopqrst',2,18,40,width)
      assert(result.first==0 and result.caret==10 and result.selectionStart==10
        and result.selectionEnd==35)
      result=Layout.field('',0,0,40,width)
      assert(result.text=='' and result.caret==0 and not result.selectionEnd)
    ''')
