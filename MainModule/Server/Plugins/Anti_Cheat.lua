server = nil
service = nil
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

		Anti.Init = nil;
		Logs:AddLog("Script", "AntiExploit Plugin Module Initialized")
	end

	local function RunAfterPlugins(data)
		Logs:AddLog("Script", "Anti Plugin Module RunAfterPlugins Finished");

		local function onPlayerAdded(player)
			if not player.Character then
				player.CharacterAdded:Wait()
			end

			if Admin.GetLevel(player) < Settings.Ranks.Moderators.Level or Core.DebugMode == true then
				Anti.CharacterCheck(player)
			end
		end

		if Settings.Detection == false then
			Logs:AddLog("Script", "Didn't load Adonis protection systems due to settings.Detection being set to false.")
			return
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

	server.Anti.CharacterCheck = function(player) -- // From my plugin FE++ (Creator Github@ccuser44/Roblox@ALE111_boiPNG)
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
						Text = `Character AE Detected {player}`;
						Desc = `The Anti-Exploit character check detected player: {player} action: {action} reason: {reason}`;
						Player = player;
					})

					warn(`Charactercheck detected player: {player} action: {action} reason: {reason}`)
				else
					Anti.Detected(player, action, reason)
				end
			end
		end

		local function onCharacterRemoving(character)
			charGood = false
		end

		local function onCharacterAdded(character)
			charGood = true

			character.ChildAdded:Connect(function(child)
				if child:IsA("BackpackItem") and Settings.AntiMultiTool == true then
					local count = 0

					task.defer(function()
						for _, v in ipairs(character:GetChildren()) do
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

			humanoid.StateChanged:Connect(function(last, state)
				if last == Enum.HumanoidStateType.Dead and state ~= Enum.HumanoidStateType.Dead and humanoid then
					humanoid.Health = 0
					humanoid:ChangeState(Enum.HumanoidStateType.Dead)
					Logs.AddLog(Logs.Script, {
						Text = `AE: Humanoid came out of dead state for player: {player}`;
						Desc = `AE: Humanoid came out of dead state for player: {player}`;
						Player = player;
					})
				end
			end)

			if service.Players.CharacterAutoLoads and Settings.AntiGod == true then
				local connection

				connection = humanoid.Died:Connect(function()
					if not connection.Connected then
						return
					end

					connection:Disconnect()

					if service.Players.RespawnTime == math.huge then return end
					
					task.wait(service.Players.RespawnTime + 1.5)

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
								Text = `AE: Waist joint deleted by player: {player}`;
								Desc = `AE: Waist joint deleted by player: {player}`;
								Player = player;
							})
						end
					end)
				end)

				table.insert(connections, connection)
			end

			local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			local rootJoint = humanoid.RigType == Enum.HumanoidRigType.R15 and character:WaitForChild("LowerTorso"):WaitForChild("Root") or humanoid.RigType == Enum.HumanoidRigType.R6 and (humanoidRootPart:FindFirstChild("Root Hip") or humanoidRootPart:WaitForChild("RootJoint"))

			if Settings.AntiRootJointDeletion or Settings.AntiParanoid --[[and game.PlaceId < 13308063561]] then -- // Enable workspace.RejectCharacterDeletions instead
				makeConnection(rootJoint.AncestryChanged)

				if humanoid.RigType == Enum.HumanoidRigType.R15 then
					makeConnection(character:WaitForChild("UpperTorso"):WaitForChild("Waist").AncestryChanged)
				end
			end
		end

		if player.Character then
			task.spawn(onCharacterAdded, player.Character)
		end

		player.CharacterRemoving:Connect(onCharacterRemoving)
		player.CharacterAdded:Connect(onCharacterAdded)
	end;

	Init();
	task.wait()
	RunAfterPlugins();
end
