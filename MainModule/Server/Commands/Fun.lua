return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine
	local Pcall = env.Pcall
	local cPcall = env.cPcall

	return {
		Glitch = {
			Prefix = Settings.Prefix;
			Commands = {"glitch", "glitchdisorient", "glitch1", "glitchy"};
			Args = {"player", "intensity"};
			Description = "Makes the target player(s)'s character teleport back and forth rapidly, quite trippy, makes bricks appear to move as the player turns their character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 15)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "trippy"
				for _, v in service.GetPlayers(plr, args[1]) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		Glitch2 = {
			Prefix = Settings.Prefix;
			Commands = {"ghostglitch", "glitch2", "glitchghost"};
			Args = {"player", "intensity"};
			Description = "The same as gd but less trippy, teleports the target player(s) back and forth in the same direction, making two ghost like images of the game";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 150)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "ghost"
				for _, v in service.GetPlayers(plr, args[1]) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		Vibrate = {
			Prefix = Settings.Prefix;
			Commands = {"vibrate", "glitchvibrate"};
			Args = {"player", "intensity"};
			Description = "Kinda like gd, but teleports the player to four points instead of two";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 0.1)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "vibrate"
				for _, v in service.GetPlayers(plr, args[1]) do
					local new = scr:Clone()
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							local scr = torso:FindFirstChild("Glitchify")
							if scr then scr:Destroy() end
							new.Parent = torso
							new.Name = "Glitchify"
							new.Disabled = false
						end
					end
				end
			end
		};

		UnGlitch = {
			Prefix = Settings.Prefix;
			Commands = {"unglitch", "unglitchghost", "ungd", "ungg", "ungv", "unvibrate"};
			Args = {"player"};
			Description = "UnGlitchs the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						local scr = torso:FindFirstChild("Glitchify")
						if scr then
							scr:Destroy()
						end
					end
				end
			end
		};

		SetFPS = {
			Prefix = Settings.Prefix;
			Commands = {"setfps"};
			Args = {"player", "fps"};
			Description = "Sets the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local value = assert(tonumber(args[2]), "Missing/invalid FPS value (argument #2)")
				assert(value <= 60, "FPS cannot exceed 60!")
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "SetFPS", value)
				end
			end
		};

		RestoreFPS = {
			Prefix = Settings.Prefix;
			Commands = {"restorefps", "revertfps", "unsetfps"};
			Args = {"player"};
			Description = "Restores the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "RestoreFPS")
				end
			end
		};

		Gerald = {
			Prefix = Settings.Prefix;
			Commands = {"gerald"};
			Args = {"player"};
			Description = "A massive Gerald AloeVera hat.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				--// Apparently Rojo doesn't handle mesh parts very well, so I'm loading this remotely (using require to bypass insertservice restrictions)
				--// The model is free to take so feel free to that 👍
				--// Here's the URL https://www.roblox.com/library/7679952474/AssetModule

				warn("Requiring Assets Module by ID; Expand for module URL > ", {URL = "https://www.roblox.com/library/7679952474/Adonis-Assets-Module"})

				local rAssets = require(7679952474) --// This apparently caches, so don't delete anything else future usage breaks
				local gerald = rAssets.Gerald

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local human = v.Character:FindFirstChildOfClass("Humanoid");
						if human then
							local clone = gerald:Clone()
							clone.Name = "__ADONIS_GERALD"
							human:AddAccessory(clone)
						end
					end
				end
			end
		};

		UnGerald = {
			Prefix = Settings.Prefix;
			Commands = {"ungerald"};
			Args = {"player"};
			Description = "De-Geraldification";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local gerald = v.Character:FindFirstChild("__ADONIS_GERALD")
						if gerald then
							gerald:Destroy()
						end
					end
				end
			end
		};

		wat = { --// wat??
			Prefix = "!";
			Commands = {"wat"};
			Args = {};
			Hidden = true;
			Description = "???";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local WOT = {3657191505, 754995791, 160715357, 4881542521, 227499602, 217714490, 130872377, 142633540, 259702986, 6884041159}
				Remote.Send(plr, "Function", "PlayAudio", WOT[math.random(1, #WOT)])
			end
		};

		YouBeenTrolled = {
			Prefix = "?";
			Commands = {"trolled", "freebobuc", "freedonor", "adminpls", "enabledonor"};--//add more :)
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "You've Been Trolled You've Been Trolled Yes You've Probably Been Told...";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Effect", {Mode = "trolling";})
			end
		};

		Trigger = {
			Prefix = Settings.Prefix;
			Commands = {"trigger"};
			Args = {"player"};
			Fun = true;
			Description = "Makes the target player really angry";
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v: Player in service.GetPlayers(plr, args[1]) do
					task.defer(function()
						local char = v.Character
						local head = char and char:FindFirstChild("Head")
						if head then
							service.New("Sound", {Parent = head; SoundId = "rbxassetid://429400881";}):Play()
							service.New("Sound", {Parent = head; Volume = 3; SoundId = "rbxassetid://606862847";}):Play()
							local face = head:FindFirstChild("face")
							if face then face.Texture = "rbxassetid://412416747" end
							head.BrickColor = BrickColor.new("Maroon")
							for i = 1, 10 do
								task.wait(0.1)
								head.Size *= 1.3
							end
							service.New("Explosion", {
								Parent = char;
								Position = head.Position;
								BlastRadius = 5;
								BlastPressure = 100_000;
							})
							service.New("Sound", {
								Parent = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso");
								SoundId = "rbxassetid://165969964";
								Volume = 10;
							}):Play()
							head:Destroy()
						end
					end)
				end
			end
		};

		Brazil = {
			Prefix = Settings.Prefix;
			Commands = {"brazil", "sendtobrazil"};
			Args = {"players"};
			AdminLevel = "Moderators";
			Fun = true;
			Description = "You're going to";
			Function = function (plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					local root = v.Character:FindFirstChild("HumanoidRootPart")
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://5816432987"
					sound.Volume = 10
					sound.PlayOnRemove = true
					sound.Parent = root
					sound:Destroy()
					task.wait(1.4)
					local vel = Instance.new("BodyVelocity")
					vel.Velocity = CFrame.new(root.Position - Vector3.new(0, 1, 0), root.CFrame.LookVector * 5 + root.Position).LookVector * 1500
					vel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
					vel.P = math.huge
					vel.Parent = root
					local smoke = Instance.new("ParticleEmitter")
					smoke.Enabled = true
					smoke.Lifetime = NumberRange.new(0, 3)
					smoke.Rate = 999999
					smoke.RotSpeed = NumberRange.new(0, 20)
					smoke.Rotation = NumberRange.new(0, 360)
					smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.25, 1.25), NumberSequenceKeypoint.new(1, 1.25, 1.25) })
					smoke.Speed = NumberRange.new(1, 1)
					smoke.SpreadAngle = Vector2.new(360, 360)
					smoke.Texture = "rbxassetid://642204234"
					smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) })
					smoke.Parent = root
					service.Debris:AddItem(smoke, 99)
					service.Debris:AddItem(vel, 99)
				end
			end
		};

		CharGear = {
			Prefix = Settings.Prefix;
			Commands = {"chargear", "charactergear", "doll", "cgear"};
			Args = {"player/username"};
			Fun = true;
			AdminLevel = "Moderators";
			Description = "Gives you a doll of a player";
			Function = function(plr: Player, args: {string})
				local plrChar = assert(plr.Character, "You don't have a character")
				local cfr = assert(plrChar:FindFirstChild("RightHand") or plrChar:FindFirstChild("Right Arm"), "You don't have a right hand/arm").CFrame

				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					Routine(function()
						local targetName = service.Players:GetNameFromUserIdAsync(v.UserId)

						local tool = service.New("Tool", {
							Name = targetName;
							ToolTip = "@"..targetName.." as a tool";
						})
						local handle = service.New("Part", {
							Parent = tool;
							Name = "Handle";
							CanCollide = false;
							Transparency = 1;
						})

						local model = service.Players:CreateHumanoidModelFromDescription(
							service.Players:GetHumanoidDescriptionFromUserId(v.UserId),
							Enum.HumanoidRigType.R15
						)
						model.Name = targetName

						local hum = model:WaitForChild("Humanoid")
						hum:WaitForChild("BodyHeightScale").Value /= 2
						hum:WaitForChild("BodyDepthScale").Value /= 2
						hum:WaitForChild("BodyWidthScale").Value /= 2

						if v ~= plr then
							handle.CFrame = cfr
						end

						model.Animate.Disabled = true

						for _, obj in model:GetDescendants() do
							if obj:IsA("BasePart") then
								obj.Massless = true
								obj.CanCollide = false
							end
						end

						model.Parent = tool
						if v ~= plr then
							model:PivotTo(cfr)
						end

						service.New("WeldConstraint", {
							Parent = tool;
							Part0 = handle;
							Part1 = model:FindFirstChild("Left Leg") or model:FindFirstChild("LeftFoot");
						})

						tool.Parent = plr:FindFirstChildWhichIsA("Backpack")
					end)
				end
			end
		};

		PlrGear = {
			Prefix = Settings.Prefix;
			Commands = {"playergear", "dollify", "pgear", "plrgear"};
			Args = {"player"};
			Fun = true;
			AdminLevel = "Moderators";
			Description = "Turns the target player into a doll which can be picked up";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					if not char then
						Functions.Hint(service.FormatPlayer(v).." has no character", {plr})
						continue
					end
					if char.Parent and char.Parent:IsA("Tool") then
						Functions.Hint(service.FormatPlayer(v).." is already a doll", {plr})
						continue
					end

					Routine(function()
						local tool = service.New("Tool", {
							Name = v.Name;
							ToolTip = service.FormatPlayer(v).." as a tool; converted using Adonis";
						})
						local handle = service.New("Part", {
							Parent = tool;
							Name = "Handle";
							Transparency = 1;
						})

						local charHum = char:FindFirstChildOfClass("Humanoid")
						local model = service.Players:CreateHumanoidModelFromDescription(
							service.Players:GetHumanoidDescriptionFromUserId(plr.UserId),
							if charHum then charHum.RigType else Enum.HumanoidRigType.R15
						)
						model.Name = v.DisplayName
						model.PrimaryPart = model:WaitForChild("HumanoidRootPart", 1)

						local pivot = char:GetPivot()
						char:Destroy()
						v.Character = model
						model:PivotTo(pivot)

						local hum = model:WaitForChild("Humanoid")
						hum:WaitForChild("BodyHeightScale").Value /= 2
						hum:WaitForChild("BodyDepthScale").Value /= 2
						hum:WaitForChild("BodyWidthScale").Value /= 2

						handle.CFrame = pivot
						handle.CanCollide = false
						for _, v in model:GetDescendants() do
							if v:IsA("BasePart") then
								v.Massless = true
							end
						end

						model.Parent = tool

						service.New("WeldConstraint", {
							Parent = tool;
							Part0 = handle;
							Part1 = model.PrimaryPart;
						})

						tool.Parent = workspace
					end)
				end
			end
		};

		LowRes = {
			Prefix = Settings.Prefix;
			Commands = {"lowres", "pixelrender", "pixel", "pixelize"};
			Args = {"player", "pixelSize", "renderDist"};
			Description = "Pixelizes the player's view";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local size = tonumber(args[2]) or 19
				local dist = tonumber(args[3]) or 100
				for i, v in service.GetPlayers(plr, args[1]) do
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

					for i, v in obj:GetChildren() do
						doPause(v)
					end
				end

				if not Variables.ZaWarudoDebounce then
					Variables.ZaWarudoDebounce = true
					task.delay(10, function() Variables.ZaWarudoDebounce = false end)
					if Variables.ZaWarudo then
						local audio = service.New("Sound", workspace)
						audio.SoundId = "rbxassetid://676242549"
						audio.Volume = 0.5
						audio:Play()
						task.wait(2)
						for i, part in Variables.FrozenObjects do
							part.Anchored = false
						end

						local old = service.Lighting:FindFirstChild("ADONIS_ZAWARUDO")
						if old then
							for i = -2, 0, 0.1 do
								old.Saturation = i
								task.wait(0.01)
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
						task.wait(2.25)
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
							task.wait(0.01)
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
				for i, v in service.GetPlayers(plr, args[1]) do
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
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "Dizzy", false)
				end
			end
		};

		Davey = {
			Prefix = Settings.Prefix;
			Commands = {"Davey_Bones"};
			Args = {"player"};
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "userid-698712377")
				end
			end
		};

		Boombox = {
			Prefix = Settings.Prefix;
			Commands = {"boombox"};
			Args = {"player"};
			Description = "Gives the target player(s) a boombox";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local gear = service.Insert(tonumber(212641536))
				if gear:IsA("BackpackItem") then
					service.New("StringValue", gear).Name = Variables.CodeName..gear.Name
					for i, v in service.GetPlayers(plr, args[1]) do
						if v:FindFirstChild("Backpack") then
							gear:Clone().Parent = v.Backpack
						end
					end
				end
			end
		};

		Infect = {
			Prefix = Settings.Prefix;
			Commands = {"infect", "zombify"};
			Args = {"player"};
			Description = "Turn the target player(s) into a suit zombie";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local infect; infect = function(v)
					local char = v.Character
					if char and char:FindFirstChild("HumanoidRootPart") and not char:FindFirstChild("Infected") then
						local cl = service.New("StringValue", char)
						cl.Name = "Infected"
						cl.Parent = char

						for _, prt in char:GetChildren() do
							if prt:IsA("BasePart") and prt.Name ~= "HumanoidRootPart" and (prt.Name ~= "Head" or not prt.Parent:FindFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Dark green")
								if prt.Name:find("Leg") or prt.Name:find("Arm") then
									prt.BrickColor = BrickColor.new("Dark green")
								end
								local tconn; tconn = prt.Touched:Connect(function(hit)
									if hit and hit.Parent and service.Players:FindFirstChild(hit.Parent.Name) and cl.Parent == char then
										infect(hit.Parent)
									elseif cl.Parent ~= char then
										tconn:Disconnect()
									end
								end)

								cl.Changed:Connect(function()
									if cl.Parent ~= char then
										tconn:Disconnect()
									end
								end)
							elseif prt:FindFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = 0
								prt.Head.BrickColor = BrickColor.new("Dark green")
							end
						end
					end
				end

				for i, v in service.GetPlayers(plr, args[1]) do
					infect(v)
				end
			end
		};

		Rainbowify = {
			Prefix = Settings.Prefix;
			Commands = {"rainbowify", "rainbow"};
			Args = {"player"};
			Description = "Make the target player(s)'s character flash random colors";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Core.NewScript("LocalScript",[[
					repeat
						task.wait(0.1)
						local char = script.Parent.Parent
						local clr = BrickColor.random()
						for i, v in char:GetChildren() do
							if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" and (v.Name ~= "Head" or not v.Parent:FindFirstChild("NameTag", true)) then
								v.BrickColor = clr
								v.Reflectance = 0
								v.Transparency = 0
							elseif v:FindFirstChild("NameTag") then
								v.Head.BrickColor = clr
								v.Head.Reflectance = 0
								v.Head.Transparency = 0
								v.Parent.Head.Transparency = 1
							end
						end
					until not char
				]])
				scr.Name = "Effectify"

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		Noobify = {
			Prefix = Settings.Prefix;
			Commands = {"noobify", "noob"};
			Args = {"player"};
			Description = "Make the target player(s) look like a noob";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				-- TODO: Switch to HumanoidDescriptions
				local bodyColors = service.New("BodyColors", {
					HeadColor = BrickColor.new("Bright yellow"),
					LeftArmColor = BrickColor.new("Bright yellow"),
					RightArmColor = BrickColor.new("Bright yellow"),
					LeftLegColor = BrickColor.new("Br. yellowish green"),
					RightLegColor = BrickColor.new("Br. yellowish green"),
					TorsoColor = BrickColor.new("Bright blue")
				})

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for _, p in v.Character:GetChildren() do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") or p:IsA("BodyColors") then
								p:Destroy()
							end
						end
						bodyColors:Clone().Parent = v.Character
					end
				end

				bodyColors:Destroy()
			end
		};

		Material = {
			Prefix = Settings.Prefix;
			Commands = {"mat", "material"};
			Args = {"player", "material"};
			Description = "Make the target the material you choose";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local mats = {
					Plastic = 256;
					Wood = 512;
					Slate = 800;
					Concrete = 816;
					CorrodedMetal = 1040;
					DiamondPlate = 1056;
					Foil = 1072;
					Grass = 1280;
					Ice = 1536;
					Marble = 784;
					Granite = 832;
					Brick = 848;
					Pebble = 864;
					Sand = 1296;
					Fabric = 1312;
					SmoothPlastic = 272;
					Metal = 1088;
					WoodPlanks = 528;
					Neon = 288;
				}
				local enumMats = Enum.Material:GetEnumItems()

				local chosenMat = args[2] or "Plastic"

				if not args[2] then
					Functions.Hint("Material wasn't supplied; Plastic was chosen instead")
				elseif tonumber(args[2]) then
					chosenMat = table.find(mats, tonumber(args[2]))
				end

				if not chosenMat then
					Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "Invalid material choice";})
					return
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for _, p in v.Character:GetChildren() do
							if p:IsA"BasePart" then
								p.Material = chosenMat
							end
						end
					end
				end
			end
		};

		Neon = {
			Prefix = Settings.Prefix;
			Commands = {"neon", "neonify"};
			Args = {"player", "(optional)color"};
			Description = "Make the target neon";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for _, p in v.Character:GetChildren() do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
								p:Destroy()
							elseif p:IsA("Part") then
								if args[2] then
									local str = BrickColor.new("Institutional white").Color
									local teststr = args[2]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
								p.Material = "Neon"
								if p.Name == "Head" then
									local mesh = p:FindFirstChild("Mesh")
									if mesh then mesh:Destroy() end
								end
							end
						end
					end
				end
			end
		};

		Ghostify = {
			Prefix = Settings.Prefix;
			Commands = {"ghostify", "ghost"};
			Args = {"player"};
			Description = "Turn the target player(s) into a ghost";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Admin.RunCommand(Settings.Prefix.."noclip", v.Name)

						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end

						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for _, prt in v.Character:GetChildren() do
							if prt:IsA("BasePart") and prt.Name ~= "HumanoidRootPart" and (prt.Name ~= "Head" or not prt.Parent:FindFirstChild("NameTag", true)) then
								prt.Transparency = .5
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Institutional white")
								if prt.Name:find("Leg") then
									prt.Transparency = 1
								end
							elseif prt:FindFirstChild("NameTag") then
								prt.Head.Transparency = .5
								prt.Head.Reflectance = 0
								prt.Head.BrickColor = BrickColor.new("Institutional white")
							end
						end
					end
				end
			end
		};

		Goldify = {
			Prefix = Settings.Prefix;
			Commands = {"goldify", "gold"};
			Args = {"player"};
			Description = "Make the target player(s) look like gold";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt.Parent = v.Character.HumanoidRootPart
						end

						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants.Parent = v.Character.HumanoidRootPart
						end

						for _, prt in v.Character:GetChildren() do
							if prt:IsA("BasePart") and prt.Name ~= "HumanoidRootPart" and (prt.Name ~= "Head" or not prt.Parent:FindFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = .4
								prt.BrickColor = BrickColor.new("Bright yellow")
							elseif prt:FindFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = .4
								prt.Head.BrickColor = BrickColor.new("Bright yellow")
							end
						end
					end
				end
			end
		};

		Shiney = {
			Prefix = Settings.Prefix;
			Commands = {"shiney", "shineify", "shine"};
			Args = {"player"};
			Description = "Make the target player(s)'s character shiney";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for _, prt in v.Character:GetChildren() do
							if prt:IsA("BasePart") and prt.Name ~= "HumanoidRootPart" and (prt.Name ~= "Head" or not prt.Parent:FindFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 1
								prt.BrickColor = BrickColor.new("Institutional white")
							elseif prt:FindFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = 1
								prt.Head.BrickColor = BrickColor.new("Institutional white")
							end
						end
					end
				end
			end
		};

		Spook = {
			Prefix = Settings.Prefix;
			Commands = {"spook"};
			Args = {"player"};
			Description = "Makes the target player(s)'s screen 2spooky4them";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Effect", {Mode = "Spooky";})
				end
			end
		};

		Thanos = {
			Prefix = Settings.Prefix;
			Commands = {"thanos", "thanossnap", "balancetheserver", "snap"};
			Args = {"player"};
			Description = "\"Fun isn't something one considers when balancing the universe. But this... does put a smile on my face.\"";
			Fun = true;
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

				task.wait()
				thanos:Destroy()--]]
				task.wait()
				audio:Destroy()

				if #playerList == 1 then
					local player = playerList[1]
					local tLevel = Admin.GetLevel(player)

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
								task.wait()
							end
						else
							break
						end
					end
				end

				for i, p in players do
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

								for k, v in p.Character:GetChildren() do
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
							task.wait(0.2)
						end

						task.wait(1)
						p:Kick("\n\n\"I don't feel so good\"\n")
					end)
				end
			end;
		};

		iloveyou = {
			Prefix = "?";
			Commands = {"iloveyou", "alwaysnear", "alwayswatching"};
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "I love you. You are mine. Do not fear; I will always be near.";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Effect", {Mode = "lifeoftheparty";})
			end
		};

		ifoundyou = {
			Prefix = Settings.Prefix;
			Commands = {"theycome", "fromanotherworld", "ufo", "abduct", "space", "newmexico", "area51", "rockwell"};
			Args = {"player"};
			Description = "A world unlike our own.";
			Fun = true;
			Hidden = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data)
				if not args[1] then
					local plrData = server.Core.GetPlayer(plr)
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

					local ind = plrData.SleepInParadise or 1
					plrData.SleepInParadise = ind + 1

					if ind == 14 then
						plrData.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for _, p in service.GetPlayers(plr, args[1]) do
					if not Admin.CheckAuthority(plr, p, string.rep("\u{2588}", 6), true) then
						continue
					end
					local char = p.Character
					if not char then
						Functions.Hint(service.FormatPlayer(p).." does not have a character", {plr})
						continue
					end
					local torso = char:FindFirstChild("HumanoidRootPart")
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if not (torso and humanoid) then
						Functions.Hint(service.FormatPlayer(p).." does not have a HumanoidRootPart/Humanoid", {plr})
						continue
					end
					if char:FindFirstChild("ADONIS_UFO") then
						continue
					end

					service.TrackTask("Thread: UFO", function()
						local ufo = server.Deps.Assets.UFO:Clone()
						local function check()
							if not ufo.Parent or p.Parent ~= service.Players or not torso.Parent or not humanoid.Parent or not char.Parent then
								return false
							end
							return true
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
						ufo:PivotTo(tPos*CFrame.new(0, 500, 0))

						spotLight.Enabled = false
						particles.Enabled = false
						beam.Transparency = 1

						ufo.Parent = p.Character

						task.wait()
						rotScript.Disabled = false

						for i = 1, 200 do
							if not check() then
								break
							else
								ufo:PivotTo(tPos*CFrame.new(0, 200-i, 0))
								task.wait(0.001*(i/5))
							end
						end

						if check() then
							task.wait(1)
							spotLight.Enabled = true
							particles.Enabled = true
							beam.Transparency = origBeamTrans
							beamSound:Play()

							local tween = service.TweenService:Create(torso, info, {
								CFrame = bay.CFrame*CFrame.new(0, 0, 0)
							})

							torso.Anchored = true
							tween:Play()

							for i, v in p.Character:GetChildren() do
								if v:IsA("BasePart") then
									service.TweenService:Create(v, TweenInfo.new(1), {
										Transparency = 1
									}):Play()
									--v:ClearAllChildren()
								end
							end

							task.wait(5)

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

							for i, v in p.Character:GetChildren() do
								if v:IsA("BasePart") then
									v.Anchored = true
									v.Transparency = 1
									pcall(function() v:FindFirstChildOfClass("Decal"):Destroy() end)
								elseif v:IsA("Accoutrement") then
									v:Destroy()
								end
							end

							task.wait(1)

							Remote.MakeGui(p, "Effect", {Mode = "FadeOut";})

							for i = 1, 260 do
								if not check() then
									break
								else
									ufo:PivotTo(tPos*CFrame.new(0, i, 0))
									--torso.CFrame = bay.CFrame*CFrame.new(0, 2, 0)
									task.wait(0.001*(i/5))
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
								task.wait(0.5)
								pcall(function() gui:Destroy() end)
							end
						end

						pcall(function() ufo:Destroy() end)
					end)
				end
			end;
		};

		Blind = {
			Prefix = Settings.Prefix;
			Commands = {"blind"};
			Args = {"player"};
			Description = "Blinds the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Effect", {Mode = "Blind";})
				end
			end
		};

		ScreenImage = {
			Prefix = Settings.Prefix;
			Commands = {"screenimage", "scrimage", "image"};
			Args = {"player", "textureid"};
			Description = "Places the desired image on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Effect", {
						Mode = "ScreenImage";
						Image = args[2];
					})
				end
			end
		};

		ScreenVideo = {
			Prefix = Settings.Prefix;
			Commands = {"screenvideo", "scrvid", "video"};
			Args = {"player", "videoid"};
			Description = "Places the desired video on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Effect", {Mode = "ScreenVideo"; video = args[2];})
				end
			end
		};

		UnEffect = {
			Prefix = Settings.Prefix;
			Commands = {"uneffect", "unimage", "uneffectgui", "unspook", "unblind", "unstrobe", "untrippy", "unpixelize", "unlowres", "unpixel", "undance", "unflashify", "unrainbowify", "guifix", "fixgui"};
			Args = {"player"};
			Description = "Removes any effect GUIs on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Remote.MakeGui(v, "Effect", {Mode = "Off";})
				end
			end
		};

		Forest = {
			Prefix = Settings.Prefix;
			Commands = {"forest", "sendtotheforest", "intothewoods"};
			Args = {"player"};
			Description = "Sends player to The Forest for a timeout";
			Fun = true;
			NoStudio = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				local players = service.GetPlayers(plr, args[1])
				for i, p in players do
					if not Admin.CheckAuthority(plr, p, "timeout") then
						table.remove(players, i)
					end
				end
				service.TeleportService:TeleportAsync(209424751, players)
			end
		};

		Maze = {
			Prefix = Settings.Prefix;
			Commands = {"maze", "sendtothemaze", "mazerunner"};
			Args = {"player"};
			Description = "Sends player to The Maze for a timeout";
			Fun = true;
			NoStudio = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				local players = service.GetPlayers(plr, args[1])
				for i, p in players do
					if not Admin.CheckAuthority(plr, p, "timeout") then
						table.remove(players, i)
						Functions.Hint("Unable to send "..service.FormatPlayer(p).." to The Maze (insufficient permission level)", {plr})
					end
				end
				service.TeleportService:TeleportAsync(280846668, players)
			end
		};

		ClownYoink = {
			Prefix = Settings.Prefix; 								-- Someone's always watching me
			Commands = {"clown", "yoink", "youloveme", "van"};   	-- Someone's always there
			Args = {"player"}; 										-- When I'm sleeping he just waits
			Description = "Clowns."; 								-- And he stares
			Fun = true; 											-- Someone's always standing in the
			Hidden = true; 											-- Darkest corner of my room
			AdminLevel = "Admins"; 									-- He's tall and wears a suit of black,
			Function = function(plr: Player, args: {string}, data) 	-- Dressed like the perfect groom
				if not args[1] then
					local plrData = server.Core.GetPlayer(plr)
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

					local ind = plrData.SleepInParadise or 1
					plrData.SleepInParadise = ind + 1

					if ind == 14 then
						plrData.SleepInParadise = 12
					end

					error(forYou[ind])
				end

				for _, p in service.GetPlayers(plr, args[1]) do
					if not Admin.CheckAuthority(plr, p, "clown", true) then
						continue
					end
					local char = p.Character
					if not char then
						Functions.Hint(service.FormatPlayer(p).." does not have a character", {plr})
						continue
					end
					local torso = char:FindFirstChild("HumanoidRootPart")
					local humanoid = char:FindFirstChildOfClass("Humanoid")
					if not (torso and humanoid) then
						Functions.Hint(service.FormatPlayer(p).." does not have a HumanoidRootPart/Humanoid", {plr})
						continue
					end
					if char:FindFirstChild("ADONIS_VAN") then
						continue
					end

					service.TrackTask("Thread: Clowns", function()
						local van = server.Deps.Assets.Van:Clone()

						local function check()
							if not van or not van.Parent or not p or p.Parent ~= service.Players or not torso or not humanoid or not torso.Parent or not humanoid.Parent or not char or not char.Parent then
								return false
							end
							return true
						end

						local driver = van.Driver
						local grabber = van.Clown
						local primary = van.Primary
						local door = van.Door
						local tPos = torso.CFrame

						local sound = service.New("Sound", {
							Parent = primary;
							SoundId = "rbxassetid://258529216";
							Looped = true;
						})
						sound:Play()

						local chuckle = service.New("Sound", {
							Parent = primary;
							SoundId = "rbxassetid://164516281";
							Volume = 0.25;
							Looped = true;
						})
						chuckle:Play()

						van.PrimaryPart = van.Primary
						van.Name = "ADONIS_VAN"
						van.Parent = workspace
						humanoid.Name = "NoResetForYou"
						humanoid.WalkSpeed = 0
						sound.Pitch = 1.3

						Remote.PlayAudio(p, 421358540, 0.2, 1, true)

						for i = 1, 200 do
							if not check() then
								break
							else
								van:PivotTo(tPos * (CFrame.new(-200+i, -1, -7) * CFrame.Angles(0, math.rad(270), 0)))
								task.wait(0.001*(i/5))
							end
						end

						sound.Pitch = 0.9

						task.wait(0.5)
						if check() then
							door.Transparency = 1
						end
						task.wait(0.5)

						if check() then
							torso.CFrame = primary.CFrame * (CFrame.new(0, 2.3, 0) * CFrame.Angles(0, math.rad(90), 0))
						end

						task.wait(0.5)
						if check() then
							door.Transparency = 0
						end
						task.wait(0.5)

						sound.Pitch = 1.3
						Remote.MakeGui(p, "Effect", {
							Mode = "FadeOut";
						})

						p.CameraMaxZoomDistance = 0.5

						for i = 1, 400 do
							if not check() then
								break
							else
								van:PivotTo(tPos * (CFrame.new(0+i, -1, -7) * CFrame.Angles(0, math.rad(270), 0)))
								torso.CFrame = primary.CFrame * (CFrame.new(0, 2.3, 0) * CFrame.Angles(0, math.rad(90), 0))
								task.wait(0.1/(i*5))

								if i == 270 then
									Remote.FadeAudio(p, 421358540, nil, nil, 0.5)
								end
							end
						end

						local gui = service.New("ScreenGui", {
							Parent = service.ReplicatedStorage;
							IgnoreGuiInset = true;
						})
						local bg = service.New("Frame", {
							Parent = gui;
							BackgroundTransparency = 0;
							BackgroundColor3 = Color3.new(0, 0, 0);
							Size = UDim2.fromScale(1, 1);
							Position = UDim2.fromScale(0, 0);
						})
						if p and p.Parent == service.Players then
							if service.RunService:IsStudio() then
								p:Kick("You were saved by the Studio environment.")
							else
								service.TeleportService:Teleport(527443962, p, nil, bg)
							end
						end
						task.wait(0.5)
						pcall(function() van:Destroy() end)
						pcall(function() gui:Destroy() end)
					end)
				end
			end
		};

		Chik3n = {
			Prefix = Settings.Prefix;
			Commands = {"chik3n", "zelith", "z3lith"};
			Args = {};
			Description = "Call on the KFC dark prophet powers of chicken";
			Fun = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr, args)
				local hats = {}
				local tempHats = {}
				local run = true
				local hat = service.Insert(24112667):GetChildren()[1]
				--
				local scr = Deps.Assets.Quacker:Clone()
				scr.Name = "Quacker"
				scr.Parent = hat
				--]]
				hat.Anchored = true
				hat.CanCollide = false
				hat.ChickenSounds.Disabled = true
				table.insert(hats, hat)
				table.insert(Variables.Objects, hat)
				hat.Parent = workspace
				hat.CFrame = plr.Character.Head.CFrame
				service.StopLoop("ChickenSpam")
				service.StartLoop("ChickenSpam", 5, function()
					tempHats = {}
					for i, v in hats do
						task.wait(0.5)
						if not hat or not hat.Parent or not scr or not scr.Parent then
							break
						end
						local nhat = hat:Clone()
						table.insert(tempHats, v)
						table.insert(tempHats, nhat)
						table.insert(Variables.Objects, nhat)
						nhat.Parent = workspace
						nhat.Quacker.Disabled = false
						nhat.CFrame = v.CFrame*CFrame.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))*CFrame.Angles(math.random(-360, 360), math.random(-360, 360), math.random(-360, 360))
					end
					hats = tempHats
				end)
				for i, v in tempHats do
					pcall(function() v:Destroy() end)
					table.remove(tempHats, i)
				end
				for i, v in hats do
					pcall(function() v:Destroy() end)
					table.remove(hats, i)
				end
			end;
		};

		Tornado = {
			Prefix = Settings.Prefix;
			Commands = {"tornado", "twister"};
			Args = {"player", "optional time"};
			Description = "Makes a tornado on the target player(s)";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local p = service.New("Part", workspace)
					table.insert(Variables.Objects, p)
					p.Transparency = 1
					p.CFrame = v.Character.HumanoidRootPart.CFrame+Vector3.new(0,-3, 0)
					p.Size = Vector3.new(0.2, 0.2, 0.2)
					p.Anchored = true
					p.CanCollide = false
					p.Archivable = false
					--local tornado = deps.Tornado:clone()
					--tornado.Parent = p
					--tornado.Disabled = false
					local cl = Core.NewScript("Script",[[
						local Pcall=function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=pcall(cour,...) if error then print('Error: '..error) end end
						local parts = {}
						local main=script.Parent
						main.Anchored=true
						main.CanCollide=false
						main.Transparency=1
						local smoke=Instance.new("Smoke", main)
						local sound=Instance.new("Sound", main)
						smoke.RiseVelocity=25
						smoke.Size=25
						smoke.Color=Color3.new(170/255, 85/255, 0)
						smoke.Opacity=1
						sound.SoundId="rbxassetid://142840797"
						sound.Looped=true
						sound:Play()
						sound.Volume=1
						sound.Pitch=0.8
						local light=Instance

						function fling(part)
							part:BreakJoints()
							part.Anchored=false
							local attachment = Instance.New("Attachment", part)
							local pos=Instance.new("AlignPosition", part)
							pos.MaxForce = math.huge
							pos.Position = part.Position
							pos.Attachment0 = attachment
							local i=1
							local run=true
							while main and wait() and run do
								if part.Position.Y>=main.Position.Y+50 then
									run=false
								end
								pos.position=Vector3.new(50*math.cos(i), part.Position.Y+5, 50*math.sin(i))+main.Position
								i=i+1
							end
							pos.maxForce = Vector3.new(500, 500, 500)
							pos.position=Vector3.new(main.Position.X+math.random(-100, 100), main.Position.Y+100, main.Position.Z+math.random(-100, 100))
							pos:Destroy()
						end

						function get(obj)
							if obj ~= main and obj:IsA("Part") then
								table.insert(parts, 1, obj)
							elseif obj:IsA("Model") or obj:IsA("Accoutrement") or obj:IsA("Tool") or obj == workspace then
								for i, v in obj:GetChildren() do
									Pcall(get, v)
								end
								obj.ChildAdded:Connect(function(p)Pcall(get, p)end)
							end
						end

						get(workspace)

						repeat
							for i, v in parts do
								if (((main.Position - v.Position).Magnitude * 250 * 20) < (5000 * 40)) and v and v:IsDescendantOf(workspace) then
									coroutine.wrap(fling, v)
								elseif not v or not v:IsDescendantOf(workspace) then
									table.remove(parts, i)
								end
							end
							main.CFrame = main.CFrame + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
							task.wait()
					until main.Parent ~= workspace or not main]])
					cl.Parent = p
					cl.Disabled = false
					if args[2] and tonumber(args[2]) then
						for i = 1, tonumber(args[2]) do
							if not p or not p.Parent then
								return
							end
							task.wait(1)
						end
						if p then p:Destroy() end
					end
				end
			end
		};

		Nuke = {
			Prefix = Settings.Prefix;
			Commands = {"nuke"};
			Args = {"player"};
			Description = "Nuke the target player(s)";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				local nukes = {}
				local partsHit = {}

				for i, v in Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						local p = service.New("Part", {
							Name = "ADONIS_NUKE";
							Anchored = true;
							CanCollide = false;
							formFactor = "Symmetric";
							Shape = "Ball";
							Size = Vector3.new(1, 1, 1);
							Position = human.Position;
							BrickColor = BrickColor.new("New Yeller");
							Transparency = .5;
							Reflectance = .2;
							TopSurface = 0;
							BottomSurface = 0;
							Parent = workspace.Terrain;
						})

						p.Touched:Connect(function(hit)
							if not partsHit[hit] then
								partsHit[hit] = true
								hit:BreakJoints()
								service.New("Explosion", {
									Position = hit.Position;
									BlastRadius = 10000;
									BlastPressure = math.huge;
									Parent = workspace.Terrain;
								})

							end
						end)

						table.insert(Variables.Objects, p)
						table.insert(nukes, p)
					end
				end

				for i = 1, 333 do
					for i, v in nukes do
						local curPos = v.CFrame
						v.Size = v.Size + Vector3.new(3, 3, 3)
						v.CFrame = curPos
					end
					task.wait(1/44)
				end

				for i, v in nukes do
					v:Destroy()
				end

				nukes = nil
				partsHit = nil
			end
		};

		UnWildFire = {
			Prefix = Settings.Prefix;
			Commands = {"stopwildfire", "removewildfire", "unwildfire"};
			Args = {};
			Description = "Stops :wildfire from spreading further";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				Variables.WildFire = nil
			end
		};

		WildFire = {
			Prefix = Settings.Prefix;
			Commands = {"wildfire"};
			Args = {"player"};
			Description = "Starts a fire at the target player(s); Ignores locked parts and parts named 'BasePlate' or 'Baseplate'";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				local finished = false
				local partsHit = {}
				local objs = {}

				Variables.WildFire = partsHit

				local function fire(part)
					if finished or not partsHit or not objs then
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and Variables.WildFire ~= partsHit then
						for i, v in objs do
							v:Destroy()
						end

						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and part:IsA("BasePart") and (not part.Locked or (part.Parent:IsA("Model") and service.Players:GetPlayerFromCharacter(part.Parent))) and part.Name ~= "BasePlate" and part.Name ~= "Baseplate" and not partsHit[part] then
						partsHit[part] = true

						local oColor = part.Color
						local fSize = (part.Size.X + part.Size.Y + part.Size.Z)
						local f = service.New("Fire", {
							Name = "WILD_FIRE";
							Size = fSize;
							Parent = part;
						})

						local l = service.New("PointLight", {
							Name = "WILD_FIRE";
							Range = fSize;
							Color = f.Color;
							Parent = part;
						})

						table.insert(objs, f)
						table.insert(objs, l)

						part.Touched:Connect(fire)

						for i = 0.1, 1, 0.1 do
							part.Color = oColor:lerp(Color3.new(0, 0, 0), i)
							task.wait(math.random(5))
						end

						local ex = service.New("Explosion", {
							Position = part.Position;
							BlastRadius = fSize*2;
							BlastPressure = 0;
						})

						ex.Hit:Connect(fire)
						ex.Parent = workspace.Terrain;
						part.Anchored = false
						part:BreakJoints()
						f:Destroy()
						l:Destroy()
					end
				end

				for i, v in Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						fire(human)
					end
				end

				partsHit = nil
			end
		};


		Swagify = {
			Prefix = Settings.Prefix;
			Commands = {"swagify", "swagger"};
			Args = {"player"};
			Description = "Swag the target player(s) up";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for _, v in v.Character:GetChildren() do
							if v.Name == "Shirt" then local cl = v:Clone() cl.Parent = v.Parent cl.ShirtTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
							if v.Name == "Pants" then local cl = v:Clone() cl.Parent = v.Parent cl.PantsTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
						end
						Functions.Cape(v, false, "Fabric", "Pink", 109301474)
					end
				end
			end
		};

		Shrek = {
			Prefix = Settings.Prefix;
			Commands = {"shrek", "shrekify", "shrekislife", "swamp"};
			Args = {"player"};
			Description = "Shrekify the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							Admin.RunCommand(Settings.Prefix.."pants", v.Name, "233373970")
							Admin.RunCommand(Settings.Prefix.."shirt", v.Name, "133078195")

							for _, v in v.Character:GetChildren() do
								if v:IsA("Accoutrement") or v:IsA("CharacterMesh") then
									v:Destroy()
								end
							end

							Admin.RunCommand(Settings.Prefix.."hat", v.Name, "20011951")

							local sound = service.New("Sound", v.Character.HumanoidRootPart)
							sound.SoundId = "http://www.roblox.com/asset/?id="..130767645
							task.wait(0.5)
							sound:Play()
						end
					end)
				end
			end
		};

		Rocket = {
			Prefix = Settings.Prefix;
			Commands = {"rocket", "firework"};
			Args = {"player"};
			Description = "Send the target player(s) to the moon!";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							local knownchar = v.Character
							local speed = 10
							local Part = service.New("Part")
							Part.Parent = v.Character
							local SpecialMesh = service.New("SpecialMesh")
							SpecialMesh.Parent = Part
							SpecialMesh.MeshId = "http://www.roblox.com/asset/?id=2251534"
							SpecialMesh.MeshType = "FileMesh"
							SpecialMesh.TextureId = "43abb6d081e0fbc8666fc92f6ff378c1"
							SpecialMesh.Scale = Vector3.new(0.5, 0.5, 0.5)
							local Weld = service.New("Weld")
							Weld.Parent = Part
							Weld.Part0 = Part
							Weld.Part1 = v.Character.HumanoidRootPart
							Weld.C0 = CFrame.new(0,-1, 0)*CFrame.Angles(-1.5, 0, 0)
							local BodyVelocity = service.New("BodyVelocity")
							BodyVelocity.Parent = Part
							BodyVelocity.maxForce = Vector3.new(math.huge, math.huge, math.huge)
							BodyVelocity.velocity = Vector3.new(0, 100*speed, 0)
									--[[
									cPcall(function()
										for i = 1, math.huge do
											local Explosion = service.New("Explosion")
											Explosion.Parent = Part
											Explosion.BlastRadius = 0
											Explosion.Position = Part.Position + Vector3.new(0, 0, 0)
											task.wait()
										end
									end)
									--]]
							task.wait(5)
							BodyVelocity:remove()
							if knownchar.Parent then
								service.New("Explosion", workspace.Terrain).Position = knownchar.HumanoidRootPart.Position
								knownchar:BreakJoints()
							end
						end
					end)
				end
			end
		};

		Dance = {
			Prefix = Settings.Prefix;
			Commands = {"dance"};
			Args = {"player"};
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChildOfClass("Humanoid") then
						local human = v.Character:FindFirstChildOfClass("Humanoid")
						local rigType = human and (human.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15") or nil
						Functions.PlayAnimation(v, rigType == "R6" and 27789359 or 507771019)
					end
				end
			end
		};

		BreakDance = {
			Prefix = Settings.Prefix;
			Commands = {"breakdance", "fundance", "lolwut"};
			Args = {"player"};
			Description = "Make the target player(s) break dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						local color
						local num = math.random(1, 7)
						if num == 1 then
							color = "Really blue"
						elseif num == 2 then
							color = "Really red"
						elseif num == 3 then
							color = "Magenta"
						elseif num == 4 then
							color = "Lime green"
						elseif num == 5 then
							color = "Hot pink"
						elseif num == 6 then
							color = "New Yeller"
						elseif num == 7 then
							color = "White"
						end
						local hum=v.Character:FindFirstChild("Humanoid")
						if not hum then return end
						--Remote.Send(v, "Function", "Effect", "dance")
						Admin.RunCommand(Settings.Prefix.."sparkles", v.Name, color)
						Admin.RunCommand(Settings.Prefix.."fire", v.Name, color)
						Admin.RunCommand(Settings.Prefix.."nograv", v.Name)
						Admin.RunCommand(Settings.Prefix.."smoke", v.Name, color)
						Admin.RunCommand(Settings.Prefix.."spin", v.Name)
						repeat hum.PlatformStand = true wait() until not hum or hum == nil or hum.Parent == nil
					end)
				end
			end
		};

		Puke = {
			Prefix = Settings.Prefix;
			Commands = {"puke", "barf", "throwup", "vomit"};
			Args = {"player"};
			Description = "Make the target player(s) puke";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						if not v:IsA("Player") or not v or not v.Character or not v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("Epix Puke") then return end
						local run = true
						local k = service.New("StringValue", v.Character)
						k.Name = "Epix Puke"
						Routine(function()
							repeat
								task.wait(0.07)
								local p = service.New("Part", v.Character)
								p.CanCollide = false
								local color = math.random(1, 3)
								local bcolor
								if color == 1 then
									bcolor = BrickColor.new(192)
								elseif color == 2 then
									bcolor = BrickColor.new(28)
								elseif color == 3 then
									bcolor = BrickColor.new(105)
								end
								p.BrickColor = bcolor
								local m = service.New("BlockMesh", p)
								p.Size = Vector3.new(0.1, 0.1, 0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.Head.CFrame * CFrame.new(Vector3.new(0, 0, -1))
								p.Velocity = v.Character.Head.CFrame.lookVector * 20 + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
								p.Anchored = false
								m.Name = "Puke Peice"
								p.Name = "Puke Peice"
								p.Touched:Connect(function(o)
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name ~= "Puke Peice" and o.Name ~= "Blood Peice" and o.Name ~= "Blood Plate" and o.Name ~= "Puke Plate" and (o.Parent:IsA("Workspace") or o.Parent:IsA("Model")) and (o.Parent ~= p.Parent) and o:IsA("Part") and (o.Parent.Name ~= v.Character.Name) and (not o.Parent:IsA("Accessory")) and (not o.Parent:IsA("Tool")) then
										local cf = CFrame.new(p.CFrame.X, o.CFrame.Y+o.Size.Y/2, p.CFrame.Z)
										p:Destroy()
										local g = service.New("Part", workspace.Terrain)
										g.Anchored = true
										g.CanCollide = false
										g.Size = Vector3.new(0.1, 0.1, 0.1)
										g.Name = "Puke Plate"
										g.CFrame = cf
										g.BrickColor = BrickColor.new(119)
										local c = service.New("CylinderMesh", g)
										c.Scale = Vector3.new(1, 0.2, 1)
										c.Name = "PukeMesh"
										task.wait(10)
										g:Destroy()
									elseif o and o.Name == "Puke Plate" and p then
										p:Destroy()
										o.PukeMesh.Scale = o.PukeMesh.Scale+Vector3.new(0.5, 0, 0.5)
									end
								end)
							until run == false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild("Head"))
						end)
						task.wait(12)
						run = false
						k:Destroy()
					end)
				end
			end
		};

		Cut = {
			Prefix = Settings.Prefix;
			Commands = {"cut", "stab", "shank", "bleed"};
			Args = {"player"};
			Description = "Make the target player(s) bleed";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						if not v:IsA("Player") or not v or not v.Character or not v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("ADONIS_BLEED") then return end
						local run = true
						local k = service.New("StringValue", v.Character)
						k.Name = "ADONIS_BLEED"
						Routine(function()
							repeat
								task.wait(0.15)
								v.Character.Humanoid.Health = v.Character.Humanoid.Health-1
								local p = service.New("Part", v.Character)
								p.CanCollide = false
								local color = math.random(1, 3)
								local bcolor
								if color == 1 or color == 3 then
									bcolor = BrickColor.new(21)
								elseif color == 2 then
									bcolor = BrickColor.new(1004)
								end
								p.BrickColor = bcolor
								local m=service.New("BlockMesh", p)
								p.Size = Vector3.new(0.1, 0.1, 0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(2, 0, 0))
								p.Velocity = v.Character.Head.CFrame.lookVector * 1 + Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
								p.Anchored = false
								m.Name = "Blood Peice"
								p.Name = "Blood Peice"
								p.Touched:Connect(function(o)
									if not o or not o.Parent then return end
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name ~= "Blood Peice" and o.Name ~= "Puke Peice" and o.Name ~= "Puke Plate" and o.Name ~= "Blood Plate" and (o.Parent:IsA("Workspace") or o.Parent:IsA("Model")) and (o.Parent ~= p.Parent) and o:IsA("Part") and (o.Parent.Name~=v.Character.Name) and (not o.Parent:IsA("Accessory")) and (not o.Parent:IsA("Tool")) then
										local cf = CFrame.new(p.CFrame.X, o.CFrame.Y+o.Size.Y/2, p.CFrame.Z)
										p:Destroy()
										local g = service.New("Part", workspace.Terrain)
										g.Anchored = true
										g.CanCollide = false
										g.Size = Vector3.new(0.1, 0.1, 0.1)
										g.Name = "Blood Plate"
										g.CFrame = cf
										g.BrickColor = BrickColor.new(21)
										local c = service.New("CylinderMesh", g)
										c.Scale = Vector3.new(1, 0.2, 1)
										c.Name = "BloodMesh"
										task.wait(10)
										g:Destroy()
									elseif o and o.Name == "Blood Plate" and p then
										p:Destroy()
										o.BloodMesh.Scale = o.BloodMesh.Scale+Vector3.new(0.5, 0, 0.5)
									end
								end)
							until run == false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild("Head"))
						end)
						task.wait(10)
						run = false
						k:Destroy()
					end)
				end
			end
		};

		Poison = {
			Prefix = Settings.Prefix;
			Commands = {"poison"};
			Args = {"player"};
			Description = "Slowly kills the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						local larm=v.Character:FindFirstChild("Left Arm")
						local rarm=v.Character:FindFirstChild("Right Arm")
						local lleg = v.Character:FindFirstChild("Left Leg")
						local rleg = v.Character:FindFirstChild("Right Leg")
						local head = v.Character:FindFirstChild("Head")
						local hum=v.Character:FindFirstChild("Humanoid")
						if torso and larm and rarm and lleg and rleg and head and hum and not v.Character:FindFirstChild("Adonis_Poisoned") then
							local poisoned = service.New("BoolValue", v.Character)
							poisoned.Name = "Adonis_Poisoned"
							poisoned.Value = true
							local tor = torso.BrickColor
							local lar = larm.BrickColor
							local rar = rarm.BrickColor
							local lle = lleg.BrickColor
							local rle = rleg.BrickColor
							local hea = head.BrickColor
							torso.BrickColor = BrickColor.new("Br. yellowish green")
							larm.BrickColor = BrickColor.new("Br. yellowish green")
							rarm.BrickColor = BrickColor.new("Br. yellowish green")
							lleg.BrickColor = BrickColor.new("Br. yellowish green")
							rleg.BrickColor = BrickColor.new("Br. yellowish green")
							head.BrickColor = BrickColor.new("Br. yellowish green")
							local run = true
							coroutine.wrap(function() wait(10) run = false end)()
							repeat
								task.wait(1)
								hum.Health = hum.Health-5
							until (not poisoned) or (not poisoned.Parent) or (not run)
							if poisoned and poisoned.Parent then
								torso.BrickColor = tor
								larm.BrickColor = lar
								rarm.BrickColor = rar
								lleg.BrickColor = lle
								rleg.BrickColor = rle
								head.BrickColor = hea
							end
						end
					end)
				end
			end
		};

		HatPets = {
			Prefix = Settings.Prefix;
			Commands = {"hatpets"};
			Args = {"player", "number[50 MAX]/destroy"};
			Description = "Gives the target player(s) hat pets, controlled using the "..Settings.PlayerPrefix.."pets command.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if args[2] and args[2]:lower() == "destroy" then
						local hats = v.Character:FindFirstChild("ADONIS_HAT_PETS")
						if hats then hats:Destroy() end
					else
						local num = tonumber(args[2]) or 5
						if num>50 then num = 50 end
						if v.Character:FindFirstChild("HumanoidRootPart") then
							local m = v.Character:FindFirstChild("ADONIS_HAT_PETS")
							local mode
							local obj
							local hat
							if not m then
								m = service.New("Model", v.Character)
								m.Name = "ADONIS_HAT_PETS"
								table.insert(Variables.Objects, m)
								mode = service.New("StringValue", m)
								mode.Name = "Mode"
								mode.Value = "Follow"
								obj = service.New("ObjectValue", m)
								obj.Name = "Target"
								obj.Value = v.Character.HumanoidRootPart

								local scr = Deps.Assets.HatPets:Clone()
								scr.Parent = m
								scr.Disabled = false
							else
								mode = m.Mode
								obj = m.Target
							end

							for _, h in v.Character:GetChildren() do
								if h:IsA("Accessory") then
									hat = h
									break
								end
							end

							if hat then
								for k = 1, num do
									local cl = hat.Handle:clone()
									cl.Name = k
									cl.CanCollide = false
									cl.Anchored = false
									cl.Parent = m
									cl:BreakJoints()
									local att = cl:FindFirstChild("HatAttachment")
									if att then att:Destroy() end
									local bpos = service.New("BodyPosition", cl)
									bpos.Name = "bpos"
									bpos.position = obj.Value.Position
									bpos.maxForce = bpos.maxForce * 10
								end
							end
						end
					end
				end
			end
		};

		Pets = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pets"};
			Args = {"follow/float/swarm/attack", "player"};
			Description = "Makes your hat pets do the specified command (follow/float/swarm/attack)";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local hats = plr.Character:FindFirstChild("ADONIS_HAT_PETS")
				if hats then
					for i, v in service.GetPlayers(plr, args[2]) do
						if v.Character:FindFirstChild("HumanoidRootPart") and v.Character.HumanoidRootPart:IsA("Part") then
							if args[1]:lower() == "follow" then
								hats.Mode.Value = "Follow"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "float" then
								hats.Mode.Value = "Float"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "swarm" then
								hats.Mode.Value = "Swarm"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "attack" then
								hats.Mode.Value = "Attack"
								hats.Target.Value = v.Character.HumanoidRootPart
							end
						end
					end
				else
					Functions.Hint("You don't have any hat pets! If you are an admin use the "..Settings.Prefix.."hatpets command to get some", {plr})
				end
			end
		};

		RestoreGravity = {
			Prefix = Settings.Prefix;
			Commands = {"grav", "bringtoearth"};
			Args = {"player"};
			Description = "Makes the target player(s)'s gravity normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in v.Character.HumanoidRootPart:GetChildren() do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end
					end
				end
			end
		};

		SetGravity = {
			Prefix = Settings.Prefix;
			Commands = {"setgrav", "gravity", "setgravity"};
			Args = {"player", "number"};
			Description = "Set the target player(s)'s gravity";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in v.Character.HumanoidRootPart:GetChildren() do
							if frc.Name == "ADONIS_GRAVITY" or frc.Name == "ADONIS_GRAVITY_ATTACHMENT" then
								frc:Destroy()
							end
						end
						local attachment = service.New("Attachment", v.Character.HumanoidRootPart)
						attachment.Name = "ADONIS_GRAVITY_ATTACHMENT"
						
						local frc = service.New("VectorForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.Attachment0 = attachment
						frc.Force = Vector3.new(0, 0, 0)
						for _, prt in v.Character:GetChildren() do
							if prt:IsA("BasePart") then
								frc.Force -= Vector3.new(0, prt:GetMass()*tonumber(args[2]), 0)
							elseif prt:IsA("Accoutrement") then
								frc.Force -= Vector3.new(0, prt.Handle:GetMass()*tonumber(args[2]), 0)
							end
						end
					end
				end
			end
		};

		NoGravity = {
			Prefix = Settings.Prefix;
			Commands = {"nograv", "nogravity", "superjump"};
			Args = {"player"};
			Description = "NoGrav the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in v.Character.HumanoidRootPart:GetChildren() do
							if frc.Name == "ADONIS_GRAVITY" or frc.Name == "ADONIS_GRAVITY_ATTACHMENT" then
								frc:Destroy()
							end
						end

						local attachment = service.New("Attachment", v.Character.HumanoidRootPart)
						attachment.Name = "ADONIS_GRAVITY_ATTACHMENT"
						
						local frc = service.New("VectorForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.Attachment0 = attachment
						frc.Force = Vector3.new(0, 0, 0)
						for _, prt in v.Character:GetChildren() do
							if prt:IsA("BasePart") then
								frc.Force += Vector3.new(0, prt:GetMass()*workspace.Gravity, 0)
							elseif prt:IsA("Accoutrement") then
								frc.Force += Vector3.new(0, prt.Handle:GetMass()*workspace.Gravity, 0)
							end
						end
					end
				end
			end
		};

		BunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"bunnyhop", "bhop"};
			Args = {"player"};
			Description = "Makes the player jump, and jump... and jump. Just like the rabbit noobs you find in sf games ;)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local bunnyScript = Deps.Assets.BunnyHop
				bunnyScript.Name = "HippityHopitus"
				local hat = service.Insert(110891941)
				for i, v in service.GetPlayers(plr, args[1]) do
					hat:Clone().Parent = v.Character
					local clone = bunnyScript:Clone()
					clone.Parent = v.Character
					clone.Disabled = false
				end
			end
		};

		UnBunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"unbunnyhop"};
			Args = {"player"};
			Description = "Stops the forced hippity hoppening";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					local scr = v.Character:FindFirstChild("HippityHopitus")
					if scr then
						scr.Disabled = true
						scr:Destroy()
					end
				end
			end
		};

		FreeFall = {
			Prefix = Settings.Prefix;
			Commands = {"freefall", "skydive"};
			Args = {"player", "height"};
			Description = "Teleport the target player(s) up by <height> studs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character:FindFirstChild("HumanoidRootPart") then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame+Vector3.new(0, tonumber(args[2]), 0)
					end
				end
			end
		};

		Stickify = {
			Prefix = Settings.Prefix;
			Commands = {"stickify", "stick", "stickman"};
			Args = {"player"};
			Description = "Turns the target player(s) into a stick figure";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for kay, player in service.GetPlayers(plr, args[1]) do
					local m = player.Character
					for i, v in m:GetChildren() do
						if v:IsA("Part") then
							local s = service.New("SelectionPartLasso")
							s.Parent = m.HumanoidRootPart
							s.Part = v
							s.Humanoid = m.Humanoid
							s.Color = BrickColor.new(0, 0, 0)
							v.Transparency = 1
							m.Head.Transparency = 0
							m.Head.Mesh:Remove()
							local b = service.New("SpecialMesh")
							b.Parent = m.Head
							b.MeshType = "Sphere"
							b.Scale = Vector3.new(0.5, 1, 1)
							m.Head.BrickColor = BrickColor.new("Black")
						end
					end
				end
			end
		};

		Hole = {
			Prefix = Settings.Prefix;
			Commands = {"hole", "sparta"};
			Args = {"player"};
			Description = "Sends the target player(s) down a hole";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for kay, player in service.GetPlayers(plr, args[1]) do
					Routine(function()
						local torso = player.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							local hole = service.New("Part", player.Character)
							hole.Anchored = true
							hole.CanCollide = false
							hole.formFactor = Enum.FormFactor.Custom
							hole.Size = Vector3.new(10, 1, 10)
							hole.CFrame = torso.CFrame * CFrame.new(0,-3.3,-3)
							hole.BrickColor = BrickColor.new("Really black")
							local holeM = service.New("CylinderMesh", hole)
							torso.Anchored = true
							local foot = torso.CFrame * CFrame.new(0,-3, 0)
							for i = 1, 10 do
								torso.CFrame = foot * CFrame.fromEulerAnglesXYZ(-(math.pi/2)*i/10, 0, 0) * CFrame.new(0, 3, 0)
								task.wait(0.1)
							end
							for i = 1, 5, 0.2 do
								torso.CFrame = foot * CFrame.new(0,-(i^2), 0) * CFrame.fromEulerAnglesXYZ(-(math.pi/2), 0, 0) * CFrame.new(0, 3, 0)
								task.wait()
							end
							player.Character:BreakJoints()
						end
					end)
				end
			end
		};

		Lightning = {
			Prefix = Settings.Prefix;
			Commands = {"lightning", "smite"};
			Args = {"player"};
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						Admin.RunCommand(Settings.Prefix.."freeze", v.Name)
						local char = v.Character
						local zeus = service.New("Model", char)
						local cloud = service.New("Part", zeus)
						cloud.Anchored = true
						cloud.CanCollide = false
						cloud.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 25, 0)
						local sound = service.New("Sound", cloud)
						sound.SoundId = "rbxassetid://133426162"
						local mesh = service.New("SpecialMesh", cloud)
						mesh.MeshId = "http://www.roblox.com/asset/?id=1095708"
						mesh.TextureId = "http://www.roblox.com/asset/?id=1095709"
						mesh.Scale = Vector3.new(30, 30, 40)
						mesh.VertexColor = Vector3.new(0.3, 0.3, 0.3)
						local light = service.New("PointLight", cloud)
						light.Color = Color3.new(0, 85/255, 1)
						light.Brightness = 10
						light.Range = 30
						light.Enabled = false
						task.wait(0.2)
						sound.Volume = 0.5
						sound.Pitch = 0.8
						sound:Play()
						light.Enabled = true
						task.wait(1/100)
						light.Enabled = false
						task.wait(0.2)
						light.Enabled = true
						light.Brightness = 1
						task.wait(0.05)
						light.Brightness = 3
						task.wait(0.02)
						light.Brightness = 1
						task.wait(0.07)
						light.Brightness = 10
						task.wait(0.09)
						light.Brightness = 0
						task.wait(0.01)
						light.Brightness = 7
						light.Enabled = false
						task.wait(1.5)
						local part1 = service.New("Part", zeus)
						part1.Anchored = true
						part1.CanCollide = false
						part1.Size = Vector3.new(2, 9.2, 1)
						part1.BrickColor = BrickColor.new("New Yeller")
						part1.Transparency = 0.6
						part1.BottomSurface = "Smooth"
						part1.TopSurface = "Smooth"
						part1.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 15, 0)
						part1.Rotation = Vector3.new(0.359, 1.4, -14.361)
						task.wait()
						local part2 = part1:clone()
						part2.Parent = zeus
						part2.Size = Vector3.new(1, 7.48, 2)
						part2.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 7.5, 0)
						part2.Rotation = Vector3.new(77.514, -75.232, 78.051)
						task.wait()
						local part3 = part1:clone()
						part3.Parent = zeus
						part3.Size = Vector3.new(1.86, 7.56, 1)
						part3.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 1, 0)
						part3.Rotation = Vector3.new(0, 0, -11.128)
						sound.SoundId = "rbxassetid://130818250"
						sound.Volume = 1
						sound.Pitch = 1
						sound:Play()
						task.wait()
						part1.Transparency = 1
						part2.Transparency = 1
						part3.Transparency = 1
						service.New("Smoke", char.HumanoidRootPart).Color = Color3.new(0, 0, 0)
						char:BreakJoints()
					end)
				end
			end
		};

		Disco = {
			Prefix = Settings.Prefix;
			Commands = {"disco"};
			Args = {};
			Description = "Turns the place into a disco party";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				service.StopLoop("LightingTask")
				service.StartLoop("LightingTask", 0.5, function()
					local color = Color3.new(math.random(255)/255, math.random(255)/255, math.random(255)/255)
					Functions.SetLighting("Ambient", color)
					Functions.SetLighting("OutdoorAmbient", color)
					Functions.SetLighting("FogColor", color)
				end)
			end
		};

		Spin = {
			Prefix = Settings.Prefix;
			Commands = {"spin"};
			Args = {"player"};
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, q in v.Character.HumanoidRootPart:GetChildren() do
							if q.Name == "SPINNER" or q.Name == "ADONIS_SPIN_GYRO" or q.Name == "ADONIS_SPIN_GYRO_ATTACHMENT" then
								q:Destroy()
							end
						end
						local spinGryoAttachment: Attachment = service.New("Attachment")
						local spinGryo: AlignOrientation = service.New("AlignOrientation")

						spinGryoAttachment.Name = "ADONIS_SPIN_GYRO_ATTACHMENT"
						spinGryoAttachment.Parent = v.Character.HumanoidRootPart

						spinGryo.Name = "ADONIS_SPIN_GYRO"
						spinGryo.Attachment0 = spinGryoAttachment
						spinGryo.MaxTorque = math.huge
						spinGryo.Mode = Enum.OrientationAlignmentMode.OneAttachment
						spinGryo.CFrame = v.Character.HumanoidRootPart.CFrame
						spinGryo.Parent = v.Character.HumanoidRootPart
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSpin = {
			Prefix = Settings.Prefix;
			Commands = {"unspin"};
			Args = {"player"};
			Description = "Makes the target player(s) stop spinning";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, q in v.Character.HumanoidRootPart:GetChildren() do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" or q.Name == "ADONIS_SPIN_GYRO_ATTACHMENT" then
								q:Destroy()
							end
						end
					end
				end
			end
		};

		Dog = {
			Prefix = Settings.Prefix;
			Commands = {"dog", "dogify"};
			Args = {"player"};
			Description = "Turn the target player(s) into a dog";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(p, args)
				for _, plr in service.GetPlayers(p, args[1]) do
					if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						local human = plr.Character:FindFirstChildOfClass("Humanoid")

						if not human then
							Remote.MakeGui(p, "Output", {Title = "Output"; Message = plr.Name.." doesn't have a Humanoid [Transformation Error]"})
							return
						end

						if human.RigType == Enum.HumanoidRigType.R6 then
							if plr.Character:FindFirstChild("Shirt") then
								plr.Character.Shirt.Parent = plr.Character.HumanoidRootPart
							end
							if plr.Character:FindFirstChild("Pants") then
								plr.Character.Pants.Parent = plr.Character.HumanoidRootPart
							end
							local char, torso, ca1, ca2 = plr.Character, plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("UpperTorso"), CFrame.Angles(0, math.rad(90), 0), CFrame.Angles(0, math.rad(-90), 0)
							local head = char:FindFirstChild("Head")

							torso.Transparency = 1

							for _, v in torso:GetChildren() do
								if v:IsA("Motor6D") then
									local lc0 = service.New("CFrameValue", {Name = "LastC0";Value = v.C0;Parent = v})
								end
							end

							torso.Neck.C0 = CFrame.new(0, -.5, -2) * CFrame.Angles(math.rad(90), math.rad(180), 0)

							torso["Right Shoulder"].C0 = CFrame.new(.5, -1.5, -1.5) * ca1
							torso["Left Shoulder"].C0 = CFrame.new(-.5, -1.5, -1.5) * ca2
							torso["Right Hip"].C0 = CFrame.new(1.5, -1, 1.5) * ca1
							torso["Left Hip"].C0 = CFrame.new(-1.5, -1, 1.5) * ca2
							local st = service.New("Seat", {
								Name = "Adonis_Torso",
								FormFactor = 0,
								TopSurface = 0,
								BottomSurface = 0,
								Size = Vector3.new(3, 1, 4),
							})

							local attachment = service.New("Attachment", {Parent = st})
							local bf = service.New("VectorForce", {Force = Vector3.new(0, 2e3, 0), Parent = st, Attachment0 = attachment})

							st.CFrame = torso.CFrame
							st.Parent = char

							local weld = service.New("Weld", {Parent = st, Part0 = torso, Part1 = st, C1 = CFrame.new(0, .5, 0)})

							for _, v in char:GetDescendants() do
								if v:IsA("BasePart") then
									v.BrickColor = BrickColor.new("Brown")
								end
							end
						elseif human.RigType == Enum.HumanoidRigType.R15 then
							Remote.MakeGui(p, "Output", {Title = "Output"; Message = "Cannot support R15 for "..plr.Name.." [Dog Transformation Error]"})
						end
					end
				end
			end
		};

		Dogg = {
			Prefix = Settings.Prefix;
			Commands = {"dogg", "snoop", "snoopify", "dodoubleg"};
			Args = {"player"};
			Description = "Turns the target into the one and only D O Double G";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Dogg:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2, 3, 0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=131396137"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://137545053"
				sound.Looped = true

				for i, v in service.GetPlayers(plr, args[1]) do
					local character = v.Character
					for k, p in character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					local headMesh = character.Head:FindFirstChild("Mesh")
					if headMesh then
						character.Head.Transparency = 0.9
						headMesh.Scale = Vector3.new(0.01, 0.01, 0.01)
					else
						character.Head.Transparency = 1
						for _, c in character.Head:GetChildren() do
							if c:IsA("Decal") then
								c.Transparency = 1
							elseif c:IsA("LayerCollector") then
								c.Enabled = false
							end
						end
					end

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Sp00ky = {
			Prefix = Settings.Prefix;
			Commands = {"sp00ky", "spooky", "spookyscaryskeleton"};
			Args = {"player"};
			Description = "Sends shivers down ur spine";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Sp00ks:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2, 3, 0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=183747890"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://174270407"
				sound.Looped = true

				for i, v in service.GetPlayers(plr, args[1]) do
					for k, p in v.Character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					local headMesh = v.Character.Head:FindFirstChild("Mesh")
					if headMesh then
						v.Character.Head.Transparency = 0.9
						headMesh.Scale = Vector3.new(0.01, 0.01, 0.01)
					else
						v.Character.Head.Transparency = 1
						for _, c in v.Character.Head:GetChildren() do
							if c:IsA("Decal") then
								c.Transparency = 1
							elseif c:IsA("LayerCollector") then
								c.Enabled = false
							end
						end
					end

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		K1tty = {
			Prefix = Settings.Prefix;
			Commands = {"k1tty", "cut3"};
			Args = {"player"};
			Description = "2 cute 4 u";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Kitty:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2, 3, 0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=280224764"
				decal1.Name = "Snoop"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"
				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://179393562"
				sound.Looped = true

				for i, v in service.GetPlayers(plr, args[1]) do
					for k, p in v.Character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					local headMesh = v.Character.Head:FindFirstChild("Mesh")
					if headMesh then
						v.Character.Head.Transparency = 0.9
						headMesh.Scale = Vector3.new(0.01, 0.01, 0.01)
					else
						v.Character.Head.Transparency = 1
						for _, c in v.Character.Head:GetChildren() do
							if c:IsA("Decal") then
								c.Transparency = 1
							elseif c:IsA("LayerCollector") then
								c.Enabled = false
							end
						end
					end

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Nyan = {
			Prefix = Settings.Prefix;
			Commands = {"nyan", "p0ptart"};
			Args = {"player"};
			Description = "Poptart kitty";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Nyan1:Clone()
				local c2 = Deps.Assets.Nyan2:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(0.1, 4.8, 20)

				local decal1 = service.New("Decal")
				decal1.Face = "Left"
				decal1.Texture = "http://www.roblox.com/asset/?id=332277963"
				decal1.Name = "Nyan"
				local decal2=decal1:clone()
				decal2.Face = "Right"
				decal2.Texture = "http://www.roblox.com/asset/?id=332288373"

				cl.Name = "Animator"
				c2.Name = "Animator"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://265125691"
				sound.Looped = true

				for i, v in service.GetPlayers(plr, args[1]) do
					for k, p in v.Character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01, 0.01, 0.01)

					cl:Clone().Parent = decal1
					c2:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Fr0g = {
			Prefix = Settings.Prefix;
			Commands = {"fr0g", "fr0ggy", "mlgfr0g", "mlgfrog"};
			Args = {"player"};
			Description = "MLG fr0g";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Fr0g:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2, 3, 0.1)
				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=185945467"
				decal1.Name = "Fr0g"

				cl.Name = "Animator"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://149690685"
				sound.Looped = true

				for i, v in service.GetPlayers(plr, args[1]) do
					for k, p in v.Character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01, 0.01, 0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Sh1a = {
			Prefix = Settings.Prefix;
			Commands = {"sh1a", "lab00f", "sh1alab00f", "shia"};
			Args = {"player"};
			Description = "Sh1a LaB00f";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local cl = Deps.Assets.Shia:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2, 3, 0.1)

				local decal1 = service.New("Decal")
				decal1.Face = "Back"
				decal1.Texture = "http://www.roblox.com/asset/?id=286117283"
				decal1.Name = "Shia"

				local decal2 = decal1:Clone()
				decal2.Face = "Front"

				local sound = service.New("Sound")
				sound.SoundId = "rbxassetid://259702986"
				sound.Looped = true

				cl.Name = "Animator"

				for i, v in service.GetPlayers(plr, args[1]) do
					for k, p in v.Character.HumanoidRootPart:GetChildren() do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats", v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible", v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01, 0.01, 0.01)

					cl:Clone().Parent = decal1
					cl:Clone().Parent = decal2

					decal1.Parent = v.Character.HumanoidRootPart
					decal2.Parent = v.Character.HumanoidRootPart
					sound.Parent = v.Character.HumanoidRootPart
					mesh.Parent = v.Character.HumanoidRootPart

					decal1.Animator.Disabled = false
					decal2.Animator.Disabled = false

					sound:Play()
				end
			end
		};

		Trail = {
			Prefix = Settings.Prefix;
			Commands = {"trail", "trails"};
			Args = {"player", "textureid", "color"};
			Description = "Adds trails to the target's character's parts";
			AdminLevel = "Moderators";
			Fun = true;
			Function = function(plr, args)
				assert(args[1], "Player argument missing")

				local color = Functions.ParseColor3(args[3])
				local colorSequence = ColorSequence.new(color or Color3.new(1, 1, 1))

				if not color and args[3] and (args[3]:lower() == "truecolors" or args[3]:lower() == "rainbow") then
					colorSequence = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
						ColorSequenceKeypoint.new(1/7, Color3.fromRGB(255, 136, 0)),
						ColorSequenceKeypoint.new(2/7, Color3.fromRGB(255, 228, 17)),
						ColorSequenceKeypoint.new(3/7, Color3.fromRGB(135, 255, 7)),
						ColorSequenceKeypoint.new(4/7, Color3.fromRGB(11, 255, 207)),
						ColorSequenceKeypoint.new(5/7, Color3.fromRGB(10, 46, 255)),
						ColorSequenceKeypoint.new(6/7, Color3.fromRGB(255, 55, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 127))
					}
				end

				for _, v in Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					for _, p in char:GetChildren() do
						if p:IsA("BasePart") then
							Functions.RemoveParticle(p, "ADONIS_CMD_TRAIL")

							local attachment0 = p:FindFirstChild("ADONIS_TRAIL_ATTACHMENT0") or service.New("Attachment", {
								Parent = p;
								Name = "ADONIS_TRAIL_ATTACHMENT0";
							})
							local attachment1 = p:FindFirstChild("ADONIS_TRAIL_ATTACHMENT1") or service.New("Attachment", {
								Position = Vector3.new(0,-0.05,0);
								Parent = p;
								Name = "ADONIS_TRAIL_ATTACHMENT1";
							})
							Functions.NewParticle(p, "Trail", {
								Color = colorSequence;
								Texture = tonumber(args[2]) and "rbxassetid://"..args[2];
								TextureMode = "Stretch";
								TextureLength = 2;
								Attachment0 = attachment0;
								Attachment1 = attachment1;
								Name = "ADONIS_CMD_TRAIL";
							})
						end
					end
				end
			end;
		};

		UnParticle = {
			Prefix = Settings.Prefix;
			Commands = {"unparticle", "removeparticles"};
			Args = {"player"};
			Description = "Removes particle emitters from target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "PARTICLE")
					end
				end
			end
		};

		Particle = {
			Prefix = Settings.Prefix;
			Commands = {"particle"};
			Args = {"player", "textureid", "startColor3", "endColor3"};
			Description = "Put custom particle emitter on target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				if not args[2] then error("Missing texture") end
				local startColor = {}
				local endColor = {}
				local startc = Color3.new(1, 1, 1)
				local endc = Color3.new(1, 1, 1)

				if args[3] then
					for s in args[3]:gmatch("[%d]+")do
						table.insert(startColor, tonumber(s))
					end
				end

				if args[4] then--276138620 :)
					for s in args[4]:gmatch("[%d]+")do
						table.insert(endColor, tonumber(s))
					end
				end

				if #startColor == 3 then
					startc = Color3.new(startColor[1], startColor[2], startColor[3])
				end

				if #endColor == 3 then
					endc = Color3.new(endColor[1], endColor[2], endColor[3])
				end

				for i, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "ParticleEmitter", {
							Name = "PARTICLE";
							Texture = "rbxassetid://".. Functions.GetTexture(args[2]);
							Size = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(1,.5);
							});
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(.9,.5,.25);
								NumberSequenceKeypoint.new(1, 1);
							});
							Lifetime = NumberRange.new(5);
							Speed = NumberRange.new(.5, 1);
							Rotation = NumberRange.new(0, 359);
							RotSpeed = NumberRange.new(-90, 90);
							Rate = 11;
							VelocitySpread = 180;
							Color = ColorSequence.new(startc, endc);
						})
					end
				end
			end
		};

		Flatten = {
			Prefix = Settings.Prefix;
			Commands = {"flatten", "2d", "flat"};
			Args = {"player", "optional num"};
			Description = "Flatten.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tonumber(args[2]) or 0.1

				local function sizePlayer(p)
					local char = p.Character
					local human = char:FindFirstChildOfClass("Humanoid")

					if human and human.RigType == Enum.HumanoidRigType.R15 then
						if human:FindFirstChild("BodyDepthScale") then
							human.BodyDepthScale.Value = 0.1
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local torso = char:FindFirstChild("Torso")
						local root = char:FindFirstChild("HumanoidRootPart")
						local welds = {}

						torso.Anchored = true
						torso.BottomSurface = 0
						torso.TopSurface = 0

						for _, v in char:GetChildren() do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end

						local function size(part)
							for _, v in part:GetChildren() do
								if (v:IsA("Weld") or v:IsA("Motor") or v:IsA("Motor6D")) and v.Part1 and v.Part1:IsA("Part") then
									local p1 = v.Part1
									local c0 = {v.C0:components()}
									local c1 = {v.C1:components()}

									c0[3] = c0[3]*num
									c1[3] = c1[3]*num

									p1.Anchored = true
									v.Part1 = nil

									v.C0 = CFrame.new(unpack(c0))
									v.C1 = CFrame.new(unpack(c1))

									if p1.Name ~= "Head" and p1.Name ~= "Torso" then
										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X, p1.Size.Y, num)
									elseif p1.Name ~= "Torso" then
										p1.Anchored = true
										for _, m in p1:GetChildren() do
											if m:IsA("Weld") then
												m.Part0 = nil
												m.Part1.Anchored = true
											end
										end

										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X, p1.Size.Y, num)

										for _, m in p1:GetChildren() do
											if m:IsA("Weld") then
												m.Part0 = p1
												m.Part1.Anchored = false
											end
										end
									end

									if v.Parent == torso then
										p1.BottomSurface = 0
										p1.TopSurface = 0
									end

									p1.Anchored = false
									v.Part1 = p1

									if v.Part0 == torso then
										table.insert(welds, v)
										p1.Anchored = true
										v.Part0 = nil
									end
								elseif v:IsA("CharacterMesh") then
									local bp = tostring(v.BodyPart):match("%w+.%w+.(%w+)")
									local msh = service.New("SpecialMesh")
								elseif v:IsA("SpecialMesh") and v.Parent ~= char.Head then
									v.Scale = Vector3.new(v.Scale.X, v.Scale.Y, num)
								end
								size(v)
							end
						end

						size(char)

						torso.formFactor = 3
						torso.Size = Vector3.new(torso.Size.X, torso.Size.Y, num)

						for i, v in welds do
							v.Part0 = torso
							v.Part1.Anchored = false
						end

						for i, v in char:GetChildren() do
							if v:IsA("BasePart") then
								v.Anchored = false
							end
						end

						local weld = service.New("Weld", root)
						weld.Part0 = root
						weld.Part1 = torso

						local cape = char:FindFirstChild("ADONIS_CAPE")
						if cape then
							cape.Size = cape.Size*num
						end
					end
				end

				for i, v in service.GetPlayers(plr, args[1]) do
					sizePlayer(v)
				end
			end
		};

		OldFlatten = {
			Prefix = Settings.Prefix;
			Commands = {"oldflatten", "o2d", "oflat"};
			Args = {"player", "optional num"};
			Description = "Old Flatten. Went lazy on this one.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						for _, p in v.Character:GetChildren() do
							if p:IsA("Part") then
								if p:FindFirstChild("Mesh") then p.Mesh:Destroy() end
								service.New("BlockMesh", p).Scale = Vector3.new(1, 1, args[2] or 0.1)
							elseif p:IsA("Accoutrement") and p:FindFirstChild("Handle") then
								if p.Handle:FindFirstChild("Mesh") then
									p.Handle.Mesh.Scale = Vector3.new(1, 1, args[2] or 0.1)
								else
									service.New("BlockMesh", p.Handle).Scale = Vector3.new(1, 1, args[2] or 0.1)
								end
							elseif p:IsA("CharacterMesh") then
								p:Destroy()
							end
						end
					end)
				end
			end
		};

		Sticky = {
			Prefix = Settings.Prefix;
			Commands = {"sticky"};
			Args = {"player"};
			Description = "Sticky";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					local event
					local torso = v.Character.HumanoidRootPart
					event = v.Character.HumanoidRootPart.Touched:Connect(function(p)
						if torso and torso.Parent and not p:IsDescendantOf(v.Character) and not p.Locked then
							Functions.MakeWeld(torso, p)
						elseif not torso or not torso.Parent then
							event:Disconnect()
						end
					end)
				end
			end
		};

		Break = {
			Prefix = Settings.Prefix;
			Commands = {"break"};
			Args = {"player", "optional num"};
			Description = "Break the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					cPcall(function()
						if v.Character then
							local head = v.Character.Head
							local torso = v.Character.HumanoidRootPart
							local larm = v.Character["Left Arm"]
							local rarm = v.Character["Right Arm"]
							local lleg = v.Character["Left Leg"]
							local rleg = v.Character["Right Leg"]
							for _, v in v.Character:GetChildren() do
								if v:IsA("Part") then v.Anchored = true end
							end
							torso.FormFactor = "Custom"
							torso.Size = Vector3.new(torso.Size.X, torso.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=v.Character.HumanoidRootPart
							weld.C0=v.Character.HumanoidRootPart.CFrame
							head.FormFactor = "Custom"
							head.Size = Vector3.new(head.Size.X, head.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=head
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(0, 1.5, 0)
							larm.FormFactor = "Custom"
							larm.Size = Vector3.new(larm.Size.X, larm.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=larm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1, 0, 0)
							rarm.FormFactor = "Custom"
							rarm.Size = Vector3.new(rarm.Size.X, rarm.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rarm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1, 0, 0)
							lleg.FormFactor = "Custom"
							lleg.Size = Vector3.new(larm.Size.X, larm.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=lleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1,-1.5, 0)
							rleg.FormFactor = "Custom"
							rleg.Size = Vector3.new(larm.Size.X, larm.Size.Y, tonumber(args[2]) or 0.1)
							local weld = service.New("Weld", v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1,-1.5, 0)
							task.wait()
							for _, v in v.Character:GetChildren() do
								if v:IsA("Part") then v.Anchored = false end
							end
						end
					end)
				end
			end
		};

		Skeleton = {
			Prefix = Settings.Prefix;
			Commands = {"skeleton"};
			Args = {"player"};
			Description = "Turn the target player(s) into a skeleton";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local hat = service.Insert(36883367)
				local players = service.GetPlayers(plr, args[1])
				for _, v in players do
					for _, m in v.Character:GetChildren() do
						if m:IsA("CharacterMesh") or m:IsA("Accoutrement") then
							m:Destroy()
						end
					end
					hat:Clone().Parent = v.Character
				end
				if #players > 0 then
					-- This is done outside of the for loop above as the Package command inserts all package items each time the command is run
					-- By only running it once, it's only inserting the items once and therefore reducing overhead
					local t = {}
					for _, v in players do
						table.insert(t, v.Name)
					end
					Admin.RunCommand(Settings.Prefix.."package "..table.concat(t, ",").." 295")
				end
			end
		};

		Creeper = {
			Prefix = Settings.Prefix;
			Commands = {"creeper", "creeperify"};
			Args = {"player"};
			Description = "Turn the target player(s) into a creeper";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
							local joints = Functions.GetJoints(v.Character)

							if v.Character:FindFirstChild("Shirt") then v.Character.Shirt.Parent = v.Character.HumanoidRootPart end
							if v.Character:FindFirstChild("Pants") then v.Character.Pants.Parent = v.Character.HumanoidRootPart end

							if joints["Neck"] then
								joints["Neck"].C0 = isR15 and CFrame.new(0, 1, 0) or (CFrame.new(0, 1, 0) * CFrame.Angles(math.rad(90), math.rad(180), 0))
							end

							local rarm = isR15 and joints["RightShoulder"] or joints["Right Shoulder"]
							if rarm then
								rarm.C0 = isR15 and CFrame.new(-1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0, math.rad(90), 0))
							end

							local larm = isR15 and joints["LeftShoulder"] or joints["Left Shoulder"]
							if larm then
								larm.C0 = isR15 and CFrame.new(1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0, math.rad(-90), 0))
							end

							local rleg = isR15 and joints["RightHip"] or joints["Right Hip"]
							if rleg then
								rleg.C0 = isR15 and (CFrame.new(-0.5,-0.5, 0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0, math.rad(90), 0))
							end

							local lleg = isR15 and joints["LeftHip"] or joints["Left Hip"]
							if lleg then
								lleg.C0 = isR15 and (CFrame.new(0.5,-0.5, 0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0, math.rad(-90), 0))
							end

							for _, part in v.Character:GetChildren() do
								if part:IsA("BasePart") then
									part.BrickColor = BrickColor.new("Bright green")
									if part.Name == "FAKETORSO" then
										part:Destroy()
									end
								elseif part:FindFirstChild("NameTag") then
									part.Head.BrickColor = BrickColor.new("Bright green")
								end
							end
						end
					end
				end
			end
		};

		BigHead = {
			Prefix = Settings.Prefix;
			Commands = {"bighead"};
			Args = {"player", "num"};
			Description = "Give the target player(s) a larger ego";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid")

						if human then
							if human.RigType == Enum.HumanoidRigType.R6 then
								v.Character.Head.Mesh.Scale = Vector3.new(1.75, 1.75, 1.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0, 1.3, 0) * CFrame.Angles(math.rad(90), math.rad(180), 0)
							else
								local scale = human and human:FindFirstChild("HeadScale")
								if scale then
									scale.Value = tonumber(args[2]) or 1.5
								end
							end
						end
					end
				end
			end
		};

		SmallHead = {
			Prefix = Settings.Prefix;
			Commands = {"smallhead", "minihead"};
			Args = {"player", "num"};
			Description = "Give the target player(s) a small head";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid")

						if human then
							if human.RigType == Enum.HumanoidRigType.R6 then
								v.Character.Head.Mesh.Scale = Vector3.new(.75,.75,.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0,.8, 0) * CFrame.Angles(math.rad(90), math.rad(180), 0)
							else
								local scale = human and human:FindFirstChild("HeadScale")
								if scale then
									scale.Value = tonumber(args[2]) or 0.5;
								end
							end
						end
					end
				end
			end
		};

		Resize = {
			Prefix = Settings.Prefix;
			Commands = {"resize", "size", "scale"};
			Args = {"player", "mult"};
			Description = "Resize the target player(s)'s character by <mult>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local sizeLimit = Settings.SizeLimit or 20
				local num = math.clamp(tonumber(args[2]) or 1, 0.001, sizeLimit) -- Size limit exceeding over 20 would be unnecessary and may potientially create massive lag !!

				if not args[2] or not tonumber(args[2]) then
					num = 1
					Functions.Hint("Size changed to 1 [Argument #2 (size multiplier) wasn't supplied correctly.]", {plr})
				elseif tonumber(args[2]) and tonumber(args[2]) > sizeLimit then
					Functions.Hint("Size changed to the maximum "..tostring(num).." [Argument #2 (size multiplier) went over the size limit]", {plr})
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChildOfClass("Humanoid")

					if not human then
						Functions.Hint("Cannot resize "..service.FormatPlayer(v).."'s character: humanoid and/or character doesn't exist!", {plr})
						continue
					end

					if not Variables.SizedCharacters[char] then
						Variables.SizedCharacters[char] = num
					elseif Variables.SizedCharacters[char] and Variables.SizedCharacters[char]*num < sizeLimit then
						Variables.SizedCharacters[char] = Variables.SizedCharacters[char]*num
					else
						Functions.Hint(string.format("Cannot resize %s's character by %f%%: size limit exceeded.", service.FormatPlayer(v), num*100), {plr})
						continue
					end

					if human and human.RigType == Enum.HumanoidRigType.R15 then
						for _, val in human:GetChildren() do
							if val:IsA("NumberValue") and val.Name:match(".*Scale") then
								val.Value *= num
							end
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local motors = {}
						table.insert(motors, char.HumanoidRootPart:FindFirstChild("RootJoint"))
						for _, motor in char.Torso:GetChildren() do
							if motor:IsA("Motor6D") then table.insert(motors, motor) end
						end
						for _, motor in motors do
							motor.C0 = CFrame.new((motor.C0.Position * num)) * (motor.C0 - motor.C0.Position)
							motor.C1 = CFrame.new((motor.C1.Position * num)) * (motor.C1 - motor.C1.Position)
						end

						for _, v in char:GetDescendants() do
							if v:IsA("BasePart") then
								v.Size *= num
							elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
								local handle = v.Handle
								handle.AccessoryWeld.C0 = CFrame.new((handle.AccessoryWeld.C0.Position * num)) * (handle.AccessoryWeld.C0 - handle.AccessoryWeld.C0.Position)
								handle.AccessoryWeld.C1 = CFrame.new((handle.AccessoryWeld.C1.Position * num)) * (handle.AccessoryWeld.C1 - handle.AccessoryWeld.C1.Position)
								local mesh = handle:FindFirstChildOfClass("SpecialMesh")
								if mesh then
									mesh.Scale *= num
								end
							elseif v:IsA("SpecialMesh") and v.Parent.Name ~= "Handle" and v.Parent.Name ~= "Head" then
								v.Scale *= num
							end
						end
					end
				end
			end
		};

		Seizure = {
			Prefix = Settings.Prefix;
			Commands = {"seizure"};
			Args = {"player"};
			Description = "Make the target player(s)'s character spazz out on the floor";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Deps.Assets.Seize
				scr.Name = "Seize"
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character:FindFirstChild("HumanoidRootPart") then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSeizure = {
			Prefix = Settings.Prefix;
			Commands = {"unseizure"};
			Args = {"player"};
			Description = "Removes the effects of the seizure command";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") then
						local old = v.Character.HumanoidRootPart:FindFirstChild("Seize")
						if old then old:Destroy() end
						v.Character.Humanoid.PlatformStand = false
					end
				end
			end
		};

		RemoveLimbs = {
			Prefix = Settings.Prefix;
			Commands = {"removelimbs", "delimb"};
			Args = {"player"};
			Description = "Remove the target player(s)'s arms and legs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						for a, obj in v.Character:GetChildren() do
							if obj:IsA("BasePart") and (obj.Name:find("Leg") or obj.Name:find("Arm")) then
								obj:Destroy()
							end
						end
					end
				end
			end
		};

		LoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"loopfling"};
			Args = {"player"};
			Description = "Loop flings the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					service.StartLoop(v.UserId.."LOOPFLING", 2, function()
						Admin.RunCommand(Settings.Prefix.."fling", v.Name)
					end)
				end
			end
		};

		UnLoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"unloopfling"};
			Args = {"player"};
			Description = "UnLoop Fling";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(v.UserId.."LOOPFLING")
				end
			end
		};

		Deadlands = {
			Prefix = Settings.Prefix;
			Commands = {"deadlands", "farlands", "renderingcyanide"};
			Args = {"player", "mult"};
			Description = "The edge of Roblox math; WARNING CAPES CAN CAUSE LAG";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local dist = 1000000 * (tonumber(args[2]) or 1.5)
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							Functions.UnCape(v)
							torso.CFrame = CFrame.new(dist, dist+10, dist)
							Admin.RunCommand(Settings.Prefix.."noclip", v.Name)
						end
					end
				end
			end
		};

		UnDeadlands = {
			Prefix = Settings.Prefix;
			Commands = {"undeadlands", "unfarlands", "unrenderingcyanide"};
			Args = {"player"};
			Description = "Clips the player and teleports them to you";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						local pTorso = plr.Character:FindFirstChild("HumanoidRootPart")
						if torso and pTorso and plr ~= v then
							Admin.RunCommand(Settings.Prefix.."clip", v.Name)
							task.wait(0.3)
							torso.CFrame = pTorso.CFrame*CFrame.new(0, 0, 5)
						else
							plr:LoadCharacter()
						end
					end
				end
			end
		};

		RopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"rope", "chain"};
			Args = {"player1", "player2", "length"};
			Description = "Connects players using a rope constraint";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				assert(args[1] and args[2], "Missing player names (must specify two)")
				for i, player1 in service.GetPlayers(plr, args[1]) do
					for i2, player2 in service.GetPlayers(plr, args[2]) do
						local torso1 = player1.Character:FindFirstChild("HumanoidRootPart")
						local torso2 = player2.Character:FindFirstChild("HumanoidRootPart")
						if torso1 and torso2 then
							local att1 = service.New("Attachment", torso1)
							local att2 = service.New("Attachment", torso2)
							local rope = service.New("RopeConstraint", torso1)

							att1.Name = "Adonis_Rope_Attachment";
							att2.Name = "Adonis_Rope_Attachment";
							rope.Name = "Adonis_Rope_Constraint";

							rope.Visible = true
							rope.Attachment0 = att1
							rope.Attachment1 = att2
							rope.Length = tonumber(args[3]) or 20
						end
					end
				end
			end;
		};

		UnRopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"unrope", "unchain"};
			Args = {"player"};
			Description = "UnRope";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, p in service.GetPlayers(plr, args[1]) do
					local torso = p.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						for i, v in torso:GetChildren() do
							if v.Name == "Adonis_Rope_Attachment" or v.Name == "Adonis_Rope_Constraint" then
								v:Destroy()
							end
						end
					end
				end
			end;
		};

		Headlian = {
			Prefix = Settings.Prefix;
			Commands = {"headlian", "beautiful"};
			Args = {"player"};
			Description = "hot";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				--{Left, right}--
				local faces = {
					477737479;
					477737542;
					477737607;
					477737705;
					477737766;
					477737856;
					477737394;
					477737230;
					477737111;
					477737019;
					476913612;
					476913523;
					476762259;
					476762307;
					476596314;
					476596271;
					476596231;
					476596193;
					476596141;
					476596110;
					476596484;
					475197261;
					475098996;
					475098974;
					475098946;
					475098926;
					475098906;
					475098892;
					475098877;
					475098826;
					475098809;
					475099023;
					475099039;
					475127779;
					475127982;
					466322174;
					466322170;
					466322165;
					466322160;
					466322149;
					466322155;
					466322109;
					466322115;
					466322127;
					466322139;
					466322137;
					466322143;
					466322107;
					466322100;
					466322094;
					464898017;
					464897989;
					464897899;
					464897871;
					464897826;
					464897791;
					464897735;
					464850359;
					464850241;
					464836234;
					464836592;
					464836707;
					464836958;
					459665424;
					459654933;
					459654870;
					459654346;
					459654157;
					455731264;
					436570797;
					455519408;
					455519497;
					455451293;
					455433153;
					455433334;
					451621075;
					441642820;
					441642684;
					441621737;
					441621370;
					437671929;
					437672060;
					436611230;
					436666773;
					436662014;
				}
				local arms = {
					{27493648, 27493629}; -- Alien
					{86500054, 86500036}; -- Man
					{86499716, 86499698}; -- Woman
					{36781447, 36781407}; -- Skeleton
					{32336182, 32336117}; -- Superhero
					{137715036, 137715073}; -- Polar bear
					{53980922, 53980889}; -- Gentleman robot
					{132896993, 132897065}; -- Witch
				}
				local legs = {
					{86499753, 86499793}; -- Woman
					{132897097, 132897160}; -- Witch
					{54116394, 54116432}; -- Mr Robot
					{232519786, 232519950}; -- Sir Kitty McPawnington
					{32357631, 32357663}; -- Slinger
					{293226935, 293227110}; -- Lillian
					{32336243, 32336306}; -- Superhero
					{27493683, 27493718}; -- Alien
					{28279894, 28279938}; -- Cool kid
					{136801087, 136801165}; -- Bludroid: Ev1LR0b0t
					{53980959, 53980996}; -- Gentleman robot
					{139607673, 139607718}; -- Korblox
					{143624963, 143625109}; -- Team ROBLOX Parka
					{77517631, 77517683}; -- Empyrean Armor
					{128157317, 128157361}; -- Telamon's Business Casual
					{86500078, 86500064}; -- Man
					{27112056, 27112068}; -- Roblox 2.0
				}

				local function clear(char)
					for i, v in char:GetChildren() do
						if v:IsA("CharacterMesh") or v:IsA("Accoutrement") or v:IsA("ShirtGraphic") or v:IsA("Pants") or v:IsA("Shirt") then
							v:Destroy()
						end
					end
				end

				local function apply(char)
					local color = BrickColor.new(Color3.new(math.random(), math.random(), math.random()))
					local face = faces[math.random(1,#faces)]
					local arms = arms[math.random(1,#arms)]
					local legs = legs[math.random(1,#legs)]
					local la, ra = arms[1], arms[2]
					local ll, rl = legs[1], legs[2]
					local head = char:FindFirstChild("Head")
					local bodyColors = char:FindFirstChild("Body Colors")
					if head then
						local old = head:FindFirstChild("Mesh")
						if old then old:Destroy() end
						local mesh = service.New("SpecialMesh", head)
						mesh.MeshType = "FileMesh"
						mesh.MeshId = "http://www.roblox.com/asset/?id=134079402"
						mesh.TextureId = "http://www.roblox.com/asset/?id=133940918"
					end
					if bodyColors then
						bodyColors.HeadColor = color
						bodyColors.LeftArmColor = color
						bodyColors.LeftLegColor = color
						bodyColors.RightArmColor = color
						bodyColors.RightLegColor = color
						bodyColors.TorsoColor = color
					end
					service.Insert(la).Parent = char
					service.Insert(ra).Parent = char
					service.Insert(ll).Parent = char
					service.Insert(rl).Parent = char
					service.Insert(face).Parent = char
				end

				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						clear(v.Character)
						apply(v.Character)
					end
				end
			end
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
				for _, v in service.GetPlayers(plr, args[1]) do
					service.ChatService:Chat(v.Character.Head, message, Enum.ChatColor.Blue)
				end
			end
		};

		IceFreeze = {
			Prefix = Settings.Prefix;
			Commands = {"ice", "iceage", "icefreeze", "funfreeze"};
			Args = {"player"};
			Description = "Freezes the target player(s) in a block of ice";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							for _, obj in v.Character:GetChildren() do
								if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then obj.Anchored = true end
							end
							local ice = service.New("Part", v.Character)
							ice.BrickColor = BrickColor.new("Steel blue")
							ice.Material = "Ice"
							ice.Name = "Adonis_Ice"
							ice.Anchored = true
							--ice.CanCollide = false
							ice.TopSurface = "Smooth"
							ice.BottomSurface = "Smooth"
							ice.FormFactor = "Custom"
							ice.Size = Vector3.new(5, 6, 5)
							ice.Transparency = 0.3
							ice.CFrame = v.Character.HumanoidRootPart.CFrame
						end
					end)
				end
			end
		};

		Fire = {
			Prefix = Settings.Prefix;
			Commands = {"fire", "makefire", "givefire"};
			Args = {"player", "color"};
			Description = "Sets the target player(s) on fire, coloring the fire based on what you server";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)
				local secondary = Color3.new(1, 0, 0)

				if args[2] then
					local str = BrickColor.new("Bright orange").Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
					secondary = str
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Fire", {
							Name = "FIRE";
							Color = color;
							SecondaryColor = secondary;
						})
						Functions.NewParticle(torso, "PointLight", {
							Name = "FIRE_LIGHT";
							Color = color;
							Range = 15;
							Brightness = 5;
						})
					end
				end
			end
		};

		UnFire = {
			Prefix = Settings.Prefix;
			Commands = {"unfire", "removefire", "extinguish"};
			Args = {"player"};
			Description = "Puts out the flames on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "FIRE")
						Functions.RemoveParticle(torso, "FIRE_LIGHT")
					end
				end
			end
		};

		Smoke = {
			Prefix = Settings.Prefix;
			Commands = {"smoke", "givesmoke"};
			Args = {"player", "color"};
			Description = "Makes smoke come from the target player(s) with the desired color";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)

				if args[2] then
					local str = BrickColor.new("White").Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Smoke", {
							Name = "SMOKE";
							Color = color;
						})
					end
				end
			end
		};

		UnSmoke = {
			Prefix = Settings.Prefix;
			Commands = {"unsmoke"};
			Args = {"player"};
			Description = "Removes smoke from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "SMOKE")
					end
				end
			end
		};

		Sparkles = {
			Prefix = Settings.Prefix;
			Commands = {"sparkles"};
			Args = {"player", "color"};
			Description = "Puts sparkles on the target player(s) with the desired color";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local color = Color3.new(1, 1, 1)

				if args[2] then
					local str = BrickColor.new("Cyan").Color
					local teststr = args[2]

					if BrickColor.new(teststr) ~= nil then
						str = BrickColor.new(teststr).Color
					end

					color = str
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso, "Sparkles", {
							Name = "SPARKLES";
							SparkleColor = color;
						})
						Functions.NewParticle(torso, "PointLight", {
							Name = "SPARKLES_LIGHT";
							Color = color;
							Range = 15;
							Brightness = 5;
						})
					end
				end
			end
		};

		UnSparkles = {
			Prefix = Settings.Prefix;
			Commands = {"unsparkles"};
			Args = {"player"};
			Description = "Removes sparkles from the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "SPARKLES")
						Functions.RemoveParticle(torso, "SPARKLES_LIGHT")
					end
				end
			end
		};

		Animation = {
			Prefix = Settings.Prefix;
			Commands = {"animation", "loadanim", "animate"};
			Args = {"player", "animationID"};
			Description = "Load the animation onto the target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")

				for _, v in service.GetPlayers(plr, args[1]) do
					Functions.PlayAnimation(v , args[2])
				end
			end
		};

		WalkAnimation = {
			Prefix = Settings.Prefix;
			Commands = {"walkanimation", "walkanim"};
			Args = {"player", "animationID"};
			Description = "Change the target player(s)'s walk animation, based on the default animation system. Supports 'R15' and 'R6' as animationID argument to use default rig animation.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				local animId

				if not (args[2] == "R15" or args[2] == "R6") then
					assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")
					animId = args[2]
				elseif args[2] == "R15" then
					animId = "507777826" -- Default R15 animation
				elseif args[2] == "R6" then
					animId = "180426354"
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _, v2 in animateScript:GetDescendants() do
								if v2.Name == "walk" then
									found = true
									local walkAnimation = v2:FindFirstChildOfClass("Animation")
									if walkAnimation then
										walkAnimation.AnimationId = "rbxassetid://" .. animId
									else
										local walkAnimation = Instance.new("Animation")
										walkAnimation.Name = "WalkAnim" -- Name actually doesn't matter, but I just name it like the default one.
										walkAnimation.AnimationId = "rbxassetid://" .. animId
										walkAnimation.Parent = v2
									end
								end
							end

							if not (found) then
								assert(nil, "Instance 'StringValue' named 'walk' was not found. Please note, this command is designed for the default animation system.")
							end
						else
							assert(nil, "Target player does not have the 'Animate' LocalScript")
						end
					end
				end
			end
		};

		RunAnimation = {
			Prefix = Settings.Prefix;
			Commands = {"runanimation", "runanim"};
			Args = {"player", "animationID"};
			Description = "Change the target player(s)'s run animation, based on the default animation system. Supports 'R15' as animationID argument to use default rig animation.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				local animId

				if not (args[2] == "R15" or args[2] == "R6") then
					assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")
					animId = args[2]
				elseif args[2] == "R15" then
					animId = "507767714"
				elseif args[2] == "R6" then
					animId = "180426354"
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _,v2 in animateScript:GetDescendants() do
								if v2.Name == "run" then
									found = true
									local runAnimation = v2:FindFirstChildOfClass("Animation")
									if runAnimation then
										runAnimation.AnimationId = "rbxassetid://" .. animId
									else
										local runAnimation = Instance.new("Animation")
										runAnimation.Name = "RunAnim"
										runAnimation.AnimationId = "rbxassetid://" .. animId
										runAnimation.Parent = v2
									end
								end
							end

							if not (found) then
								assert(nil, "Instance 'StringValue' named 'run' was not found. Please note, this command is designed for the default animation system.")
							end
						else
							assert(nil, "Target player does not have the 'Animate' LocalScript")
						end
					end
				end
			end
		};

		JumpAnimation = {
			Prefix = Settings.Prefix;
			Commands = {"jumpanimation", "jumpanim"};
			Args = {"player", "animationID"};
			Description = "Change the target player(s)'s jump animation, based on the default animation system. Supports 'R15' as animationID argument to use default rig animation.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				local animId

				if not (args[2] == "R15" or args[2] == "R6") then
					assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")
					animId = args[2]
				elseif args[2] == "R15" then
					animId = "507765000"
				elseif args[2] == "R6" then
					animId = "125750702"
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _, v2 in animateScript:GetDescendants() do
								if v2.Name == "jump" then
									found = true
									local jumpAnimation = v2:FindFirstChildOfClass("Animation")
									if jumpAnimation then
										jumpAnimation.AnimationId = "rbxassetid://" .. animId
									else
										local jumpAnimation = Instance.new("Animation")
										jumpAnimation.Name = "JumpAnim"
										jumpAnimation.AnimationId = "rbxassetid://" .. animId
										jumpAnimation.Parent = v2
									end
								end
							end

							if not (found) then
								assert(nil, "Instance 'StringValue' named 'jump' was not found. Please note, this command is designed for the default animation system.")
							end
						else
							assert(nil, "Target player does not have the 'Animate' LocalScript")
						end
					end
				end
			end
		};

		FallAnimation = {
			Prefix = Settings.Prefix;
			Commands = {"fallanimation", "fallanim"};
			Args = {"player", "animationID"};
			Description = "Change the target player(s)'s fall animation, based on the default animation system. Supports 'R15' as animationID argument to use default rig animation.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				if args[1] and not args[2] then args[2] = args[1] args[1] = nil end

				local animId

				if not (args[2] == "R15" or args[2] == "R6") then
					assert(tonumber(args[2]), tostring(args[2]).." is not a valid ID")
					animId = args[2]
				elseif args[2] == "R15" then
					animId = "507767968"
				elseif args[2] == "R6" then
					animId = "180436148"
				end

				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _,v2 in animateScript:GetDescendants() do
								if v2.Name == "fall" then
									found = true
									local fallAnimation = v2:FindFirstChildOfClass("Animation")
									if fallAnimation then
										fallAnimation.AnimationId = "rbxassetid://" .. animId
									else
										local fallAnimation = Instance.new("Animation")
										fallAnimation.Name = "FallAnim"
										fallAnimation.AnimationId = "rbxassetid://" .. animId
										fallAnimation.Parent = v2
									end
								end
							end

							if not (found) then
								assert(nil, "Instance 'StringValue' named 'fall' was not found. Please note, this command is designed for the default animation system.")
							end
						else
							assert(nil, "Target player does not have the 'Animate' LocalScript")
						end
					end
				end
			end
		};

		BlurEffect = {
			Prefix = Settings.Prefix;
			Commands = {"blur", "screenblur", "blureffect"};
			Args = {"player", "blur size"};
			Description = "Blur the target player's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local moder = tonumber(args[2]) or 0.5
				if moder > 5 then moder = 5 end
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.NewLocal(v, "BlurEffect", {
						Name = "WINDOW_BLUR",
						Size = tonumber(args[2]) or 24,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		BloomEffect = {
			Prefix = Settings.Prefix;
			Commands = {"bloom", "screenbloom", "bloomeffect"};
			Args = {"player", "intensity", "size", "threshold"};
			Description = "Give the player's screen the bloom lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.NewLocal(v, "BloomEffect", {
						Name = "WINDOW_BLOOM",
						Intensity = tonumber(args[2]) or 0.4,
						Size = tonumber(args[3]) or 24,
						Threshold = tonumber(args[4]) or 0.95,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		SunRaysEffect = {
			Prefix = Settings.Prefix;
			Commands = {"sunrays", "screensunrays", "sunrayseffect"};
			Args = {"player", "intensity", "spread"};
			Description = "Give the player's screen the sunrays lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.NewLocal(v, "SunRaysEffect", {
						Name = "WINDOW_SUNRAYS",
						Intensity = tonumber(args[2]) or 0.25,
						Spread = tonumber(args[3]) or 1,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		ColorCorrectionEffect = {
			Prefix = Settings.Prefix;
			Commands = {"colorcorrect", "colorcorrection", "correctioneffect", "correction", "cce"};
			Args = {"player", "brightness", "contrast", "saturation", "tint"};
			Description = "Give the player's screen the sunrays lighting effect";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				local r, g, b = 1, 1, 1
				if args[5] and args[5]:match("(.*),(.*),(.*)") then
					r, g, b = args[5]:match("(.*),(.*),(.*)")
				end
				r, g, b = tonumber(r), tonumber(g), tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				for _, p in service.GetPlayers(plr, args[1]) do
					Remote.NewLocal(p, "ColorCorrectionEffect", {
						Name = "WINDOW_COLORCORRECTION",
						Brightness = tonumber(args[2]) or 0,
						Contrast = tonumber(args[3]) or 0,
						Saturation = tonumber(args[4]) or 0,
						TintColor = Color3.new(r, g, b),
						Enabled = true,
					}, "Camera")
				end
			end
		};

		Freaky = {
			Prefix = Settings.Prefix;
			Commands = {"freaky"};
			Args = {"0-600,0-600,0-600", "optional player"};
			Description = "Does freaky stuff to lighting. Like a messed up ambient.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local r, g, b = 100, 100, 100
				if args[1] and args[1]:match("(.*),(.*),(.*)") then
					r, g, b = args[1]:match("(.*),(.*),(.*)")
				end
				r, g, b = tonumber(r), tonumber(g), tonumber(b)
				if not r or not g or not b then error("Invalid Input") end
				local num1, num2, num3 = r, g, b
				num1 = "-"..num1.."00000"
				num2 = "-"..num2.."00000"
				num3 = "-"..num3.."00000"
				if args[2] then
					for i, v in service.GetPlayers(plr, args[2]) do
						Remote.SetLighting(v, "FogColor", Color3.new(tonumber(num1), tonumber(num2), tonumber(num3)))
						Remote.SetLighting(v, "FogEnd", 9e9)
					end
				else
					Functions.SetLighting("FogColor", Color3.new(tonumber(num1), tonumber(num2), tonumber(num3)))
					Functions.SetLighting("FogEnd", 9e9) --Thanks go to Janthran for another neat glitch
				end
			end
		};

		LoadSky = {
			Prefix = Settings.Prefix;
			Commands = {"loadsky", "skybox"};
			Args = {"front", "back", "left", "right", "up", "down", "celestialBodies? (default: true)", "starCount (default: 3000)"};
			Description = "Change the skybox front with the provided image IDs";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.Lighting:GetChildren() do
					if v:IsA("Sky") then v:Destroy() end
				end
				local sky = service.New("Sky", service.Lighting)
				for i, v in {"Ft", "Bk", "Lf", "Rt", "Up", "Dn"} do
					local img = args[i] or args[1]
					if img --[[and (v ~= "Dn" or args[6])]] then
						sky["Skybox"..v] = tonumber(img) and ("rbxassetid://"..img) or img
					end
				end
				if args[7] and args[7]:lower() == "false" then
					sky.CelestialBodiesShown = false
				end
				if tonumber(args[8]) then
					sky.StarCount = tonumber(args[8])
				end
				Functions.Hint("Created new sky", {plr})
			end
		};

		StarterGear = {
			Prefix = Settings.Prefix;
			Commands = {"startergear", "givestartergear"};
			Args = {"player", "id"};
			Description = "Inserts the desired gear into the target player(s)'s starter gear";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local gearID = assert(tonumber(args[2]), "Invalid ID (not Number?)")
				local AssetIdType = service.MarketPlace:GetProductInfo(gearID).AssetTypeId

				if AssetIdType == 19 then
					local gear = service.Insert(gearID)

					if gear:IsA("BackpackItem") then
						service.New("StringValue", gear).Name = Variables.CodeName..gear.Name
						for i, v in service.GetPlayers(plr, args[1]) do
							if v:FindFirstChild("StarterGear") then
								gear:Clone().Parent = v.StarterGear
							end
						end
					end
				else
					error("Invalid ID provided, Not AssetType Gear.", 0)
				end
			end
		};

		Gear = {
			Prefix = Settings.Prefix;
			Commands = {"gear", "givegear"};
			Args = {"player", "id"};
			Description = "Gives the target player(s) a gear from the catalog based on the ID you supply";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local gearID = assert(tonumber(args[2]), "Invalid ID (not Number?)")
				local AssetIdType = service.MarketPlace:GetProductInfo(gearID).AssetTypeId

				if AssetIdType == 19 then
					local gear = service.Insert(gearID)

					if gear:IsA("BackpackItem") then
						service.New("StringValue", gear).Name = Variables.CodeName..gear.Name
						for i, v in service.GetPlayers(plr, args[1]) do
							if v:FindFirstChild("Backpack") then
								gear:Clone().Parent = v.Backpack
							end
						end
					end
				else
					error("Invalid ID provided, Not AssetType Gear.", 0)
				end
			end
		};

		Slippery = {
			Prefix = Settings.Prefix;
			Commands = {"slippery", "iceskate", "icewalk", "slide"};
			Args = {"player"};
			Description = "Makes the target player(s) slide when they walk";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local vel = service.New("BodyVelocity")
				vel.Name = "ADONIS_IceVelocity"
				vel.maxForce = Vector3.new(5000, 0, 5000)
				local scr = Deps.Assets.Slippery:Clone()

				scr.Name = "ADONIS_IceSkates"

				for i, v in service.GetPlayers(plr, args[1]:lower()) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local vel = vel:Clone()
						vel.Parent = v.Character.HumanoidRootPart
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end

				scr:Destroy()
			end
		};

		UnSlippery = {
			Prefix = Settings.Prefix;
			Commands = {"unslippery", "uniceskate", "unslide"};
			Args = {"player"};
			Description = "Get sum friction all up in yo step";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]:lower()) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						local scr = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceSkates")
						local vel = v.Character.HumanoidRootPart:FindFirstChild("ADONIS_IceVelocity")
						if vel then vel:Destroy() end
						if scr then scr.Disabled = true scr:Destroy() end
					end
				end
			end
		};

		OldBodySwap = {
			Prefix = Settings.Prefix;
			Commands = {"oldbodyswap", "oldbodysteal"};
			Args = {"player1", "player2"};
			Description = "[Old] Swaps player1's and player2's bodies and tools";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					for i2, v2 in service.GetPlayers(plr, args[2]) do
						local temptools = service.New("Model")
						local tempcloths = service.New("Model")
						local vpos = v.Character.HumanoidRootPart.CFrame
						local v2pos = v2.Character.HumanoidRootPart.CFrame
						local vface = v.Character.Head.face
						local v2face = v2.Character.Head.face
						vface.Parent = v2.Character.Head
						v2face.Parent = v.Character.Head
						for k, p in v.Character:GetChildren() do
							if p:IsA("BodyColors") or p:IsA("CharacterMesh") or p:IsA("Pants") or p:IsA("Shirt") or p:IsA("Accessory") then
								p.Parent = tempcloths
							elseif p:IsA("Tool") then
								p.Parent = temptools
							end
						end
						for k, p in v.Backpack:GetChildren() do
							p.Parent = temptools
						end
						for k, p in v2.Character:GetChildren() do
							if p:IsA("BodyColors") or p:IsA("CharacterMesh") or p:IsA("Pants") or p:IsA("Shirt") or p:IsA("Accessory") then
								p.Parent = v.Character
							elseif p:IsA("Tool") then
								p.Parent = v.Backpack
							end
						end
						for k, p in tempcloths:GetChildren() do
							p.Parent = v2.Character
						end
						for k, p in v2.Backpack:GetChildren() do
							p.Parent = v.Backpack
						end
						for k, p in temptools:GetChildren() do
							p.Parent = v2.Backpack
						end
						v2.Character.HumanoidRootPart.CFrame = vpos
						v.Character.HumanoidRootPart.CFrame = v2pos
					end
				end
			end
		};

		BodySwap = {
			Prefix = Settings.Prefix;
			Commands = {"bodyswap", "bodysteal", "bswap"};
			Args = {"player1", "player2"};
			Description = "Swaps player1's and player2's avatars, bodies and tools";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v1 in service.GetPlayers(plr, args[1]) do
					if not v1.Character then continue end
					local v1hum = v1.Character:FindFirstChildOfClass("Humanoid")
					local v1desc = v1hum:GetAppliedDescription()

					for _, v2 in service.GetPlayers(plr, args[2]) do
						if not v2.Character then continue end
						local v2hum = v1.Character:FindFirstChildOfClass("Humanoid")
						local v2desc = v2hum:GetAppliedDescription()

						local v1pos, v2pos = v1.Character:GetPivot(), v2.Character:GetPivot()

						v1hum:UnequipTools()
						v2hum:UnequipTools()
						local v1tools, v2tools = v1.Backpack:GetChildren(), v2.Backpack:GetChildren()

						for _, t in v1tools do
							if t:IsA("Tool") then
								t.Parent = v2.Backpack
							end
						end
						for _, t in v2tools do
							if t:IsA("Tool") then
								t.Parent = v1.Backpack
							end
						end

						v1hum:ApplyDescription(v2desc, Enum.AssetTypeVerification.Always)
						v2hum:ApplyDescription(v1desc, Enum.AssetTypeVerification.Always)

						v1.Character:PivotTo(v2pos)
						v2.Character:PivotTo(v1pos)
					end
				end
			end
		};

		Explode = {
			Prefix = Settings.Prefix;
			Commands = {"explode", "boom", "boomboom"};
			Args = {"player", "radius (default: 20 studs)", "blast pressure (default: 500,000)", "visible? (default: true)"};
			Description = "Explodes the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character.PrimaryPart then
						service.New("Explosion", {
							Archivable = false;
							BlastPressure = args[3] or 500_000;
							BlastRadius = args[2] or 20;
							Visible = if args[4] and args[4]:lower() == "false" then false else true;
							Position = v.Character.PrimaryPart.Position;
							Parent = workspace.Terrain;
						})
					end
				end
			end
		};

		Trip = {
			Prefix = Settings.Prefix;
			Commands = {"trip"};
			Args = {"player", "angle"};
			Description = "Rotates the target player(s) by 180 degrees or a custom angle";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local angle = 130 or args[2]
				for i, v in service.GetPlayers(plr, args[1]) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, 0, math.rad(angle))
					end
				end
			end
		};

		Oddliest = {
			Prefix = Settings.Prefix;
			Commands = {"oddliest"};
			Args = {"player"};
			Description = "Turns you into the one and only Oddliest";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "51310503")
				end
			end
		};

		Sceleratis = {
			Prefix = Settings.Prefix;
			Commands = {"sceleratis"};
			Args = {"player"};
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in service.GetPlayers(plr, args[1]) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "userid-1237666")
				end
			end
		};

		ThermalVision = {
			Prefix = Settings.Prefix;
			Commands = {"thermal", "thermalvision", "heatvision"};
			Args = {"player"};
			Description = "Looks like heat vision";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.NewLocal(v, "ColorCorrectionEffect", {
						Name = "WINDOW_THERMAL",
						Brightness = 1,
						Contrast = 20,
						Saturation = 20,
						TintColor = Color3.new(0.5, 0.2, 1);
						Enabled = true,
					}, "Camera")
					Remote.NewLocal(v, "BlurEffect", {
						Name = "WINDOW_THERMAL",
						Size = 24,
						Enabled = true,
					}, "Camera")
				end
			end
		};

		UnThermalVision = {
			Prefix = Settings.Prefix;
			Commands = {"unthermal", "unthermalvision"};
			Args = {"player"};
			Description = "Removes the thermal effect from the target player's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.RemoveLocal(v, "WINDOW_THERMAL", "Camera")
				end
			end
		};

		GameGravity = {
			Prefix = Settings.Prefix;
			Commands = {"ggrav", "gamegrav", "workspacegrav"};
			Args = {"number or fix"};
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

						for i, v in Variables.MusicList do
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
							task.delay(0.4, function()
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
								task.wait(2)
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
						task.wait(2)
					end

					sound.Parent = spart
					spart.Parent = workspace
					spart.Archivable = false
				end
			end
		};
	}
end
