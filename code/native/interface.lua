local M = {}

-- Host UCP Lua state only. Resolve the documented owner exports through UCP's
-- library service; do not load another DLL through the Windows loader or call
-- luaopen again. The returned handle must remain pinned by the module owner.
function M.open(core)
  local library, err=core.openLibraryHandle('ucp/modules/winProcHandler/winProcHandler.dll')
  assert(library,err or 'chain.library-unavailable')
  local interface={RegisterProc=library:getProcAddress('_RegisterProc@8'),
    CallNextProc=library:getProcAddress('_CallNextProc@20')}
  for _,address in pairs(interface) do
    assert(type(address)=='number' and address>0 and address<4294967296
      and address==math.floor(address), 'chain.export-unavailable')
  end
  assert(interface.RegisterProc and interface.CallNextProc, 'chain.export-unavailable')
  return interface,library
end

return M
