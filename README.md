<div align="center">
    <img src="https://images-ext-2.discordapp.net/external/aIBRjVfZJAGn2awfso3GY3kadhMQlVupqLEwnKGD3OE/https/repository-images.githubusercontent.com/55325103/2bed6800-bfef-11eb-835b-99b981918623?width=300&height=260"/>
    <div>&nbsp;</div>
    <a href="https://www.roblox.com/library/7510622625/">
        <img src="https://img.shields.io/static/v1?label=roblox&message=model&color=blue&logo=roblox&logoColor=white"/>
    </a>
    <a href="https://www.roblox.com/library/8612978896/">
        <img src="https://img.shields.io/badge/roblox-nightly-blueviolet?logo=roblox"/>
    </a>
    <a href="https://github.com/Sceleratis/Adonis/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/Sceleratis/Adonis"/>
    </a>
    <a href="https://github.com/Sceleratis/Adonis/releases">
        <img src="https://img.shields.io/github/v/release/Sceleratis/Adonis?label=version"/>
    </a>
    <a href="https://dvr.cx/discord">
        <img src="https://img.shields.io/discord/81902207070380032?label=discord&logo=discord&logoColor=white"/>
    </a>
</div>
<hr/> 

Adonis is a community-maintained server moderation and management system created for use on the Roblox platform.

## ✨ Installation

📢 **New to Adonis? Take a look at our official quick start video [here](https://youtu.be/1f9x9gdxLjw) or read the unofficial setup guide [here](https://devforum.roblox.com/t/1535122).**
<br>If you get stuck, feel free to ask for assistance in our [Discord server](https://discord.gg/H5RvTP3).

### Method 1 (recommended): Official Roblox Model

* [Take a copy](https://www.roblox.com/library/7510622625/) of the Adonis loader model from the Roblox Library

* Insert the model into Studio using the Toolbox, and place it under `ServerScriptService` (do not leave it in the Workspace!)

### Method 2: GitHub Releases

* Download the `rbxm` file snapshot from the [latest release](https://github.com/Sceleratis/Adonis/releases/latest)
* Import the model file into Studio
  * Note: By default, snapshots included in releases have <a href="#%EF%B8%8F-debug-mode">`DebugMode`</a> enabled.

### Method 3: Filesystem

* Download the repository to your computer's file system
* Install and use a plugin like [Rojo](https://rojo.space/) to compile Adonis into a `rbxmx` file
  * If using Rojo, you can run `rojo build /path/to/adonis -o Adonis.rbxmx` to build a `rbxmx`
* Import the compiled model file into Studio
  * Note: By default, loaders compiled from the repository have <a href="#%EF%B8%8F-debug-mode">`DebugMode`</a> enabled. **⚠️ This method compiles the _bleeding edge_ version of Adonis, which may be not fully tested and highly unstable.**

## 🛠️ Debug Mode

The Adonis loader provides a `DebugMode` option which will load a local copy of the `MainModule` rather than fetching the latest version. This could be useful if you are a contributor working on the ``MainModule``, or want to maintain a custom version for your game. Debug mode expects the `MainModule` to share the same parent with the loader model (e.g. both should be in `ServerScriptService`). **By default, snapshots provided in  releases have `DebugMode` enabled.**

### Toggling debug mode

* Open `Adonis_Loader` > `Loader` > `Loader`
* Change `DebugMode` at the end of the `data` table to the desired value (e.g. `DebugMode = false`)

## 🔗 Links
* Official Adonis Loader: https://www.roblox.com/library/7510622625/Adonis-Loader
* Official MainModule: https://www.roblox.com/library/7510592873/Adonis-MainModule
* Documentation: https://github.com/Sceleratis/Adonis/wiki
* Discord Server: https://discord.gg/rdkgGc4
* Plugins Repository: https://github.com/Sceleratis/Adonis-Plugins

## ⭐ Contributing

The purpose of this repository is to allow others to contribute and make improvements to Adonis. Even if you've never contributed on GitHub before, we would appreciate any contributions that you can provide.

### 📜 Contributing Guide

Read the [contributing guide](https://github.com/Sceleratis/Adonis/blob/master/CONTRIBUTING.md) to get a better understanding of our development process and workflow, along with answers to common questions related to contributing to Adonis.

### ⚖️ License

Adonis is available under the terms of the MIT license. Read more details about the license [here](https://github.com/Sceleratis/Adonis/blob/master/LICENSE).

### Thank you to our contributors!

[![contributors](https://contributors-img.web.app/image?repo=sceleratis/adonis)](https://github.com/sceleratis/adonis/graphs/contributors)
