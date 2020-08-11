Adonis is a server moderation and management system created for the ROBLOX platform.

Uploaded to GitHub for collaboration and issue tracking.

NOTE: By default the Adonis.rbxm file uploaded in the root of this repo may have debug mode enabled. To disabled it, open Adonis_Loader > Loader > Loader.lua and change DebugMode = true to DebugMode = false in the "data" table.

When DebugMode is enabled, the loader will try to load the MainModule from the same parent it is currently in instead of requiring it by ID. If you wish to maintain a personal, modified, version of Adonis, setting DebugMode to true will allow you to do this. 

How to load a custom version:
If you maintain your own version of the MainModule you either need to enable DebugMode in the loader script and have the MainModule in the same directory as the "Adonis_Loader" model (NOT in the model, just the same PARENT as the model) or you need to upload the MainModule to Roblox and change the ModuleId in the Loader script to your own module id.

If you don't know/can't figure out how to do either of the things I just mentioned, you probably shouldn't be messing with the module at all or you'll probably break something.

## Adonis Loader:

https://www.roblox.com/library/2373505175/Adonis-Loader-BETA


## Adonis MainModule:

https://www.roblox.com/library/2373501710/Adonis-MainModule


## Documentation:

https://github.com/Sceleratis/Adonis/wiki
