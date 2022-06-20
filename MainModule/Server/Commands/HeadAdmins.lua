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
			Hidden = false;
			Description = "Bans the target player(s) for the supplied amount of time; Data Persistent; Undone using :untimeban";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing time amount")
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

				assert(tonumber(time), "Unable to cast time, check "..Settings.PlayerPrefix.."usage for more infomation on timeban.")

				local level = data.PlayerData.Level;
				local timebans = Core.Variables.TimeBans

				for i, v in pairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					if level > Admin.GetLevel(v) then
						local endTime = os.time() + tonumber(time)
						local reason = service.Filter(args[3], plr, v) or "No reason provided";
						local data = {
							Name = v.Name;
							UserId = v.UserId;
							EndTime = endTime;
							Reason = reason;
						}

						table.insert(timebans, data)

						-- Please make a Admin.AddTimeBan function like Admin.AddBan
						v:Kick("\n Reason: "..reason.."\nBanned until ".. service.FormatTime(endTime, {WithWrittenDate = true}))
						Functions.Hint("Saving timeban for ".. tostring(v.Name) .."...", {plr})

						Core.DoSave({
							Type = "TableAdd";
							Table = {"Core", "Variables", "TimeBans"};
							Value = data;
						})

						Functions.Hint("Banned "..tostring(v.Name).." for ".. tostring(time), {plr})
					end
				end
			end
		};

		UnTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"untimeban", "untimedban", "untban", "untempban", "untemporaryban"};
			Args = {"player"};
			Hidden = false;
			Description = "Removes specified player from Timebans list";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				local timebans = Core.Variables.TimeBans or {}

				for i, data in pairs(timebans) do
					if data.Name:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(timebans, i)
						Core.DoSave({
							Type = "TableRemove";
							Table = {"Core", "Variables", "TimeBans"};
							Value = data;
						})

						Functions.Hint(tostring(data.Name)..' has been Unbanned', {plr})
					end
				end
			end
		};

		PermanentBan = {
			Prefix = Settings.Prefix;
			Commands = {"permban", "permanentban", "pban", "gameban", "saveban", "databan"};
			Args = {"player", "reason"};
			Description = "Bans the player from the game permenantly. If they join a different server they will be banned there too";
			AdminLevel = "HeadAdmins";
			Filter = true;
			Hidden = false;
			Fun = false;
			Function = function(plr: Player, args: {string}, data: {})
				local level = data.PlayerData.Level
				local reason = args[2] or "No reason provided";

				for _, v in pairs(service.GetPlayers(plr, args[1], {
					DontError = false;
					IsServer = false;
					IsKicking = true;
					UseFakePlayer = true;
					})) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, reason, true)
						Functions.Hint("Game banned "..tostring(v), {plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"unpermban", "unpermanentban", "unpban", "ungameban", "saveunban", "undataban"};
			Args = {"player"};
			Description = "UnBans the player from game (Saves)";
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Argument #1 (player) is required")
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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

		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"admin", "permadmin", "pa", "padmin", "fulladmin"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the target player(s) an admin; Saves";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				local sendLevel = data.PlayerData.Level
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "Admins")
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							Icon = server.MatIcons["Admin panel settings"];
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now an admin', {plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
					end
				end
			end
		};

		TempAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempadmin", "ta"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the target player(s) a temporary admin; Does not save";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string}, data: {})
				local sendLevel = data.PlayerData.Level
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v, "Admins", true)
						Remote.MakeGui(v, "Notification", {
							Title = "Notification";
							Message = "You are a temp administrator. Click to view commands.";
							Time = 10;
							Icon = server.MatIcons["Admin panel settings"];
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now a temp admin', {plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher", {plr})
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
				assert(args[1], "Missing message")

				if not Core.CrossServer("Message", plr.Name, args[1]) then
					error("CrossServer Handler Not Ready");
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
				assert(args[1], "Missing time amount")
				assert(args[2], "Missing message")


				if not Core.CrossServer("Message", plr.Name, args[2], args[1]) then
					error("CrossServer Handler Not Ready");
				end
			end;
		};

		MakeList = {
			Prefix = Settings.Prefix;
			Commands = {"makelist", "newlist", "newtrellolist", "maketrellolist"};
			Args = {"name"};
			Hidden = false;
			Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				if not args[1] then error("You need to supply a list name.") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.Boards.MakeList(Settings.Trello_Primary, args[1])
				Functions.Hint("Made list "..list.name, {plr})
			end
		};

		ViewList = {
			Prefix = Settings.Prefix;
			Commands = {"viewlist", "viewtrellolist"};
			Args = {"name"};
			Hidden = false;
			Description = "Views the specified Trello list from the primary board set in Settings.";
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				if not args[1] then error("Enter a valid list name") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey, Settings.Trello_Token)
				local list = trello.Boards.GetList(Settings.Trello_Primary, args[1])
				if not list then error("List not found.") end
				local cards = trello.Lists.GetCards(list.id)
				local temp = {}
				for i, v in pairs(cards) do
					table.insert(temp, {Text=v.name,Desc=v.desc})
				end
				Remote.MakeGui(plr, "List", {Title = list.name; Tab = temp})
			end
		};

		MakeCard = {
			Prefix = Settings.Prefix;
			Commands = {"makecard", "maketrellocard", "createcard"};
			Args = {};
			Hidden = false;
			Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
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
				for i, v in pairs(objects) do
					v:Destroy()
				end
				table.clear(objects)

				--for i, v in pairs(Functions.GetPlayers()) do
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
				local plr_name = plr and plr.Name

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
				for _, v in ipairs(workspace:GetChildren()) do
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
					Desc = (plr_name or "<SERVER>").." has successfully backed up the map.";
				})
			end
		};

		Explore = {
			Prefix = Settings.Prefix;
			Commands = {"explore", "explorer"};
			Args = {};
			Hidden = false;
			Description = "Lets you explore the game, kinda like a file browser";
			Fun = false;
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
			Hidden = false;
			Fun = false;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					service.SocialService:PromptGameInvite(v)
				end
			end
		};

		ForceRejoin = {
			Prefix = Settings.Prefix;
			Commands = {"forcerejoin"};
			Args = {"player"};
			Description = "Forces target player(s) to rejoin the server, same as them running !rejoin";
			Hidden = false;
			Fun = false;
			NoStudio = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					service.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, v)
				end
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
					Question = "Shutdown all running servers for the reason "..tostring(args[1]).."?";
					Title = "Shutdown all running servers?";
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
			Commands = {"incognito", "vanish", "incognitomode"};
			Args = {"player"};
			Description = "Removes the target player from other clients' perspectives (persists until rejoin, see a list of vanished players using "..Settings.Prefix.."incognitolist)";
			AdminLevel = "HeadAdmins";
			Hidden = true;
			Function = function(plr: Player, args: {string})
				for _, v: Player in ipairs(service.GetPlayers(plr, args[1])) do
					if Variables.IncognitoPlayers[v] then
						Functions.Hint(service.FormatPlayer(v).." is already incognito.", {plr})
						continue
					end
					Variables.IncognitoPlayers[v] = os.time()
					local n = 0
					for _, otherPlr: Player in ipairs(service.Players:GetPlayers()) do
						if otherPlr == v then continue end
						Remote.LoadCode(otherPlr, [[
					for _, p in pairs(service.Players:GetPlayers()) do
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

				for _, v: Player in ipairs(service.GetPlayers(plr, args[1])) do
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
