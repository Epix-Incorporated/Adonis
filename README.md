![](https://images-ext-2.discordapp.net/external/aIBRjVfZJAGn2awfso3GY3kadhMQlVupqLEwnKGD3OE/https/repository-images.githubusercontent.com/55325103/2bed6800-bfef-11eb-835b-99b981918623?width=300&height=280)
=
Adonis is a server moderation and management system created for use on the Roblox platform.

Uploaded to GitHub for collaboration and issue tracking.


By default, the releases on this GitHub have DebugMode enabled, meaning the MainModule will be loaded from the parent folder of the Loader model. To disable it and instead retreive updates from the currently uploaded MainModule, open Adonis_Loader > Loader > Loader.lua and change DebugMode = true to DebugMode = false in the "data" table. When using a release downloaded from GitHub, Adonis will remain locked at whatever version you downloaded and will basically be "offline" in the sense that it won't receive any updates. This is useful if you need to rollback to a previous version (such as in the case of incompatibilities introduced in a new version) or maintain a custom one. 

## Nightlies:
Releases are only made when the current version of the source is determined to be ready. This is usually after it's been tested and debugged enough for me to feel comfortable shipping it out. If you would like the "bleeding edge" version we now offer "nightly" builds which you can grab in the Discord. Any time I make or merge a change to the source a new build will be automatically created and I'll post it in the #nightly-builds channel on our Discord server. These may be extremely unstable or outright broken so use them at you're own risk. They are provided for those who would like to give feedback on planned changes before they're live without having to build it from source. You can find our Discord below if interested. 

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

Once installed, download/clone this repository, enter the repo's directory, and run "rojo build AdonisSourceFolderPathHere -o Adonis.rbxmx" to build a model file or "rojo build -o Adonis.rbxlx" to build a place file (Note: In the place file, you can find the model in ServerScriptService > Adonis_Rojo)
 
Quick Start: https://youtu.be/1f9x9gdxLjw
=

## Adonis Loader:

https://www.roblox.com/library/2373505175/Adonis-Loader-BETA


## Adonis MainModule:

https://www.roblox.com/library/2373501710/Adonis-MainModule


## Documentation:

https://github.com/Sceleratis/Adonis/wiki


## Our Discord:

https://discord.gg/rdkgGc4
