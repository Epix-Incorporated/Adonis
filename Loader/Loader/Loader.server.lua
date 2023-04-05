--!nonstrict
--[[

	DEVELOPMENT HAS BEEN MOVED FROM DAVEY_BONES/SCELERATIS TO THE EPIX INCORPORATED GROUP

	CURRENT LOADER:
	https://www.roblox.com/library/7510622625/Adonis-Admin-Loader-Epix-Incorporated

	CURRENT MODULE:
	https://www.roblox.com/library/7510592873/Adonis-MainModule

--]]

----------------------------------------------------------------------------------
--                                Adonis Loader                                 --
--                            By Epix Incorporated                              --
----------------------------------------------------------------------------------
--          Edit settings using the Settings module in the Config folder        --
----------------------------------------------------------------------------------
--       This script loads the Adonis source (MainModule) into the game.        --
--            Only edit this script if you know what you're doing!              --
----------------------------------------------------------------------------------

local warn = function(...)
	warn(":: Adonis ::", ...)
end

warn("Loading...")

local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

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

	local dropper = loaderFolder.Dropper
	local loader = loaderFolder.Loader
	local runner = script

	local settingsModule = configFolder.Settings
	local pluginsFolder = configFolder.Plugins
	local themesFolder = configFolder.Themes

	local backup = model:Clone()

	local data = {
		Settings = {} :: {[string]: any};
		Descriptions = {} :: {[string]: string};
		Messages = {} :: {string|{[string]: any}};
		ServerPlugins = {} :: {ModuleScript};
		ClientPlugins = {} :: {ModuleScript};
		Packages = {} :: {Folder};
		Themes = {} :: {Instance};

		ModelParent = model.Parent;
		Model = model;
		Config = configFolder;
		Core = loaderFolder;

		Loader = loader;
		Dopper = dropper;
		Runner = runner;

		ModuleID = 7510592873;  --// https://www.roblox.com/library/7510592873/Adonis-MainModule
		LoaderID = 7510622625;	--// https://www.roblox.com/library/7510622625/Adonis-Loader-Sceleratis-Davey-Bones-Epix

		DebugMode = true;
	}

	--// Init

	-- selene: allow(incorrect_standard_library_use)
	script.Parent = nil --script:Destroy()
	model.Name = math.random()

	local moduleId = data.ModuleID
	if data.DebugMode then
		for _, v in model.Parent:GetChildren() do
			if v.Name == "MainModule" and v:IsA("ModuleScript") then
				moduleId = v
				break
			end
		end
		if not moduleId then
			error("Adonis DebugMode is enabled but no ModuleScript named 'MainModule' is found in "..model.Parent:GetFullName())
		end
	end
	local success, setTab = pcall(require, settingsModule)
	if success then
		data.Messages = setTab.Settings.Messages
	else
		warn("[DEVELOPER ERROR] Settings module errored while loading; Using defaults; Error Message: ", setTab)
		table.insert(data.Messages, {
			Title = "Warning!";
			Icon = "rbxassetid://7495468117";
			Message = "Settings module error detected; using default settings.";
			Time = 15;
		})
		setTab = {}
	end

	data.Settings = setTab.Settings
	data.Descriptions = setTab.Description
	data.Order = setTab.Order

	for _, module in pluginsFolder:GetChildren() do
		local name = string.lower(module.Name)
		
		if module:IsA("Folder") then
			table.insert(data.Packages, module)
			
		elseif string.match(name, "^client[%-:]") then
			table.insert(data.ClientPlugins, module)
			
		elseif string.match(name, "^server[%-:]") then
			table.insert(data.ServerPlugins, module)
			
		else
			warn("[DEVELOPER ERROR] Unknown Plugin Type for "..tostring(module).."; Plugin name should either start with 'Server:', 'Server-', 'Client:', or 'Client-'")
		end
	end

	for _, theme in themesFolder:GetChildren() do
		table.insert(data.Themes, theme)
	end

	if tonumber(moduleId) then
		warn("Requiring Adonis MainModule; Model URL: https://www.roblox.com/library/".. moduleId)
	end

	local module = require(moduleId)
	local response = module(data)

	if response == "SUCCESS" then
		if (data.Settings and data.Settings.HideScript) and not data.DebugMode and not RunService:IsStudio() then
			model.Parent = nil
			game:BindToClose(function()
				model.Parent = ServerScriptService
				model.Name = "Adonis_Loader"
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
