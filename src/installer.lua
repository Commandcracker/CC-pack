-- functions
local function setTextColour(color)
    if term.isColor() then
        term.setTextColour(color)
    end
end

local function question(_question)
    if _question == nil then else
        setTextColour(colors.orange)
        term.write(_question.."? [")
        setTextColour(colors.lime)
        term.write('Y')
        setTextColour(colors.orange)
        term.write('/')
        setTextColour(colors.red)
        term.write('n')
        setTextColour(colors.orange)
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
    local request, err = http.get(url)
    if request then
        local file = fs.open(path, "w")
        file.write(request.readAll())
        file.close()
        request.close()
    else
        printError("Faild to download: "..url)
        printError(err)
    end
end

local function loadAPIFromURL(url, name)
    local api_path = "/tmp/"..name
    download(url, api_path)
    local api = dofile(api_path)
    fs.delete(api_path)
    return api
end

-- installer

if not http then
    printError("pack requires the http API")
    printError("Set http_enable to true in ComputerCraft.cfg")
    return
end

local url_base = "https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/"
local pack = loadAPIFromURL(url_base.."lib/pack.lua", "pack")

if question("install pack") then
    pack.fixSources(false)

    for source,Package in pairs(pack.getPackages()) do
        for name,p in pairs(Package) do
            if name == "pack" then
                if pack.isPackageInstalled(source.."/"..name) then
                    printError("Pack is already installed")
                    return
                end
                pack.installPackage(source.."/"..name, p, shell)
                if fs.exists("/startup") then
                    if question("Replace startup") then
                        download(url_base.."startup.lua", "/startup")
                    end
                else
                    download(url_base.."startup.lua", "/startup")
                end
                return
            end
        end
    end

    printError("Faild to install pack")
end
