server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Admin
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings, Commands
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

		service.TrackTask("Thread: ChatServiceHandler", function()
			--// ChatService mute handler (credit to Coasterteam)
			local chatService = Functions.GetChatService();

			if chatService then
				chatService:RegisterProcessCommandsFunction("ADONIS_CMD", function(speakerName, message, channelName)
					if server.Admin.DoHideChatCmd(service.Players:FindFirstChild(speakerName), message) then
						return true
					end

					return false
				end);

				chatService:RegisterProcessCommandsFunction("AdonisMuteServer", function(speakerName, message, channelName)
					local slowCache = Admin.SlowCache;
					local speaker = chatService:GetSpeaker(speakerName)
					local player = speaker:GetPlayer()
					if player and Admin.IsMuted(player) then
						speaker:SendSystemMessage("You are muted!", channelName)
						return true
					elseif player and Admin.SlowMode and not Admin.CheckAdmin(player) and slowCache[player] and os.time() - slowCache[player] < Admin.SlowMode then
						speaker:SendSystemMessage("Slow mode enabled! (".. Admin.SlowMode - (os.time() - slowCache[player]) .."s)" , channelName)
						return true
					end

					if Admin.SlowMode then
						slowCache[player] = os.time()
					end

					return false
				end)

				Logs:AddLog("Script", "ChatService Handler Loaded")
			else
				warn("Place is missing ChatService; Vanilla Roblox chat related features may not work")
				Logs:AddLog("Script", "ChatService Handler Not Found")
			end
		end)

		--// Make sure the default ranks are always present for compatability with existing commands
		for rank,data in next,server.Defaults.Settings.Ranks do
			if not server.Settings.Ranks[rank] then
				server.Settings.Ranks[rank] = data;
			end
		end

		--// Old setting backwards compatability
		if Settings.Owners then
			Settings.Ranks.HeadAdmins.Users = Settings.Owners;
		end

		if Settings.HeadAdmins then
			Settings.Ranks.HeadAdmins.Users = Settings.HeadAdmins;
		end

		if Settings.Admins then
			Settings.Ranks.Admins.Users = Settings.HeadAdmins;
		end

		if Settings.Moderators then
			Settings.Ranks.Moderators.Users = Settings.Moderators;
		end

		if Settings.CustomRanks then
			for name,users in next,Settings.CustomRanks do
				if not Settings.Ranks[name] then
					Settings.Ranks[name] = {
						Level = 1;
						Users = users;
					};
				end
			end
		end

		Admin.Init = nil;
		Logs:AddLog("Script", "Admin Module Initialized")
	end;

	local function RunAfterPlugins(data)
		--// Backup Map
		if Settings.AutoBackup then
			service.TrackTask("Thread: Initial Map Backup", Admin.RunCommand, Settings.Prefix.."backupmap")
		end

		--// Run OnStartup Commands
		for i,v in next,Settings.OnStartup do
			server.Threading.NewThread(Admin.RunCommand, v)
			Logs:AddLog("Script",{
				Text = "Startup: Executed "..tostring(v);
				Desc = "Executed startup command; "..tostring(v)
			})
		end

		--// Check if Shutdownlogs is set and if not then set it
		if Core.DataStore and not Core.GetData("ShutdownLogs") then
			Core.SetData("ShutdownLogs", {})
		end

		Admin.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Admin Module RunAfterPlugins Finished");
	end

	service.MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		if Variables and player.Parent and id == 1348327 and purchased then
			Variables.CachedDonors[tostring(player.UserId)] = os.time()
		end
	end)

	local function FormatAliasArgs(alias, aliasCmd, msg)
		local uniqueArgs = {}
		local argTab = {}
		local numArgs = 0;

		--local cmdArgs =
		for arg in aliasCmd:gmatch("<(%S+)>") do
			if arg ~= "" and arg ~= " " then
				local arg = "<".. arg ..">"
				if not uniqueArgs[arg] then --// Get only unique placeholder args, repeats will be matched to the same arg pos
					numArgs = numArgs+1;
					uniqueArgs[arg] = true; --// :cmd <arg1> <arg2>
					table.insert(argTab, arg)
				end
			end
		end

		local suppliedArgs = Admin.GetArgs(msg, numArgs) -- User supplied args (when running :alias arg)
		local out = aliasCmd;

		for i,argType in next,argTab do
			local replaceWith = suppliedArgs[i]
			if replaceWith then
				out = out:gsub(argType, replaceWith)
			end
		end

		return out;
	end

	server.Admin = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		PrefixCache = {};
		CommandCache = {};
		SpecialLevels = {};
		GroupRanks = {};
		TempAdmins = {};
		SlowCache = {};
		UserIdCache = {};
		BlankPrefix = false;

		DoHideChatCmd = function(p, message, data)
			local pData = data or Core.GetPlayer(p);
			if pData.Client.HideChatCommands
					and (message:sub(1,1) == Settings.Prefix or message:sub(1,1) == Settings.PlayerPrefix)
					and message:sub(2,2) ~= message:sub(1,1) then
				return true;
			end
		end;

		GetTrueRank = function(p, group)
			local localRank = Remote.LoadCode(p, [[return service.Player:GetRankInGroup(]]..group..[[)]], true)
			if localRank and localRank > 0 then
				return localRank
			end
		end;

		GetPlayerGroup = function(p, group)
			local data = Core.GetPlayer(p)
			local groups = data.Groups
			local isID = type(group) == "number"
			if groups then
				for i,v in next,groups do
					if (isID and group == v.Id) or (not isID and group == v.Name) then
						return v
					end
				end
			end
		end;

		IsMuted = function(player)
			for _,v in next,Settings.Muted do
				if Admin.DoCheck(player, v) then
					return true
				end
			end

			for _,v in next,HTTP.Trello.Mutes do
				if Admin.DoCheck(player, v) then
					return true
				end
			end

			if HTTP.WebPanel.Mutes then
				for _,v in next,HTTP.WebPanel.Mutes do
					if Admin.DoCheck(player, v) then
						return true
					end
				end
			end
		end;

		DoCheck = function(p, check)
			local pType = type(p)
			local cType = type(check)
			if pType == "string" and cType == "string" then
				if p == check or check:lower():sub(1,#tostring(p)) == p:lower() then
					return true
				end
			elseif pType == "number" and (cType == "number" or tonumber(check)) then
				if p == tonumber(check) then
					return true
				end
			elseif cType == "number" then
				if p.userId == check then
					return true
				end
			elseif cType == "string" and pType == "userdata" and p:IsA("Player") then
				local isGood = p and p.Parent == service.Players
				if isGood and check:match("^Group:(.*):(.*)") then
					local sGroup,sRank = check:match("^Group:(.*):(.*)")
					local group,rank = tonumber(sGroup),tonumber(sRank)
					if group and rank then
						local pGroup = Admin.GetPlayerGroup(p, group)
						if pGroup then
							local pRank = pGroup.Rank
							if pRank == rank or (rank < 0 and pRank >= math.abs(rank)) then
								return true
							end
						end
					end
				elseif isGood and check:sub(1, 6) == "Group:" then --check:match("^Group:(.*)") then
					local group = tonumber(check:match("^Group:(.*)"))
					if group then
						local pGroup = Admin.GetPlayerGroup(p, group)
						if pGroup then
							return true
						end
					end
				elseif isGood and check:sub(1, 5) == "Item:" then --check:match("^Item:(.*)") then
					local item = tonumber(check:match("^Item:(.*)"))
					if item then
						if service.MarketPlace:PlayerOwnsAsset(p, item) then
							return true
						end
					end
				elseif p and check:sub(1, 9) == "GamePass:" then --check:match("^GamePass:(.*)") then
					local item = tonumber(check:match("^GamePass:(.*)"))
					if item then
						if service.MarketPlace:UserOwnsGamePassAsync(p.UserId, item) then
							return true
						end
					end
				elseif check:match("^(.*):(.*)") then
					local player, sUserid = check:match("^(.*):(.*)")
					local userid = tonumber(sUserid)
					if player and userid and p.Name == player or p.userId == userid then
						return true
					end
				elseif p.Name == check then
					return true
				elseif type(check) == "string" then
					local cache = Admin.UserIdCache[check]

					if cache and p.UserId == cache then
						return true
					elseif cache==false then
						return
					end

					local suc,userId = pcall(function() return service.Players:GetUserIdFromNameAsync(check) end)

					if suc and userId then
						Admin.UserIdCache[check] = userId

						if p.UserId == userId then
							return true
						end
					elseif not suc then
						Admin.UserIdCache[check] = false
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

		UpdateCachedLevel = function(p)
			local data = Core.GetPlayer(p)
			data.Groups = service.GroupService:GetGroupsAsync(p.UserId) or {}
			data.AdminLevel = Admin.GetUpdatedLevel(p)
			data.LastLevelUpdate = tick()
			Logs.AddLog("Script", {
				Text = "Updating cached level for ".. tostring(p);
				Desc = "Updating the cached admin level for ".. tostring(p);
				Player = p;
			})
			return data.AdminLevel
		end;

		LevelToList = function(lvl)
			local lvl = tonumber(lvl);
			if not lvl then return nil end;
			for i,v in next,Settings.Ranks do
				if lvl == v.Level then
					return v.Users, i, v;
				end
			end
		end;

		LevelToListName = function(lvl)
			if lvl > 999 then return "Place Owner" end
			for i,v in next,Settings.Ranks do
				if v.Level == lvl then
					return i
				end
			end
		end;

		GetLevel = function(p)
			local data = Core.GetPlayer(p)
			local level = data.AdminLevel
			local lastUpdate = data.LastLevelUpdate
			local clients = Remote.Clients

			if clients[tostring(p.UserId)] and not level or not lastUpdate or tick()-lastUpdate > 60 then
				Admin.UpdateCachedLevel(p)
				if level and data.AdminLevel and type(p) == "userdata" and p:IsA("Player") then
					if data.AdminLevel < level then
						Functions.Hint("Your admin level has been reduced to ".. data.AdminLevel .." ["..Admin.LevelToListName(data.AdminLevel) or "Unknown".."]", {p})
					elseif data.AdminLevel > level then
						Functions.Hint("Your admin level has been increased to ".. data.AdminLevel .." ["..Admin.LevelToListName(data.AdminLevel) or "Unknown".."]", {p})
					end
				end
			end

			return data.AdminLevel or 0
		end;

		GetUpdatedLevel = function(p)
			local checkTable = Admin.CheckTable
			local doCheck = Admin.DoCheck

			if Admin.IsPlaceOwner(p) then
				return 1000
			end

			for ind,admin in next,Admin.SpecialLevels do
				if doCheck(p,admin.Player) then
					return admin.Level
				end
			end

			local highest = 0
			for rank,data in next,Settings.Ranks do
				if data.Level > highest then
					for i,v in ipairs(data.Users) do
						if doCheck(p, v) then
							highest = data.Level;
							break;
						end
					end
				end
			end

			return highest
		end;

		IsPlaceOwner = function(p)
			if type(p) == "userdata" and p:IsA("Player") then
				if Settings.CreatorPowers then
					for ind,id in next,{1237666,76328606,698712377} do  --// These are my accounts; Lately I've been using my game dev account(698712377) more so I'm adding it so I can debug without having to sign out and back in (it's really a pain)
						if p.userId == id then							--// Disable CreatorPowers in settings if you don't trust me. It's not like I lose or gain anything either way. Just re-enable it BEFORE telling me there's an issue with the script so I can go to your place and test it.
							return true
						end
					end
				end

				if game.CreatorType == Enum.CreatorType.User then
					if p.userId == game.CreatorId then
						return true
					end
				else
					local group = Admin.GetPlayerGroup(p, game.CreatorId)
					if p and p.Parent == service.Players and group and group.Rank == 255 then-- p:GetRankInGroup(game.CreatorId) == 255 then
						return true
					end
				end

				if p.userId == -1 then
					return true
				end
			end
		end;

		CheckAdmin = function(p)
			local level = Admin.GetLevel(p)
			if level > 0 then
				return true
			else
				return false
			end
		end;

		SetLevel = function(p, level)
			local current = Admin.GetLevel(p)
			local list = Admin.LevelToList(current)

			if tonumber(level) then
				if current >= 999 then
					return false
				else
					Admin.SpecialLevels[tostring(p.userId)] = {Player = p.userId, Level = level}
				end
			elseif level == "Reset" then
				Admin.SpecialLevels[tostring(p.userId)] = nil
			end
			Admin.UpdateCachedLevel(p)
		end;

		IsTempAdmin = function(p)
			for i,v in next,Admin.TempAdmins do
				if Admin.DoCheck(p,v) then
					return true,i
				end
			end
		end;

		RemoveAdmin = function(p,temp,override)
			local current = Admin.GetLevel(p)
			local list, listName, listData = Admin.LevelToList(current)
			local isTemp,tempInd = Admin.IsTempAdmin(p)

			if isTemp then
				temp = true
				table.remove(Admin.TempAdmins,tempInd)
			end

			if override then
				temp = false
			end

			if type(p) == "userdata" then
				Admin.SetLevel(p,0)
			end
			if list then
				for ind,check in ipairs(list) do
					if Admin.DoCheck(p, check) and not (type(check) == "string" and (check:match("^Group:") or check:match("^Item:"))) then
						table.remove(list, ind)

						if not temp and Settings.SaveAdmins then
							Core.DoSave({
								Type = "TableRemove";
								Table = {"Settings", "Ranks", listName, "Users"};
								Value = check;
							});
						end
					end
				end
			end
			Admin.UpdateCachedLevel(p)
		end;

		AddAdmin = function(p, level, temp)
			local current = Admin.GetLevel(p)
			local list = Admin.LevelToList(current)

			if type(level) == "string" then
				level = Admin.StringToComLevel(level) or level;
			end

			Admin.RemoveAdmin(p, temp)
			Admin.SetLevel(p, level)

			if temp then
				table.insert(Admin.TempAdmins,p)
			end

			if list and type(list) == "table" then
				local index,value

				for ind,ent in ipairs(list) do
					if (type(ent)=="number" or type(ent)=="string") and (ent==p.userId or ent:lower()==p.Name:lower() or ent:lower()==(p.Name..":"..p.userId):lower()) then
						index = ind
						value = ent
					end
				end

				if index and value then
					table.remove(list, index)
				end
			end

			local value = p.Name..":"..p.userId
			local newList,newListName = Admin.LevelToList(level);

			if newList then
				table.insert(newList,value)

				if Settings.SaveAdmins and not temp then
					Core.DoSave({
						Type = "TableAdd";
						Table = {"Settings", "Ranks", newListName, "Users"};
						Value = value
					})
				end
			end

			Admin.UpdateCachedLevel(p)
		end;

		CheckDonor = function(p)
			--if not Settings.DonorPerks then return false end
			local key = tostring(p.userId)
			if Variables.CachedDonors[key] then
				return true
			else
				--if p.userId<0 or (tonumber(p.AccountAge) and tonumber(p.AccountAge)<0) then return false end
				for ind,pass in next,Variables.DonorPass do
					local ran, ret;
					if type(pass) == "number" then
						ran,ret = pcall(function() return service.MarketPlace:UserOwnsGamePassAsync(p.UserId, pass) end)
					elseif type(pass) == "string" and tonumber(pass) then
						ran,ret = pcall(function() return service.MarketPlace:PlayerOwnsAsset(p, tonumber(pass)) end)
					end

					if ran and ret then
						Variables.CachedDonors[key] = os.time()
						return true
					end
				end
			end
		end;

		CheckBan = function(p)
			local doCheck = Admin.DoCheck
			local banCheck = Admin.DoBanCheck
			for ind,admin in next,Settings.Banned do
				if doCheck(p, admin) or banCheck(p, admin) or (type(admin) == "table" and (doCheck(p, admin.Name) or doCheck(p, admin.UserId))) then
					return true, (type(admin) == "table" and admin.Reason)
				end
			end

			for ind,ban in next,Core.Variables.TimeBans do
				if (p.UserId == ban.UserId) then
					if ban.EndTime-os.time() <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						return true, ban.Reason;
					end
				end
			end

			for ind,admin in next,HTTP.Trello.Bans do
				if doCheck(p, admin) or banCheck(p, admin) then
					return true, (type(admin) == "table" and admin.Reason)
				end
			end

			if HTTP.WebPanel.Bans then
				for ind,admin in next,HTTP.WebPanel.Bans do
					if doCheck(p,admin) or banCheck(p, admin) then
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

				Core.CrossServer("Loadstring", [[
					local player = game:GetService("Players"):FindFirstChild("]]..p.Name..[[")
					if player then
						player:Kick("]]..Variables.BanMessage..[[ | Reason: ]]..(value.Reason or "No reason provided")..[[")
					end
				]])
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
					if type(name) == "string" and check.Name and check.Name:lower() == name:lower() then
						return true;
					elseif id and check.UserId and check.UserId == id then
						return true;
					end
			elseif type(check) == "string" then
				local cName,cId = check:match("(.*):(.*)") or check;

				if cName then
					if cName:lower() == name:lower() then
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
			for i,v in next,Settings.Banned do
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

		RunCommand = function(coma,...)
			local ind,com = Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma,#cmdArgs,...)
				--local task,ran,error = service.Threads.TimeoutRunTask("SERVER_COMMAND: "..coma,com.Function,60*5,false,args)
				local ran, error = service.TrackTask("Command: ".. tostring(coma), com.Function, false, args)
				if error then
					--logError("SERVER","Command",error)
				end
			end
		end;

		RunCommandAsPlayer = function(coma,plr,...)
			local ind,com = Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma,#cmdArgs,...)
				local adminLvl = Admin.GetLevel(plr)
				local ran, error = service.TrackTask(tostring(plr) ..": ".. coma, com.Function, plr, args, {PlayerData = {
					Player = plr;
					Level = adminLvl;
					isAgent = HTTP.Trello.CheckAgent(plr) or false;
					isDonor = (Admin.CheckDonor(plr) and (Settings.DonorCommands or com.AllowDonors)) or false;
				}})
				--local task,ran,error = service.Threads.TimeoutRunTask("COMMAND:"..tostring(plr)..": "..coma,com.Function,60*5,plr,args)
				if error then
					--logError(plr,"Command",error)
					error = error:match(":(.+)$") or "Unknown error"
					Remote.MakeGui(plr,'Output',{Title = ''; Message = error; Color = Color3.new(1,0,0)})
				end
			end
		end;

		RunCommandAsNonAdmin = function(coma,plr,...)
			local ind,com = Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = Admin.GetArgs(coma,#cmdArgs,...)
				local ran, error = service.TrackTask(tostring(plr) ..": ".. coma, com.Function, plr, args, {PlayerData = {
					Player = plr;
					Level = 0;
					isAgent = false;
					isDonor = false;
				}})
				if error then
					error = error:match(":(.+)$") or "Unknown error"
					Remote.MakeGui(plr,'Output',{Title = ''; Message = error; Color = Color3.new(1,0,0)})
				end
			end
		end;


		CacheCommands = function()
			local tempTable = {}
			local tempPrefix = {}
			for ind,data in next,Commands do
				if type(data) == "table" then
					for i,cmd in next,data.Commands do
						if data.Prefix == "" then Variables.BlankPrefix = true end
						tempPrefix[data.Prefix] = true
						tempTable[(data.Prefix..cmd):lower()] = ind
					end
				end
			end

			Admin.PrefixCache = tempPrefix
			Admin.CommandCache = tempTable
		end;

		GetCommand = function(Command)
			if Admin.PrefixCache[Command:sub(1,1)] or Variables.BlankPrefix then
				local matched
				if Command:find(Settings.SplitKey) then
					matched = Command:match("^(%S+)"..Settings.SplitKey)
				else
					matched = Command:match("^(%S+)")
				end

				if matched then
					local found = Admin.CommandCache[matched:lower()]
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
			local prefixChar = string.sub(Command, 1, 1);
			local checkPrefix = Admin.PrefixCache[prefixChar] and prefixChar;
			local matched
			if Command:find(Settings.SplitKey) then
				matched = Command:match("^(%S+)"..Settings.SplitKey)
			else
				matched = Command:match("^(%S+)")
			end

			if matched then
				local foundCmds = {};
				matched = string.lower(matched);

				for ind,cmd in next,Commands do
					if type(cmd) == "table" and ((checkPrefix and prefixChar == cmd.Prefix) or not checkPrefix) then
						for _,alias in pairs(cmd.Commands) do
							if string.lower(alias) == matched then
								foundCmds[ind] = cmd;
								break;
							end
						end
					end
				end

				return foundCmds;
			end
		end;

		SetPermission = function(comString, newLevel)
			local cmds = Admin.FindCommands(comString)
			if cmds then
				for ind,cmd in next,cmds do
					cmd.AdminLevel = newLevel;
				end
			end
		end;

		FormatCommand = function(command)
			local text = command.Prefix..command.Commands[1]
			local cmdArgs = command.Args or command.Arguments
			local splitter = Settings.SplitKey

			for ind,arg in next,cmdArgs do
				text = text..splitter.."<"..arg..">"
			end

			return text
		end;

		CheckTable = function(p,tab)
			local doCheck = Admin.DoCheck
			for i,v in next,tab do
				if doCheck(p,v) then
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

		GetArgs = function(msg,num,...)
			local args = Functions.Split((msg:match("^.-"..Settings.SplitKey..'(.+)') or ''),Settings.SplitKey,num) or {}
			for i,v in next,{...} do table.insert(args,v) end
			return args
		end;

		AliasFormat = function(aliases, msg)
			if aliases then
				for alias,cmd in next,aliases do
					if not Admin.CheckAliasBlacklist(alias) then
						if msg:match("^"..alias) or msg:match("%s".. alias) then
							msg = FormatAliasArgs(alias, cmd, msg);
						end
					end
				end
			end

			return msg
		end;

		IsComLevel = function(testLevel, comLevel)
			--print("Checking", tostring(testLevel), tostring(comLevel))
			if testLevel == comLevel then
				return true
			elseif type(testLevel) == "table" then
				for i,v in next,testLevel do
					if i == comLevel or v == comLevel or (type(i) == "string" and type(comLevel) == "string" and i:lower() == comLevel:lower()) then
						--	print("One Match")
						return i,v
					elseif type(comLevel) == "table" then
						for k,m in ipairs(comLevel) do
							if i == m or v == m or (type(i) == "string" and type(m) == "string" and i:lower() == m:lower()) then
								--print("Found a match")
								return i,v
							end
						end
					end
				end
			elseif type(comLevel) == "string" then
				return testLevel:lower() == comLevel:lower()
			elseif type(comLevel) == "table" then
				for i,v in ipairs(comLevel) do
					if testLevel:lower() == v:lower() then
						return true
					end
				end
			end

			--print("No Match")
		end;

		StringToComLevel = function(str)
			if type(str) == "number" then return str end;
			if string.lower(str) == "players" then return 0 end;

			local lvl = Settings.Ranks[str];
			return (lvl and lvl.Level) or tonumber(str);
		end;

		CheckComLevel = function(plrAdminLevel, comLevel)
			if type(comLevel) == "string" then
				comLevel = Admin.StringToComLevel(comLevel);
			end

			if type(comLevel) == "number" and plrAdminLevel >= comLevel then
				return true;
			elseif type(comLevel) == "table" then
				for i,level in next, comLevel do
					if plrAdminLevel == level then
						return true;
					end
				end
			end
		end;

		IsBlacklisted = function(p)
			for i,list in next,Variables.Blacklist.Lists do
				if Admin.CheckTable(p, list) then
					return true
				end
			end
		end;

		CheckPermission = function(pDat, cmd)
			local allowed = false
			local p = pDat.Player
			local adminLevel = pDat.Level
			local isAgent = pDat.isAgent
			local isDonor = (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors))
			local comLevel = cmd.AdminLevel
			local funAllowed = Settings.FunCommands
			local isComLevel = Admin.IsComLevel

			if adminLevel >= 999 then
				return true
			elseif cmd.Fun and not funAllowed then
				return false
			elseif cmd.Donors and isDonor then
				return true
			elseif cmd.Agents and isAgent then
				return true
			elseif comLevel == 0 and Settings.PlayerCommands then
				return true
			elseif Admin.CheckComLevel(adminLevel, comLevel) then
				return true
			end

			return false
		end;

		SearchCommands = function(p,search)
			local checkPerm = Admin.CheckPermission
			local tab = {}
			local pDat = {
				Player = p;
				Level = Admin.GetLevel(p);
				isAgent = HTTP.Trello.CheckAgent(p);
				isDonor = Admin.CheckDonor(p);
			}

			for index,command in next,Commands do
				if checkPerm(pDat, command) then
					tab[index] = command
				end
			end

			return tab
		end;
	};
end
