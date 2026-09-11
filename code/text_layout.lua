-- Pixel-bounded layout for the game's verified single-byte font encodings.
-- Callers convert UTF-8 first. Never split a UTF-8 or DBCS string here.
local M={}
function M.fit(text,width,measure)
  if width<=0 then return '' end
  if measure(text)<=width then return text end
  local suffix='...'
  if measure(suffix)>width then return '' end
  local lo,hi=0,#text
  while lo<hi do
    local mid=math.floor((lo+hi+1)/2)
    if measure(text:sub(1,mid)..suffix)<=width then lo=mid else hi=mid-1 end
  end
  return text:sub(1,lo)..suffix
end
function M.field(text,caret,anchor,width,measure)
  caret=math.max(0,math.min(#text,caret))
  anchor=math.max(0,math.min(#text,anchor))
  local available=math.max(0,width-measure('|'))
  local first=0
  while first<caret and measure(text:sub(first+1,caret))>available do first=first+1 end
  local last=first
  while last<#text and measure(text:sub(first+1,last+1))<=available do last=last+1 end
  local start=math.max(first,math.min(caret,anchor))
  local finish=math.min(last,math.max(caret,anchor))
  return {text=text:sub(first+1,last),first=first,last=last,
    caret=measure(text:sub(first+1,caret)),
    selectionStart=measure(text:sub(first+1,start)),
    selectionEnd=finish>start and measure(text:sub(first+1,finish)) or nil}
end
return M
