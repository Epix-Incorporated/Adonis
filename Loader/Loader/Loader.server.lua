--[[

	DEVELOPMENT HAS BEEN MOVED FROM DAVEY_BONES/SCELERATIS TO THE EPIX INCORPORATED GROUP

	CURRENT LOADER:
	https://www.roblox.com/library/7510622625/Adonis-Loader-Sceleratis-Davey-Bones-Epix

	CURRENT MODULE:
	https://www.roblox.com/library/7510592873/Adonis-MainModule

--]]




----------------------------------------------------------------------------------------
--                                  Adonis Loader                                     --
----------------------------------------------------------------------------------------
--		   	  Epix Incorporated. Not Everything is so Black and White.    --
----------------------------------------------------------------------------------------
--	    Edit settings in-game or using the settings module in the Config folder   --
----------------------------------------------------------------------------------------
--	                  This is not designed to work in solo mode                   --
----------------------------------------------------------------------------------------

local warn = function(...)
	warn(":: Adonis ::", ...)
end

warn("Loading...");

if rawget(_G, "__Adonis_MUTEX") and type(rawget(_G, "__Adonis_MUTEX")) == "string" then
	warn("Adonis is already running! Aborting...; Running Location:", rawget(_G, "__Adonis_MUTEX"), "This Location:", script:GetFullName())
else
	if table.isfrozen and not table.isfrozen(_G) or not table.isfrozen then
		rawset(_G, "__Adonis_MUTEX", script:GetFullName())
	else
		warn("The _G table is locked, Adonis can't detect if there are other loaders already running!; If you are seeing issues with multiple Adonis instances please unlock the _G table!")
	end

	local model = script.Parent.Parent
	local config = model.Config
	local core = model.Loader

	local dropper = core.Dropper
	local loader = core.Loader
	local runner = script

	local settings = config.Settings
	local plugins = config.Plugins
	local themes = config.Themes

	local backup = model:Clone()

	local data = {
		Settings = {};
		Descriptions = {};
		ServerPlugins = {};
		ClientPlugins = {};
		Packages = {};
		Themes = {};

		ModelParent = model.Parent;
		Model = model;
		Config = config;
		Core = core;

		Loader = loader;
		Dopper = dropper;
		Runner = runner;

		ModuleID = 7510592873;  --// https://www.roblox.com/library/7510592873/Adonis-MainModule
		LoaderID = 7510622625;	--// https://www.roblox.com/library/7510622625/Adonis-Loader-Sceleratis-Davey-Bones-Epix

		DebugMode = true;
	}

	--// Init
	script:Destroy()
	model.Name = math.random()

	local moduleId = data.ModuleID
	if data.DebugMode then
		moduleId = model.Parent.MainModule
	end

	local success, setTab = pcall(require, settings)
	if not success then
		warn("Settings module errored while loading; Using defaults; Error Message: ", setTab)
		setTab = {}
	end

	data.Settings = setTab.Settings;
	data.Descriptions = setTab.Description;
	data.Order = setTab.Order;

	for _, Plugin in ipairs(plugins:GetChildren()) do
		if Plugin:IsA("Folder") then
			table.insert(data.Packages, Plugin)
		elseif string.sub(string.lower(Plugin.Name), 1, 7) == "client:" or string.sub(string.lower(Plugin.Name), 1, 7) == "client-" then
			table.insert(data.ClientPlugins, Plugin)
		elseif string.sub(string.lower(Plugin.Name), 1, 7) == "server:" or string.sub(string.lower(Plugin.Name), 1, 7) == "server-" then
			table.insert(data.ServerPlugins, Plugin)
		else
			warn("Unknown Plugin Type for "..tostring(Plugin).."; Plugin name should either start with server:, server-, client:, or client-")
		end
	end

	for _, Theme in ipairs(themes:GetChildren()) do
		table.insert(data.Themes, Theme)
	end

	if tonumber(moduleId) then
		warn("Requiring Adonis MainModule. Expand for model URL > ", {URL = "https://www.roblox.com/library/".. moduleId})
	end

	local module = require(moduleId)
	local response = module(data)

	if response == "SUCCESS" then
		if (data.Settings and data.Settings.HideScript) and not data.DebugMode and not game:GetService("RunService"):IsStudio() then
			model.Parent = nil
			game:BindToClose(function() model.Parent = game:GetService("ServerScriptService") model.Name = "Adonis_Loader" end)
		end

		model.Name = "Adonis_Loader"
	else
		error(" !! MainModule failed to load !! ")
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
