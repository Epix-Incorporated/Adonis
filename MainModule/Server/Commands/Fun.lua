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
			Hidden = false;
			Description = "Makes the target player(s)'s character teleport back and forth rapidly, quite trippy, makes bricks appear to move as the player turns their character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 15)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "trippy"
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "The same as gd but less trippy, teleports the target player(s) back and forth in the same direction, making two ghost like images of the game";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 150)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "ghost"
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Kinda like gd, but teleports the player to four points instead of two";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local num = tostring(args[2] or 0.1)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "vibrate"
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnGlitchs the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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

		Gerald = {
			Prefix = Settings.Prefix;
			Commands = {"gerald"};
			Args = {"player"};
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local human = v.Character:FindFirstChildOfClass("Humanoid");
						if human then
							local clone = gerald:Clone();
							clone.Name = "__ADONIS_GERALD";
							human:AddAccessory(clone);
						end
					end
				end
			end
		};

		UnGerald = {
			Prefix = Settings.Prefix;
			Commands = {"ungerald"};
			Args = {"player"};
			Hidden = false;
			Description = "De-Geraldification";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local gerald = v.Character:FindFirstChild("__ADONIS_GERALD");
						if gerald then
							gerald:Destroy();
						end
					end
				end
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
				for _, v: Player in pairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local root = v.Character:FindFirstChild("HumanoidRootPart")
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxassetid://5816432987"
					sound.Volume = 10
					sound.PlayOnRemove = true
					sound.Parent = root
					sound:Destroy()
					wait(1.4)
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
			Hidden = false;
			AdminLevel = "Moderators";
			Description = "Gives you a doll of a player";
			Function = function(plr: Player, args: {string})
				local function generate(userId)
					local tool = Instance.new("Tool")
					local targetName = service.Players:GetNameFromUserIdAsync(userId)
					if service.Players:GetPlayerByUserId(userId) then
						tool.ToolTip = service.Players:GetPlayerByUserId(userId).DisplayName.." as a tool"
					else
						tool.ToolTip = "@"..targetName.." as a tool"
					end
					tool.Name = service.Players:GetNameFromUserIdAsync(userId)
					local handle = Instance.new("Part")
					handle.Name = "Handle"
					handle.CanCollide = false
					handle.Transparency = 1
					handle.Parent = tool
					local model = service.Players:CreateHumanoidModelFromDescription(service.Players:GetHumanoidDescriptionFromUserId(userId), Enum.HumanoidRigType.R15)
					model.Name = targetName
					local hum = model:WaitForChild("Humanoid")
					local bHeight = hum:WaitForChild("BodyHeightScale")
					local bDepth = hum:WaitForChild("BodyDepthScale")
					local bWidth = hum:WaitForChild("BodyWidthScale")
					bHeight.Value = bHeight.Value / 2
					bDepth.Value = bDepth.Value / 2
					bWidth.Value = bWidth.Value / 2
					local cfr = (plr.Character:FindFirstChild("Right Arm") or plr.Character:FindFirstChild("RightFoot")).CFrame
					handle.CFrame = cfr
					model:FindFirstChild("Animate").Disabled = true
					for _, obj in pairs(model:GetDescendants()) do
						if obj:IsA("BasePart") then
							obj.Massless = true
							obj.CanCollide = false
						end
					end
					model.Parent = tool
					model:SetPrimaryPartCFrame(cfr)
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = model:FindFirstChild("Left Leg") or model:FindFirstChild("LeftFoot")
					weld.Parent = tool
					tool.Parent = plr:FindFirstChildWhichIsA("Backpack")
				end

				if pcall(function() service.GetPlayers(plr, args[1]) end) then
					for _, v in pairs(service.GetPlayers(plr, args[1])) do
						generate(v.UserId)
					end
				else
					local success, id = pcall(service.Players.GetUserIdFromNameAsync, service.Players, args[1])
					if success then
						generate(id)
					else
						error("Unable to find target user")
					end
				end
			end
		};

		PlrGear = {
			Prefix = Settings.Prefix;
			Commands = {"playergear", "dollify", "pgear", "plrgear"};
			Args = {"player"};
			Fun = true;
			Hidden = false;
			AdminLevel = "Moderators";
			Description = "Turns a player into a doll which can be picked up";
			Function = function(runner, args)
				for _, plr in pairs(service.GetPlayers(runner, args[1])) do
					if plr.Character.Parent:IsA("Tool") ~= true then
						local tool = Instance.new("Tool")
						tool.ToolTip = plr.DisplayName .. " as a tool, converted with Adonis."
						tool.Name = plr.Name
						local handle = Instance.new("Part")
						handle.Name = "Handle"
						handle.Transparency = 1
						handle.Parent = tool
						local model = service.Players:CreateHumanoidModelFromDescription(service.Players:GetHumanoidDescriptionFromUserId(plr.UserId), Enum.HumanoidRigType.R15)
						model.Name = plr.DisplayName
						local oldcframe = plr.Character:FindFirstChild("HumanoidRootPart").CFrame
						plr.Character:Destroy()
						plr.Character = model
						model:SetPrimaryPartCFrame(oldcframe)
						local hum = model:WaitForChild("Humanoid") -- U forgot that variable
						local bHeight = hum:WaitForChild("BodyHeightScale")
						local bDepth = hum:WaitForChild("BodyDepthScale")
						local bWidth = hum:WaitForChild("BodyWidthScale")
						bHeight.Value = bHeight.Value / 2
						bDepth.Value = bDepth.Value / 2
						bWidth.Value = bWidth.Value / 2
						local cfr = (plr.Character:FindFirstChild("HumanoidRootPart")).CFrame
						handle.CFrame = cfr
						handle.CanCollide = false
						for _, v in pairs(model:GetDescendants()) do
							if v:IsA("BasePart") then
								v.Massless = true
							end
						end
						model.Parent = tool
						model:SetPrimaryPartCFrame(cfr)
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = handle
						weld.Part1 = model:FindFirstChild("HumanoidRootPart")
						weld.Parent = tool
						tool.Parent = workspace
					else
						error("That user is already a doll!")
					end
				end
			end
		};

		Davey = {
			Prefix = Settings.Prefix;
			Commands = {"Davey_Bones"};
			Args = {"player"};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "userid-698712377")
				end
			end
		};

		Boombox = {
			Prefix = Settings.Prefix;
			Commands = {"boombox"};
			Args = {"player"};
			Hidden = false;
			Description = "Gives the target player(s) a boombox";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local gear = service.Insert(tonumber(212641536))
				if gear:IsA("BackpackItem") then
					service.New("StringValue", gear).Name = Variables.CodeName..gear.Name
					for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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

						for _, prt in pairs(char:GetChildren()) do
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					infect(v)
				end
			end
		};

		Rainbowify = {
			Prefix = Settings.Prefix;
			Commands = {"rainbowify", "rainbow"};
			Args = {"player"};
			Hidden = false;
			Description = "Make the target player(s)'s character flash random colors";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Core.NewScript("LocalScript",[[
					repeat
						wait(0.1)
						local char = script.Parent.Parent
						local clr = BrickColor.random()
						for i, v in pairs(char:GetChildren()) do
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for _, p in pairs(v.Character:GetChildren()) do
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

		PlayerColor = {
			Prefix = Settings.Prefix;
			Commands = {"color", "playercolor", "bodycolor"};
			Args = {"player", "brickcolor or RGB"};
			Hidden = false;
			Description = "Recolors the target character(s) with the given color, or random if none is given";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local color

				local BodyColorProperties = {"HeadColor", "LeftArmColor", "RightArmColor", "RightLegColor", "LeftLegColor", "TorsoColor"}

				if not args[2] then
					color = BrickColor.random().Color
					Functions.Hint("A color wasn't supplied. A random color will be used instead.", {plr})
				else 
					color = Functions.ParseColor3(args[2])
					assert(color, "Invalid color provided")
				end

				for _, v: Player in pairs(service.GetPlayers(plr, args[1])) do
					local humanoid: Humanoid? = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						local humanoidDesc: HumanoidDescription = humanoid:GetAppliedDescription()

						for _, property in ipairs(BodyColorProperties) do 
							humanoidDesc[property] = color
						end 
						
						task.defer(humanoid.ApplyDescription, humanoid, humanoidDesc)
					end
				end
			end
		};

		Material = {
			Prefix = Settings.Prefix;
			Commands = {"mat", "material"};
			Args = {"player", "material"};
			Hidden = false;
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
					Functions.Hint("Material wasn't supplied. Plastic was chosen instead")
				elseif tonumber(args[2]) then
					chosenMat = table.find(mats, tonumber(args[2]))
				end

				if not chosenMat then
					Remote.MakeGui(plr, "Output", {Title = "Output"; Message = "Invalid material choice";})
					return
				end

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for _, p in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Make the target neon";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for _, p in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Turn the target player(s) into a ghost";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						Admin.RunCommand(Settings.Prefix.."noclip", v.Name)

						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end

						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for _, prt in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Make the target player(s) look like gold";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt.Parent = v.Character.HumanoidRootPart
						end

						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants.Parent = v.Character.HumanoidRootPart
						end

						for _, prt in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Make the target player(s)'s character shiney";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						if v.Character:FindFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:FindFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for _, prt in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Makes the target player(s)'s screen 2spooky4them";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Effect", {Mode = "Spooky";})
				end
			end
		};

		Blind = {
			Prefix = Settings.Prefix;
			Commands = {"blind"};
			Args = {"player"};
			Hidden = false;
			Description = "Blinds the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Effect", {Mode = "Blind";})
				end
			end
		};

		ScreenImage = {
			Prefix = Settings.Prefix;
			Commands = {"screenimage", "scrimage", "image"};
			Args = {"player", "textureid"};
			Hidden = false;
			Description = "Places the desired image on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Places the desired video on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Effect", {Mode = "ScreenVideo"; video = args[2];})
				end
			end
		};

		UnEffect = {
			Prefix = Settings.Prefix;
			Commands = {"uneffect", "unimage", "uneffectgui", "unspook", "unblind", "unstrobe", "untrippy", "unpixelize", "unlowres", "unpixel", "undance", "unflashify", "unrainbowify", "guifix", "fixgui"};
			Args = {"player"};
			Hidden = false;
			Description = "Removes any effect GUIs on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Remote.MakeGui(v, "Effect", {Mode = "Off";})
				end
			end
		};

		Swagify = {
			Prefix = Settings.Prefix;
			Commands = {"swagify", "swagger"};
			Args = {"player"};
			Hidden = false;
			Description = "Swag the target player(s) up";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for _, v in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Shrekify the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							Admin.RunCommand(Settings.Prefix.."pants", v.Name, "233373970")
							Admin.RunCommand(Settings.Prefix.."shirt", v.Name, "133078195")

							for _, v in pairs(v.Character:GetChildren()) do
								if v:IsA("Accoutrement") or v:IsA("CharacterMesh") then
									v:Destroy()
								end
							end

							Admin.RunCommand(Settings.Prefix.."hat", v.Name, "20011951")

							local sound = service.New("Sound", v.Character.HumanoidRootPart)
							sound.SoundId = "http://www.roblox.com/asset/?id="..130767645
							wait(0.5)
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
			Hidden = false;
			Description = "Send the target player(s) to the moon!";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
											wait()
										end
									end)
									--]]
							wait(5)
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
			Hidden = false;
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Make the target player(s) break dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Make the target player(s) puke";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if not v:IsA("Player") or not v or not v.Character or not v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("Epix Puke") then return end
						local run = true
						local k = service.New("StringValue", v.Character)
						k.Name = "Epix Puke"
						Routine(function()
							repeat
								wait(0.07)
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
										wait(10)
										g:Destroy()
									elseif o and o.Name == "Puke Plate" and p then
										p:Destroy()
										o.PukeMesh.Scale = o.PukeMesh.Scale+Vector3.new(0.5, 0, 0.5)
									end
								end)
							until run == false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild("Head"))
						end)
						wait(12)
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
			Hidden = false;
			Description = "Make the target player(s) bleed";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if not v:IsA("Player") or not v or not v.Character or not v.Character:FindFirstChild("Head") or v.Character:FindFirstChild("ADONIS_BLEED") then return end
						local run = true
						local k = service.New("StringValue", v.Character)
						k.Name = "ADONIS_BLEED"
						Routine(function()
							repeat
								wait(0.15)
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
										wait(10)
										g:Destroy()
									elseif o and o.Name == "Blood Plate" and p then
										p:Destroy()
										o.BloodMesh.Scale = o.BloodMesh.Scale+Vector3.new(0.5, 0, 0.5)
									end
								end)
							until run == false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild("Head"))
						end)
						wait(10)
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
			Hidden = false;
			Description = "Slowly kills the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
								wait(1)
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
			Hidden = false;
			Description = "Gives the target player(s) hat pets, controled using the !pets command.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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

							for _, h in pairs(v.Character:GetChildren()) do
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

		RestoreGravity = {
			Prefix = Settings.Prefix;
			Commands = {"grav", "bringtoearth"};
			Args = {"player"};
			Hidden = false;
			Description = "Makes the target player(s)'s gravity normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in pairs(v.Character.HumanoidRootPart:GetChildren()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy() end
						end
					end
				end
			end
		};

		SetGravity = {
			Prefix = Settings.Prefix;
			Commands = {"setgrav", "gravity", "setgravity"};
			Args = {"player", "number"};
			Hidden = false;
			Description = "Set the target player(s)'s gravity";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in pairs(v.Character.HumanoidRootPart:GetChildren()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0, 0, 0)
						for _, prt in pairs(v.Character:GetChildren()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force - Vector3.new(0, prt:GetMass()*tonumber(args[2]), 0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force - Vector3.new(0, prt.Handle:GetMass()*tonumber(args[2]), 0)
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
			Hidden = false;
			Description = "NoGrav the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, frc in pairs(v.Character.HumanoidRootPart:GetChildren()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0, 0, 0)
						for _, prt in pairs(v.Character:GetChildren()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force + Vector3.new(0, prt:GetMass()*196.25, 0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force + Vector3.new(0, prt.Handle:GetMass()*196.25, 0)
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
			Hidden = false;
			Description = "Makes the player jump, and jump... and jump. Just like the rabbit noobs you find in sf games ;)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local bunnyScript = Deps.Assets.BunnyHop
				bunnyScript.Name = "HippityHopitus"
				local hat = service.Insert(110891941)
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Stops the forced hippity hoppening";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					local scrapt = v.Character:FindFirstChild("HippityHopitus")
					if scrapt then
						scrapt.Disabled = true
						scrapt:Destroy()
					end
				end
			end
		};

		FreeFall = {
			Prefix = Settings.Prefix;
			Commands = {"freefall", "skydive"};
			Args = {"player", "height"};
			Hidden = false;
			Description = "Teleport the target player(s) up by <height> studs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Turns the target player(s) into a stick figure";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for kay, player in pairs(service.GetPlayers(plr, args[1])) do
					local m = player.Character
					for i, v in pairs(m:GetChildren()) do
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
			Hidden = false;
			Description = "Sends the target player(s) down a hole";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for kay, player in pairs(service.GetPlayers(plr, args[1])) do
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
								wait(0.1)
							end
							for i = 1, 5, 0.2 do
								torso.CFrame = foot * CFrame.new(0,-(i^2), 0) * CFrame.fromEulerAnglesXYZ(-(math.pi/2), 0, 0) * CFrame.new(0, 3, 0)
								wait()
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
			Hidden = false;
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
						wait(0.2)
						sound.Volume = 0.5
						sound.Pitch = 0.8
						sound:Play()
						light.Enabled = true
						wait(1/100)
						light.Enabled = false
						wait(0.2)
						light.Enabled = true
						light.Brightness = 1
						wait(0.05)
						light.Brightness = 3
						wait(0.02)
						light.Brightness = 1
						wait(0.07)
						light.Brightness = 10
						wait(0.09)
						light.Brightness = 0
						wait(0.01)
						light.Brightness = 7
						light.Enabled = false
						wait(1.5)
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
						wait()
						local part2 = part1:clone()
						part2.Parent = zeus
						part2.Size = Vector3.new(1, 7.48, 2)
						part2.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 7.5, 0)
						part2.Rotation = Vector3.new(77.514, -75.232, 78.051)
						wait()
						local part3 = part1:clone()
						part3.Parent = zeus
						part3.Size = Vector3.new(1.86, 7.56, 1)
						part3.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0, 1, 0)
						part3.Rotation = Vector3.new(0, 0, -11.128)
						sound.SoundId = "rbxassetid://130818250"
						sound.Volume = 1
						sound.Pitch = 1
						sound:Play()
						wait()
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
			Hidden = false;
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
			Hidden = false;
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				local bg = Instance.new("BodyGyro")
				bg.Name = "SPINNER_GYRO"
				bg.maxTorque = Vector3.new(0, math.huge, 0)
				bg.P = 11111
				bg.D = 0
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, q in pairs(v.Character.HumanoidRootPart:GetChildren()) do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" then
								q:Destroy()
							end
						end
						local gyro = bg:Clone()
						gyro.cframe = v.Character.HumanoidRootPart.CFrame
						gyro.Parent = v.Character.HumanoidRootPart
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
			Hidden = false;
			Description = "Makes the target player(s) stop spinning";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
						for _, q in pairs(v.Character.HumanoidRootPart:GetChildren()) do
							if q.Name == "SPINNER" or q.Name == "SPINNER_GYRO" then
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
			Hidden = false;
			Description = "Turn the target player(s) into a dog";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(p, args)
				for _, plr in ipairs(service.GetPlayers(p, args[1])) do
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

							for _, v in ipairs(torso:GetChildren()) do
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

							local bf = service.New("BodyForce", {Force = Vector3.new(0, 2e3, 0), Parent = st})

							st.CFrame = torso.CFrame
							st.Parent = char

							local weld = service.New("Weld", {Parent = st, Part0 = torso, Part1 = st, C1 = CFrame.new(0, .5, 0)})

							for _, v in ipairs(char:GetDescendants()) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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

		Sp00ky = {
			Prefix = Settings.Prefix;
			Commands = {"sp00ky", "spooky", "spookyscaryskeleton"};
			Args = {"player"};
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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
						for _, c in ipairs(v.Character.Head:GetChildren()) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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
						for _, c in ipairs(v.Character.Head:GetChildren()) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for k, p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
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

				for _, v in pairs(Functions.GetPlayers(plr, args[1])) do
					local char = v.Character
					for _, p in pairs(char:GetChildren()) do
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
			Hidden = false;
			Description = "Removes particle emitters from target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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

						for _, v in ipairs(char:GetChildren()) do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end

						local function size(part)
							for _, v in ipairs(part:GetChildren()) do
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
										for _, m in pairs(p1:GetChildren()) do
											if m:IsA("Weld") then
												m.Part0 = nil
												m.Part1.Anchored = true
											end
										end

										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X, p1.Size.Y, num)

										for _, m in pairs(p1:GetChildren()) do
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

						for i, v in pairs(welds) do
							v.Part0 = torso
							v.Part1.Anchored = false
						end

						for i, v in pairs(char:GetChildren()) do
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					sizePlayer(v)
				end
			end
		};

		OldFlatten = {
			Prefix = Settings.Prefix;
			Commands = {"oldflatten", "o2d", "oflat"};
			Args = {"player", "optional num"};
			Hidden = false;
			Description = "Old Flatten. Went lazy on this one.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						for _, p in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Sticky";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Break the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if v.Character then
							local head = v.Character.Head
							local torso = v.Character.HumanoidRootPart
							local larm = v.Character["Left Arm"]
							local rarm = v.Character["Right Arm"]
							local lleg = v.Character["Left Leg"]
							local rleg = v.Character["Right Leg"]
							for _, v in pairs(v.Character:GetChildren()) do if v:IsA("Part") then v.Anchored = true end end
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
							wait()
							for _, v in pairs(v.Character:GetChildren()) do if v:IsA("Part") then v.Anchored = false end end
						end
					end)
				end
			end
		};

		Skeleton = {
			Prefix = Settings.Prefix;
			Commands = {"skeleton"};
			Args = {"player"};
			Hidden = false;
			Description = "Turn the target player(s) into a skeleton";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local hat = service.Insert(36883367)
				local players = service.GetPlayers(plr, args[1])
				for _, v in pairs(players) do
					for _, m in pairs(v.Character:GetChildren()) do
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
					for _, v in pairs(players) do
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
			Hidden = false;
			Description = "Turn the target player(s) into a creeper";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(service.GetPlayers(plr, args[1])) do
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

							for _, part in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Give the target player(s) a larger ego";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Give the target player(s) a small head";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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

				for _, v in pairs(service.GetPlayers(plr, args[1])) do
					local char = v.Character
					local human = char and char:FindFirstChildOfClass("Humanoid")

					if not human then
						Functions.Hint("Cannot resize "..v.Name.."'s character: humanoid and/or character doesn't exist!", {plr})
						continue
					end

					if not Variables.SizedCharacters[char] then
						Variables.SizedCharacters[char] = num
					elseif Variables.SizedCharacters[char] and Variables.SizedCharacters[char]*num < sizeLimit then
						Variables.SizedCharacters[char] = Variables.SizedCharacters[char]*num
					else
						Functions.Hint(string.format("Cannot resize %s's character by %f%%: size limit exceeded.", v.Name, num*100), {plr})
						continue
					end

					if human and human.RigType == Enum.HumanoidRigType.R15 then
						for _, val in pairs(human:GetChildren()) do
							if val:IsA("NumberValue") and val.Name:match(".*Scale") then
								val.Value *= num
							end
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local motors = {}
						table.insert(motors, char.HumanoidRootPart:FindFirstChild("RootJoint"))
						for _, motor in pairs(char.Torso:GetChildren()) do
							if motor:IsA("Motor6D") then table.insert(motors, motor) end
						end
						for _, motor in pairs(motors) do
							motor.C0 = CFrame.new((motor.C0.Position * num)) * (motor.C0 - motor.C0.Position)
							motor.C1 = CFrame.new((motor.C1.Position * num)) * (motor.C1 - motor.C1.Position)
						end

						for _, v in ipairs(char:GetDescendants()) do
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
			Hidden = false;
			Description = "Make the target player(s)'s character spazz out on the floor";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local scr = Deps.Assets.Seize
				scr.Name = "Seize"
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Removes the effects of the seizure command";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Remove the target player(s)'s arms and legs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for a, obj in pairs(v.Character:GetChildren()) do
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
			Hidden = false;
			Description = "Loop flings the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "UnLoop Fling";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						local pTorso = plr.Character:FindFirstChild("HumanoidRootPart")
						if torso and pTorso and plr ~= v then
							Admin.RunCommand(Settings.Prefix.."clip", v.Name)
							wait(0.3)
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
				for i, player1 in pairs(service.GetPlayers(plr, args[1])) do
					for i2, player2 in pairs(service.GetPlayers(plr, args[2])) do
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
				for i, p in pairs(service.GetPlayers(plr, args[1])) do
					local torso = p.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						for i, v in pairs(torso:GetChildren()) do
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
					for i, v in pairs(char:GetChildren()) do
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

				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						clear(v.Character)
						apply(v.Character)
					end
				end
			end
		};

		Transparency = {
			Prefix = Settings.Prefix;
			Commands = {"transparency", "trans"};
			Args = {"player", "value (0-1)"};
			Hidden = false;
			Description = "Set the transparency of the target's character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						for k, p in pairs(v.Character:GetChildren()) do
							if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
								p.Transparency = args[2]
								if p.Name == "Head" then
									for _, v2 in pairs(p:GetChildren()) do
										if v2:IsA("Decal") then
											v2.Transparency = args[2]
										end
									end
								end
							elseif p:IsA("Accessory") and #p:GetChildren() ~= 0 then
								for _, v2 in pairs(p:GetChildren()) do
									if v2:IsA("BasePart") then
										v2.Transparency = args[2]
									end
								end
							end
						end
					end
				end
			end
		};

		TransparentPart = {
			Prefix = Settings.Prefix;
			Commands = {"transparentpart"};
			Args = {"player", "parts", "value (0-1)"};
			Hidden = false;
			Description = "Set the transparency of the target's character's parts, including accessories. Supports comma separated list of parts.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, player in pairs(service.GetPlayers(plr, args[1])) do
					if player.Character then
						local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local rigType =  humanoid.RigType
							local GroupPartInputs = {"LeftArm", "RightArm", "RightLeg", "LeftLeg", "Torso"}
							local PartInputs = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}

							local usageText = {
								"Possible inputs are:",
								"R6: Head, LeftArm, RightArm, RightLeg, LeftLeg, Torso",
								"R15: Head, UpperTorso, LowerTorso, LeftUpperArm, LeftLowerArm, LeftHand, RightUpperArm, RightLowerArm, RightHand, LeftUpperLeg, LeftLowerLeg, LeftFoot, RightUpperLeg, RightLowerLeg, RightFoot",
								"",
								"If the input is 'LeftArm' on a R15 rig, it will select the entire Left Arm for R15.",
								"Special Inputs: all, accessories",
								"all: All limbs including accessories. If this is specified it will ignore all other specified parts.",
								"limbs: Changes the transparency of all limbs",
								"face: Changes the transparency of the face",
								"accessories: Changes transparency of accessories"
							}

							if not (args[2]) then
								--assert(args[2], "No parts specified. See developer console for possible inputs.")
								local tab = {}
								for _,v in pairs(usageText) do
									table.insert(tab, {
										Text = v;
										Desc = v;
									})
								end
								--// Generate the UI for this player
								server.Remote.MakeGui(plr, "List", {
									Tab = tab;
									Title = "Command Usage";
								})
								return
							end

							local partInput = {}
							local inputs = string.split(args[2], ",")

							for _, v in pairs(inputs) do
								if v ~= "" then
									if v == "all" then
										partInput = "all"
										break -- break if "all" is found.
									end

									-- Validate inputs
									if v == "limbs" or v == "face" or v == "accessories" then
										table.insert(partInput, v)
									else
										local found = false
										while found ~= true do
											for _,v2 in pairs(GroupPartInputs) do
												if v == v2 then
													table.insert(partInput, v)
													found = true
													break
												end
											end

											for _,v2 in pairs(PartInputs) do
												if v == v2 then
													table.insert(partInput, v)
													found = true
													break
												end
											end

											if not (found) then
												assert(nil, "'"..v.."'".." is not a valid input. Run command with no arguments to see possible inputs.")
											end
										end
									end
								else
									assert(nil, "Part argument contains empty value.")
								end
							end


							-- Check if partInput is a table
							if typeof(partInput) == "table" then
								local hash = {}

								-- Check for duplicates
								for i,v in pairs(partInput) do
									if not (hash[v]) then
										hash[v] = i -- Store into table to check for duplicates.
									else
										assert(nil, "Duplicate '"..v.."'".." found in input. Specify each input once only.")
									end
								end


								-- Clean up the parts we don't need, depending on rigType, to allow this command to be more dynamic

								if rigType == Enum.HumanoidRigType.R15 then
									for i = #partInput, 1, -1 do
										if partInput[i] == "RightArm" then
											local foundKeys = {}
											for k2, v2 in pairs(partInput) do
												if v2 == "RightUpperArm" or v2 == "RightLowerArm" or v2 == "RightHand" then
													table.insert(foundKeys, k2)
												end
											end
											-- If not all keys were found just remove all keys and add them manually
											if #foundKeys ~= 3 then
												for _, foundKey in pairs(foundKeys) do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "RightUpperArm")
												table.insert(partInput, "RightLowerArm")
												table.insert(partInput, "RightHand")
											end
											table.remove(partInput, i) -- Remove the group part input

										elseif partInput[i] == "LeftArm" then
											local foundKeys = {}
											for k2, v2 in pairs(partInput) do
												if v2 == "LeftUpperArm" or v2 == "LeftLowerArm" or v2 == "LeftHand" then
													table.insert(foundKeys, k2)
												end
											end

											if #foundKeys ~= 3 then
												for _, foundKey in pairs(foundKeys) do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "LeftUpperArm")
												table.insert(partInput, "LeftLowerArm")
												table.insert(partInput, "LeftHand")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "RightLeg" then
											local foundKeys = {}
											for i = #partInput, 1, -1 do
												if partInput[i] == "RightUpperLeg" or partInput[i] == "RightLowerLeg" or partInput[i] == "RightFoot" then
													table.insert(foundKeys, partInput[i])
												end
											end
											if #foundKeys ~= 3 then
												for _, foundKey in pairs(foundKeys) do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "RightUpperLeg")
												table.insert(partInput, "RightLowerLeg")
												table.insert(partInput, "RightFoot")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "LeftLeg" then
											local foundKeys = {}
											for k2, v2 in pairs(partInput) do
												if v2 == "LeftUpperLeg" or v2 == "LeftLowerLeg" or v2 == "LeftFoot" then
													table.insert(foundKeys, k2)
												end
											end
											
											if #foundKeys ~= 3 then
												for _, foundKey in pairs(foundKeys) do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "LeftUpperLeg")
												table.insert(partInput, "LeftLowerLeg")
												table.insert(partInput, "LeftFoot")
											end
											table.remove(partInput, i)
										elseif partInput[i] == "Torso" then
											local foundKeys = {}
											for k2, v2 in pairs(partInput) do
												if v2 == "UpperTorso" or v2 == "LowerTorso" then
													table.insert(foundKeys, k2)
												end
											end
											if #foundKeys ~= 2 then
												for _, foundKey in pairs(foundKeys) do
													table.remove(partInput, foundKey)
												end
												table.insert(partInput, "UpperTorso")
												table.insert(partInput, "LowerTorso")
											end
											table.remove(partInput, i)
										end
									end
								end

								if rigType == Enum.HumanoidRigType.R6 then
									for i = #partInput, 1, -1 do
										if partInput[i] == "RightUpperArm" or partInput[i] == "RightLowerArm" or partInput[i] == "RightHand" then
											table.remove(partInput, i)
										elseif partInput[i] == "LeftUpperArm" or partInput[i] == "LeftLowerArm" or partInput[i] == "LeftHand" then
											table.remove(partInput, i)
										elseif partInput[i] == "RightUpperLeg" or partInput[i] == "RightLowerLeg" or partInput[i] == "RightFoot" then
											table.remove(partInput, i)
										elseif partInput[i] == "LeftUpperLeg" or partInput[i] == "LeftLowerLeg" or partInput[i] == "LeftFoot" then
											table.remove(partInput, i)
										elseif partInput[i] == "UpperTorso" or partInput[i] == "LowerTorso" then
											table.remove(partInput, i)
										end
									end
								end


								-- Make chosen parts transparent
								for k, v in pairs(partInput) do
									if not (v == "limbs" or v == "face" or v == "accessories") then
										local part = player.Character:FindFirstChild(v)
										if part ~= nil and part:IsA("BasePart") then
											part.Transparency = args[3]
										end

									elseif v == "limbs" then
										for key, part in pairs(player.Character:GetChildren()) do
											if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
												part.Transparency = args[3]
											end
										end

									elseif v == "face" then
										local headPart = player.Character:FindFirstChild("Head")
										for _, v2 in pairs(headPart:GetChildren()) do
											if v2:IsA("Decal") then
												v2.Transparency = args[3]
											end
										end

									elseif v == "accessories" then
										for key, part in pairs(player.Character:GetChildren()) do
											if part:IsA("Accessory") then
												for _, v2 in pairs(part:GetChildren()) do
													if v2:IsA("BasePart") then
														v2.Transparency = args[3]
													end
												end
											end
										end
									end
								end


							-- If "all" is specified
							elseif partInput == "all" then
								for k, p in pairs(player.Character:GetChildren()) do
									if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
										p.Transparency = args[3]
										if p.Name == "Head" then
											for _, v2 in pairs(p:GetChildren()) do
												if v2:IsA("Decal") then
													v2.Transparency = args[3]
												end
											end
										end
									elseif p:IsA("Accessory") and #p:GetChildren() ~= 0 then
										for _, v2 in pairs(p:GetChildren()) do
											if v2:IsA("BasePart") then
												v2.Transparency = args[3]
											end
										end
									end
								end
							end
						end
					end
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							for _, obj in ipairs(v.Character:GetChildren()) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _, v2 in pairs(animateScript:GetDescendants()) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _,v2 in pairs(animateScript:GetDescendants()) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _, v2 in pairs(animateScript:GetDescendants()) do
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

				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					if v.Character then
						local animateScript = v.Character:FindFirstChild("Animate")
						if animateScript then
							local found = false
							for _,v2 in pairs(animateScript:GetDescendants()) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
				for _, p in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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
					for i, v in pairs(service.GetPlayers(plr, args[2])) do
						Remote.SetLighting(v, "FogColor", Color3.new(tonumber(num1), tonumber(num2), tonumber(num3)))
						Remote.SetLighting(v, "FogEnd", 9e9)
					end
				else
					Functions.SetLighting("FogColor", Color3.new(tonumber(num1), tonumber(num2), tonumber(num3)))
					Functions.SetLighting("FogEnd", 9e9) --Thanks go to Janthran for another neat glitch
				end
			end
		};

		StarterGear = {
			Prefix = Settings.Prefix;
			Commands = {"startergear", "givestartergear"};
			Args = {"player", "id"};
			Hidden = false;
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
						for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
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
						for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Makes the target player(s) slide when they walk";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local vel = service.New("BodyVelocity")
				vel.Name = "ADONIS_IceVelocity"
				vel.maxForce = Vector3.new(5000, 0, 5000)
				local scr = Deps.Assets.Slippery:Clone()

				scr.Name = "ADONIS_IceSkates"

				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
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
			Hidden = false;
			Description = "Get sum friction all up in yo step";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1]:lower())) do
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
			Hidden = false;
			Description = "[Old] Swaps player1's and player2's bodies and tools";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					for i2, v2 in pairs(service.GetPlayers(plr, args[2])) do
						local temptools = service.New("Model")
						local tempcloths = service.New("Model")
						local vpos = v.Character.HumanoidRootPart.CFrame
						local v2pos = v2.Character.HumanoidRootPart.CFrame
						local vface = v.Character.Head.face
						local v2face = v2.Character.Head.face
						vface.Parent = v2.Character.Head
						v2face.Parent = v.Character.Head
						for k, p in pairs(v.Character:GetChildren()) do
							if p:IsA("BodyColors") or p:IsA("CharacterMesh") or p:IsA("Pants") or p:IsA("Shirt") or p:IsA("Accessory") then
								p.Parent = tempcloths
							elseif p:IsA("Tool") then
								p.Parent = temptools
							end
						end
						for k, p in pairs(v.Backpack:GetChildren()) do
							p.Parent = temptools
						end
						for k, p in pairs(v2.Character:GetChildren()) do
							if p:IsA("BodyColors") or p:IsA("CharacterMesh") or p:IsA("Pants") or p:IsA("Shirt") or p:IsA("Accessory") then
								p.Parent = v.Character
							elseif p:IsA("Tool") then
								p.Parent = v.Backpack
							end
						end
						for k, p in pairs(tempcloths:GetChildren()) do
							p.Parent = v2.Character
						end
						for k, p in pairs(v2.Backpack:GetChildren()) do
							p.Parent = v.Backpack
						end
						for k, p in pairs(temptools:GetChildren()) do
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
			Hidden = false;
			Description = "Swaps player1's and player2's avatars, bodies and tools";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v1 in pairs(service.GetPlayers(plr, args[1])) do
					if not v1.Character then continue end
					local v1hum = v1.Character:FindFirstChildOfClass("Humanoid")
					local v1desc = v1hum:GetAppliedDescription()
		
					for _, v2 in pairs(service.GetPlayers(plr, args[2])) do
						if not v2.Character then continue end
						local v2hum = v1.Character:FindFirstChildOfClass("Humanoid")
						local v2desc = v2hum:GetAppliedDescription()
		
						local v1pos, v2pos = v1.Character:GetPivot(), v2.Character:GetPivot()
		
						v1hum:UnequipTools()
						v2hum:UnequipTools()
						local v1tools, v2tools = v1.Backpack:GetChildren(), v2.Backpack:GetChildren()
		
						for _, t in ipairs(v1tools) do
							if t:IsA("Tool") then
								t.Parent = v2.Backpack
							end
						end
						for _, t in pairs(v2tools) do
							if t:IsA("Tool") then
								t.Parent = v1.Backpack
							end
						end
		
						v1hum:ApplyDescription(v2desc)
						v2hum:ApplyDescription(v1desc)
		
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
			Hidden = false;
			Description = "Explodes the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Rotates the target player(s) by 180 degrees or a custom angle";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				local angle = 130 or args[2]
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Turns you into the one and only Oddliest";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "51310503")
				end
			end
		};

		Sceleratis = {
			Prefix = Settings.Prefix;
			Commands = {"sceleratis"};
			Args = {"player"};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr: Player, args: {string})
				for i, v in pairs(service.GetPlayers(plr, args[1])) do
					Admin.RunCommand(Settings.Prefix.."char", v.Name, "userid-1237666")
				end
			end
		};

		ThermalVision = {
			Prefix = Settings.Prefix;
			Commands = {"thermal", "thermalvision", "heatvision"};
			Args = {"player"};
			Hidden = false;
			Description = "Looks like heat vision";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
			Hidden = false;
			Description = "Removes the thermal effect from the target player's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr, args)
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
					Remote.RemoveLocal(v, "WINDOW_THERMAL", "Camera")
				end
			end
		};
	}
end
