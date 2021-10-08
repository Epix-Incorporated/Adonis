server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;

		Variables.BanMessage = Settings.BanMessage
		Variables.LockMessage = Settings.LockMessage


		for ind, music in next, Settings.MusicList or {} do table.insert(Variables.MusicList, music) end
		for ind, music in next, Settings.InsertList or {} do table.insert(Variables.InsertList, music) end
		for ind, cape in next, Settings.CapeList or {} do table.insert(Variables.Capes, cape) end

		Variables.Init = nil;
		Logs:AddLog("Script", "Variables Module Initialized")
	end;

	local function AfterInit(data)
		server.Variables.CodeName = server.Functions:GetRandom()

		Variables.RunAfterInit = nil;
		Logs:AddLog("Script", "Finished Variables AfterInit");
	end

	local Lighting = service.Lighting
	server.Variables = {
		Init = Init;
		RunAfterInit = AfterInit;
		ZaWarudo = false;
		CodeName = math.random();
		IsStudio = service.RunService:IsStudio(); --Used to check if Adonis is running inside Roblox Studio as things like TeleportService and DataStores (if API Access is disabled) do not work in Studio
		AuthorizedToReply = {};
		FrozenObjects = {};
		ScriptBuilder = {};
		CachedDonors = {};
		BanMessage = "Banned";
		LockMessage = "Not Whitelisted";
		DonorPass = {1348327, 1990427, 1911740, 167686, 98593, "6878510605"}; --// Strings are items, numbers are gamepasses
		WebPanel_Initiated = false;
		LightingSettings = {
			Ambient = Lighting.Ambient;
			OutdoorAmbient = Lighting.OutdoorAmbient;
			Brightness = Lighting.Brightness;
			TimeOfDay = Lighting.TimeOfDay;
			FogColor = Lighting.FogColor;
			FogEnd = Lighting.FogEnd;
			FogStart = Lighting.FogStart;
			GlobalShadows = Lighting.GlobalShadows;
			Outlines = Lighting.Outlines;
			ShadowColor = Lighting.ShadowColor;
			ColorShift_Bottom = Lighting.ColorShift_Bottom;
			ColorShift_Top = Lighting.ColorShift_Top;
			GeographicLatitude = Lighting.GeographicLatitude;
			Name = Lighting.Name;
		};

		OriginalLightingSettings = {
			Ambient = Lighting.Ambient;
			OutdoorAmbient = Lighting.OutdoorAmbient;
			Brightness = Lighting.Brightness;
			TimeOfDay = Lighting.TimeOfDay;
			FogColor = Lighting.FogColor;
			FogEnd = Lighting.FogEnd;
			FogStart = Lighting.FogStart;
			GlobalShadows = Lighting.GlobalShadows;
			Outlines = Lighting.Outlines;
			ShadowColor = Lighting.ShadowColor;
			ColorShift_Bottom = Lighting.ColorShift_Bottom;
			ColorShift_Top = Lighting.ColorShift_Top;
			GeographicLatitude = Lighting.GeographicLatitude;
			Name = Lighting.Name;
			Sky = Lighting:FindFirstChildOfClass("Sky") and Lighting:FindFirstChildOfClass("Sky"):Clone();
		};

		HelpRequests = {};

		Objects = {};

		InsertedObjects = {};

		CommandLoops = {};

		Waypoints = {};

		Cameras = {};

		Jails = {};

		LocalEffects = {};

		SizedCharacters = {};

		BundleCache = {};

		MusicList = {
			{Name='jericho',ID=292340735}; -- Jericho - Gordon Bok
			{Name='beam',ID=165065112}; -- Mako - Beam (Proximity)
			{Name='myswamp',ID=166325648};
			{Name='skeletons',ID=168983825}; -- Spooky Scary Skeletons
			{Name='russianmen',ID=173038059};
			{Name='freedom',ID=130760592};
			{Name='seatbelt',ID=135625718};
			{Name="focus",ID=136786547};
			{Name="azylio",ID=137603138};
			{Name="epic",ID=27697743};
			{Name="halo",ID=1034065};
			{Name="pokemon",ID=1372261};
			{Name="cursed",ID=1372257};
			{Name="extreme",ID=11420933};
			{Name="tacos",ID=142295308}; -- Raining Tacos
			{Name="wakemeup",ID=2599359802};
			{Name="awaken",ID=27697277};
			{Name="alone",ID=27697392};
			{Name="mario",ID=1280470};
			{Name="choir",ID=1372258};
			{Name="chrono",ID=1280463};
			{Name="dotr",ID=11420922};
			{Name="entertain",ID=27697267};
			{Name="fantasy",ID=1280473};
			{Name="final",ID=1280414};
			{Name="emblem",ID=1372259};
			{Name="flight",ID=27697719};
			{Name="gothic",ID=27697743};
			{Name="hiphop",ID=27697735};
			{Name="intro",ID=27697707};
			{Name="mule",ID=1077604};
			{Name="film",ID=27697713};
			{Name="nezz",ID=8610025};
			{Name="resist",ID=27697234};
			{Name="schala",ID=5985787};
			{Name="tunnel",ID=9650822};
			{Name="spanish",ID=5982975};
			{Name="venom",ID=1372262};
			{Name="wind",ID=1015394};
			{Name="guitar",ID=5986151};
			{Name="pianoremix",ID=142407859};
			{Name="antidote",ID=145579822};
			{Name="tsunami",ID=569900517};
			{Name="minecraftorchestral",ID=148900687};
			{Name="superbacon",ID=300872612};
			{Name="alonemarsh",ID=639750143}; -- Alone - Marshmello
			{Name="crabraveoof",ID=2590490779}; -- Crab rave oof
			{Name="deathbed",ID=4966153470};
			{Name="crabrave",ID=5410086218}; -- Noisestorm - Crab Rave
		};

		InsertList = {};

		Capes = {
			{Name="crossota",Material="Neon",Color="Cyan",ID=420260457},
			{Name="jamiejr99",Material="Neon",Color="Cashmere",ID=429297485},
			{Name="new yeller",Material='Fabric',Color="New Yeller"},
			{Name="pastel blue",Material='Fabric',Color="Pastel Blue"},
			{Name="dusty rose",Material='Fabric',Color="Dusty Rose"},
			{Name="cga brown",Material='Fabric',Color="CGA brown"},
			{Name="random",Material='Fabric',Color=(BrickColor.random()).Name},
			{Name="shiny",Material='Plastic',Color="Institutional white",Reflectance=1},
			{Name="gold",Material='Plastic',Color="Bright yellow",Reflectance=0.4},
			{Name="kohl",Material='Fabric',Color="Really black",ID=108597653},
			{Name="script",Material='Plastic',Color="White",ID=151359194},
			{Name="batman",Material='Fabric',Color="Institutional white",ID=108597669},
			{Name="epix",Material='Plastic',Color="Really black",ID=149442745},
			{Name="superman",Material='Fabric',Color="Bright blue",ID=108597677},
			{Name="swag",Material='Fabric',Color="Pink",ID=109301474},
			{Name="donor",Material='Plastic',Color="White",ID=149009184},
			{Name="starbucks",Material='Plastic',Color="Black",ID=149248066},
			{Name="gomodern",Material='Plastic',Color="Really black",ID=149438175},
			{Name="admin",Material='Plastic',Color="White",ID=149092195},
			{Name="giovannis",Material='Plastic',Color="White",ID=149808729},
			{Name="godofdonuts",Material='Plastic',Color="Institutional white",ID=151034443},
			{Name="host",Material='Plastic',Color="Really black",ID=152299000},
			{Name="cohost",Material='Plastic',Color="Really black",ID=152298950},
			{Name="trainer",Material='Plastic',Color="Really black",ID=152298976},
			{Name="ba",Material='Plastic',Color='White',ID=172528001}
		};

		Blacklist = {
			Enabled = (server.Settings.BlacklistEnabled ~= nil and server.Settings.BlacklistEnabled) or true;
			Lists = {
				Settings = server.Settings.Blacklist
			};
		};

		Whitelist = {
			Enabled = server.Settings.WhitelistEnabled;
			Lists = {
				Settings = server.Settings.Whitelist
			};
		};
	};
end
