--[[
       ___                  
      |_  |                 
        | | ___  ___  _ __  
        | |/ __|/ _ \| '_ \ 
    /\__/ /\__ \ (_) | | | |
    \____/ |___/\___/|_| |_|
]]

------------------------------------------------------------------ utils
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}

local function isArray(t)
	local max = 0
	for k,v in pairs(t) do
		if type(k) ~= "number" then
			return false
		elseif k > max then
			max = k
		end
	end
	return max == #t
end

local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
local function removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end

------------------------------------------------------------------ encoding

local function encodeCommon(val, pretty, tabLevel, tTracking)
	local str = ""

	-- Tabbing util
	local function tab(s)
		str = str .. ("\t"):rep(tabLevel) .. s
	end

	local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
		str = str .. bracket
		if pretty then
			str = str .. "\n"
			tabLevel = tabLevel + 1
		end
		for k,v in iterator(val) do
			tab("")
			loopFunc(k,v)
			str = str .. ","
			if pretty then str = str .. "\n" end
		end
		if pretty then
			tabLevel = tabLevel - 1
		end
		if str:sub(-2) == ",\n" then
			str = str:sub(1, -3) .. "\n"
		elseif str:sub(-1) == "," then
			str = str:sub(1, -2)
		end
		tab(closeBracket)
	end

	-- Table encoding
	if type(val) == "table" then
		assert(not tTracking[val], "Cannot encode a table holding itself recursively")
		tTracking[val] = true
		if isArray(val) then
			arrEncoding(val, "[", "]", ipairs, function(k,v)
				str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		else
			arrEncoding(val, "{", "}", pairs, function(k,v)
				assert(type(k) == "string", "JSON object keys must be strings", 2)
				str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
				str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		end
	-- String encoding
	elseif type(val) == "string" then
		str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
	-- Number encoding
	elseif type(val) == "number" or type(val) == "boolean" then
		str = tostring(val)
	else
		error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
	end
	return str
end

local function encode(val)
	return encodeCommon(val, false, 0, {})
end

local function encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

------------------------------------------------------------------ decoding

local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end

local function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

local function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
local function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

local function parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1,1) ~= "\"" do
		local next = str:sub(1,1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")

		if next == "\\" then
			local escape = str:sub(1,1)
			str = str:sub(2)

			next = assert(decodeControls[next..escape], "Invalid escape character")
		end

		s = s .. next
	end
	return s, removeWhite(str:sub(2))
end

local function parseArray(str)
	str = removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = parseValue(str)
		val[i] = v
		i = i + 1
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

local function parseObject(str)
	str = removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = parseMember(str)
		val[k] = v
		str = removeWhite(str)
	end
	str = removeWhite(str:sub(2))
	return val, str
end

function parseMember(str)
	local k = nil
	k, str = parseValue(str)
	local val = nil
	val, str = parseValue(str)
	return k, val, str
end

function parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return parseObject(str)
	elseif fchar == "[" then
		return parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return parseBoolean(str)
	elseif fchar == "\"" then
		return parseString(str)
	elseif str:sub(1, 4) == "null" then
		return parseNull(str)
	end
	return nil
end

local function decode(str)
	str = removeWhite(str)
	t = parseValue(str)
	return t
end

local function decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = decode(file.readAll())
	file.close()
	return decoded
end

--[[
      __                  _   _                 
     / _|                | | (_)                
    | |_ _   _ _ __   ___| |_ _  ___  _ __  ___ 
    |  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    | | | |_| | | | | (__| |_| | (_) | | | \__ \
    |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
]]

local function split(string, delimiter)
    local result = { }
    local from = 1
    local delim_from, delim_to = string.find( string, delimiter, from )
    while delim_from do
        table.insert( result, string.sub( string, from , delim_from-1 ) )
        from = delim_to + 1
        delim_from, delim_to = string.find( string, delimiter, from )
    end
    table.insert( result, string.sub( string, from ) )
    return result
end

local function dowload(url, path)
    response = http.get(url)
    response = response.readAll()
    file = fs.open(path, "w")
    file.write(response)
    file.close()
end

local function question(question)
    if question == nil then else
        if term.isColor() then
            term.setTextColour(colors.orange)
        end
        term.write(question.."? [")
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

-- Vars
local pack_path = "/etc/pack"
local sources_list_path = pack_path.."/sources.list"
local sources_list_d_path = pack_path.."/sources.list.d"
local install_path = pack_path.."/packages"

-- sources
local function load_sources()
    local sources_file = io.open(sources_list_path, "r")
    
    local line = sources_file:read()
    local sources = {}
    
    while line do
        table.insert(sources, split(line, " "))
        line = sources_file:read()
    end

    return sources
end

local function fetch_sources()
	local sources = load_sources()
	print("Fetching")
	for _,source in pairs(sources) do
		print(source[1])
		dowload(source[2], sources_list_d_path.."/"..source[1])
	end
end

-- packages
local function load_packages()
	packages = {}
    for _,p in pairs(fs.list(sources_list_d_path)) do
		_f = fs.open(sources_list_d_path.."/"..p,"r")
		packages[p] = decode(_f.readAll())
		_f.close()
	end
    return packages
end

--[[
local function get_packag(source, package)
    packages = load_packages()
	return packages[source][package]
end
]]

local function install_packag(name, packag)
    for k,v in pairs(packag["files"]) do
        dowload(v, install_path.."/"..name.."/"..k)
    end
end

local function is_packag_installed(name)
	return fs.exists(install_path.."/"..name)
end

local function remove_packag(name)
	fs.delete(install_path.."/"..name)
end

if not fs.exists(sources_list_path) then
    _f = fs.open(sources_list_path, "w")
	_f.write("pack https://raw.githubusercontent.com/Commandcracker/CC-pack/master/packages.json")
	_f.close()
	fetch_sources()
end

--[[
     _____  _     _____ 
    /  __ \| |   |_   _|
    | /  \/| |     | |  
    | |    | |     | |  
    | \__/\| |_____| |_ 
     \____/\_____/\___/ 
]]

local function _list()
    for source,Package in pairs(load_packages()) do
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

    for source,Package in pairs(load_packages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				print("Package:", name)
				print("Url:", p["url"])
				print("Installed:", is_packag_installed(source.."/"..name))
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

	for source,Package in pairs(load_packages()) do
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

    for source,Package in pairs(load_packages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				if is_packag_installed(source.."/"..name) then
					printError("Package already installed")
					return
				end
				if question("install "..source.."/"..name) then
					install_packag(source.."/"..name, p)
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

	for source,Package in pairs(load_packages()) do
		for name,p in pairs(Package) do
			if name == args[2] then
				if not is_packag_installed(source.."/"..name) then
					printError("Package not installed")
					return
				end
				if question("remove "..source.."/"..name) then
					remove_packag(source.."/"..name)
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

	if not http.checkURL(args[3]) then
		printError("Bad url")
		return
	end

	local _f = fs.open(sources_list_path, "a")
	_f.write("\n"..args[2].." "..args[3])
	_f.close()

	print("Added:", args[2], args[3])
	fetch_sources()
end

local commands = {
    {"install", "install packages", _install},
    {"show", "show package details", _show},
    {"search", "search in package descriptions", _search},
    {"remove", "remove packages", _remove},
    {"list", "list packages based on package names", _list},
	{"fetch", "updats the sources", fetch_sources},
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
