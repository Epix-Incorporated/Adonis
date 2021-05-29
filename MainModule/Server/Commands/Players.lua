return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		ViewCommands = {
			Prefix = Settings.Prefix;
			Commands = {"cmds","commands","cmdlist"};
			Args = {};
			Description = "Shows you a list of commands";
			AdminLevel = "Players";
			Function = function(plr,args)
				local commands = Admin.SearchCommands(plr,"all")
				local tab = {}
				local cStr

				for i,v in next,commands do
					if not v.Hidden and not v.Disabled then
						if type(v.AdminLevel) == "table" then
							cStr = ""
							for k,m in ipairs(v.AdminLevel) do
								cStr = cStr..m..", "
							end
						else
							cStr = tostring(v.AdminLevel)
						end

						table.insert(tab, {
							Text = Admin.FormatCommand(v),
							Desc = "["..cStr.."] "..v.Description,
							Filter = v.AdminLevel
						})
					end
				end

				Remote.MakeGui(plr,"List",
					{
						Title = "Commands";
						Table = tab;
					}
				)
			end
		};

		Notepad = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notepad","stickynote"};
			Args = {};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Notepad",{})
			end
		};

		Prefix = {
			Prefix = "!";
			Commands = {"example";};
			Args = {};
			Description = "Shows you the command prefix using the :cmds command";
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.Hint('"'..Settings.Prefix..'cmds"',{plr})
			end
		};

		ClientTab = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"client";"clientsettings","playersettings"};
			Args = {};
			Hidden = false;
			Description = "Opens the client settings panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Client"})
			end
		};

		Donate = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donate";"change";"changecape";"donorperks";};
			Args = {};
			Hidden = false;
			Description = "Opens the donation panel";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Donate"})
			end
		};

		DonorUncape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"uncape";"removedonorcape";};
			Args = {};
			Hidden = false;
			Description = "Remove donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				Functions.UnCape(plr)
			end
		};

		DonorCape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"cape";"donorcape";};
			Args = {};
			Hidden = false;
			Description = "Get donor cape";
			Fun = false;
			AllowDonors = true;
			AdminLevel = "Donors";
			Function = function(plr,args)
				Functions.Donor(plr)
			end
		};

		DonorShirt = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"shirt";"giveshirt";};
			Args = {"ID";};
			Hidden = false;
			Description = "Give you the shirt that belongs to <ID>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Shirt = AssetIdType == 11 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Shirt", ClothingId) or error("Item ID passed has invalid item type")
					if Shirt then
						for g,k in pairs(plr.Character:GetChildren()) do
							if k:IsA("Shirt") then k:Destroy() end
						end
						local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
						local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

						if humandescrip then
							humandescrip.Shirt = ClothingId
						end
						Shirt:Clone().Parent = plr.Character
					else
						error("Unexpected error occured. Clothing is missing")
					end
				end
			end
		};

		DonorPants = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pants";"givepants";};
			Args = {"id";};
			Hidden = false;
			Description = "Give you the pants that belongs to <id>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Pants = AssetIdType == 12 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Pants", ClothingId) or error("Item ID passed has invalid item type")
					if Pants then
						for g,k in pairs(plr.Character:GetChildren()) do
							if k:IsA("Pants") then k:Destroy() end
						end

						local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
						local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

						if humandescrip then
							humandescrip.Pants = ClothingId
						end

						Pants:Clone().Parent = plr.Character
					else
						error("Unexpected error occured. Clothing is missing")
					end
				end
			end
		};

		DonorFace = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"face";"giveface";};
			Args = {"id";};
			Hidden = false;
			Description = "Gives you the face that belongs to <id>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character and plr.Character:findFirstChild("Head") and plr.Character.Head:findFirstChild("face") then
					plr.Character.Head:findFirstChild("face"):Destroy()
				end

				local id = tonumber(args[1])
				local market = service.MarketPlace
				local info = market:GetProductInfo(id)

				local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
				local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

				if humandescrip then
					humandescrip.Face = id
				end

				if info.AssetTypeId == 8 then
					if plr.Character:FindFirstChild("Head") then
						local face = service.Insert(args[1])
						if face then
							face.Parent = plr.Character:FindFirstChild("Head")
						end
					end
				else
					error("Invalid face ID")
				end
			end
		};

		DonorNeon = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"neon";};
			Args = {"color";};
			Hidden = false;
			Description = "Changes your body material to neon and makes you the (optional) color of your choosing.";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				if plr.Character then
					for k,p in pairs(plr.Character:children()) do
						if p:IsA("BasePart") then
							if args[1] then
								local str = BrickColor.new('Institutional white').Color
								local teststr = args[1]
								if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
								p.BrickColor = str
							end
							p.Material = Enum.Material.Neon
						end
					end
				end
			end
		};

		DonorFire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"fire";"donorfire";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you fire with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					local secondary = Color3.new(1,0,0)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
						secondary = str
					end

					Functions.RemoveParticle(torso,"DONOR_FIRE")
					Functions.NewParticle(torso,"Fire",{
						Name = "DONOR_FIRE";
						Color = color;
						SecondaryColor = secondary;
					})
					Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_FIRE_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorSparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"sparkles";"donorsparkles";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you sparkles with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Bright orange').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso,"DONOR_SPARKLES")
					Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
					Functions.NewParticle(torso,"Sparkles",{
						Name = "DONOR_SPARKLES";
						SparkleColor = color;
					})

					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_SPARKLES_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorLight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"light";"donorlight";};
			Args = {"color (optional)";};
			Hidden = false;
			Description = "Gives you a PointLight with the specified color (if you specify one)";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso,"DONOR_LIGHT")
					Functions.NewParticle(torso,"PointLight",{
						Name = "DONOR_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorParticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"particle";};
			Args = {"textureid";"startColor3";"endColor3";};
			Hidden = false;
			Description = "Put a custom particle emitter on your character";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local startColor = {}
					local endColor = {}

					if args[2] then
						for s in args[2]:gmatch("[%d]+")do
							table.insert(startColor,tonumber(s))
						end
					end
					if args[3] then--276138620 :)
						for s in args[3]:gmatch("[%d]+")do
							table.insert(endColor,tonumber(s))
						end
					end

					local startc = Color3.new(1,1,1)
					local endc = Color3.new(1,1,1)
					if #startColor==3 then
						startc = Color3.new(startColor[1],startColor[2],startColor[3])
					end
					if #endColor==3 then
						endc = Color3.new(endColor[1],endColor[2],endColor[3])
					end

					Functions.RemoveParticle(torso,"DONOR_PARTICLE")
					Functions.NewParticle(torso,"ParticleEmitter",{
						Name = "DONOR_PARTICLE";
						Texture = 'rbxassetid://'..Functions.GetTexture(args[1]);
						Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0,0);
							NumberSequenceKeypoint.new(.1,.25,.25);
							NumberSequenceKeypoint.new(1,.5);
						});
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0,1);
							NumberSequenceKeypoint.new(.1,.25,.25);
							NumberSequenceKeypoint.new(.9,.5,.25);
							NumberSequenceKeypoint.new(1,1);
						});
						Lifetime = NumberRange.new(5);
						Speed = NumberRange.new(.5,1);
						Rotation = NumberRange.new(0,359);
						RotSpeed = NumberRange.new(-90,90);
						Rate = 11;
						VelocitySpread = 180;
						Color = ColorSequence.new(startc,endc);
					})
				end
			end
		};

		DonorUnparticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unparticle";"removeparticles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor particles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_PARTICLE")
			end
		};

		DonorUnfire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unfire";"undonorfire";};
			Args = {};
			Hidden = false;
			Description = "Removes donor fire on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_FIRE")
				Functions.RemoveParticle(torso,"DONOR_FIRE_LIGHT")
			end
		};

		DonorUnsparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unsparkles";"undonorsparkles";};
			Args = {};
			Hidden = false;
			Description = "Removes donor sparkles on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_SPARKLES")
				Functions.RemoveParticle(torso,"DONOR_SPARKLES_LIGHT")
			end
		};

		DonorUnlight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unlight";"undonorlight";};
			Args = {};
			Hidden = false;
			Description = "Removes donor light on you";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso,"DONOR_LIGHT")
			end
		};

		DonorHat = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"hat";"gethat";};
			Args = {"ID";};
			Hidden = false;
			Description = "Gives you the hat specified by <ID>";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				local id = tonumber(args[1])
				local hats = 0
				for i,v in pairs(plr.Character:GetChildren()) do if v:IsA("Accoutrement") then hats = hats+1 end end
				if id and hats<15 then
					local market = service.MarketPlace
					local info = market:GetProductInfo(id)
					if info.AssetTypeId == 8 or (info.AssetTypeId >= 41 and info.AssetTypeId <= 47) then
						local hat = service.Insert(id)
						assert(hat,"Invalid ID")
						local banned = {
							Script = true;
							LocalScript = true;
							Tool = true;
							HopperBin = true;
							ModuleScript = true;
							RemoteFunction = true;
							RemoteEvent = true;
							BindableEvent = true;
							Folder = true;
							RocketPropulsion = true;
							Explosion = true;
						}

						local removeScripts; removeScripts = function(obj)
							for i,v in pairs(obj:GetChildren()) do
								pcall(function()
									removeScripts(v)
									if banned[v.ClassName] then
										v:Destroy()
									end
								end)
							end
						end

						removeScripts(hat)
						hat.Parent = plr.Character
						hat.Changed:connect(function()
							if hat.Parent ~= plr.Character then
								hat:Destroy()
							end
						end)
					end
				end
			end
		};

		DonorRemoveHats = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"removehats";"nohats";};
			Args = {};
			Hidden = false;
			Description = "Removes any hats you are currently wearing";
			Fun = false;
			AdminLevel = "Donors";
			Function = function(plr,args)
				for i,v in pairs(plr.Character:children()) do
					if v:IsA("Accoutrement") then
						v:Destroy()
					end
				end
			end
		};

		Keybinds = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"keybinds";"binds";"bind";"keybind";"clearbinds";"removebind";};
			Args = {};
			Hidden = false;
			Description = "Opens the keybind manager";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "KeyBinds"})
			end
		};

		GetScript = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getscript";"getadonis"};
			Args = {};
			Hidden = false;
			Description = "Get this script.";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.MarketPlace:PromptPurchase(plr, Core.LoaderID)
			end
		};

		Ping = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"ping";};
			Args = {};
			Hidden = false;
			Description = "Shows you your current ping (in seconds)";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,'Ping')
			end
		};

		GetPing = {
			Prefix = Settings.Prefix;
			Commands = {"getping";};
			Args = {"player";};
			Hidden = false;
			Description = "Shows the target player's ping (in seconds)";
			Fun = false;
			AdminLevel = "Helpers";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Hint(v.Name.."'s Ping is "..Remote.Get(v,"Ping").."ms",{plr})
				end
			end
		};

		Donors = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donors";"donorlist";"donatorlist";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of donators who are currently in the server";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temptable = {}
				for i,v in pairs(service.Players:children()) do
					if Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				Remote.MakeGui(plr,'List',{Title = 'Donors In-Game'; Tab = temptable; Update = 'DonorList'})
			end
		};

		RequestHelp = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"help";"requesthelp";"gethelp";"lifealert";};
			Args = {};
			Hidden = false;
			Description = "Calls admins for help";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				if Settings.HelpSystem == true then
					local num = 0
					local answered = false
					local pending = Variables.HelpRequests[plr.Name];

					if pending and os.time() - pending.Time < 30 then
						error("You can only send a help request once every 30 seconds.");
					elseif pending and pending.Pending then
						error("You already have a pending request")
					else
						service.TrackTask("Thread: ".. tostring(plr).. " Help Request Handler", function()
							Functions.Hint("Request sent",{plr})

							pending = {
								Time = os.time();
								Pending = true;
							}

							Variables.HelpRequests[plr.Name] = pending;

							for ind,p in pairs(service.Players:GetPlayers()) do
								if Admin.CheckAdmin(p) then
									local ret = Remote.MakeGuiGet(p,"Notification",{
										Title = "Help Request";
										Message = plr.Name.." needs help!";
										Time = 30;
										OnClick = Core.Bytecode("return true");
										OnClose = Core.Bytecode("return false");
										OnIgnore = Core.Bytecode("return false");
									})

									num = num+1
									if ret then
										if not answered then
											answered = true
											Admin.RunCommand(Settings.Prefix.."tp",p.Name,plr.Name)
										end
									end
								end
							end

							local w = tick()
							repeat wait(0.5) until tick()-w>30 or answered

							pending.Pending = false;

							if not answered then
								Functions.Message("Help System","Sorry but no one is available to help you right now",{plr})
							end
						end)
					end
				else
					Functions.Message("Help System","Help System Disabled by Place Owner",{plr})
				end
			end
		};

		Rejoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"rejoin";};
			Args = {};
			Hidden = false;
			Description = "Makes you rejoin the server";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local succeeded, errorMsg, placeId, instanceId = service.TeleportService:GetPlayerPlaceInstanceAsync(plr.userId)
				if succeeded then
					service.TeleportService:TeleportToPlaceInstance(placeId, instanceId, plr)
				else
					Functions.Hint("Could not rejoin.")
				end
			end
		};

		Join = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"join";"follow";"followplayer";};
			Args = {"username";};
			Hidden = false;
			Description = "Makes you follow the player you gave the username of to the server they are in";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local player = service.Players:GetUserIdFromNameAsync(args[1])
				if player then
					local succeeded, errorMsg, placeId, instanceId = service.TeleportService:GetPlayerPlaceInstanceAsync(player)
					if succeeded then
						service.TeleportService:TeleportToPlaceInstance(placeId, instanceId, plr)
					else
						Functions.Hint("Could not follow "..args[1]..". "..errorMsg,{plr})
					end
				else
					Functions.Hint(args[1].." is not a valid Roblox user",{plr})
				end
			end
		};

		Agents = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"agents";"trelloagents";"showagents";};
			Args = {};
			Hidden = false;
			Description = "Shows a list of Trello agents pulled from the configured boards";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local temp={}
				for i,v in pairs(HTTP.Trello.Agents) do
					table.insert(temp,{Text = v,Desc = "A Trello agent"})
				end
				Remote.MakeGui(plr,"List",{Title = "Agents", Tab = temp})
			end
		};

		Credits = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"credit";"credits";};
			Args = {};
			Hidden = false;
			Description = "Credits";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"List",{
					Title = 'Credits',
					Tab = server.Credits
				})
			end
		};

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog";"changes";};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"List",{
					Title = 'Change Log',
					Table = server.Changelog,
					Size = {500,400}
				})
			end
		};

		Quote = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"quote";"inspiration";"randomquote";};
			Args = {};
			Description = "Shows you a random quote";
			AdminLevel = "Players";
			Function = function(plr,args)
				local quotes = require(Deps.Assets.Quotes)
				Functions.Message('Random Quote',quotes[math.random(1,#quotes)],{plr})
			end
		};

		Usage = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"usage";};
			Args = {};
			Hidden = false;
			Description = "Shows you how to use some syntax related things";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local usage={
					'Mouse over things in lists to expand them';
					'Special Functions: ';
					'Ex: '..Settings.Prefix..'kill FUNCTION, so like '..Settings.Prefix..'kill '..Settings.SpecialPrefix..'all';
					'Put /e in front to make it silent (/e '..Settings.Prefix..'kill scel)';
					Settings.SpecialPrefix..'me - Runs a command on you';
					Settings.SpecialPrefix..'all - Runs a command on everyone';
					Settings.SpecialPrefix..'admins - Runs a command on all admins in the game';
					Settings.SpecialPrefix..'nonadmins - Same as !admins but for people who are not an admin';
					Settings.SpecialPrefix..'others - Runs command on everyone BUT you';
					Settings.SpecialPrefix..'random - Runs command on a random person';
					Settings.SpecialPrefix..'friends - Runs command on anyone on your friends list';
					'%TEAMNAME - Runs command on everyone in the team TEAMNAME Ex: '..Settings.Prefix..'kill %raiders';
					'$GROUPID - Run a command on everyone in the group GROUPID, Will default to the GroupId setting if no id is given';
					'-PLAYERNAME - Will remove PLAYERNAME from list of players to run command on. '..Settings.Prefix..'kill all,-scel will kill everyone except scel';
					'#NUMBER - Will run command on NUMBER of random players. '..Settings.Prefix..'ff #5 will ff 5 random players.';
					'radius-NUMBER -- Lets you run a command on anyone within a NUMBER stud radius of you. '..Settings.Prefix..'ff radius-5 will ff anyone within a 5 stud radius of you.';
					'Certain commands can be used by anyone, these commands have '..Settings.PlayerPrefix..' infront, such as '..Settings.PlayerPrefix..'clean and '..Settings.PlayerPrefix..'rejoin';
					''..Settings.Prefix..'kill me,noob1,noob2,'..Settings.SpecialPrefix..'random,%raiders,$123456,!nonadmins,-scel';
					'Multiple Commands at a time - '..Settings.Prefix..'ff me '..Settings.BatchKey..' '..Settings.Prefix..'sparkles me '..Settings.BatchKey..' '..Settings.Prefix..'rocket jim';
					'You can add a wait if you want; '..Settings.Prefix..'ff me '..Settings.BatchKey..' !wait 10 '..Settings.BatchKey..' '..Settings.Prefix..'m hi we waited 10 seconds';
					''..Settings.Prefix..'repeat 10(how many times to run the cmd) 1(how long in between runs) '..Settings.Prefix..'respawn jim';
					'Place HeadAdmins can edit some settings in-game via the '..Settings.Prefix..'settings command';
					'Please refer to the Tips and Tricks section under the settings in the script for more detailed explanations'
				}
				Remote.MakeGui(plr,"List",{Title = 'Usage', Tab = usage})
			end
		};

		GlobalJoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"joinfriend";};
			Args = {"username";};
			Hidden = false;
			Description = "Joins your friend outside/inside of the game (must be online)";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args) -- uses Player:GetFriendsOnline()
				--// NOTE: MAY NOT WORK IF "ALLOW THIRD-PARTY GAME TELEPORTS" (GAME SECURITY PERMISSION) IS DISABLED

				local player = service.Players:GetUserIdFromNameAsync(args[1])

				if player then
					for i,v in next, plr:GetFriendsOnline() do
						if v.VisitorId == player and v.IsOnline and v.PlaceId and v.GameId then
							local new = Core.NewScript('LocalScript',"service.TeleportService:TeleportToPlaceInstance("..v.PlaceId..", "..v.GameId..", "..plr:GetFullName()..")")
							new.Disabled = false
							new.Parent = plr:FindFirstChildOfClass"Backpack"
						end
					end
				else
					Functions.Hint(args[1].." is not a valid Roblox user",{plr})
				end
			end
		};

		ScriptInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"info";"about";"userpanel";};
			Args = {};
			Hidden = false;
			Description = "Shows info about the script";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Info"})
			end
		};

		Aliases = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"aliases", "addalias", "removealias", "newalias"};
			Args = {};
			Hidden = false;
			Description = "Opens the alias manager";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"UserPanel",{Tab = "Aliases"})
			end
		};

		Invite = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"invite";"invitefriends"};
			Args = {};
			Description = "Invite your friends into the game";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.SocialService:PromptGameInvite(plr)
			end
		};

		OnlineFriends = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"onlinefriends";"friendsonline";};
			Args = {};
			Description = "Shows a list of your friends who are currently online";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Friends")
			end
		};

		GetPremium = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getpremium";"purcahsepremium";"robloxpremium"};
			Args = {};
			Description = "Lets you to purchase Roblox Premium";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.MarketplaceService:PromptPremiumPurchase(plr)
			end
		};

		AddFriend = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"addfriend";"friendrequest";"sendfriendrequest";};
			Args = {"player"};
			Description = "Sends a friend request to the specified player";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					assert(v~=plr, "Cannot friend yourself!")
					assert(not plr:IsFriendsWith(v), "You are already friends with "..v.Name)
					Remote.LoadCode(plr,[[game:GetService("StarterGui"):SetCore("PromptSendFriendRequest",game:GetService("Players").]]..v.Name..[[)]])
				end
			end
		};

		UnFriend = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unfriend";"removefriend";};
			Args = {"player"};
			Description = "Unfriends the specified player";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					assert(v~=plr, "Cannot unfriend yourself!")
					assert(plr:IsFriendsWith(v), "You are not currently friends with "..v.Name)
					Remote.LoadCode(plr,[[game:GetService("StarterGui"):SetCore("PromptUnfriend",game:GetService("Players").]]..v.Name..[[)]])
				end
			end
		};

		DevConsole = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"devconsole";"developerconsole";"opendevconsole";};
			Args = {};
			Description = "Opens the Roblox developer console";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.LoadCode(plr,[[service.StarterGui:SetCore("DevConsoleVisible",true)]])
			end
		};
	}
end
