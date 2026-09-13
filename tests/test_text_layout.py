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


def test_multibyte_layout_measures_encoded_characters_and_preserves_caret(lua):
    lua.execute('''
      local Layout=require('code/text_layout')
      local Text=require('code/text_edit')
      local function encode(s)
        return (s:gsub('中','<>'):gsub('文','[]'):gsub('é','E'))
      end
      local function width(s) return #s end
      assert(Layout.fit('中文中文',7,width,encode)=='<>[]...')
      assert(Layout.fit('中文',4,width,encode)=='<>[]')
      -- The edit model counts characters, regardless of encoded byte count.
      local field=Layout.field('中é文中',3,1,6,width,encode)
      assert(field.first==0 and field.last==3 and field.text=='<>E[]')
      assert(field.caret==5 and field.selectionStart==2 and field.selectionEnd==5)
      field=Layout.field('中é文中',4,1,5,width,encode)
      assert(field.first==2 and field.last==4 and field.text=='[]<>')
      assert(field.caret==4 and field.selectionStart==0 and field.selectionEnd==4)
      for limit=0,18 do
        assert(Text.valid(Layout.fit('中文é中文',limit,width)))
      end
      assert(Layout.fit('中é',10,width,function(s)
        return not s:find('中',1,true) and encode(s) or nil
      end)=='?E')
    ''')
