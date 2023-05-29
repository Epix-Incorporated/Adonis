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
					local UserId = Functions.GetUserIdFromNameAsync(i)
					if UserId then
						if UserId == plr.UserId then
							Functions.Hint("You cannot ban yourself", {plr})
							continue
						end

						local getNameSuccess, username = pcall(service.Players.GetNameFromUserIdAsync, service.Players, UserId)
						if not getNameSuccess then
							username = i
						end

						Admin.AddBan({
							UserId = UserId,
							Name = username
						}, reason, true, plr)

						Functions.Hint(`Direct-banned {if getNameSuccess then `@{username}` else `'{username}'`} from the game`, {plr})
					else
						Functions.Hint(`No user named '{i}' exists! (Please try again if you think this is an internal error)`, {plr})
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
					local UserId = Functions.GetUserIdFromNameAsync(i)
					if UserId then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = `{i}:{UserId}`;
						})

						local getNameSuccess, actualName = pcall(service.Players.GetNameFromUserIdAsync, service.Players, UserId)
						if getNameSuccess then
							Core.DoSave({
								Type = "TableRemove";
								Table = "Banned";
								Value = `{i}:{actualName}`;
							})
						end

						Functions.Hint(`{if getNameSuccess then `@{actualName}` else `'{i}'`} has been unbanned from the game`, {plr})
					else
						Functions.Hint(`No user named '{i}' exists! (Please try again if you think this is an internal error)`, {plr})
					end
				end
			end
		};

		Settings = {
			Prefix = "";
			Commands = {":adonissettings", `{Settings.Prefix}settings`, `{Settings.Prefix}adonissettings`};
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
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`);
						})
						Functions.Hint(`{service.FormatPlayer(v)} is now a permanent head admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v)} is already the same admin level as you or higher`, {plr})
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
							OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`);
						})
						Functions.Hint(`{service.FormatPlayer(v)} is now a temporary head admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v)} is already the same admin level as you or higher`, {plr})
					end
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
					Question = `Clearing all PlayerData for {username} will erase all warns, notes, bans, and other data associated with them, such as theme preference.\n Are you sure you want to erase {username}'s PlayerData? This action is irreversible.`;
					Title = `Clear PlayerData for {username}?`;
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
	}
end
