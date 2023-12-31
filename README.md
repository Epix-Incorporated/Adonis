<div align="center">

<img src="https://repository-images.githubusercontent.com/55325103/2bed6800-bfef-11eb-835b-99b981918623?width=300&height=260" alt="The Epix-Incorporated logo" width="300" height="260">

<div>&nbsp;</div>

[![Roblox model](https://img.shields.io/static/v1?label=roblox&message=model&color=blue&logo=roblox&logoColor=white)](https://www.roblox.com/library/7510622625/ "The offical Adonis admin model.")
[![Roblox nightly](https://img.shields.io/badge/roblox-nightly-blueviolet?logo=roblox)](https://www.roblox.com/library/8612978896/ "The beta testing source code modulescript.")
[![LICENSE](https://img.shields.io/github/license/Epix-Incorporated/Adonis)](https://github.com/Epix-Incorporated/Adonis/blob/master/LICENSE.md "The legal LICENSE governing the usage of the admin system.")
[![releases](https://img.shields.io/github/v/release/Epix-Incorporated/Adonis?label=version)](https://github.com/Epix-Incorporated/Adonis/releases "Downloadable versions of the admin system.")
[![Discord server](https://img.shields.io/discord/81902207070380032?label=discord&logo=discord&logoColor=white)](https://dvr.cx/discord "A Discord server where people can discuss Adonis related stuff and talk.")
[![lint](https://github.com/Epix-Incorporated/Adonis/actions/workflows/lint.yml/badge.svg)](https://github.com/Epix-Incorporated/Adonis/actions/workflows/lint.yml "Allows to check if the code of the admin system is valid without errors.")

</div>

---

Adonis is a community-maintained server moderation and management system created for use on the Roblox platform.

<h2 id="install"> ✨ Installation </h2>

📢 **New to Adonis? Take a look at our [official quick start video](https://youtu.be/1f9x9gdxLjw) or read [the unofficial setup guide](https://devforum.roblox.com/t/1535122).**

If you get stuck, feel free to ask for assistance on our [Discord server](https://discord.gg/H5RvTP3).

### Method 1 (recommended): Official Roblox Model

1. [Take a copy](https://www.roblox.com/library/7510622625/) of the Adonis loader model from the Roblox Library.
2. Insert the model into Studio using the Toolbox, and place it under `ServerScriptService`. (Do not leave it in the `Workspace`!)

### Method 2: GitHub Releases

1. Download the `rbxm` file snapshot from the [latest release](https://github.com/Epix-Incorporated/Adonis/releases/latest).
2. Import the model file into Studio.

ℹ️ **Note:** By default, snapshots included in releases have [`DebugMode`](#debug-mode) enabled.

### Method 3: Filesystem

1. Download the repository to your computer's file system.
2. Install and use a plugin like [Rojo](https://rojo.space/) to compile Adonis into a `rbxmx` file.
    If using Rojo, you can run `rojo build /path/to/adonis -o Adonis.rbxmx` to build an `rbxmx`.
3. Import the compiled model file into Studio.

🔐 **Warning:** By default, loaders compiled from the repository have [`DebugMode`](#debug-mode) enabled.

**⚠️ Method 3 compiles the *bleeding edge* version of Adonis, which may be not fully tested and is highly unstable.**

<h3 id="configuring-adonis">⚙️ Configuring Adonis</h3>

Once you've inserted the Adonis loader into your game, open `Adonis_Loader` > `Config` > `Settings`, and change `settings.DataStoreKey` to something absolutely random (eg. `"2fgi02e)^Q"`). This is for security as it prevents serverside tampering with Adonis's datastores.

You may then edit the Settings module to configure Adonis to suit your game. Instructions and elaboration are provided within the Settings module.

<h3 id="debug-mode">🔧 Debug Mode</h3>

#### **PLEASE NOTE THAT THIS FEATURE IS INTENDED FOR DEVELOPMENT/DEBUGGING PURPOSES ONLY, PLEASE CHANGE `ModuleID` FOR CUSTOM MODULES**
The `DebugModule` feature enables a number of debug features, including but not limited to:

1. Not protecting the Adonis model (such as parenting it to nil)
2. Exposes a debugging API
3. Enables debugging commands for Creators

The Adonis loader provides a `DebugMode` option which will load a local copy of the `MainModule` rather than fetching the latest version. This could be useful if you are a contributor working on the `MainModule`. Debug mode expects the `MainModule` to share the same parent with the loader model (e.g. both should be in `ServerScriptService`). **By default, snapshots provided in releases have `DebugMode` enabled.**

#### Toggling debug mode

1. Open `Adonis_Loader` > `Loader` > `Loader`
2. Change `DebugMode` at the end of the `data` table to the desired value (e.g. `DebugMode = false`)

* Official Adonis Loader: <https://www.roblox.com/library/7510622625/Adonis-Admin-Loader-Epix-Incorporated>
* Official MainModule: <https://www.roblox.com/library/7510592873/Adonis-MainModule>
* Nightly MainModule: <https://www.roblox.com/library/8612978896/Nightlies-Adonis-MainModule>

### Reference

* 📄 Documentation: <https://github.com/Epix-Incorporated/Adonis/wiki>
* 📘 User Manual: <https://github.com/Epix-Incorporated/Adonis/wiki/User-Manual-&-Feature-Showcase>
* 📜 Contributing Guide: <https://github.com/Epix-Incorporated/Adonis/blob/master/CONTRIBUTING.md>

### Social

* Discord Server: <https://discord.gg/H5RvTP3> or <https://dvr.cx/discord>
* Roblox Group: <https://www.roblox.com/groups/886423>

### Misc

* Plugins Repository: <https://github.com/Epix-Incorporated/Adonis-Plugins>
* Donor Perks Pass: <https://www.roblox.com/game-pass/1348327>

## ⭐ Contributing

The purpose of this repository is to allow others to contribute and make improvements to Adonis. Even if you've never contributed to GitHub before, we would appreciate any contributions that you can provide.

### 📜 Contributing Guide

Read the [contributing guide](https://github.com/Epix-Incorporated/Adonis/blob/master/CONTRIBUTING.md) to get a better understanding of our development process and workflow, along with answers to common questions related to contributing to Adonis.

### ⚖️ License

Adonis is available under the terms of [the MIT license](https://github.com/Epix-Incorporated/Adonis/blob/master/LICENSE).

### Thank you to our contributors

[![contributors](https://contributors-img.web.app/image?repo=Epix-Incorporated/Adonis)](https://github.com/Epix-Incorporated/Adonis/graphs/contributors)

