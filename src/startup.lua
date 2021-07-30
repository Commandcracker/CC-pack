local pack_path = "/etc/pack/packages/pack/"
local pack_src_path = pack_path.."pack-src/lib/pack"
local pack_min_path = pack_path.."pack/lib/pack"

if fs.exists(pack_src_path) then
    dofile(pack_src_path).loadPackages(shell)
elseif fs.exists(pack_min_path) then
    dofile(pack_min_path).loadPackages(shell)
end