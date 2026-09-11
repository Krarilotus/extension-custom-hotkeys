local ffi=require('ffi')
local M={}
local function i(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local function s(address) return tonumber(ffi.cast('int16_t *',address)[0]) end
local function b(address) return tonumber(ffi.cast('uint8_t *',address)[0]) end
local function write(address,value) ffi.cast('int32_t *',address)[0]=value end
local units=ffi.cast('void *',0x1387f38)
local matches=ffi.cast('int (__thiscall *)(void *,int)',0x5360a0)
local escape=ffi.cast('void (__thiscall *)(void *)',0x536c70)
local select=ffi.cast('void (__thiscall *)(void *,int)',0x535fd0)
local screen=ffi.cast('void (__thiscall *)(void *,int,int)',0x46b340)

function M.inspect(group,player)
  if type(group)~='number' or group~=math.floor(group) or group<0 or group>9 then return nil end
  local count=i(0x1387f38)
  if count<1 or count>2500 then return nil end
  local first
  -- Native selection reads all2500 entries, including holes. Validate every
  -- index before allowing it to dereference that table; never stop at a hole.
  for index=0,2499 do
    local address=0x112b0b8+group*0x4e20+index*8
    local id=i(address)
    if id~=-1 then
      if id<1 or id>2499 then return nil end
      local offset=id*0x490
      if i(address+4)==i(0x13885e4+offset) then
        if s(0x13885e2+offset)~=player then return nil end
        if not first and s(0x13885d8+offset)==2 and s(0x13887ec+offset)==0
            and s(0x13888a4+offset)==0 and b(0x138887a+offset)==0 then
          local tile=i(0x1388620+offset)
          if tile<0 or tile>159999 then return nil end
          first={id=id,tile=tile}
        end
      end
    end
  end
  return first
end

function M.matches(group) return matches(units,group)~=0 end
function M.recall(group)
  -- Same validated player-input submission sequence as the original number
  -- branch. Escape queues0x0F; selection creates its tribe through queue0x10.
  -- Never call the synchronized command execution/tribe mutator directly.
  escape(units);select(units,group)
  if i(0x1387f58)<=0 then return end
  -- Original local selection-panel transition after native submission.
  local tab=i(0x1fe7d34)
  if tab~=61 then write(0x1fe7d48,tab) end
  write(0x1fe7d34,61)
  screen(ffi.cast('void *',0x1fe7d10),14,0)
  write(0x1fe7bec,1);write(0x1387f4c,1);write(0x1387f48,1)
  write(0x1388490,0);write(0xb48ee4,1)
end
return M
