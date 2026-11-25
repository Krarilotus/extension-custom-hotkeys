local A=require('code/addresses')
-- One checked insertion before the original local input update. This uses the
-- existing UCP patch API; no second Windows hook or simulation/recorder hook.
local M={}
local installed
function M.install(core,callback)
  assert(not installed,'input-frame.installed')
  assert(type(callback)=='number' and callback>0 and callback<4294967296
    and callback==math.floor(callback),'input-frame.callback')
  local current=core.readBytes(A.inputFrame,9)
  assert(current[1]==0xff and current[2]==0x15 and current[7]==0x8b
    and current[8]==0x4e and current[9]==0x14,'input-frame.site-owned')
  local address={}
  for i=1,4 do address[i]=math.floor(callback/256^(i-1))%256 end
  -- The prologue has moved this to ESI. Replay the absolute import call once.
  installed=core.insertCode(A.inputFrame,6,{0x9c,0x60,0xfc,0x56,0xb8,address,
    0xff,0xd0,0x83,0xc4,0x04,0x61,0x9d},nil,'after')
  return installed
end
return M
