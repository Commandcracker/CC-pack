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

local function dowload(url, path)
    response = http.get(url)
    response = response.readAll()
    file = fs.open(path, "w")
    file.write(response)
    file.close()
end

if not question("Install pack") then
	printError("Abort.")
    return
end

local function get(url)
    local response = http.get(url)
    
    if response then
        local sResponse = response.readAll()
        response.close()
        return sResponse
    else
        print( "Failed." )
    end
end

local url = "https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/pack.lua"
local tArgs = {
    "install",
    "pack"
}
local res = get(url)

if res then
    local func, err = load(res, url, "t", _ENV)
    if not func then
        printError( err )
        return
    end
    local success, msg = pcall(func, table.unpack(tArgs, 1))
    if not success then
        printError( msg )
    end
end

if question("install startup") then
    dowload("https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/startup.lua", "/startup")
else
    print("add:", get("https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/startup.lua"), "to your startup")
end
