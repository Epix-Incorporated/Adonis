--[[

	CURRENT LOADER:
	https://www.roblox.com/library/2373505175/Adonis-Loader-BETA

--]]




----------------------------------------------------------------------------------------
--                                  Adonis Loader                                     --
----------------------------------------------------------------------------------------
--		   	  Epix Incorporated. Not Everything is so Black and White.		   		 			  --
----------------------------------------------------------------------------------------
--	    Edit settings in-game or using the settings module in the Config folder	      --
----------------------------------------------------------------------------------------
--	                  This is not designed to work in solo mode                       --
----------------------------------------------------------------------------------------

warn(":: Adonis :: Loading...");

if _G["__Adonis_MUTEX"] and type(_G["__Adonis_MUTEX"])=="string" then
	warn("\n-----------------------------------------------"
		.."\nAdonis is already running! Aborting..."
		.."\nRunning Location: ".._G["__Adonis_MUTEX"]
		.."\nThis Location: "..script:GetFullName()
		.."\n-----------------------------------------------")
	--script:Destroy()
else
	_G["__Adonis_MUTEX"] = script:GetFullName()

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
		Themes = {};

		ModelParent = model.Parent;
		Model = model;
		Config = config;
		Core = core;

		Loader = loader;
		Dopper = dropper;
		Runner = runner;

		ModuleID = tonumber('23735'..'01710'); --// Trying to break existing (unupdatable) malicious plugins that replace the ModuleID from studio on insertion
		LoaderID = tonumber('23735'..'05175');

		DebugMode = true;
	}

	--// Init
	script:Destroy()
	model.Name = math.random()
	local moduleId = data.ModuleID
	local a,setTab = pcall(require,settings)
	if not a then
		warn'::Adonis:: Settings module errored while loading; Using defaults;'
		setTab = {}
	end
	data.Settings, data.Descriptions, data.Order = setTab.Settings,setTab.Descriptions,setTab.Order
	for _,Plugin in next,plugins:GetChildren()do if Plugin.Name:lower():sub(1,7)=="client:" or Plugin.Name:lower():sub(1,7) == "client-" then table.insert(data.ClientPlugins,Plugin) elseif Plugin.Name:lower():sub(1,7)=="server:" or Plugin.Name:lower():sub(1,7)=="server-" then table.insert(data.ServerPlugins,Plugin) else warn("Unknown Plugin Type for "..tostring(Plugin)) end end
	for _,Theme in next,themes:GetChildren()do table.insert(data.Themes,Theme) end
	if data.DebugMode then moduleId = model.Parent.MainModule end
	local module = require(moduleId)
	local response = module(data)
	if response == "SUCCESS" then
		if (data.Settings and data.Settings.HideScript) and not data.DebugMode and not game:GetService("RunService"):IsStudio() then
			model.Parent = nil
			game:BindToClose(function() model.Parent = game:GetService("ServerScriptService") model.Name = "Adonis_Loader" end)
		end

		model.Name = "Adonis_Loader"
	else
		error("MainModule failed to load")
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
