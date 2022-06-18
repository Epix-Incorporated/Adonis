return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		Chik3n = {
			Prefix = Settings.Prefix;
			Commands = {"chik3n", "zelith", "z3lith"};
			Args = {};
			Hidden = false;
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
					for i, v in pairs(hats) do
						wait(0.5)
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
				for i, v in pairs(tempHats) do
					pcall(function() v:Destroy() end)
					table.remove(tempHats, i)
				end
				for i, v in pairs(hats) do
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
				for _, v in ipairs(service.GetPlayers(plr, args[1])) do
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
							local pos=Instance.new("BodyPosition", part)
							pos.maxForce = Vector3.new(math.huge, math.huge, math.huge)--10000, 10000, 10000)
							pos.position = part.Position
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
								for i, v in pairs(obj:GetChildren()) do
									Pcall(get, v)
								end
								obj.ChildAdded:Connect(function(p)Pcall(get, p)end)
							end
						end

						get(workspace)

						repeat
							for i, v in pairs(parts) do
								if (((main.Position - v.Position).Magnitude * 250 * 20) < (5000 * 40)) and v and v:IsDescendantOf(workspace) then
									coroutine.wrap(fling, v)
								elseif not v or not v:IsDescendantOf(workspace) then
									table.remove(parts, i)
								end
							end
							main.CFrame = main.CFrame + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
							wait()
					until main.Parent ~= workspace or not main]])
					cl.Parent = p
					cl.Disabled = false
					if args[2] and tonumber(args[2]) then
						for i = 1, tonumber(args[2]) do
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
			Commands = {"nuke"};
			Args = {"player"};
			Description = "Nuke the target player(s)";
			AdminLevel = "HeadAdmins";
			Fun = true;
			Function = function(plr: Player, args: {string})
				local nukes = {}
				local partsHit = {}

				for i, v in ipairs(Functions.GetPlayers(plr, args[1])) do
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
					for i, v in pairs(nukes) do
						local curPos = v.CFrame
						v.Size = v.Size + Vector3.new(3, 3, 3)
						v.CFrame = curPos
					end
					wait(1/44)
				end

				for i, v in pairs(nukes) do
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
						for i, v in pairs(objs) do
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
							wait(math.random(5))
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

				for i, v in pairs(Functions.GetPlayers(plr, args[1])) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						fire(human)
					end
				end

				partsHit = nil
			end
		};
    }
end
