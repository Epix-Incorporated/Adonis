Adonis is a server moderation and management system created for the Roblox platform.

Uploaded to GitHub for collaboration and issue tracking.

NOTE: Adonis is constantly changing. Whether it be new features, improvements, or the removal or modification of existing features when necessary. If a plugin you've been using suddenly stops working, something it relied on was likely changed. Adonis is updated whenever new changes are made, as opposed to other softwares that have "stable" and "nightly" branches/releases, Adonis' model on ROBLOX will always be the most up to date version, so if you have important plugins that are essential to the operation of your game, I advise that you either fork Adonis or use the version that can be found in the releases on this GitHub. You will have to manually update to get future changes. 

By default, the Adonis.rbxm file in this repo may have debug mode enabled. To disable it, open Adonis_Loader > Loader > Loader.lua and change DebugMode = true to DebugMode = false in the "data" table. I recommend using the Adonis_Loader model instead.

Quick Start: https://youtu.be/XnhWcfoAJ_o


## How to load a custom version:
When DebugMode is enabled, the loader will try to load the MainModule from the same parent as the Adonis_Loader model instead of requiring the model by ID. This is how I test changes to Adonis before each update, hence why it's called "Debug Mode."

If you want to maintain your own version of the MainModule you need to either enable DebugMode in the loader script and have the MainModule in the same directory as the "Adonis_Loader" model (NOT in the model, just the same PARENT as the model) or you need to upload the MainModule to Roblox and change the ModuleId in the Loader script to your own module id.

You can download "snapshot" versions of Adonis from this repo's releases page. These models consist of a folder containing the MainModule and Loader at the time the release was made. DebugMode is set to true in the Loader, so it will (by default) load the included MainModule.

If you find any bugs or come up with useful changes feel free to submit an issue or pull request. Doing so will help make Adonis better for everyone :)!
However, please do not submit issues caused by changes you made to your personal version of the code. If you are trying to change Adonis' code, you do so at your own risk and anything you break as a result will be on you to debug. 

Feel free to seek guidance in the development channel on our Discord.

## Adonis Loader:

https://www.roblox.com/library/2373505175/Adonis-Loader-BETA


## Adonis MainModule:

https://www.roblox.com/library/2373501710/Adonis-MainModule


## Documentation:

https://github.com/Sceleratis/Adonis/wiki


## Our Discord:

https://discord.gg/rdkgGc4
