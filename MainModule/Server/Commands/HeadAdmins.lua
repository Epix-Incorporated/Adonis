return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		TimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"tempban", "timedban", "timeban", "tban", "temporaryban"};
			Args = {"player", "number<s/m/h/d>", "reason"};
			Description = "Bans the target player(s) for the supplied amount of time; data-persistent; undo using "..Settings.Prefix.."untimeban";
			Filter = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target user (argument #1)")
				assert(args[2], "Missing time amount (argument #2)")
				local time = args[2]
				local lower, sub = string.lower, string.sub
				if sub(lower(time), #time)=='s' then
					time = sub(time, 1, #time-1)
					time = tonumber(time)
				elseif sub(lower(time), #time)=='m' then
					time = sub(time, 1, #time-1)
					time = tonumber(time)*60
				elseif sub(lower(time), #time)=='h' then
					time = sub(time, 1, #time-1)
					time = ((time)*60)*60
				elseif sub(lower(time), #time)=='d' then
					time = sub(time, 1, #time-1)
					time = ((tonumber(time)*60)*60)*24
				end

				assert(tonumber(time), "Invalid time amount value; check "..Settings.PlayerPrefix.."usage for more information on timeban")

				local level = data.PlayerData.Level
				local reason = args[3] or "No reason provided"

				for _, v in pairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					if level > Admin.GetLevel(v) then
						Admin.AddTimeBan(v, tonumber(time), reason, plr)
						Functions.Hint("Time-banned "..service.FormatPlayer(v).." for ".. args[2], {plr})
					else
						Functions.Hint("Unable to time-ban "..service.FormatPlayer(v).." (insufficient permission level)", {plr})
					end
				end
			end
		};

		DirectTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"directtimeban", "directtimedban", "directtimeban", "directtban", "directtemporaryban"};
			Args = {"username", "number<s/m/h/d>", "reason"};
			Description = "Bans the target user(s) for the supplied amount of time; Data Persistent; undo using "..Settings.Prefix.."untimeban";
			Filter = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target user (argument #1)")
				assert(args[2], "Missing time amount (argument #2)")
				local time = args[2]
				local lower, sub = string.lower, string.sub
				if sub(lower(time), #time)=='s' then
					time = sub(time, 1, #time-1)
					time = tonumber(time)
				elseif sub(lower(time), #time)=='m' then
					time = sub(time, 1, #time-1)
					time = tonumber(time)*60
				elseif sub(lower(time), #time)=='h' then
					time = sub(time, 1, #time-1)
					time = ((time)*60)*60
				elseif sub(lower(time), #time)=='d' then
					time = sub(time, 1, #time-1)
					time = ((tonumber(time)*60)*60)*24
				end

				assert(tonumber(time), "Invalid time amount value; check "..Settings.PlayerPrefix.."usage for more information on timeban")

				local reason = args[3] or "No reason provided"

				for i in string.gmatch(args[1], "[^,]+") do
					local userId = service.Players:GetUserIdFromNameAsync(i)

					if userId == plr.UserId then
						error("You cannot ban yourself or the creator of the game", 2)
						return
					end

					if userId then
						Admin.AddTimeBan({UserId = userId, Name = i}, tonumber(time), reason, plr)
						Functions.Hint("Time-banned '"..tostring(i).."' for ".. args[2], {plr})
					end
				end
			end
		};

		UnTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"untimeban", "untimedban", "untban", "untempban", "untemporaryban"};
			Args = {"player"};
			Description = "Removes the target player from Timebans list";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target user (argument #1)")

				local ret = Admin.RemoveTimeBan(args[1])
				if ret then
					Functions.Hint(tostring(ret).." has been unbanned", {plr})
				end
			end
		};

		PermanentBan = {
			Prefix = Settings.Prefix;
			Commands = {"permban", "permanentban", "pban", "gameban", "saveban", "databan"};
			Args = {"player", "reason"};
			Description = "Bans the target user from the game permenantly; if they join a different server they will be banned there too";
			AdminLevel = "HeadAdmins";
			Filter = true;
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target user (argument #1)")
				local level = data.PlayerData.Level
				local reason = args[2] or "No reason provided"

				for _, v in pairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, reason, true, plr)
						Functions.Hint("Game-banned "..tostring(v), {plr})
					else
						Functions.Hint("Unable to game-ban "..tostring(v).." (insufficient permission level)", {plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"unpermban", "unpermanentban", "unpban", "ungameban", "saveunban", "undataban"};
			Args = {"player"};
			Description = "Unbans the user from the game; saves";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing target user (argument #1)")
				for _, v in service.GetPlayers(plr, args[1]) do
					local ret = Admin.RemoveBan(v.Name, true)
					if ret then
						if type(ret) == "table" then
							ret = tostring(ret.Name) .. ":" .. tostring(ret.UserId)
						else
							ret = tostring(ret)
						end
						Functions.Hint(ret.." has been unbanned from the game", {plr})
					end
				end
			end
		};

		TempAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempadmin", "tadmin"};
			Args = {"player"};
			Description = "Makes the target player(s) a temporary admin; does not save";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target player (argument #1)")
				local senderLevel = data.PlayerData.Level
				for _, v in service.GetPlayers(plr, args[1]) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Admins", true)
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are a temp administrator. Click to view commands.";
							Time = 10;
							Icon = server.MatIcons["Admin panel settings"];
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(service.FormatPlayer(v).." is now a temporary admin", {plr})
					else
						Functions.Hint(service.FormatPlayer(v).." is already the same admin level as you or higher", {plr})
					end
				end
			end
		};

		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"permadmin", "padmin", "admin"};
			Args = {"player"};
			Description = "Makes the target player(s) an admin; saves";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing target player (argument #1)")
				local senderLevel = data.PlayerData.Level
				for _, v in service.GetPlayers(plr, args[1]) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Admins")
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							Icon = server.MatIcons["Admin panel settings"];
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(service.FormatPlayer(v).." is now a permanent admin", {plr})
					else
						Functions.Hint(service.FormatPlayer(v).." is already the same admin level as you or higher", {plr})
					end
				end
			end
		};

		GlobalMessage = {
			Prefix = Settings.Prefix;
			Commands = {"globalmessage", "gm", "globalannounce"};
			Args = {"message"};
			Description = "Sends a global message to all servers";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				if not Core.CrossServer("Message", plr.Name, assert(args[1], "Missing message")) then
					error("CrossServer handler not ready; please try again later")
				end
			end;
		};

		GlobalTimeMessage = {
			Prefix = Settings.Prefix;
			Commands = {"gtm", "globaltimedmessage", "globaltimemessage", "globaltimem"};
			Args = {"time", "message"};
			Description = "Sends a global message to all servers and makes it stay on the screen for the amount of time (in seconds) you supply";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				if not Core.CrossServer("Message", plr.Name, assert(args[2], "Missing message"), assert(args[1], "Missing time amount")) then
					error("CrossServer handler not ready; please try again later")
				end
			end;
		};

		MakeList = {
			Prefix = Settings.Prefix;
			Commands = {"makelist", "newlist", "newtrellolist", "maketrellolist"};
			Args = {"name"};
			Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
			TrelloRequired = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "You need to supply a list name.")

				local trello = HTTP.Trello.API
				if not Settings.Trello_Enabled or trello == nil then return Functions.Hint('Trello has not been configured in settings', {plr}) end

				local list = trello.Boards.MakeList(Settings.Trello_Primary, args[1])
				Functions.Hint("Made list "..list.name, {plr})
			end
		};

		ViewList = {
			Prefix = Settings.Prefix;
			Commands = {"viewlist", "viewtrellolist"};
			Args = {"name"};
			Description = "Views the specified Trello list from the primary board set in Settings.";
			TrelloRequired = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local trello = HTTP.Trello.API
				if not Settings.Trello_Enabled or trello == nil then return Functions.Hint('Trello has not been configured in settings', {plr}) end
				assert(args[1], "Enter a valid list name")
				local list = assert(trello.Boards.GetList(Settings.Trello_Primary, args[1]), "List not found.")

				local cards = trello.Lists.GetCards(list.id)
				local temp = table.create(#cards)
				for _, v in cards do
					table.insert(temp, {Text = v.name, Desc = v.desc})
				end
				Remote.MakeGui(plr, "List", {Title = list.name; Tab = temp})
			end
		};

		MakeCard = {
			Prefix = Settings.Prefix;
			Commands = {"makecard", "maketrellocard", "createcard"};
			Args = {};
			Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
			TrelloRequired = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "CreateCard")
			end
		};

		FullClear = {
			Prefix = Settings.Prefix;
			Commands = {"fullclear", "clearinstances", "fullclr"};
			Args = {};
			Description = "Removes any instance created server-side by Adonis; May break things";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local objects = service.GetAdonisObjects()
				for i, v in objects do
					v:Destroy()
				end
				table.clear(objects)

				--for i, v in Functions.GetPlayers() do
				--	Remote.Send(v, "Function", "ClearAllInstances")
				--end
			end
		};

		BackupMap = {
			Prefix = Settings.Prefix;
			Commands = {"backupmap", "mapbackup", "bmap"};
			Args = {};
			Description = "Changes the backup for the restore map command to the map's current state";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local plr_name = if plr then service.FormatPlayer(plr) else "%SYSTEM%"

				if plr then
					Functions.Hint("Updating Map Backup...", {plr})
				end

				if Variables.BackingupMap then
					error("Backup Map is in progress. Please try again later!")
					return
				end
				if Variables.RestoringMap then
					error("Cannot backup map while map is being restored!")
					return
				end

				Variables.BackingupMap = true

				local tempmodel = service.New("Model", {
					Name = "BACKUP_MAP_MODEL"
				})
				for _, v in workspace:GetChildren() do
					if v.ClassName ~= "Terrain" and not service.Players:GetPlayerFromCharacter(v) then
						local archive = v.Archivable
						v.Archivable = true
						v:Clone().Parent = tempmodel
						v.Archivable = archive
					end
				end
				Variables.MapBackup = tempmodel:Clone()
				tempmodel:Destroy()

				local Terrain = workspace.Terrain or workspace:FindFirstChildOfClass("Terrain")
				if Terrain then
					Variables.TerrainMapBackup = Terrain:CopyRegion(Terrain.MaxExtents)
				end

				if plr then
					Functions.Hint('Backup Complete', {plr})
				end

				Variables.BackingupMap = false

				Logs.AddLog(Logs.Script, {
					Text = "Backup Complete";
					Desc = plr_name.." has successfully backed up the map.";
				})
			end
		};

		Explore = {
			Prefix = Settings.Prefix;
			Commands = {"explore", "explorer"};
			Args = {};
			Description = "Lets you explore the game, kinda like a file browser (alternative to "..Settings.Prefix.."dex)";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Explorer")
			end
		};

		PromptInvite = {
			Prefix = Settings.Prefix;
			Commands = {"promptinvite", "inviteprompt", "forceinvite"};
			Args = {"player"};
			Description = "Opens the friend invitation popup for the target player(s), same as them running !invite";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.SocialService:PromptGameInvite(v)
				end
			end
		};

		ForceRejoin = {
			Prefix = Settings.Prefix;
			Commands = {"forcerejoin"};
			Args = {"player"};
			Description = "Forces target player(s) to rejoin the server; same as them running "..Settings.PlayerPrefix.."rejoin";
			NoStudio = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				local players = service.GetPlayers(plr, args[1])
				local teleportOptions = service.New("TeleportOptions", {
					ServerInstanceId = game.JobId
				})
				service.TeleportService:TeleportAsync(game.PlaceId, players, teleportOptions)
			end
		};

		FullShutdown = {
			Prefix = Settings.Prefix;
			Commands = {"fullshutdown", "globalshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			AdminLevel = "HeadAdmins";
			Filter = true;
			IsCrossServer = true;
			Function = function(plr: Player, args: {string})
				assert(args[1], "Reason must be supplied for this command!")
				local ans = Remote.GetGui(plr, "YesNoPrompt", {
					Question = "Shutdown all running servers for the reason '"..tostring(args[1]).."'?";
					Title = "Global Shutdown";
				})
				if ans == "Yes" then
					if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."shutdown "..args[1] .. "\n\n\n[GLOBAL SHUTDOWN]") then
						error("An error has occured")
					end
				end
			end;
		};

		Incognito = {
			Prefix = Settings.Prefix;
			Commands = {"incognito"};
			Args = {"player"};
			Description = "Removes the target player from other clients' perspectives (persists until rejoin)";
			AdminLevel = "HeadAdmins";
			Hidden = true;
			Function = function(plr: Player, args: {string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					if Variables.IncognitoPlayers[v] then
						Functions.Hint(service.FormatPlayer(v).." is already incognito.", {plr})
						continue
					end
					Variables.IncognitoPlayers[v] = os.time()
					local n = 0
					for _, otherPlr: Player in service.Players:GetPlayers() do
						if otherPlr == v then continue end
						Remote.LoadCode(otherPlr, [[
					for _, p in service.Players:GetPlayers() do
						if p.UserId == ]]..v.UserId..[[ then
							if p:FindFirstChild("leaderstats") then p.leaderstats:Destroy() end
							p:Destroy()
						end
					end]])
						n += 1
					end
					if n == 0 then
						Functions.Hint(string.format("Placed %s on the incognito list.", service.FormatPlayer(v)), {plr})
					else
						Functions.Hint(string.format("Hidden %s from %d other player%s.", service.FormatPlayer(v), n, n == 1 and "" or "s"), {plr})
					end
					Remote.MakeGui(v, "Notification", {
						Title = "Incognito Mode";
						Icon = server.MatIcons["Privacy tip"];
						Text = "You will cease to appear on the player list, on other players' screens.";
						Time = 15;
					})
				end
			end
		};

		AwardBadge = {
			Prefix = Settings.Prefix;
			Commands = {"awardbadge", "badge", "givebadge"};
			Args = {"player", "badgeId"};
			Description = "Awards the badge of the specified ID to the target player(s)";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				if not Variables.BadgeInfoCache then
					Variables.BadgeInfoCache = {}
				end

				local badgeId = assert(tonumber(args[2]), "Invalid badge ID specified!")
				local badgeInfo = Variables.BadgeInfoCache[tostring(badgeId)]
				if not badgeInfo then
					local success, badgeInfo = nil, nil
					local tries = 0
					repeat
						tries += 1
						success, badgeInfo = pcall(service.BadgeService.GetBadgeInfoAsync, service.BadgeService, badgeId)
					until success or tries > 2
					Variables.BadgeInfoCache[tostring(badgeId)] = assert(success and badgeInfo, "Unable to retrieve badge information; please try again")
				end

				for _, v: Player in service.GetPlayers(plr, args[1]) do
					local success, hasBadge = nil, nil
					local tries = 0
					repeat
						tries += 1
						success, hasBadge = pcall(service.BadgeService.UserHasBadgeAsync, service.BadgeService, v.UserId, badgeId)
					until success or tries > 2
					if not success then
						Functions.Hint(string.format("ERROR: Unable to get badge ownership status for %s; skipped", service.FormatPlayer(v)))
						continue
					end
					if hasBadge then
						Functions.Hint(string.format("%s already has the badge '%s'", service.FormatPlayer(v), badgeInfo.Name), {plr})
					elseif service.BadgeService:AwardBadge(v.UserId, badgeId) then
						Functions.Hint(string.format("Successfully awarded badge '%s' for %s", badgeInfo.Name, service.FormatPlayer(v)), {plr})
					else
						Functions.Hint(string.format("ERROR: Failed to award badge '%s' for %s due to an unexpected internal error", badgeInfo.Name, service.FormatPlayer(v)), {plr})
					end
				end
			end
		};
	}
end
