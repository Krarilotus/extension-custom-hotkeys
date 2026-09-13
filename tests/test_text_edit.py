def test_utf8_selection_and_deletion_keep_complete_characters(lua):
    lua.execute('''
      local T=require('code/text_edit')
      local text=T.new('Aä€')
      text:move(3);text:delete(true);assert(text:value()=='Aä')
      text:move(1);text:delete(false);assert(text:value()=='A')
      text:selectAll();assert(text:insert('Ö'));assert(text:value()=='Ö')
      assert(text.caret==1 and text.anchor==1)
    ''')


def test_text_limit_and_invalid_unicode_preserve_previous_draft(lua):
    lua.execute('''
      local T=require('code/text_edit')
      local text=T.new('ä',3);text:move(1)
      assert(not text:insert('ö'));assert(text:value()=='ä')
      assert(not text:insert(string.char(237,160,128)))
      assert(not text:insert(string.char(192,128)))
      assert(not text:insert(string.char(0)))
      assert(text:value()=='ä')
      assert(text:insert('a'));assert(text:value()=='äa')
    ''')
