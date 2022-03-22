server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions
		Admin = server.Admin
		Anti = server.Anti
		Core = server.Core
		HTTP = server.HTTP
		Logs = server.Logs
		Remote = server.Remote
		Process = server.Process
		Variables = server.Variables
		Settings = server.Settings

		Variables.BanMessage = Settings.BanMessage
		Variables.LockMessage = Settings.LockMessage

		for _, v in ipairs(Settings.MusicList or {}) do table.insert(Variables.MusicList, v) end
		for _, v in ipairs(Settings.InsertList or {}) do table.insert(Variables.InsertList, v) end
		for _, v in ipairs(Settings.CapeList or {}) do table.insert(Variables.Capes, v) end

		Variables.Init = nil
		Logs:AddLog("Script", "Variables Module Initialized")
	end

	local function AfterInit(data)
		server.Variables.CodeName = server.Functions:GetRandom()

		Variables.RunAfterInit = nil
		Logs:AddLog("Script", "Finished Variables AfterInit")
	end

	local Lighting = service.Lighting
	server.Variables = {
		Init = Init,
		RunAfterInit = AfterInit,
		ZaWarudo = false,
		CodeName = math.random(),
		IsStudio = service.RunService:IsStudio(), -- Used to check if Adonis is running inside Roblox Studio as things like TeleportService and DataStores (if API Access is disabled) do not work in Studio
		AuthorizedToReply = {},
		FrozenObjects = {},
		ScriptBuilder = {},
		CachedDonors = {},
		BanMessage = "Banned",
		LockMessage = "Not Whitelisted",
		DonorPass = {1348327, 1990427, 1911740, 167686, 98593, "6878510605", 5212082, 5212081}, --// Strings are items, numbers are gamepasses
		WebPanel_Initiated = false,
		LightingSettings = {
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness,
			TimeOfDay = Lighting.TimeOfDay,
			FogColor = Lighting.FogColor,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
			GlobalShadows = Lighting.GlobalShadows,
			Outlines = Lighting.Outlines,
			ShadowColor = Lighting.ShadowColor,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			ColorShift_Top = Lighting.ColorShift_Top,
			GeographicLatitude = Lighting.GeographicLatitude,
			Name = Lighting.Name,
		},

		OriginalLightingSettings = {
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness,
			TimeOfDay = Lighting.TimeOfDay,
			FogColor = Lighting.FogColor,
			FogEnd = Lighting.FogEnd,
			FogStart = Lighting.FogStart,
			GlobalShadows = Lighting.GlobalShadows,
			Outlines = Lighting.Outlines,
			ShadowColor = Lighting.ShadowColor,
			ColorShift_Bottom = Lighting.ColorShift_Bottom,
			ColorShift_Top = Lighting.ColorShift_Top,
			GeographicLatitude = Lighting.GeographicLatitude,
			Name = Lighting.Name,
			Sky = Lighting:FindFirstChildOfClass("Sky") and Lighting:FindFirstChildOfClass("Sky"):Clone(),
		},

		PMtickets = {};

		HelpRequests = {};

		Objects = {};

		InsertedObjects = {};

		CommandLoops = {};

		SavedTools = {};

		Waypoints = {};

		Cameras = {};

		Jails = {};

		LocalEffects = {};

		SizedCharacters = {};

		BundleCache = {};

		TrackingTable = {};

		DisguiseBindings = {};

		IncognitoPlayers = {};

		MusicList = {
			{Name = "epic", 	ID = 27697743}, -- Zero Project - Gothic
			{Name = "halo", 	ID = 1034065}, -- Halo Theme
			{Name = "cursed", 	ID = 1372257}, -- Cursed Abbey
			{Name = "extreme", 	ID = 11420933}, -- TOPW
			{Name = "awaken", 	ID = 27697277}, -- Positively Dark - Awakening
			{Name = "mario", 	ID = 1280470}, -- SM64 Theme
			{Name = "chrono", 	ID = 1280463}, -- Chrono Trigger Theme
			{Name = "dotr", 	ID = 11420922}, -- DOTR | ▼ --- ▼ I do not speak tags
			{Name = "entertain", ID = 27697267}, -- ##### ###### - Entertainer Rag
			{Name = "fantasy", 	ID = 1280473}, -- FFVII Battle AC
			{Name = "final", 	ID = 1280414}, -- Final Destination
			{Name = "emblem", 	ID = 1372259}, -- Fire Emblem
			{Name = "flight", 	ID = 27697719}, -- Daniel Bautista - Flight of the Bumblebee
			{Name = "gothic", 	ID = 27697743}, -- Zero Project - Gothic
			{Name = "hiphop", 	ID = 27697735}, -- Jeff Syndicate - Hip Hop
			{Name = "intro", 	ID = 27697707}, -- Daniel Bautista - Intro
			{Name = "mule", 	ID = 1077604}, -- M.U.L.E
			{Name = "film", 	ID = 27697713}, -- Daniel Bautista - Music for a Film
			{Name = "schala", 	ID = 5985787}, -- Schala
			{Name = "tunnel",	ID = 9650822}, -- S4Tunnel
			{Name = "spanish", 	ID = 5982975}, -- TheBuzzer
			{Name = "venom", 	ID = 1372262}, -- Star Fox Theme
			{Name = "guitar", 	ID = 5986151}, -- 5986151
			{Name = "crabrave", 	ID = 5410086218}, -- Noisestorm - Crab Rave
		};

		InsertList = {};

		Capes = {
			{Name = "crossota", 	Material = "Neon", 		Color = "Cyan", 				ID = 420260457},
			{Name = "jamiejr99", 	Material = "Neon", 		Color = "Cashmere",				ID = 429297485},
			{Name = "new yeller", 	Material = "Fabric", 	Color = "New Yeller"},
			{Name = "pastel blue", 	Material = "Fabric", 	Color = "Pastel Blue"},
			{Name = "dusty rose", 	Material = "Fabric", 	Color = "Dusty Rose"},
			{Name = "cga brown", 	Material = "Fabric", 	Color = "CGA brown"},
			{Name = "random", 		Material = "Fabric", 	Color = (BrickColor.random()).Name},
			{Name = "shiny", 		Material = "Plastic", 	Color = "Institutional white",	Reflectance = 1},
			{Name = "gold",			Material = "Plastic", 	Color = "Bright yellow",		Reflectance = 0.4},
			{Name = "kohl",			Material = "Fabric", 	Color = "Really black", 		ID = 108597653},
			{Name = "script", 		Material = "Plastic", 	Color = "White", 				ID = 151359194},
			{Name = "batman", 		Material = "Fabric", 	Color = "Institutional white", 	ID = 108597669},
			{Name = "epix", 		Material = "Plastic", 	Color = "Really black", 		ID = 149442745},
			{Name = "superman", 	Material = "Fabric", 	Color = "Bright blue", 			ID = 108597677},
			{Name = "swag", 		Material = "Fabric", 	Color = "Pink", 				ID = 109301474},
			{Name = "donor", 		Material = "Plastic", 	Color = "White", 				ID = 149009184},
			{Name = "gomodern", 	Material = "Plastic", 	Color = "Really black", 		ID = 149438175},
			{Name = "admin", 		Material = "Plastic", 	Color = "White", 				ID = 149092195},
			{Name = "giovannis", 	Material = "Plastic", 	Color = "White", 				ID = 149808729},
			{Name = "godofdonuts", 	Material = "Plastic", 	Color = "Institutional white",	ID = 151034443},
			{Name = "host", 		Material = "Plastic", 	Color = "Really black", 		ID = 152299000},
			{Name = "cohost", 		Material = "Plastic", 	Color = "Really black", 		ID = 152298950},
			{Name = "trainer",	 	Material = "Plastic", 	Color = "Really black", 		ID = 152298976},
			{Name = "ba", 			Material = "Plastic", 	Color = "White", 				ID = 172528001}
		};

		Blacklist = {
			Enabled = (server.Settings.BlacklistEnabled ~= nil and server.Settings.BlacklistEnabled) or true,
			Lists = {
				Settings = server.Settings.Blacklist
			},
		};

		Whitelist = {
			Enabled = server.Settings.WhitelistEnabled,
			Lists = {
				Settings = server.Settings.Whitelist
			},
		};
	}
end

