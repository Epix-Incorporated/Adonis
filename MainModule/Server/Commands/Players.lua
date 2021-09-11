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
				local cStr = ""

				local cmdCount = 0
				for i,v in next,commands do
					if not v.Hidden and not v.Disabled then
						local lvl = v.AdminLevel;
						local gotLevels = {};

						if type(lvl) == "table" then
							for i,v in pairs(lvl) do
								table.insert(gotLevels, v);
							end
						elseif type(lvl) == "string" or type(lvl) == "number" then
							table.insert(gotLevels, lvl);
						end

						for i,lvl in next,gotLevels do
							local tempStr = "";

							if type(lvl) == "number" then
								local list, name, data = Admin.LevelToList(lvl);
								--print(tostring(list), tostring(name), tostring(data))
								tempStr = (name or "No Rank") .."; Level ".. lvl;
							elseif type(lvl) == "string" then
								local numLvl = Admin.StringToComLevel(lvl);
								tempStr = lvl .. "; Level: ".. (numLvl or "Unknown Level")
							end

							if i > 1 then
								tempStr = cStr.. ", ".. tempStr;
							end

							cStr = tempStr;
						end

						table.insert(tab, {
							Text = Admin.FormatCommand(v),
							Desc = "["..cStr.."] "..v.Description,
							Filter = cStr
						})
						cmdCount = cmdCount + 1
					end
				end

				Remote.MakeGui(plr,"List",
					{
						Title = "Commands ("..cmdCount..")";
						Table = tab;
						TitleButtons = {
							{
								Text = "?";
								OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.PlayerPrefix.."usage')")
							}
						};
					}
				)
			end
		};

		CommandInfo = {
			Prefix = Settings.Prefix;
			Commands = {"cmdinfo","commandinfo","cmddetails"};
			Args = {"command"};
			Description = "Shows you information about a specific command";
			AdminLevel = "Players";
			Function = function(plr,args)
				assert(args[1], "No command provided")

				local commands = Admin.SearchCommands(plr,"all")
				local cmd
				for i,v in next,commands do
					for _, p in pairs(v.Commands) do
						if p:lower() == args[1]:lower() then
							cmd = v
							break
						end
					end
				end
				assert(cmd, "Command not found / don't include prefix")

				local cmdArgs = Admin.FormatCommand(cmd):sub((#cmd.Commands[1]+2))
				if cmdArgs == "" then cmdArgs = "-" end
				Remote.MakeGui(plr,"List",
					{
						Title = "Command Info";
						Table = {
							{Text = "Prefix: "..cmd.Prefix, Desc = "Prefix used to run the command"},
							{Text = "Commands: "..table.concat(cmd.Commands, ", "), Desc = "Valid default aliases for the command"},
							{Text = "Arguments: "..cmdArgs, Desc = "Parameters taken by the command"},
							{Text = "Admin Level: "..cmd.AdminLevel, Desc = "Rank required to run the command"},
							{Text = "Fun: "..tostring(cmd.Fun), Desc = "Is the command fun?"},
							{Text = "Hidden: "..tostring(cmd.Hidden), Desc = "Is the command hidden from the command list?"},
							{Text = "Description: "..cmd.Description, Desc = "Command description"}
						};
						Size = {400,220}
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
					
		Paint = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"paint","canvas","draw"};
			Args = {};
			Description = "Opens a canvas window for you to draw on";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Paint",{})
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
						
		NotifyMe = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notifyme"};
			Args = {"time (in seconds) or inf";"message"};
			Hidden = true;
			Description = "Sends yourself a notification";
			AdminLevel = "Players";
			Function = function(plr, args)
				assert(args[1] and args[2], "Argument(s) missing or nil")
				Remote.MakeGui(plr, "Notification", {
					Title = "Notification";
					Message = args[2];
					Time = tonumber(args[1]);
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

		GetScript = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getscript";"getadonis"};
			Args = {};
			Hidden = false;
			Description = "Prompts you to take a copy of the script";
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
			Description = "Shows you your current ping (latency)";
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
			Description = "Shows the target player's ping";
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
				for _,v in pairs(service.Players:GetPlayers()) do
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

							local w = time()
							repeat wait(0.5) until time()-w>30 or answered

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
				service.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, plr)
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

		Credits = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"credit";"credits";};
			Args = {};
			Hidden = false;
			Description = "Shows you Adonis development credits";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Credits",{})
			end
		};

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog";"changes";"updates"};
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
					'NOTE: This info is temporary.';
					'A revamped user manual is being made.';
					'';
					'Mouse over things in lists to expand them';
					'You can also resize windows by dragging the edges';
					'';
					'<b>Commands:</b>';
					'Timeban, Works with non-ingame players, <i>'.. Settings.Prefix ..'tban Player time(d/h/m/s)</i> | Example: <i>'.. Settings.Prefix ..'timeban Sceleratis 10h</i> (10 hours ban), d = days, h = hour, m = minutes, s = seconds';
					'<b>Special Functions:</b>';
					'Ex: <i>'..Settings.Prefix..'kill FUNCTION</i>, so like <i>'..Settings.Prefix..'kill '..Settings.SpecialPrefix..'all</i>';
					'Put <i>/e</i> in front to silence it (<i>/e '..Settings.Prefix..'kill scel</i>) or enable chat command hiding in client settings';
					'<i>'..Settings.SpecialPrefix..'me</i> - Runs a command on you';
					'<i>'..Settings.SpecialPrefix..'all</i> - Runs a command on everyone';
					'<i>'..Settings.SpecialPrefix..'admins</i> - Runs a command on all admins in the game';
					'<i>'..Settings.SpecialPrefix..'nonadmins</i> - Same as !admins but for people who are not an admin';
					'<i>'..Settings.SpecialPrefix..'others</i> - Runs command on everyone BUT you';
					'<i>'..Settings.SpecialPrefix..'random</i> - Runs command on a random person';
					'<i>'..Settings.SpecialPrefix..'friends</i> - Runs command on anyone on your friends list';
					'<i>%TEAMNAME</i> - Runs command on everyone in the team TEAMNAME Ex: '..Settings.Prefix..'kill %raiders';
					'<i>$GROUPID</i> - Run a command on everyone in the group GROUPID, Will default to the GroupId setting if no id is given';
					'<i>-PLAYERNAME</i> - Will remove PLAYERNAME from list of players to run command on. '..Settings.Prefix..'kill all,-scel will kill everyone except scel';
					'<i>#NUMBER</i> - Will run command on NUMBER of random players. <i>'..Settings.Prefix..'ff #5</i> will ff 5 random players.';
					'<i>radius-NUMBER</i> -- Lets you run a command on anyone within a NUMBER stud radius of you. '..Settings.Prefix..'ff radius-5 will ff anyone within a 5 stud radius of you.';
					'';
					'Certain commands can be used by anyone, these commands have <i>'..Settings.PlayerPrefix..'</i> infront, such as <i>'..Settings.PlayerPrefix..'clean</i> and <i>'..Settings.PlayerPrefix..'rejoin</i>';
					'<i>'..Settings.Prefix..'kill me,noob1,noob2,'..Settings.SpecialPrefix..'random,%raiders,$123456,!nonadmins,-scel</i>';
					'Multiple Commands at a time - <i>'..Settings.Prefix..'ff me '..Settings.BatchKey..' '..Settings.Prefix..'sparkles me '..Settings.BatchKey..' '..Settings.Prefix..'rocket jim</i>';
					'You can add a wait if you want; <i>'..Settings.Prefix..'ff me '..Settings.BatchKey..' !wait 10 '..Settings.BatchKey..' '..Settings.Prefix..'m hi we waited 10 seconds</i>';
					'<i>'..Settings.Prefix..'repeat 10(how many times to run the cmd) 1(how long in between runs) '..Settings.Prefix..'respawn jim</i>';
					'Place HeadAdmins can edit some settings in-game via the '..Settings.Prefix..'settings command';
					'Please refer to the Tips and Tricks section under the settings in the script for more detailed explanations'
				}
				Remote.MakeGui(plr,"List",{Title = 'Usage', Tab = usage, Size = {280, 240}, RichText = true})
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
			Description = "Shows info about the script (Adonis)";
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
			Description = "Prompts you to purchase Roblox Premium";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				service.MarketplaceService:PromptPremiumPurchase(plr)
			end
		};

		--[[AddFriend = {
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
					Remote.LoadCode(plr,"service.StarterGui:SetCore("PromptSendFriendRequest",service.Players."..v.Name..")")
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
					Remote.LoadCode(plr,"service.StarterGui:SetCore("PromptUnfriend",service.Players."..v.Name..")")
				end
			end
		};]]
		
		InspectAvatar = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"inspectavatar";"avatarinspect";"viewavatar";"examineavatar";};
			Args = {"player"};
			Description = "Opens the Roblox avatar inspect menu for the specified player";
			Hidden = false;
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.LoadCode(plr,"service.GuiService:InspectPlayerFromUserId("..v.UserId..")")
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
		
		NumPlayers = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pnum","numplayers","playercount"};
			Args = {};
			Description = "Tells you how many players are in the server";
			AdminLevel = "Players";
			Function = function(plr, args)
				local num = 0
				local nilNum = 0
				for _, v in ipairs(service.GetPlayers()) do
					if v.Parent ~= service.Players then
						nilNum += 1
					end

					num += 1
				end

				if nilNum > 0 and Admin.GetLevel(plr) >= 100 then
					Functions.Hint("There are currently "..tostring(num).." player(s); "..tostring(nilNum).." are nil or loading", {plr})
				else
					Functions.Hint("There are "..tostring(num).." player(s)", {plr})
				end
			end
		};
		
		TimeDate = {
			Prefix = Settings.Prefix;
			Commands = {"timedate";"date";"datetime";};
			Args = {};
			Hidden = false;
			Description = "Shows you the current time and date.";
			Fun = false;
			AdminLevel = "Players";
			Function = function(plr, args)
				local ostime = os.time()
				local tab = {}
				table.insert(tab, {Text = "―――――――――――――――――――――――"})

				table.insert(tab, {Text = "Date: "..os.date("%x", ostime)})
				table.insert(tab, {Text = "Time: "..os.date("%H:%M | %I:%M %p", ostime)})
				table.insert(tab, {Text = "Timezone: "..os.date("%Z", ostime)})

				table.insert(tab, {Text = "―――――――――――――――――――――――"})


				table.insert(tab, {Text = "Minute: "..os.date("%M", ostime)})
				table.insert(tab, {Text = "Hour: "..os.date("%H | %I %p" ,ostime)})
				table.insert(tab, {Text = "Day: "..os.date("%d %A", ostime)})
				table.insert(tab, {Text = "Week (First sunday): "..os.date("%U", ostime)})
				table.insert(tab, {Text = "Week (First monday): "..os.date("%W", ostime)})
				table.insert(tab, {Text = "Month: "..os.date("%m %B", ostime)})
				table.insert(tab, {Text = "Year: "..os.date("%Y", ostime)})

				table.insert(tab, {Text = "―――――――――――――――――――――――"})

				table.insert(tab, {Text = "Day of the year: "..os.date("%j", ostime)})
				table.insert(tab, {Text = "Day of the month: "..os.date("%d", ostime)})

				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				Remote.MakeGui(plr, "List", {
					Title = "Date",
					Table = tab,
					Update = 'DateTime',
					AutoUpdate = 59,
					Size = {270, 390};
				})
			end
		};


	}
end
