Adonis is a server moderation and management system created for the ROBLOX platform.

Uploaded to GitHub for collaboration and issue tracking.

NOTE: By default the Adonis.rbxm file uploaded in the root of this repo may have debug mode enabled. To disabled it, open Adonis_Loader > Loader > Loader.lua and change DebugMode = true to DebugMode = false in the "data" table.



## How to load a custom version:
When DebugMode is enabled, the loader will try to load the MainModule from the same parent as the Adonis_Loader model instead of requiring the model by ID. This is how I test changes to Adonis before each update, hence why it's called "Debug Mode."

If you want to maintain your own version of the MainModule you need to either enable DebugMode in the loader script and have the MainModule in the same directory as the "Adonis_Loader" model (NOT in the model, just the same PARENT as the model) or you need to upload the MainModule to Roblox and change the ModuleId in the Loader script to your own module id.

If you don't know/can't figure out how to do either of the things I just mentioned, you probably shouldn't be messing with the module at all or you'll probably break something.

## Adonis Loader:

https://www.roblox.com/library/2373505175/Adonis-Loader-BETA


## Adonis MainModule:

https://www.roblox.com/library/2373501710/Adonis-MainModule


## Documentation:

https://github.com/Sceleratis/Adonis/wiki
