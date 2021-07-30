local pack = {}
local json = {}
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
function json.removeWhite(str)
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

function json.encode(val)
	return encodeCommon(val, false, 0, {})
end

function json.encodePretty(val)
	return encodeCommon(val, true, 0, {})
end

------------------------------------------------------------------ decoding

local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end

function json.parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, json.removeWhite(str:sub(5))
	else
		return false, json.removeWhite(str:sub(6))
	end
end

function json.parseNull(str)
	return nil, json.removeWhite(str:sub(5))
end

local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function json.parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = json.removeWhite(str:sub(i))
	return val, str
end

function json.parseString(str)
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
	return s, json.removeWhite(str:sub(2))
end

function json.parseArray(str)
	str = json.removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = json.parseValue(str)
		val[i] = v
		i = i + 1
		str = json.removeWhite(str)
	end
	str = json.removeWhite(str:sub(2))
	return val, str
end

function json.parseObject(str)
	str = json.removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = json.parseMember(str)
		val[k] = v
		str = json.removeWhite(str)
	end
	str = json.removeWhite(str:sub(2))
	return val, str
end

function json.parseMember(str)
	local k = nil
	k, str = json.parseValue(str)
	local val = nil
	val, str = json.parseValue(str)
	return k, val, str
end

function json.parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return json.parseObject(str)
	elseif fchar == "[" then
		return json.parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return json.parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return json.parseBoolean(str)
	elseif fchar == "\"" then
		return json.parseString(str)
	elseif str:sub(1, 4) == "null" then
		return json.parseNull(str)
	end
	return nil
end

function json.decode(str)
	str = json.removeWhite(str)
	t = json.parseValue(str)
	return t
end

function json.decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = json.decode(file.readAll())
	file.close()
	return decoded
end

-- Vars
local pack_path = "/etc/pack"
local packages_path = pack_path.."/packages"
local sources_list_path = pack_path.."/sources.list"
local sources_list_d_path = pack_path.."/sources.list.d"

-- functions
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

local function download(url, path)
    local request = http.get(url)
    local file = fs.open(path, "w")
    file.write(request.readAll())
    file.close()
    request.close()
end

-- Sources Stuff
function pack.getSources()
    local sources_file = io.open(sources_list_path, "r")
    
    local line = sources_file:read()
    local sources = {}
    
    while line do
        table.insert(sources, split(line, " "))
        line = sources_file:read()
    end

    return sources
end

function pack.fetchSources(cli)
	local sources = pack.getSources()
    if cli then
		if term.isColor() then
			term.setTextColour(colors.lime)
		end
		print("Fetching")
		if term.isColor() then
			term.setTextColour(colors.blue)
		end
    end
	for _,source in pairs(sources) do
        if cli then
		    print(source[1])
        end
		download(source[2], sources_list_d_path.."/"..source[1])
	end
	if cli then
		term.setTextColour(colors.white)
	end
end

function pack.fixSources(cli)
    if not fs.exists(sources_list_path) then
        local sources_list = fs.open(sources_list_path, "w")
        sources_list.write("pack https://raw.githubusercontent.com/Commandcracker/CC-pack/master/packages.json")
        sources_list.close()
        pack.fetchSources(cli)
    end
end

function pack.addSource(namespace,url,cli)

	for _,source in pairs(pack.getSources()) do
		if source[1] == namespace then
			printError("Namespace already exists")
			return
		end
	end

	if not http.checkURL(url) then
		if cli then
			printError("Bad url")
		end
		return
	end

	local file = fs.open(sources_list_path, "a")
	file.write("\n"..namespace.." "..url)
	file.close()

	if cli then
		if term.isColor() then
			term.setTextColour(colors.lime)
		end
		print("Added:")
		if term.isColor() then
			term.setTextColour(colours.lightGrey )
		end
		print(namespace)
		if term.isColor() then
			term.setTextColour(colors.blue)
		end
		print(url)
		term.setTextColour(colors.white)
	end
	pack.fetchSources(cli)
end

-- Package Stuff
function pack.loadPackage(path, shell)
    for _,file_name in pairs(fs.list(path)) do
        if file_name == "bin" or file_name == "programs" then
            shell.setPath(shell.path()..":"..path.."/"..file_name)
        elseif file_name == "lib" or file_name == "apis" then
            for _, lib in pairs(fs.list(path.."/"..file_name)) do
                --os.loadAPI(path.."/"..file_name.."/"..lib)
            end
        elseif file_name == "startup" or file_name == "startup.lua" then
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

function pack.loadPackages(shell)
    for _,source_folder_name in pairs(fs.list(packages_path)) do
        for _,package_folder_name in pairs(fs.list(packages_path.."/"..source_folder_name)) do
            pack.loadPackage(packages_path.."/"..source_folder_name.."/"..package_folder_name, shell)
        end
    end
end

function pack.installPackage(name, packag, shell)
	if term.isColor() then
		term.setTextColour(colors.lime)
	end
	print("Downloading")
	if term.isColor() then
		term.setTextColour(colors.blue)
	end

    for k,v in pairs(packag["files"]) do
		print(packages_path.."/"..name.."/"..k)
        download(v, packages_path.."/"..name.."/"..k)
    end

	term.setTextColour(colors.white)
    pack.loadPackage(packages_path.."/"..name, shell)
end

function pack.isPackageInstalled(name)
	return fs.exists(packages_path.."/"..name)
end

function pack.removePackage(name)
	fs.delete(packages_path.."/"..name)
end

function pack.getPackages()
	packages = {}
    for _,source in pairs(fs.list(sources_list_d_path)) do
		local source_file = fs.open(sources_list_d_path.."/"..source,"r")
		packages[source] = json.decode(source_file.readAll())
		source_file.close()
	end
    return packages
end

pack.json = json
return pack