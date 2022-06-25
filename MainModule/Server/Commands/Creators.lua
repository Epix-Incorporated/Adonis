return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		DirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"directban"};
			Args = {"username", "reason"};
			Description = "DirectBans the specified user (Saves)";
			AdminLevel = "Creators";
			Filter = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local reason = args[2] or "No reason provided"

				for i in string.gmatch(args[1], "[^,]+") do
					local UserId = service.Players:GetUserIdFromNameAsync(i)

					if UserId == plr.UserId then
						error("You cannot ban yourself or the creator of the game", 2)
						return
					end

					if UserId then
						Admin.AddBan({UserId = UserId, Name = i}, reason, true, plr)
						Functions.Hint("Direct banned "..i, {plr})
					end
				end
			end
		};

		UnDirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"undirectban"};
			Args = {"username"};
			Description = "UnDirectBans the player (Saves)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				for i in string.gmatch(args[1], "[^,]+") do

					local userid = service.Players:GetUserIdFromNameAsync(i)

					if userid then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = i..':'..userid;
						})

						Functions.Hint(i.." has been Unbanned", {plr})
					end
				end
			end
		};

		GlobalPlace = {
			Prefix = Settings.Prefix;
			Commands = {"globalplace", "gplace"};
			Args = {"placeId"};
			Description = "Force all game-players to teleport to a desired place";
			AdminLevel = "Creators";
			CrossServerDenied = true;
			IsCrossServer = true;
			NoStudio = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing PlaceId")
				assert(tonumber(args[1]), "Invalid PlaceId")

				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = "Force all game-players to teleport to place '".. args[1].."'?";
					Title = "Force teleport all users?";
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."forceplace all "..args[1]) then
						error("CrossServer Handler Not Ready")
					end
				end
			end;
		};

		ForcePlace = {
			Prefix = Settings.Prefix;
			Commands = {"forceplace"};
			Args = {"player", "placeId/serverName"};
			Description = "Force the target player(s) to teleport to the desired place";
			NoStudio = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local reservedServerInfo = (Core.GetData("PrivateServers") or {})[args[2]]
				local placeId = assert(if reservedServerInfo then reservedServerInfo.ID else tonumber(args[2]), "Invalid place ID or server name (argument #2)")
				local players = service.GetPlayers(plr, args[1])
				local teleportOptions = if reservedServerInfo then service.New("TeleportOptions", {
					ReservedServerAccessCode = reservedServerInfo.Code
				}) else nil

				local teleportValidation = service.TeleportService.TeleportInitFailed:Connect(function(p: Player, teleportResult: Enum.TeleportResult, errorMessage: string)
					Function.Hint(string.format("Failed to teleport %s: [%s] %s", service.FormatPlayer(p), teleportResult.Name, errorMessage or "???"), {plr})
				end)
				local success, fault = pcall(service.TeleportService.TeleportAsync, service.TeleportService, placeId, players, teleportOptions)
				teleportValidation:Disconnect()
				if success and plr and plr.Parent == service.Players then
					Functions.Hint("Teleport success", {plr})
				elseif not success then
					error(fault)
				end
			end
		};

		GivePlayerPoints = { --// obsolete since ROBLOX discontinued player points
			Prefix = Settings.Prefix;
			Commands = {"giveppoints", "giveplayerpoints", "sendplayerpoints"};
			Args = {"player", "amount"};
			Hidden = true;
			Description = "Lets you give <player> <amount> player points";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local ran, failed = pcall(function() service.PointsService:AwardPoints(v.UserId, tonumber(args[2])) end)
					if ran and service.PointsService:GetAwardablePoints() >= tonumber(args[2]) then
						Functions.Hint('Gave '..args[2]..' points to '..v.Name, {plr})
					elseif service.PointsService:GetAwardablePoints() < tonumber(args[2]) then
						Functions.Hint("You don't have "..args[2]..' points to give to '..v.Name, {plr})
					else
						Functions.Hint("(Unknown Error) Failed to give "..args[2]..' points to '..v.Name, {plr})
					end
					Functions.Hint('Available Player Points: '..service.PointsService:GetAwardablePoints(), {plr})
				end
			end
		};

		Settings = {
			Prefix = "";
			Commands = {":adonissettings", Settings.Prefix.. "settings", Settings.Prefix.. "adonissettings"};
			Args = {};
			Description = "Opens the Adonis settings management interface";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "UserPanel", {Tab = "Settings"})
			end
		};

		MakeHeadAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"headadmin", "owner", "hadmin", "oa"};
			Args = {"player"};
			Description = "Makes the target player(s) a HeadAdmin; Saves";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				local sendLevel = data.PlayerData.Level
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel > targLevel then
						Admin.AddAdmin(v, "HeadAdmins")
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are a head admin. Click to view commands.";
							Time = 10;
							Icon = "rbxassetid://7536784790";
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a head admin', {plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
					end
				end
			end
		};

		TempHeadAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempheadadmin", "tempowner", "toa", "thadmin"};
			Args = {"player"};
			Description = "Makes the target player(s) a temporary head admin; Does not save";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				local sendLevel = data.PlayerData.Level
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "HeadAdmins", true)
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are a temp head admin. Click to view commands.";
							Time = 10;
							Icon = "rbxassetid://7536784790";
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a temp head admin', {plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
					end
				end
			end
		};

		Sudo = {
			Prefix = Settings.Prefix;
			Commands = {"sudo"};
			Arguments = {"player", "command"};
			Description = "Runs a command as the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name");
				assert(args[2], "Missing command name");
				for i, v in pairs(Functions.GetPlayers(plr, args[1])) do
					Process.Command(v, args[2], {isSystem = true})
				end
			end;
		};

		ClearPlayerData = {
			Prefix = Settings.Prefix;
			Commands = {"clearplayerdata", "clrplrdata", "clearplrdata"};
			Arguments = {"UserId"};
			Description = "Clears PlayerData linked to the specified UserId";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local id = tonumber(args[1])
				assert(id, "Must supply a valid UserId")
				local username = select(2, xpcall(function()
					return service.Players:GetNameFromUserIdAsync(args[1])
				end, function() return "[Unknown User]" end))
				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = "Clearing all PlayerData for "..username.." will erase all warns, notes, bans, and other data associated with " ..username.. " such as theme preference.\n Are you sure you want to erase "..username.."'s PlayerData? This action is irreversible.";
					Title = "Clear PlayerData for "..username.."?";
					Size = {281.25, 187.5};
				})
				if ans == "Yes" then
					Core.RemoveData(tostring(id))
					Core.PlayerData[tostring(id)] = nil

					Remote.MakeGui(plr, "Notification", {
						Title = "Notification";
						Icon = server.MatIcons["Delete"];
						Message = "Cleared data for ".. id;
						Time = 10;
					})
				end
			end;
		};

		Terminal = {
			Prefix = "";
			Commands = {Settings.Prefix.."terminal", Settings.Prefix.."console", ":terminal", ":console"};
			Args = {};
			Description = "Opens the debug terminal";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Terminal")
			end
		};

		--[[
		TaskManager = { --// Unfinished
			Prefix = Settings.Prefix;
			Commands = {"taskmgr", "taskmanager"};
			Args = {};
			Description = "Task manager";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "TaskManager", {})
			end
		};
		--]]
	}
end
