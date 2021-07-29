-- https://github.com/Commandcracker/CC-pack
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

local url = "https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/installer.lua"
local tArgs = { ... }
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
