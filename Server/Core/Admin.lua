server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Admin
return function()
	server.Admin = {
		PrefixCache = {};
		CommandCache = {};
		SpecialLevels = {};
		GroupRanks = {};
		TempAdmins = {};
		BlankPrefix = false;
		
		GetTrueRank = function(p, group)
			local localRank = server.Remote.LoadCode(p, [[return service.Player:GetRankInGroup(]]..group..[[)]], true)
			if localRank and localRank > 0 then
				return localRank
			end
		end;
		
		GetPlayerGroup = function(p, group)
			local data = server.Core.GetPlayer(p)
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
				local isGood = p.Parent == service.Players
				if isGood and check:match("^Group:(.*):(.*)") then
					local sGroup,sRank = check:match("^Group:(.*):(.*)")
					local group,rank = tonumber(sGroup),tonumber(sRank)
					if group and rank then
						local pGroup = server.Admin.GetPlayerGroup(p, group)
						if pGroup then
							local pRank = pGroup.Rank
							if pRank == rank or (rank < 0 and pRank >= math.abs(rank)) then
								return true
							end
						end
					end
				elseif isGood and check:match("^Group:(.*)") then
					local group = tonumber(check:match("^Group:(.*)"))
					if group then
						local pGroup = server.Admin.GetPlayerGroup(p, group)
						if pGroup then
							return true
						end
					end
				elseif check:match("^Item:(.*)") then
					local item = tonumber(check:match("^Item:(.*)"))
					if item then
						if service.MarketPlace:PlayerOwnsAsset(p,item) then
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
			elseif cType == "table" and pType == "userdata" and p:IsA("Player") then
				if check.Group and check.Rank then
					local rank = check.Rank
					local pGroup = server.Admin.GetPlayerGroup(p, check.Group)
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
			local data = server.Core.GetPlayer(p)
			data.Groups = service.GroupService:GetGroupsAsync(p.UserId) or {}
			data.AdminLevel = server.Admin.GetUpdatedLevel(p)
			data.LastLevelUpdate = tick()
			server.Logs.AddLog("Script", {
				Text = "Updating cached level for ".. tostring(p);
				Desc = "Updating the cached admin level for ".. tostring(p);
			})
			return data.AdminLevel
		end;
		
		LevelToList = function(lvl)
			return ({
				[1] = server.Settings.Moderators;
				[2] = server.Settings.Admins;
				[3] = server.Settings.Owners;
				[4] = server.Settings.Creators;
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
			local data = server.Core.GetPlayer(p)
			local level = data.AdminLevel
			local lastUpdate = data.LastLevelUpdate
			local clients = server.Remote.Clients
			
			if clients[tostring(p.userId)] and not level or not lastUpdate or tick()-lastUpdate > 60 then
				server.Admin.UpdateCachedLevel(p)
				if level and data.AdminLevel and type(p) == "userdata" and p:IsA("Player") then
					if data.AdminLevel < level then
						server.Functions.Hint("Your admin level has been reduced to ".. data.AdminLevel .." ["..server.Admin.LevelToListName(data.AdminLevel) or "Unknown".."]", {p})
					elseif data.AdminLevel > level then
						server.Functions.Hint("Your admin level has been increased to ".. data.AdminLevel .." ["..server.Admin.LevelToListName(data.AdminLevel) or "Unknown".."]", {p})
					end
				end
			end
			
			return data.AdminLevel or 0
		end;
		
		GetUpdatedLevel = function(p)
			local checkTable = server.Admin.CheckTable
			local doCheck = server.Admin.DoCheck
			
			if server.Admin.IsPlaceOwner(p) then
				return 5
			end
			
			for ind,admin in next,server.Admin.SpecialLevels do
				if doCheck(p,admin.Player) then
					return admin.Level
				end
			end
			
			local levels = {
				{ --// Blacklist
					Level = 0;
					Tables = {
						server.Settings.Blacklist;
						server.HTTP.Trello.Blacklist;
					};
				};
				--[[
				{ --// Banlist
					Level = -1;
					Tables = {
						server.Settings.Banned;
						server.HTTP.Trello.Bans;
					}
				};
				--]]
				{ --// Creators
					Level = 4;
					Tables = {
						server.Settings.Creators;
						server.HTTP.Trello.Creators;
					}
				};
				
				{ --// Owners
					Level = 3;
					Tables = {
						server.Settings.Owners;
						server.HTTP.Trello.Owners;
					}
				};
				
				{ --// Admins
					Level = 2;
					Tables = {
						server.Settings.Admins;
						server.HTTP.Trello.Admins;
					}
				};
				
				{ --//Moderators
					Level = 1;
					Tables = {
						server.Settings.Moderators;
						server.HTTP.Trello.Moderators;
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
			
			return 0
		end;
		
		IsPlaceOwner = function(p)
			if type(p) == "userdata" and p:IsA("Player") then
				if game.CreatorType == Enum.CreatorType.User then
					if p.userId == game.CreatorId then 
						return true
					end
				else
					local group = server.Admin.GetPlayerGroup(p, game.CreatorId)
					if p and p.Parent == service.Players and group and group.Rank == 255 then-- p:GetRankInGroup(game.CreatorId) == 255 then
						return true
					end
				end
				
				if server.Core.DebugMode and p.userId == -1 then 
					return true
				end
				
				if server.Settings.CreatorPowers then
					for ind,id in next,{1237666,76328606} do
						if p.userId == id then
							return true
						end
					end
				end
			end
		end;
		
		CheckAdmin = function(p)
			local level = server.Admin.GetLevel(p)
			if level>0 then
				return true
			else
				return false
			end
		end;
		
		SetLevel = function(p,level)
			local current = server.Admin.GetLevel(p)
			local list = server.Admin.LevelToList(current)
			if tonumber(level) then 
				if current>4 then
					return false
				else
					server.Admin.SpecialLevels[tostring(p.userId)] = {Player = p.userId, Level = level}
				end
			elseif level == "Reset" then
				server.Admin.SpecialLevels[tostring(p.userId)] = nil
			end
			server.Admin.UpdateCachedLevel(p)
		end;
		
		IsTempAdmin = function(p)
			for i,v in next,server.Admin.TempAdmins do
				if server.Admin.DoCheck(p,v) then
					return true,i
				end
			end
		end;
		
		RemoveAdmin = function(p,temp,override)
			local current = server.Admin.GetLevel(p)
			local list = server.Admin.LevelToList(current)
			local isTemp,tempInd = server.Admin.IsTempAdmin(p)
			
			if isTemp then
				temp = true
				table.remove(server.Admin.TempAdmins,tempInd)
			end
			
			if override then
				temp = false
			end
			
			if type(p) == "userdata" then
				server.Admin.SetLevel(p,0)
			end
			
			local function doRemove(level,check)
				if level == 1 then
					server.Core.DoSave({
						Type = "TableRemove";
						Table = "Moderators";
						Value = check;
					})
				elseif level == 2 then
					if server.Settings.SaveAdmins then
						server.Core.DoSave({
							Type = "TableRemove";
							Table = "Admins";
							Value = check;
						})
					end
				elseif level == 3 then
					if server.Settings.SaveAdmins then
						server.Core.DoSave({
							Type = "TableRemove";
							Table = "Owners";
							Value = check;
						})		
					end					
				elseif level == 4 then
					if server.Settings.SaveAdmins then
						server.Core.DoSave({
							Type = "TableRemove";
							Table = "Creators";
							Value = check;
						})
					end
				end
			end
			
			local function removeFromTable(list,level)
				for ind,check in pairs(list) do
					if server.Admin.DoCheck(p,check) and not (type(check) == "string" and (check:match("^Group:") or check:match("^Item:"))) then
						table.remove(list,ind)
						if not temp and server.Settings.SaveAdmins then
							doRemove(level,check)
						end
					end
				end
			end
			
			removeFromTable(server.Settings.Moderators,1)
			removeFromTable(server.Settings.Admins,2)
			removeFromTable(server.Settings.Owners,3)
			removeFromTable(server.Settings.Creators,4)
			server.Admin.UpdateCachedLevel(p)
		end;

		AddAdmin = function(p,level,temp)
			local current = server.Admin.GetLevel(p)
			local list = server.Admin.LevelToList(current)
			
			server.Admin.RemoveAdmin(p,temp)
			server.Admin.SetLevel(p,level)
			if temp then table.insert(server.Admin.TempAdmins,p) end
			
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
				table.insert(server.Settings.Moderators,value)
				if server.Settings.SaveAdmins and not temp then
					server.Core.DoSave({
						Type = "TableAdd";
						Table = "Moderators";
						Value = value
					})
				end
			elseif level == 2 then
				table.insert(server.Settings.Admins,value)
				if server.Settings.SaveAdmins and not temp then
					server.Core.DoSave({
						Type = "TableAdd";
						Table = "Admins";
						Value = value
					})
				end
			elseif level == 3 then
				table.insert(server.Settings.Owners,value)
				if server.Settings.SaveAdmins and not temp then
					server.Core.DoSave({
						Type = "TableAdd";
						Table = "Owners";
						Value = value
					})
				end
			elseif level == 4 then
				table.insert(server.Settings.Creators,value)
				if server.Settings.SaveAdmins and not temp then
					server.Core.DoSave({
						Type = "TableAdd";
						Table = "Creators";
						Value = value
					})
				end
			end
			
			server.Admin.UpdateCachedLevel(p)
		end;	
		
		CheckDonor = function(p)
			--if not server.Settings.DonorPerks then return false end
			local key = tostring(p.userId)
			if server.Variables.CachedDonors[key] then
				return true
			else
				if p.userId<0 or (tonumber(p.AccountAge) and tonumber(p.AccountAge)<0) then return false end
				if not service.GamepassService or not service.MarketPlace then return end
				for ind,pass in next,server.Variables.DonorPass do
					local ran,ret = pcall(function() return service.MarketPlace:PlayerOwnsAsset(p,pass) end)
					if ran and ret then --service.GamepassService:PlayerHasPass(p,pass) or 
						server.Variables.CachedDonors[key] = tick()
						return true
					end
				end
				--[[
				for ind,old in pairs(server.Variables.OldDonorList) do
					if p.Name==old.Name or p.userId==old.Id then
						server.Variables.CachedDonors[key] = tick()
						return true
					end
				end
				--]]
			end
		end;
		
		CheckBan = function(p)
			local doCheck = server.Admin.DoCheck
			for ind,admin in next,server.Settings.Banned do
				if doCheck(p,admin) then
					return true
				end
			end
			
			for ind,ban in next,server.Core.Variables.TimeBans do
				if (p.UserId == ban.UserId) then
					if ban.EndTime-os.time() <= 0 then
						table.remove(server.Core.Variables.TimeBans, ind)
					else
						return true
					end
				end
			end
			
			for ind,admin in next,server.HTTP.Trello.Bans do
				if doCheck(p,admin) then
					return true
				end
			end
		end;
		
		AddBan = function(p, doSave)
			table.insert(server.Settings.Banned, p.Name..':'..p.userId) 
			if doSave then
				server.Core.DoSave({
					Type = "TableAdd";
					Table = "Banned";
					Value = p.Name..':'..p.UserId;
				})
			end
			if not service.Players:FindFirstChild(p.Name) then
				server.Remote.Send(p,'Function','KillClient')
			else
				if p then ypcall(function() p:Kick("You have been banned") end) end
			end
		end;
		
		RemoveBan = function(name, doSave)
			local ret
			for i,v in next,server.Settings.Banned do
				if v:lower():sub(1,#name) == name:lower() or name:lower()=="all" then
					table.remove(server.Settings.Banned, i)
					ret = v
					if doSave then
						server.Core.DoSave({
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
			local index,command = server.Admin.GetCommand(cmd)
			if command and newLevel then 
				command.AdminLevel = newLevel
			end
		end;
		
		RunCommand = function(coma,...)
			local ind,com = server.Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = server.Admin.GetArgs(coma,#cmdArgs,...)
				--local task,ran,error = service.Threads.TimeoutRunTask("SERVER_COMMAND: "..coma,com.Function,60*5,false,args)
				local ran, error = service.TrackTask("Command: ".. tostring(coma), com.Function, false, args)
				if error then 
					--logError("SERVER","Command",error) 
				end
			end
		end;
		
		RunCommandAsPlayer = function(coma,plr,...)
			local ind,com = server.Admin.GetCommand(coma)
			if com then
				local cmdArgs = com.Args or com.Arguments
				local args = server.Admin.GetArgs(coma,#cmdArgs,...)
				local ran, error = service.TrackTask(tostring(plr) ..": ".. coma, com.Function, plr, args)
				--local task,ran,error = service.Threads.TimeoutRunTask("COMMAND:"..tostring(plr)..": "..coma,com.Function,60*5,plr,args)
				if error then 
					--logError(plr,"Command",error) 
					error = error:match(":(.+)$") or "Unknown error"
					server.Remote.MakeGui(plr,'Output',{Title = ''; Message = error; Color = Color3.new(1,0,0)})  
				end
			end
		end;
		
		GetArgs = function(msg,num,...)
			local args = server.Functions.Split((msg:match("^.-"..server.Settings.SplitKey..'(.+)') or ''),server.Settings.SplitKey,num) or {}
			for i,v in next,{...} do table.insert(args,v) end
			return args
		end;
		
		CacheCommands = function()
			local tempTable = {}
			local tempPrefix = {}
			for ind,data in next,server.Commands do
				for i,cmd in next,data.Commands do
					if data.Prefix == "" then server.Variables.BlankPrefix = true end
					tempPrefix[data.Prefix] = true
					tempTable[(data.Prefix..cmd):lower()] = ind
				end
			end
			
			server.Admin.PrefixCache = tempPrefix
			server.Admin.CommandCache = tempTable
		end;
		
		GetCommand = function(Command)
			if server.Admin.PrefixCache[Command:sub(1,1)] or server.Variables.BlankPrefix then
				local matched
				if Command:find(server.Settings.SplitKey) then
					matched = Command:match("^(%S+)"..server.Settings.SplitKey)
				else
					matched = Command:match("^(%S+)")
				end
				
				if matched then	
					local found = server.Admin.CommandCache[matched:lower()]
					if found then
						local real = server.Commands[found]
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
			local splitter = server.Settings.SplitKey
			
			for ind,arg in next,cmdArgs do
				text = text..splitter.."<"..arg..">"
			end
			
			return text
		end;
		
		CheckTable = function(p,tab)
			local doCheck = server.Admin.DoCheck
			for i,v in next,tab do
				if doCheck(p,v) then
					return true
				end
			end
		end;
		
		CheckPermission = function(pDat,cmd)
			local allowed = false
			local p = pDat.Player
			local adminLevel = pDat.Level
			local isAgent = pDat.isAgent
			local isDonor = (pDat.isDonor and (server.Settings.DonorCommands or cmd.AllowDonors))
			local comLevel = cmd.AdminLevel
			local funAllowed = server.Settings.FunCommands
			local isFun = cmd.Fun
			
			if adminLevel >= 4 then
				return true
			elseif isFun and not funAllowed and adminLevel < 4 then
				return false
			elseif server.Core.EmergencyMode and adminLevel >= 1 and (comLevel == "Helper" or comLevel == "Moderator" or comLevel == "Admin") then
				return true
			elseif comLevel=="Players" and (server.Settings.PlayerCommands or adminLevel >= 1) then
				return true
			elseif comLevel=="Donors" and isDonor then
				return true
			elseif cmd.Agents and isAgent then
				return true
			elseif comLevel=="Moderators" and adminLevel >= 1 then
				return true
			elseif comLevel=="Admins" and adminLevel >= 2 then
				return true
			elseif comLevel=="Owners" and adminLevel >= 3 then
				return true
			elseif comLevel=="Creators" and adminLevel >= 4 then
				return true
			elseif server.Settings.CustomRanks[comLevel] then
				if adminLevel >= 1 or server.Admin.CheckTable(p,server.Settings.CustomRanks[comLevel]) then
					return true
				end
			end
			
			return false
		end;
		
		SearchCommands = function(p,search) 
			local checkPerm = server.Admin.CheckPermission
			local tab = {}
			local pDat = {
				Player = p;
				Level = server.Admin.GetLevel(p);
				isAgent = server.HTTP.Trello.CheckAgent(p);
				isDonor = server.Admin.CheckDonor(p);
			}
			
			for index,command in next,server.Commands do
				if checkPerm(pDat, command) then
					tab[index] = command
				end
			end
			
			return tab
		end;
	};
end