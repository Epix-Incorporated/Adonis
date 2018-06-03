server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function()
	server.Variables = {
		ZaWarudo = false;
		CodeName = math.random();
		FrozenObjects = {};
		ScriptBuilder = {};
		CachedDonors = {};
		ServerStartTime = os.time();
		BanMessage = "Banned";
		LockMessage = "Not Whitelisted";
		DonorPass = {497917601,442800581,418722590,159549976,157092510};
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
			Sky = (function() 
				for i,v in pairs(service.Lighting:GetChildren()) do 
					if v:IsA("Sky") then 
						return v:Clone() 
					end 
				end 
			end)()
		};
		
		HelpRequests = {};
		
		Objects = {};
		
		InsertedObjects = {};
		
		CommandLoops = {};
		
		Waypoints = {};
		
		Cameras = {};
		
		Jails = {};
		
		LocalEffects = {};
		
		MusicList = {
			{Name='jericho',ID=292340735};
			{Name='dieinafire',ID=242222291};
			{Name='beam',ID=165065112};
			{Name='myswamp',ID=166325648};
			{Name='habits',ID=182402191};
			{Name='skeletons',ID=174270407};
			{Name='russianmen',ID=173038059};
			{Name='heybrother',ID=183833194};
			{Name='loseyourself',ID=153480949};
			{Name='diamonds',ID=142533681};
			{Name='happy',ID=146952916};
			{Name='clinteastwood',ID=148649589};
			{Name='freedom',ID=130760592};
			{Name='seatbelt',ID=135625718};
			{Name='tempest',ID=135554032};
			{Name="focus",ID=136786547};
			{Name="azylio",ID=137603138};
			{Name="caramell",ID=2303479};
			{Name="epic",ID=27697743};
			{Name="rick",ID=2027611};
			{Name="crystallize",ID=143929751};
			{Name="halo",ID=1034065};
			{Name="pokemon",ID=1372261};
			{Name="cursed",ID=1372257};
			{Name="extreme",ID=11420933};
			{Name="harlemshake",ID=142468820};
			{Name="tacos",ID=142295308};
			{Name="wakemeup",ID=147632133};
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
			{Name="banjo",ID=27697298};
			{Name="gothic",ID=27697743};
			{Name="hiphop",ID=27697735};
			{Name="intro",ID=27697707};
			{Name="mule",ID=1077604};
			{Name="film",ID=27697713};
			{Name="nezz",ID=8610025};
			{Name="angel",ID=1372260};
			{Name="resist",ID=27697234};
			{Name="schala",ID=5985787};
			{Name="organ",ID=11231513};
			{Name="tunnel",ID=9650822};
			{Name="spanish",ID=5982975};
			{Name="venom",ID=1372262};
			{Name="wind",ID=1015394};
			{Name="guitar",ID=5986151};
			{Name="selfie1",ID=148321914};
			{Name="selfie2",ID=151029303};
			{Name="fareast",ID=148999977};
			{Name="ontopoftheworld",ID=142838705};
			{Name="mashup",ID=143994035};
			{Name="getlucky",ID=142677206};
			{Name="dragonborn",ID=150015506};
			{Name="craveyou",ID=142397454};
			{Name="weapon",ID=142400410};
			{Name="derezzed",ID=142402620};
			{Name="burn",ID=142594142};
			{Name="workhardplayhard",ID=144721295};
			{Name="royals",ID=144662895};
			{Name="pompeii",ID=144635805};
			{Name="powerglove",ID=152324067};
			{Name="pompeiiremix",ID=153519026};
			{Name="sceptics",ID=153251489};
			{Name="pianoremix",ID=142407859};
			{Name="antidote",ID=145579822};
			{Name="takeawalk",ID=142473248};
			{Name="countingstars",ID=142282722};
			{Name="turndownforwhat",ID=143959455};
			{Name="overtime",ID=145111795};
			{Name="fluffyunicorns",ID=141444871};
			{Name="gaspedal",ID=142489916};
			{Name="bangarang",ID=142291921};
			{Name="talkdirty",ID=148952593};
			{Name="bad",ID=155444244};
			{Name="demons",ID=142282614};
			{Name="roar",ID=148728760};
			{Name="letitgo",ID=142343490};
			{Name="finalcountdown",ID=142859512};
			{Name="tsunami",ID=152775066};
			{Name="animals",ID=142370129};
			{Name="partysignals",ID=155779549};
			{Name="finalcountdownremix",ID=145162750};
			{Name="mambo",ID=144018440};
			{Name="stereolove",ID=142318819};
			{Name='minecraftorchestral',ID=148900687}
		};
		
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