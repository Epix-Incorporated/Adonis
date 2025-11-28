local settingsInfo = {}

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals


function settingsInfo.initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	--API = data.API
	--RMD = data.RMD
	--env = data.env
	--service = data.service
	--plr = data.plr
	--create = data.create
	--createSimple = data.createSimple
end


-- Register Setting
local function RegisterSetting(categoryTable, settingName, data)
	categoryTable.Info[settingName] = data
	
	table.insert(categoryTable.Order, settingName)
end

--[[
Example Settings

-- this is the basic setup
settingInfo.CategoryName


]]

-- The order here, defines the order on how they show up
settingsInfo._Categories = {
	--"Main",
	"Explorer",
	"Properties",
	"Theme",
}

-- TODO: Use "DefaultSettings" for default values perhaps

settingsInfo.Main = {}
settingsInfo.Main.Info = {}
settingsInfo.Main.Order = {}

--[[RegisterSetting(settingsInfo["Main"], "ResetOnSpawn", {
	desc = "Whether to reset the UI on spawn.";
	defaultVal = true;
	typeName = "boolean";

	OnChange = function(newValue)
		Settings.Main.ResetOnSpawn = newValue
		
		if (Main.LocalScript_Gui) then
			Main.LocalScript_Gui.ResetOnSpawn = newValue
		end
		
		if (Main.MainGui) then
			Main.MainGui.ResetOnSpawn = newValue
		end
		
		if (Lib.SidesGui) then
			Lib.SidesGui.ResetOnSpawn = newValue
		end
		
		if (Lib.StoredWindows) then
			for k,v in pairs(Lib.StoredWindows) do
				if (v.Gui) then
					v.Gui.ResetOnSpawn = newValue
				end
			end
		end
	end;
})]]



settingsInfo.Explorer = {}
settingsInfo.Explorer.Info = {}
settingsInfo.Explorer.Order = {}



-- Example Setting
RegisterSetting(settingsInfo.Explorer, "Sorting", {
	desc = nil;
	defaultVal = true;
	typeName = "boolean";

	OnChange = function(newValue)
		Apps.Explorer.SetSortingEnabled(newValue)
	end;
})


RegisterSetting(settingsInfo.Explorer, "TeleportToOffset", {
	desc = "Offset when teleporting to Instances";
	defaultVal = Vector3.new(0,0,0);
	typeName = "Vector3";
})

RegisterSetting(settingsInfo.Explorer, "ClickToSelect", {
	desc = "Whether clicking will select parts";
	defaultVal = false;
	typeName = "boolean";
	
	OnChange = function(newValue)
		Settings.Explorer.ClickToSelect = newValue
		Apps.Explorer.InitClickToSelect()
	end,
})


--[[RegisterSetting(settingsInfo.Explorer, "ClickToRename", {
	desc = "ClickToRename";
	defaultVal = true;
	typeName = "boolean";
})]]


RegisterSetting(settingsInfo.Explorer, "AutoUpdateSearch", {
	desc = nil;
	defaultVal = true;
	typeName = "boolean";
})


--[[RegisterSetting(settingsInfo.Explorer, "AutoUpdateMode", {
	desc = "0 Default, 1 no tree update, 2 no descendant events, 3 frozen";
	defaultVal = 0;
	typeName = "number";
})]]


RegisterSetting(settingsInfo.Explorer, "PartSelectionBox", {
	desc = "Toggle Selection Box on Objects";
	defaultVal = true;
	typeName = "boolean";
})

RegisterSetting(settingsInfo.Explorer, "GuiSelectionBox", {
	desc = "Toggle Selection Box on GUIs";
	defaultVal = true;
	typeName = "boolean";
})

RegisterSetting(settingsInfo.Explorer, "CopyPathUseGetChildren", {
	desc = nil;
	defaultVal = true;
	typeName = "boolean";
})




settingsInfo.Properties = {}
settingsInfo.Properties.Info = {}
settingsInfo.Properties.Order = {}

RegisterSetting(settingsInfo.Properties, "MaxConflictCheck", {
	desc = nil;
	defaultVal = 50;
	typeName = "number";
})


RegisterSetting(settingsInfo.Properties, "ShowDeprecated", {
	desc = nil;
	defaultVal = false;
	typeName = "boolean";
})

RegisterSetting(settingsInfo.Properties, "ShowHidden", {
	desc = nil;
	defaultVal = false;
	typeName = "boolean";
})


RegisterSetting(settingsInfo.Properties, "NumberRounding", {
	desc = nil;
	defaultVal = 3;
	typeName = "number";
})


RegisterSetting(settingsInfo.Properties, "ShowAttributes", {
	desc = nil;
	defaultVal = false;
	typeName = "boolean";
})


RegisterSetting(settingsInfo.Properties, "MaxAttributes", {
	desc = nil;
	defaultVal = 50;
	typeName = "number";
})


RegisterSetting(settingsInfo.Properties, "ScaleType", {
	desc = "0 Full Name Shown, 1 Equal Halves";
	defaultVal = 1;
	typeName = "number";
})


settingsInfo.Theme = {}
settingsInfo.Theme.Info = {}
settingsInfo.Theme.Order = {}

local rgb = Color3.fromRGB

RegisterSetting(settingsInfo.Theme, "Main1", {
	desc = nil;
	defaultVal = rgb(52,52,52);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Main2", {
	desc = nil;
	defaultVal = rgb(45,45,45);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Outline1", {
	desc = "Mainly frames";
	defaultVal = rgb(33,33,33);
	typeName = "Color3";
})
RegisterSetting(settingsInfo.Theme, "Outline2", {
	desc = "Mainly button";
	defaultVal = rgb(55,55,55);
	typeName = "Color3";
})
RegisterSetting(settingsInfo.Theme, "Outline3", {
	desc = "Mainly textbox";
	defaultVal = rgb(30,30,30);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "TextBox", {
	desc = nil;
	defaultVal = rgb(38,38,38);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Menu", {
	desc = nil;
	defaultVal = rgb(32,32,32);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "ListSelection", {
	desc = nil;
	defaultVal = rgb(11,90,175);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Button", {
	desc = nil;
	defaultVal = rgb(60,60,60);
	typeName = "Color3";
})
RegisterSetting(settingsInfo.Theme, "ButtonHover", {
	desc = nil;
	defaultVal = rgb(68,68,68);
	typeName = "Color3";
})
RegisterSetting(settingsInfo.Theme, "ButtonPress", {
	desc = nil;
	defaultVal = rgb(40,40,40);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Highlight", {
	desc = nil;
	defaultVal = rgb(75,75,75);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Text", {
	desc = nil;
	defaultVal = rgb(255,255,255);
	typeName = "Color3";
})
RegisterSetting(settingsInfo.Theme, "PlaceholderText", {
	desc = nil;
	defaultVal = rgb(100,100,100);
	typeName = "Color3";
})

RegisterSetting(settingsInfo.Theme, "Important", {
	desc = nil;
	defaultVal = rgb(255,0,0);
	typeName = "Color3";
})



return settingsInfo