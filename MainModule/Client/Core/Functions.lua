client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function()
	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, elapsedTime, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = service
	local client = client
	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables;
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		Functions.Init = nil;
	end

	local function RunLast()
		--[[client = service.ReadOnly(client, {
				[client.Variables] = true;
				[client.Handlers] = true;
				G_API = true;
				G_Access = true;
				G_Access_Key = true;
				G_Access_Perms = true;
				Allowed_API_Calls = true;
				HelpButtonImage = true;
				Finish_Loading = true;
				RemoteEvent = true;
				ScriptCache = true;
				Returns = true;
				PendingReturns = true;
				EncodeCache = true;
				DecodeCache = true;
				Received = true;
				Sent = true;
				Service = true;
				Holder = true;
				GUIs = true;
				LastUpdate = true;
				RateLimits = true;

				Init = true;
				RunLast = true;
				RunAfterInit = true;
				RunAfterLoaded = true;
				RunAfterPlugins = true;
			}, true)--]]

			Functions.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Functions = {
		Init = Init;
		RunLast = RunLast;
		Kill = client.Kill;

		ESPFaces = {"Front", "Back", "Top", "Bottom", "Left", "Right"};
		ESPify = function(obj, color)
			for i, part in ipairs(obj:GetChildren()) do
				if part:IsA("BasePart") then
					if part.Name == "Head" and not part:FindFirstChild("__ADONIS_NAMETAG") then
						local player = service.Players:GetPlayerFromCharacter(part.Parent)

						if player then
							local bb = Instance.new("BillboardGui")
							bb.Name = "__ADONIS_NAMETAG"
							bb.Adornee = part
							bb.AlwaysOnTop = true
							bb.StudsOffset = Vector3.new(0,2,0)
							bb.Size = UDim2.new(0,100,0,40)
							local taglabel = Instance.new("TextLabel")
							local pos = service.Player:DistanceFromCharacter(part.Position)
							taglabel.BackgroundTransparency = 1
							taglabel.TextColor3 = Color3.new(1,1,1)
							taglabel.TextStrokeTransparency = 0
							taglabel.Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, pos and math.floor(pos) or 'N/A')
							taglabel.Size = UDim2.new(1, 0, 1, 0)
							taglabel.TextScaled = true
							taglabel.TextWrapped = true
							taglabel.Parent = bb
							bb.Parent = part
							
							if player ~= service.Player then
								coroutine.wrap(function()
									repeat
										if not part then
											break
										end

										local DIST = service.Player:DistanceFromCharacter(part.CFrame.Position)
										taglabel.Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, DIST and math.floor(DIST) or 'N/A')

										service.RunService.Heartbeat:Wait()
									until not part or not bb or not taglabel
								end)()
							end
						end
					end

					for i,surface in ipairs(Functions.ESPFaces) do
						local gui = Instance.new("SurfaceGui")
						gui.Name = "__ADONISESP"
						gui.AlwaysOnTop = true
						gui.ResetOnSpawn = false
						gui.Adornee = part
						gui.Face = surface

						do
							local temp = Instance.new("Frame")
							temp.Size = UDim2.new(1, 0, 1, 0)
							temp.BackgroundColor3 = color or Color3.fromRGB(255, 0, 234)
							temp.Parent = gui
						end

						gui.Parent = part;
						gui.AncestryChanged:Connect(function()
							if not game.IsDescendantOf(gui,workspace) then
								service.Debris:AddItem(gui,0)
								
								for i,v in pairs(Variables.ESPObjects) do
									if v == gui then
										table.remove(Variables.ESPObjects, i)
										break;
									end
								end
							end
						end)

						Variables.ESPObjects[gui] = part;
					end
				end
			end
		end;

		CharacterESP = function(mode, target, color)
			if Variables.ESPEvent then
				Variables.ESPEvent:Disconnect();
				Variables.ESPEvent = nil;
			end

			for obj in pairs(Variables.ESPObjects) do
				if not mode or not target or (target and obj:IsDescendantOf(target)) then
					local __ADONIS_NAMETAG = obj.Parent:FindFirstChild("__ADONIS_NAMETAG")
					if __ADONIS_NAMETAG then
						__ADONIS_NAMETAG:Destroy()
					end

					service.Debris:AddItem(obj,0)
					Variables.ESPObjects[obj] = nil;
				end
			end

			if mode == true then
				if not target then
					Variables.ESPEvent = workspace.ChildAdded:Connect(function(obj)
						service.RunService.Heartbeat:Wait()
						local human = obj:IsA("Model") and service.Players:GetPlayerFromCharacter(obj)

						if human then
							coroutine.wrap(Functions.ESPify)(obj, color);
						end
					end)
					
					for i,obj in ipairs(workspace:GetChildren()) do
						local human = obj:IsA("Model") and service.Players:GetPlayerFromCharacter(obj)
						if human then
							coroutine.wrap(Functions.ESPify)(obj, color);
						end
					end
				else
					Functions.ESPify(target, color);
				end
			end
		end;

		GetRandom = function(pLen)
			local Len = (type(pLen) == "number" and pLen) or math.random(10,15) --// reru
			local Res = {};
			for Idx = 1, Len do
				Res[Idx] = string.format('%02x', math.random(255));
			end;
			return table.concat(Res)
		end;

		Round = function(num)
			return math.floor(num + 0.5)
		end;

		SetView = function(ob)
			if ob=='reset' then
				workspace.CurrentCamera.CameraType = 'Custom'
				workspace.CurrentCamera.CameraSubject = service.Player.Character.Humanoid
				workspace.CurrentCamera.FieldOfView = 70
			else
				workspace.CurrentCamera.CameraSubject = ob
			end
		end;

		AddAlias = function(alias, command)
			Variables.Aliases[alias:lower()] = command;
			Remote.Get("UpdateAliases", Variables.Aliases)
			spawn(function()
				UI.MakeGui("Notification",{
					Time = 5;
					Title = "Notification";
					Message = "Alias added";
				})
			end)
		end;

		RemoveAlias = function(alias)
			if client.Variables.Aliases[alias:lower()] then
				Variables.Aliases[alias:lower()] = nil;
				Remote.Get("UpdateAliases", Variables.Aliases)
				spawn(function()
					UI.MakeGui("Notification",{
						Time = 5;
						Title = "Notification";
						Message = "Alias removed";
					})
				end)
			else
				spawn(function()
					UI.MakeGui("Notification",{
						Time = 5;
						Title = "Notification";
						Message = "Alias not found";
					})
				end)
			end
		end;

		Playlist = function()
			return client.Remote.Get("Playlist")
		end;

		UpdatePlaylist = function(playlist)
			client.Remote.Get("UpdatePlaylist", playlist)
		end;

		Dizzy = function(speed)
			service.StopLoop("DizzyLoop")
			if speed then
				local cam = workspace.CurrentCamera
				local last = tick()
				local rot = 0
				local flip = false
				service.StartLoop("DizzyLoop","RenderStepped",function()
					local dt = tick() - last
					if flip then
						rot = rot+math.rad(speed*dt)
					else
						rot = rot-math.rad(speed*dt)
					end

					if rot >= 2.5 or rot <= -2.5 then
						--flip = not flip
					end
					cam.CoordinateFrame = cam.CoordinateFrame * CFrame.Angles(0, 0.00, rot)
					last = tick()
				end)
			end
		end;

		Base64Encode = function(data)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			return ((data:gsub('.', function(x)
				local r,b='',string.byte(x)
				for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
				return r;
			end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
				if (#x < 6) then return '' end
				local c=0
				for i=1,6 do c=c+(string.sub(x,i,i)=='1' and 2^(6-i) or 0) end
				return string.sub(b,c+1,c+1)
			end)..({ '', '==', '=' })[#data%3+1])
		end;

		Base64Decode = function(data)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			data = string.gsub(data, '[^'..b..'=]', '')
			return (data:gsub('.', function(x)
				if (x == '=') then return '' end
				local r,f='',(string.find(b,x)-1)
				for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
				return r;
			end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if (#x ~= 8) then return '' end
				local c=0
				for i=1,8 do c=c+(string.sub(x,i,i)=='1' and 2^(7-i) or 0) end
				return string.char(c)
			end))
		end;

		GetGuiData = function(args)
			local props = {
				"AbsolutePosition";
				"AbsoluteSize";
				"ClassName";
				"Name";
				"Parent";
				"Archivable";
				"SelectionImageObject";
				"Active";
				"BackgroundColor3";
				"BackgroundTransparency";
				"BorderColor3";
				"BorderSizePixel";
				"Position";
				"Rotation";
				"Selectable";
				"Size";
				"SizeConstraint";
				"Style";
				"Visible";
				"ZIndex";
				"ClipsDescendants";
				"Draggable";
				"NextSelectionDown";
				"NextSelectionLeft";
				"NextSelectionRight";
				"NextSelectionUp";
				"AutoButtonColor";
				"Modal";
				"Image";
				"ImageColor3";
				"ImageRectOffset";
				"ImageRectSize";
				"ImageTransparency";
				"ScaleType";
				"SliceCenter";
				"Text";
				"TextColor3";
				"Font";
				"TextScaled";
				"TextStrokeColor3";
				"TextStrokeTransparency";
				"TextTransparency";
				"TextWrapped";
				"TextXAlignment";
				"TextYAlignment";
			};

			local classes = {
				"ScreenGui";
				"GuiMain";
				"Frame";
				"TextButton";
				"TextLabel";
				"ImageButton";
				"ImageLabel";
				"ScrollingFrame";
				"TextBox";
				"BillboardGui";
				"SurfaceGui";
			}

			local guis = {
				Properties = {
					Name = "ViewGuis";
					ClassName = "Folder";
				};
				Children = {};
			}

			local rLockedFound = false

			local add; add = function(tab,child)
				if not Anti.ObjRLocked(child) then
					local good = false

					for i,v in next,classes do
						if child:IsA(v) then
							good = true
						end
					end

					if good then
						local new = {
							Properties = {};
							Children = {};
						}

						for i,v in next,props do
							pcall(function()
								new.Properties[v] = child[v]
							end)
						end

						for i,v in next,child:GetChildren()do
							add(new,v)
						end
						table.insert(tab.Children, new)
					end
				else
					rLockedFound = true
				end
			end
			for i,v in next,service.PlayerGui:GetChildren()do
				pcall(add,guis,v)
			end
			return guis
		end;

		LoadGuiData = function(data)
			local make; make = function(dat)
				local props = dat.Properties
				local children = dat.Children
				local gui = service.New(props.ClassName)

				for i,v in next,props do
					pcall(function()
						gui[i] = v
					end)
				end

				for i,v in next,children do
					pcall(function()
						local g = make(v)
						if g then
							g.Parent = gui
						end
					end)
				end
				return gui
			end

			local temp = Instance.new("Folder")
			for i,v in next,service.PlayerGui:GetChildren()do
				if not UI.Get(v) then
					v.Parent = temp
				end
			end
			Variables.GuiViewFolder = temp
			local folder = service.New("Folder",{Parent = service.PlayerGui; Name = "LoadedGuis"})
			for i,v in next,data.Children do
				pcall(function()
					local g = make(v)
					if g then
						g.Parent = folder
					end
				end)
			end
		end;

		UnLoadGuiData = function()
			for i,v in next,service.PlayerGui:GetChildren()do
				if v.Name == "LoadedGuis" then
					v:Destroy()
				end
			end

			if Variables.GuiViewFolder then
				for i,v in next,Variables.GuiViewFolder:GetChildren()do
					v.Parent = service.PlayerGui
				end
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end
		end;

		GetParticleContainer = function(target)
			if target then
				for i,v in next,service.LocalContainer():GetChildren()do
					if v.Name == target:GetFullName().."PARTICLES" then
						local obj = v:FindFirstChild("_OBJECT")
						if obj.Value == target then
							return v
						end
					end
				end
			end
		end;

		NewParticle = function(target, class, properties)
			local effect, index;

			properties.Parent = target;
			properties.Enabled = Variables.ParticlesEnabled;

			effect = service.New(class, properties);
			index = Functions.GetRandom();

			Variables.Particles[index] = effect;

			table.insert(Variables.Particles, effect);

			effect.Changed:Connect(function()
				if not effect or not effect.Parent or effect.Parent ~= target then
					pcall(function() effect:Destroy() end)
					Variables.Particles[index] = nil;
				end
			end)
		end;

		RemoveParticle = function(target, name)
			for i,effect in next,Variables.Particles do
				if effect.Parent == target and effect.Name == name then
					effect:Destroy();
					Variables.Particles[i] = nil;
				end
			end
		end;

		EnableParticles = function(enabled)
			for i,effect in next,Variables.Particles do
				if enabled then
					effect.Enabled = true
				else
					effect.Enabled = false
				end
			end
		end;

		NewLocal = function(class, props, parent)
			local obj = service.New(class)
			for prop,value in next,props do
				obj[prop] = value
			end

			if not parent or parent == "LocalContainer" then
				obj.Parent = service.LocalContainer()
			elseif parent == "Camera" then
				obj.Parent = service.Workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				obj.Parent = service.PlayerGui
			end
		end;

		MakeLocal = function(object,parent,clone)
			if object then
				local object = object
				if clone then object = object:Clone() end
				if not parent or parent == "LocalContainer" then
					object.Parent = service.LocalContainer()
				elseif parent == "Camera" then
					object.Parent = service.Workspace.CurrentCamera
				elseif parent == "PlayerGui" then
					object.Parent = service.PlayerGui
				end
			end
		end;

		MoveLocal = function(object,parent,newParent)
			local par
			if not parent or parent == "LocalContainer" then
				par = service.LocalContainer()
			elseif parent == "Camera" then
				par = service.Workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end
			for ind,obj in next,par:GetChildren()do
				if obj.Name == object or obj == obj then
					obj.Parent = newParent
				end
			end
		end;

		RemoveLocal = function(object,parent,match)
			local par
			if not parent or parent == "LocalContainer" then
				par = service.LocalContainer()
			elseif parent == "Camera" then
				par = service.Workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end

			for ind,obj in next,par:GetChildren() do
				if (match and string.match(obj.Name,object)) or (obj.Name == object or object == obj) then
					obj:Destroy()
				end
			end
		end;

		NewCape = function(data)
			local char = data.Parent
			local material = data.Material or "Neon"
			local color = data.Color or "White"
			local reflect = data.Reflectance or 0
			local decal = tonumber(data.Decal or "")
			if char then
				Functions.RemoveCape(char)
				local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
				local isR15 = (torso.Name == "UpperTorso")
				if torso then
					local p = service.New("Part")
					p.Name = "ADONIS_CAPE"
					p.Anchored = false
					p.Position = torso.Position
					p.Transparency = 0
					p.Material = material
					p.CanCollide = false
					p.TopSurface = 0
					p.BottomSurface = 0
					p.Size = Vector3.new(2,4,0.1)
					p.BrickColor = BrickColor.new(color) or BrickColor.new("White")
					p.Parent = service.LocalContainer()

					if reflect then
						p.Reflectance = reflect
					end

					local motor1 = service.New("Motor", p)
					motor1.Part0 = p
					motor1.Part1 = torso
					motor1.MaxVelocity = .01
					motor1.C0 = CFrame.new(0,1.75,0)*CFrame.Angles(0,math.rad(90),0)
					motor1.C1 = CFrame.new(0,1-((isR15 and 0.2) or 0),(torso.Size.Z/2))*CFrame.Angles(0,math.rad(90),0)

					local msh = service.New("BlockMesh", p)
					msh.Scale = Vector3.new(0.9,0.87,0.1)

					local dec
					if decal and decal ~= 0 then
						dec = service.New("Decal", p)
						dec.Name = "Decal"
						dec.Face = 2
						dec.Texture = "http://www.roblox.com/asset/?id="..decal
						dec.Transparency = 0
					end

					local index = Functions.GetRandom()
					Variables.Capes[index] = {
						Part = p;
						Motor = motor1;
						Enabled = true;
						Parent = data.Parent;
						Torso = torso;
						Decal = dec;
						Data = data;
						Wave = true;
						isR15 = isR15;
					}

					local p = service.Players:GetPlayerFromCharacter(data.Parent)
					if p and p == service.Player then
						Variables.Capes[index].isPlayer = true
					end

					if not Variables.CapesEnabled then
						p.Transparency = 1
						if dec then
							dec.Transparency = 1
						end
						Variables.Capes[index].Enabled = false
					end

					Functions.MoveCapes()
				end
			end
		end;
		RemoveCape = function(parent)
			for i,v in next,Variables.Capes do
				if v.Parent == parent or not v.Parent or not v.Parent.Parent then
					pcall(v.Part.Destroy,v.Part)
					Variables.Capes[i] = nil
				end
			end
		end;
		HideCapes = function(hide)
			for i,v in next,Variables.Capes do
				local torso = v.Torso
				local parent = v.Parent
				local part = v.Part
				local motor = v.Motor
				local wave = v.Wave
				local decal = v.Decal

				if parent and parent.Parent and torso and torso.Parent and part and part.Parent then
					if not hide then
						part.Transparency = 0

						if decal then
							decal.Transparency = 0
						end

						v.Enabled = true
					else
						part.Transparency = 1
						if decal then
							decal.Transparency = 1
						end
						v.Enabled = false
					end
				else
					pcall(part.Destroy,part)
					Variables.Capes[i] = nil
				end
			end
		end;

		MoveCapes = function()
			service.StopLoop("CapeMover")
			service.StartLoop("CapeMover",0.1,function()
				if Functions.CountTable(Variables.Capes) == 0 or not Variables.CapesEnabled then
					service.StopLoop("CapeMover")
				else
					for i,v in next,Variables.Capes do
						local torso = v.Torso
						local parent = v.Parent
						local isPlayer = v.isPlayer
						local isR15 = v.isR15
						local part = v.Part
						local motor = v.Motor
						local wave = v.Wave
						local decal = v.Decal

						if parent and parent.Parent and torso and torso.Parent and part and part.Parent then
							if v.Enabled and Variables.CapesEnabled then
								part.Transparency = 0

								if decal then
									decal.Transparency = 0
								end

								local ang = 0.1
								if wave then
									if torso.Velocity.Magnitude > 1 then
										ang = ang + ((torso.Velocity.Magnitude/10)*.05)+.05
									end
									v.Wave = false
								else
									v.Wave = true
								end
								ang = ang + math.min(torso.Velocity.Magnitude/11, .8)
								motor.MaxVelocity = math.min((torso.Velocity.Magnitude/111), .04) + 0.002
								if isPlayer then
									motor.DesiredAngle = -ang
								else
									motor.CurrentAngle = -ang -- bugs
								end
								if motor.CurrentAngle < -.2 and motor.DesiredAngle > -.2 then
									motor.MaxVelocity = .04
								end
							else
								part.Transparency = 1
								if decal then
									decal.Transparency = 1
								end
							end
						else
							pcall(part.Destroy,part)
							Variables.Capes[i] = nil
						end
					end
				end
			end, true)
		end;

		CountTable = function(tab)
			local count = 0
			for i,v in next,tab do
				count = count+1
			end
			return count
		end;

		ClearAllInstances = function()
			local objects = service.GetAdonisObjects()
			for i in next,objects do
				i:Destroy()
				objects[i] = nil
			end
		end;

		PlayAnimation = function(animId)
			if animId == 0 then return end

			local char = service.Player.Character
			local human = char:FindFirstChildOfClass("Humanoid")
			local animator = human:FindFirstChildOfClass("Animator") or human:WaitForChild("Animator")

			for i,v in pairs(animator:GetPlayingAnimationTracks()) do
				v:Stop()
			end
			local anim = service.New('Animation')
			anim.AnimationId = 'rbxassetid://'..animId
			anim.Name = "ADONIS_Animation"
			local track = animator:LoadAnimation(anim)
			track:Play()
		end;

		SetLighting = function(prop,value)
			if service.Lighting[prop]~=nil then
				service.Lighting[prop] = value
				Variables.LightingSettings[prop] = value
			end
		end;


		ChatMessage = function(msg,color,font,size)
			local tab = {}

			tab.Text = msg

			if color then
				tab.Color = color
			end

			if font then
				tab.Font = font
			end

			if size then
				tab.Size = size
			end

			service.StarterGui:SetCore("ChatMakeSystemMessage",tab)

			if Functions.SendToChat then
				Functions.SendToChat({Name = "::Adonis::"},msg,"Private")
			end
		end;

		SetCamProperty = function(prop,value)
			local cam = workspace.CurrentCamera
			if cam[prop] then
				cam[prop] = value
			end
		end;

		SetFPS = function(fps)
			service.StopLoop("SetFPS")
			local fps = tonumber(fps)
			if fps then
				service.StartLoop("SetFPS",0.1,function()
					local ender = tick()+1/fps
					repeat until tick()>=ender
				end)
			end
		end;

		RestoreFPS = function()
			service.StopLoop("SetFPS")
		end;

		Crash = function()
			--[[
			local load = function(f) return f() end
			local s = string.rep("\n", 2^24)
			print(load(function() return s end))--]]
			--print(string.find(string.rep("a", 2^20), string.rep(".?", 2^20)))
			--[[while true do
				spawn(function()
					spawn(function()
						spawn(function()
							spawn(function()
								spawn(function()
									spawn(function()
										spawn(function()
											spawn(function()
												spawn(function()
													spawn(function()
														spawn(function()
															print("Triangles.")
														end)
													end)
												end)
											end)
										end)
									end)
								end)
							end)
						end)
					end)
				end)
			end--]]

			local Run = service.RunService;
			local Lol = 0;

			local Thread; function Thread()
				Run:BindToRenderStep(tostring(Lol), 100, function() print"Stopping"; Thread(); end);
				Lol = Lol + 1;
			end;

			Thread();
			--local crash; crash = function() while true do repeat spawn(function() pcall(function() print(game[("%s|"):rep(100000)]) crash() end) end) until nil end end
			--crash()
		end;

		HardCrash = function()
			local crash
			local tab
			local gui = service.New("ScreenGui",service.PlayerGui)
			local rem = service.New("RemoteEvent",workspace.CurrentCamera)
			crash = function()
				for i=1,50 do
					service.Debris:AddItem(service.New("Part",workspace.CurrentCamera),2^4000)
					print("((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)((((**&&#@#$$$$$%%%%:)")
					local f = service.New('Frame',gui)
					f.Size = UDim2.new(1,0,1,0)
					spawn(function() table.insert(tab,string.rep(tostring(math.random()),100)) end)
					rem:FireServer("Hiiiiiiiiiiiiiiii")
					spawn(function()
						spawn(function()
							spawn(function()
								spawn(function()
									spawn(function()
										print("hi")
										spawn(crash)
									end)
								end)
							end)
						end)
					end)
					--print(game[("%s|"):rep(0xFFFFFFF)])
				end
				tab = {}
			end
			while wait(0.01) do
				for i = 1,50000000 do
					cPcall(function() client.GPUCrash() end)
					cPcall(function() crash() end)
					print(1)
				end
			end
		end;

		GPUCrash = function()
			local crash
			local gui = service.New("ScreenGui",service.PlayerGui)
			crash = function()
				while wait(0.01) do
					for i = 1,500000 do
						local f = service.New('Frame',gui)
						f.Size = UDim2.new(1,0,1,0)
					end
				end
			end
			crash()
		end;

		RAMCrash = function()
			while wait(0.1) do
				for i = 1,10000 do
					service.Debris:AddItem(service.New("Part",workspace.CurrentCamera),2^4000)
				end
			end
		end;

		KillClient = function()
			client.Kill("KillClient called")
		end;

		KeyCodeToName = function(keyVal)
			local keyVal = tonumber(keyVal);
			if keyVal then
				for i,e in next,Enum.KeyCode:GetEnumItems() do
					if e.Value == tonumber(keyVal) then
						return e.Name;
					end
				end
			end
			return "UNKNOWN";
		end;

		KeyBindListener = function()
			if not Variables then wait() end;
			local timer = 0

			Variables.KeyBinds = Remote.Get("PlayerData").Keybinds or {}

			service.UserInputService.InputBegan:Connect(function(input)
				local key = tostring(input.KeyCode.Value)
				local textbox = service.UserInputService:GetFocusedTextBox()

				if Variables.KeybindsEnabled and not (textbox) and key and Variables.KeyBinds[key] and not Variables.WaitingForBind then
					local isAdmin = Remote.Get("CheckAdmin")
					if (tick() - timer > 5 or isAdmin) then
						Remote.Send('ProcessCommand',Variables.KeyBinds[key],false,true)
						UI.Make("Hint",{
							Message = "[Ran] Key: "..Functions.KeyCodeToName(key).." | Command: "..tostring(Variables.KeyBinds[key])
						})
					end
					timer = tick()
				end
			end)
		end;

		AddKeyBind = function(key, command)
			local key = tostring(key);
			Variables.KeyBinds[tostring(key)] = command
			Remote.Get("UpdateKeybinds",Variables.KeyBinds)
			UI.Make("Hint",{
				Message = 'Bound "'..Functions.KeyCodeToName(key)..'" to '..command
			})
		end;

		RemoveKeyBind = function(key)
			local key = tostring(key);

			if Variables.KeyBinds[tostring(key)] ~= nil then
				Variables.KeyBinds[tostring(key)] = nil
				Remote.Get("UpdateKeybinds",Variables.KeyBinds)
				Routine(function()
					UI.Make("Hint",{
						Message = 'Removed "'..Functions.KeyCodeToName(key)..'" from key binds'
					})
				end)
			end
		end;

		BrickBlur = function(on,trans,color)
			local exists = service.LocalContainer():FindFirstChild("ADONIS_WINDOW_FUNC_BLUR")
			if exists then exists:Destroy() end
			if on then
				local pa = Instance.new("Part",workspace.CurrentCamera)
				pa.Name = "ADONIS_WINDOW_FUNC_BLUR"
				pa.Material = "Neon"
				pa.BrickColor = color or BrickColor.Black()
				pa.Transparency = trans or 0.5
				pa.CanCollide = false
				pa.Anchored = true
				pa.FormFactor = "Custom"
				pa.Size=Vector3.new(100,100,0)
				while pa and pa.Parent and wait(1/40) do
					pa.CFrame = workspace.CurrentCamera.CoordinateFrame*CFrame.new(0,0,-2.5)*CFrame.Angles(12.6,0,0)
				end
			else
				for i,v in next,workspace.CurrentCamera:GetChildren()do
					if v.Name == "ADONIS_WINDOW_FUNC_BLUR" then
						v:Destroy()
					end
				end
			end
		end;

		PlayAudio = function(audioId, volume, pitch, looped)
			if Variables.localSounds[tostring(audioId)] then Variables.localSounds[tostring(audioId)]:Stop() Variables.localSounds[tostring(audioId)]:Destroy() Variables.localSounds[tostring(audioId)]=nil end
			local sound = service.New("Sound")
			sound.SoundId = "rbxassetid://"..audioId
			if looped then sound.Looped = true end
			if volume then sound.Volume = volume end
			if pitch then sound.Pitch = pitch end
			sound.Name = "ADONI_LOCAL_SOUND "..audioId
			sound.Parent = service.LocalContainer()
			Variables.localSounds[tostring(audioId)] = sound
			sound:Play()
			wait(1)
			repeat wait(0.1) until not sound.IsPlaying
			sound:Destroy()
			Variables.localSounds[tostring(audioId)] = nil
		end;

		StopAudio = function(audioId)
			if Variables.localSounds[tostring(audioId)] then
				Variables.localSounds[tostring(audioId)]:Stop()
				Variables.localSounds[tostring(audioId)]:Destroy()
				Variables.localSounds[tostring(audioId)] = nil
			elseif audioId == "all" then
				for i,v in pairs(Variables.localSounds) do
					Variables.localSounds[i]:Stop()
					Variables.localSounds[i]:Destroy()
					Variables.localSounds[i] = nil
				end
			end
		end;

		FadeAudio = function(audioId,inVol,pitch,looped,incWait)
			if not inVol then
				local sound = Variables.localSounds[tostring(audioId)]
				if sound then
					for i = sound.Volume,0,-0.01 do
						sound.Volume = i
						wait(incWait or 0.1)
					end
					Functions.StopAudio(audioId)
				end
			else
				Functions.StopAudio(audioId)
				Functions.PlayAudio(audioId,0,pitch,looped)
				local sound = Variables.localSounds[tostring(audioId)]
				if sound then
					for i = 0,inVol,0.01 do
						sound.Volume = i
						wait(incWait or 0.1)
					end
				end
			end
		end;

		KillAllLocalAudio = function()
			for i,v in next,Variables.localSounds do
				v:Stop()
				v:Destroy()
				table.remove(Variables.localSounds,i)
			end
		end;

		RemoveGuis = function()
			for i,v in next,service.PlayerGui:GetChildren()do
				if not UI.Get(v) then
					v:Destroy()
				end
			end
		end;

		SetCoreGuiEnabled = function(element,enabled)
			service.StarterGui:SetCoreGuiEnabled(element,enabled)
		end;

		UnCape = function()
			local cape = service.LocalContainer():FindFirstChild("::Adonis::Cape")
			if cape then cape:Destroy() end
		end;

		Cape = function(material,color,decal,reflect)
			local torso = service.Player.Character:FindFirstChild("HumanoidRootPart")
			if torso then
				local p = service.New("Part",service.LocalContainer())
				p.Name = "::Adonis::Cape"
				p.Anchored = true
				p.Transparency=0.1
				p.Material=material
				p.CanCollide = false
				p.TopSurface = 0
				p.BottomSurface = 0
				if type(color)=="table" then
					color = Color3.new(color[1],color[2],color[3])
				end
				p.BrickColor = BrickColor.new(color) or BrickColor.new("White")
				if reflect then
					p.Reflectance=reflect
				end
				if decal and decal~=0 then
					local dec = service.New("Decal", p)
					dec.Face = 2
					dec.Texture = "http://www.roblox.com/asset/?id="..decal
					dec.Transparency=0
				end
				p.formFactor = "Custom"
				p.Size = Vector3.new(.2,.2,.2)
				local msh = service.New("BlockMesh", p)
				msh.Scale = Vector3.new(9,17.5,.5)
				wait(0.1)
				p.Anchored=false
				local motor1 = service.New("Motor", p)
				motor1.Part0 = p
				motor1.Part1 = torso
				motor1.MaxVelocity = .01
				motor1.C0 = CFrame.new(0,1.75,0)*CFrame.Angles(0,math.rad(90),0)
				motor1.C1 = CFrame.new(0,1,torso.Size.Z/2)*CFrame.Angles(0,math.rad(90),0)--.45
				local wave = false
				repeat wait(1/44)
					local ang = 0.1
					local oldmag = torso.Velocity.Magnitude
					local mv = .002
					if wave then ang = ang + ((torso.Velocity.Magnitude/10)*.05)+.05
						wave = false
					else
						wave = true
					end
					ang = ang + math.min(torso.Velocity.Magnitude/11, .5)
					motor1.MaxVelocity = math.min((torso.Velocity.Magnitude/111), .04) + mv
					motor1.DesiredAngle = -ang
					if motor1.CurrentAngle < -.2 and motor1.DesiredAngle > -.2 then
						motor1.MaxVelocity = .04
					end

					repeat wait() until motor1.CurrentAngle == motor1.DesiredAngle or math.abs(torso.Velocity.Magnitude - oldmag) >=(torso.Velocity.Magnitude/10) + 1

					if torso.Velocity.Magnitude < .1 then
						wait(.1)
					end
				until not p or not p.Parent or p.Parent ~= service.LocalContainer()
			end
		end;

		TextToSpeech = function(str)
			local audioId = 296333956

			local audio = Instance.new("Sound",service.LocalContainer())
			audio.SoundId = "rbxassetid://"..audioId
			audio.Volume = 1

			local audio2 = Instance.new("Sound",service.LocalContainer())
			audio2.SoundId = "rbxassetid://"..audioId
			audio2.Volume = 1

			local phonemes = {
				{
					str='%so';
					func={17}
				}; --(on)
				{
					str='ing';
					func={41}
				}; --(singer)
				{
					str="oot";
					func={4, 26}; --oo,t
				};
				{
					str='or';
					func={10}
				}; --(door) --oor
				{
					str='oo';
					func={3}
				};  --(good)
				{
					str='hi';
					func={44, 19}; --h, y/ii
				};
				{
					str='ie';
					func={1}; --ee
				};
				{
					str="eye";
					func={19}; --y/ii
				};
				{
					str="$Suy%s"; --%Suy
					real="uy";
					func={19}; --y/ii
				};
				{
					str="%Sey%s"; --%Sey
					func={1}; --ee
				};
				{
					str="%sye"; --%sye
					func={19}; --y/ii
				};
				--[[{
					str='th';
					func={30.9, 31.3}
				}; --(think)--]]
				{
					str='the';
					func={25, 15}; --th, u
				};
				{
					str='th';
					func={32, 0.2395}
				}; --(this)
				--[[
				{
					str='ow';
					func={10, 0.335}
				}; --(show) --ow
				--]]
				{
					str='ow';
					func={20}
				}; --(cow) --ow
				{
					str="qu";
					func={21,38};--c,w
				};
				{
					str='ee';
					func={1}
				}; --(sheep)
				{
					str='i%s';
					delay=0.5;
					func={19}
				}; --(I)
				{
					str='ea';
					func={1}
				}; --(read)
				{
					str='u(.*)e';
					real='u';
					capture=true;
					func={9}
				}; --(cure) (match ure) --u
				{
					str='ch';
					func={24}
				}; --(cheese)
				{
					str='ere';
					func={5}
				}; --(here)
				{
					str='ai';
					func={6}
				}; --(wait)
				{
					str='la';
					func={39,6}
				};
				{
					str='oy';
					func={8}
				}; --(boy)
				{
					str='gh';
					func={44};
				};
				{
					str='sh';
					func={22}
				}; --(shall)
				{
					str='air';
					func={18}
				}; --(hair)

				{
					str='ar';
					func={16}
				}; --(far)
				{
					str='ir';
					func={11}
				}; --(bird)
				{
					str='er';
					func={12}
				}; --(teacher)
				{
					str='sio';
					func={35}
				}; --(television)
				{
					str='ck';
					func={21}
				}; --(book)
				{
					str="zy";
					func={34,1}; --z,ee
				};
				{
					str="ny";
					func={42, 1}; --n,ee
				};
				{
					str="ly";
					func={39, 1}; --l,ee
				};
				{
					str="ey";
					func={1} --ee
				};
				{
					str='ii';
					func={19}
				}; --(ii?)
				{
					str='i';
					func={2}
				};--(ship)

				{
					str='y'; --y%S
					func={37}
				}; --(yes)
				--[[
				{
					str='%Sy';
					func={23.9, 24.4}
				}; --(my)
				--]]
				{
					str='y';
					func={37}
				}; --(my)

				{
					str='s';
					func={23}
				}; --(see)

				{
					str='e';
					func={13};
				}; --(bed)
				--[[--]]
				{
					str='a';
					func={14}
				}; --(cat)
				--[[
				{
					str='a';
					func={6}
				}; --(lazy) --ai--]]
				{
					str="x";
					func={21, 23} --c, s
				};
				{
					str='u';
					func={15}
				}; --(up)
				{
					str='o';
					func={17}
				}; --(on)
				{
					str='c';
					func={21}
				}; --(car)
				{
					str='k';
					func={21}
				}; --(book)
				{
					str='t';
					func={26}
				}; --(tea)
				{
					str='f';
					func={27}
				}; --(fly)
				{
					str='i';
					func={2}
				};--(ship)
				{
					str='p';
					func={28}
				}; --(pea)
				{
					str='b';
					func={29}
				}; --(boat)
				{
					str='v';
					func={30}
				}; --(video)
				{
					str='d';
					func={31}
				}; --(dog)
				{
					str='j';
					func={33}
				}; --(june)
				{
					str='z';
					func={34}
				}; --(zoo)
				{
					str='g';
					func={36}
				}; --(go)
				{
					str='w';
					func={38}
				}; --(wet)
				{
					str='l';
					func={39}
				}; --(love)
				{
					str='r';
					func={40}
				}; --(red)
				{
					str='n';
					func={42}
				}; --(now)
				{
					str='m';
					func={43}
				}; --(man)
				{
					str='h';
					func={44}
				}; --(hat)
				{
					str=' ';
					func="wait";
				};
				{
					str='%.';
					func="wait";
				};
				{
					str='!';
					func="wait";
				};
				{
					str='?';
					func="wait";
				};
				{
					str=';';
					func="wait";
				};
				{
					str=':';
					func="wait";
				};

			}

			game:service("ContentProvider"):Preload("rbxassetid://"..audioId)

			local function getText(str)
				local tab = {}
				local str = str
				local function getNext()
					for i,v in ipairs(phonemes) do
						local occ,pos = string.find(string.lower(str),"^"..v.str)
						if occ then
							if v.capture then
								local real = v.real
								local realStart,realEnd = string.find(string.lower(str),real)
								--local captStart,captEnd = str:lower():find(v.str)
								local capt = string.match(string.lower(str),v.str)
								if occ>realEnd then
									table.insert(tab,v)
									getText(capt)
								else
									getText(capt)
									table.insert(tab,v)
								end
							else
								table.insert(tab,v)
							end
							str = string.sub(str,pos+1)
							getNext()
						end
					end
				end
				getNext()
				return tab
			end

			local phos=getText(str)
			local swap = false

			local function say(pos)
				local sound=audio
				--[[--]]
				if swap then
					sound=audio2
				end--]]
				sound.TimePosition=pos
				--sound:Play()
				--wait(0.2) --wait(pause)
				--sound:Stop()
			end

			audio:Play()
			audio2:Play()
			for i,v in ipairs(phos) do
				--print(i,v.str)
				if type(v.func)=="string" then--v.func=="wait" then
					wait(0.5)
				elseif type(v)=="table" then
					for l,p in ipairs(v.func) do
						--[[--]]
						if swap then
							swap=false
						else
							swap=true
						end--]]
						say(p)
						if v.delay then
							wait(v.delay)
						else
							wait(0.1)
						end
					end
				end
			end
			wait(0.5)
			audio:Stop()
			audio2:Stop()
		end;

		IsValidTexture = function(id)
			local id = tonumber(id)
			local ran, info = pcall(function() return service.MarketPlace:GetProductInfo(id) end)

			if ran and info and info.AssetTypeId == 1 then
				return true;
			else
				return false;
			end
		end;

		GetTexture = function(id)
			local id = tonumber(id);
			if id and Functions.IsValidTexture(id) then
				return id;
			else
				return 6825455804;
			end
		end;
	};
end
