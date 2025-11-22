server = nil
service = nil
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

			--// Support for modern TextChatService
			if service.TextChatService and service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				local function onNewTextchannel(textchannel: TextChannel)
					AddLog("Script", `Connected to TextChannel: {textchannel.Name}`)

					if Settings.OverrideChatCallbacks ~= false then --// Default to "on" this for all games
						AddLog("Script", "Overriding ShouldDeliverCallback for " .. textchannel.Name)
						textchannel.ShouldDeliverCallback = function(chatMessage, textSource)
							if
								chatMessage.Status == Enum.TextChatMessageStatus.Success
								or chatMessage.Status == Enum.TextChatMessageStatus.Sending
							then
								local SenderId = chatMessage.TextSource.UserId
								local SenderPlayer = service.Players:GetPlayerByUserId(SenderId)
								local Receiver = service.Players:GetPlayerByUserId(textSource.UserId)
								local slowCache = Admin.SlowCache

								local IsOriginalSender = SenderPlayer == Receiver

								if not SenderPlayer then
									return true
								elseif Settings.ChatCommands and Admin.DoHideChatCmd(SenderPlayer, chatMessage.Text) then -- // Hide chat commands?
									if IsOriginalSender then
										Remote.Send(SenderPlayer, "Function", "DisplaySystemMessageInTextChat", nil, "You ran a command hidden from others!")
									end

									return false
								elseif Admin.IsMuted(SenderPlayer) then -- // Mute handler
									if IsOriginalSender then
										Remote.Send(SenderPlayer, "Function", "DisplaySystemMessageInTextChat", nil, `<font color="rgb(130, 100, 130)">[Adonis Chat]: </font><b>You are muted!</b> Other players cannot see your messages.`)
									end

									return false
								elseif Admin.SlowMode and not Admin.CheckAdmin(SenderPlayer) and slowCache[SenderPlayer] and os.time() - slowCache[SenderPlayer] < Admin.SlowMode then
									if IsOriginalSender then --// Only show this for the person sending! Hide for others, however
										--Functions.Notification("You are chatting too fast!", string.format("[Adonis] :: Slow mode enabled! (%g second(s) remaining)", Admin.SlowMode - (os.time() - slowCache[SenderPlayer])), {SenderPlayer}, 10)

										Remote.Send(SenderPlayer, "Function", "DisplaySystemMessageInTextChat", nil, `<font color="rgb(130, 100, 130)">[Adonis Chat]: </font><b>You are sending messages too fast! {string.format("(%g second(s) remaining)", Admin.SlowMode - (os.time() - slowCache[SenderPlayer]))}</b>`)
									end

									return false
								end

								if Variables.DisguiseBindings[SenderId] then -- // Disguise command handler
									chatMessage.PrefixText = Variables.DisguiseBindings[SenderId].TargetUsername..":"
								end

								if Admin.SlowMode and IsOriginalSender then
									slowCache[SenderPlayer] = os.time()
								end
							end

							return true
						end
					else
						AddLog("Script", `Using the 'CanSend' method of handling chat connectivity in channel {textchannel.Name}`)
						Variables.TextChatSpeakers = {}
						local function AddUserToTextChatSpeakers(player: Player, speaker: TextSource)
							if not Variables.TextChatSpeakers[player] then
								Variables.TextChatSpeakers[player] = {}
							end
							table.insert(Variables.TextChatSpeakers[player], speaker)
							--// Check if the player is muted or not
							speaker:SetAttribute("OriginalCanSend", speaker.CanSend)
							if Admin.IsMuted(player) then
								speaker.CanSend = false
							end
						end
						local function SpeakerAdded(speaker: TextSource)
							if speaker.UserId and speaker.UserId > 0 then
								local Player = service.Players:GetPlayerByUserId(speaker.UserId)
								if Player then
									AddUserToTextChatSpeakers(Player, speaker)
								end
							end
						end
						local function SpeakerRemoved(speaker: TextSource)
							if speaker.UserId and speaker.UserId > 0 then
								local Player = service.Players:GetPlayerByUserId(speaker.UserId)
								local Tab = Variables.TextChatSpeakers[Player]
								if Tab then
									local index = table.find(Tab, speaker)
									while index do
										table.remove(Tab, index)
										index = table.find(Tab, speaker)
									end
									task.defer(function()
										if #Tab == 0 then
											Variables.TextChatSpeakers[Player] = nil
										end
									end)
								end
							end
						end

						service.RbxEvent(textchannel.ChildAdded, function(textSource)
							if textSource.ClassName == "TextSource" then
								pcall(SpeakerAdded, textSource)
							end
						end)

						service.RbxEvent(textchannel.ChildRemoved, function(textSource)
							if textSource.ClassName == "TextSource" then
								pcall(SpeakerRemoved, textSource)
							end
						end)

						for _,inst in textchannel:GetChildren() do
							if inst.ClassName == "TextSource" then
								pcall(SpeakerAdded, inst)
							end
						end

					end
				end

				--// Only set this up once
				--// This is for commands to tell us when a player should be muted
				if not Settings.OverrideChatCallbacks then
					service.Events.PlayerMuted:Connect(function(data)
						local PlayerId = data.Target;
						local ModId = data.Moderator;

						local Player = service.Players:GetPlayerByUserId(PlayerId)
						--// Loop through CanSend of a speaker
						for _,speakers : TextSource in if Player then Variables.TextChatSpeakers[Player] or {} else {} do
							speakers.CanSend = false
						end
						if Player then
							AddLog("Script", `Muted player {Player.Name}:{Player.UserId} using CanSend method`)
						end
					end)
					service.Events.PlayerUnMuted:Connect(function(data)
						local PlayerId = data.Target;
						local ModId = data.Moderator;

						local Player = service.Players:GetPlayerByUserId(PlayerId)
						--// Loop through CanSend of a speaker
						for _,speakers : TextSource in if Player then Variables.TextChatSpeakers[Player] or {} else {} do
							local original = speakers:GetAttribute("OriginalCanSend")
							speakers.CanSend = if original ~= nil then original else true
						end
						if Player then
							AddLog("Script", `UnMuted player {Player.Name}:{Player.UserId} via CanSend method`)
						end
					end)
					service.Events.MutedPlayerChat_UnFiltered:Connect(function(p, ...)
						Remote.Send(p, "Function", "DisplaySystemMessageInTextChat", nil, `<font color="rgb(130, 100, 130)">[Adonis Chat]: </font><b>You are muted!</b> Other players cannot see your messages.`)
					end)
				end


				local function onTextChannelsAdded(textChannels)
					service.RbxEvent(textChannels.ChildAdded, function(child)
						if child.ClassName == "TextChannel" then
							task.spawn(pcall, onNewTextchannel, child)
						end
					end)

					for _, v in textChannels:GetChildren() do
						if v.ClassName == "TextChannel" then
							task.spawn(pcall, onNewTextchannel, v)
						end
					end
				end

				service.RbxEvent(service.TextChatService.ChildAdded, function(child)
					if child.Name == "TextChannels" then
						task.spawn(pcall, onTextChannelsAdded, child)
					end
				end)

				local TextChannels = service.TextChatService:FindFirstChild("TextChannels")
				if TextChannels and TextChannels:IsA("Folder") then
					task.spawn(pcall, onTextChannelsAdded, TextChannels)
				end

				AddLog("Script", "TextChatService Handler Loaded")
			end
		end)

		--// Make sure the default ranks are always present for compatability with existing commands
		local Ranks = Settings.Ranks
		for rank, data in Defaults.Settings.Ranks do
			if not Ranks[rank] then
				for r, d in Ranks do
					if d.Level == data.Level then
						data.Hidden = true
						break
					end
				end
				Ranks[rank] = data
			end
		end

		if Settings.LoadAdminsFromDS then
			for rank in Settings.Ranks do
				service.Events[`DataStoreAdd_Settings.Ranks.{rank}.Users`]:Connect(function(data)
					local userId = if type(data) == "string"
						then (tonumber(string.match(data, ":(%d+)$")) or tonumber(data) or data)
						elseif type(data) == "table" then (tonumber(data.UserId) or data.Name)
						else nil

					local plr = type(userId) == "number" and service.Players:GetPlayerByUserId(userId)
						or type(userId) == "string" and service.Players:FindFirstChild(userId)
					if plr then
						Admin.UpdateCachedLevel(plr)
					end
				end)
			end
		end

		if Settings.CommandCooldowns then
			for cmdName, cooldownData in Settings.CommandCooldowns do
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

		--// Cache clearing job to clear GroupsCache every 6 minutes to prevent gradual memory leaking
		service.StartLoop("GroupsCacheClear", 360, function()
			for key, cache in Admin.GroupsCache do
				if os.time() - cache.LastUpdated > 300 then
					Admin.GroupsCache[key] = nil
				end
			end
		end, true)

		Admin.Init = nil;
		AddLog("Script", "Admin Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// Backup Map
		if Settings.AutoBackup then
			TrackTask("Thread: Initial Map Backup", Admin.RunCommand, false, `{Settings.Prefix}backupmap`)
		end

		--// Run OnStartup Commands
		for i,v in Settings.OnStartup do
			print(`Running startup command {v}`)
			TrackTask(`Thread: Startup_Cmd: {v}`, Admin.RunCommand, false, v)
			AddLog("Script", {
				Text = `Startup: Executed {v}`;
				Desc = `Executed startup command; {v}`;
			})
		end

		--// Check if Shutdownlogs is set and if not then set it
		if Core.DataStore and not Core.GetData("ShutdownLogs") then
			Core.SetData("ShutdownLogs", {})
		end

		Admin.RunAfterPlugins = nil;
		AddLog("Script", "Admin Module RunAfterPlugins Finished")
	end

	service.RbxEvent(service.MarketplaceService.PromptGamePassPurchaseFinished, function(player, id, purchased)
		if Variables and player.Parent and table.find(Variables.DonorPass, id) and purchased then
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
				local arg = `<{arg}>`
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
					local arg = `<{arg}>`
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

		local SanitizePattern = service.SanitizePattern
		for i,argType in argTab do
			local replaceWith = suppliedArgs[i]
			if replaceWith then
				out = string.gsub(out, SanitizePattern(argType), replaceWith)
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
		UsernameCache = {};
		GroupsCache = {};

		BlankPrefix = false;

		--// How long admin levels will be cached (unless forcibly updated via something like :admin user)
		AdminLevelCacheTimeout = 30;

		CheckSlowMode = function(p: Player)
			if Admin.SlowMode and Admin.SlowCache[p] and os.time() - Admin.SlowCache[p] < Admin.SlowMode then
				return true
			else
				return false
			end
		end,

		DoHideChatCmd = function(p: Player, message: string, data: {[string]: any}?)
			local pData = data or Core.GetPlayer(p)
			if pData.Client.HideChatCommands then
				if Admin.BlankPrefix and

					(string.sub(message,1,1) ~= Settings.Prefix or string.sub(message,1,1) ~= Settings.PlayerPrefix or (type(Settings.Prefix) == "table" and not table.find(Settings.Prefix, string.sub(message,1,1)))) then
					local isCMD = Admin.GetCommand(message)
					if isCMD then
						return true
					else
						return false
					end
				elseif (string.sub(message,1,1) == Settings.Prefix or string.sub(message,1,1) == Settings.PlayerPrefix or (type(Settings.Prefix) == "table" and table.find(Settings.Prefix, string.sub(message,1,1))))
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
				for _, g in groups do
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
					if (existCache and (os.time()-existCache.LastUpdated > 300)) or not existCache then
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
					return table.clone(cacheTab.Groups)
				else
					return table.clone((existCache and existCache.Groups) or {})
				end
			end
		end;

		GetGroupLevel = function(uid, groupId)
			groupId = tonumber(groupId)

			if groupId then
				local groups = Admin.GetGroups(uid) or {}

				for _, group in groups do
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
				for i,group in groups do
					if group.Id == groupId then
						return true
					end
				end
			end

			return false
		end,

		IsLax = function(str)
			for _, v in {"plr", "user", "player", "brickcolor"} do
				if string.match(string.lower(str), v) then
					return true
				end
			end

			return false
		end,

		IsMuted = function(player)
			local DoCheck = Admin.DoCheck
			for _, v in Settings.Muted do
				if DoCheck(player, v) then
					return true
				end
			end

			for _, v in HTTP.Trello.Mutes do
				if DoCheck(player, v) then
					return true
				end
			end

			if HTTP.WebPanel.Mutes then
				for _, v in HTTP.WebPanel.Mutes do
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

			local plr: Player = if pType == "userdata" and pObj:IsA("Player") then pObj
				elseif pType == "number" then service.Players:GetPlayerByUserId(pObj)
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
						local requiredRank,noRank = tonumber((string.match(filterData, "^%d+:(.+)$"))), string.match(filterData,"^%d+$")
						if requiredRank then
							if requiredRank < 0 then
								return plrRank >= math.abs(requiredRank)
							else
								return plrRank == requiredRank
							end
						elseif noRank then
							return plrRank > 0
						end
					end
					return false
				elseif filterName == "item" then
					local itemId = tonumber((string.match(filterData, "^%d+")))
					return itemId and service.CheckAssetOwnership(plr, itemId)
				elseif filterName == "gamepass" then
					local gamepassId = tonumber((string.match(filterData, "^%d+")))
					return gamepassId and service.CheckPassOwnership(plr, gamepassId)
				elseif filterName == "subscription" then
					local subscriptionId = string.match(filterData, "^EXP%-%d+$")
					return subscriptionId and service.CheckSubscriptionStatus(plr, subscriptionId)
				else
					local username, userId = string.match(check, "^(.*):(.*)")
					if username and userId and (plr.UserId == tonumber(userId) or string.lower(plr.Name) == string.lower(username)) then
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
			for i,v in Defaults.Settings.Ranks do
				local tRank = Settings.Ranks[i];
				if tRank and tRank.Level == v.Level and v.Level == lvl then
					return i
				end
			end

			for i,v in Settings.Ranks do
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
				Text = `Updating cached level for {p.Name}`;
				Desc = `Updating the cached admin level for {p.Name}`;
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
						Functions.Hint(`Your admin level has been reduced to {newLevel} [{newRank or "Unknown"}]`, {p})
					elseif newLevel > level then
						Functions.Hint(`Your admin level has been increased to {newLevel} [{newRank or "Unknown"}]`, {p})
					end
				end

				return newLevel, newRank
			end

			return level or 0, rank;
		end;

		GetUpdatedLevel = function(p, data)
			local checkTable = Admin.CheckTable
			local doCheck = Admin.DoCheck

			for _, admin in Admin.SpecialLevels do
				if doCheck(p, admin.Player) then
					return admin.Level, admin.Rank
				end
			end

			local sortedRanks = {}
			for rank, data in Settings.Ranks do
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

			for _, data in sortedRanks do
				local level = data.Level
				if level > highestLevel then
					for _, v in data.Users do
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

				if p.UserId == -1 and Variables.IsStudio then --// To account for player emulators in multi-client Studio tests
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
				end
			elseif level == "Reset" then
				Admin.SpecialLevels[tostring(p.UserId)] = nil
			end

			Admin.UpdateCachedLevel(p)
		end;

		IsTempAdmin = function(p)
			local DoCheck = Admin.DoCheck
			for i,v in Admin.TempAdmins do
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
				for ind,check in list do
					if DoCheck(p, check) and not (type(check) == "string" and (string.match(check,"^Group:") or string.match(check,"^Item:"))) then
						table.remove(list, ind)

						if not temp and Settings.SaveAdmins then
							TrackTask("Thread: RemoveAdmin", Core.DoSave, false, {
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

				for ind,ent in list do
					if (type(ent)=="number" or type(ent)=="string") and (ent==p.UserId or string.lower(ent)==string.lower(p.Name) or string.lower(ent)==string.lower(`{p.Name}:{p.UserId}`)) then
						index = ind
						value = ent
					end
				end

				if index and value then
					table.remove(list, index)
				end
			end

			local value = `{p.Name}:{p.UserId}`

			if newList then
				table.insert(newList, value)

				if Settings.SaveAdmins and levelName and not temp then
					TrackTask("Thread: SaveAdmin", Core.DoSave, false, {
						Type = "TableAdd";
						Table = {"Settings", "Ranks", levelName, "Users"};
						Value = value
					})
				end
			end

			Admin.UpdateCachedLevel(p)
		end;

		CheckDonor = function(p)
			local key = tostring(p.UserId)
			if Variables.CachedDonors[key] then
				return true
			else
				local pGroup = Admin.GetPlayerGroup(p, 886423)
				for _, pass in Variables.DonorPass do
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

			for ind, admin in Settings.Banned do
				if (type(admin) == "table" and ((admin.UserId and doCheck(p, admin.UserId, true)) or (admin.Name and not admin.UserId and doCheck(p, admin.Name, true)))) or doCheck(p, admin, true) then
					return true, (type(admin) == "table" and admin.Reason)
				end
			end

			for ind, ban in Core.Variables.TimeBans do
				if p.UserId == ban.UserId then
					if ban.EndTime-os.time() <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						return true, `\n {ban.Reason or "(No reason provided.)"}\n | Banned until {service.FormatTime(ban.EndTime, {WithWrittenDate = true})}`
					end
				end
			end

			for ind, admin in HTTP.Trello.Bans do
				local name = type(admin) == "table" and admin.Name or admin
				if doCheck(p, name) or banCheck(p, name) then
					return true, if type(admin) == "table" and admin.Reason and typeof(p) == "Instance" then service.Filter(admin.Reason, p, p) else admin.Reason
				end
			end

			if HTTP.WebPanel.Bans then
				for ind, admin in HTTP.WebPanel.Bans do
					if doCheck(p, admin) or banCheck(p, admin) then
						return true, (type(admin) == "table" and admin.Reason)
					end
				end
			end
		end;

		AddBan = function(p, reason, doSave, moderator, banType)
			local value = {
				Name = p.Name;
				UserId = p.UserId;
				Reason = reason;
				Moderator = if moderator then service.FormatPlayer(moderator) else "%SYSTEM%";
				BanType = banType
			}

			table.insert(Settings.Banned, value)

			if doSave then
				Core.DoSave({
					Type = "TableAdd";
					Table = "Banned";
					Value = value;
				})

				Core.CrossServer("RemovePlayer", tonumber(p.UserId), Variables.BanMessage, value.Reason or "No reason provided")
			end

			if type(p) ~= "table" then
				if not service.Players:FindFirstChild(p.Name) then
					Remote.Send(p,'Function','KillClient')
				else
					if p then pcall(function() p:Kick(`{Variables.BanMessage} | Reason: {value.Reason or "No reason provided"}`) end) end
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

			Core.CrossServer("RemovePlayer", tonumber(p.UserId), Variables.BanMessage, value.Reason or "No reason provided")

			if type(p) ~= "table" then
				if not service.Players:FindFirstChild(p.Name) then
					Remote.Send(p, "Function", "KillClient")
				else
					if p then pcall(function() p:Kick(`{Variables.BanMessage} | Reason: {value.Reason or "No reason provided"}`) end) end
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
					elseif id and cId and id == tonumber(cId) then
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
			for i,v in Settings.Banned do
				if Admin.DoBanCheck(name, v) then
					ret = table.remove(Settings.Banned, i)
					if doSave then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Banned";
							Value = ret;
							LaxCheck = true;
						})
					end
				end
			end
			return ret
		end;

		RemoveTimeBan = function(name : string | number | Instance)
			local ret
			for i,v in Core.Variables.TimeBans do
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

				TrackTask(`Command: {coma}`, com.Function, function(err)
					warn(`Encountered an error while running a command: {coma}\n{err}\n{debug.traceback()}`)
				end, false, args)
			end
		end;

		RunCommandAsPlayer = function(coma, plr, ...)
			local ind, com = Admin.GetCommand(coma)
			if com then
				local adminLvl = Admin.GetLevel(plr)

				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma, #cmdArgs, ...)
				local ran, error = TrackTask(
					`{plr.Name}: {coma}`,
					com.Function,
					function(err)
						err = string.match(err, ":(.+)$") or "Unknown error"
						Remote.MakeGui(plr, "Output", {
							Title = "Error",
							Message = error,
							Color = Color3.new(1, 0, 0),
						})
						warn(`Encountered an error while running a command: {coma}\n{err}\n{debug.traceback()}`)
					end,
					plr,
					args,
					{
						PlayerData = {
							Player = plr,
							Level = adminLvl,
							isDonor = ((Settings.DonorCommands or com.AllowDonors) and Admin.CheckDonor(plr)) or false,
						},
					}
				)
			end
		end;

		RunCommandAsNonAdmin = function(coma, plr, ...)
			local ind, com = Admin.GetCommand(coma)
			if com and com.AdminLevel == 0 then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma, #cmdArgs, ...)
				local _, error = TrackTask(
					`{plr.Name}: {coma}`,
					com.Function,
					function(err)
						err = string.match(err, ":(.+)$") or "Unknown error"
						Remote.MakeGui(plr, "Output", {
							Title = "",
							Message = error,
							Color = Color3.new(1, 0, 0),
						})
						warn(`Encountered an error while running a command: {coma}\n{err}\n{debug.traceback()}`)
					end,
					plr,
					args,
					{ PlayerData = {
						Player = plr,
						Level = 0,
						isDonor = false,
					} }
				)
			end
		end;

		CacheCommands = function()
			local tempTable = {}
			local tempPrefix = {}
			for ind, data in Commands do
				if type(data) == "table" then
					for i,cmd in data.Commands do
						if type(data.Prefix) ~= "table" and data.Prefix == "" then Admin.BlankPrefix = true end
						if type(data.Prefix) == "table" then
							for _,p in data.Prefix do
								tempPrefix[p] = true
								tempTable[string.lower(p..cmd)] = ind
							end
						else
							tempPrefix[data.Prefix] = true
							tempTable[string.lower(data.Prefix..cmd)] = ind
						end
					end
				end
			end

			Admin.PrefixCache = tempPrefix
			Admin.CommandCache = tempTable

			if Variables.ChatCreateRobloxCommands and Settings.ChatCommands then
				-- // Support for commands to be ran via TextChat
				task.spawn(function()
					local container = service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService and service.TextChatService:WaitForChild("TextChatCommands", 120)

					if container and container:IsA("Folder") then
						for _, v in container:GetChildren() do
							if string.sub(v.Name, 1, 7) == "Adonis_" then
								v:Destroy()
							end
						end

						local blacklistedCommands = {}

						for _, v in container:GetDescendants() do
							if v:IsA("TextChatCommand") then
								blacklistedCommands[v.PrimaryAlias] = true
								blacklistedCommands[v.SecondaryAlias] = true
							end
						end

						for name, data in Commands do
							local command1, command2 = nil, nil

							if type(data) ~= "table" or data.Hidden then
								continue
							end

							for _, v in data.Commands do
								if type(data.Prefix) == "table" then
									for _, p in data.Prefix do
										if not blacklistedCommands["/"..p..v] then
											if not command1 then
												command1 = "/"..p..v
											else
												command2 = "/"..p..v
											end
										end
									end
								else
									if not blacklistedCommands["/"..data.Prefix..v] then
										if not command1 then
											command1 = "/"..data.Prefix..v
										else
											command2 = "/"..data.Prefix..v
										end
									end

								end

							end

							if command1 then
								local command = service.New("TextChatCommand", {
									Name = `Adonis_{name}`,
									PrimaryAlias = command1,
									SecondaryAlias = command2 or "",
									Archivable = false,
								})
								command:SetAttribute("AdminLevel", tonumber(data.AdminLevel) or Admin.StringToComLevel(data.AdminLevel) or data.AdminLevel or nil)
								command.Triggered:Connect(function(textSource: TextSource, text: string)
									local player: Player = service.Players:GetPlayerByUserId(textSource.UserId)

									if player and type(text) == "string" then
										Remote.Commands.ProcessCommand(player, {string.sub(text, 2)})
									end
								end)
								command.Parent = container
							end
						end
					end
				end)
			end
		end;

		GetCommand = function(Command)
			if Admin.PrefixCache[string.sub(Command, 1, 1)] or Admin.BlankPrefix then
				local matched
				matched = if string.find(Command, Settings.SplitKey) then
					string.match(Command, `^(%S+){Settings.SplitKey}`)
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
				matched = string.match(Command, `^(%S+){Settings.SplitKey}`)
			else
				matched = string.match(Command, "^(%S+)")
			end

			if matched then
				local foundCmds = {}
				matched = string.lower(matched)

				for ind,cmd in Commands do
					if type(cmd) == "table" and ((checkPrefix and prefixChar == cmd.Prefix) or not checkPrefix) then
						for _, alias in cmd.Commands do
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
				for ind, cmd in cmds do
					cmd.AdminLevel = newLevel
				end
			end
		end;

		FormatCommandArguments = function(command)
			local text = table.create(#command.Args)
			for i, arg in command.Args do
				text[i] = `<{arg}>`
			end
			return table.concat(text, Settings.SplitKey)
		end;

		FormatCommand = function(command, cmdn)
			return table.concat({
				(if type(command.Prefix) == "table" then command.Prefix[1] else command.Prefix or ""),
				tostring(command.Commands[cmdn or 1]),
				#command.Args > 0 and Settings.SplitKey or "",
				#command.Args > 0 and Admin.FormatCommandArguments(command) or ""
			})
		end;

		FormatCommandAdminLevel = function(command)
			local levels = if type(command.AdminLevel) == "table"
				then table.clone(command.AdminLevel)
				else {command.AdminLevel}
			local permissionDesc = table.create(#levels)

			for i, lvl in levels do
				if type(lvl) == "number" then
					local list, name, data = Admin.LevelToList(lvl)
					permissionDesc[i] = `{name or "No Rank"}; Level {lvl}`
				elseif type(lvl) == "string" then
					local numLvl = Admin.StringToComLevel(lvl)
					permissionDesc[i] = `{lvl}; Level {numLvl or "Unknown"}`
				else
					permissionDesc[i] = "N/A"
				end
			end

			return table.concat(permissionDesc, ", ")
		end;

		CheckTable = function(p, tab)
			local doCheck = Admin.DoCheck
			for i,v in tab do
				if doCheck(p, v) then
					return true
				end
			end
		end;

		--// Make it so you can't accidentally overwrite certain existing commands... resulting in being unable to add/edit/remove aliases (and other stuff)
		CheckAliasBlacklist = function(alias)
			local playerPrefix = Settings.PlayerPrefix;
			local prefix = Settings.Prefix
			local blacklist = {
				[`{playerPrefix}alias`] = true;
				[`{playerPrefix}newalias`] = true;
				[`{playerPrefix}removealias`] = true;
				[`{playerPrefix}client`] = true;
				[`{playerPrefix}userpanel`] = true;
				[":adonissettings"] = true;
			}
			--return Admin.CommandCache[alias:lower()] --// Alternatively, we could make it so you can't overwrite ANY existing commands...
			return blacklist[alias];
		end;

		GetArgs = function(msg, num, ...)
			local newArgs = table.pack(...)
			local args = Functions.Split(string.match(msg, `^.-{Settings.SplitKey}(.+)`) or "", Settings.SplitKey, num) or table.create(newArgs.n)
			for i = 1, newArgs.n do
				table.insert(args, newArgs[i])
			end
			return args
		end;

		AliasFormat = function(aliases, msg)
			local foundPlayerAlias = false --// Check if there's a player-defined alias first then otherwise check settings aliases

			local CheckAliasBlacklist, SanitizePattern = Admin.CheckAliasBlacklist, service.SanitizePattern

			if aliases then
				for alias, cmd in aliases do
					local tAlias = stripArgPlaceholders(alias)
					if not Admin.CheckAliasBlacklist(tAlias) then
						local escAlias = SanitizePattern(tAlias)
						--// Ignore any "empty" aliases, aka aliases that would basically match any command
						if string.len(Functions.Trim(escAlias)) == 0 then
							continue
						end
						local trimmedMsg = Functions.Trim(msg)
						--// Use Adonis split to better support various characters that string.split can't handle properly
						local aliasCharacters = Functions.Split(trimmedMsg, Settings.SplitKey)
						--// Matching an alias can result in an infinite loop like running !fire with the alias !f, it will infinitely run the !f alias
						--// If you have an alias !f
						if escAlias == aliasCharacters[1] or string.match(trimmedMsg, `%s{escAlias}`) then
							msg = FormatAliasArgs(alias, cmd, msg)
						end
					end
				end
			end

			for alias, cmd in Variables.Aliases do
				local tAlias = stripArgPlaceholders(alias)
				if not CheckAliasBlacklist(tAlias) then
					local escAlias = SanitizePattern(tAlias)
					if string.match(msg, `^{escAlias}`) or string.match(msg, `%s{escAlias}`) then
						msg = FormatAliasArgs(alias, cmd, msg)
					end
				end
			end

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
				for _, level in comLevel do
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
			for _, list in Variables.Blacklist.Lists do
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

			if Variables.IsStudio and cmd.NoStudio and not Core.DebugMode then
				return false, "This command cannot be used in Roblox Studio."
			end

			if opts.CrossServer and cmd.CrossServerDenied then -- Ignore when disabled then
				return false, "This command may not be run across servers (cross-server-blacklisted)."
			end

			if (cmd.CrossServer or cmd.IsCrossServer) and not Settings.CrossServerCommands then
				return false, "This command has been disabled due to CrossServerCommands being disabled"
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

			if opts.Chat and cmd.NonChattable == true then
				return false, "This command is not permitted as chat message (non-chattable command)."
			end

			local permAllowed = (cmd.Donors and (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors))) or (cmd.Agent and HTTP.Trello.CheckAgent) and HTTP.Trello.CheckAgent(pDat.Player)
				or Admin.CheckComLevel(adminLevel, comLevel)

			if permAllowed and not ignoreCooldown and type(pDat.Player) == "userdata" then
				local playerCooldown = tonumber(cmd.PlayerCooldown)
				local serverCooldown = tonumber(cmd.ServerCooldown)
				local crossCooldown = tonumber(cmd.CrossCooldown)

				local cmdFullName = cmd._fullName or (function()
					local aliases = cmd.Aliases or cmd.Commands or {}
					cmd._fullName = `{cmd.Prefix}{aliases[1] or `{service.HttpService:GenerateGUID(false)}-RANDOM_COMMAND`}`
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
				cmd._fullName = `{cmd.Prefix}{aliases[1] or `{service.HttpService:GenerateGUID(false)}-RANDOM_COMMAND`}`
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

			for ind, cmd in Commands do
				if checkPerm(pDat, cmd, true) then
					tab[ind] = cmd
				end
			end

			return tab
		end;

		CheckAuthority = function(p, target, actionName, allowSelf)
			if p == target then
				if allowSelf == false then
					Functions.Hint(`You cannot {actionName} yourself`, {p})
					return false
				end

				return allowSelf or Remote.GetGui(p, "YesNoPrompt", {
					Question = `Are you sure you want to {actionName} yourself?`;
				}) == "Yes"

			elseif Admin.GetLevel(p) > Admin.GetLevel(target) then
				return true
			end

			Functions.Hint(`You don't have permission to {actionName} {service.FormatPlayer(target)}`, {p})
			return false
		end;

		GetAliases = function(player)
			local aliases = table.clone(Variables.Aliases)
			local pData = player and Core.GetPlayer(player)

			if pData and pData.Aliases then
				for alias, command in pData.Aliases do
					aliases[alias] = command
				end
			end

			return aliases
		end;
	}
end
