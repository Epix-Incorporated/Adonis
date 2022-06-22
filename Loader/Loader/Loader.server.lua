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

local function warn(...)
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
	mutex.Value = script:GetFullName()
	mutex.Parent = RunService

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
		Messages = {};
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

	-- selene: allow(incorrect_standard_library_use)
	script.Parent = nil --script:Destroy()
	model.Name = math.random()

	local moduleId = data.ModuleID
	if data.DebugMode then
		moduleId = model.Parent.MainModule
	end
	local success, setTab = pcall(require, settings)
	if success then
		data.Messages = setTab.Settings.Messages
	else
		warn("[DEVELOPER ERROR] Settings module errored while loading; Using defaults; Error Message: ", setTab)
		table.insert(data.Messages, {
			Title = "Warning!";
			Message = "Settings module error detected. Using default settings.";
			Time = 15;
		})
		setTab = {}
	end

	data.Settings = setTab.Settings
	data.Descriptions = setTab.Description
	data.Order = setTab.Order

	for _, plugin in ipairs(plugins:GetChildren()) do
		if plugin:IsA("Folder") then
			table.insert(data.Packages, plugin)
		elseif plugin.Name:lower():match("^client[%-:]") then
			table.insert(data.ClientPlugins, plugin)
		elseif plugin.Name:lower():match("^server[%-:]") then
			table.insert(data.ServerPlugins, plugin)
		else
			warn("[DEVELOPER ERROR] Unknown Plugin Type for "..tostring(Plugin).."; Plugin name should either start with 'Server:', 'Server-', 'Client:', or 'Client-'")
		end
	end

	for _, theme in ipairs(themes:GetChildren()) do
		table.insert(data.Themes, theme)
	end

	if tonumber(moduleId) then
		warn("Requiring Adonis MainModule. Model URL: https://www.roblox.com/library/".. moduleId)
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
