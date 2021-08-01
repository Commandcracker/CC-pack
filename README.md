# Pack

Pack is a Package manager for [ComputerCraft](https://github.com/dan200/ComputerCraft) and [ComputerCraft Tweaked](https://github.com/SquidDev-CC/CC-Tweaked)

## Installation

### ComputerCraft 1.78+ and ComputerCraft Tweaked

```bash
pastebin run gTMnqnRk
```

### ComputerCraft 1.77

```bash
wget https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/installer.lua installer
installer
```

### ComputerCraft 1.76-

```lua
lua
local a=http.get("https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/installer.lua")local b=fs.open(shell.resolve("installer"),"w")b.write(a.readAll())b.close()a.close()exit()
installer
```

## pack.json (Required)

### Examples

```json
{
    "packages": {
        "package-name-1": {
            "files": {
                "pastebin/myFile": {"url": "https://pastebin.com/raw/???"},
                "gist/myFile": {"url": "https://gist.githubusercontent.com/???/???/raw"},
                "github/myFile": {"url": "https://raw.githubusercontent.com/???/???/master/???"}
            }
        },
        "package-name-2": {
            "files": {
                "pastebin/myFile": {"url": "https://pastebin.com/raw/???"},
                "gist/myFile": {"url": "https://gist.githubusercontent.com/???/???/raw"},
                "github/myFile": {"url": "https://raw.githubusercontent.com/???/???/master/???"}
            }
        }
    }
}
```

pack's [pack.json](pack.json)

### Package

#### Example

```json
"package-name": {
    "hardware": {
        "color": true
    },
    "files": {
        "pastebin/myFile": {"url": "https://pastebin.com/raw/???"},
        "gist/myFile": {"url": "https://gist.githubusercontent.com/???/???/raw"},
        "github/myFile": {"url": "https://raw.githubusercontent.com/???/???/master/???"}
    }
}
```

#### Files (Required)

```json
"files": {
    "pastebin/myFile": {"url": "https://pastebin.com/raw/???"},
    "gist/myFile": {"url": "https://gist.githubusercontent.com/???/???/raw"},
    "github/myFile": {"url": "https://raw.githubusercontent.com/???/???/master/???"}
}
```

##### Path Rules

- Point to a file
- Local path

| ❌          | ✔️          |
|-------------|------------|
| /bin/myFile | bin/myFile |

##### URL Rules

- Must point to a raw file
- Won't change

| ❌                                                    | ✔️                                                   |
|-------------------------------------------------------|-----------------------------------------------------|
| https//pastebin.com/???                               | https//pastebin.com/raw/???                         |
| https//github.com/???/???/blob/master/???             | https//raw.githubusercontent.com/???/???/master/??? |
| https//gist.github.com/???/???                        | https//gist.githubusercontent.com/???/???/raw       |
| https//gist.githubusercontent.com/???/???/raw/???/??? | https//gist.githubusercontent.com/???/???/raw       |

##### Additional information

If a file points to /`startup` or /`startup.lua` \
it will run at startup

If a file points to /`bin/myProgram` \
it will be added to the shell's path

if you want to get your local path use

```lua
local path = fs.getDir(shell.getRunningProgram())
```

if you want auto-completion \
do something like this in your `startup`

```lua
shell.setCompletionFunction(
    fs.getDir(shell.getRunningProgram()).."/bin/myprogram", 
    function(shell, index, text)
        if index == 2 then return end
        return fs.complete(text, shell.dir(), true, false)
    end
)
```

Dont use:

```lua
os.loadAPI()
```

use:

```lua
dofile(shell.getRunningProgram()).."mypath")`
```

#### Hardware (Optinal)

The values that you see here are the `default values`

```json5
"hardware": {
    "turtle": true,   // Runs on a turtle
    "pocket": true,    // Runs on a pocket computer
    "computer": true, // Runs on a computer
    "command": false, // Only runs on command capable devices
    "color": false    // Only runs on advanced devices
}
```

## Third Party Libraries

| Library                               | Maintainer                                              |
|---------------------------------------|---------------------------------------------------------|
| [Json](https://pastebin.com/4nRg9CHU) | [ElvishJerricco](https://pastebin.com/u/ElvishJerricco) |

## Building

### Requirements

You need to have [Node.js](https://nodejs.org) Installed. \
Then run this command to install [luamin](https://github.com/mathiasbynens/luamin).

```bash
npm install luamin
```

### Running the build process

```bash
node build
```
