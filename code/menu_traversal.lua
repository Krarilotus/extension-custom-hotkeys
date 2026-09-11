-- Read-only interaction-pass traversal of SHC 1.41 Menu::handleMenuItems.
-- Produces candidates for native hit testing, never invokes raw callbacks.
local M={}
local function has(value,flag) return math.floor(value/flag)%2==1 end
local function integer(value) return type(value)=='number' and value==math.floor(value) end

function M.active(read,count,state)
  if not integer(count) or count<1 or count>4096 or type(state)~='table'
      or not integer(state.tab) or not integer(state.subtab)
      or not integer(state.modal) or not integer(state.sliding) then
    return nil,'menu.state'
  end
  local function row(index)
    if index<1 or index>count then error('menu.bounds') end
    local r=read(index)
    if type(r)~='table' or not integer(r.type) or r.type<0 or r.type>4294967295
        or not integer(r.parameter) or not integer(r.skip) or r.skip<0
        or not integer(r.condition) then error('menu.row') end
    return r
  end
  local ok,result=pcall(function()
    if row(count).type~=0x66 then error('menu.sentinel') end
    local out,index={},1
    while index<=count do
      local item=row(index)
      local t=item.type
      if t==0x66 or t==0x67 then return out end
      if t==0x64 then
        if item.parameter~=state.tab then index=index+item.skip end
      elseif t==0x65 then
        if item.parameter==state.tab then return out end
      elseif t==8 then
        if state.sliding~=0 then return out end
      elseif t==9 then
        if state.modal~=-1 then return out end
      elseif t==0x21000000 then
        local nextIndex=index+item.skip+1
        local nextRow=row(nextIndex)
        while nextRow.type==0x11000000 and nextRow.condition~=state.subtab do
          nextIndex=nextIndex+nextRow.skip+1
          nextRow=row(nextIndex)
        end
        if nextRow.type==0x11000000 then index=nextIndex end
      elseif t==0x11000000 then
        index=index+item.skip
      elseif t~=7 and t~=0x1000000 and not has(t,0x4000000) then
        if has(t,0x8000000) then
          local alternative=index+1
          local alternate=row(alternative)
          while has(alternate.type,0x4000000) do
            if alternate.condition==state.subtab then index=alternative;item=alternate;break end
            alternative=alternative+1;alternate=row(alternative)
          end
        end
        -- Native input pass skips signed items; only rectangle interaction
        -- kinds become focus candidates. Zero/one are automatic callbacks.
        local base=item.type%0x800000
        if item.type<0x80000000 and base>=2 and base<=6
            and item.disabled==0 and item.inactive==0 then
          out[#out+1]=index
        end
      end
      index=index+1
    end
    error('menu.sentinel')
  end)
  if not ok then return nil,result end
  return result
end
return M
