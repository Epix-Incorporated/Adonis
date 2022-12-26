server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

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

		local function onPlayerAdded(player)
			if not player.Character then
				player.CharacterAdded:Wait()
			end

			if Admin.GetLevel(player) < Settings.Ranks.Moderators.Level or Core.DebugMode == true then
				Anti.CharacterCheck(player)
			end
		end

		if
			service.ServerScriptService:FindFirstChild("AntiExploit_PlusPlus") or
			service.ServerScriptService:FindFirstChild("FE_Plus_Plus_AntiExploit") -- // Legacy name
		then
			Logs:AddLog("Script", "Didn't run character AC checks because another anti-exploit which does the same is already loaded.")
			return
		end

		for _, v in service.Players:GetPlayers() do
			task.spawn(onPlayerAdded, v)
		end
		service.Players.PlayerAdded:Connect(onPlayerAdded)
	end

	local antiNotificationDebounce, antiNotificationResetTick = {}, os.clock() + 60
	local kickedPlayers = setmetatable({}, {__mode = "v"})

	server.Anti = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		ClientTimeoutLimit = 300; --// ... Five minutes without communication seems long enough right?
		SpoofCheckCache = {};
		RemovePlayer = function(p, info)
			info = tostring(info) or "No Reason Given"

			pcall(function()service.UnWrap(p):Kick(":: Adonis ::\n".. tostring(info)) end)

			task.wait(1)

			pcall(p.Destroy, p)
			pcall(service.Delete, p)

			Logs.AddLog("Script",{
				Text = "Server removed "..tostring(p);
				Desc = info;
			})
		end;

		CharacterCheck = function(player) -- // From my plugin FE++ (Creator Github@ccuser44/Roblox@ALE111_boiPNG)
			local charGood = false --// Prevent accidental triggers while removing the character ~ Scel

			local function Detected(player, action, reason)
				if charGood then
					if Settings.CharacterCheckLogs ~= true and (string.lower(action) == "log" or string.lower(action) == "kill") then
						if action == "kill" then
							local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
							if humanoid then
								humanoid.Health = 0
							end
						end

						Logs.AddLog(Logs.Script, {
							Text = "Character AE Detected "..tostring(player);
							Desc = "The Anti-Exploit character check detected player: "..tostring(player).." action: "..tostring(action).." reason: "..tostring(reason);
							Player = player;
						})

						warn("Charactercheck detected player: "..tostring(player).." action: "..tostring(action).." reason: "..tostring(reason))
					else
						Anti.Detected(player, action, reason)
					end
				end
			end

			local function protectHat(hat)
				local handle = hat:WaitForChild("Handle", 30)

				if handle then
					task.defer(function()
						local joint = handle:WaitForChild("AccessoryWeld")

						local connection
						connection = joint.AncestryChanged:Connect(function(_, parent)
							if not connection.Connected or parent then
								return
							end

							connection:Disconnect()

							if handle and handle:CanSetNetworkOwnership() then
								handle:SetNetworkOwner(nil)
							end

							Logs.AddLog(Logs.Script, {
								Text = "AE: Hat joint deletion reset network ownership for player: "..tostring(player);
								Desc = "The AE reset joint handle network ownership for player: "..tostring(player);
								Player = player;
							})
						end)
					end)

					if handle:IsA("Part") then
						local mesh = handle:FindFirstChildOfClass("SpecialMesh") or handle:WaitForChild("Mesh")

						mesh.AncestryChanged:Connect(function(child, parent)
							task.defer(function()
								if child == mesh and handle and (not parent or not handle:IsAncestorOf(mesh)) and hat and hat.Parent then
									mesh.Parent = handle
									Detected(player, "log", "Hat mesh removed. Very likely using a hat exploit")
								end
							end)
						end)
					end
				end
			end

			local function onCharacterRemoving(character)
				charGood = false
			end

			local function onCharacterAdded(character)
				charGood = true

				for _, v in character:GetChildren() do
					if v:IsA("Accoutrement") and Settings.ProtectHats == true then
						coroutine.wrap(protectHat)(v)
					end
				end

				character.ChildAdded:Connect(function(child)
					if child:IsA("Accoutrement") and Settings.ProtectHats == true then
						protectHat(child)
					elseif child:IsA("BackpackItem") and Settings.AntiMultiTool == true then
						local count = 0

						task.defer(function()
							for _, v in character:GetChildren() do
								if v:IsA("BackpackItem") then
									count += 1
									if count > 1 then
										local backpack = player:FindFirstChildOfClass("Backpack") or Instance.new("Backpack")
										if not backpack.Parent then
											backpack.Parent = player
										end
										v.Parent = backpack
										Detected(player, "log", "Multiple tools equipped at the same time")
									end
								end
							end
						end)
					end
				end)

				local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

				if Settings.AntiHumanoidDeletion then
					humanoid.AncestryChanged:Connect(function(child, parent)
						task.defer(function()
							if child == humanoid and character and (not parent or not character:IsAncestorOf(humanoid)) then
								humanoid.Parent = character
								Detected(player, "kill", "Humanoid removed")
							end
						end)
					end)
				end

				humanoid.StateChanged:Connect(function(last, state)
					if last == Enum.HumanoidStateType.Dead and state ~= Enum.HumanoidStateType.Dead and humanoid then
						humanoid.Health = 0
						humanoid:ChangeState(Enum.HumanoidStateType.Dead)
						Logs.AddLog(Logs.Script, {
							Text = "AE: Humanoid came out of dead state for player: "..tostring(player);
							Desc = "AE: Humanoid came out of dead state for player: "..tostring(player);
							Player = player;
						})
					end
				end)

				if game:GetService("Players").CharacterAutoLoads and Settings.AntiGod == true then
					local connection

					connection = humanoid.Died:Connect(function()
						if not connection.Connected then
							return
						end

						connection:Disconnect()

						task.wait(game:GetService("Players").RespawnTime + 1.5)

						if workspace:IsAncestorOf(humanoid) then
							Detected(player, "log", "Player took too long to respawn. Respawning manually")
							player:LoadCharacter()
						end
					end)
				end

				local animator = humanoid:WaitForChild("Animator")

				animator.AnimationPlayed:Connect(function(animationTrack)
					local animationId = animationTrack.Animation.AnimationId
					if animationId == "rbxassetid://148840371" or string.match(animationId, "[%d%l]+://[/%w%p%?=%-_%$&'%*%+%%]*148840371/*") then
						task.defer(function()
							animationTrack:Stop(1/60)
						end)
						Detected(player, "log", "Player played an inappropriate character animation")
					end
				end)

				local connections = {}
				local function makeConnection(Conn)
					local connection
					connection = Conn:Connect(function(_, parent)
						task.defer(function()
							if not connection.Connected or parent or humanoid and humanoid.Health <= 0 then
								return
							end

							for _, v in connections do
								v:Disconnect()
							end

							if humanoid then
								humanoid.Health = 0
								humanoid:ChangeState(Enum.HumanoidStateType.Dead)
								Logs.AddLog(Logs.Script, {
									Text = "AE: Waist joint deleted by player: "..tostring(player);
									Desc = "AE: Waist joint deleted by player: "..tostring(player);
									Player = player;
								})
							end
						end)
					end)

					table.insert(connections, connection)
				end

				if Settings.AntiRootJointDeletion or Settings.AntiParanoid then
					local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
					local rootJoint = humanoid.RigType == Enum.HumanoidRigType.R15 and character:WaitForChild("LowerTorso"):WaitForChild("Root") or humanoid.RigType == Enum.HumanoidRigType.R6 and (humanoidRootPart:FindFirstChild("Root Hip") or humanoidRootPart:WaitForChild("RootJoint"))

					makeConnection(rootJoint.AncestryChanged)

					if humanoid.RigType == Enum.HumanoidRigType.R15 then
						makeConnection(character:WaitForChild("UpperTorso"):WaitForChild("Waist").AncestryChanged)
					end
				end
			end

			if player.Character then
				coroutine.wrap(onCharacterAdded)(player.Character)
			end

			player.CharacterRemoving:Connect(onCharacterRemoving)
			player.CharacterAdded:Connect(onCharacterAdded)
		end;

		CheckAllClients = function()
			--// Check if clients are alive
			if Settings.CheckClients and server.Running then
				Logs.AddLog(Logs.Script,{
					Text = "Checking Clients";
					Desc = "Making sure all clients are active";
				})

				for ind,p in service.Players:GetPlayers() do
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
						for i,user in userInfo do
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

		CheckBackpack = function(p, obj)
			local ran, err = pcall(function()
				return p:WaitForChild("Backpack", 60):FindFirstChild(obj)
			end)
			return if ran then ran else false
		end;

		Detected = function(player, action, info)
			local info = string.gsub(tostring(info), "\n", "")

			if table.find(kickedPlayers, player) then
				player:Kick(":: Adonis ::\n"..info)
				return
			elseif service.RunService:IsStudio() then
				warn("ANTI-EXPLOIT: "..player.Name.." "..action.." "..info)
			elseif service.NetworkServer then
				if player then
					if string.lower(action) == "kick" then
						table.insert(kickedPlayers, player)
						Anti.RemovePlayer(player, info)
					elseif string.lower(action) == "kill" then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

						if humanoid then
							humanoid:ChangeState(Enum.HumanoidStateType.Dead)
							humanoid.Health = 0
						end
						player.Character:BreakJoints()
					elseif string.lower(action) == "crash" then
						table.insert(kickedPlayers, player)
						Remote.Send(player, "Function", "Kill")
						task.wait(5)
						pcall(function()
							local scr = Core.NewScript("LocalScript", [[while true do end]])
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)

						Anti.RemovePlayer(player, info)
					elseif string.lower(action) ~= "log" then
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
				Text = "[Action: "..tostring(action).." User: (".. tostring(player) ..")] ".. tostring(string.sub(info, 1, 50)) .. " (Mouse over for full info)";
				Desc = tostring(info);
				Player = player;
			})

			if Settings.AENotifs == true or Settings.ExploitNotifications == true then -- AENotifs for old loaders
				local debounceIndex = tostring(action)..tostring(player)..tostring(info)
				if os.clock() < antiNotificationResetTick then
					antiNotificationDebounce = {}
					antiNotificationResetTick = os.clock() + 60
				end

				if not antiNotificationDebounce[debounceIndex] then
					antiNotificationDebounce[debounceIndex] = 1
				elseif
					(string.lower(action) == "log" or string.lower(action) == "kill") and
					antiNotificationDebounce[debounceIndex] > 3
				then
					return
				end

				for _, plr in service.Players:GetPlayers() do
					if Admin.GetLevel(plr) >= Settings.Ranks.Moderators.Level then
						Remote.MakeGui(plr, "Notification", {
							Title = "Notification",
							Icon = server.MatIcons["Notification important"];
							Message = string.format(
								"%s was detected for exploiting, action: %s info: %s  (See exploitlogs for full info)",
								player.Name,
								action,
								string.sub(info, 1, 50)
							);
							Time = 30;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."exploitlogs')");
						})
					end
				end
			end
		end;
	};
end
