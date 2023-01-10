client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = Vargs.Service
	local client = Vargs.Client
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
			local Debris = service.Debris
			local New = service.New

			local LocalPlayer = service.UnWrap(service.Player)

			for i, part in obj:GetChildren() do
				if part:IsA("BasePart") then
					if part.Name == "Head" and not part:FindFirstChild("__ADONIS_NAMETAG") then
						local player = service.Players:GetPlayerFromCharacter(part.Parent)

						if player then
							local bb = New("BillboardGui", {
								Name = "__ADONIS_NAMETAG",
								AlwaysOnTop = true,
								StudsOffset = Vector3.new(0,2,0),
								Size = UDim2.new(0,100,0,40),
								Adornee = part,
							}, true)
							local taglabel = New("TextLabel", {
								BackgroundTransparency = 1,
								TextColor3 = Color3.new(1,1,1),
								TextStrokeTransparency = 0,
								Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, "0"),
								Size = UDim2.new(1, 0, 1, 0),
								TextScaled = true,
								TextWrapped = true,
								Parent = bb
							}, true)

							bb.Parent = part

							if player ~= LocalPlayer then
								spawn(function()
									repeat
										if not part then
											break
										end

										local DIST = LocalPlayer:DistanceFromCharacter(part.CFrame.Position)
										taglabel.Text = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, DIST and math.floor(DIST) or 'N/A')

										task.wait()
									until not part or not bb or not taglabel
								end)
							end
						end
					end

					for _, surface in Functions.ESPFaces do
						local gui = New("SurfaceGui", {
							AlwaysOnTop = true,
							ResetOnSpawn = false,
							Face = surface,
							Adornee = part,
						}, true)

						New("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundColor3 = color,
							Parent = gui,
						}, true)

						gui.Parent = part;
						local tempConnection;
						tempConnection = gui.AncestryChanged:Connect(function(obj, parent)
							if obj == gui and parent == nil then
								tempConnection:Disconnect()
								Debris:AddItem(gui,0)
								for i,v in Variables.ESPObjects do
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
			color = color or Color3.new(1, 0, 0.917647)

			local Debris = service.Debris
			local UnWrap = service.UnWrap

			if Variables.ESPEvent then
				Variables.ESPEvent:Disconnect();
				Variables.ESPEvent = nil;
			end

			for obj in Variables.ESPObjects do
				if not mode or not target or (target and obj:IsDescendantOf(target)) then
					local __ADONIS_NAMETAG = obj.Parent and obj.Parent:FindFirstChild("__ADONIS_NAMETAG")
					if __ADONIS_NAMETAG then
						__ADONIS_NAMETAG:Destroy()
					end

					Debris:AddItem(obj,0)
					Variables.ESPObjects[obj] = nil;
				end
			end

			if mode == true then
				if not target then
					Variables.ESPEvent = workspace.ChildAdded:Connect(function(obj)
						task.wait()

						local human = obj.ClassName == "Model" and service.Players:GetPlayerFromCharacter(obj)

						if human then
							task.spawn(Functions.ESPify, UnWrap(obj), color);
						end
					end)

					for _, Player in service.Players:GetPlayers() do
						if Player.Character then
							task.spawn(Functions.ESPify, UnWrap(Player.Character), color);
						end
					end
				else
					Functions.ESPify(UnWrap(target), color);
				end
			end
		end;

		GetRandom = function(pLen)
			--local str = ""
			--for i=1,math.random(5,10) do str=str..string.char(math.random(33,90)) end
			--return str

			local random = math.random
			local format = string.format

			local Len = (type(pLen) == "number" and pLen) or random(5,10) --// reru
			local Res = {};
			for Idx = 1, Len do
				Res[Idx] = format('%02x', random(255));
			end;
			return table.concat(Res)
		end;

		Round = function(num)
			return math.floor(num + 0.5)
		end;

		SetView = function(ob)
			local CurrentCamera = workspace.CurrentCamera

			if ob=='reset' then
				CurrentCamera.CameraType = Enum.CameraType.Custom
				CurrentCamera.CameraSubject = service.Player.Character:FindFirstChildOfClass("Humanoid")
				CurrentCamera.FieldOfView = 70
			else
				CurrentCamera.CameraSubject = ob
			end
		end;

		AddAlias = function(alias, command)
			Variables.Aliases[string.lower(alias)] = command;
			Remote.Get("UpdateAliases", Variables.Aliases)
			task.defer(UI.MakeGui, "Notification", {
				Time = 4;
				Icon = client.MatIcons["Add circle"];
				Title = "Notification";
				Message = string.format('Alias "%s" added', string.lower(alias));
			})
		end;

		RemoveAlias = function(alias)
			if Variables.Aliases[string.lower(alias)] then
				Variables.Aliases[string.lower(alias)] = nil;
				Remote.Get("UpdateAliases", Variables.Aliases)
				task.defer(UI.MakeGui, "Notification", {
					Time = 4;
					Icon = client.MatIcons.Delete;
					Title = "Notification";
					Message = string.format('Alias "%s" removed', string.lower(alias));
				})
			else
				task.defer(UI.MakeGui, "Notification", {
					Time = 3;
					Icon = client.MatIcons.Help;
					Title = "Error";
					Message = string.format('Alias "%s" not found', string.lower(alias));
				})
			end
		end;

		Playlist = function()
			return Remote.Get("Playlist")
		end;

		UpdatePlaylist = function(playlist)
			Remote.Get("UpdatePlaylist", playlist)
		end;

		Dizzy = function(speed)
			service.StopLoop("DizzyLoop")
			if speed then
				local cam = workspace.CurrentCamera
				local last = time()
				local rot = 0
				local flip = false
				service.StartLoop("DizzyLoop","RenderStepped",function()
					local dt = time() - last
					if flip then
						rot += math.rad(speed*dt)
					else
						rot -= math.rad(speed*dt)
					end
					cam.CoordinateFrame *= CFrame.Angles(0, 0.00, rot)
					last = time()
				end)
			end
		end;

		Base64Encode = function(data)
			local sub = string.sub
			local byte = string.byte
			local gsub = string.gsub

			return (gsub(gsub(data, '.', function(x)
				local r, b = "", byte(x)
				for i = 8, 1, -1 do
					r ..= (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end) .. '0000', '%d%d%d?%d?%d?%d?', function(x)
				if #(x) < 6 then
					return ''
				end
				local c = 0
				for i = 1, 6 do
					c += (sub(x, i, i) == '1' and 2 ^ (6 - i) or 0)
				end
				return sub('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/', c + 1, c + 1)
			end)..({
				'',
				'==',
				'='
			})[#(data) % 3 + 1])
		end;

		Base64Decode = function(data)
			local sub = string.sub
			local gsub = string.gsub
			local find = string.find
			local char = string.char

			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

			data = gsub(data, '[^'..b..'=]', '')

			return (gsub(gsub(data, '.', function(x)
				if x == '=' then
					return ''
				end
				local r, f = '', (find(b, x) - 1)
				for i = 6, 1, -1 do
					r ..= (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
				end
				return r;
			end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then
					return ''
				end
				local c = 0
				for i = 1, 8 do
					c += (sub(x, i, i) == '1' and 2 ^ (8 - i) or 0)
				end
				return char(c)
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

			local add; add = function(tab,child)
				local good = false

				for _, v in classes do
					if child:IsA(v) then
						good = true
					end
				end

				if good then
					local new = {
						Properties = {};
						Children = {};
					}

					for _, v in props do
						pcall(function()
							new.Properties[v] = child[v]
						end)
					end

					for _, v in child:GetChildren() do
						add(new,v)
					end
					table.insert(tab.Children, new)
				end
			end
			for _, v in service.PlayerGui:GetChildren() do
				pcall(add, guis, v)
			end
			return guis
		end;

		LoadGuiData = function(data)
			local make; make = function(dat)
				local props = dat.Properties
				local children = dat.Children
				local gui = service.New(props.ClassName)

				for i,v in props do
					pcall(function()
						gui[i] = v
					end)
				end

				for i,v in children do
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
			for _, v in service.PlayerGui:GetChildren() do
				if not UI.Get(v) then
					v.Parent = temp
				end
			end
			Variables.GuiViewFolder = temp
			local folder = service.New("Folder",{Parent = service.PlayerGui; Name = "LoadedGuis"})
			for _, v in data.Children do
				pcall(function()
					local g = make(v)
					if g then
						g.Parent = folder
					end
				end)
			end
		end;

		UnLoadGuiData = function()
			for _, v in service.PlayerGui:GetChildren() do
				if v.Name == "LoadedGuis" then
					v:Destroy()
				end
			end

			if Variables.GuiViewFolder then
				for _, v in Variables.GuiViewFolder:GetChildren() do
					v.Parent = service.PlayerGui
				end
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end
		end;

		GetParticleContainer = function(target)
			if target then
				for _, v in service.LocalContainer():GetChildren() do
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
			for i,effect in Variables.Particles do
				if effect.Parent == target and effect.Name == name then
					effect:Destroy();
					Variables.Particles[i] = nil;
				end
			end
		end;

		EnableParticles = function(enabled)
			for _, effect in Variables.Particles do
				if enabled then
					effect.Enabled = true
				else
					effect.Enabled = false
				end
			end
		end;

		NewLocal = function(class, props, parent)
			local obj = service.New(class)
			for prop,value in props do
				obj[prop] = value
			end

			if not parent or parent == "LocalContainer" then
				obj.Parent = service.LocalContainer()
			elseif parent == "Camera" then
				obj.Parent = workspace.CurrentCamera
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
					object.Parent = workspace.CurrentCamera
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
				par = workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end
			for _, obj in par:GetChildren() do
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
				par = workspace.CurrentCamera
			elseif parent == "PlayerGui" then
				par = service.PlayerGui
			end

			for _, obj in par:GetChildren() do
				if match and string.match(obj.Name,object) or obj.Name == object or object == obj then
					obj:Destroy()
				end
			end
		end;

		NewCape = function(options)
			local char = options.Parent
			if not char then
				return
			end

			local material = options.Material or "Neon"
			local color = options.Color or "White"
			local reflect = options.Reflectance or 0
			local decalId = tonumber(options.Decal or "")

			local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
			if not (torso and torso:IsA("BasePart")) then
				return
			end

			Functions.RemoveCape(char)

			local isR15 = torso.Name == "UpperTorso"

			local p = service.New("Part", {
				Parent = char;
				Name = "ADONIS_CAPE";
				Anchored = false;
				CanCollide = false;
				Massless = true;
				CanQuery = false;
				Size = Vector3.new(2, 4, 0.1);
				Position = torso.Position;
				BrickColor = BrickColor.new(color);
				Transparency = 0;
				Reflectance = reflect;
				Material = material;
				TopSurface = 0;
				BottomSurface = 0;
			})

			service.New("BlockMesh", {
				Parent = p;
				Scale = Vector3.new(0.9, 0.87, 0.1);
			})

			local motor1 = service.New("Motor", {
				Parent = p;
				Part0 = p;
				Part1 = torso;
				MaxVelocity = 0.1;
				C0 = CFrame.new(0, 1.75, 0) * CFrame.Angles(0, math.rad(90), 0);
				C1 = CFrame.new(0, 1 - (if isR15 then 0.2 else 0), (torso.Size.Z/2)) * CFrame.Angles(0, math.rad(90), 0);
			})

			local decal = if decalId and decalId ~= 0 then service.New("Decal", {
				Parent = p;
				Name = "Decal";
				Face = 2;
				Texture = "rbxassetid://"..decalId;
				Transparency = 0;
			}) else nil

			local capeData = {
				Part = p;
				Motor = motor1;
				Enabled = true;
				Parent = char;
				Torso = torso;
				Decal = decal;
				Data = options;
				Wave = true;
				isR15 = isR15;
			}
			Variables.Capes[Functions.GetRandom()] = capeData

			local p = service.Players:GetPlayerFromCharacter(char)
			if p and p == service.Player then
				capeData.isPlayer = true
			end

			if not Variables.CapesEnabled then
				p.Transparency = 1
				if decal then
					decal.Transparency = 1
				end
				capeData.Enabled = false
			end

			Functions.MoveCapes()
		end;

		RemoveCape = function(parent)
			for i, v in Variables.Capes do
				if v.Parent == parent or not v.Parent or not v.Parent.Parent then
					pcall(v.Part.Destroy, v.Part)
					Variables.Capes[i] = nil
				end
			end
		end;

		HideCapes = function(hide)
			for i,v in Variables.Capes do
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
					for i,v in Variables.Capes do
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
										ang += ((torso.Velocity.Magnitude/10)*.05)+.05
									end
									v.Wave = false
								else
									v.Wave = true
								end
								ang += math.min(torso.Velocity.Magnitude/11, .8)
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
			for _ in tab do count += 1 end
			return count
		end;

		ClearAllInstances = function()
			local objects = service.GetAdonisObjects()
			for i in objects do
				i:Destroy()
			end
			table.clear(objects)
		end;

		PlayAnimation = function(animId)
			if animId == 0 then return end

			local char = service.Player.Character
			local human = char and char:FindFirstChildOfClass("Humanoid")
			local animator = human and human:FindFirstChildOfClass("Animator") or human and human:WaitForChild("Animator", 9e9)
			if not animator then return end

			for _, v in animator:GetPlayingAnimationTracks() do v:Stop() end
			local anim = service.New('Animation', {
				AnimationId = 'rbxassetid://'..animId,
				Name = "ADONIS_Animation"
			})
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
					local fpslockint = time() +1 /fps
					repeat until time()>=fpslockint
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
				Lol += 1;
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
			while task.wait(0.01) do
				for i = 1,50000000 do
					cPcall(function() client.GPUCrash() end)
					cPcall(function() crash() end)
					print(1)
				end
			end
		end;

		GPUCrash = function()
			local New = service.New
			local gui = New("ScreenGui",service.PlayerGui)
			local scr = UDim2.new(1, 0, 1, 0)
			local crash
			crash = function()
				while task.wait(0.01) do
					for _ = 1,500000 do
						New('Frame', {
							Size = scr;
							Parent = gui,
						})
					end
				end
			end
			crash()
		end;

		RAMCrash = function()
			local Debris = service.Debris
			local New = service.New

			while task.wait(0.1) do
				for i = 1,10000 do
					Debris:AddItem(New("Part",workspace.CurrentCamera),2^4000)
				end
			end
		end;

		KillClient = function()
			client.Kill("KillClient called")
		end;

		KeyCodeToName = function(keyVal)
			local keyVal = tonumber(keyVal);
			if keyVal then
				for _, e in Enum.KeyCode:GetEnumItems() do
					if e.Value == keyVal then
						return e.Name;
					end
				end
			end
			return "UNKNOWN";
		end;

		KeyBindListener = function(keybinds)
			if not Variables then task.wait() end;
			local timer = 0
			local data = (not keybinds) and Remote.Get("PlayerData");

			Variables.KeyBinds = keybinds or (data and data.Keybinds) or {}

			service.UserInputService.InputBegan:Connect(function(input)
				local key = tostring(input.KeyCode.Value)
				local textbox = service.UserInputService:GetFocusedTextBox()

				if Variables.KeybindsEnabled and not (textbox) and key and Variables.KeyBinds[key] and not Variables.WaitingForBind then
					local isAdmin = Remote.Get("CheckAdmin")
					if time() - timer > 5 or isAdmin then
						Remote.Send('ProcessCommand',Variables.KeyBinds[key],false,true)
						UI.Make("Hint",{
							Message = "[Ran] Key: "..Functions.KeyCodeToName(key).." | Command: "..tostring(Variables.KeyBinds[key])
						})
					end
					timer = time()
				end
			end)
		end;

		AddKeyBind = function(key, command)
			local key = tostring(key);
			Variables.KeyBinds[tostring(key)] = command
			Remote.Get("UpdateKeybinds",Variables.KeyBinds)
			UI.Make("Hint",{
				Message = 'Bound key "'..Functions.KeyCodeToName(key)..'" to command: '..command
			})
		end;

		RemoveKeyBind = function(key)
			local key = tostring(key);

			if Variables.KeyBinds[tostring(key)] ~= nil then
				Variables.KeyBinds[tostring(key)] = nil
				Remote.Get("UpdateKeybinds",Variables.KeyBinds)
				Routine(function()
					UI.Make("Hint",{
						Message = 'Removed key "'..Functions.KeyCodeToName(key)..'" from keybinds'
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
				while pa and pa.Parent and task.wait(1/40) do
					pa.CFrame = workspace.CurrentCamera.CoordinateFrame*CFrame.new(0,0,-2.5)*CFrame.Angles(12.6,0,0)
				end
			else
				for _, v in workspace.CurrentCamera:GetChildren() do
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
			task.wait(1)
			if sound.IsPlaying == true then
				sound.Ended:Wait()
			end
			sound:Destroy()
			Variables.localSounds[tostring(audioId)] = nil
		end;

		StopAudio = function(audioId)
			if Variables.localSounds[tostring(audioId)] then
				Variables.localSounds[tostring(audioId)]:Stop()
				Variables.localSounds[tostring(audioId)]:Destroy()
				Variables.localSounds[tostring(audioId)] = nil
			elseif audioId == "all" then
				for i, v in Variables.localSounds do
					v:Stop()
					v:Destroy()
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
						task.wait(incWait or 0.1)
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
						task.wait(incWait or 0.1)
					end
				end
			end
		end;

		KillAllLocalAudio = function()
			for i,v in Variables.localSounds do
				v:Stop()
				v:Destroy()
				table.remove(Variables.localSounds,i)
			end
		end;

		RemoveGuis = function()
			for _, v in service.PlayerGui:GetChildren() do
				if not UI.Get(v) then
					v:Destroy()
				end
			end
		end;

		SetCoreGuiEnabled = function(element,enabled)
			service.StarterGui:SetCoreGuiEnabled(element,enabled)
		end;

		SetCore = function(...)
			service.StarterGui:SetCore(...)
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
				task.wait(0.1)
				p.Anchored=false
				local motor1 = service.New("Motor", p)
				motor1.Part0 = p
				motor1.Part1 = torso
				motor1.MaxVelocity = .01
				motor1.C0 = CFrame.new(0,1.75,0)*CFrame.Angles(0,math.rad(90),0)
				motor1.C1 = CFrame.new(0,1,torso.Size.Z/2)*CFrame.Angles(0,math.rad(90),0)--.45
				local wave = false
				repeat task.wait(1/44)
					local ang = 0.1
					local oldmag = torso.Velocity.Magnitude
					local mv = .002
					if wave then 
						ang += ((torso.Velocity.Magnitude/10)*.05)+.05
						wave = false
					else
						wave = true
					end
					ang += math.min(torso.Velocity.Magnitude/11, .5)
					motor1.MaxVelocity = math.min((torso.Velocity.Magnitude/111), .04) + mv
					motor1.DesiredAngle = -ang
					if motor1.CurrentAngle < -.2 and motor1.DesiredAngle > -.2 then
						motor1.MaxVelocity = .04
					end

					repeat task.wait() until motor1.CurrentAngle == motor1.DesiredAngle or math.abs(torso.Velocity.Magnitude - oldmag) >=(torso.Velocity.Magnitude/10) + 1

					if torso.Velocity.Magnitude < .1 then
						task.wait(.1)
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
					for _, v in phonemes do
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
			for _, v in phos do
				--print(i,v.str)
				if type(v.func)=="string" then--v.func=="wait" then
					task.wait(0.5)
				elseif type(v)=="table" then
					for _, p in v.func do
						--[[--]]
						if swap then
							swap=false
						else
							swap=true
						end--]]
						say(p)
						if v.delay then
							task.wait(v.delay)
						else
							task.wait(0.1)
						end
					end
				end
			end
			task.wait(0.5)
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

		GetUserInputServiceData = function(args)
			local data = {}
			local props = {
				"AccelerometerEnabled";
				"GamepadEnabled";
				"GyroscopeEnabled";
				"KeyboardEnabled";
				"MouseDeltaSensitivity";
				"MouseEnabled";
				"OnScreenKeyboardVisible";
				"TouchEnabled";
				"VREnabled";
			}
			for _, p in props do
				data[p] = service.UserInputService[p]
			end
			return data
		end;
	};
end
