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
			Args = {"username(s)", "reason"};
			Description = "Adds the specified user(s) to the global ban list; saves";
			AdminLevel = "Creators";
			Filter = true;
			Hidden = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local reason = args[2] or "No reason provided"

				for i in string.gmatch(assert(args[1], "Missing target username (argument #1)"), "[^,]+") do
					local userExists, userId = pcall(service.Players.GetUserIdFromNameAsync, service.Players, i)
					if userExists then
						if userId == plr.UserId then
							Functions.Hint("You cannot ban yourself", {plr})
							continue
						end

						local getNameSuccess, username = pcall(service.Players.GetNameFromUserIdAsync, service.Players, userId)
						if not getNameSuccess then
							username = i
						end

						Admin.AddBan({UserId = userId, Name = username}, reason, true, plr)

						Functions.Hint("Direct-banned "..(if getNameSuccess then "@"..username else "'"..username.."'").." from the game", {plr})
					else
						Functions.Hint("No user named '"..i.."' exists! (Please try again if you think this is an internal error)", {plr})
					end
				end
			end
		};

		UnDirectBan = {
			Prefix = Settings.Prefix;
			Commands = {"directunban", "undirectban"};
			Args = {"username(s)"};
			Description = "Removes the specified user(s) from the global ban list; saves";
			AdminLevel = "Creators";
			Hidden = true;
			Function = function(plr: Player, args: {string}, data: {any})
				for i in string.gmatch(assert(args[1], "Missing target username (argument #1)"), "[^,]+") do
					local userExists, userId = pcall(service.Players.GetUserIdFromNameAsync, service.Players, i)
					if userExists then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = i..":"..userId;
						})

						local getNameSuccess, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, userId)
						if getNameSuccess then
							Core.DoSave({
								Type = "TableRemove";
								Table = "Banned";
								Value = i..":"..actualName;
							})
						end

						Functions.Hint((if getNameSuccess then "@"..actualName else "'"..i.."'").." has been unbanned from the game", {plr})
					else
						Functions.Hint("No user named '"..i.."' exists! (Please try again if you think this is an internal error)", {plr})
					end
				end
			end
		};

		GlobalPlace = {
			Prefix = Settings.Prefix;
			Commands = {"globalplace", "gplace", "globalforceplace"};
			Args = {"placeId"};
			Description = "Force all game-players to teleport to a desired place";
			AdminLevel = "Creators";
			CrossServerDenied = true;
			IsCrossServer = true;
			NoStudio = true;
			Function = function(plr: Player, args: {string})
				local placeId = assert(tonumber(args[1]), "Invalid/missing PlaceId (argument #2)")

				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Title = "Force-teleport all users?";
					Icon = server.MatIcons.Warning;
					Question = "Would you really like to force all game-players to teleport to place '".. placeId.."'?";
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."forceplace all "..placeId) then
						error("CrossServer handler not ready; please try again later")
					end
				else
					Functions.Hint("Operation cancelled", {plr})
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
					Functions.Hint(string.format("Failed to teleport %s: [%s] %s", service.FormatPlayer(p), teleportResult.Name, errorMessage or "???"), {plr})
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
				local amount = assert(tonumber(args[2]), "Invalid/no amount provided (argument #2 must be a number)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local ran, failed = pcall(service.PointsService.AwardPoints, service.PointsService, v.UserId, amount)
					if ran and service.PointsService:GetAwardablePoints() >= amount then
						Functions.Hint("Gave "..amount.." points to "..service.FormatPlayer(v), {plr})
					elseif service.PointsService:GetAwardablePoints() < amount then
						Functions.Hint("You don't have "..amount.." points to give to "..service.FormatPlayer(v), {plr})
					else
						Functions.Hint("(Unknown Error) Failed to give "..amount.." points to "..service.FormatPlayer(v), {plr})
					end
					Functions.Hint("Available Player Points: "..service.PointsService:GetAwardablePoints(), {plr})
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
				for _, v in service.GetPlayers(plr, args[1]) do
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
						Functions.Hint(service.FormatPlayer(v).." is now a permanent head admin", {plr})
					else
						Functions.Hint(service.FormatPlayer(v).." is already the same admin level as you or higher", {plr})
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
				for _, v in service.GetPlayers(plr, args[1]) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel > targLevel then
						Admin.AddAdmin(v, "HeadAdmins", true)
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are a temp head admin. Click to view commands.";
							Time = 10;
							Icon = "rbxassetid://7536784790";
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(service.FormatPlayer(v).." is now a temporary head admin", {plr})
					else
						Functions.Hint(service.FormatPlayer(v).." is already the same admin level as you or higher", {plr})
					end
				end
			end
		};

		Sudo = {
			Prefix = Settings.Prefix;
			Commands = {"sudo"};
			Args = {"player", "command"};
			Description = "Runs a command as the target player(s)";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target player (argument #1)")
				assert(args[2], "Missing command string (argument #2)")
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = false}) do
					task.defer(Process.Command, v, args[2], {isSystem = true})
				end
			end
		};

		ClearPlayerData = {
			Prefix = Settings.Prefix;
			Commands = {"clearplayerdata", "clrplrdata", "clearplrdata", "clrplayerdata"};
			Args = {"UserId"};
			Description = "Clears PlayerData linked to the specified UserId";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				local id = assert(tonumber(args[1]), "Must supply a valid UserId (argument #1)")
				local username = select(2, xpcall(function()
					return service.Players:GetNameFromUserIdAsync(id)
				end, function() return "[Unknown User]" end))

				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = "Clearing all PlayerData for "..username.." will erase all warns, notes, bans, and other data associated with them, such as theme preference.\n Are you sure you want to erase "..username.."'s PlayerData? This action is irreversible.";
					Title = "Clear PlayerData for "..username.."?";
					Icon = server.MatIcons.Info;
					Size = {300, 200};
				})
				if ans == "Yes" then
					Core.RemoveData(tostring(id))
					Core.PlayerData[tostring(id)] = nil

					Remote.MakeGui(plr, "Notification", {
						Title = "Notification";
						Icon = server.MatIcons["Delete"];
						Message = string.format("Cleared data for %s [%d].", username, id);
						Time = 10;
					})
				else
					Functions.Hint("Operation cancelled", {plr})
				end
			end
		};

		Terminal = {
			Prefix = "";
			Commands = {Settings.Prefix.."terminal", Settings.Prefix.."console", ":terminal", ":console"};
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
