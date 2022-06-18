return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
        SetFPS = {
			Prefix = Settings.Prefix;
			Commands = {"setfps"};
			Args = {"player", "fps"};
			Hidden = false;
			Description = "Sets the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player name")
				assert(args[2], "Missing FPS value")
				assert(tonumber(args[2]), tostring(args[2]).." is not a valid number")
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "SetFPS", tonumber(args[2]))
				end
			end
		};

		RestoreFPS = {
			Prefix = Settings.Prefix;
			Commands = {"restorefps", "revertfps", "unsetfps"};
			Args = {"player"};
			Hidden = false;
			Description = "Restores the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "RestoreFPS")
				end
			end
		};

        LowRes = {
			Prefix = Settings.Prefix;
			Commands = {"lowres", "pixelrender", "pixel", "pixelize"};
			Args = {"player", "pixelSize", "renderDist"};
			Hidden = false;
			Description = "Pixelizes the player's view";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local size = tonumber(args[2]) or 19
				local dist = tonumber(args[3]) or 100
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Effect", {
						Mode = "Pixelize";
						Resolution = size;
						Distance = dist;
					})
				end
			end
		};

		ZaWarudo = {
			Prefix = Settings.Prefix;
			Commands = {"zawarudo", "stoptime"};
			Args = {};
			Fun = true;
			Description = "Freezes everything but the player running the command";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local doPause; doPause = function(obj)
					if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(plr.Character) then
						obj.Anchored = true
						table.insert(Variables.FrozenObjects, obj)
					end

					for i, v in pairs(obj:GetChildren()) do
						doPause(v)
					end
				end

				if not Variables.ZaWarudoDebounce then
					Variables.ZaWarudoDebounce = true
					delay(10, function() Variables.ZaWarudoDebounce = false end)
					if Variables.ZaWarudo then
						local audio = service.New("Sound", workspace)
						audio.SoundId = "rbxassetid://676242549"
						audio.Volume = 0.5
						audio:Play()
						wait(2)
						for i, part in pairs(Variables.FrozenObjects) do
							part.Anchored = false
						end

						local old = service.Lighting:FindFirstChild("ADONIS_ZAWARUDO")
						if old then
							for i = -2, 0, 0.1 do
								old.Saturation = i
								wait(0.01)
							end
							old:Destroy()
						end

						local audio = workspace:FindFirstChild("ADONIS_CLOCK_AUDIO")
						if audio then
							audio:Stop()
							audio:Destroy()
						end

						Variables.ZaWarudo:Disconnect()
						Variables.FrozenObjects = {}
						Variables.ZaWarudo = false
						audio:Destroy()
					else
						local audio = service.New("Sound", workspace)
						audio.SoundId = "rbxassetid://274698941"
						audio.Volume = 10
						audio:Play()
						wait(2.25)
						doPause(workspace)
						Variables.ZaWarudo = game.DescendantAdded:Connect(function(c)
							if c:IsA("BasePart") and not c.Anchored and c.Name ~= "HumanoidRootPart" then
								c.Anchored = true
								table.insert(Variables.FrozenObjects, c)
							end
						end)

						local cc = service.New("ColorCorrectionEffect", service.Lighting)
						cc.Name = "ADONIS_ZAWARUDO"
						for i = 0,-2,-0.1 do
							cc.Saturation = i
							wait(0.01)
						end

						audio:Destroy()
						local clock = service.New("Sound", workspace)
						clock.Name = "ADONIS_CLOCK_AUDIO"
						clock.SoundId = "rbxassetid://160189066"
						clock.Looped = true
						clock.Volume = 1
						clock:Play()
					end
					Variables.ZaWarudoDebounce = false
				end
			end
		};

		Dizzy = {
			Prefix = Settings.Prefix;
			Commands = {"dizzy"};
			Args = {"player", "speed"};
			Description = "Causes motion sickness";
			AdminLevel = "Admins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				local speed = args[2] or 50
				if not speed or not tonumber(speed) then
					speed = 1000
				end
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "Dizzy", tonumber(speed))
				end
			end
		};

		UnDizzy = {
			Prefix = Settings.Prefix;
			Commands = {"undizzy"};
			Args = {"player"};
			Description = "UnDizzy";
			AdminLevel = "Admins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.Send(v, "Function", "Dizzy", false)
				end
			end
		};

        Thanos = {
			Prefix = Settings.Prefix;
			Commands = {"thanos", "thanossnap", "balancetheserver", "snap"};
			Args = {"player"};
			Description = "\"Fun isn't something one considers when balancing the universe. But this... does put a smile on my face.\"";
			Fun = true;
			Hidden = false;
			AdminLevel = "Admins";
			Function = function(plr, args, data)
				local players = {}
				local deliverUs = {}
				local playerList = service.GetPlayers(args[1] and plr, args[1])
				local plrLevel = data.PlayerData.Level

				local audio = Instance.new("Sound")
				audio.Name = "Adonis_Snap"
				audio.SoundId = "rbxassetid://".. 2231214507
				audio.Looped = false
				audio.Volume = 1
				audio.PlayOnRemove = true

				--[[local thanos = audio:Clone()
				thanos.Name = "Adonis_Thanos"
				thanos.SoundId = "rbxassetid://".. 2231229572

				thanos.Parent = service.SoundService
				audio.Parent = service.SoundService

				wait()
				thanos:Destroy()--]]
				wait()
				audio:Destroy()

				if #playerList == 1 then
					local player = playerList[1];
					local tLevel = Admin.GetLevel(player);

					if tLevel < plrLevel then
						deliverUs[player] = true
						table.insert(players, player)
					end
				elseif #playerList > 1 then
					for i = 1, #playerList*10 do
						if #players < math.max((#playerList/2), 1) then
							local index = math.random(1, #playerList)
							local targPlayer = playerList[index]
							if not deliverUs[targPlayer] then
								local targLevel = Admin.GetLevel(targPlayer)
								if targLevel < plrLevel then
									deliverUs[targPlayer] = true
									table.insert(players, targPlayer)
								else
									table.remove(playerList, index)
								end
								wait()
							end
						else
							break
						end
					end
				end

				for i, p in pairs(players) do
					service.TrackTask("Thread: Thanos", function()
						for t = 0.1, 1.1, 0.05 do
							if p.Character then
								local human = p.Character:FindFirstChildOfClass("Humanoid")
								if human then
									human.HealthDisplayDistance = 1
									human.NameDisplayDistance = 1
									human.HealthDisplayType = "AlwaysOff"
									human.NameOcclusion = "OccludeAll"
								end

								for k, v in ipairs(p.Character:GetChildren()) do
									if v:IsA("BasePart") then
										local decal = v:FindFirstChildOfClass("Decal")
										local foundDust = v:FindFirstChild("Thanos_Emitter")
										local trans = (t/k)+t

										if decal then
											decal.Transparency = trans
										end

										v.Transparency = trans

										if v.Color ~= Color3.fromRGB(106, 57, 9) then
											v.Color = v.Color:lerp(Color3.fromRGB(106, 57, 9), 0.05)
										end

										if not foundDust and t < 0.3 then
											local em = Instance.new("ParticleEmitter")
											em.Color = ColorSequence.new(Color3.fromRGB(199, 132, 65))
											em.LightEmission = 0.5
											em.LightInfluence = 0
											em.Size = NumberSequence.new{
												NumberSequenceKeypoint.new(0, 2),
												NumberSequenceKeypoint.new(1, 3)
											}
											em.Texture = "rbxassetid://173642823"
											em.Transparency = NumberSequence.new{
												NumberSequenceKeypoint.new(0, 0),
												NumberSequenceKeypoint.new(1, 1)
											}
											em.Acceleration = Vector3.new(1, 0.1, 0)
											em.VelocityInheritance = 0
											em.EmissionDirection = "Top"
											em.Lifetime = NumberRange.new(3, 8)
											em.Rate = 10
											em.Rotation = NumberRange.new(0, 135)
											em.RotSpeed = NumberRange.new(10, 20)
											em.Speed = NumberRange.new(0, 0)
											em.SpreadAngle = Vector2.new(0, 0)
											em.Name = "Thanos_Emitter"
											em.Parent = v
										elseif t > 0.5 then
											foundDust.Enabled = false
										end
									end
								end
							end

							--[[local root = p.Character:FindFirstChild("HumanoidRootPart")
							if root then
								local part = Instance.new("Part")
								part.Anchored = false
								part.CanCollide = true
								part.BrickColor = BrickColor.new("Burnt Sienna")
								part.Size = Vector3.new(0.1, 0.1, 0.1)
								part.CFrame = root.CFrame*CFrame.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
								part.Parent = workspace
								service.Debris:AddItem(part, 5)
							end--]]
							wait(0.2)
						end

						wait(1)
						p:Kick("\n\n\"I don't feel so good\"\n")
					end)
				end
			end;
		};

        ifoundyou = {
			Prefix = Settings.Prefix;
			Commands = {"theycome", "fromanotherworld", "ufo", "abduct", "space", "newmexico", "area51", "rockwell"};
			Args = {"player"};
			Description = "A world unlike our own.";
			Fun = true;
			Hidden = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local data = server.Core.GetPlayer(plr)
				local forYou = {
					'"Who are you?"';
					'"I am Death," said the creature. "I thought that was obvious."';
					'"But you\'re so small!"';
					'"Only because you are small."';
					'"You are young and far from your Death, September, ..."';
					'"... so I seem as anything would seem if you saw it from a long way off ..."';
					'"... very small, very harmless."';
					'"But I am always closer than I appear."';
					'"As you grow, I shall grow with you ..."';
					'"... until at the end, I shall loom huge and dark over your bed ..."';
					'"... and you will shut your eyes so as not to see me."';

					'Find me.';
					'Fear me.';
					'Love me.';
				}

				if not args[1] then
					local ind = data.SleepInParadise or 1
					data.SleepInParadise = ind+1

					if ind == 14 then
						data.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for i, p in ipairs(service.GetPlayers(plr, args[1])) do
					service.TrackTask("Thread: UFO", function()
						local char = p.Character
						local torso = p.Character:FindFirstChild("HumanoidRootPart")
						local humanoid = p.Character:FindFirstChild("Humanoid")

						if torso and humanoid and not char:FindFirstChild("ADONIS_UFO") then
							local ufo = server.Deps.Assets.UFO:Clone()
							if ufo then
								local function check()
									if not ufo.Parent or p.Parent ~= service.Players or not torso.Parent or not humanoid.Parent or not char.Parent then
										return false
									else
										return true
									end
								end

								local light = ufo.Light
								local rotScript = ufo.Rotator
								local beam = ufo.BeamPart
								local spotLight = light.SpotLight
								local particles = light.ParticleEmitter
								local primary = ufo.Primary
								local bay = ufo.Bay

								local hum = light.Humming
								local leaving = light.Leaving
								local idle = light.Idle
								local beamSound = light.Beam

								local origBeamTrans = beam.Transparency

								local tPos = torso.CFrame
								local info = TweenInfo.new(5, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out, -1, true, 0)

								humanoid.Name = "NoResetForYou"
								humanoid.WalkSpeed = 0

								ufo.Name = "ADONIS_UFO"
								ufo.PrimaryPart = primary
								ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, 500, 0))

								spotLight.Enabled = false
								particles.Enabled = false
								beam.Transparency = 1

								ufo.Parent = p.Character

								wait()
								rotScript.Disabled = false

								for i = 1, 200 do
									if not check() then
										break
									else
										ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, 200-i, 0))
										wait(0.001*(i/5))
									end
								end

								if check() then
									wait(1)
									spotLight.Enabled = true
									particles.Enabled = true
									beam.Transparency = origBeamTrans
									beamSound:Play()

									local tween = service.TweenService:Create(torso, info, {
										CFrame = bay.CFrame*CFrame.new(0, 0, 0)
									})

									torso.Anchored = true
									tween:Play()

									for i, v in ipairs(p.Character:GetChildren()) do
										if v:IsA("BasePart") then
											service.TweenService:Create(v, TweenInfo.new(1), {
												Transparency = 1
											}):Play()
											--v:ClearAllChildren()
										end
									end

									wait(5)

									spotLight.Enabled = false
									particles.Enabled = false
									beam.Transparency = 1
									beamSound:Stop()

									--idle:Stop()
									--leaving:Play()

									Remote.LoadCode(p,[[
										local cam = workspace.CurrentCamera
										local player = service.Players.LocalPlayer
										local ufo = player.Character:FindFirstChild("ADONIS_UFO")
										if ufo then
											local part = ufo:FindFirstChild("Bay")
											if part then
												--cam.CameraType = "Track"
												cam.CameraSubject = part
											end
										end
									]])

									for i, v in ipairs(p.Character:GetChildren()) do
										if v:IsA("BasePart") then
											v.Anchored = true
											v.Transparency = 1
											pcall(function() v:FindFirstChildOfClass("Decal"):Destroy() end)
										elseif v:IsA("Accoutrement") then
											v:Destroy()
										end
									end

									wait(1)

									server.Remote.MakeGui(p, "Effect", {Mode = "FadeOut";})

									for i = 1, 260 do
										if not check() then
											break
										else
											ufo:SetPrimaryPartCFrame(tPos*CFrame.new(0, i, 0))
											--torso.CFrame = bay.CFrame*CFrame.new(0, 2, 0)
											wait(0.001*(i/5))
										end
									end

									if check() then
										p.CameraMaxZoomDistance = 0.5

										local gui = Instance.new("ScreenGui")
										gui.Parent = service.ReplicatedStorage
										local bg = Instance.new("Frame")
										bg.BackgroundTransparency = 0
										bg.BackgroundColor3 = Color3.new(0, 0, 0)
										bg.Size = UDim2.new(2, 0, 2, 0)
										bg.Position = UDim2.new(-0.5, 0,-0.5, 0)
										bg.Parent = gui
										if p and p.Parent == service.Players then service.TeleportService:Teleport(6806826116, p, nil, bg) end
										wait(0.5)
										pcall(function() gui:Destroy() end)
									end
								end

								pcall(function() ufo:Destroy() end)
							end
						end
					end)
				end
			end;
		};

        Forest = {
			Prefix = Settings.Prefix;
			Commands = {"forest", "sendtotheforest", "intothewoods"};
			Args = {"player"};
			Hidden = false;
			Description = "Sends player to The Forest for a time out";
			Fun = true;
			NoStudio = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(209424751, v)
					end
				end
			end
		};

		Maze = {
			Prefix = Settings.Prefix;
			Commands = {"maze", "sendtothemaze", "mazerunner"};
			Args = {"player"};
			Hidden = false;
			Description = "Sends player to The Maze for a time out";
			Fun = true;
			NoStudio = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(280846668, v)
					end
				end
			end
		};

		ClownYoink = {
			Prefix = Settings.Prefix; 							-- Someone's always watching me
			Commands = {"clown", "yoink", "youloveme", "van"};   	-- Someone's always there
			Args = {"player"}; 									-- When I'm sleeping he just waits
			Description = "Clowns."; 							-- And he stares
			Fun = true; 										-- Someone's always standing in the
			Hidden = true; 										-- Darkest corner of my room
			AdminLevel = "Admins"; 								-- He's tall and wears a suit of black,
			Function = function(plr: Player, args: {string}) 						-- Dressed like the perfect groom
				local data = server.Core.GetPlayer(plr)
				local forYou = {
					'"Who are you?"';
					'"I am Death," said the creature. "I thought that was obvious."';
					'"But you\'re so small!"';
					'"Only because you are small."';
					'"You are young and far from your Death, September, ..."';
					'"... so I seem as anything would seem if you saw it from a long way off ..."';
					'"... very small, very harmless."';
					'"But I am always closer than I appear."';
					'"As you grow, I shall grow with you ..."';
					'"... until at the end, I shall loom huge and dark over your bed ..."';
					'"... and you will shut your eyes so as not to see me."';

					'Find me.';
					'Fear me.';
					'Love me.';
				}

				if not args[1] then
					local ind = data.SleepInParadise or 1
					data.SleepInParadise = ind+1

					if ind == 14 then
						data.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for i, p in ipairs(service.GetPlayers(plr, args[1])) do
					spawn(function()
						local char = p.Character
						local torso = p.Character:FindFirstChild("HumanoidRootPart")
						local humanoid = p.Character:FindFirstChild("Humanoid")
						if torso and humanoid and not char:FindFirstChild("ADONIS_VAN") then
							local van = server.Deps.Assets.Van:Clone()
							if van then
								local function check()
									if not van or not van.Parent or not p or p.Parent ~= service.Players or not torso or not humanoid or not torso.Parent or not humanoid.Parent or not char or not char.Parent then
										return false
									else
										return true
									end
								end

								local driver = van.Driver
								local grabber = van.Clown
								local primary = van.Primary
								local door = van.Door
								local tPos = torso.CFrame

								local sound = Instance.new("Sound")
								sound.SoundId = "rbxassetid://258529216"
								sound.Looped = true
								sound.Parent = primary
								sound:Play()

								local chuckle = Instance.new("Sound")
								chuckle.SoundId = "rbxassetid://164516281"
								chuckle.Looped = true
								chuckle.Volume = 0.25
								chuckle.Parent = primary
								chuckle:Play()

								van.PrimaryPart = van.Primary
								van.Name = "ADONIS_VAN"
								van.Parent = workspace
								humanoid.Name = "NoResetForYou"
								humanoid.WalkSpeed = 0
								sound.Pitch = 1.3

								server.Remote.PlayAudio(p, 421358540, 0.2, 1, true)

								for i = 1, 200 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(-200+i,-1,-7)*CFrame.Angles(0, math.rad(270), 0)))
										wait(0.001*(i/5))
									end
								end

								sound.Pitch = 0.9

								wait(0.5)
								if check() then
									door.Transparency = 1
								end
								wait(0.5)

								if check() then
									torso.CFrame = primary.CFrame*(CFrame.new(0, 2.3, 0)*CFrame.Angles(0, math.rad(90), 0))
								end

								wait(0.5)
								if check() then
									door.Transparency = 0
								end
								wait(0.5)

								sound.Pitch = 1.3
								server.Remote.MakeGui(p, "Effect", {
									Mode = "FadeOut";
								})

								p.CameraMaxZoomDistance = 0.5

								for i = 1, 400 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(0+i,-1,-7)*CFrame.Angles(0, math.rad(270), 0)))
										torso.CFrame = primary.CFrame*(CFrame.new(0, 2.3, 0)*CFrame.Angles(0, math.rad(90), 0))
										wait(0.1/(i*5))

										if i == 270 then
											server.Remote.FadeAudio(p, 421358540, nil, nil, 0.5)
										end
									end
								end

								local gui = Instance.new("ScreenGui")
								gui.Parent = service.ReplicatedStorage
								local bg = Instance.new("Frame")
								bg.BackgroundTransparency = 0
								bg.BackgroundColor3 = Color3.new(0, 0, 0)
								bg.Size = UDim2.new(2, 0, 2, 0)
								bg.Position = UDim2.new(-0.5, 0,-0.5, 0)
								bg.Parent = gui
								if p and p.Parent == service.Players then
									if service.RunService:IsStudio() then
										p:Kick("You were saved by the Studio environment.")
									else
										service.TeleportService:Teleport(527443962, p, nil, bg)
									end
								end
								wait(0.5)
								pcall(function() van:Destroy() end)
								pcall(function() gui:Destroy() end)
							end
						end
					end)
				end
			end;
		};

        MakeTalk = {
			Prefix = Settings.Prefix;
			Commands = {"talk", "maketalk"};
			Args = {"player", "message"};
			Filter = true;
			Fun = true;
			Description = "Makes a dialog bubble appear over the target player(s) head with the desired message";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local message = args[2]
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					service.ChatService:Chat(v.Character.Head, message, Enum.ChatColor.Blue)
				end
			end
		};

        GameGravity = {
			Prefix = Settings.Prefix;
			Commands = {"ggrav", "gamegrav", "workspacegrav"};
			Args = {"number or fix"};
			Hidden = false;
			Description = "Sets Workspace.Gravity";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local num = assert(tonumber(args[1]), "Missing gravity value (or enter 'fix' to reset to normal)'")
				workspace.Gravity = num or 196.2
			end
		};

        CreateSoundPart = {
			Prefix = Settings.Prefix;
			Commands = {"createsoundpart", "createspart"};
			Args = {"soundid", "soundrange (default: 10) (max: 100)", "pitch (default: 1)", "noloop (default: false)", "volume (default: 1)", "clicktotoggle (default: false)", "share type (default: everyone)"};
			Description = "Creates a sound part";
			Hidden = false;
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(plr.Character ~= nil, "Character not found")
				assert(typeof(plr.Character) == "Instance", "Character found fake")
				assert(plr.Character:IsA("Model"), "Character isn't a model.")

				local char = plr.Character
				assert(char:FindFirstChild("Head"), "Head isn't found in your character. How is it going to spawn?")

				local soundid = (args[1] and tonumber(args[1])) or select(1, function()
					if args[1] then
						local nam = args[1]

						for i, v in pairs(server.Variables.MusicList)do
							if string.lower(v.Name) == string.lower(nam)then
								return v.ID
							end
						end
					end
				end)() or error("SoundId wasn't provided or wasn't a valid number")

				local soundrange = (args[2] and tonumber(args[2])) or 10
				local pitch = (args[3] and tonumber(args[3])) or 1
				--local disco-- = (args[4] and string.lower(args[4]) == "true") or false
				--local showhint-- = (args[5] and string.lower(args[5]) == "true") or false
				local noloop = (args[4] and string.lower(args[4]) == "true") or false
				local volume = (args[5] and tonumber(args[7])) or 1
				local changeable = true; -- = (args[8] and string.lower(args[8]) == "true") or false
				local toggable = (args[6] and string.lower(args[6]) == "true") or false
				local rangetotoggle = 0--(args[10] and tonumber(args[10])) or 10
				local sharetype = (args[7] and string.lower(args[7]) == "all" and "all")
					or (args[7] and string.lower(args[7]) == "self" and "self")
					or (args[7] and string.lower(args[7]) == "friends" and "friends")
					or (args[7] and string.lower(args[7]) == "admins" and "admins")
					or "all"

				if rangetotoggle == 0 then
					rangetotoggle = 32
				elseif rangetotoggle < 0 then
					rangetotoggle = math.abs(rangetotoggle)
				end

				pitch = math.abs(pitch)
				soundrange = math.abs(soundrange)

				if soundrange > 100 then
					soundrange = 100
				end

				local Success, Return = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, soundid)

				assert(Success, "Sound Id isn't a sound or doesn't exist.")
				if Success and Return then
					assert(Return.AssetTypeId == 3, "Sound Id isn't a sound. Please check the right id.")

					local sound = service.New("Sound")
					sound.Name = "Part_Sound"
					sound.Looped = not noloop
					sound.SoundId = "rbxassetid://"..soundid
					sound.Volume = volume
					sound.EmitterSize = soundrange
					sound.PlaybackSpeed = pitch
					sound.Archivable = false

					local spart = service.New("Part")
					spart.Anchored = true
					spart.Name = "SoundPart"
					spart.Position = char:FindFirstChild("Head").Position
					spart.Size = Vector3.new(2, 1, 2)
					table.insert(Variables.InsertedObjects, spart)

					sound.Changed:Connect(function(prot)
						if prot == "SoundId" then
							if sound.IsPlaying then
								sound:Stop()
							end

							sound.TimePosition = 0
						end
					end)

					if toggable then
						local clickd = service.New("ClickDetector")
						clickd.Name = "ClickToPlay"
						clickd.Archivable = false
						clickd.MaxActivationDistance = rangetotoggle
						local clicks = 0

						local ownerid = plr.UserId
						clickd.MouseClick:Connect(function(clicker)
							if sharetype == "self" and clicker.UserId ~= ownerid then return end
							if sharetype == "friends" then
								if clicker.UserId ~= ownerid and not clicker:IsFriendsWith(ownerid) then
									return
								end
							end

							clicks += 1
							delay(0.4, function()
								clicks -= 1
							end)

							if clicks == 1 then
								if sound.IsPlaying then
									sound:Pause()
								else
									sound:Resume()
								end
							elseif clicks == 2 then
								if sound.IsPlaying then
									sound:Stop()
								else
									sound:Play()
								end
							end
						end)

						clickd.Parent = spart
					end

					local prevname = spart.Name
					spart.Changed:Connect(function(prot)
						if prot == "Name" and changeable then
							if prevname == spart.Name then return end
							local Success, ProductInfo = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, tonumber(spart.Name)or 0)

							if Success and ProductInfo then
								if ProductInfo.AssetTypeId ~= 3 then
									spart.Name = prevname
									sound:Pause()
									return
								end

								prevname = spart.Name
								sound.SoundId = "rbxassetid://"..spart.Name
								wait(2)
							elseif not Success then
								spart.Name = prevname
							end

							if not toggable then
								sound:Play()
							end
						end
					end)

					if not toggable then
						sound:Play()
						wait(2)
					end

					sound.Parent = spart
					spart.Parent = workspace
					spart.Archivable = false
				end
			end
		};

    }
end
