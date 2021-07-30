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
function removeWhite(str)
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

function encode(val)
	return encodeCommon(val, false, 0, {})
end

function encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

------------------------------------------------------------------ decoding

local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end

function parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, removeWhite(str:sub(5))
	else
		return false, removeWhite(str:sub(6))
	end
end

function parseNull(str)
	return nil, removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = removeWhite(str:sub(i))
	return val, str
end

function parseString(str)
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

function parseArray(str)
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

function parseObject(str)
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

function decode(str)
	str = removeWhite(str)
	t = parseValue(str)
	return t
end

function decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = decode(file.readAll())
	file.close()
	return decoded
end

-- Vars
pack_path = "/etc/pack"
packages_path = pack_path.."/packages"
sources_list_path = pack_path.."/sources.list"
sources_list_d_path = pack_path.."/sources.list.d"

-- functions
function split(string, delimiter)
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

function download(url, path)
    response = http.get(url)
    response = response.readAll()
    file = fs.open(path, "w")
    file.write(response)
    file.close()
end

-- Sources Stuff
function getSources()
    local sources_file = io.open(sources_list_path, "r")
    
    local line = sources_file:read()
    local sources = {}
    
    while line do
        table.insert(sources, split(line, " "))
        line = sources_file:read()
    end

    return sources
end

function fetchSources(cli)
	local sources = getSources()
    if cli then
        print("Fetching")
    end
	for _,source in pairs(sources) do
        if cli then
		    print(source[1])
        end
		download(source[2], sources_list_d_path.."/"..source[1])
	end
end

function fixSources(cli)
    local sources_list = fs.open(sources_list_path, "w")
	sources_list.write("pack https://raw.githubusercontent.com/Commandcracker/CC-pack/master/packages.json")
	sources_list.close()
	fetchSources(cli)
end

-- Package Stuff
function loadPackage(path)
    for _,file_name in pairs(fs.list(path)) do
        if file_name == "bin" or file_name == "programs" then
            for _, programm in pairs(fs.list(path.."/"..file_name)) do
                shell.setPath(shell.path()..":"..path.."/"..file_name.."/"..programm)
            end
        elseif file_name == "lib" or file_name == "apis" then
            for _, lib in pairs(fs.list(path.."/"..file_name)) do
                os.loadAPI(path.."/"..file_name.."/"..lib)
            end
        elseif file_name == "startup" or "startup.lua" then
            if fs.isDir(path.."/"..file_name) then
                for _, startup in pairs(fs.list(path.."/"..file_name)) do
                    shell.run(path.."/"..file_name.."/"..startup)
                end
            else
                shell.run(path.."/"..file_name)
            end
        end
    end
end

function loadPackages()
    for _,source_folder_name in pairs(fs.list(packages_path)) do
        for _,package_folder_name in pairs(fs.list(packages_path.."/"..source_folder_name)) do
            if source_folder_name.."/"..package_folder_name ~= "pack/pack" then
                loadPackage(packages_path.."/"..source_folder_name.."/"..package_folder_name)
            end
        end
    end
end

function installPackage(name, packag)
    for k,v in pairs(packag["files"]) do
        download(v, packages_path.."/"..name.."/"..k)
    end
end

function isPackageInstalled(name)
	return fs.exists(packages_path.."/"..name)
end

function removePackage(name)
	fs.delete(packages_path.."/"..name)
end

function getPackages()
	packages = {}
    for _,source in pairs(fs.list(sources_list_d_path)) do
		local source_file = fs.open(sources_list_d_path.."/"..source,"r")
		packages[source] = decode(source_file.readAll())
		source_file.close()
	end
    return packages
end
