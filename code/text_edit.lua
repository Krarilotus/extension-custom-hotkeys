-- UTF-8 draft text with byte-boundary-safe caret and selection operations.
local M={}
M.__index=M
local function characters(text)
  local result,i={},1
  while i<=#text do
    local b=text:byte(i)
    local length=b<128 and 1 or (b>=194 and b<=223 and 2)
      or (b>=224 and b<=239 and 3) or (b>=240 and b<=244 and 4)
    if not length or i+length-1>#text or b<32 or b==127 then return nil end
    for j=i+1,i+length-1 do local c=text:byte(j);if c<128 or c>191 then return nil end end
    local second=text:byte(i+1)
    if (b==224 and second<160) or (b==237 and second>=160)
        or (b==240 and second<144) or (b==244 and second>=144) then return nil end
    result[#result+1]=text:sub(i,i+length-1);i=i+length
  end
  return result
end
function M.valid(value) return type(value)=='string' and characters(value)~=nil end
function M.new(value,limit)
  return setmetatable({chars=assert(characters(value)),caret=0,anchor=0,limit=limit or 120},M)
end
function M:value() return table.concat(self.chars) end
function M:move(position,select)
  self.caret=math.max(0,math.min(#self.chars,position))
  if not select then self.anchor=self.caret end
end
function M:selectAll() self.anchor=0;self.caret=#self.chars end
function M:insert(text)
  local incoming=characters(text)
  if not incoming then return nil,'editor.text' end
  local first,last=math.min(self.caret,self.anchor),math.max(self.caret,self.anchor)
  local result={}
  for i=1,first do result[#result+1]=self.chars[i] end
  for _,char in ipairs(incoming) do result[#result+1]=char end
  for i=last+1,#self.chars do result[#result+1]=self.chars[i] end
  if #table.concat(result)>self.limit then return nil,'editor.text-size' end
  self.chars=result;self:move(first+#incoming);return true
end
function M:delete(backward)
  if self.caret==self.anchor then
    self.anchor=math.max(0,math.min(#self.chars,self.caret+(backward and -1 or 1)))
  end
  return self:insert('')
end
return M
