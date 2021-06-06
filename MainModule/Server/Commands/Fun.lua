return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		Glitch = {
			Prefix = Settings.Prefix;
			Commands = {"glitch";"glitchdisorient";"glitch1";"glitchy"};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Makes the target player(s)'s character teleport back and forth rapidly, quite trippy, makes bricks appear to move as the player turns their character";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 15)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "trippy"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"ghostglitch";"glitch2";"glitchghost"};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "The same as gd but less trippy, teleports the target player(s) back and forth in the same direction, making two ghost like images of the game";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 150)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "ghost"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"vibrate";"glitchvibrate";};
			Args = {"player";"intensity";};
			Hidden = false;
			Description = "Kinda like gd, but teleports the player to four points instead of two";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local num = tostring(args[2] or 0.1)
				local scr = Deps.Assets.Glitcher:Clone()
				scr.Num.Value = num
				scr.Type.Value = "vibrate"
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"unglitch";"unglitchghost";"ungd";"ungg";"ungv";"unvibrate";};
			Args = {"player";};
			Hidden = false;
			Description = "UnGlitchs the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"setfps";};
			Args = {"player";"fps";};
			Hidden = false;
			Description = "Sets the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				assert(tonumber(args[2]),tostring(args[2]).." is not a valid number")
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","SetFPS",tonumber(args[2]))
				end
			end
		};

		RestoreFPS = {
			Prefix = Settings.Prefix;
			Commands = {"restorefps";"revertfps";"unsetfps";};
			Args = {"player";};
			Hidden = false;
			Description = "Restores the target players's FPS";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","RestoreFPS")
				end
			end
		};

		wat = { --// wat??
			Prefix = "!";
			Commands = {"wat";};
			Args = {};
			Hidden = true;
			Description = "???";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr,args)
				local wot = {3657191505,754995791,160715357,4881542521,4608323236,227499602,217714490,130872377,142633540,259702986}
				Remote.Send(plr,"Function","PlayAudio",wot[math.random(1,#wot)])
			end
		};

		YouBeenTrolled = {
			Prefix = "?";
			Commands = {"trolled";"freebobuc";"freedonor";"?free-creator-powers?";};--//add more :)
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "You've Been Trolled You've Been Trolled";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Effect",{Mode = "trolling"})
			end
		};
		LowRes = {
			Prefix = Settings.Prefix;
			Commands = {"lowres","pixelrender","pixel","pixelize"};
			Args = {"player","pixelSize","renderDist"};
			Hidden = false;
			Description = "Pixelizes the player's view";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
				local size = tonumber(args[2]) or 19
				local dist = tonumber(args[3]) or 100
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{
						Mode = "Pixelize";
						Resolution = size;
						Distance = dist;
					})
				end
			end
		};

		ZaWarudo = {
			Prefix = Settings.Prefix;
			Commands = {"zawarudo","stoptime"};
			Args = {};
			Fun = true;
			Description = "Freezes everything but the player running the command";
			AdminLevel = "Admins";
			Function = function(plr,args)
				local doPause; doPause = function(obj)
					if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(plr.Character) then
						obj.Anchored = true
						table.insert(Variables.FrozenObjects, obj)
					end

					for i,v in next,obj:GetChildren() do
						doPause(v)
					end
				end

				if not Variables.ZaWarudoDebounce then
					Variables.ZaWarudoDebounce = true
					delay(10, function() Variables.ZaWarudoDebounce = false end)
					if Variables.ZaWarudo then
						local audio = service.New("Sound",workspace)
						audio.SoundId = "rbxassetid://676242549"
						audio.Volume = 0.5
						audio:Play()
						wait(2)
						for i,part in next,Variables.FrozenObjects do
							part.Anchored = false
						end

						local old = service.Lighting:FindFirstChild("ADONIS_ZAWARUDO")
						if old then
							for i = -2,0,0.1 do
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
						local audio = service.New("Sound",workspace)
						audio.SoundId = "rbxassetid://274698941"
						audio.Volume = 10
						audio:Play()
						wait(2.25)
						doPause(workspace)
						Variables.ZaWarudo = game.DescendantAdded:connect(function(c)
							if c:IsA("BasePart") and not c.Anchored and c.Name ~= "HumanoidRootPart" then
								c.Anchored = true
								table.insert(Variables.FrozenObjects,c)
							end
						end)

						local cc = service.New("ColorCorrectionEffect",service.Lighting)
						cc.Name = "ADONIS_ZAWARUDO"
						for i = 0,-2,-0.1 do
							cc.Saturation = i
							wait(0.01)
						end

						audio:Destroy()
						local clock = service.New("Sound",workspace)
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
			Commands = {"dizzy";};
			Args = {"player","speed"};
			Description = "Causes motion sickness";
			AdminLevel = "Admins";
			Fun = true;
			Function = function(plr,args)
				local speed = args[2] or 50
				if not speed or not tonumber(speed) then
					speed = 1000
				end
				for i,v in next,service.GetPlayers(plr,args[1]) do
					Remote.Send(v,"Function","Dizzy",tonumber(speed))
				end
			end
		};

		UnDizzy = {
			Prefix = Settings.Prefix;
			Commands = {"undizzy";};
			Args = {"player"};
			Description = "UnDizzy";
			AdminLevel = "Admins";
			Fun = true;
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.Send(v,"Function","Dizzy",false)
				end
			end
		};

		Davey = {
			Prefix = Settings.Prefix;
			Commands = {"Davey_Bones";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns you into me <3";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Admin.RunCommand(Settings.Prefix.."char",v.Name,"userid-698712377")
				end
			end
		};--//Ender was here

		Boombox = {
			Prefix = Settings.Prefix;
			Commands = {"boombox"};
			Args = {"player";};
			Hidden = false;
			Description = "Gives the target player(s) a boombox";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local gear = service.Insert(tonumber(212641536))
				if gear:IsA("Tool") or gear:IsA("HopperBin") then
					service.New("StringValue",gear).Name = Variables.CodeName..gear.Name
					for i, v in pairs(service.GetPlayers(plr,args[1])) do
						if v:findFirstChild("Backpack") then
							gear:Clone().Parent = v.Backpack
						end
					end
				end
			end
		};

		Infect = {
			Prefix = Settings.Prefix;
			Commands = {"infect";"zombify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a suit zombie";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local infect; infect = function(v)
					local char = v.Character
					if char and char:findFirstChild("HumanoidRootPart") and not char:FindFirstChild("Infected") then
						local cl = service.New("StringValue", char)
						cl.Name = "Infected"
						cl.Parent = char

						for q, prt in pairs(char:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Dark green")
								if prt.Name:find("Leg") or prt.Name:find('Arm') then
									prt.BrickColor = BrickColor.new("Dark green")
								end
								local tconn; tconn = prt.Touched:connect(function(hit)
									if hit and hit.Parent and service.Players:findFirstChild(hit.Parent.Name) and cl.Parent == char then
										infect(hit.Parent)
									elseif cl.Parent ~= char then
										tconn:disconnect()
									end
								end)

								cl.Changed:connect(function()
									if cl.Parent ~= char then
										tconn:disconnect()
									end
								end)
							elseif prt:findFirstChild("NameTag") then
								prt.Head.Transparency = 0
								prt.Head.Reflectance = 0
								prt.Head.BrickColor = BrickColor.new("Dark green")
							end
						end
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					infect(v)
				end
			end
		};

		Rainbowify = {
			Prefix = Settings.Prefix;
			Commands = {"rainbowify";"rainbow";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character flash random colors";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Core.NewScript("LocalScript",[[
					repeat
						wait(0.1)
						local char = script.Parent.Parent
						local clr = BrickColor.random()
						for i,v in pairs(char:children()) do
							if v:IsA("BasePart") and v.Name~='HumanoidRootPart' and (v.Name ~= "Head" or not v.Parent:findFirstChild("NameTag", true)) then
								v.BrickColor = clr
								v.Reflectance = 0
								v.Transparency = 0
							elseif v:findFirstChild("NameTag") then
								v.Head.BrickColor = clr
								v.Head.Reflectance = 0
								v.Head.Transparency = 0
								v.Parent.Head.Transparency = 1
							end
						end
					until not char
				]])
				scr.Name = "Effectify"

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"noobify";"noob";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look like a noob";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local bodyColors = service.New("BodyColors", {
					HeadColor = BrickColor.new("Bright yellow"),
					LeftArmColor = BrickColor.new("Bright yellow"),
					RightArmColor = BrickColor.new("Bright yellow"),
					LeftLegColor = BrickColor.new("Br. yellowish green"),
					RightLegColor = BrickColor.new("Br. yellowish green"),
					TorsoColor = BrickColor.new("Bright blue")
				})

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
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

		Color = {
			Prefix = Settings.Prefix;
			Commands = {"color";"bodycolor";};
			Args = {"player";"color";};
			Hidden = false;
			Description = "Make the target the color you choose";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Part") then
								if args[2] then
									local str = BrickColor.new('Institutional white').Color
									local teststr = args[2]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
							end
						end
					end
				end
			end
		};

		Material = {
			Prefix = Settings.Prefix;
			Commands = {"mat";"material";};
			Args = {"player";"material";};
			Hidden = false;
			Description = "Make the target the material you choose";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
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
					Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid material choice"})
					return
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
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
			Commands = {"neon";"neonify";};
			Args = {"player";"(optional)color";};
			Hidden = false;
			Description = "Make the target neon";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Shirt") or p:IsA("Pants") or p:IsA("ShirtGraphic") or p:IsA("CharacterMesh") or p:IsA("Accoutrement") then
								p:Destroy()
							elseif p:IsA("Part") then
								if args[2] then
									local str = BrickColor.new('Institutional white').Color
									local teststr = args[2]
									if BrickColor.new(teststr) ~= nil then str = BrickColor.new(teststr) end
									p.BrickColor = str
								end
								p.Material = "Neon"
								if p.Name=="Head" then
									local mesh=p:FindFirstChild("Mesh")
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
			Commands = {"ghostify";"ghost";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a ghost";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						Admin.RunCommand(Settings.Prefix.."noclip",v.Name)

						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end

						if v.Character:findFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = .5
								prt.Reflectance = 0
								prt.BrickColor = BrickColor.new("Institutional white")
								if prt.Name:find("Leg") then
									prt.Transparency = 1
								end
							elseif prt:findFirstChild("NameTag") then
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
			Commands = {"goldify";"gold";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) look like gold";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt.Parent = v.Character.HumanoidRootPart
						end

						if v.Character:findFirstChild("Pants") then
							v.Character.Pants.Parent = v.Character.HumanoidRootPart
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = .4
								prt.BrickColor = BrickColor.new("Bright yellow")
							elseif prt:findFirstChild("NameTag") then
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
			Commands = {"shiney";"shineify";"shine";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character shiney";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						if v.Character:findFirstChild("Shirt") then
							v.Character.Shirt:Destroy()
						end
						if v.Character:findFirstChild("Pants") then
							v.Character.Pants:Destroy()
						end

						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") and prt.Name~='HumanoidRootPart' and (prt.Name ~= "Head" or not prt.Parent:findFirstChild("NameTag", true)) then
								prt.Transparency = 0
								prt.Reflectance = 1
								prt.BrickColor = BrickColor.new("Institutional white")
							elseif prt:findFirstChild("NameTag") then
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
			Commands = {"spook";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s screen 2spooky4them";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Spooky"})
				end
			end
		};

		Thanos = {
			Prefix = Settings.Prefix;
			Commands = {"thanos", "thanossnap","balancetheserver", "snap"};
			Args = {"(opt)player"};
			Description = "\"Fun isn't something one considers when balancing the universe. But this... does put a smile on my face.\"";
			Fun = true;
			Hidden = false;
			AdminLevel = "Admins";
			Function = function(plr,args, data)
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

				for i = 1, #playerList*10 do
					if #players < math.max((#playerList/2), 1) then
						local index = math.random(1, #playerList)
						local targPlayer = playerList[index]
						if not deliverUs[targPlayer] then
							local targLevel = server.Admin.GetLevel(targPlayer)
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

				for i,p in next,players do
					service.TrackTask("Thread: Thanos", function()
						for t = 0.1,1.1,0.05 do
							if p.Character then
								local human = p.Character:FindFirstChildOfClass("Humanoid")
								if human then
									human.HealthDisplayDistance = 1
									human.NameDisplayDistance = 1
									human.HealthDisplayType = "AlwaysOff"
									human.NameOcclusion = "OccludeAll"
								end

								for k,v in ipairs(p.Character:GetChildren()) do
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
											em.Size = NumberSequence.new(2, 3, 1)
											em.Texture = "rbxassetid://173642823"
											em.Transparency = NumberSequence.new(0,1,0,0.051532,0,0,0.927577,0,0,1,1,0)
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
								part.Size = Vector3.new(0.1,0.1,0.1)
								part.CFrame = root.CFrame*CFrame.new(math.random(-3,3), math.random(-3,3), math.random(-3,3))
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

		iloveyou = {
			Prefix = "?";
			Commands = {"iloveyou";"alwaysnear";"alwayswatching";};
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "I love you. You are mine. Do not fear; I will always be near.";
			AdminLevel = "Players";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Effect",{Mode = "lifeoftheparty"})
			end
		};

		ifoundyou = {
			Prefix = Settings.Prefix;
			Commands = {"theycome","fromanotherworld","ufo","abduct","space","newmexico","area51","rockwell"};
			Args = {"player"};
			Description = "A world unlike our own.";
			Fun = true;
			Hidden = true;
			AdminLevel = "Admins";
			Function = function(plr,args)
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

				for i,p in next,service.GetPlayers(plr,args[1]) do
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

								for i = 1,200 do
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

									for i,v in next,p.Character:GetChildren() do
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

									for i,v in next,p.Character:GetChildren() do
										if v:IsA("BasePart") then
											v.Anchored = true
											v.Transparency = 1
											pcall(function() v:FindFirstChildOfClass("Decale"):Destroy() end)
										elseif v:IsA("Accoutrement") then
											v:Destroy()
										end
									end

									wait(1)

									server.Remote.MakeGui(p,"Effect",{
										Mode = "FadeOut";
									})

									for i = 1,260 do
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

										local gui = Instance.new("ScreenGui", service.ReplicatedStorage)
										local bg = Instance.new("Frame", gui)
										bg.BackgroundTransparency = 0
										bg.BackgroundColor3 = Color3.new(0,0,0)
										bg.Size = UDim2.new(2,0,2,0)
										bg.Position = UDim2.new(-0.5,0,-0.5,0)
										if p and p.Parent == service.Players then service.TeleportService:Teleport(6806826116,p,nil,bg) end
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

		Blind = {
			Prefix = Settings.Prefix;
			Commands = {"blind";};
			Args = {"player";};
			Hidden = false;
			Description = "Blinds the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Blind"})
				end
			end
		};

		ScreenImage = {
			Prefix = Settings.Prefix;
			Commands = {"screenimage";"scrimage";"image";};
			Args = {"player";"textureid";};
			Hidden = false;
			Description = "Places the desired image on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "ScreenImage",Image = args[2]})
				end
			end
		};

		ScreenVideo = {
			Prefix = Settings.Prefix;
			Commands = {"screenvideo";"scrvid";"video";};
			Args = {"player";"videoid";};
			Hidden = false;
			Description = "Places the desired video on the target's screen";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local img = tostring(args[2])
				if not img then error(args[2].." is not a valid ID") end
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "ScreenVideo",Video = args[2]})
				end
			end
		};

		UnEffect = {
			Prefix = Settings.Prefix;
			Commands = {"uneffect";"unimage";"uneffectgui";"unspook";"unblind";"unstrobe";"untrippy";"unpixelize","unlowres","unpixel","undance";"unflashify";"unrainbowify";"guifix";"fixgui";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes any effect GUIs on the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Remote.MakeGui(v,"Effect",{Mode = "Off"})
				end
			end
		};

		Forest = {
			Prefix = Settings.Prefix;
			Commands = {"forest";"sendtotheforest";"intothewoods";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Forest for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(209424751,v)
					end
				end
			end
		};

		Maze = {
			Prefix = Settings.Prefix;
			Commands = {"maze";"sendtothemaze";"mazerunner";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends player to The Maze for a time out";
			Fun = true;
			AdminLevel = "Admins";
			Function = function(plr,args,data)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if data.PlayerData.Level>Admin.GetLevel(v) then
						service.TeleportService:Teleport(280846668,v)
					end
				end
			end
		};

		ClownYoink = {
			Prefix = Settings.Prefix; 					-- Someone's always watching me
			Commands = {"clown","yoink","youloveme","van"};   	-- Someone's always there
			Args = {"player"}; 									-- When I'm sleeping he just waits
			Description = "Clowns."; 							-- And he stares
			Fun = true; 										-- Someone's always standing in the
			Hidden = true; 										-- Darkest corner of my room
			AdminLevel = "Admins"; 								-- He's tall and wears a suit of black,
			Function = function(plr,args) 						-- Dressed like the perfect groom
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

				for i,p in next,service.GetPlayers(plr,args[1]) do
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

								local sound = Instance.new("Sound",primary)
								sound.SoundId = "rbxassetid://258529216"
								sound.Looped = true
								sound:Play()

								local chuckle = Instance.new("Sound",primary)
								chuckle.SoundId = "rbxassetid://164516281"
								chuckle.Looped = true
								chuckle.Volume = 0.25
								chuckle:Play()

								van.PrimaryPart = van.Primary
								van.Name = "ADONIS_VAN"
								van.Parent = workspace
								humanoid.Name = "NoResetForYou"
								humanoid.WalkSpeed = 0
								sound.Pitch = 1.3

								server.Remote.PlayAudio(p,421358540,0.2,1,true)

								for i = 1,200 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(-200+i,-1,-7)*CFrame.Angles(0,math.rad(270),0)))
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
									torso.CFrame = primary.CFrame*(CFrame.new(0,2.3,0)*CFrame.Angles(0,math.rad(90),0))
								end

								wait(0.5)
								if check() then
									door.Transparency = 0
								end
								wait(0.5)

								sound.Pitch = 1.3
								server.Remote.MakeGui(p,"Effect",{
									Mode = "FadeOut";
								})

								p.CameraMaxZoomDistance = 0.5

								for i = 1,400 do
									if not check() then
										break
									else
										van:SetPrimaryPartCFrame(tPos*(CFrame.new(0+i,-1,-7)*CFrame.Angles(0,math.rad(270),0)))
										torso.CFrame = primary.CFrame*(CFrame.new(0,2.3,0)*CFrame.Angles(0,math.rad(90),0))
										wait(0.1/(i*5))

										if i == 270 then
											server.Remote.FadeAudio(p,421358540,nil,nil,0.5)
										end
									end
								end

								local gui = Instance.new("ScreenGui",service.ReplicatedStorage)
								local bg = Instance.new("Frame", gui)
								bg.BackgroundTransparency = 0
								bg.BackgroundColor3 = Color3.new(0,0,0)
								bg.Size = UDim2.new(2,0,2,0)
								bg.Position = UDim2.new(-0.5,0,-0.5,0)
								if p and p.Parent == service.Players then service.TeleportService:Teleport(527443962,p,nil,bg) end
								wait(0.5)
								pcall(function() van:Destroy() end)
								pcall(function() gui:Destroy() end)
							end
						end
					end)
				end
			end;
		};


		Chik3n = {
			Prefix = Settings.Prefix;
			Commands = {"chik3n","zelith","z3lith"};
			Args = {};
			Hidden = false;
			Description = "Call on the KFC dark prophet powers of chicken";
			Fun = true;
			AdminLevel = "HeadAdmins";
			Function = function(plr, args)
				local hats = {}
				local tempHats = {}
				local run = true
				local hat = service.Insert(24112667):children()[1]
				--
				local scr = Deps.Assets.Quacker:Clone()
				scr.Name = "Quacker"
				scr.Parent = hat
				--]]
				hat.Anchored = true
				hat.CanCollide = false
				hat.ChickenSounds.Disabled = true
				table.insert(hats,hat)
				table.insert(Variables.Objects,hat)
				hat.Parent = workspace
				hat.CFrame = plr.Character.Head.CFrame
				service.StopLoop("ChickenSpam")
				service.StartLoop("ChickenSpam",5,function()
					tempHats = {}
					for i,v in pairs(hats) do
						wait(0.5)
						if not hat or not hat.Parent or not scr or not scr.Parent then
							break
						end
						local nhat = hat:Clone()
						table.insert(tempHats, v)
						table.insert(tempHats,nhat)
						table.insert(Variables.Objects,nhat)
						nhat.Parent = workspace
						nhat.Quacker.Disabled = false
						nhat.CFrame = v.CFrame*CFrame.new(math.random(-100,100),math.random(-100,100),math.random(-100,100))*CFrame.Angles(math.random(-360,360),math.random(-360,360),math.random(-360,360))
					end
					hats = tempHats
				end)
				for i,v in pairs(tempHats) do
					pcall(function() v:Destroy() end)
					table.remove(tempHats,i)
				end
				for i,v in pairs(hats) do
					pcall(function() v:Destroy() end)
					table.remove(hats,i)
				end
			end;
		};

		Tornado = {
			Prefix = Settings.Prefix;
			Commands = {"tornado";"twister";};
			Args = {"player";"optional time";};
			Description = "Makes a tornado on the target player(s)";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local p=service.New('Part',service.Workspace)
					table.insert(Variables.Objects,p)
					p.Transparency=1
					p.CFrame=v.Character.HumanoidRootPart.CFrame+Vector3.new(0,-3,0)
					p.Size=Vector3.new(0.2,0.2,0.2)
					p.Anchored=true
					p.CanCollide=false
					p.Archivable=false
					--local tornado=deps.Tornado:clone()
					--tornado.Parent=p
					--tornado.Disabled=false
					local cl=Core.NewScript('Script',[[
						local Pcall=function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=pcall(cour,...) if error then print('Error: '..error) end end
						local parts = {}
						local main=script.Parent
						main.Anchored=true
						main.CanCollide=false
						main.Transparency=1
						local smoke=Instance.new("Smoke",main)
						local sound=Instance.new("Sound",main)
						smoke.RiseVelocity=25
						smoke.Size=25
						smoke.Color=Color3.new(170/255,85/255,0)
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
							local pos=Instance.new("BodyPosition",part)
							pos.maxForce = Vector3.new(math.huge,math.huge,math.huge)--10000, 10000, 10000)
							pos.position = part.Position
							local i=1
							local run=true
							while main and wait() and run do
								if part.Position.Y>=main.Position.Y+50 then
									run=false
								end
								pos.position=Vector3.new(50*math.cos(i),part.Position.Y+5,50*math.sin(i))+main.Position
								i=i+1
							end
							pos.maxForce = Vector3.new(500, 500, 500)
							pos.position=Vector3.new(main.Position.X+math.random(-100,100),main.Position.Y+100,main.Position.Z+math.random(-100,100))
							pos:Destroy()
						end

						function get(obj)
							if obj ~= main and obj:IsA("Part") then
								table.insert(parts, 1, obj)
							elseif obj:IsA("Model") or obj:IsA("Accoutrement") or obj:IsA("Tool") or obj == workspace then
								for i,v in pairs(obj:children()) do
									Pcall(get,v)
								end
								obj.ChildAdded:connect(function(p)Pcall(get,p)end)
							end
						end

						get(workspace)

						repeat
							for i,v in pairs(parts) do
								if (((main.Position - v.Position).magnitude * 250 * 20) < (5000 * 40)) and v and v:IsDescendantOf(workspace) then
									coroutine.wrap(fling,v)
								elseif not v or not v:IsDescendantOf(workspace) then
									table.remove(parts,i)
								end
							end
							main.CFrame = main.CFrame + Vector3.new(math.random(-3,3), 0, math.random(-3,3))
							wait()
					until main.Parent~=workspace or not main]])
					cl.Parent=p
					cl.Disabled=false
					if args[2] and tonumber(args[2]) then
						for i=1,tonumber(args[2]) do
							if not p or not p.Parent then
								return
							end
							wait(1)
						end
						if p then p:Destroy() end
					end
				end
			end
		};

		Nuke = {
			Prefix = Settings.Prefix;
			Commands = {"nuke";};
			Args = {"player";};
			Description = "Nuke the target player(s)";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr,args)
				local nukes = {}
				local partsHit = {}

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						local p = service.New("Part", {
							Name = "ADONIS_NUKE";
							Anchored = true;
							CanCollide = false;
							formFactor = "Symmetric";
							Shape = "Ball";
							Size = Vector3.new(1,1,1);
							Position = human.Position;
							BrickColor = BrickColor.new("New Yeller");
							Transparency = .5;
							Reflectance = .2;
							TopSurface = 0;
							BottomSurface = 0;
							Parent = service.Workspace;
						})

						p.Touched:Connect(function(hit)
							if not partsHit[hit] then
								partsHit[hit] = true
								hit:BreakJoints()
								service.New("Explosion", {
									Position = hit.Position;
									BlastRadius = 10000;
									BlastPressure = math.huge;
									Parent = service.Workspace;
								})

							end
						end)

						table.insert(Variables.Objects, p)
						table.insert(nukes, p)
					end
				end

				for i = 1, 333 do
					for i,v in next,nukes do
						local curPos = v.CFrame
						v.Size = v.Size + Vector3.new(3, 3, 3)
						v.CFrame = curPos
					end
					wait(1/44)
				end

				for i,v in next,nukes do
					v:Destroy()
				end

				nukes = nil
				partsHit = nil
			end
		};

		UnWildFire = {
			Prefix = Settings.Prefix;
			Commands = {"stopwildfire", "removewildfire", "unwildfire";};
			Args = {};
			Description = "Stops :wildfire from spreading further";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr,args)
				Variables.WildFire = nil
			end
		};

		WildFire = {
			Prefix = Settings.Prefix;
			Commands = {"wildfire";};
			Args = {"player";};
			Description = "Starts a fire at the target player(s); Ignores locked parts and parts named 'BasePlate' or 'Baseplate'";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr,args)
				local finished = false
				local partsHit = {}
				local objs = {}

				Variables.WildFire = partsHit

				function fire(part)
					if finished or not partsHit or not objs then
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and Variables.WildFire ~= partsHit then
						for i,v in next,objs do
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

						part.Touched:connect(fire)

						for i = 0.1, 1, 0.1 do
							part.Color = oColor:lerp(Color3.new(0, 0, 0), i)
							wait(math.random(5))
						end

						local ex = service.New("Explosion", {
							Position = part.Position;
							BlastRadius = fSize*2;
							BlastPressure = 0;
						})

						ex.Hit:connect(fire)
						ex.Parent = service.Workspace;
						part.Anchored = false
						part:BreakJoints()
						f:Destroy()
						l:Destroy()
					end
				end

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
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
			Commands = {"swagify";"swagger";};
			Args = {"player";};
			Hidden = false;
			Description = "Swag the target player(s) up";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for i,v in pairs(v.Character:children()) do
							if v.Name == "Shirt" then local cl = v:Clone() cl.Parent = v.Parent cl.ShirtTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
							if v.Name == "Pants" then local cl = v:Clone() cl.Parent = v.Parent cl.PantsTemplate = "http://www.roblox.com/asset/?id=109163376" v:Destroy() end
						end
						Functions.Cape(v,false,'Fabric','Pink',109301474)
					end
				end
			end
		};

		Shrek = {
			Prefix = Settings.Prefix;
			Commands = {"shrek";"shrekify";"shrekislife";"swamp";};
			Args = {"player";};
			Hidden = false;
			Description = "Shrekify the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
							Admin.RunCommand(Settings.Prefix.."pants",v.Name,"233373970")
							Admin.RunCommand(Settings.Prefix.."shirt",v.Name,"133078195")

							for i,v in pairs(v.Character:children()) do
								if v:IsA("Accoutrement") or v:IsA("CharacterMesh") then
									v:Destroy()
								end
							end

							Admin.RunCommand(Settings.Prefix.."hat",v.Name,"20011951")

							local sound = service.New("Sound",v.Character.HumanoidRootPart)
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
			Commands = {"rocket";"firework";};
			Args = {"player";};
			Hidden = false;
			Description = "Send the target player(s) to the moon!";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
							SpecialMesh.Scale = Vector3.new(0.5,0.5,0.5)
							local Weld = service.New("Weld")
							Weld.Parent = Part
							Weld.Part0 = Part
							Weld.Part1 = v.Character.HumanoidRootPart
							Weld.C0 = CFrame.new(0,-1,0)*CFrame.Angles(-1.5,0,0)
							local BodyVelocity = service.New("BodyVelocity")
							BodyVelocity.Parent = Part
							BodyVelocity.maxForce = Vector3.new(math.huge,math.huge,math.huge)
							BodyVelocity.velocity = Vector3.new(0,100*speed,0)
									--[[
									cPcall(function()
										for i = 1,math.huge do
											local Explosion = service.New("Explosion")
											Explosion.Parent = Part
											Explosion.BlastRadius = 0
											Explosion.Position = Part.Position + Vector3.new(0,0,0)
											wait()
										end
									end)
									--]]
							wait(5)
							BodyVelocity:remove()
							if knownchar.Parent then
								service.New("Explosion",service.Workspace).Position = knownchar.HumanoidRootPart.Position
								knownchar:BreakJoints()
							end
						end
					end)
				end
			end
		};

		Dance = {
			Prefix = Settings.Prefix;
			Commands = {"dance";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.PlayAnimation(v,27789359)
				end
			end
		};

		BreakDance = {
			Prefix = Settings.Prefix;
			Commands = {"breakdance";"fundance";"lolwut";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) break dance";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						local color
						local num=math.random(1,7)
						if num==1 then
							color='Really blue'
						elseif num==2 then
							color='Really red'
						elseif num==3 then
							color='Magenta'
						elseif num==4 then
							color='Lime green'
						elseif num==5 then
							color='Hot pink'
						elseif num==6 then
							color='New Yeller'
						elseif num==7 then
							color='White'
						end
						local hum=v.Character:FindFirstChild('Humanoid')
						if not hum then return end
						--Remote.Send(v,'Function','Effect','dance')
						Admin.RunCommand(Settings.Prefix.."sparkles",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."fire",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."nograv",v.Name)
						Admin.RunCommand(Settings.Prefix.."smoke",v.Name,color)
						Admin.RunCommand(Settings.Prefix.."spin",v.Name)
						repeat hum.PlatformStand=true wait() until not hum or hum==nil or hum.Parent==nil
					end)
				end
			end
		};

		Puke = {
			Prefix = Settings.Prefix;
			Commands = {"puke";"barf";"throwup";"vomit";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) puke";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if (not v:IsA('Player')) or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head')) or v.Character:FindFirstChild('Epix Puke') then return end
						local run=true
						local k=service.New('StringValue',v.Character)
						k.Name='Epix Puke'
						Routine(function()
							repeat
								wait(0.15)
								local p = service.New("Part",v.Character)
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
								local m = service.New('BlockMesh',p)
								p.Size = Vector3.new(0.1,0.1,0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.Head.CFrame * CFrame.new(Vector3.new(0, 0, -1))
								p.Velocity = v.Character.Head.CFrame.lookVector * 20 + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
								p.Anchored = false
								m.Name = 'Puke Peice'
								p.Name = 'Puke Peice'
								p.Touched:connect(function(o)
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name~='Puke Peice' and o.Name~='Blood Peice' and o.Name~='Blood Plate' and o.Name~='Puke Plate' and (o.Parent.Name=='Workspace' or o.Parent:IsA('Model')) and (o.Parent~=p.Parent) and o:IsA('Part') and (o.Parent.Name~=v.Character.Name) and (not o.Parent:IsA('Accessory')) and (not o.Parent:IsA('Tool')) then
										local cf = CFrame.new(p.CFrame.X,o.CFrame.Y+o.Size.Y/2,p.CFrame.Z)
										p:Destroy()
										local g=service.New('Part',service.Workspace)
										g.Anchored=true
										g.CanCollide=false
										g.Size=Vector3.new(0.1,0.1,0.1)
										g.Name='Puke Plate'
										g.CFrame=cf
										g.BrickColor=BrickColor.new(119)
										local c=service.New('CylinderMesh',g)
										c.Scale=Vector3.new(1,0.2,1)
										c.Name='PukeMesh'
										wait(10)
										g:Destroy()
									elseif o and o.Name=='Puke Plate' and p then
										p:Destroy()
										o.PukeMesh.Scale=o.PukeMesh.Scale+Vector3.new(0.5,0,0.5)
									end
								end)
							until run==false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head'))
						end)
						wait(10)
						run = false
						k:Destroy()
					end)
				end
			end
		};

		Cut = {
			Prefix = Settings.Prefix;
			Commands = {"cut";"stab";"shank";"bleed";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s) bleed";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					cPcall(function()
						if (not v:IsA('Player')) or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head')) or v.Character:FindFirstChild('Epix Bleed') then return end
						local run=true
						local k=service.New('StringValue',v.Character)
						k.Name='ADONIS_BLEED'
						Routine(function()
							repeat
								wait(0.15)
								v.Character.Humanoid.Health=v.Character.Humanoid.Health-1
								local p = service.New("Part",v.Character)
								p.CanCollide = false
								local color = math.random(1, 3)
								local bcolor
								if color == 1 then
									bcolor = BrickColor.new(21)
								elseif color == 2 then
									bcolor = BrickColor.new(1004)
								elseif color == 3 then
									bcolor = BrickColor.new(21)
								end
								p.BrickColor = bcolor
								local m=service.New('BlockMesh',p)
								p.Size=Vector3.new(0.1,0.1,0.1)
								m.Scale = Vector3.new(math.random()*0.9, math.random()*0.9, math.random()*0.9)
								p.Locked = true
								p.TopSurface = "Smooth"
								p.BottomSurface = "Smooth"
								p.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(Vector3.new(2, 0, 0))
								p.Velocity = v.Character.Head.CFrame.lookVector * 1 + Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1))
								p.Anchored = false
								m.Name='Blood Peice'
								p.Name='Blood Peice'
								p.Touched:connect(function(o)
									if not o or not o.Parent then return end
									if o and p and (not service.Players:FindFirstChild(o.Parent.Name)) and o.Name~='Blood Peice' and o.Name~='Puke Peice' and o.Name~='Puke Plate' and o.Name~='Blood Plate' and (o.Parent.Name=='Workspace' or o.Parent:IsA('Model')) and (o.Parent~=p.Parent) and o:IsA('Part') and (o.Parent.Name~=v.Character.Name) and (not o.Parent:IsA('Accessory')) and (not o.Parent:IsA('Tool')) then
										local cf=CFrame.new(p.CFrame.X,o.CFrame.Y+o.Size.Y/2,p.CFrame.Z)
										p:Destroy()
										local g=service.New('Part',service.Workspace)
										g.Anchored=true
										g.CanCollide=false
										g.Size=Vector3.new(0.1,0.1,0.1)
										g.Name='Blood Plate'
										g.CFrame=cf
										g.BrickColor=BrickColor.new(21)
										local c=service.New('CylinderMesh',g)
										c.Scale=Vector3.new(1,0.2,1)
										c.Name='BloodMesh'
										wait(10)
										g:Destroy()
									elseif o and o.Name=='Blood Plate' and p then
										p:Destroy()
										o.BloodMesh.Scale=o.BloodMesh.Scale+Vector3.new(0.5,0,0.5)
									end
								end)
							until run==false or not k or not k.Parent or (not v) or (not v.Character) or (not v.Character:FindFirstChild('Head'))
						end)
						wait(10)
						run=false
						k:Destroy()
					end)
				end
			end
		};

		Poison = {
			Prefix = Settings.Prefix;
			Commands = {"poison";};
			Args = {"player";};
			Hidden = false;
			Description = "Slowly kills the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local torso=v.Character:FindFirstChild('HumanoidRootPart')
						local larm=v.Character:FindFirstChild('Left Arm')
						local rarm=v.Character:FindFirstChild('Right Arm')
						local lleg=v.Character:FindFirstChild('Left Leg')
						local rleg=v.Character:FindFirstChild('Right Leg')
						local head=v.Character:FindFirstChild('Head')
						local hum=v.Character:FindFirstChild('Humanoid')
						if torso and larm and rarm and lleg and rleg and head and hum and not v.Character:FindFirstChild('EpixPoisoned') then
							local poisoned=service.New('BoolValue',v.Character)
							poisoned.Name='EpixPoisoned'
							poisoned.Value=true
							local tor=torso.BrickColor
							local lar=larm.BrickColor
							local rar=rarm.BrickColor
							local lle=lleg.BrickColor
							local rle=rleg.BrickColor
							local hea=head.BrickColor
							torso.BrickColor=BrickColor.new('Br. yellowish green')
							larm.BrickColor=BrickColor.new('Br. yellowish green')
							rarm.BrickColor=BrickColor.new('Br. yellowish green')
							lleg.BrickColor=BrickColor.new('Br. yellowish green')
							rleg.BrickColor=BrickColor.new('Br. yellowish green')
							head.BrickColor=BrickColor.new('Br. yellowish green')
							local run=true
							coroutine.wrap(function() wait(10) run=false end)()
							repeat
								wait(1)
								hum.Health=hum.Health-5
							until (not poisoned) or (not poisoned.Parent) or (not run)
							if poisoned and poisoned.Parent then
								torso.BrickColor=tor
								larm.BrickColor=lar
								rarm.BrickColor=rar
								lleg.BrickColor=lle
								rleg.BrickColor=rle
								head.BrickColor=hea
							end
						end
					end)
				end
			end
		};

		HatPets = {
			Prefix = Settings.Prefix;
			Commands = {"hatpets";};
			Args = {"player";"number[50 MAX]/destroy";};
			Hidden = false;
			Description = "Gives the target player(s) hat pets, controled using the !pets command.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if args[2] and args[2]:lower()=='destroy' then
						local hats = v.Character:FindFirstChild('ADONIS_HAT_PETS')
						if hats then hats:Destroy() end
					else
						local num = tonumber(args[2]) or 5
						if num>50 then num = 50 end
						if v.Character:FindFirstChild('HumanoidRootPart') then
							local m = v.Character:FindFirstChild('ADONIS_HAT_PETS')
							local mode
							local obj
							local hat
							if not m then
								m = service.New('Model',v.Character)
								m.Name = 'ADONIS_HAT_PETS'
								table.insert(Variables.Objects,m)
								mode = service.New('StringValue',m)
								mode.Name = 'Mode'
								mode.Value = 'Follow'
								obj = service.New('ObjectValue',m)
								obj.Name = 'Target'
								obj.Value = v.Character.HumanoidRootPart

								local scr = Deps.Assets.HatPets:Clone()
								scr.Parent = m
								scr.Disabled = false
							else
								mode = m.Mode
								obj = m.Target
							end

							for l,h in pairs(v.Character:children()) do
								if h:IsA('Accessory') then
									hat = h
									break
								end
							end

							if hat then
								for k = 1,num do
									local cl = hat.Handle:clone()
									cl.Name = k
									cl.CanCollide = false
									cl.Anchored = false
									cl.Parent = m
									cl:BreakJoints()
									local att = cl:FindFirstChild("HatAttachment")
									if att then att:Destroy() end
									local bpos = service.New("BodyPosition",cl)
									bpos.Name = 'bpos'
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
			Commands = {"pets";};
			Args = {"follow/float/swarm/attack";"player";};
			Hidden = false;
			Description = "Makes your hat pets do the specified command (follow/float/swarm/attack)";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr,args)
				local hats = plr.Character:FindFirstChild('ADONIS_HAT_PETS')
				if hats then
					for i,v in pairs(service.GetPlayers(plr,args[2])) do
						if v.Character:FindFirstChild('HumanoidRootPart') and v.Character.HumanoidRootPart:IsA('Part') then
							if args[1]:lower()=='follow' then
								hats.Mode.Value='Follow'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='float' then
								hats.Mode.Value='Float'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='swarm' then
								hats.Mode.Value='Swarm'
								hats.Target.Value=v.Character.HumanoidRootPart
							elseif args[1]:lower()=='attack' then
								hats.Mode.Value='Attack'
								hats.Target.Value=v.Character.HumanoidRootPart
							end
						end
					end
				else
					Functions.Hint("You don't have any hat pets! If you are an admin use the :hatpets command to get some",{plr})
				end
			end
		};

		RestoreGravity = {
			Prefix = Settings.Prefix;
			Commands = {"grav";"bringtoearth";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s)'s gravity normal";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy() end
						end
					end
				end
			end
		};

		SetGravity = {
			Prefix = Settings.Prefix;
			Commands = {"setgrav";"gravity";"setgravity";};
			Args = {"player";"number";};
			Hidden = false;
			Description = "Set the target player(s)'s gravity";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0,0,0)
						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force - Vector3.new(0,prt:GetMass()*tonumber(args[2]),0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force - Vector3.new(0,prt.Handle:GetMass()*tonumber(args[2]),0)
							end
						end
					end
				end
			end
		};

		NoGravity = {
			Prefix = Settings.Prefix;
			Commands = {"nograv";"nogravity";"superjump";};
			Args = {"player";};
			Hidden = false;
			Description = "NoGrav the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v and v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a, frc in pairs(v.Character.HumanoidRootPart:children()) do
							if frc.Name == "ADONIS_GRAVITY" then
								frc:Destroy()
							end
						end

						local frc = service.New("BodyForce", v.Character.HumanoidRootPart)
						frc.Name = "ADONIS_GRAVITY"
						frc.force = Vector3.new(0,0,0)
						for a, prt in pairs(v.Character:children()) do
							if prt:IsA("BasePart") then
								frc.force = frc.force + Vector3.new(0,prt:GetMass()*196.25,0)
							elseif prt:IsA("Accoutrement") then
								frc.force = frc.force + Vector3.new(0,prt.Handle:GetMass()*196.25,0)
							end
						end
					end
				end
			end
		};

		BunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"bunnyhop";"bhop"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the player jump, and jump... and jump. Just like the rabbit noobs you find in sf games ;)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local bunnyScript = Deps.Assets.BunnyHop
				bunnyScript.Name = "HippityHopitus"
				local hat = service.Insert(110891941)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					hat:Clone().Parent = v.Character
					local clone = bunnyScript:Clone()
					clone.Parent = v.Character
					clone.Disabled = false
				end
			end
		};

		UnBunnyHop = {
			Prefix = Settings.Prefix;
			Commands = {"unbunnyhop";};
			Args = {"player";};
			Hidden = false;
			Description = "Stops the forced hippity hoppening";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
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
			Commands = {"freefall";"skydive";};
			Args = {"player";"height";};
			Hidden = false;
			Description = "Teleport the target player(s) up by <height> studs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character:FindFirstChild('HumanoidRootPart') then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame+Vector3.new(0,tonumber(args[2]),0)
					end
				end
			end
		};

		Stickify = {
			Prefix = Settings.Prefix;
			Commands = {"stickify";"stick";"stickman";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns the target player(s) into a stick figure";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for kay,player in pairs(service.GetPlayers(plr,args[1])) do
					local m = player.Character
					for i,v in pairs(m:GetChildren()) do
						if v:IsA("Part") then
							local s = service.New("SelectionPartLasso")
							s.Parent = m.HumanoidRootPart
							s.Part = v
							s.Humanoid = m.Humanoid
							s.Color = BrickColor.new(0,0,0)
							v.Transparency = 1
							m.Head.Transparency = 0
							m.Head.Mesh:Remove()
							local b = service.New("SpecialMesh")
							b.Parent = m.Head
							b.MeshType = "Sphere"
							b.Scale = Vector3.new(0.5,1,1)
							m.Head.BrickColor = BrickColor.new("Black")
						end
					end
				end
			end
		};

		Hole = {
			Prefix = Settings.Prefix;
			Commands = {"hole";"sparta";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends the target player(s) down a hole";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for kay, player in pairs(service.GetPlayers(plr,args[1])) do
					Routine(function()
						local torso = player.Character:FindFirstChild('HumanoidRootPart')
						if torso then
							local hole = service.New("Part",player.Character)
							hole.Anchored = true
							hole.CanCollide = false
							hole.formFactor = Enum.FormFactor.Custom
							hole.Size = Vector3.new(10,1,10)
							hole.CFrame = torso.CFrame * CFrame.new(0,-3.3,-3)
							hole.BrickColor = BrickColor.new("Really black")
							local holeM = service.New("CylinderMesh",hole)
							torso.Anchored = true
							local foot = torso.CFrame * CFrame.new(0,-3,0)
							for i=1,10 do
								torso.CFrame = foot * CFrame.fromEulerAnglesXYZ(-(math.pi/2)*i/10,0,0) * CFrame.new(0,3,0)
								wait(0.1)
							end
							for i=1,5,0.2 do
								torso.CFrame = foot * CFrame.new(0,-(i^2),0) * CFrame.fromEulerAnglesXYZ(-(math.pi/2),0,0) * CFrame.new(0,3,0)
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
			Commands = {"lightning";"smite";};
			Args = {"player";};
			Hidden = false;
			Description = "Zeus strikes down the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						Admin.RunCommand(Settings.Prefix.."freeze",v.Name)
						local char = v.Character
						local zeus = service.New("Model",char)
						local cloud = service.New("Part",zeus)
						cloud.Anchored = true
						cloud.CanCollide = false
						cloud.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,25,0)
						local sound = service.New("Sound",cloud)
						sound.SoundId = "rbxassetid://133426162"
						local mesh = service.New("SpecialMesh",cloud)
						mesh.MeshId = "http://www.roblox.com/asset/?id=1095708"
						mesh.TextureId = "http://www.roblox.com/asset/?id=1095709"
						mesh.Scale = Vector3.new(30,30,40)
						mesh.VertexColor = Vector3.new(0.3,0.3,0.3)
						local light = service.New("PointLight",cloud)
						light.Color = Color3.new(0,85/255,1)
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
						local part1 = service.New("Part",zeus)
						part1.Anchored = true
						part1.CanCollide = false
						part1.Size = Vector3.new(2, 9.2, 1)
						part1.BrickColor = BrickColor.new("New Yeller")
						part1.Transparency = 0.6
						part1.BottomSurface = "Smooth"
						part1.TopSurface = "Smooth"
						part1.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,15,0)
						part1.Rotation = Vector3.new(0.359, 1.4, -14.361)
						wait()
						local part2 = part1:clone()
						part2.Parent = zeus
						part2.Size = Vector3.new(1, 7.48, 2)
						part2.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,7.5,0)
						part2.Rotation = Vector3.new(77.514, -75.232, 78.051)
						wait()
						local part3 = part1:clone()
						part3.Parent = zeus
						part3.Size = Vector3.new(1.86, 7.56, 1)
						part3.CFrame = char.HumanoidRootPart.CFrame*CFrame.new(0,1,0)
						part3.Rotation = Vector3.new(0, 0, -11.128)
						sound.SoundId = "rbxassetid://130818250"
						sound.Volume = 1
						sound.Pitch = 1
						sound:Play()
						wait()
						part1.Transparency = 1
						part2.Transparency = 1
						part3.Transparency = 1
						service.New("Smoke",char.HumanoidRootPart).Color = Color3.new(0,0,0)
						char:BreakJoints()
					end)
				end
			end
		};

		Disco = {
			Prefix = Settings.Prefix;
			Commands = {"disco";};
			Args = {};
			Hidden = false;
			Description = "Turns the place into a disco party";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				service.StopLoop("LightingTask")
				service.StartLoop("LightingTask",0.5,function()
					local color = Color3.new(math.random(255)/255,math.random(255)/255,math.random(255)/255)
					Functions.SetLighting("Ambient",color)
					Functions.SetLighting("OutdoorAmbient",color)
					Functions.SetLighting("FogColor",color)
				end)
			end
		};

		Spin = {
			Prefix = Settings.Prefix;
			Commands = {"spin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) spin";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Deps.Assets.Spinner:Clone()
				scr.Name = "SPINNER"
				local bg = Instance.new("BodyGyro")
				bg.Name = "SPINNER_GYRO"
				bg.maxTorque = Vector3.new(0,math.huge,0)
				bg.P = 11111
				bg.D = 0
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a,q in pairs(v.Character.HumanoidRootPart:children()) do
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
			Commands = {"unspin";};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) stop spinning";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						for a,q in pairs(v.Character.HumanoidRootPart:children()) do
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
			Commands = {"dog";"dogify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a dog";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(p,args)
				for i,plr in pairs(service.GetPlayers(p,args[1])) do
					--Routine(function()
					if (plr and plr.Character and plr.Character:FindFirstChild"HumanoidRootPart") then
						local human = plr.Character:FindFirstChildOfClass"Humanoid"

						if not human then
							Remote.MakeGui(p,'Output',{Title = 'Output'; Message = plr.Name.." doesn't have a Humanoid [Transformation Error]"})
							return
						end

						if human.RigType == Enum.HumanoidRigType.R6 then
							if plr.Character:FindFirstChild"Shirt" then
								plr.Character.Shirt.Parent = plr.Character.HumanoidRootPart
							end
							if plr.Character:FindFirstChild"Pants" then
								plr.Character.Pants.Parent = plr.Character.HumanoidRootPart
							end
							local char, torso, ca1, ca2 = plr.Character, plr.Character:FindFirstChild"Torso" or plr.Character:FindFirstChild"UpperTorso", CFrame.Angles(0, math.rad(90), 0), CFrame.Angles(0, math.rad(-90), 0)
							local head = char:FindFirstChild"Head"

							torso.Transparency = 1

							for i,v in next,torso:GetChildren() do
								if v:IsA'Motor6D' then
									local lc0 = service.New('CFrameValue', {Name='LastC0';Value=v.C0;Parent=v})
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

							for d,e in next, char:GetDescendants() do
								if e:IsA"BasePart" then
									e.BrickColor = BrickColor.new("Brown")
								end
							end
						elseif human.RigType == Enum.HumanoidRigType.R15 then
							Remote.MakeGui(p,'Output',{Title = 'Output'; Message = "Cannot support R15 for "..plr.Name.." [Dog Transformation Error]"})
						end
					end
					--end)
				end
			end
		};

		Dogg = {
			Prefix = Settings.Prefix;
			Commands = {"dogg";"snoop";"snoopify";"dodoubleg";};
			Args = {"player";};
			Hidden = false;
			Description = "Turns the target into the one and only D O Double G";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Dogg:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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
			Commands = {"sp00ky";"spooky";"spookyscaryskeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Sends shivers down ur spine";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Sp00ks:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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
			Commands = {"k1tty";"cut3";};
			Args = {"player";};
			Hidden = false;
			Description = "2 cute 4 u";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Kitty:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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
			Commands = {"nyan";"p0ptart"};
			Args = {"player";};
			Hidden = false;
			Description = "Poptart kitty";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Nyan1:Clone()
				local c2 = Deps.Assets.Nyan2:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(0.1,4.8,20)

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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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
			Commands = {"fr0g";"fr0ggy";"mlgfr0g";"mlgfrog";};
			Args = {"player";};
			Hidden = false;
			Description = "MLG fr0g";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Fr0g:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)
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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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
			Commands = {"sh1a";"lab00f";"sh1alab00f";"shia"};
			Args = {"player";};
			Hidden = false;
			Description = "Sh1a LaB00f";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local cl = Deps.Assets.Shia:Clone()

				local mesh = service.New("BlockMesh")
				mesh.Scale = Vector3.new(2,3,0.1)

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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					for k,p in pairs(v.Character.HumanoidRootPart:GetChildren()) do
						if p:IsA("Decal") or p:IsA("Sound") then
							p:Destroy()
						end
					end

					local sound = sound:Clone()
					local decal1 = decal1:Clone()
					local decal2 = decal2:Clone()
					local mesh = mesh:Clone()

					Admin.RunCommand(Settings.Prefix.."removehats",v.Name)
					Admin.RunCommand(Settings.Prefix.."invisible",v.Name)

					v.Character.Head.Transparency = 0.9
					v.Character.Head.Mesh.Scale = Vector3.new(0.01,0.01,0.01)

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

		--[[Trail = {
			Prefix = Settings.Prefix;
			Commands = {"trail", "trails"};
			Args = {"player", "textureid"};
			Description = "Adds trails to the target's character's parts";
			AdminLevel = "Moderators";
			Fun = true;
			Function = function(plr, args)
				assert(args[1], "Player argument missing")
				local newTrail = service.New("Trail", {
					Color = (args[2] and (args[2]:lower() == "truecolors" or args[2]:lower() == "rainbow") and ColorSequence.new(Color3.new(1, 0, 0), Color3.fromRGB(255, 136, 0), Color3.fromRGB(255, 228, 17), Color3.fromRGB(135, 255, 7), Color3.fromRGB(11, 255, 207), Color3.fromRGB(10, 46, 255), Color3.fromRGB(255, 55, 255), Color3.fromRGB(170, 0, 127)));
					Texture = args[2] and "rbxassetid://"..args[2];
					TextureMode = "Stretch";
					TextureLength = 2;
					Name = "ADONIS_TRAIL";
				})

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					for k,p in next,char:GetChildren() do
						if p:IsA("BasePart") then
							Functions.RemoveParticle(p,"ADONIS_CMD_TRAIL")
							Functions.NewParticle(p,"Trail",{
								Color = (args[2] and (args[2]:lower() == "truecolors" or args[2]:lower() == "rainbow") and ColorSequence.new(Color3.new(1, 0, 0), Color3.fromRGB(255, 136, 0), Color3.fromRGB(255, 228, 17), Color3.fromRGB(135, 255, 7), Color3.fromRGB(11, 255, 207), Color3.fromRGB(10, 46, 255), Color3.fromRGB(255, 55, 255), Color3.fromRGB(170, 0, 127)));
								Texture = tonumber(args[2]) and "rbxassetid://"..args[2];
								TextureMode = "Stretch";
								TextureLength = 2;
								Name = "ADONIS_CMD_TRAIL";
							})
						end
					end
				end
			end;
		};--]]

		UnParticle = {
			Prefix = Settings.Prefix;
			Commands = {"unparticle";"removeparticles";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes particle emitters from target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.RemoveParticle(torso, "PARTICLE")
					end
				end
			end
		};

		Particle = {
			Prefix = Settings.Prefix;
			Commands = {"particle";};
			Args = {"player";"textureid";"startColor3";"endColor3";};
			Hidden = false;
			Description = "Put custom particle emitter on target";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				if not args[2] then error("Missing texture") end
				local startColor = {}
				local endColor = {}
				local startc = Color3.new(1,1,1)
				local endc = Color3.new(1,1,1)

				if args[3] then
					for s in args[3]:gmatch("[%d]+")do
						table.insert(startColor,tonumber(s))
					end
				end

				if args[4] then--276138620 :)
					for s in args[4]:gmatch("[%d]+")do
						table.insert(endColor,tonumber(s))
					end
				end

				if #startColor==3 then
					startc = Color3.new(startColor[1],startColor[2],startColor[3])
				end

				if #endColor==3 then
					endc = Color3.new(endColor[1],endColor[2],endColor[3])
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local torso = v.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						Functions.NewParticle(torso,"ParticleEmitter",{
							Name = "PARTICLE";
							Texture = 'rbxassetid://'.. Functions.GetTexture(args[1]);
							Size = NumberSequence.new({
								NumberSequenceKeypoint.new(0,0);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(1,.5);
							});
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0,1);
								NumberSequenceKeypoint.new(.1,.25,.25);
								NumberSequenceKeypoint.new(.9,.5,.25);
								NumberSequenceKeypoint.new(1,1);
							});
							Lifetime = NumberRange.new(5);
							Speed = NumberRange.new(.5,1);
							Rotation = NumberRange.new(0,359);
							RotSpeed = NumberRange.new(-90,90);
							Rate = 11;
							VelocitySpread = 180;
							Color = ColorSequence.new(startc,endc);
						})
					end
				end
			end
		};

		Flatten = {
			Prefix = Settings.Prefix;
			Commands = {"flatten";"2d";"flat";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Flatten.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
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

						for i,v in pairs(char:GetChildren()) do
							if v:IsA("BasePart") then
								v.Anchored = true
							end
						end

						local function size(part)
							for i,v in pairs(part:GetChildren()) do
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

									if p1.Name ~= 'Head' and p1.Name ~= 'Torso' then
										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)
									elseif p1.Name ~= 'Torso' then
										p1.Anchored = true
										for k,m in pairs(p1:children()) do
											if m:IsA('Weld') then
												m.Part0 = nil
												m.Part1.Anchored = true
											end
										end

										p1.formFactor = 3
										p1.Size = Vector3.new(p1.Size.X,p1.Size.Y,num)

										for k,m in pairs(p1:children()) do
											if m:IsA('Weld') then
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
										table.insert(welds,v)
										p1.Anchored = true
										v.Part0 = nil
									end
								elseif v:IsA('CharacterMesh') then
									local bp = tostring(v.BodyPart):match('%w+.%w+.(%w+)')
									local msh = service.New('SpecialMesh')
								elseif v:IsA('SpecialMesh') and v.Parent ~= char.Head then
									v.Scale = Vector3.new(v.Scale.X,v.Scale.Y,num)
								end
								size(v)
							end
						end

						size(char)

						torso.formFactor = 3
						torso.Size = Vector3.new(torso.Size.X,torso.Size.Y,num)

						for i,v in pairs(welds) do
							v.Part0 = torso
							v.Part1.Anchored = false
						end

						for i,v in pairs(char:GetChildren()) do
							if v:IsA('BasePart') then
								v.Anchored = false
							end
						end

						local weld = service.New('Weld',root)
						weld.Part0 = root
						weld.Part1 = torso

						local cape = char:findFirstChild("ADONIS_CAPE")
						if cape then
							cape.Size = cape.Size*num
						end
					end
				end

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					sizePlayer(v)
				end
			end
		};

		OldFlatten = {
			Prefix = Settings.Prefix;
			Commands = {"oldflatten";"o2d";"oflat";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Old Flatten. Went lazy on this one.";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						for k,p in pairs(v.Character:children()) do
							if p:IsA("Part") then
								if p:FindFirstChild("Mesh") then p.Mesh:Destroy() end
								service.New("BlockMesh",p).Scale=Vector3.new(1,1,args[2] or 0.1)
							elseif p:IsA("Accoutrement") and p:FindFirstChild("Handle") then
								if p.Handle:FindFirstChild("Mesh") then
									p.Handle.Mesh.Scale=Vector3.new(1,1,args[2] or 0.1)
								else
									service.New("BlockMesh",p.Handle).Scale=Vector3.new(1,1,args[2] or 0.1)
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
			Commands = {"sticky";};
			Args = {"player";};
			Hidden = false;
			Description = "Sticky";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local event
					local torso = v.Character.HumanoidRootPart
					event = v.Character.HumanoidRootPart.Touched:connect(function(p)
						if torso and torso.Parent and not p:IsDescendantOf(v.Character) and not p.Locked then
							Functions.MakeWeld(torso,p)
						elseif not torso or not torso.Parent then
							event:disconnect()
						end
					end)
				end
			end
		};

		Break = {
			Prefix = Settings.Prefix;
			Commands = {"break";};
			Args = {"player";"optional num";};
			Hidden = false;
			Description = "Break the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					cPcall(function()
						if v.Character then
							local head = v.Character.Head
							local torso = v.Character.HumanoidRootPart
							local larm = v.Character['Left Arm']
							local rarm = v.Character['Right Arm']
							local lleg = v.Character['Left Leg']
							local rleg = v.Character['Right Leg']
							for i,v in pairs(v.Character:children()) do if v:IsA("Part") then v.Anchored=true end end
							torso.FormFactor="Custom"
							torso.Size=Vector3.new(torso.Size.X,torso.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=v.Character.HumanoidRootPart
							weld.C0=v.Character.HumanoidRootPart.CFrame
							head.FormFactor="Custom"
							head.Size=Vector3.new(head.Size.X,head.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=head
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(0,1.5,0)
							larm.FormFactor="Custom"
							larm.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=larm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1,0,0)
							rarm.FormFactor="Custom"
							rarm.Size=Vector3.new(rarm.Size.X,rarm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rarm
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1,0,0)
							lleg.FormFactor="Custom"
							lleg.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=lleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(-1,-1.5,0)
							rleg.FormFactor="Custom"
							rleg.Size=Vector3.new(larm.Size.X,larm.Size.Y,tonumber(args[2]) or 0.1)
							local weld = service.New("Weld",v.Character.HumanoidRootPart)
							weld.Part0=v.Character.HumanoidRootPart
							weld.Part1=rleg
							weld.C0=v.Character.HumanoidRootPart.CFrame*CFrame.new(1,-1.5,0)
							wait()
							for i,v in pairs(v.Character:children()) do if v:IsA("Part") then v.Anchored=false end end
						end
					end)
				end
			end
		};

		Skeleton = {
			Prefix = Settings.Prefix;
			Commands = {"skeleton";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a skeleton";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local hat = service.Insert(36883367)
				local players = service.GetPlayers(plr,args[1])
				for i,v in pairs(players) do
					for k,m in pairs(v.Character:children()) do
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
					for _,v in pairs(players) do
						table.insert(t, v.Name)
					end
					Admin.RunCommand(Settings.Prefix.."package "..table.concat(t,",").." 295")
				end
			end
		};

		Creeper = {
			Prefix = Settings.Prefix;
			Commands = {"creeper";"creeperify";};
			Args = {"player";};
			Hidden = false;
			Description = "Turn the target player(s) into a creeper";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character and v.Character:findFirstChild("HumanoidRootPart") then
						local humanoid = v.Character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
							local joints = Functions.GetJoints(v.Character)

							if v.Character:findFirstChild("Shirt") then v.Character.Shirt.Parent = v.Character.HumanoidRootPart end
							if v.Character:findFirstChild("Pants") then v.Character.Pants.Parent = v.Character.HumanoidRootPart end

							if joints["Neck"] then
								joints["Neck"].C0 = isR15 and CFrame.new(0, 1, 0) or (CFrame.new(0,1,0) * CFrame.Angles(math.rad(90),math.rad(180),0))
							end

							local rarm = isR15 and joints["RightShoulder"] or joints["Right Shoulder"]
							if rarm then
								rarm.C0 = isR15 and CFrame.new(-1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(90),0))
							end

							local larm = isR15 and joints["LeftShoulder"] or joints["Left Shoulder"]
							if larm then
								larm.C0 = isR15 and CFrame.new(1, -1.5, -0.5) or (CFrame.new(0,-1.5,-.5) * CFrame.Angles(0,math.rad(-90),0))
							end

							local rleg = isR15 and joints["RightHip"] or joints["Right Hip"]
							if rleg then
								rleg.C0 = isR15 and (CFrame.new(-0.5,-0.5,0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(90),0))
							end

							local lleg = isR15 and joints["LeftHip"] or joints["Left Hip"]
							if lleg then
								lleg.C0 = isR15 and (CFrame.new(0.5,-0.5,0.5) * CFrame.Angles(0, math.rad(180), 0)) or (CFrame.new(0,-1,.5) * CFrame.Angles(0,math.rad(-90),0))
							end

							for a, part in pairs(v.Character:children()) do
								if part:IsA("BasePart") then
									part.BrickColor = BrickColor.new("Bright green")
									if part.Name == "FAKETORSO" then
										part:Destroy()
									end
								elseif part:findFirstChild("NameTag") then
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
			Commands = {"bighead";};
			Args = {"player", "num"};
			Hidden = false;
			Description = "Give the target player(s) a larger ego";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid");

						if human then
							if human.RigType == Enum.HumanoidRigType.R6 then
								v.Character.Head.Mesh.Scale = Vector3.new(1.75,1.75,1.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0,1.3,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
							else
								local scale = human and human:FindFirstChild("HeadScale");
								if scale then
									scale.Value = tonumber(args[2]) or 1.5;
								end
							end
						end
					end
				end
			end
		};

		SmallHead = {
			Prefix = Settings.Prefix;
			Commands = {"smallhead";"minihead";};
			Args = {"player", "num"};
			Hidden = false;
			Description = "Give the target player(s) a small head";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i, v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						local char = v.Character;
						local human = char and char:FindFirstChildOfClass("Humanoid");

						if human then
							if human.RigType == Enum.HumanoidRigType.R6 then
								v.Character.Head.Mesh.Scale = Vector3.new(.75,.75,.75)
								v.Character.Torso.Neck.C0 = CFrame.new(0,.8,0) * CFrame.Angles(math.rad(90),math.rad(180),0)
							else
								local scale = human and human:FindFirstChild("HeadScale");
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
			Commands = {"resize";"size";};
			Args = {"player";"mult";};
			Hidden = false;
			Description = "Resize the target player(s)'s character by <mult>";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local sizeLimit = Settings.SizeLimit or 20
				local num = math.clamp(tonumber(args[2]) or 1, 0.001, sizeLimit) -- Size limit exceeding over 20 would be unnecessary and may potientially create massive lag !!

				if not args[2] or not tonumber(args[2]) then
					num = 1
					Functions.Hint("Size changed to 1 [Argument #2 wasn't supplied correctly.]", {plr})
				elseif tonumber(args[2]) and tonumber(args[2]) > sizeLimit then
					Functions.Hint("Size changed to the maximum "..tostring(num).." [Argument #2 went over the size limit]", {plr})
				end

				for i,v in next,service.GetPlayers(plr,args[1]) do
					local char = v.Character;
					local human = char and char:FindFirstChildOfClass("Humanoid");

					if not human then
						Functions.Hint("Cannot resize "..v.Name.."'s character. Humanoid doesn't exist!",{plr})
						continue
					end

					if not Variables.SizedCharacters[char] then
						Variables.SizedCharacters[char] = num
					elseif Variables.SizedCharacters[char] and Variables.SizedCharacters[char]*num < sizeLimit then
						Variables.SizedCharacters[char] = Variables.SizedCharacters[char]*num
					else
						Functions.Hint("Cannot resize "..v.Name.."'s character by "..tostring(num*100).."%. Size limit exceeded.",{plr})
						continue
					end

					if human and human.RigType == Enum.HumanoidRigType.R15 then
						for k,val in next,human:GetChildren() do
							if val:IsA("NumberValue") and val.Name:match(".*Scale") then
								val.Value = val.Value * num;
							end
						end
					elseif human and human.RigType == Enum.HumanoidRigType.R6 then
						local Motors = {}
						local Percent = num

						table.insert(Motors, char.HumanoidRootPart.RootJoint)
						for i,Motor in pairs(char.Torso:GetChildren()) do
							if Motor:IsA("Motor6D") == false then continue end
							table.insert(Motors, Motor)
						end
						for i,v in pairs(Motors) do
							v.C0 = CFrame.new((v.C0.Position * Percent)) * (v.C0 - v.C0.Position)
							v.C1 = CFrame.new((v.C1.Position * Percent)) * (v.C1 - v.C1.Position)
						end


						for i,Part in pairs(char:GetChildren()) do
							if Part:IsA("BasePart") == false then continue end
							Part.Size = Part.Size * Percent
						end


						for i,Accessory in pairs(char:GetChildren()) do
							if Accessory:IsA("Accessory") == false then continue end

							Accessory.Handle.AccessoryWeld.C0 = CFrame.new((Accessory.Handle.AccessoryWeld.C0.Position * Percent)) * (Accessory.Handle.AccessoryWeld.C0 - Accessory.Handle.AccessoryWeld.C0.Position)
							Accessory.Handle.AccessoryWeld.C1 = CFrame.new((Accessory.Handle.AccessoryWeld.C1.Position * Percent)) * (Accessory.Handle.AccessoryWeld.C1 - Accessory.Handle.AccessoryWeld.C1.Position)

							if Accessory.Handle:FindFirstChildOfClass("SpecialMesh") then
								Accessory.Handle:FindFirstChildOfClass("SpecialMesh").Scale *= Percent
							end
						end
					end
				end
			end
		};

		Seizure = {
			Prefix = Settings.Prefix;
			Commands = {"seizure";};
			Args = {"player";};
			Hidden = false;
			Description = "Make the target player(s)'s character spazz out on the floor";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local scr = Deps.Assets.Seize
				scr.Name = "Seize"
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character:FindFirstChild('HumanoidRootPart') then
						v.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(90),0,0)
						local new = scr:Clone()
						new.Parent = v.Character.HumanoidRootPart
						new.Disabled = false
					end
				end
			end
		};

		UnSeizure = {
			Prefix = Settings.Prefix;
			Commands = {"unseizure";};
			Args = {"player";};
			Hidden = false;
			Description = "Removes the effects of the seizure command";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
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
			Commands = {"removelimbs";"delimb";};
			Args = {"player";};
			Hidden = false;
			Description = "Remove the target player(s)'s arms and legs";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						for a, obj in pairs(v.Character:children()) do
							if obj:IsA("BasePart") and (obj.Name:find("Leg") or obj.Name:find("Arm")) then
								obj:Destroy()
							end
						end
					end
				end
			end
		};

		RightLeg = {
			Prefix = Settings.Prefix;
			Commands = {"rleg";"rightleg";"rightlegpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Right Leg package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=31 then
					error('ID is not a right leg!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		LeftLeg = {
			Prefix = Settings.Prefix;
			Commands = {"lleg";"leftleg";"leftlegpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Leg package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=30 then
					error('ID is not a left leg!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		RightArm = {
			Prefix = Settings.Prefix;
			Commands = {"rarm";"rightarm";"rightarmpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Right Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id=service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=28 then
					error('ID is not a right arm!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		LeftArm = {
			Prefix = Settings.Prefix;
			Commands = {"larm";"leftarm";"leftarmpackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=29 then
					error('ID is not a left arm!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		Torso = {
			Prefix = Settings.Prefix;
			Commands = {"torso";"torsopackage";};
			Args = {"player";"id";};
			Hidden = false;
			Description = "Change the target player(s)'s Left Arm package";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local id = service.MarketPlace:GetProductInfo(args[2]).AssetTypeId

				if id~=27 then
					error('ID is not a torso!')
				end

				local model = service.Insert(args[2], true)

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						Functions.ApplyBodyPart(v.Character, model)
					end
				end

				model:Destroy()
			end
		};

		LoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"loopfling";};
			Args = {"player";};
			Hidden = false;
			Description = "Loop flings the target player(s)";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StartLoop(v.userId.."LOOPFLING",2,function()
						Admin.RunCommand(Settings.Prefix.."fling",v.Name)
					end)
				end
			end
		};

		UnLoopFling = {
			Prefix = Settings.Prefix;
			Commands = {"unloopfling";};
			Args = {"player";};
			Hidden = false;
			Description = "UnLoop Fling";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					service.StopLoop(v.userId.."LOOPFLING")
				end
			end
		};

		Deadlands = {
			Prefix = Settings.Prefix;
			Commands = {"deadlands","farlands","renderingcyanide"};
			Args = {"player","mult"};
			Description = "The edge of Roblox math; WARNING CAPES CAN CAUSE LAG";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				local dist = 1000000 * (tonumber(args[2]) or 1.5)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						if torso then
							Functions.UnCape(v)
							torso.CFrame = CFrame.new(dist, dist+10, dist)
							Admin.RunCommand(Settings.Prefix.."noclip",v.Name)
						end
					end
				end
			end
		};

		UnDeadlands = {
			Prefix = Settings.Prefix;
			Commands = {"undeadlands","unfarlands","unrenderingcyanide"};
			Args = {"player"};
			Description = "Clips the player and teleports them to you";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,v in next,service.GetPlayers(plr,args[1]) do
					if v.Character then
						local torso = v.Character:FindFirstChild("HumanoidRootPart")
						local pTorso = plr.Character:FindFirstChild("HumanoidRootPart")
						if torso and pTorso and plr ~= v then
							Admin.RunCommand(Settings.Prefix.."clip",v.Name)
							wait(0.3)
							torso.CFrame = pTorso.CFrame*CFrame.new(0,0,5)
						else
							plr:LoadCharacter()
						end
					end
				end
			end
		};

		RopeConstraint = {
			Prefix = Settings.Prefix;
			Commands = {"rope","chain"};
			Args = {"player1","player2","length"};
			Description = "Connects players using a rope constraint";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")
				for i,player1 in pairs(service.GetPlayers(plr,args[1])) do
					for i2,player2 in pairs(service.GetPlayers(plr,args[2])) do
						local torso1 = player1.Character:FindFirstChild("HumanoidRootPart")
						local torso2 = player2.Character:FindFirstChild("HumanoidRootPart")
						if torso1 and torso2 then
							local att1 = service.New("Attachment",torso1)
							local att2 = service.New("Attachment",torso2)
							local rope = service.New("RopeConstraint",torso1)

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
			Commands = {"unrope","unchain"};
			Args = {"player"};
			Description = "UnRope";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				for i,p in pairs(service.GetPlayers(plr,args[1])) do
					local torso = p.Character:FindFirstChild("HumanoidRootPart")
					if torso then
						for i,v in pairs(torso:GetChildren()) do
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
			Commands = {"headlian","beautiful"};
			Args = {"player"};
			Description = "hot";
			Fun = true;
			AdminLevel = "Moderators";
			Function = function(plr,args)
				--{Left,Right}--
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
					{27493648,27493629}; -- Alien
					{86500054,86500036}; -- Man
					{86499716,86499698}; -- Woman
					{36781447,36781407}; -- Skeleton
					{32336182,32336117}; -- Superhero
					{137715036,137715073}; -- Polar bear
					{53980922,53980889}; -- Gentleman robot
					{132896993,132897065}; -- Witch
				}
				local legs = {
					{86499753,86499793}; -- Woman
					{132897097,132897160}; -- Witch
					{54116394,54116432}; -- Mr Robot
					{232519786,232519950}; -- Sir Kitty McPawnington
					{32357631,32357663}; -- Slinger
					{293226935,293227110}; -- Lillian
					{32336243,32336306}; -- Superhero
					{27493683,27493718}; -- Alien
					{28279894,28279938}; -- Cool kid
					{136801087,136801165}; -- Bludroid: Ev1LR0b0t
					{53980959,53980996}; -- Gentleman robot
					{139607673,139607718}; -- Korblox
					{143624963,143625109}; -- Team ROBLOX Parka
					{77517631,77517683}; -- Empyrean Armor
					{128157317,128157361}; -- Telamon's Business Casual
					{86500078,86500064}; -- Man
					{27112056,27112068}; -- Roblox 2.0
				}

				local function clear(char)
					for i,v in pairs(char:GetChildren()) do
						if v:IsA("CharacterMesh") or v:IsA("Accoutrement") or v:IsA("ShirtGraphic") or v:IsA("Pants") or v:IsA("Shirt") then
							v:Destroy()
						end
					end
				end

				local function apply(char)
					local color = BrickColor.new(Color3.new(math.random(),math.random(),math.random()))
					local face = faces[math.random(1,#faces)]
					local arms = arms[math.random(1,#arms)]
					local legs = legs[math.random(1,#legs)]
					local la,ra = arms[1],arms[2]
					local ll,rl = legs[1],legs[2]
					local head = char:FindFirstChild("Head")
					local bodyColors = char:FindFirstChild("Body Colors")
					if head then
						local old = head:FindFirstChild("Mesh")
						if old then old:Destroy() end
						local mesh = service.New("SpecialMesh",head)
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

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					if v.Character then
						clear(v.Character)
						apply(v.Character)
					end
				end
			end
		};
	}
end
