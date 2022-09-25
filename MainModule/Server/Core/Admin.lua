server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Admin
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;
	local cloneTable = service.CloneTable;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Commands
	local AddLog, TrackTask, Defaults
	local CreatorId = game.CreatorType == Enum.CreatorType.User and game.CreatorId or service.GetGroupCreatorId(game.CreatorId)
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;
		Commands = server.Commands;
		Defaults = server.Defaults

		TrackTask = service.TrackTask
		AddLog = Logs.AddLog;

		TrackTask("Thread: ChatServiceHandler", function()
			--// ChatService mute handler (credit to Coasterteam)
			local chatService = Functions.GetChatService()

			if chatService then
				chatService:RegisterProcessCommandsFunction("ADONIS_CMD", function(speakerName, message)
					local speaker = chatService:GetSpeaker(speakerName)
					local speakerPlayer = speaker and speaker:GetPlayer()

					if not speakerPlayer then
						return false
					end

					if Admin.DoHideChatCmd(speakerPlayer, message) then
						return true
					end

					return false
				end)

				chatService:RegisterProcessCommandsFunction("ADONIS_MUTE_SERVER", function(speakerName, _, channelName)
					local slowCache = Admin.SlowCache

					local speaker = chatService:GetSpeaker(speakerName)
					local speakerPlayer = speaker and speaker:GetPlayer()

					if not speakerPlayer then
						return false
					end

					if speakerPlayer and Admin.IsMuted(speakerPlayer) then
						speaker:SendSystemMessage("[Adonis] :: You are muted!", channelName)
						return true
					elseif speakerPlayer and Admin.SlowMode and not Admin.CheckAdmin(speakerPlayer) and slowCache[speakerPlayer] and os.time() - slowCache[speakerPlayer] < Admin.SlowMode then
						speaker:SendSystemMessage(string.format("[Adonis] :: Slow mode enabled! (%g second(s) remaining)", Admin.SlowMode - (os.time() - slowCache[speakerPlayer])), channelName)
						return true
					end

					if Admin.SlowMode then
						slowCache[speakerPlayer] = os.time()
					end

					return false
				end)

				AddLog("Script", "ChatService Handler Loaded")
			else
				warn("Place is missing ChatService; Vanilla Roblox chat related features may not work")
				AddLog("Script", "ChatService Handler Not Found")
			end
		end)

		--// Make sure the default ranks are always present for compatability with existing commands
		local Ranks = Settings.Ranks
		for rank, data in pairs(Defaults.Settings.Ranks) do
			if not Ranks[rank] then
				for r, d in pairs(Ranks) do
					if d.Level == data.Level then
						data.Hidden = true
						break
					end
				end
				Ranks[rank] = data
			end
		end

		--// Old settings/plugins backwards compatibility
		for _, rank in ipairs({"Owners", "HeadAdmins", "Admins", "Moderators", "Creators"}) do
			if Settings[rank] then
				Settings.Ranks[if rank == "Owners" then "HeadAdmins" else rank].Users = Settings[rank]
			end
		end

		--[[Settings.HeadAdmins = Settings.Ranks.HeadAdmins.Users;
		Settings.Admins = Settings.Ranks.Admins.Users;
		Settings.Moderators = Settings.Ranks.Moderators.Users;--]]

		if Settings.CustomRanks then
			local Ranks = Settings.Ranks
			for name, users in pairs(Settings.CustomRanks) do
				if not Ranks[name] then
					Ranks[name] = {
						Level = 1;
						Users = users;
					};
				end
			end
		end

		if Settings.CommandCooldowns then
			for cmdName, cooldownData in pairs(Settings.CommandCooldowns) do
				local realCmd = Admin.GetCommand(cmdName)

				if realCmd then
					if cooldownData.Player then
						realCmd.PlayerCooldown = cooldownData.Player
					end

					if cooldownData.Server then
						realCmd.ServerCooldown = cooldownData.Server
					end

					if cooldownData.Cross then
						realCmd.CrossCooldown = cooldownData.Cross
					end
				end
			end
		end

		if Settings.CommandCooldowns then
			for cmdName, cooldownData in pairs(Settings.CommandCooldowns) do
				local realCmd = Admin.GetCommand(cmdName)

				if realCmd then
					if cooldownData.Player then
						realCmd.PlayerCooldown = cooldownData.Player
					end

					if cooldownData.Server then
						realCmd.ServerCooldown = cooldownData.Server
					end

					if cooldownData.Cross then
						realCmd.CrossCooldown = cooldownData.Cross
					end
				end
			end
		end

		if Settings.CommandCooldowns then
			for cmdName, cooldownData in pairs(Settings.CommandCooldowns) do
				local realCmd = Admin.GetCommand(cmdName)

				if realCmd then
					if cooldownData.Player then
						realCmd.PlayerCooldown = cooldownData.Player
					end

					if cooldownData.Server then
						realCmd.ServerCooldown = cooldownData.Server
					end

					if cooldownData.Cross then
						realCmd.CrossCooldown = cooldownData.Cross
					end
				end
			end
		end

		Admin.Init = nil;
		AddLog("Script", "Admin Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// Backup Map
		if Settings.AutoBackup then
			TrackTask("Thread: Initial Map Backup", Admin.RunCommand, Settings.Prefix.."backupmap")
		end

		--// Run OnStartup Commands
		for i,v in pairs(Settings.OnStartup) do
			warn("Running startup command ".. tostring(v))
			TrackTask("Thread: Startup_Cmd: ".. tostring(v), Admin.RunCommand, v)
			AddLog("Script", {
				Text = "Startup: Executed "..tostring(v);
				Desc = "Executed startup command; "..tostring(v);
			})
		end

		--// Check if Shutdownlogs is set and if not then set it
		if Core.DataStore and not Core.GetData("ShutdownLogs") then
			Core.SetData("ShutdownLogs", {})
		end

		Admin.RunAfterPlugins = nil;
		AddLog("Script", "Admin Module RunAfterPlugins Finished")
	end

	service.MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		if Variables and player.Parent and id == 1348327 and purchased then
			Variables.CachedDonors[tostring(player.UserId)] = os.time()
		end
	end)

	local function stripArgPlaceholders(alias)
		return service.Trim(string.gsub(alias, "<%S+>", ""))
	end

	local function FormatAliasArgs(alias, aliasCmd, msg)
		local uniqueArgs = {}
		local argTab = {}
		local numArgs = 0

		--// First try to extract args info from the alias
		for arg in string.gmatch(alias, "<(%S+)>") do
			if arg ~= "" and arg ~= " " then
				local arg = "<".. arg ..">"
				if not uniqueArgs[arg] then
					numArgs += 1
					uniqueArgs[arg] = true
					table.insert(argTab, arg)
				end
			end
		end

		--// If no args in alias string, check the command string instead and try to guess args based on order of appearance
		if numArgs == 0 then
			for arg in string.gmatch(aliasCmd, "<(%S+)>") do
				if arg ~= "" and arg ~= " " then
					local arg = "<".. arg ..">"
					if not uniqueArgs[arg] then --// Get only unique placeholder args, repeats will be matched to the same arg pos
						numArgs += 1
						uniqueArgs[arg] = true --// :cmd <arg1> <arg2>
						table.insert(argTab, arg)
					end
				end
			end
		end

		local suppliedArgs = Admin.GetArgs(msg, numArgs) -- User supplied args (when running :alias arg)
		local out = aliasCmd

		local EscapeSpecialCharacters = service.EscapeSpecialCharacters
		for i,argType in pairs(argTab) do
			local replaceWith = suppliedArgs[i]
			if replaceWith then
				out = string.gsub(out, EscapeSpecialCharacters(argType), replaceWith)
			end
		end

		return out
	end

	server.Admin = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;

		SpecialLevels = {};
		TempAdmins = {};

		PrefixCache = {};
		CommandCache = {};
		SlowCache = {};
		UserIdCache = {};
		GroupsCache = {};

		BlankPrefix = false;

		--// How long admin levels will be cached (unless forcibly updated via something like :admin user)
		AdminLevelCacheTimeout = 30;

		DoHideChatCmd = function(p: Player, message: string, data: {[string]: any}?)
			local pData = data or Core.GetPlayer(p)
			if pData.Client.HideChatCommands then
				if Variables.BlankPrefix and
					(string.sub(message,1,1) ~= Settings.Prefix or string.sub(message,1,1) ~= Settings.PlayerPrefix) then
					local isCMD = Admin.GetCommand(message)
					if isCMD then
						return true
					else
						return false
					end
				elseif (string.sub(message,1,1) == Settings.Prefix or string.sub(message,1,1) == Settings.PlayerPrefix)
					and string.sub(message,2,2) ~= string.sub(message,1,1) then
					return true;
				end
			end
		end;

		GetPlayerGroups = function(p: Player)
			if not p or p.Parent ~= service.Players then
				return {}
			end
			return Admin.GetGroups(p.UserId)
		end;

		GetPlayerGroup = function(p, group)
			local groups = Admin.GetPlayerGroups(p)
			local isId = type(group) == "number"
			if groups and #groups > 0 then
				for _, g in ipairs(groups) do
					if (isId and g.Id == group) or (not isId and g.Name == group) then
						return g
					end
				end
			end
		end;

		GetGroups = function(uid, updateCache)
			uid = tonumber(uid)

			if type(uid) == "number" then
				local existCache = Admin.GroupsCache[uid]
				local canUpdate = false

				if not updateCache then
					--> Feel free to adjust the time to update over or less than 300 seconds (5 minutes).
					--> 300 seconds is recommended in the event of unexpected server breakdowns with Roblox and faster performance.
					if existCache and (os.time()-existCache.LastUpdated > 300) then
						canUpdate = true
					elseif not existCache then
						canUpdate = true
					end
				else
					canUpdate = true
				end

				if canUpdate then
					local cacheTab = {
						Groups = (existCache and existCache.Groups) or {};
						LastUpdated = os.time();
					}
					Admin.GroupsCache[uid] = cacheTab

					local suc,groups = pcall(function()
						return service.GroupService:GetGroupsAsync(uid) or {}
					end)

					if suc and type(groups) == "table" then
						cacheTab.Groups = groups
						return cacheTab.Groups
					end

					Admin.GroupsCache[uid] = cacheTab
					return cloneTable(cacheTab.Groups)
				else
					return cloneTable((existCache and existCache.Groups) or {})
				end
			end
		end;

		GetGroupLevel = function(uid, groupId)
			groupId = tonumber(groupId)

			if groupId then
				local groups = Admin.GetGroups(uid) or {}

				for _, group in pairs(groups) do
					if group.Id == groupId then
						return group.Rank
					end
				end
			end

			return 0
		end;

		CheckInGroup = function(uid, groupId)
			local groups = Admin.GetGroups(uid) or {}
			groupId = tonumber(groupId)

			if groupId then
				for i,group in pairs(groups) do
					if group.Id == groupId then
						return true
					end
				end
			end

			return false
		end,

		IsLax = function(str)
			for _, v in ipairs({"plr", "user", "player", "brickcolor"}) do
				if string.match(string.lower(str), v) then
					return true
				end
			end

			return false
		end,

		IsMuted = function(player)
			local DoCheck = Admin.DoCheck
			for _, v in pairs(Settings.Muted) do
				if DoCheck(player, v) then
					return true
				end
			end

			for _, v in pairs(HTTP.Trello.Mutes) do
				if DoCheck(player, v) then
					return true
				end
			end

			if HTTP.WebPanel.Mutes then
				for _, v in pairs(HTTP.WebPanel.Mutes) do
					if DoCheck(player, v) then
						return true
					end
				end
			end
		end;

		DoCheck = function(pObj, check, banCheck)
			local pType = typeof(pObj)
			local cType = typeof(check)

			local pUnWrapped = service.UnWrap(pObj)

			local plr: Player = if pType == "number" then service.Players:GetPlayerByUserId(pObj)
				elseif pType == "string" then service.Players:FindFirstChild(pObj)
				elseif typeof(pUnWrapped) == "Instance" and pUnWrapped:IsA("Player") then pUnWrapped
				elseif pType == "userdata" then service.Players:GetPlayerByUserId(pObj.UserId)
				else nil
			if not plr then
				return false
			end

			if cType == "number" then
				return plr.UserId == check
			elseif cType == "string" then
				if plr.Name == check then
					return true
				end

				local filterName, filterData = string.match(check, "^(.-):(.+)$")
				if filterName then
					filterName = string.lower(filterName)
				else
					return false
				end
				if filterName == "group" then
					local groupId = tonumber((string.match(filterData, "^%d+")))
					if groupId then
						local plrRank = Admin.GetGroupLevel(plr.UserId, groupId)
						local requiredRank = tonumber((string.match(filterData, "^%d+:(.+)$")))
						if requiredRank then
							return plrRank == requiredRank or (requiredRank < 0 and plrRank >= math.abs(requiredRank))
						end
						return plrRank > 0
					end
					return false
				elseif filterName == "item" then
					local itemId = tonumber((string.match(filterData, "^%d+")))
					return itemId and service.CheckAssetOwnership(plr, itemId)
				elseif filterName == "gamepass" then
					local gamepassId = tonumber((string.match(filterData, "^%d+")))
					return gamepassId and service.CheckPassOwnership(plr, gamepassId)
				else
					local username, userId = string.match(check, "^(.*):(.*)")
					if username and userId and (plr.UserId == userId or string.lower(plr.Name) == string.lower(username)) then
						return true
					end

					if not banCheck and type(check) == "string" and not string.find(check, ":") then
						local cache = Functions.GetUserIdFromNameAsync(check)
						if cache and plr.UserId == cache then
							return true
						end
					end
				end
			elseif cType == "table" then
				local groupId, rank = check.Group, check.Rank
				if groupId and rank then
					local plrGroupInfo = Admin.GetPlayerGroup(plr, groupId)
					if plrGroupInfo then
						local plrRank = plrGroupInfo.Rank
						return plrRank == rank or (rank < 0 and plrRank >= math.abs(rank))
					end
				end
			end

			return check == plr
		end;

		LevelToList = function(lvl)
			local lvl = tonumber(lvl)
			if not lvl then return nil end
			local listName = Admin.LevelToListName(lvl)
			if listName then
				local list = Settings.Ranks[listName];
				if list then
					return list.Users, listName, list;
				end
			end
		end;

		LevelToListName = function(lvl)
			if lvl > 999 then
				return "Place Owner"
			elseif lvl == 0 then
				return "Players"
			end

			--// Check if this is a default rank and if the level matches the default (so stuff like [Trello] Admins doesn't appear in the command list)
			for i,v in pairs(server.Defaults.Settings.Ranks) do
				local tRank = Settings.Ranks[i];
				if tRank and tRank.Level == v.Level and v.Level == lvl then
					return i
				end
			end

			for i,v in pairs(Settings.Ranks) do
				if v.Level == lvl then
					return i
				end
			end
		end;

		UpdateCachedLevel = function(p, data)
			local data = data or Core.GetPlayer(p)
			local oLevel, oRank = data.AdminLevel, data.AdminRank
			local level, rank = Admin.GetUpdatedLevel(p, data)

			data.AdminLevel = level
			data.AdminRank = rank
			data.LastLevelUpdate = os.time()

			AddLog("Script", {
				Text = "Updating cached level for ".. p.Name;
				Desc = "Updating the cached admin level for ".. p.Name;
				Player = p;
			})

			if Settings.Console and (oLevel ~= level or oRank ~= rank) then
				if not Settings.Console_AdminsOnly or (Settings.Console_AdminsOnly and level > 0) then
					task.defer(Remote.RefreshGui, p, "Console")
				else
					task.defer(Remote.RemoveGui, p, "Console")
				end
			end

			return level, rank
		end;

		GetLevel = function(p)
			local data = Core.GetPlayer(p)
			local level = data.AdminLevel
			local rank = data.AdminRank
			local lastUpdate = data.LastLevelUpdate or 0
			local clients = Remote.Clients
			local key = tostring(p.UserId)

			local currentTime = os.time()

			if (not level or not lastUpdate or currentTime - lastUpdate > Admin.AdminLevelCacheTimeout) or lastUpdate > currentTime then
				local newLevel, newRank = Admin.UpdateCachedLevel(p, data)

				if clients[key] and level and newLevel and type(p) == "userdata" and p:IsA("Player") then
					if newLevel < level then
						Functions.Hint("Your admin level has been reduced to ".. newLevel.." [".. (newRank or "Unknown") .."]", {p})
					elseif newLevel > level then
						Functions.Hint("Your admin level has been increased to ".. newLevel .." [".. (newRank or "Unknown") .."]", {p})
					end
				end

				return newLevel, newRank
			end

			return level or 0, rank;
		end;

		GetUpdatedLevel = function(p, data)
			local checkTable = Admin.CheckTable
			local doCheck = Admin.DoCheck

			--[[if data and data.AdminLevelOverride then
				return data.AdminLevelOverride
			end--]]

			for _, admin in pairs(Admin.SpecialLevels) do
				if doCheck(p, admin.Player) then
					return admin.Level, admin.Rank
				end
			end

			local sortedRanks = {}
			for rank, data in pairs(Settings.Ranks) do
				table.insert(sortedRanks, {
					Rank = rank;
					Users = data.Users;
					Level = data.Level;
				});
			end

			table.sort(sortedRanks, function(t1, t2)
				return t1.Level > t2.Level
			end)

			local highestLevel = 0
			local highestRank = nil

			for _, data in pairs(sortedRanks) do
				local level = data.Level
				if level > highestLevel then
					for _, v in ipairs(data.Users) do
						if doCheck(p, v) then
							highestLevel, highestRank = level, data.Rank
							break
						end
					end
				end
			end

			if Admin.IsPlaceOwner(p) and highestLevel < 1000 then
				return 1000, "Place Owner"
			end

			return highestLevel, highestRank
		end;

		IsPlaceOwner = function(p)
			if type(p) == "userdata" and p:IsA("Player") then
				--// These are my accounts; Lately I've been using my game dev account(698712377) more so I'm adding it so I can debug without having to sign out and back in (it's really a pain)
				--// Disable CreatorPowers in settings if you don't trust me. It's not like I lose or gain anything either way. Just re-enable it BEFORE telling me there's an issue with the script so I can go to your place and test it.
				if Settings.CreatorPowers and table.find({1237666, 76328606, 698712377}, p.UserId) then
					return true
				end

				if tonumber(CreatorId) and p.UserId == CreatorId then
					return true
				end

				if p.UserId == -1 then --// To account for player emulators in multi-client Studio tests
					return true
				end
			end
		end;

		CheckAdmin = function(p)
			return Admin.GetLevel(p) > 0
		end;

		SetLevel = function(p, level, doSave, rankName)
			local current, rank = Admin.GetLevel(p)

			if tonumber(level) then
				if current >= 1000 then
					return false
				else
					Admin.SpecialLevels[tostring(p.UserId)] = {
						Player = p.UserId,
						Level = level,
						Rank = rankName
					}

					--[[if doSave then
						local data = Core.GetPlayer(p)
						if data then
							data.AdminLevelOverride = level;
						end
					end--]]
				end
			elseif level == "Reset" then
				Admin.SpecialLevels[tostring(p.UserId)] = nil
			end

			Admin.UpdateCachedLevel(p)
		end;

		IsTempAdmin = function(p)
			local DoCheck = Admin.DoCheck
			for i,v in pairs(Admin.TempAdmins) do
				if DoCheck(p,v) then
					return true, i
				end
			end
		end;

		RemoveAdmin = function(p, temp, override)
			local current, rank = Admin.GetLevel(p)
			local listData = rank and Settings.Ranks[rank]
			local listName = listData and rank
			local list = listData and listData.Users

			local isTemp,tempInd = Admin.IsTempAdmin(p)

			if isTemp then
				temp = true
				table.remove(Admin.TempAdmins, tempInd)
			end

			if override then
				temp = false
			end

			if type(p) == "userdata" then
				Admin.SetLevel(p, 0)
			end

			if list then
				local DoCheck = Admin.DoCheck
				for ind,check in ipairs(list) do
					if DoCheck(p, check) and not (type(check) == "string" and (string.match(check,"^Group:") or string.match(check,"^Item:"))) then
						table.remove(list, ind)

						if not temp and Settings.SaveAdmins then
							TrackTask("Thread: RemoveAdmin", Core.DoSave, {
								Type = "TableRemove";
								Table = {"Settings", "Ranks", listName, "Users"};
								Value = check;
							})
						end
					end
				end
			end

			Admin.UpdateCachedLevel(p)
		end;

		AddAdmin = function(p, level, temp)
			local current, rank = Admin.GetLevel(p)
			local list = rank and Settings.Ranks[rank]
			local levelName, newRank, newList

			if type(level) == "string" then
				local newRank = Settings.Ranks[level]
				levelName = newRank and level
				newList = newRank and newRank.Users
				level = (newRank and newRank.Level) or Admin.StringToComLevel(levelName) or level
			else
				local nL, nLN = Admin.LevelToList(level)
				levelName = nLN
				newRank = nLN
				newList = nL
			end

			Admin.RemoveAdmin(p, temp)
			Admin.SetLevel(p, level, nil, levelName)

			if temp then
				table.insert(Admin.TempAdmins, p)
			end

			if list and type(list) == "table" then
				local index,value

				for ind,ent in ipairs(list) do
					if (type(ent)=="number" or type(ent)=="string") and (ent==p.UserId or string.lower(ent)==string.lower(p.Name) or string.lower(ent)==string.lower(p.Name..":"..p.UserId)) then
						index = ind
						value = ent
					end
				end

				if index and value then
					table.remove(list, index)
				end
			end

			local value = p.Name ..":".. p.UserId

			if newList then
				table.insert(newList, value)

				if Settings.SaveAdmins and levelName and not temp then
					TrackTask("Thread: SaveAdmin", Core.DoSave, {
						Type = "TableAdd";
						Table = {"Settings", "Ranks", levelName, "Users"};
						Value = value
					})
				end
			end

			Admin.UpdateCachedLevel(p)
		end;

		CheckDonor = function(p)
			--if not Settings.DonorPerks then return false end
			local key = tostring(p.UserId)
			if Variables.CachedDonors[key] then
				return true
			else
				--if p.UserId<0 or (tonumber(p.AccountAge) and tonumber(p.AccountAge)<0) then return false end
				local pGroup = Admin.GetPlayerGroup(p, 886423)
				for _, pass in ipairs(Variables.DonorPass) do
					if p.Parent ~= service.Players then
						return false
					end

					local ran, ret
					if type(pass) == "number" then
						ran, ret = pcall(service.MarketPlace.UserOwnsGamePassAsync, service.MarketPlace, p.UserId, pass)
					elseif type(pass) == "string" and tonumber(pass) then
						ran, ret = pcall(service.MarketPlace.PlayerOwnsAsset, service.MarketPlace, p, tonumber(pass))
					end

					if (ran and ret) or (pGroup and pGroup.Rank >= 10) then --// Complimentary donor access is given to Adonis contributors & developers.
						Variables.CachedDonors[key] = os.time()
						return true
					end
				end
			end
		end;

		CheckBan = function(p)
			local doCheck = Admin.DoCheck
			local banCheck = Admin.DoBanCheck

			for ind, admin in pairs(Settings.Banned) do
				if (type(admin) == "table" and ((admin.UserId and doCheck(p, admin.UserId, true)) or (admin.Name and not admin.UserId and doCheck(p, admin.Name, true)))) or doCheck(p, admin, true) then
					return true, (type(admin) == "table" and admin.Reason)
				end
			end

			for ind, ban in pairs(Core.Variables.TimeBans) do
				if p.UserId == ban.UserId then
					if ban.EndTime-os.time() <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						return true, "\n Reason: "..(ban.Reason or "(No reason provided.)").."\n Banned until ".. service.FormatTime(ban.EndTime, {WithWrittenDate = true})
					end
				end
			end

			for ind, admin in pairs(HTTP.Trello.Bans) do
				local name = type(admin) == "table" and admin.Name or admin
				if doCheck(p, name) or banCheck(p, name) then
					return true, (type(admin) == "table" and admin.Reason and service.Filter(admin.Reason, p, p))
				end
			end

			if HTTP.WebPanel.Bans then
				for ind, admin in pairs(HTTP.WebPanel.Bans) do
					if doCheck(p, admin) or banCheck(p, admin) then
						return true, (type(admin) == "table" and admin.Reason)
					end
				end
			end
		end;

		AddBan = function(p, reason, doSave, moderator)
			local value = {
				Name = p.Name;
				UserId = p.UserId;
				Reason = reason;
				Moderator = if moderator then service.FormatPlayer(moderator) else "%SYSTEM%";
			}

			table.insert(Settings.Banned, value)--p.Name..':'..p.UserId

			if doSave then
				Core.DoSave({
					Type = "TableAdd";
					Table = "Banned";
					Value = value;
				})

				Core.CrossServer("RemovePlayer", p.Name, Variables.BanMessage, value.Reason or "No reason provided")
			end

			if type(p) ~= "table" then
				if not service.Players:FindFirstChild(p.Name) then
					Remote.Send(p,'Function','KillClient')
				else
					if p then pcall(function() p:Kick(Variables.BanMessage .. " | Reason: "..(value.Reason or "No reason provided")) end) end
				end
			end

			service.Events.PlayerBanned:Fire(p, reason, doSave, moderator)
		end;

		AddTimeBan = function(p : Player | {[string]: any}, duration: number, reason: string, moderator: Player?)
			local value = {
				Name = p.Name;
				UserId = p.UserId;
				EndTime = os.time() + tonumber(duration);
				Reason = reason;
				Moderator = if moderator then service.FormatPlayer(moderator) else "%SYSTEM%";
			}

			table.insert(Core.Variables.TimeBans, value)

			Core.DoSave({
				Type = "TableAdd";
				Table = {"Core", "Variables", "TimeBans"};
				Value = value;
			})

			Core.CrossServer("RemovePlayer", p.Name, Variables.BanMessage, value.Reason or "No reason provided")

			if type(p) ~= "table" then
				if not service.Players:FindFirstChild(p.Name) then
					Remote.Send(p, "Function", "KillClient")
				else
					if p then pcall(function() p:Kick(Variables.BanMessage .. " | Reason: "..(value.Reason or "No reason provided")) end) end
				end
			end

			service.Events.PlayerBanned:Fire(p, reason, true, moderator)
		end,

		DoBanCheck = function(name: string | number | Instance, check: string | {[string]: any})
			local id = type(name) == "number" and name

			if type(name) == "userdata" and name:IsA("Player") then
				id = name.UserId
				name = name.Name
			end

			if type(check) == "table" then
				if type(name) == "string" and check.Name and string.lower(check.Name) == string.lower(name) then
					return true
				elseif id and check.UserId and check.UserId == id then
					return true
				end
			elseif type(check) == "string" then
				local cName, cId = string.match(check, "(.*):(.*)")
				if not cName and cId then cName = check end

				if cName then
					if string.lower(cName) == string.lower(name) then
						return true
					elseif id and cId and id == cId then
						return true
					end
				else 
					return string.lower(tostring(check)) == string.lower(tostring(name))
				end
			end

			return false
		end;

		RemoveBan = function(name, doSave)
			local ret
			for i,v in pairs(Settings.Banned) do
				if Admin.DoBanCheck(name, v) then
					table.remove(Settings.Banned, i)
					ret = v
					if doSave then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = v;
							LaxCheck = true;
						})
					end
				end
			end
			return ret
		end;

		RemoveTimeBan = function(name : string | number | Instance)
			local ret
			for i,v in pairs(Core.Variables.TimeBans) do
				if Admin.DoBanCheck(name, v) then
					table.remove(Core.Variables.TimeBans, i)
					ret = v
					Core.DoSave({
						Type = "TableRemove";
						Table = {"Core", "Variables", "TimeBans"};
						Value = v;
						LaxCheck = true;
					})
				end
			end
			return ret
		end,

		RunCommand = function(coma: string, ...)
			local _, com = Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma, #cmdArgs, ...)

				--local task,ran,error = service.Threads.TimeoutRunTask("SERVER_COMMAND: "..coma,com.Function,60*5,false,args)
				--[[local ran, error = TrackTask("Command: ".. tostring(coma), com.Function, false, args)
				if error then
					--logError("SERVER","Command",error)
				end]]

				TrackTask("Command: ".. coma, com.Function, false, args)
			end
		end;

		RunCommandAsPlayer = function(coma, plr, ...)
			local ind, com = Admin.GetCommand(coma)
			if com then
				local adminLvl = Admin.GetLevel(plr)

				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma, #cmdArgs, ...)

				local ran, error = TrackTask(plr.Name .. ": ".. coma, com.Function, plr, args, {
					PlayerData = {
						Player = plr;
						Level = adminLvl;
						isDonor = ((Settings.DonorCommands or com.AllowDonors) and Admin.CheckDonor(plr)) or false;
					}
				})

				--local task,ran,error = service.Threads.TimeoutRunTask("COMMAND:"..plr.Name..": "..coma,com.Function,60*5,plr,args)
				if error then
					--logError(plr,"Command",error)
					error = string.match(error, ":(.+)$") or "Unknown error"
					Remote.MakeGui(plr, "Output", {
						Title = '';
						Message = error;
						Color = Color3.new(1, 0, 0)
					})
					return;
				end
			end
		end;

		RunCommandAsNonAdmin = function(coma, plr, ...)
			local ind, com = Admin.GetCommand(coma)
			if com and com.AdminLevel == 0 then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma,#cmdArgs,...)
				local _, error = TrackTask(plr.Name ..": ".. coma, com.Function, plr, args, {PlayerData = {
					Player = plr;
					Level = 0;
					isDonor = false;
				}})
				if error then
					error = string.match(error, ":(.+)$") or "Unknown error"
					Remote.MakeGui(plr, "Output", {
						Title = "";
						Message = error;
						Color = Color3.new(1, 0, 0)
					})
				end
			end
		end;

		CacheCommands = function()
			local tempTable = {}
			local tempPrefix = {}
			for ind, data in pairs(Commands) do
				if type(data) == "table" then
					for i,cmd in pairs(data.Commands) do
						if data.Prefix == "" then Variables.BlankPrefix = true end
						tempPrefix[data.Prefix] = true
						tempTable[string.lower(data.Prefix..cmd)] = ind
					end
				end
			end

			Admin.PrefixCache = tempPrefix
			Admin.CommandCache = tempTable
		end;

		GetCommand = function(Command)
			if Admin.PrefixCache[string.sub(Command, 1, 1)] or Variables.BlankPrefix then
				local matched
				matched = if string.find(Command, Settings.SplitKey) then
					string.match(Command, "^(%S+)"..Settings.SplitKey)
					else string.match(Command, "^(%S+)")

				if matched then
					local found = Admin.CommandCache[string.lower(matched)]
					if found then
						local real = Commands[found]
						if real then
							return found,real,matched
						end
					end
				end
			end
		end;

		FindCommands = function(Command)
			local prefixChar = string.sub(Command, 1, 1)
			local checkPrefix = Admin.PrefixCache[prefixChar] and prefixChar
			local matched

			if checkPrefix then
				Command = string.sub(Command, 2)
			end

			if string.find(Command, Settings.SplitKey) then
				matched = string.match(Command, "^(%S+)"..Settings.SplitKey)
			else
				matched = string.match(Command, "^(%S+)")
			end

			if matched then
				local foundCmds = {}
				matched = string.lower(matched)

				for ind,cmd in pairs(Commands) do
					if type(cmd) == "table" and ((checkPrefix and prefixChar == cmd.Prefix) or not checkPrefix) then
						for _, alias in pairs(cmd.Commands) do
							if string.lower(alias) == matched then
								foundCmds[ind] = cmd
								break
							end
						end
					end
				end

				return foundCmds
			end
		end;

		SetPermission = function(comString, newLevel)
			local cmds = Admin.FindCommands(comString)
			if cmds then
				for ind, cmd in pairs(cmds) do
					cmd.AdminLevel = newLevel
				end
			end
		end;

		FormatCommandArguments = function(command)
			local text = ""
			for i, arg in ipairs(command.Args) do
				text ..= "<"..arg..">"
				if i < #command.Args then
					text ..= Settings.SplitKey
				end
			end
			return text
		end;

		FormatCommand = function(command, cmdn)
			local text = command.Prefix..command.Commands[cmdn or 1]
			if #command.Args > 0 then
				text ..= Settings.SplitKey .. Admin.FormatCommandArguments(command)
			end
			return text
		end;

		FormatCommandAdminLevel = function(command)
			local levels = if type(command.AdminLevel) == "table"
				then table.clone(command.AdminLevel)
				else {command.AdminLevel}
			local permissionDesc = ""
			for i, lvl in ipairs(levels) do
				if type(lvl) == "number" then
					local list, name, data = Admin.LevelToList(lvl)
					permissionDesc ..= (name or "No Rank") .."; Level ".. lvl
				elseif type(lvl) == "string" then
					local numLvl = Admin.StringToComLevel(lvl)
					permissionDesc ..= lvl .. "; Level ".. (numLvl or "Unknown")
				end

				if i < #levels then
					permissionDesc ..= ", "
				end
			end
			return permissionDesc
		end;

		CheckTable = function(p, tab)
			local doCheck = Admin.DoCheck
			for i,v in pairs(tab) do
				if doCheck(p, v) then
					return true
				end
			end
		end;

		--// Make it so you can't accidentally overwrite certain existing commands... resulting in being unable to add/edit/remove aliases (and other stuff)
		CheckAliasBlacklist = function(alias)
			local playerPrefix = Settings.PlayerPrefix;
			local prefix = Settings.Prefix;
			local blacklist = {
				[playerPrefix.. "alias"] = true;
				[playerPrefix.. "newalias"] = true;
				[playerPrefix.. "removealias"] = true;
				[playerPrefix.. "client"] = true;
				[playerPrefix.. "userpanel"] = true;
				[":adonissettings"] = true;

			}
			--return Admin.CommandCache[alias:lower()] --// Alternatively, we could make it so you can't overwrite ANY existing commands...
			return blacklist[alias];
		end;

		GetArgs = function(msg, num, ...)
			local args = Functions.Split((string.match(msg, "^.-"..Settings.SplitKey..'(.+)') or ''),Settings.SplitKey,num) or {}
			for i,v in pairs({...}) do table.insert(args, v) end
			return args
		end;

		AliasFormat = function(aliases, msg)
			local foundPlayerAlias = false --// Check if there's a player-defined alias first then otherwise check settings aliases

			local CheckAliasBlacklist, EscapeSpecialCharacters = Admin.CheckAliasBlacklist, service.EscapeSpecialCharacters

			if aliases then
				for alias, cmd in pairs(aliases) do
					local tAlias = stripArgPlaceholders(alias)
					if not Admin.CheckAliasBlacklist(tAlias) then
						local escAlias = EscapeSpecialCharacters(tAlias)
						if string.match(msg, "^"..escAlias) or string.match(msg, "%s".. escAlias) then
							msg = FormatAliasArgs(alias, cmd, msg)
						end
					end
				end
			end

			--if not foundPlayerAlias then
			for alias, cmd in pairs(Settings.Aliases) do
				local tAlias = stripArgPlaceholders(alias)
				if not CheckAliasBlacklist(tAlias) then
					local escAlias = EscapeSpecialCharacters(tAlias)
					if string.match(msg, "^"..escAlias) or string.match(msg, "%s".. escAlias) then
						msg = FormatAliasArgs(alias, cmd, msg)
					end
				end
			end
			--end

			return msg
		end;

		StringToComLevel = function(str)
			local strType = type(str)
			if strType == "string" and string.lower(str) == "players" then
				return 0
			end
			if strType == "number" then
				return str
			end

			local lvl = Settings.Ranks[str]
			return (lvl and lvl.Level) or tonumber(str)
		end;

		CheckComLevel = function(plrAdminLevel, comLevel)
			if type(comLevel) == "string" then
				comLevel = Admin.StringToComLevel(comLevel)
			elseif type(comLevel) == "table" then
				for _, level in ipairs(comLevel) do
					if Admin.CheckComLevel(plrAdminLevel, level) then
						return true
					end
				end
				return false
			end

			return type(comLevel) == "number" and plrAdminLevel >= comLevel
		end;

		IsBlacklisted = function(p)
			local CheckTable = Admin.CheckTable
			for _, list in pairs(Variables.Blacklist.Lists) do
				if CheckTable(p, list) then
					return true
				end
			end
		end;

		CheckPermission = function(pDat, cmd, ignoreCooldown, opts)
			opts = opts or {}

			local adminLevel = pDat.Level
			local comLevel = cmd.AdminLevel

			if cmd.Disabled then
				return false, "This command has been disabled."
			end

			if Variables.IsStudio and cmd.NoStudio then
				return false, "This command cannot be used in Roblox Studio."
			end

			if opts.CrossServer and cmd.CrossServerDenied then
				return false, "This command may not be run across servers (cross-server-blacklisted)."
			end

			if Admin.IsPlaceOwner(pDat.Player) or adminLevel >= Settings.Ranks.Creators.Level then
				return true, nil
			end
					
			if Admin.IsBlacklisted(pDat.Player) then
				return false, "You are blacklisted from running commands."
			end

			if (comLevel == 0 or comLevel == "Players") and adminLevel <= 0 and not Settings.PlayerCommands then
				return false, "Player commands are disabled in this game."
			end

			if cmd.Fun and not Settings.FunCommands then
				return false, "Fun commands are disabled in this game."
			end

			if opts.Chat and cmd.Chattable == false then
				return false, "This command is not permitted as chat message (non-chattable command)."
			end

			local permAllowed = (cmd.Donors and (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors)))
				or Admin.CheckComLevel(adminLevel, comLevel)

			if permAllowed and not ignoreCooldown and type(pDat.Player) == "userdata" then
				local playerCooldown = tonumber(cmd.PlayerCooldown)
				local serverCooldown = tonumber(cmd.ServerCooldown)
				local crossCooldown = tonumber(cmd.CrossCooldown)

				local cmdFullName = cmd._fullName or (function()
					local aliases = cmd.Aliases or cmd.Commands or {}
					cmd._fullName = cmd.Prefix..(aliases[1] or service.getRandom().."-RANDOM_COMMAND")
					return cmd._fullName
				end)()

				local pCooldown_Cache = cmd._playerCooldownCache or (function()
					local tab = {}
					cmd._playerCooldownCache = tab
					return tab
				end)()

				local sCooldown_Cache = cmd._serverCooldownCache or (function()
					local tab = {}
					cmd._serverCooldownCache = tab
					return tab
				end)()

				local crossCooldown_Cache = cmd._crossCooldownCache or (function()
					local tab = {}
					cmd._crossCooldownCache = tab
					return tab
				end)()

				local cooldownIndex = tostring(pDat.Player.UserId)
				local pCooldown_playerCache = pCooldown_Cache[cooldownIndex]
				local sCooldown_playerCache = sCooldown_Cache[cooldownIndex]

				if playerCooldown and pCooldown_playerCache then
					local secsTillPass = os.clock() - pCooldown_playerCache
					if secsTillPass < playerCooldown then
						return false, string.format("[PlayerCooldown] You must wait %.0f seconds to run the command.", playerCooldown - secsTillPass)
					end
				end

				if serverCooldown and sCooldown_playerCache then
					local secsTillPass = os.clock() - sCooldown_playerCache
					if secsTillPass < serverCooldown then
						return false, string.format("[ServerCooldown] You must wait %.0f seconds to run the command.", serverCooldown - secsTillPass)
					end
				end

				if crossCooldown then
					local playerData = Core.GetPlayer(pDat.Player) or {}
					local crossCooldown_Cache = playerData._crossCooldownCache or (function()
						local tab = {}
						playerData._crossCooldownCache = tab
						return tab
					end)()
					local crossCooldown_playerCache = crossCooldown_Cache[cmdFullName]

					if crossCooldown_playerCache then
						local secsTillPass = os.clock() - crossCooldown_playerCache
						if secsTillPass < crossCooldown then
							return false, string.format("[CrossServerCooldown] You must wait %.0f seconds to run the command.", crossCooldown - secsTillPass)
						end
					end
				end
			end

			return permAllowed, nil
		end;

		UpdateCooldown = function(pDat, cmd)
			if pDat.Player == "SYSTEM" then return end
			local playerCooldown = tonumber(cmd.PlayerCooldown)
			local serverCooldown = tonumber(cmd.ServerCooldown)
			local crossCooldown = tonumber(cmd.CrossCooldown)

			local cmdFullName = cmd._fullName or (function()
				local aliases = cmd.Aliases or cmd.Commands or {}
				cmd._fullName = cmd.Prefix..(aliases[1] or service.getRandom().."-RANDOM_COMMAND")
				return cmd._fullName
			end)()

			local pCooldown_Cache = cmd._playerCooldownCache or (function()
				local tab = {}
				cmd._playerCooldownCache = tab
				return tab
			end)()

			local sCooldown_Cache = cmd._serverCooldownCache or (function()
				local tab = {}
				cmd._serverCooldownCache = tab
				return tab
			end)()

			local crossCooldown_Cache = cmd._crossCooldownCache or (function()
				local tab = {}
				cmd._crossCooldownCache = tab
				return tab
			end)()

			local cooldownIndex = tostring(pDat.Player.UserId)
			local pCooldown_playerCache = pCooldown_Cache[cooldownIndex]
			local sCooldown_playerCache = sCooldown_Cache[cooldownIndex]
			local lastUsed = os.clock()

			if playerCooldown then
				pCooldown_Cache[cooldownIndex] = lastUsed
			end

			if serverCooldown then
				sCooldown_Cache[cooldownIndex] = lastUsed
			end

			--// Cross cooldown
			do
				local playerData = Core.GetPlayer(pDat.Player)
				local crossCooldown_Cache = playerData._crossCooldownCache or {}
				local crossCooldown_playerCache = crossCooldown_Cache[cmdFullName]

				if not crossCooldown and crossCooldown_playerCache then
					crossCooldown_playerCache[cmdFullName] = nil
				elseif crossCooldown then
					crossCooldown_Cache[cmdFullName] = lastUsed
				end
			end
		end;

		SearchCommands = function(p, search)
			local checkPerm = Admin.CheckPermission
			local tab = {}
			local pDat = {
				Player = p;
				Level = Admin.GetLevel(p);
				isDonor = Admin.CheckDonor(p);
			}

			for ind, cmd in pairs(Commands) do
				if checkPerm(pDat, cmd, true) then
					tab[ind] = cmd
				end
			end

			return tab
		end;
	}
end
