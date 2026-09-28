--!nonstrict
--[[

	CURRENT LOADER:
	https://www.roblox.com/library/7510622625/Adonis-Admin-Loader-Epix-Incorporated

	CURRENT MODULE:
	https://www.roblox.com/library/7510592873/Adonis-MainModule

	NIGHTLY MODULE:
	https://www.roblox.com/library/8612978896/Nightlies-Adonis-MainModule

--]]

----------------------------------------------------------------------------------
--                                Adonis Loader                                 --
--                            By Epix Incorporated                              --
----------------------------------------------------------------------------------
--              Edit settings inside the Config -> Settings folder              --
----------------------------------------------------------------------------------
--       This script loads the Adonis source (MainModule) into the game.        --
--            Only edit this script if you know what you're doing!              --
----------------------------------------------------------------------------------

local warn = function(...)
	warn(":: Adonis ::", ...)
end

local print = function(...)
	print(":: Adonis ::", ...)
end

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local InsertService = game:GetService("InsertService")

-- Support yieldable xpcall
local function yxpcall(f, callback, ...)
	local args = table.pack(pcall(f, ...))

	if not args[1] then
		callback(args[2])
	else
		return table.unpack(args, 2, args.n)
	end
end

local function loadModuleAsset(moduleId: number)
	local asset = InsertService:LoadAsset(moduleId)

	if asset.Name == "MainModule" then
		return assert(require(asset), ":LoadAsset() module returned invalid values!")
	elseif asset:FindFirstChild("MainModule") then
		return assert(require(asset.MainModule), ":LoadAsset() module returned invalid values!")
	elseif asset:IsA("ModuleScript") then
		return assert(require(asset), ":LoadAsset() module returned invalid values!")
	end

	for _, v in asset:GetChildren() do
		if v:IsA("ModuleScript") then
			return assert(require(v), ":LoadAsset() module returned invalid values!")
		end
	end

	error(`Failed to find any matching ModuleScripts for {moduleId}.`)
end

local mutex = RunService:FindFirstChild("__Adonis_MUTEX")
if mutex then
	if mutex:IsA("StringValue") then
		warn("Adonis is already running! Aborting...; Running Location:", mutex.Value, "This Location:", script:GetFullName())
	else
		warn("Adonis mutex detected but is not a StringValue! Aborting anyway...; This Location:", script:GetFullName())
	end
else
	mutex = Instance.new("StringValue")
	mutex.Name = "__Adonis_MUTEX"
	mutex.Archivable = false
	mutex.Value = script:GetFullName()
	mutex.Parent = RunService

	local model = script.Parent.Parent
	local configFolder = model.Config
	local loaderFolder = model.Loader

	local loader = loaderFolder.Loader
	local runner = script

	local settingsFolder = configFolder:FindFirstChild("Settings")
	local pluginsFolder = configFolder.Plugins
	local themesFolder = configFolder.Themes
	local inGameSettingsEditorSettingsFolder = configFolder:FindFirstChild("InGameSettingsEditorSettings")

	local backup = model:Clone()

	local data = {
		Settings = {} :: {[string]: any};
		Descriptions = {} :: {[string]: string};
		Messages = {} :: {string|{[string]: any}};
		ServerPlugins = {} :: {ModuleScript|string};
		ClientPlugins = {} :: {ModuleScript|string};
		Packages = {} :: {Folder};
		Themes = {} :: {Instance};

		ModelParent = model.Parent;
		Model = model;
		Config = configFolder;
		Core = loaderFolder;

		Loader = loader;
		Runner = runner;
		LoaderVersion = (model and model:FindFirstChild("Version")) and tonumber(model.Version.Value);

		ModuleID = 7510592873;  		--// https://www.roblox.com/library/7510592873/Adonis-MainModule
		LoaderID = 7510622625;			--// https://www.roblox.com/library/7510622625/Adonis-Loader-Sceleratis-Davey-Bones-Epix

		--// Note: The nightly module is updated frequently with every commit merged to the master branch on the Adonis repo.
		--// It is prone to breaking, unstable, untested, and should not be used for anything other than testing/feature preview.
		NightlyMode = true;			--// If true, uses the nightly module instead of the current release module.
		NightlyModuleID = 8612978896; 	--// https://www.roblox.com/library/8612978896/Nightlies-Adonis-MainModule

		--// Module used in case MainModule is unavailable, containing only essential commands
		Backup = 17438792001; 	--// https://create.roblox.com/store/asset/17438792001/

		DebugMode = true;
		SilentStartup = false;
	}

	--// Init

	if not data.SilentStartup then
		print("Loading...")
	end

	-- selene: allow(incorrect_standard_library_use)
	script.Parent = nil

	if not data.DebugMode then
		model.Name = math.random()
	end

	local moduleId = if data.NightlyMode then data.NightlyModuleID else data.ModuleID

	if data.DebugMode then
		local found = false
		for _, v in model.Parent:GetChildren() do
			if v.Name == "MainModule" and v:IsA("ModuleScript") then
				moduleId, found = v, true
				break
			end
		end

		if not found and not data.NightlyMode then
			warn(`Adonis DebugMode is enabled but no ModuleScript named 'MainModule' is found in {model.Parent and model.Parent:GetFullName()}`)
		end
	end

	if settingsFolder == nil then
		warn("[DEVELOPER ERROR] No settings folder or module found; using default settings.")
		table.insert(data.Messages, {
			Title = "Warning!";
			Icon = "MatIcon://Dangerous";
			Message = "No settings folder or module found; using default settings.";
			Time = 15;
		})
	elseif settingsFolder:IsA("Folder") then
		local erroredSettingsModules = {}

		for _, module in settingsFolder:GetChildren() do
			xpcall(function()
				local requiredModule = require(module)

				for key, value in requiredModule do
					if key == "Messages" then
						data.Messages = value
					end

					data.Settings[key] = value
				end
			end, function(err)
				table.insert(erroredSettingsModules, {Name = module.Name, Error = err})
			end)
		end

		for _, erroredSettingModule in erroredSettingsModules do
			warn(`[DEVELOPER ERROR] The Settings.{erroredSettingModule.Name} module errored while loading; using defaults for this module; Error Message: {erroredSettingModule.Error}`)
			table.insert(data.Messages, {
				Title = "Warning!";
				Icon = "MatIcon://Dangerous";
				Message = `The Settings.{erroredSettingModule.Name} module errored while loading; using defaults for this module.`;
				Time = 15;
			})
		end

		if #erroredSettingsModules > 0 then
			data.Settings.Ranks = {} -- This is for security reasons because settings may reset back to unintended defaults.
		end

		xpcall(function()
			data.Descriptions = require(inGameSettingsEditorSettingsFolder.Descriptions)
		end, function(err)
			warn("[DEVELOPER ERROR] The InGameSettingsEditorSettings.Descriptions module errored while loading; using defaults; Error Message:", err)
			table.insert(data.Messages, {
				Title = "Warning!";
				Icon = "MatIcon://Dangerous";
				Message = "The InGameSettingsEditorSettings.Descriptions module errored while loading; using defaults.";
				Time = 15;
			})
		end)

		xpcall(function()
			data.Order = require(inGameSettingsEditorSettingsFolder.Order)
		end, function(err)
			warn("[DEVELOPER ERROR] The InGameSettingsEditorSettings.Order module errored while loading; using defaults; Error Message:", err)
			table.insert(data.Messages, {
				Title = "Warning!";
				Icon = "MatIcon://Dangerous";
				Message = "The InGameSettingsEditorSettings.Order module errored while loading; using defaults.";
				Time = 15;
			})
		end)
	else -- Account for legacy settings module
		local success, settingsData = pcall(require, settingsFolder)
		if success then
			data.Settings = settingsData.Settings
			data.Descriptions = settingsData.Description
			data.Order = settingsData.Order
			data.Messages = settingsData.Settings.Messages
		else
			warn("[DEVELOPER ERROR] Settings module errored while loading; using default settings; Error Message: ", settingsData)
			table.insert(data.Messages, {
				Title = "Warning!";
				Icon = "MatIcon://Dangerous";
				Message = "Settings module error detected; using default settings.";
				Time = 15;
			})
		end
	end

	for _, module in pluginsFolder:GetChildren() do
		local name = string.lower(module.Name)

		if module:IsA("Folder") then
			table.insert(data.Packages, module)
		elseif string.match(name, "^client[%-:]") then
			table.insert(data.ClientPlugins, module)
		elseif string.match(name, "^server[%-:]") then
			table.insert(data.ServerPlugins, module)
		else
			warn(`[DEVELOPER ERROR] Unknown Plugin Type for {module:GetFullName()}; Plugin name should either start with 'Server:', 'Server-', 'Client:' or 'Client-'`)
		end
	end

	for _, theme in themesFolder:GetChildren() do
		table.insert(data.Themes, theme)
	end

	if tonumber(moduleId) and not data.SilentStartup then
		print(`Requiring Adonis MainModule; Model URL: https://www.roblox.com/library/{moduleId}`)
	end

	local success, module = pcall(require, moduleId)

	--// Backup method for loading Adonis
	if not success and type(moduleId) == "number" then
		warn(`Failed to load Adonis MainModule {moduleId} due to {module}! If this does not work please purchase the Adonis MainModule to your inventory. Using backup method...`)
		yxpcall(function()
			module = loadModuleAsset(moduleId)
			success = true
		end, function(reason)
			warn(`Failed to load Adonis mainmodule {moduleId} via :LoadAsset() method due to {reason}! Loading the backup MainModule...`)
			yxpcall(function()
				module = assert(require(data.Backup), "Backup module returned invalid values!")
				success = true
			end, function(reason)
				warn(`Failed to load Adonis backup MainModule {data.Backup} due to {reason}! If this does not work please purchase the Adonis backup MainModule to your inventory. Using backup method...`)
				yxpcall(function()
					module = loadModuleAsset(data.Backup)
					success = true
				end, function(reason)
					module = nil
					warn(`FATAL ERROR! Failed to load Adonis backup MainModule {moduleId} via :LoadAsset() method due to {reason}! Adonis can't be booted up! Please contact the Adonis helpers immediately and add both the regular MainModule and the backup MainModule to your user&group inventory!`)
				end)
			end)
		end)
	end

	local response = assert(success and module, "FATAL ERROR! Adonis bootstrap function is missing!")(data)

	if response == "SUCCESS" then
		if data.Settings and data.Settings.HideScript and not data.DebugMode and not RunService:IsStudio() then
			model.Parent = nil
			game:BindToClose(function()
				local oldArchivable = script.Archivable
				script.Archivable = true
				local clone = script:Clone()
				clone.Archivable = oldArchivable
				clone.Parent = loaderFolder
				model.Name = "Adonis_Loader"
				model.Parent = ServerScriptService
			end)
		end

		model.Name = "Adonis_Loader"
	else
		error(" !! Adonis MainModule failed to load !! ")
	end
end

																																																							--[[
--___________________________________________________________________________________________--
--___________________________________________________________________________________________--
--___________________________________________________________________________________________--
--___________________________________________________________________________________________--

					___________      .__         .___
					\_   _____/_____ |__|__  ___ |   | ____   ____
					 |    __)_\____ \|  \  \/  / |   |/    \_/ ___\
					 |        \  |_> >  |>    <  |   |   |  \  \___
					/_______  /   __/|__/__/\_ \ |___|___|  /\___  > /\
					        \/|__|            \/          \/     \/  \/
				  --------------------------------------------------------
				  Epix Incorporated. Not Everything is so Black and White.
				  --------------------------------------------------------

--___________________________________________________________________________________________--
--___________________________________________________________________________________________--
--___________________________________________________________________________________________--
--___________________________________________________________________________________________--
																																																							--]]