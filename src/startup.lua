local install_path = "/etc/pack/packages"

for _,source_folder_name in pairs(fs.list(install_path)) do
    for _,package_folder_name in pairs(fs.list(install_path.."/"..source_folder_name)) do
        shell.setPath(shell.path()..":"..install_path.."/"..source_folder_name.."/"..package_folder_name)
    end
end
