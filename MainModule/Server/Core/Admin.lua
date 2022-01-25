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

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Commands
	local AddLog, TrackTask, Defaults
	local CreatorId = game.CreatorType == Enum.CreatorType.User and game.CreatorId
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

		if not CreatorId then
			TrackTask("Thread: GetGroupCreatorId", function()
				CreatorId = service.GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
			end)
		end

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
				Ranks[rank] = data
			end
		end

		--// Old settings/plugins backwards compatability
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

		DoHideChatCmd = function(p, message, data)
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

		GetPlayerGroup = function(p, group)
			local groups;
			do
				local key = tostring(p.UserId)

				local groupTable = Admin.GroupsCache[key]
				if not groupTable then
					Admin.GroupsCache[key] = {}
				end

				local groupInfo = groupTable and groupTable[group] or {}
				if not groupInfo[1] or os.time() - groupInfo[1] < 30 then
					Admin.GroupsCache[key][group] = {
						os.time(),
						service.GroupService:GetGroupsAsync(p.UserId) or {}
					}
					groups = Admin.GroupsCache[key][group][2]
				else
					groups = groupInfo[2] or {}
				end
			end

			local isID = type(group) == "number"
			if groups then
				for _, v in ipairs(groups) do
					if isID and group == v.Id or not isID and group == v.Name then
						return v
					end
				end
			end
		end;

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

		DoCheck = function(p, check, banCheck)
			local pType = type(p)
			local cType = type(check)

			local lower = string.lower
			local match = string.match
			local sub = string.sub

			if pType == "string" and cType == "string" then
				if p == check or sub(lower(check), 1, #tostring(p)) == lower(p) then
					return true
				end
			elseif pType == "number" and (cType == "number" or tonumber(check)) then
				if p == tonumber(check) then
					return true
				end
			elseif cType == "number" then
				if p.UserId == check then
					return true
				end
			elseif cType == "string" and pType == "userdata" and p:IsA("Player") then
				local isGood = p and p.Parent == service.Players
				if isGood and match(check, "^Group:(.*):(.*)") then
					local sGroup, sRank = match(check, "^Group:(.*):(.*)")
					local group, rank = tonumber(sGroup), tonumber(sRank)
					if group and rank then
						local pGroup = Admin.GetPlayerGroup(p, group)
						if pGroup then
							local pRank = pGroup.Rank
							if pRank == rank or (rank < 0 and pRank >= math.abs(rank)) then
								return true
							end
						end
					end
				elseif isGood and sub(check, 1, 6) == "Group:" then --check:match("^Group:(.*)") then
					local group = tonumber(match(check, "^Group:(.*)"))
					if group then
						local pGroup = Admin.GetPlayerGroup(p, group)
						if pGroup then
							return true
						end
					end
				elseif isGood and sub(check, 1, 5) == "Item:" then --check:match("^Item:(.*)") then
					local item = tonumber(match(check, "^Item:(.*)"))
					if item then
						if service.MarketPlace:PlayerOwnsAsset(p, item) then
							return true
						end
					end
				elseif p and sub(check, 1, 9) == "GamePass:" then --check:match("^GamePass:(.*)") then
					local item = tonumber(match(check, "^GamePass:(.*)"))
					if item then
						if service.MarketPlace:UserOwnsGamePassAsync(p.UserId, item) then
							return true
						end
					end
				elseif match(check, "^(.*):(.*)") then
					local player, sUserid = match(check, "^(.*):(.*)")
					local userid = tonumber(sUserid)
					if player and userid and p.Name == player or p.UserId == userid then
						return true
					end
				elseif p.Name == check then
					return true
				elseif not banCheck and type(check) == "string" and not string.find(check, ":") then
					local cache = Admin.UserIdCache[check]

					if cache and p.UserId == cache then
						return true
					elseif not cache then
						local suc, userId = pcall(function() return service.Players:GetUserIdFromNameAsync(check) end)

						if suc and userId then
							Admin.UserIdCache[check] = userId

							if p.UserId == userId then
								return true
							end
						end
					end
				end
			elseif cType == "table" and pType == "userdata" and p and p:IsA("Player") then
				if check.Group and check.Rank then
					local rank = check.Rank
					local pGroup = Admin.GetPlayerGroup(p, check.Group)
					if pGroup then
						local pRank = pGroup.Rank
						if pRank == rank or (rank < 0 and pRank >= math.abs(rank)) then
							return true
						end
					end
				end
			end
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
			local level, rank = Admin.GetUpdatedLevel(p, data)

			data.AdminLevel = level
			data.AdminRank = rank
			data.LastLevelUpdate = os.time()

			AddLog("Script", {
				Text = "Updating cached level for ".. p.Name;
				Desc = "Updating the cached admin level for ".. p.Name;
				Player = p;
			})

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

			if Admin.IsPlaceOwner(p) then
				return 1000, "Place Owner"
			end

			--[[if data and data.AdminLevelOverride then
				return data.AdminLevelOverride
			end--]]

			for ind, admin in pairs(Admin.SpecialLevels) do
				if doCheck(p,admin.Player) then
					return admin.Level, admin.Rank
				end
			end

			local sortedRanks = {};
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

			local highest = 0
			local highestRank = nil

			for _, data in pairs(sortedRanks) do
				local level = data.Level;
				if level > highest then
					for i,v in ipairs(data.Users) do
						if doCheck(p, v) then
							highest, highestRank = level, data.Rank
							break
						end
					end
				end
			end

			return highest, highestRank
		end;

		IsPlaceOwner = function(p)
			if type(p) == "userdata" and p:IsA("Player") then
				--// These are my accounts; Lately I've been using my game dev account(698712377) more so I'm adding it so I can debug without having to sign out and back in (it's really a pain)
				--// Disable CreatorPowers in settings if you don't trust me. It's not like I lose or gain anything either way. Just re-enable it BEFORE telling me there's an issue with the script so I can go to your place and test it.
				if Settings.CreatorPowers then
					for _, userId in ipairs({1237666, 76328606, 698712377}) do
						if p.UserId == userId then
							return true
						end
					end
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
				table.remove(Admin.TempAdmins,tempInd)
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
				table.insert(newList,value)

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
				for _, pass in ipairs(Variables.DonorPass) do
					local ran, ret;
					if type(pass) == "number" then
						ran,ret = pcall(service.MarketPlace.UserOwnsGamePassAsync, service.MarketPlace, p.UserId, pass)
					elseif type(pass) == "string" and tonumber(pass) then
						ran,ret = pcall(service.MarketPlace.PlayerOwnsAsset, service.MarketPlace, p, tonumber(pass))
					end

					if p:GetRankInGroup(886423) >= 10 or ran and ret then
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
				if (p.UserId == ban.UserId) then
					if ban.EndTime-os.time() <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						return true, "\n Reason: "..(ban.Reason or "(No reason provided.)").."\n Banned until ".. service.FormatTime(ban.EndTime, true)
					end
				end
			end

			for ind, admin in pairs(HTTP.Trello.Bans) do
				if doCheck(p, admin) or banCheck(p, admin) then
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

		AddBan = function(p, reason, doSave)
			local value = {
				Name = p.Name;
				UserId = p.UserId;
				Reason = reason;
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
		end;

		DoBanCheck = function(name, check)
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
						return true;
					elseif id and cId and id == cId then
						return true;
					end
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
						})
					end
				end
			end
			return ret
		end;

		RunCommand = function(coma, ...)
			local ind, com = Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma,#cmdArgs,...)

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
				local args = Admin.GetArgs(coma,#cmdArgs,...)

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
					Remote.MakeGui(plr, 'Output', {
						Title = '';
						Message = error;
						Color = Color3.new(1,0,0)
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
					Remote.MakeGui(plr, 'Output', {
						Title = "";
						Message = error;
						Color = Color3.new(1,0,0)
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

		FormatCommand = function(command, cmdn)
			local text = command.Prefix.. command.Commands[cmdn or 1]
			local cmdArgs = command.Args or command.Arguments
			local splitter = Settings.SplitKey

			for ind,arg in pairs(cmdArgs) do
				text ..= splitter.."<"..arg..">"
			end

			return text
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
			end

			if type(comLevel) == "number" and plrAdminLevel >= comLevel then
				return true;
			elseif type(comLevel) == "table" then
				for i,level in pairs(comLevel) do
					if plrAdminLevel == level then
						return true
					end
				end
			end
		end;

		IsBlacklisted = function(p)
			local CheckTable = Admin.CheckTable
			for i,list in pairs(Variables.Blacklist.Lists) do
				if CheckTable(p, list) then
					return true
				end
			end
		end;

		CheckPermission = function(pDat, cmd)
			local adminLevel = pDat.Level
			local isDonor = (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors))
			local comLevel = cmd.AdminLevel
			local funAllowed = Settings.FunCommands
			local crossServerAllowed = Settings.CrossServerCommands

			if adminLevel >= Settings.Ranks.Creators.Level then
				return true
			elseif cmd.Fun and not funAllowed then
				return false
			elseif cmd.IsCrossServer and not crossServerAllowed then
				return false
			elseif cmd.Donors and isDonor then
				return true
			elseif comLevel == 0 and Settings.PlayerCommands then
				return true
			elseif Admin.CheckComLevel(adminLevel, comLevel) then
				return true
			end

			return false
		end;

		SearchCommands = function(p, search)
			local checkPerm = Admin.CheckPermission
			local tab = {}
			local pDat = {
				Player = p;
				Level = Admin.GetLevel(p);
				isDonor = Admin.CheckDonor(p);
			}

			for index, command in pairs(Commands) do
				if checkPerm(pDat, command) then
					tab[index] = command
				end
			end

			return tab
		end;
	}
end
