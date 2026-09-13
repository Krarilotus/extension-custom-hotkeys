-- Host preparation fills this table before building the catalog. The dedicated
-- native state receives one copy; no remote lookups occur in the input path.
if remote then return remote.interface.nativeAddresses() end
return {}
