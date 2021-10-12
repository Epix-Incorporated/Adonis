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
		service.StartLoop("ClientCheck", 30, Anti.CheckAllClients, true)

		Anti.Init = nil;
		Logs:AddLog("Script", "AntiExploit Module Initialized")
	end

	local function RunAfterPlugins(data)
		Anti.RunAfterPlugins = nil;
		Logs:AddLog("Script", "Anti Module RunAfterPlugins Finished");
	end

	server.Anti = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		ClientTimeoutLimit = 300; --// ... Five minutes without communication seems long enough right?
		SpoofCheckCache = {};
		RemovePlayer = function(p, info)
			info = tostring(info) or "No Reason Given"

			pcall(function()service.UnWrap(p):Kick(":: Adonis ::\n".. tostring(info)) end)

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
			if Settings.CheckClients and server.Running then
				Logs.AddLog(Logs.Script,{
					Text = "Checking Clients";
					Desc = "Making sure all clients are active";
				})

				for ind,p in ipairs(service.Players:GetPlayers()) do
					if p and p:IsA("Player") then
						local key = tostring(p.UserId)
						local client = Remote.Clients[key]
						if client and client.LastUpdate and client.PlayerLoaded then
							if os.time() - client.LastUpdate > Anti.ClientTimeoutLimit then
								Anti.Detected(p, "Kick", "Client Not Responding [>".. Anti.ClientTimeoutLimit .." seconds]")
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

		Detected = function(player, action, info)
			local info = string.gsub(tostring(info), "\n", "")

			if service.RunService:IsStudio() then
				warn("ANTI-EXPLOIT: "..player.Name.." "..action.." "..info)
			elseif service.NetworkServer then
				if player then
					if string.lower(action) == "log" then
						-- yay?
					elseif string.lower(action) == "kick" then
						Anti.RemovePlayer(player, info)
					elseif string.lower(action) == "kill" then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

						if humanoid then
							humanoid:ChangeState(Enum.HumanoidStateType.Dead)
							Humanoid.Health = 0
						end
						player.Character:BreakJoints()
					elseif string.lower(action) == "crash" then
						Remote.Send(player, "Function", "Kill")
						task.wait(5)
						pcall(function()
							local scr = Core.NewScript("LocalScript", [[while true do end]])
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
				Text = "[Action: "..tostring(action).." User: (".. tostring(player) ..")] ".. tostring(string.sub(info, 1, 50)) .. " (Mouse over full info)";
				Desc = tostring(info);
				Player = player;
			})

			if Settings.AENotifs == true then
				for _, plr in pairs(service.Players:GetPlayers()) do
					if Admin.GetLevel(plr) >= Settings.Ranks.Moderators then
						Remote.MakeGui(plr, "Notification", {
							Title = "Notification",
							Message = string.format
								action,
								"%s was detected for exploiting, action: %s info: %s  (Mouse over full info)",
								player.Name,
								string.sub(info, 1, 50)
							),
							Time = 30;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."exploitlogs')");
						})
					end
				end
			end
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
