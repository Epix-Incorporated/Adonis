Adonis is a server moderation and management system created for use on the Roblox platform.

Uploaded to GitHub for collaboration and issue tracking.

NOTE: Adonis is constantly changing. Whether it be new features, improvements, or the removal or modification of existing features when necessary. If a plugin you've been using suddenly stops working, something it relied on was likely changed. Adonis is updated whenever new changes are made, as opposed to other softwares that have "stable" and "nightly" branches/releases, Adonis' model on ROBLOX will always be on the most current release, so if you have important plugins that are essential to the operation of your game, I advise that you either fork Adonis or use the version that can be found in the releases on this GitHub. If you go this route you will have to manually update to get future changes but there won't be any risk of a future update breaking or changing something you rely on. 

By default, the releases on this GitHub have DebugMode enabled, meaning the MainModule will be loaded from the parent folder of the Loader model. To disable it and instead retreive updates from the currently uploaded MainModule, open Adonis_Loader > Loader > Loader.lua and change DebugMode = true to DebugMode = false in the "data" table.

Quick Start: https://youtu.be/1f9x9gdxLjw


## How to load a custom version:
When DebugMode is enabled, the loader will try to load the MainModule from the same parent as the Adonis_Loader model instead of requiring the model by ID. This is how I test changes to Adonis before each update, hence why it's called "Debug Mode."

If you want to maintain your own version of the MainModule you need to either enable DebugMode in the loader script and have the MainModule in the same directory as the "Adonis_Loader" model (NOT in the model, just the same PARENT as the model) or you need to upload the MainModule to Roblox and change the ModuleId in the Loader script to your own module's asset ID.

You can download "snapshot" versions of Adonis from this repo's releases page. These models consist of a folder containing the MainModule and Loader at the time the release was made. DebugMode is set to true in the Loader, so it will (by default) load the included MainModule.

If you find any bugs or come up with useful changes feel free to submit an issue or pull request. Doing so will help make Adonis better for everyone :)!
However, please do not submit issues caused by changes you made to your personal version of the code. If you are trying to change Adonis' code, you do so at your own risk and anything you break as a result will be on you to debug. 

Feel free to seek guidance in the development channel on our Discord.

## Building from source:
This project uses Rojo.
Follow the installation steps outlined here: https://rojo.space/docs/installation/

Once installed, download/clone this repository, enter the repo's directory, and run "rojo build -o Adonis.rbxmx" to build a model file or "rojo build -o Adonis.rbxlx" to build a place file (Note: In the place file, you can find the model in ServerScriptService > Adonis_Rojo)
 
## Adonis Loader:

https://www.roblox.com/library/2373505175/Adonis-Loader-BETA


## Adonis MainModule:

https://www.roblox.com/library/2373501710/Adonis-MainModule


## Documentation:

https://github.com/Sceleratis/Adonis/wiki


## Our Discord:

https://discord.gg/rdkgGc4
