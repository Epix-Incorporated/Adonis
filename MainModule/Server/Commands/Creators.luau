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
					Question = `Would you really like to force all game-players to teleport to place '{placeId}'?`;
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, `{Settings.Prefix}forceplace all {placeId}`) then
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
			CrossServerDenied = true;
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
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local sendLevel = data.PlayerData.Level
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel > targLevel then
						Admin.AddAdmin(v, "HeadAdmins")
						Functions.Notification("Notification", "You are a head admin. Click to view commands.", {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
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
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local sendLevel = data.PlayerData.Level
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel > targLevel then
						Admin.AddAdmin(v, "HeadAdmins", true)
						Functions.Notification("Notification", "You are a temp head admin. Click to view commands.", {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v)} is now a temporary head admin`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v)} is already the same admin level as you or higher`, {plr})
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
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target player (argument #1)")
				assert(args[2], "Missing command string (argument #2)")
				for _, v in service.GetPlayers(plr, args[1]) do
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
					Question = `Clearing all PlayerData for {username} will erase all warns, notes, bans, and other data associated with them, such as theme preference.\n Are you sure you want to erase {username}'s PlayerData? This action is irreversible.`;
					Title = `Clear PlayerData for {username}?`;
					Icon = server.MatIcons.Info;
					Size = {300, 200};
				})
				if ans == "Yes" then
					Core.RemoveData(tostring(id))
					Core.PlayerData[tostring(id)] = nil
					Functions.Notification("Notification", string.format("Cleared data for %s [%d].", username, id), {plr}, 10, "MatIcon://Delete")
				else
					Functions.Hint("Operation cancelled", {plr})
				end
			end
		};

		Terminal = {
			Prefix = "";
			Commands = {`{Settings.Prefix}terminal`, `{Settings.Prefix}console`, ":terminal", ":console"};
			Description = "Opens the debug terminal";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Terminal")
			end
		};

		ScriptEditor = {
			Prefix = Settings.Prefix;
			Commands = {"scripteditor", "se"};
			Args = {"new/edit/delete/run","name"};
			Description = "Opens Script editor";
			CrossServerDenied = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				assert(plr ~= false and not service.Wrapped(plr), "A player is needed to run CodeExecution related commands.")

				if type(Remote.RemoteExecutionConfirmed) == "table" and not Remote.RemoteExecutionConfirmed[tostring(plr.UserId)] then
					local ans = Remote.GetGui(plr, "YesNoPrompt", {
						Icon = server.MatIcons.Warning;
						Question = "Are you sure you want to use the script editor command? (Once confirmed, you will not be asked again)";
						Title = "Adonis ScriptEditor";
						Delay = 3;
					})

					if ans == "Yes" then
						Remote.RemoteExecutionConfirmed[tostring(plr.UserId)] = true
					else
						return
					end
				end

				local Operation = assert(args[1], "Operation not defined (argument #1)")
				local Name = assert(args[2], "Name not defined (argument #2)")
				local se = Variables.ScriptEditor[tostring(plr.UserId)]
				if not se then
					se = {}
					Variables.ScriptEditor[tostring(plr.UserId)] = se
				end

				if Operation:lower() == "new" then
					se[Name] = {
						Script = false;
					}

					Commands.ScriptEditor.Function(plr,{"edit",Name})
				elseif Operation:lower() == "edit" then
					Remote.MakeGui(plr, "ScriptEditor",{
						Name = Name;
						Script = se[Name].Script
					})
				elseif Operation:lower() == "delete" then
					assert(se[Name], "No script found")

					se[Name] = nil
				elseif Operation:lower() == "run" then
					assert(se[Name], "No script found")

					local oError = error
					local newenv = setfenv(getfenv(),{
						print = function(...) local args, str = table.pack(...), "" for i = 1, args.n do str ..= `{(i > 1 and " " or "")}{args[i]}` end Remote.MakeGui(plr, "Output",{Title = "WARN"; Message = `{str}`}) end;
						warn = function(...) local args, str = table.pack(...), "" for i = 1, args.n do str ..= `{(i > 1 and " " or "")}{args[i]}` end Remote.MakeGui(plr, "Output",{Title = "WARN"; Message = `{str}`}) end;
						error = function(reason, level)
							if level ~= nil and type(level) ~= "number" then
								oError(string.format("bad argument #2 to 'error' (number expected, got %s)", type(level)), 2)
							end

							Remote.MakeGui(plr, "Output",{Title = "LUA_DEMAND_ERROR"; Message = `LUA_DEMAND_ERROR: {reason}`})
							oError(`Adonis ScriptEditor error: {reason}`, (level or 1) + 1)
						end;
					})

					service.TrackTask(`Thread: ScriptEditor: {plr.UserId}: {Name}`,function()
						local func,err = Core.Loadstring(se[Name]["Script"], newenv)
						if func then
							local Succ,Err = pcall(function()
								func()
							end)

							Remote.MakeGui(plr,'Output',{Title = 'ScriptEditor error'; Message = `ScriptEditor error: {Err}`})
						else
							Remote.MakeGui(plr,'Output',{Title = 'ScriptEditor error'; Message = `ScriptEditor error: {err}`})
						end
					end)
				end
			end,
		};

		CreateStarterScript = {
			Prefix = Settings.Prefix;
			Commands = {"starterscript", "clientstarterscript", "starterclientscript", "createstarterscript"};
			Args = {"name", "code"};
			Description = "Executes the given code on everyone's client upon respawn";
			AdminLevel = "Creators";
			NoFilter = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				assert(Settings.CodeExecution, "CodeExecution must be enabled for this command to work")
				assert(plr ~= false and not service.Wrapped(plr), "A player is needed to run CodeExecution related commands.")

				if type(Remote.RemoteExecutionConfirmed) == "table" and not Remote.RemoteExecutionConfirmed[tostring(plr.UserId)] then
					local ans = Remote.GetGui(plr, "YesNoPrompt", {
						Icon = server.MatIcons.Warning;
						Question = "Are you sure you want to use the starterscript command? (Once confirmed, you will not be asked again)";
						Title = "Adonis StarterScript";
						Delay = 3;
					})

					if ans == "Yes" then
						Remote.RemoteExecutionConfirmed[tostring(plr.UserId)] = true
					else
						return
					end
				end

				assert(args[1], "Missing starter script name (argument #1)")
				assert(args[2], "Missing LocalScript code (argument #2)")

				local bytecode = Core.Bytecode(args[2])
				assert(string.find(bytecode, "\27Lua"), `LocalScript unable to be created: {string.gsub(bytecode, "Loadstring%.LuaX:%d+:", "")}`)

				local new = Core.NewScript("LocalScript", args[2], true)
				new.Name = `[Adonis] {args[1]}`
				new.Parent = service.StarterGui
				new.Disabled = false
				Functions.Hint("Created starter script", {plr})
			end
		};

		ClearOldLogs = {
			Prefix = Settings.Prefix;
			Commands = {"clearoldlogs","flusholdlogs"};
			Description = "Clears old logs";
			AdminLevel = "Creators";
			Function = function(plr: Player)
				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = `Are you sure you want to clear old logs (this will be saved in old logs)`;
					Title = `Clear Old Logs`;
					Icon = server.MatIcons.Info;
					Size = {300, 200};
				})
				if ans == "Yes" then
					Core.RemoveData("OldCommandLogs")
					Functions.Hint("Old Logs Cleared (this will be saved in old logs)", {plr})
				else
					Functions.Hint("Operation cancelled", {plr})
				end
			end,
		};

		TaskManager = server.Data and server.Data.NightlyMode and { --// Unfinished
			Prefix = Settings.Prefix;
			Commands = {"taskmgr", "taskmanager"};
			Args = {};
			Description = "Task manager";
			Hidden = true;
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "TaskManager", {})
			end
		} or nil;
	}
end
