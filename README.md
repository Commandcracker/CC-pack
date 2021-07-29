# Pack

Pack is a Package manager for [ComputerCraft](https://github.com/dan200/ComputerCraft) and [ComputerCraft Tweaked](https://github.com/SquidDev-CC/CC-Tweaked)

## Installation

### ComputerCraft 1.77+ and ComputerCraft Tweaked

```bash
wget https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/pack.lua pack
```

### ComputerCraft 1.76-

```lua
lua
local a=http.get("https://raw.githubusercontent.com/Commandcracker/CC-pack/master/build/pack.lua")local b=fs.open(shell.resolve("pack"),"w")b.write(a.readAll())b.close()a.close()exit()
```

## Examples

```json
{
    "pack-name": {
        "files": {
            "pack": "raw file url"
        }
    }
}
```

pack's [pack.json](pack.json)

## Third Party Libraries

- [Json](https://pastebin.com/4nRg9CHU) by [ElvishJerricco](https://pastebin.com/u/ElvishJerricco)

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
