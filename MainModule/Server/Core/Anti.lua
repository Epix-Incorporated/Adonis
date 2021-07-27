server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
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

		--// Client check
		service.StartLoop("ClientCheck",30, Anti.CheckAllClients, true)

		Anti.Init = nil;
		Logs:AddLog("Script", "AntiExploit Module Initialized")
	end

	local function RunAfterPlugins(data)
		--// Fake finder
		--service.RbxEvent(service.Players.ChildAdded, server.Anti.RemoveIfFake)

		Anti.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Anti Module RunAfterPlugins Finished");
	end

	server.Anti = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		ClientTimeoutLimit = 120; --// Two minutes without communication seems long enough right?
		SpoofCheckCache = {};
		RemovePlayer = function(p, info)
			info = tostring(info) or "No Reason Given"

			pcall(function()service.UnWrap(p):Kick("::Adonis::\n".. tostring(info)) end)

			wait(1)

			pcall(p.Destroy, p)
			pcall(service.Delete, p)

			Logs.AddLog("Script",{
				Text = "Server removed "..tostring(p);
				Desc = info;
			})
		end;

		CheckAllClients = function()
			--// Check if clients are alive
			if Settings.CheckClients and (not Core.PanicMode) and server.Running then
				Logs.AddLog(Logs.Script,{
					Text = "Checking Clients";
					Desc = "Making sure all clients are active";
				})

				for ind,p in ipairs(service.Players:GetPlayers()) do
					if p and p:IsA("Player") then
						if Anti.ObjRLocked(p) then
							Anti.Detected(p, "Log", "Player RobloxLocked")
						else
							local key = tostring(p.UserId)
							local client = Remote.Clients[key]
							if client and client.LastUpdate then
								if os.time() - client.LastUpdate > Anti.ClientTimeoutLimit then
									Anti.Detected(p, "Kick", "Client Not Responding [>".. Anti.ClientTimeoutLimit .." seconds]\n[Please open the developer console (F9) and screenshot any errors/warnings related to Adonis if this was done in error]")
								end
							end
						end
					end
				end
			end
		end;

		UserSpoofCheck = function(p)
			--// Supplied by BetterAccount
			if not service.RunService:IsStudio() then
				local userService = service.UserService;
				local success,err = pcall(function()
					local userInfo = Anti.SpoofCheckCache[p.UserId] or userService:GetUserInfosByUserIdsAsync({p.UserId})
					local data = userInfo and userInfo[1];

					Anti.SpoofCheckCache[p.UserId] = userInfo;

					if data and data.Id == p.UserId then
						if p.Name ~= data.Username or p.DisplayName ~= data.DisplayName then
							return true
						end
					else
						for i,user in next,userInfo do
							if user.Id == p.UserId then
								if p.Name ~= user.Username or p.DisplayName ~= user.DisplayName then
									return true
								end
							end
						end
					end
				end)

				if not success then
					warn("Failed to check validity of player's name, reason: ".. tostring(err))
				end
			end
		end;

		Sanitize = function(obj, classList)
			if Anti.RLocked(obj) then
				pcall(service.Delete, obj)
			else
				for i,child in next,obj:GetChildren() do
					if Anti.RLocked(child) or Functions.IsClass(child, classList) then
						pcall(service.Delete, child)
					else
						pcall(Anti.Sanitize, child, classList)
					end
				end
			end
		end;

		isFake = function(p)
			if Anti.ObjRLocked(p) or not p:IsA("Player") then
				return true,1
			else
				local players = service.Players:GetPlayers()
				local found = 0

				if service.NetworkServer then
					local net = false
					for i,v in pairs(service.NetworkServer:GetChildren()) do
						if v:IsA("NetworkReplicator") and v:GetPlayer() == p then
							net = true
						end
					end
					if not net then
						return true,1
					end
				end

				for i,v in pairs(players) do
					if tostring(v) == tostring(p) then
						found = found+1
					end
				end

				if found>1 then
					return true,found
				else
					return false
				end
			end
		end;

		RemoveIfFake = function(p)
			local isFake
			local ran,err = pcall(function() isFake = Anti.isFake(p) end)
			if isFake or not ran then
				Anti.RemovePlayer(p)
			end
		end;

		FindFakePlayers = function()
			for i,v in pairs(service.Players:GetPlayers()) do
				if Anti.isFake(v) then
					Anti.RemovePlayer(v, "Fake")
				end
			end
		end;

		GetClassName = function(obj)
			local testName = tostring(math.random()..math.random())
			local ran,err = pcall(function()
				local test = obj[testName]
			end)
			if err then
				local class = err:match(testName.." is not a valid member of (.*)")
				if class then
					return class
				end
			end
		end;

		RLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
		end;

		ObjRLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
		end;

		AssignName = function()
			local name = math.random(100000,999999)
			return name
		end;

		Detected = function(player,action,info)
			local info = string.gsub(tostring(info), "\n", "")

			if service.RunService:IsStudio() then
				warn("ANTI-EXPLOIT: "..player.Name.." "..action.." "..info)
			elseif service.NetworkServer then
				if player then
					if action:lower() == 'log' then
						-- yay?
					elseif action:lower() == 'kick' then
						Anti.RemovePlayer(player, info)
						--player:Kick("Adonis; Disconnected by server; \n"..tostring(info))
					elseif action:lower() == 'kill' then
						player.Character:BreakJoints()
					elseif action:lower() == 'crash' then
						Remote.Send(player,'Function','Kill')
						wait(5)
						pcall(function()
							local scr = Core.NewScript("LocalScript",[[while true do end]])
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)

						Anti.RemovePlayer(player, info)
					else
						-- fake log (thonk?)
						Anti.Detected(player, "Kick", "Spoofed log")
						return;
					end
				end
			end

			Logs.AddLog(Logs.Script,{
				Text = "AE Detected "..tostring(player);
				Desc = "The Anti-Exploit system detected strange activity from "..tostring(player);
				Player = player;
			})

			Logs.AddLog(Logs.Exploit,{
				Text = "[Action: "..tostring(action).." User: (".. tostring(player) ..")] ".. tostring(info:sub(1, 50)) .. " (Mouse over full info)";
				Desc = tostring(info);
				Player = player;
			})
		end;

		CheckNameID = function(p)
			if p.userId > 0 and p.userId ~= game.CreatorId and p.Character then
				local realId = service.Players:GetUserIdFromNameAsync(p.Name) or p.userId
				local realName = service.Players:GetNameFromUserIdAsync(p.userId) or p.Name

				if realName and realId then
					if (tonumber(realId) and realId~=p.userId) or (tostring(realName)~="nil" and realName~=p.Name) then
						Anti.Detected(p,'log','Name/UserId does not match')
					end

					Remote.Send(p,"LaunchAnti","NameId",{RealID = realId; RealName = realName})
				end
			end
		end;
	};
end
