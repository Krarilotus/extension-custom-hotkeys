-- One checked insertion before the original local input update. This uses the
-- existing UCP patch API; no second Windows hook or simulation/recorder hook.
local M={}
local installed
function M.install(core,callback)
  assert(not installed,'input-frame.installed')
  assert(type(callback)=='number' and callback>0 and callback<4294967296
    and callback==math.floor(callback),'input-frame.callback')
  local original={0x83,0xec,0x08,0x53,0x55}
  local current=core.readBytes(0x468100,5)
  for i,byte in ipairs(original) do assert(current[i]==byte,'input-frame.site-owned') end
  local address={}
  for i=1,4 do address[i]=math.floor(callback/256^(i-1))%256 end
  -- Preserve flags/registers, pass the actual native this pointer to a cdecl
  -- callback, restore, and execute every displaced original instruction once.
  installed=core.insertCode(0x468100,5,{0x9c,0x60,0xfc,0x51,0xb8,address,
    0xff,0xd0,0x83,0xc4,0x04,0x61,0x9d},nil,'after')
  return installed
end
return M
