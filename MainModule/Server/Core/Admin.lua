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

		--// Cache Commands
		Admin.CacheCommands()
		
		service.TrackTask("Thread: ChatServiceHandler", function()
			--// ChatService mute handler (credit to Coasterteam)
			local ChatService = require(service.ServerScriptService:WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))

			ChatService:RegisterProcessCommandsFunction("AdonisMuteServer", function(speakerName, message, channelName)
				local slowCache = Admin.SlowCache;
				local speaker = ChatService:GetSpeaker(speakerName)
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
		end)
		
		Logs:AddLog("Script", "Admin Module Initialized")
	end;

	service.MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		if Variables and player.Parent and id == 1348327 and purchased then
			Variables.CachedDonors[tostring(player.UserId)] = tick()
		end
	end)

	server.Admin = {
		Init = Init;
		PrefixCache = {};
		CommandCache = {};
		SpecialLevels = {};
		GroupRanks = {};
		TempAdmins = {};
		SlowCache = {};
		BlankPrefix = false;

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
			for _,v in next,server.Settings.Muted do
				if server.Admin.DoCheck(player, v) then
					return true
				end
			end

			for _,v in next,server.HTTP.Trello.Mutes do
				if server.Admin.DoCheck(player, v) then
					return true
				end
			end
			
			if HTTP.WebPanel.Mutes then
				for _,v in next,server.HTTP.WebPanel.Mutes do
					if server.Admin.DoCheck(player, v) then
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
			return ({
				[1] = Settings.Moderators;
				[2] = Settings.Admins;
				[3] = Settings.Owners;
				[4] = Settings.Creators;
			})[lvl]
		end;

		LevelToListName = function(lvl)
			return ({
				[0] = "Players";
				[1] = "Moderators";
				[2] = "Admins";
				[3] = "Owners";
				[4] = "Creators";
			})[lvl]
		end;

		GetLevel = function(p)
			local data = Core.GetPlayer(p)
			local level = data.AdminLevel
			local lastUpdate = data.LastLevelUpdate
			local clients = Remote.Clients

			if clients[tostring(p.userId)] and not level or not lastUpdate or tick()-lastUpdate > 60 then
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
				return 5
			end

			for ind,admin in next,Admin.SpecialLevels do
				if doCheck(p,admin.Player) then
					return admin.Level
				end
			end

			local levels = {
				{ --// Blacklist
					Level = 0;
					Tables = {
						Settings.Blacklist;
						HTTP.Trello.Blacklist;
						HTTP.WebPanel.Blacklist;
					};
				};
				--[[
				{ --// Banlist
					Level = -1;
					Tables = {
						Settings.Banned;
						HTTP.Trello.Bans;
					}
				};
				--]]
				{ --// Creators
					Level = 4;
					Tables = {
						Settings.Creators;
						HTTP.Trello.Creators;
						HTTP.WebPanel.Creators;
					}
				};

				{ --// Owners
					Level = 3;
					Tables = {
						Settings.Owners;
						HTTP.Trello.Owners;
						HTTP.WebPanel.Owners;
					}
				};

				{ --// Admins
					Level = 2;
					Tables = {
						Settings.Admins;
						HTTP.Trello.Admins;
						HTTP.WebPanel.Admins;
					}
				};

				{ --//Moderators
					Level = 1;
					Tables = {
						Settings.Moderators;
						HTTP.Trello.Moderators;
						HTTP.WebPanel.Moderators;
					}
				};
			}

			for i = 1,#levels do --service.CountTable(levels) do
				local level = levels[i]
				if level then
					for ind,tab in next,level.Tables do
						if checkTable(p,tab) then
							return level.Level
						end
					end
				end
			end

			for i,v in next,Settings.CustomRanks do
				if checkTable(p, v) then
					return 0.5
				end
			end

			return 0
		end;

		IsPlaceOwner = function(p)
			if type(p) == "userdata" and p:IsA("Player") then
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

				if Core.DebugMode and p.userId == -1 then 
					return true
				end

				if Settings.CreatorPowers then
					for ind,id in next,{1237666,76328606,698712377} do  --// These are my accounts; Lately I've been using my game dev account(698712377) more so I'm adding it so I can debug without having to sign out and back in (it's really a pain)
						if p.userId == id then							--// Disable CreatorPowers in settings if you don't trust me. It's not like I lose or gain anything either way. Just re-enable it BEFORE telling me there's an issue with the script so I can go to your place and test it.
							return true
						end
					end
				end
			end
		end;

		CheckAdmin = function(p)
			local level = Admin.GetLevel(p)
			if level>0 then
				return true
			else
				return false
			end
		end;

		SetLevel = function(p,level)
			local current = Admin.GetLevel(p)
			local list = Admin.LevelToList(current)
			if tonumber(level) then 
				if current>4 then
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
			local list = Admin.LevelToList(current)
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

			local function doRemove(level,check)
				if level == 1 then
					Core.DoSave({
						Type = "TableRemove";
						Table = "Moderators";
						Value = check;
					})
				elseif level == 2 then
					if Settings.SaveAdmins then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Admins";
							Value = check;
						})
					end
				elseif level == 3 then
					if Settings.SaveAdmins then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Owners";
							Value = check;
						})		
					end					
				elseif level == 4 then
					if Settings.SaveAdmins then
						Core.DoSave({
							Type = "TableRemove";
							Table = "Creators";
							Value = check;
						})
					end
				end
			end

			local function removeFromTable(list,level)
				for ind,check in pairs(list) do
					if Admin.DoCheck(p,check) and not (type(check) == "string" and (check:match("^Group:") or check:match("^Item:"))) then
						table.remove(list,ind)
						if not temp and Settings.SaveAdmins then
							doRemove(level,check)
						end
					end
				end
			end

			removeFromTable(Settings.Moderators,1)
			removeFromTable(Settings.Admins,2)
			removeFromTable(Settings.Owners,3)
			removeFromTable(Settings.Creators,4)
			Admin.UpdateCachedLevel(p)
		end;

		AddAdmin = function(p,level,temp)
			local current = Admin.GetLevel(p)
			local list = Admin.LevelToList(current)

			Admin.RemoveAdmin(p,temp)
			Admin.SetLevel(p,level)
			if temp then table.insert(Admin.TempAdmins,p) end

			if list and type(list)=="table" then 
				local index,value
				for ind,ent in pairs(list) do
					if (type(ent)=="number" or type(ent)=="string") and (ent==p.userId or ent:lower()==p.Name:lower() or ent:lower()==(p.Name..":"..p.userId):lower()) then
						index = ind
						value = ent
					end
				end
				if index and value then
					table.remove(list,index)
				end
			end

			local value = p.Name..":"..p.userId
			if level == 1 then
				table.insert(Settings.Moderators,value)
				if Settings.SaveAdmins and not temp then
					Core.DoSave({
						Type = "TableAdd";
						Table = "Moderators";
						Value = value
					})
				end
			elseif level == 2 then
				table.insert(Settings.Admins,value)
				if Settings.SaveAdmins and not temp then
					Core.DoSave({
						Type = "TableAdd";
						Table = "Admins";
						Value = value
					})
				end
			elseif level == 3 then
				table.insert(Settings.Owners,value)
				if Settings.SaveAdmins and not temp then
					Core.DoSave({
						Type = "TableAdd";
						Table = "Owners";
						Value = value
					})
				end
			elseif level == 4 then
				table.insert(Settings.Creators,value)
				if Settings.SaveAdmins and not temp then
					Core.DoSave({
						Type = "TableAdd";
						Table = "Creators";
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
				if p.userId<0 or (tonumber(p.AccountAge) and tonumber(p.AccountAge)<0) then return false end
				for ind,pass in next,Variables.DonorPass do
					local ran,ret = pcall(function() return service.MarketPlace:UserOwnsGamePassAsync(p.UserId, pass) end)
					if ran and ret then
						Variables.CachedDonors[key] = os.time()
						return true
					end
				end
				--[[
				for ind,old in pairs(Variables.OldDonorList) do
					if p.Name==old.Name or p.userId==old.Id then
						Variables.CachedDonors[key] = tick()
						return true
					end
				end
				--]]
			end
		end;

		CheckBan = function(p)
			local doCheck = Admin.DoCheck
			for ind,admin in next,Settings.Banned do
				if doCheck(p,admin) then
					return true
				end
			end

			for ind,ban in next,Core.Variables.TimeBans do
				if (p.UserId == ban.UserId) then
					if ban.EndTime-os.time() <= 0 then
						table.remove(Core.Variables.TimeBans, ind)
					else
						return true
					end
				end
			end

			for ind,admin in next,HTTP.Trello.Bans do
				if doCheck(p,admin) then
					return true
				end
			end
			
			if HTTP.WebPanel.Bans then
				for ind,admin in next,HTTP.WebPanel.Bans do
					if doCheck(p,admin) then
						return true
					end
				end
			end
		end;

		AddBan = function(p, doSave)
			table.insert(Settings.Banned, p.Name..':'..p.userId) 
			if doSave then
				Core.DoSave({
					Type = "TableAdd";
					Table = "Banned";
					Value = p.Name..':'..p.UserId;
				})
			end
			if not service.Players:FindFirstChild(p.Name) then
				Remote.Send(p,'Function','KillClient')
			else
				if p then pcall(function() p:Kick("You have been banned") end) end
			end
		end;

		RemoveBan = function(name, doSave)
			local ret
			for i,v in next,Settings.Banned do
				if tostring(v):lower():sub(1,#name) == name:lower() or name:lower()=="all" then
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

		SetPermission = function(cmd,newLevel)
			local index,command = Admin.GetCommand(cmd)
			if command and newLevel then 
				command.AdminLevel = newLevel
			end
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
					isAgent = HTTP.Trello.CheckAgent(p) or false;
					isDonor = (Admin.CheckDonor(p) and (Settings.DonorCommands or command.AllowDonors)) or false;
				}})
				--local task,ran,error = service.Threads.TimeoutRunTask("COMMAND:"..tostring(plr)..": "..coma,com.Function,60*5,plr,args)
				if error then 
					--logError(plr,"Command",error) 
					error = error:match(":(.+)$") or "Unknown error"
					Remote.MakeGui(plr,'Output',{Title = ''; Message = error; Color = Color3.new(1,0,0)})  
				end
			end
		end;

		GetArgs = function(msg,num,...)
			local args = Functions.Split((msg:match("^.-"..Settings.SplitKey..'(.+)') or ''),Settings.SplitKey,num) or {}
			for i,v in next,{...} do table.insert(args,v) end
			return args
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

		CheckPermission = function(pDat,cmd)
			local allowed = false
			local p = pDat.Player
			local adminLevel = pDat.Level
			local isAgent = pDat.isAgent
			local isDonor = (pDat.isDonor and (Settings.DonorCommands or cmd.AllowDonors))
			local comLevel = cmd.AdminLevel
			local funAllowed = Settings.FunCommands
			local isComLevel = Admin.IsComLevel

			if adminLevel >= 4 then
				return true
			elseif cmd.Fun and not (funAllowed or adminLevel >= 4) then
				return false
			elseif cmd.Agents and isAgent then
				return true
			elseif Core.PanicMode and adminLevel >= 1 and (comLevel == "Helper" or comLevel == "Moderator" or comLevel == "Admin") then
				return true
			elseif (Settings.PlayerCommands or adminLevel >= 1) and isComLevel("Players", comLevel) then
				return true
			elseif isDonor and isComLevel("Donors", comLevel)then
				return true
			elseif adminLevel >= 1 and isComLevel("Moderators", comLevel) then
				return true
			elseif adminLevel >= 2 and isComLevel("Admins", comLevel) then
				return true
			elseif adminLevel >= 3 and isComLevel("Owners", comLevel) then
				return true
			elseif adminLevel >= 4 and isComLevel("Creators", comLevel) then
				return true
			elseif adminLevel > 0 and (isComLevel(Settings.CustomRanks, comLevel) or (HTTP.WebPanel.CustomRanks and isComLevel(HTTP.WebPanel.CustomRanks, comLevel))) then
				if adminLevel >= 1 then
					return true
				else
					for i,v in next,Settings.CustomRanks do
						if isComLevel(i, comLevel) and Admin.CheckTable(p, v) then
							return true
						end
					end
					
					if HTTP.WebPanel.CustomRanks then
						for i,v in next,HTTP.WebPanel.CustomRanks do
							if isComLevel(i, comLevel) and Admin.CheckTable(p, v) then
								return true
							end
						end
					end
				end
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
