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
		
		Logs:AddLog("Script", "Variables Module Initialized")
	end;
	
	server.Variables = {
		Init = Init;
		ZaWarudo = false;
		CodeName = math.random();
		FrozenObjects = {};
		ScriptBuilder = {};
		CachedDonors = {};
		BanMessage = "Banned";
		LockMessage = "Not Whitelisted";
		DonorPass = {1348327,1990427,1911740,167686,98593};
		LightingSettings = {
			Ambient = service.Lighting.Ambient;
			OutdoorAmbient = service.Lighting.OutdoorAmbient;
			Brightness = service.Lighting.Brightness;
			TimeOfDay = service.Lighting.TimeOfDay;
			FogColor = service.Lighting.FogColor;
			FogEnd = service.Lighting.FogEnd;
			FogStart = service.Lighting.FogStart;
			GlobalShadows = service.Lighting.GlobalShadows;
			Outlines = service.Lighting.Outlines;
			ShadowColor = service.Lighting.ShadowColor;
			ColorShift_Bottom = service.Lighting.ColorShift_Bottom;
			ColorShift_Top = service.Lighting.ColorShift_Top;
			GeographicLatitude = service.Lighting.GeographicLatitude;
			Name = service.Lighting.Name;
		};
		
		OriginalLightingSettings = {
			Ambient = service.Lighting.Ambient;
			OutdoorAmbient = service.Lighting.OutdoorAmbient;
			Brightness = service.Lighting.Brightness;
			TimeOfDay = service.Lighting.TimeOfDay;
			FogColor = service.Lighting.FogColor;
			FogEnd = service.Lighting.FogEnd;
			FogStart = service.Lighting.FogStart;
			GlobalShadows = service.Lighting.GlobalShadows;
			Outlines = service.Lighting.Outlines;
			ShadowColor = service.Lighting.ShadowColor;
			ColorShift_Bottom = service.Lighting.ColorShift_Bottom;
			ColorShift_Top = service.Lighting.ColorShift_Top;
			GeographicLatitude = service.Lighting.GeographicLatitude;
			Name = service.Lighting.Name;
			Sky = service.Lighting:FindFirstChildOfClass("Sky") and service.Lighting:FindFirstChildOfClass("Sky"):Clone();
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
		
		MusicList = {
			{Name='jericho',ID=292340735};
			{Name='dieinafire',ID=242222291};
			{Name='beam',ID=165065112};
			{Name='myswamp',ID=166325648};
			{Name='skeletons',ID=168983825};
			{Name='russianmen',ID=173038059};
			{Name='freedom',ID=130760592};
			{Name='seatbelt',ID=135625718};
			{Name='tempest',ID=135554032};
			{Name="focus",ID=136786547};
			{Name="azylio",ID=137603138};
			{Name="caramell",ID=2303479};
			{Name="epic",ID=27697743};
			{Name="halo",ID=1034065};
			{Name="pokemon",ID=1372261};
			{Name="cursed",ID=1372257};
			{Name="extreme",ID=11420933};
			{Name="tacos",ID=142295308};
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
			{Name="organ",ID=11231513};
			{Name="tunnel",ID=9650822};
			{Name="spanish",ID=5982975};
			{Name="venom",ID=1372262};
			{Name="wind",ID=1015394};
			{Name="guitar",ID=5986151};
			{Name="weapon",ID=142400410};
			{Name="derezzed",ID=142402620};
			{Name="sceptics",ID=153251489};
			{Name="pianoremix",ID=142407859};
			{Name="antidote",ID=145579822};
			{Name="overtime",ID=135037991};
			{Name="fluffyunicorns",ID=141444871};
			{Name="tsunami",ID=569900517};
			{Name="finalcountdownremix",ID=145162750};
			{Name="stereolove",ID=142318819};
			{Name="minecraftorchestral",ID=148900687};
			{Name="superbacon",ID=300872612};
			{Name="alonemarsh",ID=639750143}; -- Alone - Marshmello
			{Name="crabraveoof",ID=2590490779}; -- Crab rave oof
			{Name="rickroll",ID=4581203569};
			{Name="deathbed",ID=4966153470};
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
		
		Whitelist = {
			Enabled = server.Settings.WhitelistEnabled;
			List = server.Settings.Whitelist or {};
		};
	};
end
