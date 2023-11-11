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

		for _, v in Settings.MusicList or {} do table.insert(Variables.MusicList, v) end
		for _, v in Settings.InsertList or {} do table.insert(Variables.InsertList, v) end
		for _, v in Settings.CapeList or {} do table.insert(Variables.Capes, v) end

		Variables.Init = nil
		Logs:AddLog("Script", "Variables Module Initialized")
	end

	local function AfterInit(data)
		server.Variables.CodeName = service.HttpService:GenerateGUID(false)

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
		PlayerJoinFilters = {};
		LockMessage = "Not Whitelisted",
		DonorPass = {1348327, 1990427, 1911740, 167686, 98593, "6878510605", 5212082, 5212081}, --// Strings are items; numbers are gamepasses
		WebPanel_Initiated = false,
		AnimatedFaces = {
			11822739674, 12936650534, 12936972483, 12937095639, 12937204578, 12939347925, 12945410659, 12946305202, 12954264879, 12992668217, 13675083217,
			13675180453, 13675522887, 13682064263, 13682077493, 13682108684, 13691995281, 13692793711, 13692942131, 13692947484, 13692956122, 13692975981,
			13702615195, 13693003885, 13692999952, 13820744684, 14193299178, 14474232253, 14478101144, 14478328247, 14483837205, 14484001930, 14525047012,
			14525311372, 14532846222, 14719537379, 13702692127, 13820838786, 13821263793, 13821330310, 13821486499, 13822633229, 13822758815, 13823067122,
			13823254076, 13823337209, 14193509240, 14193559599, 14193608834, 14193662834, 14193774321, 14193899807, 14205261998, 14205289572, 10687288296,
			10638267973, 10723855306, 10725626210, 10725826963, 11159990982, 11163789916, 11180212350, 11236434712, 11244608373, 11308682721, 11308884165,
			11308945948
		},
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
		
		AtmosphereSettings = {},

		OriginalAtmosphereSettings = {},

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

		TrackingTable = {};

		DisguiseBindings = {};

		IncognitoPlayers = {};

		MusicList = {
			{Name = "crabrave", 				ID = 5410086218},
			{Name = "shiawase", 				ID = 5409360995},
			{Name = "unchartedwaters", 			ID = 7028907200},
			{Name = "glow", 				ID = 7028856935},
			{Name = "good4me", 				ID = 7029051434},
			{Name = "bloom", 				ID = 7029024726},
			{Name = "safe&sound", 				ID = 7024233823},
			{Name = "shaku", 				ID = 7024332460},
			{Name = "fromdust&ashes", 			ID = 7024254685},
			{Name = "loveis", 				ID = 7029092469},
			{Name = "playitcool", 				ID = 7029017448},
			{Name = "still", 				ID = 7023771708},
			{Name = "sleep", 				ID = 7023407320},
			{Name = "whatareyouwaitingfor", 		ID = 7028977687},
			{Name = "balace", 				ID = 7024183256},
			{Name = "brokenglass", 				ID = 7028799370},
			{Name = "thelanguageofangels", 			ID = 7029031068},
			{Name = "imprints", 				ID = 7023704173},
			{Name = "foundareason", 			ID = 7028919492},
			{Name = "newhorizons", 				ID = 7028518546},
			{Name = "whatsitlike", 				ID = 7028997537},
			{Name = "destroyme",				ID = 7023617400},
			{Name = "consellations", 			ID = 7023733671},
			{Name = "wish", 				ID = 7023670701},
			{Name = "samemistake", 				ID = 7024101188},
			{Name = "whereibelong", 			ID = 7028527348},
			{Name = "rainingtacos", 			ID = 142376088},
		};

		InsertList = {};

		Capes = {
			{Name = "crossota", 	Material = "Neon", 	Color = "Cyan", 			ID = 420260457},
			{Name = "jamiejr99", 	Material = "Neon", 	Color = "Cashmere",			ID = 429297485},
			{Name = "new yeller", 	Material = "Fabric", 	Color = "New Yeller"},
			{Name = "pastel blue", 	Material = "Fabric", 	Color = "Pastel Blue"},
			{Name = "dusty rose", 	Material = "Fabric", 	Color = "Dusty Rose"},
			{Name = "cga brown", 	Material = "Fabric", 	Color = "CGA brown"},
			{Name = "random", 	Material = "Fabric", 	Color = (BrickColor.random()).Name},
			{Name = "shiny", 	Material = "Plastic", 	Color = "Institutional white",		Reflectance = 1},
			{Name = "gold",		Material = "Plastic", 	Color = "Bright yellow",		Reflectance = 0.4},
			{Name = "kohl",		Material = "Fabric", 	Color = "Really black", 		ID = 108597653},
			{Name = "script", 	Material = "Plastic", 	Color = "White", 			ID = 151359194},
			{Name = "batman", 	Material = "Fabric", 	Color = "Institutional white", 		ID = 108597669},
			{Name = "epix", 	Material = "Plastic", 	Color = "Really black", 		ID = 149442745},
			{Name = "superman", 	Material = "Fabric", 	Color = "Bright blue", 			ID = 108597677},
			{Name = "swag", 	Material = "Fabric", 	Color = "Pink", 			ID = 109301474},
			{Name = "donor", 	Material = "Plastic", 	Color = "White", 			ID = 149009184},
			{Name = "gomodern", 	Material = "Plastic", 	Color = "Really black", 		ID = 149438175},
			{Name = "admin", 	Material = "Plastic", 	Color = "White", 			ID = 149092195},
			{Name = "giovannis", 	Material = "Plastic", 	Color = "White", 			ID = 149808729},
			{Name = "godofdonuts", 	Material = "Plastic", 	Color = "Institutional white",		ID = 151034443},
			{Name = "host", 	Material = "Plastic", 	Color = "Really black", 		ID = 152299000},
			{Name = "cohost", 	Material = "Plastic", 	Color = "Really black", 		ID = 152298950},
			{Name = "trainer",	Material = "Plastic", 	Color = "Really black", 		ID = 152298976},
			{Name = "ba", 		Material = "Plastic", 	Color = "White", 			ID = 172528001}
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
