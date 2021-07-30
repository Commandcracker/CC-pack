--[[
      __                  _   _                 
     / _|                | | (_)                
    | |_ _   _ _ __   ___| |_ _  ___  _ __  ___ 
    |  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    | | | |_| | | | | (__| |_| | (_) | | | \__ \
    |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
]]

local function question(_question)
    if _question == nil then else
        if term.isColor() then
            term.setTextColour(colors.orange)
        end
        term.write(_question.."? [")
        if term.isColor() then
            term.setTextColour(colors.lime)
        end
        term.write('Y')
        if term.isColor() then
            term.setTextColour(colors.orange)
        end
        term.write('/')
        if term.isColor() then
            term.setTextColour(colors.red)
        end
        term.write('n')
        if term.isColor() then
            term.setTextColour(colors.orange)
        end
        term.write("] ")
        term.setTextColour(colors.white)
    end
    local input = string.lower(string.sub(read(),1,1))
    if input == 'y' or input == 'j' or input == '' then
        return true
    else 
        return false
    end
end

--[[
     _____  _     _____ 
    /  __ \| |   |_   _|
    | /  \/| |     | |  
    | |    | |     | |  
    | \__/\| |_____| |_ 
     \____/\_____/\___/ 
]]

local pack = nil or pack

if not pack then
	pack = dofile("/"..fs.getDir(shell.getRunningProgram()).."/../".."lib/pack")
end

pack.fixSources(true)

local function _list()
    for source,Package in pairs(pack.getPackages()) do
		for name,_ in pairs(Package) do
			print(source.."/"..name)
		end
    end
end

local function _show(args)
    if not args[2] then
        printError("Usage: show <package>")
        return
    end

    for source,Package in pairs(pack.getPackages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				print("Package:", name)
				print("Url:", p["url"])
				print("Installed:", pack.isPackageInstalled(source.."/"..name))
				return
			end
		end
    end

    printError("Package not found")
end

local function _search(args)
    if not args[2] then
        printError("Usage: search <package>")
        return
    end
    local sucsess = false

	for source,Package in pairs(pack.getPackages()) do
		for name,_ in pairs(Package) do
			if string.match(name, args[2]) then
				print(source.."/"..name)
				sucsess = true
			end
		end
    end
    if not sucsess then
        printError("No matching packages found")
    end
end

local function _install(args)
    if not args[2] then
        printError("Usage: install <package>")
        return
    end

    for source,Package in pairs(pack.getPackages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				if pack.isPackageInstalled(source.."/"..name) then
					printError("Package already installed")
					return
				end
				if question("install "..source.."/"..name) then
					pack.installPackage(source.."/"..name, p, shell)
				end
				return
			end
		end
    end

    printError("Package not found")
end

local function _remove(args)
	if not args[2] then
		printError("Usage: remove <package>")
		return
	end

	for source,Package in pairs(pack.getPackages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				if not pack.isPackageInstalled(source.."/"..name) then
					printError("Package not installed")
					return
				end
				if question("remove "..source.."/"..name) then
					pack.removePackage(source.."/"..name)
				end
				return
			end
		end
	end

	printError("Package not found")
end

local function _add_source(args)
	if not args[3] then
		printError("Usage: add-source <name> <url>")
		return
	end

    pack.addSource(args[2], args[3], true)
end

local function _fetch_sources()
	pack.fetchSources(true)
end

local commands = {
    {"install", "install packages", _install},
    {"show", "show package details", _show},
    {"search", "search in package descriptions", _search},
    {"remove", "remove packages", _remove},
    {"list", "list packages based on package names", _list},
	{"fetch", "updats the sources", _fetch_sources},
	{"add-source", "add asorce to the sources file", _add_source}
}

local function _list_commands()
    print("commands:")
    for _,command in pairs(commands) do
        print("  "..command[1].." - "..command[2])
    end
end

local args = {...}

if #args <= 0 then
    print("Usage: pack <command>")
    _list_commands()
    return
end

for _,command in pairs(commands) do
    if args[1] == command[1] then
        command[3](args)
        return
    end
end

printError("Command not found!")
_list_commands()
