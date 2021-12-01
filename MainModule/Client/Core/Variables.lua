client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function()
	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = service
	local client = client
	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		Variables.Init = nil;
	end

	local function RunAfterLoaded()
		--// Get CodeName
		client.Variables.CodeName = client.Remote.Get("Variable", "CodeName")

		Variables.RunAfterLoaded = nil;
	end

	local function RunLast()
		--[[client = service.ReadOnly(client, {
				[client.Variables] = true;
				[client.Handlers] = true;
				G_API = true;
				G_Access = true;
				G_Access_Key = true;
				G_Access_Perms = true;
				Allowed_API_Calls = true;
				HelpButtonImage = true;
				Finish_Loading = true;
				RemoteEvent = true;
				ScriptCache = true;
				Returns = true;
				PendingReturns = true;
				EncodeCache = true;
				DecodeCache = true;
				Received = true;
				Sent = true;
				Service = true;
				Holder = true;
				GUIs = true;
				LastUpdate = true;
				RateLimits = true;

				Init = true;
				RunLast = true;
				RunAfterInit = true;
				RunAfterLoaded = true;
				RunAfterPlugins = true;
			}, true)--]]

			Variables.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.GUIs = {}
	client.GUIHolder = service.New("Folder")
	client.Variables = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		CodeName = "";
		UIKeepAlive = true;
		KeybindsEnabled = true;
		ParticlesEnabled = true;
		CapesEnabled = true;
		HideChatCommands = false;
		PrivacyMode = false;
		Particles = {};
		KeyBinds = {};
		Aliases = {};
		Capes = {};
		savedUI = {};
		localSounds = {};
		ESPObjects = {};
		CommunicationsHistory = {};
		LightingSettings = {
			Ambient = service.Lighting.Ambient;
			Brightness = service.Lighting.Brightness;
			ColorShift_Bottom = service.Lighting.ColorShift_Bottom;
			ColorShift_Top = service.Lighting.ColorShift_Top;
			GlobalShadows = service.Lighting.GlobalShadows;
			OutdoorAmbient = service.Lighting.OutdoorAmbient;
			Outlines = service.Lighting.Outlines;
			ShadowColor = service.Lighting.ShadowColor;
			GeographicLatitude = service.Lighting.GeographicLatitude;
			Name = service.Lighting.Name;
			TimeOfDay = service.Lighting.TimeOfDay;
			FogColor = service.Lighting.FogColor;
			FogEnd = service.Lighting.FogEnd;
			FogStart = service.Lighting.FogStart;
		}
	};
end
