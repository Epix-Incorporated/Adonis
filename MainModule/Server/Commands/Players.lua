return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine
	local Pcall = env.Pcall

	return {
		ViewCommands = {
			Prefix = Settings.Prefix;
			Commands = {"cmds", "commands", "cmdlist"};
			Args = {};
			Description = "Lists all available commands";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local tab = {}
				local cmdCount = 0

				for _, cmd in Admin.SearchCommands(plr, "all") do
					if cmd.Hidden or cmd.Disabled then
						continue
					end

					local permissionDesc = Admin.FormatCommandAdminLevel(cmd)
					table.insert(tab, {
						Text = Admin.FormatCommand(cmd),
						Desc = string.format("[%s] %s", permissionDesc, cmd.Description or "(No description provided)"),
						Filter = permissionDesc
					})
					cmdCount += 1
				end

				for alias, command in Core.GetPlayer(plr).Aliases or {} do
					table.insert(tab, {
						Text = alias,
						Desc = `[User Alias] {command}`,
						Filter = command
					})
					cmdCount += 1
				end

				table.sort(tab, function(a, b) return a.Text < b.Text end)

				Remote.MakeGui(plr, "List", {
					Title = `Commands ({cmdCount})`;
					Table = tab;
					TitleButtons = {
						{
							Text = "?";
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.PlayerPrefix}usage')`)
						}
					};
				})
			end
		};

		CommandInfo = {
			Prefix = Settings.Prefix;
			Commands = {"cmdinfo", "commandinfo", "cmddetails", "commanddetails"};
			Args = {"command"};
			Description = "Shows you information about a specific command";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(args[1], "No command provided")

				local cmd, ind
				for i, v in Admin.SearchCommands(plr, "all") do
					for _, p in v.Commands do
						if (v.Prefix or "")..string.lower(p) == string.lower(args[1]) then
							cmd, ind = v, i
							break
						end
					end
					if ind then break end
				end
				assert(cmd, `Command '{args[1]}' is either not found or beyond your permission level`)

				local SanitizeXML = service.SanitizeXML

				local cmdArgs = Admin.FormatCommandArguments(cmd)

				local cmdAttribs = {}
				for _, key in {"Disabled", "Fun", "Hidden", "NoStudio", "NonChattable", "CrossServerDenied", "AllowDonors"} do
					if cmd[key] then
						table.insert(cmdAttribs, key)
					end
				end

				Remote.MakeGui(plr, "List", {
					Title = "Command Info";
					Icon = server.MatIcons.Info;
					Table = {
						{Text = `<b>Prefix:</b> {cmd.Prefix}`, Desc = "Prefix used to run the command"},
						{Text = `<b>Commands:</b> {SanitizeXML(table.concat(cmd.Commands, ", "))}`, Desc = "Valid default aliases for the command"},
						{Text = `<b>Arguments:</b> {if cmdArgs == "" then "-" else SanitizeXML(cmdArgs)}`, Desc = "Parameters taken by the command"},
						{Text = `<b>Admin Level:</b> {Admin.FormatCommandAdminLevel(cmd)}`, Desc = "Rank required to run the command"},
						{Text = `<b>Description:</b> {SanitizeXML(cmd.Description)}`, Desc = "Command description"},
						{Text = `<b>Attributes:</b> {if #cmdAttribs == 0 then "-" else table.concat(cmdAttribs, "; ")}`, Desc = "Extra data about the command"},
						{Text = `<b>Index:</b> {SanitizeXML(tostring(ind))}`, Desc = "The internal command index/identifier"},
					};
					RichText = true;
					Size = {400, 225};
				})
			end
		};

		Notepad = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notepad", "stickynote"};
			Args = {};
			Description = "Opens a textbox window for you to type into";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Notepad", {})
			end
		};

		Paint = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"paint", "canvas", "draw"};
			Args = {};
			Description = "Opens a canvas window for you to draw on";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Paint", {})
			end
		};

		Prefix = {
			Prefix = "!";
			Commands = {"example"};
			Args = {};
			Description = "Shows you the command prefix using the :cmds command";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Functions.Hint(`"{Settings.Prefix}cmds"`, {plr})
			end
		};

		NotifyMe = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notifyme"};
			Args = {"time (in seconds) or inf", "message"};
			Hidden = true;
			Description = "Sends yourself a notification";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing time amount")
				assert(args[2], "Missing message")
				Remote.MakeGui(plr, "Notification", {
					Title = "Notification";
					Icon = server.MatIcons["Notifications"];
					Message = args[2];
					Time = tonumber(args[1]);
				})
			end
		};

		CommsPanel = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"notifications", "comms", "nc", "commspanel"};
			Args = {};
			Description = "Opens the communications panel, showing you all the Adonis messages you have recieved in a timeline";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "CommsPanel")
			end
		};

		RandomNum = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"rand", "random", "randnum", "dice"};
			Args = {"num m", "num n"};
			Description = "Generates a number using Lua's math.random";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert((not args[1]) or tonumber(args[1]), "Argument(s) provided must be numbers")
				assert((not args[2]) or tonumber(args[2]), "Arguments provided must be numbers")

				if args[2] then
					assert(args[2] >= args[1], "Second argument n cannot be smaller than first")
					Functions.Hint(math.random(args[1], args[2]), {plr})
				elseif args[1] then
					Functions.Hint(math.random(args[1]), {plr})
				else
					Functions.Hint(math.random(), {plr})
				end
			end
		};

		BrickColorList = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"brickcolors", "colors", "colorlist"};
			Args = {};
			Description = "Shows you a list of Roblox BrickColors for reference";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local children = {
					Core.Bytecode([[Object:ResizeCanvas(false, true, false, false, 5, 5)]]);
				}

				local brickColorNames = {}
				for i = 1, 127 do
					table.insert(brickColorNames, BrickColor.palette(i).Name)
				end
				table.sort(brickColorNames)

				for i, bc in brickColorNames do
					bc = BrickColor.new(bc)
					table.insert(children, {
						Class = "TextLabel";
						Size = UDim2.new(1, -10, 0, 30);
						Position = UDim2.new(0, 5, 0, 30*(i-1));
						BackgroundTransparency = 1;
						TextXAlignment = "Left";
						Text = `  {bc.Name}`;
						ToolTip = string.format("RGB: %d, %d, %d | Num: %d", bc.r*255, bc.g*255, bc.b*255, bc.Number);
						ZIndex = 11;
						Children = {
							{
								Class = "Frame";
								BackgroundColor3 = bc.Color;
								Size = UDim2.new(0, 80, 1, -4);
								Position = UDim2.new(1, -82, 0, 2);
								ZIndex = 12;
							}
						};
					})
				end

				Remote.MakeGui(plr, "Window", {
					Name = "BrickColorList";
					Title = "BrickColors";
					Size  = {270, 300};
					MinSize = {150, 100};
					Content = children;
					Ready = true;
				})
			end
		};

		MaterialList = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"materials", "materiallist", "mats"};
			Args = {};
			Description = "Shows you a list of Roblox materials for reference";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local mats = {
					"Brick", "Cobblestone", "Concrete", "CorrodedMetal", "DiamondPlate", "Fabric", "Foil", "ForceField", "Glass", "Granite",
					"Grass", "Ice", "Marble", "Metal", "Neon", "Pebble", "Plastic", "Slate", "Sand", "SmoothPlastic", "Wood", "WoodPlanks",
					"Rock", "Glacier", "Snow", "Sandstone", "Mud", "Basalt", "Ground", "CrackedLava", "Asphalt", "LeafyGrass", "Salt", "Limestone", "Pavement"
				}
				for i, mat in mats do
					mats[i] = {Text = mat; Desc = `Enum value: {Enum.Material[mat].Value}`}
				end
				Remote.MakeGui(plr, "List", {Title = "Materials"; Tab = mats;})
			end
		};

		ClientTab = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"client", "clientsettings", "playersettings"};
			Args = {};
			Description = "Opens the client settings panel";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Client"})
			end
		};

		Donate = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donate", "change", "changecape", "donorperks"};
			Args = {};
			Description = "Opens the donation panel";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Donate"})
			end
		};

		GetScript = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getscript", "getadonis"};
			Args = {};
			Description = "Prompts you to take a copy of the script";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				service.MarketPlace:PromptPurchase(plr, Core.LoaderID)
			end
		};

		ClientPerfStats = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"cstats", "clientperformance", "clientperformanceststs", "clientstats", "ping", "latency", "fps","framespersecond"};
			Args = {};
			Description = "Shows you your client performance stats";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "PerfStats")
			end
		};

		ServerSpeed = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"serverspeed", "serverping", "serverfps", "serverlag", "tps"};
			Args = {};
			Description = "Shows you the FPS (speed) of the server";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Functions.Hint(`The server FPS is {math.round(service.Workspace:GetRealPhysicsFPS())}`, {plr})
			end
		};

		Donors = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"donors", "donorlist", "donatorlist", "donators"};
			Args = {"autoupdate? (default: true)"};
			Description = "Shows a list of Adonis donators who are currently in the server";
			AdminLevel = "Players";
			ListUpdater = function(plr: Player)
				local tab = {}
				for _, v in service.Players:GetPlayers() do
					if not Variables.IncognitoPlayers[v] and Admin.CheckDonor(v) then
						table.insert(tab, service.FormatPlayer(v))
					end
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.RemoveGui(plr, "DonorList")
				Remote.MakeGui(plr, "List", {
					Name = "DonorList";
					Title = "Donors In-Game";
					Icon = server.MatIcons["People alt"];
					Tab = Logs.ListUpdaters.Donors(plr);
					Update = "Donors";
					AutoUpdate = if not args[1] or string.lower(args[1]) == "true" or string.lower(args[1]) == "yes" then 2 else nil;
				})
			end
		};

		RequestHelp = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"help", "requesthelp", "gethelp", "lifealert", "sos"};
			Args = {"reason"};
			Description = "Calls admins for help";
			Filter = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				if Settings.HelpSystem == true then
					local num = 0
					local answered = false
					local pending = Variables.HelpRequests[plr.Name];
					local reason = args[1] or "No reason provided";

					if pending and os.time() - pending.Time < 30 then
						error("You can only send a help request once every 30 seconds.");
					elseif pending and pending.Pending then
						error("You already have a pending request")
					else
						service.TrackTask(`Thread: {plr} Help Request Handler`, function()
							Functions.Hint("Request sent", {plr})

							pending = {
								Time = os.time();
								Pending = true;
								Reason = reason;
							}

							Variables.HelpRequests[plr.Name] = pending;

							for ind, p in service.Players:GetPlayers() do
								Routine(function()
									if Admin.CheckAdmin(p) then
										local ret = Remote.MakeGuiGet(p, "Notification", {
											Title = "Help Request";
											Message = `{plr.Name} needs help! Reason: {pending.Reason}`;
											Icon = server.MatIcons.Mail;
											Time = 30;
											OnClick = Core.Bytecode("return true");
											OnClose = Core.Bytecode("return false");
											OnIgnore = Core.Bytecode("return false");
										})

										num += 1
										if ret then
											if not answered then
												answered = true
												Commands.Teleport.Function(plr, {p.Name, `@{plr.Name}`})
											else
												Remote.MakeGui(p, "Notification", {
													Title = "Help Request";
													Message = "Another admin has already responded to this request!";
													Icon = server.MatIcons.Mail;
													Time = 5;
												})
											end
										end
									end
								end)
							end

							local w = os.time()
							repeat task.wait(0.5) until os.time()-w>30 or answered

							pending.Pending = false;

							if not answered then
								Functions.Message('HelpSystem', "Help System", "Sorry but no one is available to help you right now", 'MatIcon://Warning', {plr})
							end
						end)
					end
				else
					Functions.Message('HelpSystem', "Help System", "The help system has been disabled by the place owner.", 'MatIcon://Error', {plr})
				end
			end
		};

		Rejoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"rejoin"};
			Args = {};
			Description = "Makes you rejoin the server";
			NoStudio = true; -- Commands which cannot be used in Roblox Studio (e.g. commands which use TeleportService)
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(#(service.Players:GetPlayers()) < service.Players.MaxPlayers or not Settings.DisableRejoinAtMaxPlayers, "Cannot rejoin while server is at max capacity.")
				service.TeleportService:TeleportAsync(game.PlaceId, {plr}, service.New("TeleportOptions", {
					ServerInstanceId = game.JobId
				}))
			end
		};

		Join = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"join", "follow", "followplayer"};
			Args = {"username"};
			Description = "Makes you follow the player you gave the username of to the server they are in";
			NoStudio = true; -- TeleportService cannot be used in Roblox Studio
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument #1 (username) is required")
				assert(#args[1] <= 20 and args[1]:match("^[%a%d_]+$"), "Invalid username provided")

				local UserId = Functions.GetUserIdFromNameAsync(args[1])
				if UserId then
					local success, found, _, placeId, jobId = pcall(service.TeleportService.GetPlayerPlaceInstanceAsync, service.TeleportService, UserId)
					if success then
						assert(jobId ~= service.DataModel.JobId, "You're already in this server!")
						if found and placeId and jobId then
							service.TeleportService:TeleportAsync(placeId, {plr}, service.New("TeleportOptions", {
								ServerInstanceId = jobId
							}))
							Functions.Hint("Teleporting...", {plr})
						else
							Functions.Hint(`{service.Players:GetNameFromUserIdAsync(UserId)} was not found playing this game`, {plr})
						end
					else
						Functions.Hint(`Unexpected internal error: {found}`, {plr})
					end
				else
					Functions.Hint(`'{args[1]}' is not a valid Roblox user`, {plr})
				end
			end
		};

		GlobalJoin = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"joinfriend", "globaljoin"};
			Args = {"username"};
			Description = "Joins your friend outside/inside of the game (must be online)";
			NoStudio = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string}) -- uses Player:GetFriendsOnline()
				--// NOTE: MAY NOT WORK IF "ALLOW THIRD-PARTY GAME TELEPORTS" (GAME SECURITY PERMISSION) IS DISABLED

				assert(args[1], "Argument #1 (username) is required")
				assert(#args[1] <= 20 and args[1]:match("^[%a%d_]+$"), "Invalid username provided")

				local UserId = Functions.Functions.GetUserIdFromNameAsync(args[1])
				if UserId then
					for _, v in plr:GetFriendsOnline() do
						if v.VisitorId == UserId then
							if v.IsOnline and v.PlaceId and v.GameId then
								service.TeleportService:TeleportAsync(v.PlaceId, {plr})
								Functions.Hint(string.format("Joining %s (%s)...", v.UserName, v.LastLocation or "unknown game"), {plr})
							else
								Functions.Hint(`{v.UserName} is not currently playing a game`, {plr})
							end

							return
						end
					end

					Functions.Hint("You are not a friend of the specified user", {plr})
				else
					Functions.Hint(`'{args[1]}' is not a valid Roblox user`, {plr})
				end
			end
		};

		Credits = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"credit", "credits"};
			Args = {};
			Description = "Shows you Adonis development credits";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Credits")
			end
		};

		ChangeLog = {
			Prefix = Settings.Prefix;
			Commands = {"changelog", "changes", "updates", "version"};
			Args = {};
			Description = "Shows you the script's changelog";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Change Log";
					Icon = server.MatIcons["Text snippet"];
					Table = server.Changelog;
					Size = {500, 400};
				})
			end
		};

		Quote = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"quote", "inspiration", "randomquote"};
			Args = {};
			Description = "Shows you a random quote";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local quotes = require(Deps.Assets.Quotes)
				Functions.Message('Command', "Random Quote", quotes[math.random(1, #quotes)], 'MatIcon://Chat', {plr})
			end
		};

		Usage = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"usage", "usermanual"};
			Args = {};
			Description = "Shows you how to use some syntax related things";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local usage = {
					"";
					"Mouse over things in lists to expand them";
					"You can also resize windows by dragging the edges";
					"";
					`Put <i>/e</i> in front to silence commands in chat (<i>/e {Settings.Prefix}kill scel</i>) or enable chat command hiding in client settings`;
					`Player commands can be used by anyone, these commands have <i>{Settings.PlayerPrefix}</i> infront, such as <i>{Settings.PlayerPrefix}info</i> and <i>{Settings.PlayerPrefix}rejoin</i>`;
					"";
					"<b>――――― Player Selectors ―――――</b>";
					`Usage example: <i>{Settings.Prefix}kill {Settings.SpecialPrefix}all</i> (where <i>{Settings.SpecialPrefix}all</i> is the selector)`;
					`<i>{Settings.SpecialPrefix}me</i> - Yourself`;
					`<i>{Settings.SpecialPrefix}all</i> - Everyone in the server`;
					`<i>{Settings.SpecialPrefix}admins</i> - All admins in the server`;
					`<i>{Settings.SpecialPrefix}nonadmins</i> - Non-admins (normal players) in the server`;
					`<i>{Settings.SpecialPrefix}others</i> - Everyone except yourself`;
					`<i>{Settings.SpecialPrefix}random</i> - A random person in the server excluding those removed with -SELECTION`;
					`<i>@USERNAME</i> - Targets a specific player with that exact username Ex: <i>{Settings.Prefix}god @Sceleratis </i> would give a player with the username 'Sceleratis' god powers`;
					`<i>#NUM</i> - NUM random players in the server <i>{Settings.Prefix}ff #5</i> will ff 5 random players excluding those removed with -SELECTION.`;
					`<i>{Settings.SpecialPrefix}friends</i> - Your friends who are in the server`;
					`<i>%TEAMNAME</i> - Members of the team TEAMNAME Ex: {Settings.Prefix}kill %raiders`;
					`<i>$GROUPID</i> - Members of the group with ID GROUPID (number in the Roblox group webpage URL)`;
					`<i>-SELECTION</i> - Inverts the selection, ie. will remove SELECTION from list of players to run command on. {Settings.Prefix}kill all,-%TEAM will kill everyone except players on TEAM`;
					`<i>+SELECTION</i> - Readds the selection, ie. will readd SELECTION from list of players to run command on. {Settings.Prefix}kill all,-%TEAM,+Lethalitics will kill everyone except players on TEAM but also Lethalitics`;
					`<i>radius-NUM</i> -- Anyone within a NUM-stud radius of you. {Settings.Prefix}ff radius-5 will ff anyone within a 5-stud radius of you.`;
					"";
					"<b>――――― Repetition ―――――</b>";
					"Multiple player selections - <i>{Settings.Prefix}kill me,noob1,noob2,{Settings.SpecialPrefix}random,%raiders,$123456,{Settings.SpecialPrefix}nonadmins,-scel</i>";
					"Multiple Commands at a time - <i>{Settings.Prefix}ff me {Settings.BatchKey} {Settings.Prefix}sparkles me {Settings.BatchKey} {Settings.Prefix}rocket jim</i>";
					"You can add a delay if you want; <i>{Settings.Prefix}ff me {Settings.BatchKey} !wait 10 {Settings.BatchKey} {Settings.Prefix}m hi we waited 10 seconds</i>";
					`<i>{Settings.Prefix}repeat 10(how many times to run the cmd) 1(how long in between runs) {Settings.Prefix}respawn jim</i>`;
					"";
					"<b>――――― Reference Info ―――――</b>";
					`<i>{Settings.Prefix}cmds</i> for a list of available commands`;
					`<i>{Settings.Prefix}cmdinfo &lt;command&gt;</i> for detailed info about a specific command`;
					`<i>{Settings.PlayerPrefix}brickcolors</i> for a list of BrickColors`;
					`<i>{Settings.PlayerPrefix}materials</i> for a list of materials`;
					"";
					`<i>{Settings.Prefix}capes</i> for a list of preset admin capes`;
					`<i>{Settings.Prefix}musiclist</i> for a list of preset audios`;
					`<i>{Settings.Prefix}insertlist</i> for a list of insertable assets using {Settings.Prefix}insert`;
				}
				Remote.MakeGui(plr, "List", {
					Title = "Usage";
					Tab = usage;
					Size = {300, 250};
					RichText = true;
				})
			end
		};

		UserPanel = {
			Prefix = "";
			Commands = {":userpanel"};
			Args = {};
			Hidden = true;
			Description = "Backup command for opening the userpanel window";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Info";})
			end
		};

		Theme = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"theme", "usertheme"};
			Args = {"theme name (leave blank to reset to default)"};
			Hidden = true;
			Description = "Changes the Adonis client UI theme";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local playerData = Core.GetPlayer(plr)
				local data = playerData.Client or {}
				data.CustomTheme = args[1]
				playerData.Client = data
				Core.SavePlayer(plr, playerData)
				Remote.MakeGui(plr, "Notification", {
					Title = "Theme Changed";
					Icon = server.MatIcons.Palette;
					Message = if args[1] then `UI theme set to '{args[1]}'!` else "UI theme reset to default.";
					Time = 5;
				})
				Remote.LoadCode(plr, `client.Variables.CustomTheme = {if args[1] then `[[{args[1]}]]` else "nil"}`)
			end
		};

		ScriptInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"info", "about", "userpanel", "script", "scriptinfo"};
			Args = {};
			Description = "Shows info about the admin system (Adonis)";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Info";})
			end
		};

		Aliases = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"aliases", "addalias", "removealias", "newalias"};
			Args = {};
			Description = "Opens the alias manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Aliases";})
			end
		};

		Keybinds = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"keybinds", "binds", "bind", "keybind", "clearbinds", "removebind"};
			Args = {};
			Description = "Opens the keybind manager";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "KeyBinds";})
			end
		};

		Invite = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"invite", "invitefriends"};
			Args = {};
			Description = "Invite your friends into the game";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				service.SocialService:PromptGameInvite(plr)
			end
		};

		OnlineFriends = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"onlinefriends", "friendsonline", "friends"};
			Args = {};
			Description = "Shows a list of your friends who are currently online";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Friends")
			end
		};

		BlockedUsers = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"blockedusers", "blockedplayers", "blocklist"};
			Args = {};
			Description = "Shows a list of people you've blocked on Roblox";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "BlockedUsers")
			end
		};

		GetPremium = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getpremium", "purchasepremium", "robloxpremium"};
			Args = {};
			Description = "Prompts you to purchase Roblox Premium";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				service.MarketplaceService:PromptPremiumPurchase(plr)
			end
		};

		AddFriend = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"addfriend", "friendrequest", "sendfriendrequest"};
			Args = {"player"};
			Description = "Send a friend request to the specified player";
			Hidden = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					assert(v ~= plr, "Cannot friend yourself!")
					assert(not plr:IsFriendsWith(v.UserId), `You are already friends with {v.Name}`)
					Remote.Send(plr, "Function", "SetCore", "PromptSendFriendRequest", v)
				end
			end
		};

		UnFriend = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unfriend", "removefriend"};
			Args = {"player"};
			Description = "Prompts you to unfriend the specified player";
			Hidden = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				for i, v: Player in service.GetPlayers(plr, args[1]) do
					assert(v ~= plr, "Cannot unfriend yourself!")
					assert(plr:IsFriendsWith(v.UserId), `You are not currently friends with {v.Name}`)
					Remote.Send(plr, "Function", "SetCore", "PromptUnfriend", v)
				end
			end
		};

		InspectAvatar = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"inspectavatar", "avatarinspect", "viewavatar", "examineavatar"};
			Args = {"player"};
			Description = "Opens the Roblox avatar inspect menu for the specified player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					Remote.LoadCode(plr, `service.GuiService:InspectPlayerFromUserId({v.UserId})`)
				end
			end
		};

		DevConsole = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"devconsole", "developerconsole", "opendevconsole"};
			Args = {};
			Description = "Opens the Roblox developer console";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.Send(plr, "Function", "SetCore", "DevConsoleVisible", true)
			end
		};

		NumPlayers = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pnum", "numplayers", "playercount"};
			Args = {};
			Description = "Tells you how many players are in the server";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local num = 0
				local nilNum = 0
				for _, v in service.GetPlayers() do
					if v.Parent ~= service.Players then
						nilNum += 1
					end
					num += 1
				end

				if nilNum > 0 and Admin.GetLevel(plr) >= Settings.Ranks.Moderators.Level then
					Functions.Hint(`There are currently {num} player(s); {nilNum} are nil or loading`, {plr})
				else
					Functions.Hint(`There are {num} player(s)`, {plr})
				end
			end
		};

		TimeDate = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"timedate", "date", "datetime"};
			Args = {};
			Description = "Shows you the current time and date.";
			AdminLevel = "Players";
			ListUpdater = function(plr: Player)
				local ostime = os.time()
				local tab = {
					{Text = "―――――――――――――――――――――――"},
					{"Date"; os.date("%x", ostime)},
					{"Time"; os.date("%H:%M | %I:%M %p", ostime)},
					{"Timezone"; os.date("%Z", ostime)},
					{Text = "―――――――――――――――――――――――"},
					{"Minute"; os.date("%M", ostime)},
					{"Hour"; os.date("%H | %I %p" , ostime)},
					{"Day"; os.date("%d %A", ostime)},
					{"Week (first Sunday)"; os.date("%U", ostime)},
					{"Week (first Monday)"; os.date("%W", ostime)},
					{"Month"; os.date("%m %B", ostime)},
					{"Year"; os.date("%Y", ostime)},
					{Text = "―――――――――――――――――――――――"},
					{"Day of the year"; os.date("%j", ostime)},
					{"Day of the month"; os.date("%d", ostime)},
					{Text = "―――――――――――――――――――――――"},
				}
				for i, v in tab do
					if not v[2] then continue end
					tab[i] = {Text = `<b>{v[1]}:</b> {v[2]}`; Desc = v[2];}
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Date";
					Table = Logs.ListUpdaters.TimeDate(plr);
					RichText = true;
					Update = "TimeDate";
					AutoUpdate = 59;
					Size = {288, 390};
				})
			end
		};

		PersonalCountdown = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"countdown", "timer", "cd"};
			Args = {"time (in seconds)"};
			Description = "Makes a countdown on your screen";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local num = assert(tonumber(args[1]), "Missing or invalid time value (must be a number)")
				assert(num <= 1000, "Countdown cannot be longer than 1000 seconds.")
				assert(num >= 0, "Countdown cannot be negative.")
				Remote.MakeGui(plr, "Countdown", {
					Time = math.round(num);
				})
			end
		};

		PersonalStopwatch = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"stopwatch"};
			Args = {};
			Description = "Makes a stopwatch on your screen";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Stopwatch")
			end
		};

		ViewProfile = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"profile", "inspect", "playerinfo", "whois", "viewprofile"};
			Args = {"player"};
			Description = "Shows comphrehensive information about a player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local elevated: boolean = Admin.CheckAdmin(plr)
				local players = service.GetPlayers(plr, args[1], {NoFakePlayer = true; NoSelectors = not elevated;})

				if #players > 2 then
					Functions.Hint(string.format("Loading profile data for %d players... [This may take a while]", #players), {plr})
				end

				for _, v: Player in players do
					task.defer(function()
						local gameData

						if elevated then
							local level, rank = Admin.GetLevel(v)
							gameData = {
								IsMuted = table.find(Settings.Muted, `{v.Name}:{v.UserId}`) and true or false;
								AdminLevel = `[{level}] {rank or "Unknown"}`;
								SourcePlaceId = v:GetJoinData().SourcePlaceId or "N/A";
							}
							for k, d in Remote.Get(v, "Function", "GetUserInputServiceData") do
								gameData[k] = d
							end
						end

						local policyInfo = elevated and select(2, xpcall(service.PolicyService.GetPolicyInfoForPlayerAsync, function() return "[Error]" end, service.PolicyService, v))
						local hasSafeChat = if policyInfo then
							type(policyInfo) == "string" and policyInfo or table.find(policyInfo.AllowedExternalLinkReferences, "Discord") and "No" or "Yes"
							else "[Redacted]"
						
						local mailVerif = select(2, xpcall(service.MarketplaceService.PlayerOwnsAsset, function() return "[Error]" end, service.MarketplaceService, v, 102611803))
						local hasVerifiedMail = if elevated then
							type(mailVerif) == "string" and mailVerif or mailVerif and "Yes" or "No"
							else "[Redacted]"
						
						local idVerif = select(2, xpcall(v.IsVerified, function() return "[Error]" end, v))
						local hasVerifiedId = if elevated then
							type(idVerif) == "string" and idVerif or idVerif and "Yes" or "No"
							else "[Redacted]"

						Remote.RemoveGui(plr, `Profile_{v.UserId}`)
						Remote.MakeGui(plr, "Profile", {
							Target = v;
							SafeChat = hasSafeChat;
							CanChatGet = table.pack(pcall(service.Chat.CanUserChatAsync, service.Chat, v.UserId));
							MailVerified = hasVerifiedMail;
							IDVerified = hasVerifiedId;
							IsDonor = Admin.CheckDonor(v);
							GameData = gameData;
							IsServerOwner = v.UserId == game.PrivateServerOwnerId;
							CmdPrefix = Settings.Prefix;
							CmdSplitKey = Settings.SplitKey;
						})
					end)
				end
			end
		};

		ServerDetails = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"serverinfo", "server", "serverdetails", "gameinfo", "gamedetails"};
			Args = {};
			Description = "Shows you details about the current server";
			AdminLevel = "Players";
			ListUpdater = function(plr: Player)
				local elevated = Admin.CheckAdmin(plr)
				local data = {}

				local donorList = {}
				for _, v in service.GetPlayers() do
					if not Variables.IncognitoPlayers[v] and Admin.CheckDonor(v) then
						table.insert(donorList, v.Name)
					end
				end

				local adminDictionary, workspaceInfo
				if elevated then
					adminDictionary = {}
					for _, v in service.GetPlayers() do
						local level, rank = Admin.GetLevel(v)
						if level > 0 then
							adminDictionary[v.Name] = rank or "Unknown"
						end
					end
					local nilPlayers = 0
					for _, v in service.NetworkServer:GetChildren() do
						if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
							nilPlayers += 1
						end
					end
					workspaceInfo = {
						ObjectCount = #Variables.Objects;
						CameraCount = #Variables.Cameras;
						NilPlayerCount = nilPlayers;
						HttpEnabled = HTTP.CheckHttp();
						LoadstringEnabled = HTTP.LoadstringEnabled;
					}
				end

				return {Admins = adminDictionary; Donors = donorList; WorkspaceInfo = workspaceInfo;}
			end;
			Function = function(plr: Player, args: {string})
				local elevated = Admin.CheckAdmin(plr)

				local serverInfo = select(2, xpcall(function()
					local res = service.HttpService:JSONDecode(service.HttpService:GetAsync("http://ip-api.com/json"))
					return {
						country = res.country,
						city = res.city,
						region = res.region,
						zipcode = res.zip or "N/A",
						timezone = res.timezone,
						query = elevated and res.query or "[Redacted]",
						coords = elevated and string.format("LAT: %s, LON: %s", res.lat, res.lon) or "[Redacted]",
					}
				end, function() return end))

				Remote.MakeGui(plr, "ServerDetails", {
					CreatorId = game.CreatorId;
					PrivateServerId = game.PrivateServerId;
					PrivateServerOwnerId = game.PrivateServerOwnerId;
					ServerStartTime = server.ServerStartTime;
					ServerAge = service.FormatTime(os.time() - server.ServerStartTime);
					ServerInternetInfo = serverInfo;
					Refreshables = Logs.ListUpdaters.ServerDetails(plr);
					CmdPrefix = Settings.Prefix;
					CmdPlayerPrefix = Settings.PlayerPrefix;
					SplitKey = Settings.SplitKey;
				})
			end
		};

		GetGroupInfo = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"getgroupinfo", "groupinfo", "viewgroupinfo"};
			Args = {"group ID"};
			Description = "Shows you information about the specified Roblox group";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local groupId = assert(args[1] and tonumber(args[1]), "Missing/invalid group ID")
				local groupInfo = assert(select(2, xpcall(service.GroupService.GetGroupInfoAsync, function() return nil end, service.GroupService, groupId)), "Error fetching data")
				local tab = {
					`Name: {groupInfo.Name}`,
					`ID: {groupInfo.Id}`,
					if groupInfo.Owner then string.format("Owner: %s [%d]", groupInfo.Owner.Name or "???", groupInfo.Owner.Id) else "[No Owner]",
					{Text = string.format("――― Roles (%d): ―――――――――――――――――", #groupInfo.Roles)},
				}
				for _, role in groupInfo.Roles do
					table.insert(tab, string.format("[%d] %s", role.Rank, role.Name))
				end

				local function getPageItems(pages: StandardPages, res: {any})
					res = res or {}
					for _, item in pages:GetCurrentPage() do
						table.insert(res, item)
					end
					if not pages.IsFinished then
						pages:AdvanceToNextPageAsync()
						getPageItems(pages, res)
					end
					return res
				end

				local done = false
				local startTime = os.clock()
				task.defer(function()
					local allies = getPageItems(service.GroupService:GetAlliesAsync(groupId))
					table.insert(tab, {Text = string.format("――― Allies (%d): ―――――――――――――――――", #allies)})
					if #allies > 0 then
						local names, refs = {}, {}
						for _, grp in allies do
							table.insert(names, grp.Name)
							refs[grp.Name] = grp
						end
						table.sort(names)
						for _, name in names do
							local grp = refs[name]
							table.insert(tab, {Text = string.format("[#%d] %s", grp.Id, name), Desc = `Owner: {if grp.Owner then string.format("%s [%d]", grp.Owner.Name or "???", grp.Owner.Id) else "[No Owner]"}`})
						end
					else
						table.insert(tab, {Text = "This group doesn't have any allies."})
					end

					local enemies = getPageItems(service.GroupService:GetEnemiesAsync(groupId))
					table.insert(tab, {Text = string.format("――― Enemies (%d): ―――――――――――――――――", #enemies)})
					if #enemies > 0 then
						local names, refs = {}, {}
						for _, grp in enemies do
							table.insert(names, grp.Name)
							refs[grp.Name] = grp
						end
						table.sort(names)
						for _, name in names do
							local grp = refs[name]
							table.insert(tab, {Text = string.format("[#%d] %s", grp.Id, name), Desc = `Owner: {if grp.Owner then string.format("%s [%d]", grp.Owner.Name or "???", grp.Owner.Id) else "[No Owner]"}`})
						end
					else
						table.insert(tab, {Text = "This group doesn't have any enemies."})
					end

					table.insert(tab, {Text = "―――――――――――――――――――――――"})
					Remote.MakeGui(plr, "List", {
						Title = string.format("Group Information (%.2fs)", os.clock() - startTime);
						Icon = server.MatIcons.Info;
						Tab = tab;
						Size = {300, 300};
					})
					done = true
				end)
				task.delay(5, function()
					if not done then
						Functions.Hint("Taking a while to load group information...", {plr})
						task.delay(10, function()
							if not done then
								Functions.Hint("We're still loading group info...", {plr})
							end
						end)
					end
				end)
			end
		};

		AudioPlayer = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"ap", "audioplayer", "mp", "musicplayer"};
			Args = {"soundId?"};
			Description = "Opens the audio player";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local canUseGlobalBroadcast
				local cmd, ind
				for i, v in Admin.SearchCommands(plr, "all") do
					for _, p in ipairs(v.Commands) do
						if (v.Prefix or "")..string.lower(p) == (v.Prefix or "")..string.lower("music") then
							cmd, ind = v, i
							break
						end
					end
					if ind then break end
				end
				if cmd then
					canUseGlobalBroadcast = true
				else
					canUseGlobalBroadcast = false
				end
				Remote.MakeGui(plr, "Music", {
					Song = args[1],
					GlobalPerms = canUseGlobalBroadcast
				})
			end
		};

		CountryList = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"countries", "countrylist", "countrycodes"},
			Args = {},
			Description = "Shows you a list of countries and their respective codes",
			AdminLevel = "Players";
			Hidden = true;
			Function = function(plr: Player, args: {string})
				local list = {}
				for code, name in require(server.Dependencies.CountryRegionCodes) do
					table.insert(list, `{code} - {name}`)
				end
				table.sort(list)
				Remote.MakeGui(plr, "List", {
					Title = "Countries";
					Icon = server.MatIcons.Language;
					Table = list;
				})
			end
		};

		BuyItem = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"buyitem", "buyasset"};
			Args = {"id"};
			Description = "Prompts yourself to buy the asset belonging to the ID supplied";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local assetId = assert(tonumber(args[1]), "Missing asset ID (argument #1)")
				local success, assetAlreadyOwned = pcall(service.MarketplaceService.PlayerOwnsAsset, service.MarketplaceService, plr, assetId)
				assert(not (success and assetAlreadyOwned), "You already own the asset!")
				local success, assetInfo = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, assetId)
				assert(success and not assetInfo.IsLimited, "Cannot buy limited assets!")
				local connection; connection = service.MarketplaceService.PromptPurchaseFinished:Connect(function(_, boughtAssetId, isPurchased)
					if boughtAssetId == assetId then
						connection:Disconnect()
						Functions.Notification("Adonis purchase", (isPurchased and string.format("Asset %d was purchased successfully!", assetId) or string.format("Asset %d was not bought", assetId)), {plr}, 10, "MatIcon://Shopping cart")
					end
				end)
				service.MarketplaceService:PromptPurchase(plr, assetId, false)
			end
		};
	};
end
