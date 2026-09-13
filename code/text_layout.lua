-- Fit UTF-8 at character boundaries; measure exactly the bytes the game draws.
local Text=require('code/text_edit')
local M={}
local function encodedCharacters(text,encode)
  local chars=Text.characters(text) or {'?'}
  if encode then
    for i,char in ipairs(chars) do chars[i]=encode(char) or '?' end
  end
  return chars
end
function M.fit(text,width,measure,encode)
  if width<=0 then return '' end
  local full=encode and encode(text) or (not encode and text)
  if full and measure(full)<=width then return full end
  local chars=encodedCharacters(text,encode)
  full=full or table.concat(chars)
  if measure(full)<=width then return full end
  local suffix='...'
  if measure(suffix)>width then return '' end
  local lo,hi=0,#chars
  while lo<hi do
    local mid=math.floor((lo+hi+1)/2)
    if measure(table.concat(chars,'',1,mid)..suffix)<=width then lo=mid else hi=mid-1 end
  end
  return table.concat(chars,'',1,lo)..suffix
end
function M.field(text,caret,anchor,width,measure,encode)
  local chars=encodedCharacters(text,encode)
  local function slice(first,last) return table.concat(chars,'',first+1,last) end
  caret=math.max(0,math.min(#chars,caret))
  anchor=math.max(0,math.min(#chars,anchor))
  local available=math.max(0,width-measure('|'))
  local first=0
  while first<caret and measure(slice(first,caret))>available do first=first+1 end
  local last=first
  while last<#chars and measure(slice(first,last+1))<=available do last=last+1 end
  local start=math.max(first,math.min(caret,anchor))
  local finish=math.min(last,math.max(caret,anchor))
  return {text=slice(first,last),first=first,last=last,
    caret=measure(slice(first,caret)),
    selectionStart=measure(slice(first,start)),
    selectionEnd=finish>start and measure(slice(first,finish)) or nil}
end
return M
