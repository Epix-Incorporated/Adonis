server = nil
service = nil

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	
	local Settings = server.Settings
	local Admin = server.Admin
	local Remote = server.Remote
	local Functions = server.Functions
	local Core = server.Core
	local Variables = server.Variables
	local HTTP = server.HTTP
	local Deps = server.Deps
	
	local Commands = {
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
					if not v.Hidden then
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

				Remote.MakeGui(plr,"Commands",
					{
						Title = "Commands";
						Table = tab;
					}
				)
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
		
		Notepad = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notepad","stickynote"};
			Args = {};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Window",{
					Name = "Notepad";
					Title = "Notepad";
					CanvasSize = UDim2.new(0,0,10,0);
					Ready = true;

					Content = {

						{
							Class = "TextBox";
							Size = UDim2.new(1,-5,1,0);
							Position = UDim2.new(0,0,0,0);
							BackgroundColor3 = Color3.new(1,1,1);
							TextColor3 = Color3.new(0,0,0);
							Font = "Code";
							FontSize = "Size18";
							TextXAlignment = "Left";
							TextYAlignment = "Top";
							TextWrapped = true;
							TextScaled = false;
							ClearTextOnFocus = false;
							MultiLine = true;
							Text = "";
						};
					}
				})
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
		
		wat = { --// wat??
			Prefix = "!";
			Commands = {"wat";};
			Args = {};
			Hidden = true;
			Description = "???";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				local wot = {227499602,153622804,196917825,217714490,130872377,142633540,130936426,130783238,151758509,259702986}
				Remote.Send(plr,"Function","PlayAudio",wot[math.random(1,#wot)])
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
					Settings.SpecialPrefix..'besties - Runs command on anyone on your best friends list';
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
					'Place owners can edit some settings in-game via the '..Settings.Prefix..'settings command';
					'Please refer to the Tips and Tricks section under the settings in the script for more detailed explanations'
				}
				Remote.MakeGui(plr,"List",{Title = 'Usage', Tab = usage})
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
		
		Clean = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"clean";};
			Args = {};
			Hidden = false;
			Description = "Cleans some useless junk out of service.Workspace";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Functions.CleanWorkspace()
			end
		};
		
		Pets = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pets";};
			Args = {"follow/float/swarm/attack";"player";};
			Hidden = false;
			Description = "Makes your hat pets do the specified command (follow/float/swarm/attack)";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr,args)
				local hats = plr.Character:FindFirstChild('ADONIS_HAT_PETS')
				if hats then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						if v.Character:FindFirstChild('HumanoidRootPart') and v.Character.HumanoidRootPart:IsA('Part') then
							if args[1]:lower()=='follow' then
								hats.Mode.Value='Follow'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='float' then
								hats.Mode.Value='Float'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='swarm' then
								hats.Mode.Value='Swarm'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='attack' then
								hats.Mode.Value='Attack'
								hats.Target.Value=v.Character.HumanoidRootPart
							end
						end
					end
				else
					Functions.Hint("You don't have any hat pets! If you are an admin use the :hatpets command to get some",{plr})
				end
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
		
		AddAlias = {
			Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
			Commands = {"alias", "newalias", "addalias"};	-- Commands
			Args = {"alias", "command(s)"};	-- Command arguments
			Description = "Binds a string/command to a certain chat message";	-- Command Description
			Hidden = false; -- Is it hidden from the command list?
			Fun = false;	-- Is it fun?
			AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
			Function = function(plr,args)    -- Function to run for command
				assert(args[1] and args[2], "Argument missing or nil");
				Remote.Send(plr, "Function", "AddAlias", args[1], args[2])
			end
		};

		RemoveAlias = {
			Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
			Commands = {"removealias";"delalias"};	-- Commands
			Args = {"alias"};	-- Command arguments
			Description = "Removes an alias";	-- Command Description
			Hidden = false; -- Is it hidden from the command list?
			Fun = false;	-- Is it fun?
			AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
			Function = function(plr,args)    -- Function to run for command
				assert(args[1], "Argument missing or nil")
				Remote.Send(plr, "Function", "RemoveAlias", args[1])
			end
		};
		
		ServerSpeed = {
			Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
			Commands = {"serverspeed"};	-- Commands
			Args = {};	-- Command arguments
			Description = "Displays the speed of the server";	-- Command Description
			Hidden = false; -- Is it hidden from the command list?
			Fun = false;	-- Is it fun?
			AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
			Function = function(plr,args)    -- Function to run for command
				local Speed = service.Round(service.Workspace:GetRealPhysicsFPS())
				Functions.Hint("The speed is "..tostring(Speed), {plr}, 5)
			end
		};
		
		PlayerCount = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pnum"};
			Args = {};
			Description = "Tells you how many players are in the server";
			AdminLevel = "Players";
			Function = function(plr,args)
				local num = 0
				local nilNum = 0
				for i,v in pairs(service.GetPlayers()) do
					if v.Parent ~= service.Players then
						nilNum = nilNum+1
					end

					num = num+1
				end

				if nilNum > 0 then
					Functions.Hint("There are currently "..tostring(num).." players; "..tostring(nilNum).." are nil or loading",{plr})
				else
					Functions.Hint("There are "..tostring(num).." players",{plr})
				end
			end
		};
		
		Wait = {
			Prefix = Settings.PlayerPrefix;	-- Prefix to use for command
			Commands = {"wait"};	-- Commands
			Args = {};	-- Command arguments
			Description = "Waits the given amount of time before running the next command";	-- Command Description
			Hidden = false; -- Is it hidden from the command list?
			Fun = false;	-- Is it fun?
			AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
			Function = function(plr,args)    -- Function to run for command
				local Time = tonumber(args[0]) or 0
				wait(Time)
			end
		};
	}
	
	for ind, com in pairs(Commands) do
		server.Commands[ind] = com
	end
end