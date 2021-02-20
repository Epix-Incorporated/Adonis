--[[
	
	CURRENT LOADER:
	https://www.roblox.com/library/2373505175/Adonis-Loader-BETA
	
--]]




----------------------------------------------------------------------------------------
--                                  Adonis Loader                                     --
----------------------------------------------------------------------------------------
--		   	  Epix Incorporated. Not Everything is so Black and White.		   		  --
----------------------------------------------------------------------------------------
--	    Edit settings in-game or using the settings module in the Config folder	      --
----------------------------------------------------------------------------------------
--	                  This is not designed to work in solo mode                       --
----------------------------------------------------------------------------------------

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
local Config = Model.Configuration
local Core = Model.Loader
local Backup = Model:Clone()
local OrigName = Model.Name

--// Core Instances
local Dropper = Core.Dropper
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
	Dropper = Dropper;
	Runner = Runner;
	
	ModuleID = tonumber('23735'..'01710'); --// Trying to break existing (unupdatable) malicious plugins that replace the ModuleID from studio on insertion
	LoaderID = tonumber('23735'..'05175');
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
	
	Model.Name = math.random()
	
	local ModuleID = Data.ModuleID
	local success, settings = pcall(require, Settings)
	
	if not success then
		warn("Settings module failed to load; Using defaults;")
		settings = {}
	end
	
	Data.Settings, Data.Descriptions, Data.Order = settings.Settings, settings.Descriptions, settings.Order
	LoadPlugins()
	LoadThemes()
	
	local Adonis = require(ModuleID)
	local Loaded, Response = Adonis(Data)
	
	if Loaded == true then
		if (Data.Settings and Data.Settings.HideScript) and not Data.Settings.Debug then
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






