-- functions
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

local function download(url, path)
    response = http.get(url)
    response = response.readAll()
    file = fs.open(path, "w")
    file.write(response)
    file.close()
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

local function loadAPIFromURL(url, name)
    api_path = "/tmp/"..name
    apt_file = fs.open(api_path,"w")
    apt_file.write(get(url))
    os.loadAPI(api_path)
    fs.delete(api_path)
end

-- cli
local url_base = "https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/"

loadAPIFromURL(url_base.."lib/pack.lua", "pack")

local url = url_base.."bin/pack.lua"
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

if fs.exists("/startup") then
    if question("Replace startup") then
        download(url_base.."startup.lua", "/startup")
    end
else
    download(url_base.."startup.lua", "/startup")
end

if question("Reboot now") then
    print()
    if term.isColor() then
        term.setTextColor(colors.orange)
    end
    print("Rebooting computer")
    sleep(1)
    os.reboot()
end
