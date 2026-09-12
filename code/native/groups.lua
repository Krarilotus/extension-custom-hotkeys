local A=require('code/addresses')
local ffi=require('ffi')
local M={}
local function i(address) return tonumber(ffi.cast('int32_t *',address)[0]) end
local function s(address) return tonumber(ffi.cast('int16_t *',address)[0]) end
local function b(address) return tonumber(ffi.cast('uint8_t *',address)[0]) end
local function write(address,value) ffi.cast('int32_t *',address)[0]=value end
local units=ffi.cast('void *',A.units)
local matches=ffi.cast('int (__thiscall *)(void *,int)',A.selectionMatchesGroup)
local escape=ffi.cast('void (__thiscall *)(void *)',A.submitDeselect)
local select=ffi.cast('void (__thiscall *)(void *,int)',A.selectGroup)
local screen=ffi.cast('void (__thiscall *)(void *,int,int)',A.changeScreen)

function M.inspect(group,player)
  if type(group)~='number' or group~=math.floor(group) or group<0 or group>9 then return nil end
  local count=i(A.units)
  if count<1 or count>A.unitCapacity then return nil end
  local first
  -- Native selection reads the full group capacity, including holes. Validate every
  -- index before allowing it to dereference that table; never stop at a hole.
  for index=0,(A.unitCapacity-1) do
    local address=A.controlGroups+group*A.groupStride+index*8
    local id=i(address)
    if id~=-1 then
      if id<1 or id>(A.unitCapacity-1) then return nil end
      local offset=id*0x490
      if i(address+4)==i(A.unitSerial+offset) then
        if s(A.unitOwner+offset)~=player then return nil end
        if not first and s(A.unitState+offset)==2 and s(A.unitExcluded1+offset)==0
            and s(A.unitExcluded3+offset)==0 and b(A.unitExcluded2+offset)==0 then
          local tile=i(A.unitTile+offset)
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
  if i(A.selectedCount)<=0 then return end
  -- Original local selection-panel transition after native submission.
  local tab=i(A.lastBuildTab)
  if tab~=61 then write(A.previousBuildTab,tab) end
  write(A.lastBuildTab,61)
  screen(ffi.cast('void *',A.gameCore),14,0)
  write(A.ownedSelection,1);write(A.unitModeAux,1);write(A.unitMode,1)
  write(A.selectionReset,0);write(A.refreshSurface,1)
end
return M
