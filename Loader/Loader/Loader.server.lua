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
--          Edit settings using the Settings module in the Config folder        --
----------------------------------------------------------------------------------
--       This script loads the Adonis source (MainModule) into the game.        --
--            Only edit this script if you know what you're doing!              --
----------------------------------------------------------------------------------

local print = function(...) for i,v in pairs({...}) do warn(":: Adonis ServerLoader :: INFO: "..tostring(v)) end end
local error = function(...) for i,v in pairs({...}) do warn(":: Adonis ServerLoader :: ERROR: "..tostring(v).."; Traceback:\n"..debug.traceback()) end end
local warn = function(...) for i,v in pairs({...}) do warn(":: Adonis ServerLoader:: WARN: "..tostring(v)) end end
local pcall = function(func, ...) local ran, rerror = pcall(func, ...) if not ran then error(rerror) end return ran, rerror end
local AbortLoad = function(Reason) warn("Adonis aborted loading. Reason: "..tostring(Reason)) if script then script:Destroy() end return false end

if _G.__Adonis_MUTEX and type(_G.__Adonis_MUTEX)=="string" then
	return AbortLoad("\n-----------------------------------------------"
		.."\nAdonis is already running! Aborting..."
		.."\nRunning Location: ".._G.__Adonis_MUTEX
		.."\nThis Location: "..script:GetFullName()
		.."\n-----------------------------------------------")
end

--// Root Folder Instances
local Model = script.Parent.Parent
local Config = Model.Config
local Core = Model.Loader
local Backup = Model:Clone()
local OrigName = Model.Name

--// Core Instances
local Loader = Core.Loader
local Runner = script

--// Get Configuration Instances
local Settings = Config.Settings
local Plugins = Config.Plugins
local Themes = Config.Themes

--// Define valid Plugin Types
local PluginTypes = {"server:";"server-";"client-";"client:"}

local Data = {
	Settings = {};
	Descriptions = {};
	Order = {};
	ServerPlugins = {};
	ClientPlugins = {};
	Themes = {};
	StartTime = tick();
	
	Model = Model;
	Config = Config;
	Core = Core;
	
	Loader = Loader;
	Runner = Runner;
	
	ModuleID = 7510592873;  		--// https://www.roblox.com/library/7510592873/Adonis-MainModule
	LoaderID = 7510622625;			--// https://www.roblox.com/library/7510622625/Adonis-Loader-Sceleratis-Davey-Bones-Epix
		
	--// Note: The nightly module is updated frequently with ever commit merged to the master branch on the Adonis repo.
	--// It is prone to breaking, unstable, untested, and should not be used for anything other than testing/feature preview.
	NightlyMode = false;			--// If true, uses the nightly module instead of the current release module.
	NightlyModuleID = 8612978896; 	--// https://www.roblox.com/library/8612978896/Nightlies-Adonis-MainModule

	DebugMode = true;
}

local LoadPlugins = function()
	for _, Plugin in pairs(Plugins:GetChildren()) do
		local Type = tostring(Plugin.Name):lower():sub(1,7)
		if Plugin:IsA("ModuleScript") and table.find(PluginTypes, Type) then
			if Type:match("client") then
				table.insert(Data.ClientPlugins, Plugin)
			elseif Type:match("server") then
				table.insert(Data.ServerPlugins, Plugin)
			else
				warn("Unknown Plugin Type for: "..tostring(Plugin))
			end
		end
	end
end

local LoadThemes = function()
	for _, Theme in pairs(Themes:GetChildren()) do
		table.insert(Data.Themes, Theme)
	end
end

local Load = function()
	warn("Loading...")
	
	_G.__Adonis_MUTEX = script:GetFullName()
	script:Destroy()
	
	if not Data.DebugMode then
		Model.Name = math.random()
	end	
	
	local ModuleId = if Data.NightlyMode then Data.NightlyModuleID else Data.ModuleID
	local success, settings = pcall(require, Settings)

	if success then
		Data.Messages = setTab.Settings.Messages
	else
		warn("[DEVELOPER ERROR] Settings module errored while loading; Using defaults; Error Message: ", setTab)
		table.insert(Data.Messages, {
			Title = "Warning!";
			Icon = "rbxassetid://7495468117";
			Message = "Settings module error detected; using default settings.";
			Time = 15;
		})
		setTab = {}
	end
	
	if not success then
		warn("Settings module failed to load; Using defaults;")
		settings = {}
	end
	
	Data.Settings, Data.Descriptions, Data.Order = setTab.Settings, setTab.Descriptions, setTab.Order
	LoadPlugins()
	LoadThemes()
	
	local Adonis = require(ModuleID)
	local Loaded, Response = Adonis(Data)
	
	if Loaded == true then
		if (Data.Settings and Data.Settings.HideScript) and not Data.DebugMode then
			Model.Parent = nil
			game:BindToClose(function()
				Model.Parent = game:GetService("ServerScriptService")
				Model.Name = OrigName
			end)
		end
		
		Model.Name = OrigName
	else
		return AbortLoad("MainModule failed to load. Responded with: "..tostring(Response))
	end
	
	return Loaded
end

pcall(Load)

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
