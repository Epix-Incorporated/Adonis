--# selene: allow(empty_loop)
client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error, pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, print, math, warn, error, pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script  = script
	local service = Vargs.Service
	local client  = Vargs.Client
	local Anti, Core, Functions, Process, Remote, UI, Variables

	local function Init()
		UI        = client.UI
		Anti      = client.Anti
		Core      = client.Core
		Variables = client.Variables
		Functions = client.Functions
		Process   = client.Process
		Remote    = client.Remote
		Functions.Init = nil
	end

	local function RunLast()
		Functions.RunLast = nil
	end

	getfenv().client  = nil
	getfenv().service = nil
	getfenv().script  = nil

	-- ── Shared helper ─────────────────────────────────────────────────────────
	local function resolveParent(parent)
		if not parent or parent == "LocalContainer" then
			return service.LocalContainer()
		elseif parent == "Camera" then
			return workspace.CurrentCamera
		elseif parent == "PlayerGui" then
			return service.PlayerGui
		end
	end

	-- ── Base64 ────────────────────────────────────────────────────────────────
	
	local B64_ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local B64_LUT   


	local GUI_PROPS, GUI_CLASS_SET

	local function buildGuiTables()
		GUI_PROPS = {
			"AbsolutePosition","AutomaticCanvasSize","BottomImage","AbsoluteSize",
			"AnchorPoint","CornerRadius","CanvasSize","CanvasPosition","ClassName",
			"ElasticBehavior","Name","Parent","Archivable","DisplayOrder",
			"SelectionImageObject","Active","BackgroundColor3","BackgroundTransparency",
			"BorderColor3","BorderSizePixel","Position","Rotation","RichText",
			"Selectable","HorizontalScrollBarPosition","Size","Enabled","Active",
			"SizeConstraint","Style","ScrollBarThickness","ScrollBarImageTransparency",
			"ScrollingEnabled","ScrollingDirection","ScrollBarImageColor","Visible",
			"ZIndex","ClipsDescendants","Draggable","NextSelectionDown",
			"NextSelectionLeft","NextSelectionRight","NextSelectionUp",
			"PlaceholderColor3","PlaceholderText","AutoButtonColor","Modal",
			"MidImage","Image","ImageColor3","ImageRectOffset","ImageRectSize",
			"ImageTransparency","ScaleType","SliceCenter","Text","TopImage",
			"TextColor3","TextDirection","Font","TextScaled","TextSize",
			"TextStrokeColor3","TextStrokeTransparency","TextTransparency",
			"TextTuncate","TextWrapped","TextXAlignment","TextYAlignment",
			"VerticalScrollBarInset","VerticalScrollBarPosition","AspectRatio",
			"AspectType","DominantAxis","Offset","Transparency","CellPadding",
			"CellSize","Padding","PaddingBottom","PaddingLeft","PaddingRight",
			"PaddingTop","Animated","Circular","EasingDirection","EasingStyle",
			"TweenTime","FillDirection","SortOrder","VerticalAlignment",
			"GamepadInputEnabled","ScrollWheelInputEnabled","TouchInputEnabled",
			"Scale","MaxSize","MinSize","ApplyStrokeMode","Color","LineJoinMode",
			"Thickness","FillEmptySpaceColumns","FillEmptySpaceRow","MajorAxis",
			"HorizontalAlignment","MaxTextSize","MinTextSize","GroupColor3",
			"GroupTransparency","SelectionImageObject","Looped","Playing",
			"TimePosition","Video","Volume","LayoutOrder","Ambient","LightColor",
			"LightDirection","CurrentCamera","AutomaticSize","AutoLocalize",
			"RootLocalizationTable",
		}
		GUI_CLASS_SET = {
			ScreenGui=true, GuiMain=true, Frame=true, CanvasGroup=true,
			TextButton=true, TextLabel=true, ImageButton=true, ImageLabel=true,
			ScrollingFrame=true, TextBox=true, BillboardGui=true, SurfaceGui=true,
			UICorner=true, UIAspectRatioConstraint=true, UIGradient=true,
			UIGridLayout=true, UIListLayout=true, UIPadding=true, UIPageLayout=true,
			UIScale=true, UISizeConstraint=true, UIStroke=true, UITableLayout=true,
			UITextSizeConstraint=true, VideoFrame=true, ViewportFrame=true,
		}
	end


	local TTS_PHONEMES = {
		{str='%so';func={17}};
		{str='ing';func={41}};
		{str="oot";func={4,26}};
		{str='or';func={10}};
		{str='oo';func={3}};
		{str='hi';func={44,19}};
		{str='ie';func={1}};
		{str="eye";func={19}};
		{str="$Suy%s";real="uy";func={19}};
		{str="%Sey%s";func={1}};
		{str="%sye";func={19}};
		{str='the';func={25,15}};
		{str='th';func={32,0.2395}};
		{str='ow';func={20}};
		{str="qu";func={21,38}};
		{str='ee';func={1}};
		{str='i%s';delay=0.5;func={19}};
		{str='ea';func={1}};
		{str='u(.*)e';real='u';capture=true;func={9}};
		{str='ch';func={24}};
		{str='ere';func={5}};
		{str='ai';func={6}};
		{str='la';func={39,6}};
		{str='oy';func={8}};
		{str='gh';func={44}};
		{str='sh';func={22}};
		{str='air';func={18}};
		{str='ar';func={16}};
		{str='ir';func={11}};
		{str='er';func={12}};
		{str='sio';func={35}};
		{str='ck';func={21}};
		{str="zy";func={34,1}};
		{str="ny";func={42,1}};
		{str="ly";func={39,1}};
		{str="ey";func={1}};
		{str='ii';func={19}};
		{str='i';func={2}};
		{str='y';func={37}};
		{str='y';func={37}};
		{str='s';func={23}};
		{str='e';func={13}};
		{str='a';func={14}};
		{str="x";func={21,23}};
		{str='u';func={15}};
		{str='o';func={17}};
		{str='c';func={21}};
		{str='k';func={21}};
		{str='t';func={26}};
		{str='f';func={27}};
		{str='i';func={2}};
		{str='p';func={28}};
		{str='b';func={29}};
		{str='v';func={30}};
		{str='d';func={31}};
		{str='j';func={33}};
		{str='z';func={34}};
		{str='g';func={36}};
		{str='w';func={38}};
		{str='l';func={39}};
		{str='r';func={40}};
		{str='n';func={42}};
		{str='m';func={43}};
		{str='h';func={44}};
		{str=' ';func="wait"};
		{str='%.';func="wait"};
		{str='!';func="wait"};
		{str='?';func="wait"};
		{str=';';func="wait"};
		{str=':';func="wait"};
	}

	client.Functions = {
		Init    = Init;
		RunLast = RunLast;
		Kill    = client.Kill;

		ESPFaces = {"Front","Back","Top","Bottom","Left","Right"};

		ESPify = function(obj, color)
			local Debris      = service.Debris
			local New         = service.New
			local LocalPlayer = service.UnWrap(service.Player)
			local ESPFaces    = Functions.ESPFaces
			local ESPObjects  = Variables.ESPObjects

			for _, part in obj:GetChildren() do
				if not part:IsA("BasePart") then continue end

				if part.Name == "Head" and not part:FindFirstChild("__ADONIS_NAMETAG") then
					local player = service.Players:GetPlayerFromCharacter(part.Parent)
					if player then
						local bb = New("BillboardGui", {
							Name        = "__ADONIS_NAMETAG";
							AlwaysOnTop = true;
							StudsOffset = Vector3.new(0, 2, 0);
							Size        = UDim2.new(0, 100, 0, 40);
							Adornee     = part;
						}, true)
						local taglabel = New("TextLabel", {
							BackgroundTransparency = 1;
							TextColor3             = Color3.new(1, 1, 1);
							TextStrokeTransparency = 0;
							Text                   = string.format("%s (@%s)\n> %s <", player.DisplayName, player.Name, "0");
							Size                   = UDim2.new(1, 0, 1, 0);
							TextScaled             = true;
							TextWrapped            = true;
							Parent                 = bb;
						}, true)
						bb.Parent = part
						if player ~= LocalPlayer then
							task.spawn(function()
								repeat
									if not part then break end
									local dist = LocalPlayer:DistanceFromCharacter(part.CFrame.Position)
									taglabel.Text = string.format("%s (@%s)\n> %s <",
										player.DisplayName, player.Name,
										dist and math.floor(dist) or "N/A")
									task.wait()
								until not part or not bb or not taglabel
							end)
						end
					end
				end

				for _, surface in ESPFaces do
					local gui = New("SurfaceGui", {
						AlwaysOnTop  = true;
						ResetOnSpawn = false;
						Face         = surface;
						Adornee      = part;
					}, true)
					New("Frame", {
						Size             = UDim2.new(1, 0, 1, 0);
						BackgroundColor3 = color;
						Parent           = gui;
					}, true)
					gui.Parent = part
					local conn
					conn = gui.AncestryChanged:Connect(function(obj, parent)
						if obj == gui and parent == nil then
							conn:Disconnect()
							Debris:AddItem(gui, 0)
							ESPObjects[gui] = nil
						end
					end)
					ESPObjects[gui] = part
				end
			end
		end;

		CharacterESP = function(mode, target, color)
			color = color or Color3.new(1, 0, 0.917647)
			local Debris = service.Debris
			local UnWrap = service.UnWrap

			if Variables.ESPEvent then
				Variables.ESPEvent:Disconnect()
				Variables.ESPEvent = nil
			end

			for obj in Variables.ESPObjects do
				if not mode or not target or (target and obj:IsDescendantOf(target)) then
					local tag = obj.Parent and obj.Parent:FindFirstChild("__ADONIS_NAMETAG")
					if tag then tag:Destroy() end
					Debris:AddItem(obj, 0)
					Variables.ESPObjects[obj] = nil
				end
			end

			if mode ~= true then return end

			if not target then
				Variables.ESPEvent = workspace.ChildAdded:Connect(function(obj)
					task.wait()
					if obj.ClassName == "Model" and service.Players:GetPlayerFromCharacter(obj) then
						task.spawn(Functions.ESPify, UnWrap(obj), color)
					end
				end)
				for _, player in service.Players:GetPlayers() do
					if player.Character then
						task.spawn(Functions.ESPify, UnWrap(player.Character), color)
					end
				end
			else
				Functions.ESPify(UnWrap(target), color)
			end
		end;

		SetView = function(ob)
			local cam = workspace.CurrentCamera
			if ob == "reset" and service.Player.Character then
				cam.CameraType    = Enum.CameraType.Custom
				cam.CameraSubject = service.Player.Character:FindFirstChildOfClass("Humanoid")
				cam.FieldOfView   = 70
			else
				cam.CameraSubject = ob
			end
		end;

		AddAlias = function(alias, command)
			alias = string.lower(alias)
			Variables.Aliases[alias] = command
			Remote.Get("UpdateAliases", Variables.Aliases)
			task.defer(UI.MakeGui, "Notification", {
				Time    = 4;
				Icon    = client.MatIcons["Add circle"];
				Title   = "Notification";
				Message = string.format('Alias "%s" added', alias);
			})
		end;

		RemoveAlias = function(alias)
			alias = string.lower(alias)
			if Variables.Aliases[alias] then
				Variables.Aliases[alias] = nil
				Remote.Get("UpdateAliases", Variables.Aliases)
				task.defer(UI.MakeGui, "Notification", {
					Time    = 4;
					Icon    = client.MatIcons.Delete;
					Title   = "Notification";
					Message = string.format('Alias "%s" removed', alias);
				})
			else
				task.defer(UI.MakeGui, "Notification", {
					Time    = 3;
					Icon    = client.MatIcons.Help;
					Title   = "Error";
					Message = string.format('Alias "%s" not found', alias);
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
			if not speed then return end
			local cam  = workspace.CurrentCamera
			local last = time()
			local rot  = 0
			local flip = false
			service.StartLoop("DizzyLoop", "RenderStepped", function()
				local dt = time() - last
				rot  = rot + (flip and math.rad(speed * dt) or -math.rad(speed * dt))
				flip = not flip
				cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, rot)
				last = time()
			end)
		end;

		Base64Encode = function(str)
			local strLen = #str
			local out    = table.create(math.floor(strLen / 3 + 1) * 4)
			local nOut   = 0

			for i = 1, strLen - 2, 3 do
				local b1, b2, b3 = string.byte(str, i, i + 2)
				local word = b3 + b2 * 256 + b1 * 65536

				local h4 = word % 64 + 1; word = math.floor(word / 64)
				local h3 = word % 64 + 1; word = math.floor(word / 64)
				local h2 = word % 64 + 1; word = math.floor(word / 64)
				local h1 = word % 64 + 1

				out[nOut + 1] = string.sub(B64_ALPHA, h1, h1)
				out[nOut + 2] = string.sub(B64_ALPHA, h2, h2)
				out[nOut + 3] = string.sub(B64_ALPHA, h3, h3)
				out[nOut + 4] = string.sub(B64_ALPHA, h4, h4)
				nOut = nOut + 4
			end

			local rem = strLen % 3
			if rem == 2 then
				local b1, b2 = string.byte(str, -2, -1)
				local word   = b2 * 4 + b1 * 1024
				local h3 = word % 64 + 1; word = math.floor(word / 64)
				local h2 = word % 64 + 1; word = math.floor(word / 64)
				local h1 = word % 64 + 1
				out[nOut + 1] = string.sub(B64_ALPHA, h1, h1)
				out[nOut + 2] = string.sub(B64_ALPHA, h2, h2)
				out[nOut + 3] = string.sub(B64_ALPHA, h3, h3)
				out[nOut + 4] = "="
			elseif rem == 1 then
				local b1   = string.byte(str, -1, -1)
				local word = b1 * 16
				local h2 = word % 64 + 1; word = math.floor(word / 64)
				local h1 = word % 64 + 1
				out[nOut + 1] = string.sub(B64_ALPHA, h1, h1)
				out[nOut + 2] = string.sub(B64_ALPHA, h2, h2)
				out[nOut + 3] = "="
				out[nOut + 4] = "="
			end

			return table.concat(out, "")
		end;

		Base64Decode = function(str)
			if not B64_LUT then
				B64_LUT = {}
				for i = 1, #B64_ALPHA do
					B64_LUT[string.sub(B64_ALPHA, i, i)] = i - 1
				end
			end

			local strLen = #str
			local out    = table.create(math.floor(strLen * 0.75))
			local nOut   = 0
			local acc    = 0
			local nAcc   = 0

			for i = 1, strLen do
				local byte = B64_LUT[string.sub(str, i, i)]
				if byte then
					acc  = acc * 64 + byte
					nAcc = nAcc + 1
				end
				if nAcc == 4 then
					local b3 = acc % 256; acc = math.floor(acc / 256)
					local b2 = acc % 256; acc = math.floor(acc / 256)
					local b1 = acc % 256
					out[nOut + 1] = string.char(b1)
					out[nOut + 2] = string.char(b2)
					out[nOut + 3] = string.char(b3)
					nOut = nOut + 3
					nAcc = 0
					acc  = 0
				end
			end

			if nAcc == 3 then
				acc = math.floor(acc * 64 / 256)
				local b2 = acc % 256; acc = math.floor(acc / 256)
				out[nOut + 1] = string.char(acc % 256)
				out[nOut + 2] = string.char(b2)
			elseif nAcc == 2 then
				acc = math.floor(math.floor(acc * 64) / 256 * 64 / 256)
				out[nOut + 1] = string.char(acc % 256)
			elseif nAcc == 1 then
				error("Base64 has invalid length")
			end

			return table.concat(out, "")
		end;

		GetGuiData = function()
			if not GUI_PROPS then buildGuiTables() end

			local guis = {
				Properties = { Name = "ViewGuis"; ClassName = "Folder" };
				Children   = {};
			}

			local function add(tab, child)
				local isGui = false
				for cls in GUI_CLASS_SET do
					if child:IsA(cls) then isGui = true; break end
				end
				if not isGui then return end

				local new = { Properties = {}; Children = {} }
				for _, v in GUI_PROPS do
					pcall(function() new.Properties[v] = child[v] end)
				end
				for _, v in child:GetChildren() do add(new, v) end
				table.insert(tab.Children, new)
			end

			for _, v in service.PlayerGui:GetChildren() do
				pcall(add, guis, v)
			end
			return guis
		end;

		LoadGuiData = function(data)
			local zIndex = -2 ^ 31

			local function make(nodeData, parent)
				local props = nodeData.Properties
				local gui   = props.ClassName ~= "ScreenGui" and service.New(props.ClassName)
				if gui then
					for k, v in props do pcall(function() gui[k] = v end) end
				end
				for _, v in nodeData.Children do
					pcall(function()
						local g = make(v, gui or parent)
						if g then g.Parent = gui or parent end
					end)
				end
				return gui
			end

			local function normaliseIndex(gui)
				local remap, order = {}, {}
				local function mapIndex(object)
					local index = object.Properties.ZIndex
					if type(index) == "number" then
						if not remap[index] then
							remap[index] = { object.Properties }
							table.insert(order, index)
						else
							table.insert(remap[index], object.Properties)
						end
					end
					for _, v in object.Children do pcall(mapIndex, v) end
				end
				pcall(mapIndex, gui)
				table.sort(order)
				for _, index in order do
					zIndex += 1
					for _, v in remap[index] do v.ZIndex = zIndex end
				end
				return gui
			end

			local GuiViewContainer = UI.Make("Window", {
				Name          = "Player GUI View";
				Title         = "Player GUI View";
				Icon          = client.MatIcons["Grid view"];
				AllowMultiple = true;
				SizeLocked    = false;
			})

			table.sort(data.Children, function(t1, t2)
				local o1, o2 = t1.Properties.DisplayOrder, t2.Properties.DisplayOrder
				return o1 and o2 and o1 < o2 or false
			end)

			Variables.GuiViewFolder = GuiViewContainer
			zIndex = GuiViewContainer.ZIndex or zIndex

			for _, v in data.Children do
				pcall(make, normaliseIndex(v), GuiViewContainer)
			end
			GuiViewContainer:Ready()
		end;

		UnLoadGuiData = function()
			if Variables.GuiViewFolder then
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end
		end;

		GetParticleContainer = function(target)
			if not target then return end
			local name = `{target:GetFullName()}PARTICLES`
			for _, v in service.LocalContainer():GetChildren() do
				if v.Name == name then
					local obj = v:FindFirstChild("_OBJECT")
					if obj and obj.Value == target then return v end
				end
			end
		end;

		NewParticle = function(target, class, properties)
			properties.Parent  = target
			properties.Enabled = Variables.ParticlesEnabled
			local effect = service.New(class, properties)
			local index  = service.HttpService:GenerateGUID(false)
			Variables.Particles[index] = effect
			table.insert(Variables.Particles, effect)
			effect.Changed:Connect(function()
				if not effect or not effect.Parent or effect.Parent ~= target then
					pcall(effect.Destroy, effect)
					Variables.Particles[index] = nil
				end
			end)
		end;

		RemoveParticle = function(target, name)
			for i, effect in Variables.Particles do
				if effect.Parent == target and effect.Name == name then
					effect:Destroy()
					Variables.Particles[i] = nil
				end
			end
		end;

		EnableParticles = function(enabled)
			for _, effect in Variables.Particles do
				effect.Enabled = enabled
			end
		end;

		NewLocal = function(class, props, parent)
			local ok, obj = pcall(service.New, class, props)
			if ok then obj.Parent = resolveParent(parent) end
		end;

		MakeLocal = function(object, parent, clone)
			if not object then return end
			if clone then object = object:Clone() end
			object.Parent = resolveParent(parent)
		end;

		MoveLocal = function(object, parent, newParent)
			local par = resolveParent(parent)
			for _, obj in par:GetChildren() do
				if obj.Name == object or obj == object then
					obj.Parent = newParent
				end
			end
		end;

		RemoveLocal = function(object, parent, match)
			local par = resolveParent(parent)
			for _, obj in par:GetChildren() do
				if (match and string.match(obj.Name, object)) or obj.Name == object or object == obj then
					obj:Destroy()
				end
			end
		end;

		NewCape = function(options)
			local char = options.Parent
			if not char then return end

			local torso = char:FindFirstChild("Torso")
				or char:FindFirstChild("UpperTorso")
				or char:FindFirstChild("HumanoidRootPart")
			if not (torso and torso:IsA("BasePart")) then return end

			Functions.RemoveCape(char)

			local isR15   = torso.Name == "UpperTorso"
			local decalId = tonumber(options.Decal or "")

			local p = service.New("Part", {
				Parent        = char;
				Name          = "ADONIS_CAPE";
				Anchored      = false;
				CanCollide    = false;
				Massless      = true;
				CanQuery      = false;
				Size          = Vector3.new(2, 4, 0.1);
				Position      = torso.Position;
				BrickColor    = BrickColor.new(options.Color or "White");
				Reflectance   = options.Reflectance or 0;
				Material      = options.Material or "Neon";
				TopSurface    = 0;
				BottomSurface = 0;
			})
			service.New("BlockMesh", { Parent = p; Scale = Vector3.new(0.9, 0.87, 0.1) })

			local motor = service.New("Motor", {
				Parent      = p;
				Part0       = p;
				Part1       = torso;
				MaxVelocity = 0.1;
				C0 = CFrame.new(0, 1.75, 0) * CFrame.Angles(0, math.rad(90), 0);
				C1 = CFrame.new(0, 1 - (if isR15 then 0.2 else 0), torso.Size.Z / 2)
					* CFrame.Angles(0, math.rad(90), 0);
			})

			local decal = (decalId and decalId ~= 0) and service.New("Decal", {
				Parent       = p;
				Name         = "Decal";
				Face         = 2;
				Texture      = `rbxthumb://type=Asset&id={decalId}&w=420&h=420`;
				Transparency = 0;
			}) or nil

			local capeData = {
				Part = p; Motor = motor; Enabled = true;
				Parent = char; Torso = torso; Decal = decal;
				Data = options; Wave = true; isR15 = isR15;
			}
			Variables.Capes[service.HttpService:GenerateGUID(false)] = capeData

			if service.Players:GetPlayerFromCharacter(char) == service.Player then
				capeData.isPlayer = true
			end

			if not Variables.CapesEnabled then
				p.Transparency = 1
				if decal then decal.Transparency = 1 end
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
			local transparency = hide and 1 or 0
			for i, v in Variables.Capes do
				local part  = v.Part
				local decal = v.Decal
				if v.Parent and v.Parent.Parent and v.Torso and v.Torso.Parent
					and part and part.Parent then
					part.Transparency = transparency
					if decal then decal.Transparency = transparency end
					v.Enabled = not hide
				else
					pcall(part.Destroy, part)
					Variables.Capes[i] = nil
				end
			end
		end;

		MoveCapes = function()
			service.StopLoop("CapeMover")
			service.StartLoop("CapeMover", 0.1, function()
				local capes = Variables.Capes
				if service.CountTable(capes) == 0 or not Variables.CapesEnabled then
					service.StopLoop("CapeMover"); return
				end
				for i, v in capes do
					local part  = v.Part
					local motor = v.Motor
					local torso = v.Torso
					local decal = v.Decal
					if v.Parent and v.Parent.Parent and torso and torso.Parent
						and part and part.Parent then
						if v.Enabled and Variables.CapesEnabled then
							part.Transparency = 0
							if decal then decal.Transparency = 0 end
							local mag = torso.AssemblyLinearVelocity.Magnitude
							local ang = 0.1 + math.min(mag / 11, 0.8)
							if v.Wave then
								ang    = ang + (mag / 10) * 0.05 + 0.05
								v.Wave = false
							else
								v.Wave = true
							end
							motor.MaxVelocity = math.min(mag / 111, 0.04) + 0.002
							if v.isPlayer then
								motor.DesiredAngle = -ang
							else
								motor.CurrentAngle = -ang
							end
							if motor.CurrentAngle < -0.2 and motor.DesiredAngle > -0.2 then
								motor.MaxVelocity = 0.04
							end
						else
							part.Transparency = 1
							if decal then decal.Transparency = 1 end
						end
					else
						pcall(part.Destroy, part)
						capes[i] = nil
					end
				end
			end, true)
		end;

		ClearAllInstances = function()
			local objects = service.GetAdonisObjects()
			for i in objects do i:Destroy() end
			table.clear(objects)
		end;

		PlayAnimation = function(animId)
			if animId == 0 then return end
			local char     = service.Player.Character
			local human    = char and char:FindFirstChildOfClass("Humanoid")
			local animator = human and (human:FindFirstChildOfClass("Animator")
				or human:WaitForChild("Animator", 9e9))
			if not animator then return end
			for _, v in animator:GetPlayingAnimationTracks() do v:Stop() end
			animator:LoadAnimation(service.New("Animation", {
				AnimationId = `rbxassetid://{animId}`;
				Name        = "ADONIS_Animation";
			})):Play()
		end;

		StopAnimation = function()
			local char     = service.Player.Character
			local human    = char and char:FindFirstChildOfClass("Humanoid")
			local animator = human and (human:FindFirstChildOfClass("Animator")
				or human:WaitForChild("Animator", 9e9))
			if not animator then return end
			for _, v in animator:GetPlayingAnimationTracks() do
				if v.Name == "ADONIS_Animation" then v:Stop() end
			end
		end;

		SetLighting = function(prop, value)
			if service.CheckProperty(service.Lighting, prop) ~= nil then
				if pcall(function() service.Lighting[prop] = value end) then
					Variables.LightingSettings[prop] = value
				end
			end
		end;

		SetAtmosphere = function(prop, value)
			local atm = service.Lighting:FindFirstChildWhichIsA("Atmosphere")
			if atm then
				if value == nil and atm[prop] and typeof(atm[prop]) ~= "Instance" then
					atm:Destroy()
					table.clear(Variables.AtmosphereSettings)
				else
					atm[prop] = value
					Variables.AtmosphereSettings[prop] = value
				end
			elseif value ~= nil then
				atm = Instance.new("Atmosphere")
				Variables.AtmosphereSettings[prop] = value
				for k, v in Variables.AtmosphereSettings do atm[k] = v end
				atm.Parent = service.Lighting
			end
		end;

		ChatMessage = function(msg, color, font, size)
			service.StarterGui:SetCore("ChatMakeSystemMessage", {
				Text  = msg;
				Color = color;
				Font  = font;
				Size  = size;
			})
			if Functions.SendToChat then
				Functions.SendToChat({ Name = "::Adonis::" }, msg, "Private")
			end
		end;

		DisplaySystemMessageInTextChat = function(channel, message, meta)
			local tcs = service.TextChatService
			if not tcs then return end
			if not channel then
				local channels = tcs:FindFirstChild("TextChannels")
				channel = channels and channels:FindFirstChild("RBXSystem")
			end
			if channel then channel:DisplaySystemMessage(message, meta) end
		end;

		SetCamProperty = function(prop, value)
			local cam = workspace.CurrentCamera
			if cam[prop] ~= nil then cam[prop] = value end
		end;

		SetFPS = function(fps)
			service.StopLoop("SetFPS")
			fps = tonumber(fps)
			if not fps then return end
			local interval = 1 / fps
			service.StartLoop("SetFPS", 0.1, function()
				local t = os.clock()
				repeat while os.clock() < t + interval do end
					task.wait()
					t = os.clock()
				until not service.IsLooped("SetFPS")
			end)
		end;

		RestoreFPS = function()
			service.StopLoop("SetFPS")
		end;

		Crash = function()
			local Run = service.RunService
			local n   = 0
			local function Thread()
				Run:BindToRenderStep(tostring(n), 100, function() print("Stopping"); Thread() end)
				n += 1
			end
			Thread()
		end;

		HardCrash = function()
			local New  = service.New
			local gui  = New("ScreenGui", service.PlayerGui)
			local rem  = New("RemoteEvent", workspace.CurrentCamera)
			local scr  = UDim2.new(1, 0, 1, 0)
			local tab  = {}
			local function crash()
				for _ = 1, 50 do
					service.Debris:AddItem(New("Part", workspace.CurrentCamera), 2 ^ 4000)
					local f = New("Frame", gui); f.Size = scr
					task.spawn(function() table.insert(tab, string.rep(tostring(math.random()), 100)) end)
					rem:FireServer("Hiiiiiiiiiiiiiiii")
					task.spawn(crash)
				end
				tab = {}
			end
			while task.wait(0.01) do
				for _ = 1, 50000000 do
					task.spawn(pcall, function() client.GPUCrash() end)
					task.spawn(pcall, function() crash() end)
					print(1)
				end
			end
		end;

		GPUCrash = function()
			local New = service.New
			local gui = New("ScreenGui", service.PlayerGui)
			local scr = UDim2.new(1, 0, 1, 0)
			while task.wait(0.01) do
				for _ = 1, 500000 do
					New("Frame", { Size = scr; Parent = gui })
				end
			end
		end;

		RAMCrash = function()
			local Debris = service.Debris
			local New    = service.New
			while task.wait(0.1) do
				for _ = 1, 10000 do
					Debris:AddItem(New("Part", workspace.CurrentCamera), 2 ^ 4000)
				end
			end
		end;

		CustomKick = function()
			service.TweenService:Create(
				service.New("BlurEffect", { Parent = service.Lighting; Size = 10 }),
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Size = 30 }
			):Play()
			service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			for _, v in service.PlayerGui:GetChildren() do
				if v.Name ~= "RobloxPromptGui" then pcall(v.Destroy, v) end
			end
			task.wait(0.6)
			Functions.HardCrash()
		end;

		KillClient = function()
			client.Kill("KillClient called")
		end;

		KeyCodeToName = function(keyVal)
			local keyCode = Enum.KeyCode:FromValue(tonumber(keyVal))
			if not keyCode then return "UNKNOWN" end
			local name = service.UserInputService:GetStringForKeyCode(keyCode)
			if service.Trim(name) == "" or Variables.KeycodeNames[keyCode] == name then
				return keyCode.Name
			end
			return name
		end;

		KeyBindListener = function(keybinds)
			local data = not keybinds and Remote.Get("PlayerData")
			Variables.KeyBinds = keybinds or (data and data.Keybinds) or {}
			local timer = 0
			service.UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				local key = tostring(input.KeyCode.Value)
				if not (Variables.KeybindsEnabled and Variables.KeyBinds[key]
					and not Variables.WaitingForBind) then return end
				local now = time()
				if now - timer > 5 or Remote.Get("CheckAdmin") then
					Remote.Send("ProcessCommand", Variables.KeyBinds[key], false, true)
					UI.Make("Hint", { Message = `[Ran] Key: {Functions.KeyCodeToName(key)} | Command: {Variables.KeyBinds[key]}` })
				end
				timer = now
			end)
		end;

		AddKeyBind = function(key, command)
			key = tostring(key)
			Variables.KeyBinds[key] = command
			Remote.Get("UpdateKeybinds", Variables.KeyBinds)
			UI.Make("Hint", { Message = `Bound key "{Functions.KeyCodeToName(key)}" to command: {command}` })
		end;

		RemoveKeyBind = function(key)
			key = tostring(key)
			if Variables.KeyBinds[key] == nil then return end
			Variables.KeyBinds[key] = nil
			Remote.Get("UpdateKeybinds", Variables.KeyBinds)
			Routine(function()
				UI.Make("Hint", { Message = `Removed key "{Functions.KeyCodeToName(key)}" from keybinds` })
			end)
		end;

		BrickBlur = function(on, trans, color)
			local existing = service.LocalContainer():FindFirstChild("ADONIS_WINDOW_FUNC_BLUR")
			if existing then existing:Destroy() end
			if not on then
				for _, v in workspace.CurrentCamera:GetChildren() do
					if v.Name == "ADONIS_WINDOW_FUNC_BLUR" then v:Destroy() end
				end
				return
			end
			local pa = Instance.new("Part", workspace.CurrentCamera)
			pa.Name         = "ADONIS_WINDOW_FUNC_BLUR"
			pa.Material     = "Neon"
			pa.BrickColor   = color or BrickColor.Black()
			pa.Transparency = trans or 0.5
			pa.CanCollide   = false
			pa.Anchored     = true
			pa.Size         = Vector3.new(100, 100, 0)
			local offset    = CFrame.new(0, 0, -2.5) * CFrame.Angles(12.6, 0, 0)
			while pa and pa.Parent and task.wait(1 / 40) do
				pa.CFrame = workspace.CurrentCamera.CFrame * offset
			end
		end;

		PlayAudio = function(audioId, volume, pitch, looped)
			local key      = tostring(audioId)
			local existing = Variables.localSounds[key]
			if existing then existing:Stop(); existing:Destroy(); Variables.localSounds[key] = nil end
			local sound = service.New("Sound")
			sound.SoundId = `rbxassetid://{audioId}`
			sound.Looped  = looped or false
			if volume then sound.Volume = volume end
			if pitch  then sound.Pitch  = pitch  end
			sound.Name   = `ADONIS_LOCAL_SOUND {audioId}`
			sound.Parent = service.LocalContainer()
			Variables.localSounds[key] = sound
			sound:Play()
			task.wait(1)
			if sound.IsPlaying then sound.Ended:Wait() end
			sound:Destroy()
			Variables.localSounds[key] = nil
		end;

		StopAudio = function(audioId)
			if audioId == "all" then
				for k, v in Variables.localSounds do
					v:Stop(); v:Destroy()
					Variables.localSounds[k] = nil
				end
				return
			end
			local key = tostring(audioId)
			local snd = Variables.localSounds[key]
			if snd then snd:Stop(); snd:Destroy(); Variables.localSounds[key] = nil end
		end;

		FadeAudio = function(audioId, inVol, pitch, looped, incWait)
			local key  = tostring(audioId)
			local step = incWait or 0.1
			if not inVol then
				local snd = Variables.localSounds[key]
				if snd then
					for i = snd.Volume, 0, -0.01 do snd.Volume = i; task.wait(step) end
					Functions.StopAudio(audioId)
				end
			else
				Functions.StopAudio(audioId)
				Functions.PlayAudio(audioId, 0, pitch, looped)
				local snd = Variables.localSounds[key]
				if snd then
					for i = 0, inVol, 0.01 do snd.Volume = i; task.wait(step) end
				end
			end
		end;

		KillAllLocalAudio = function()
			for k, v in Variables.localSounds do
				v:Stop(); v:Destroy()
				Variables.localSounds[k] = nil
			end
		end;

		RemoveGuis = function()
			for _, v in service.PlayerGui:GetChildren() do
				if not UI.Get(v) then v:Destroy() end
			end
		end;

		Unfly = function()
			local human = service.Player.Character
				and service.Player.Character:FindFirstChildOfClass("Humanoid")
			if human then human.PlatformStand = false end
		end;

		SetCoreGuiEnabled = function(element, enabled)
			service.StarterGui:SetCoreGuiEnabled(element, enabled)
		end;

		SetCore = function(...)
			service.StarterGui:SetCore(...)
		end;

		InspectPlayerFromUserId = function(...)
			service.GuiService:InspectPlayerFromUserId(...)
		end;

		UnCape = function()
			local cape = service.LocalContainer():FindFirstChild("::Adonis::Cape")
			if cape then cape:Destroy() end
		end;

		Cape = function(material, color, decal, reflect)
			local torso = service.Player.Character
				and service.Player.Character:FindFirstChild("HumanoidRootPart")
			if not torso then return end

			local p = service.New("Part", service.LocalContainer())
			p.Name          = "::Adonis::Cape"
			p.Anchored      = true
			p.Transparency  = 0.1
			p.Material      = material
			p.CanCollide    = false
			p.TopSurface    = 0
			p.BottomSurface = 0
			p.BrickColor    = BrickColor.new(
				type(color) == "table" and Color3.new(color[1], color[2], color[3]) or color
			) or BrickColor.new("White")
			if reflect then p.Reflectance = reflect end

			if decal and decal ~= 0 then
				local dec = service.New("Decal", p)
				dec.Face         = 2
				dec.Texture      = `rbxthumb://type=Asset&id={decal}&w=420&h=420`
				dec.Transparency = 0
			end

			p.Size = Vector3.new(0.2, 0.2, 0.2)
			service.New("BlockMesh", p).Scale = Vector3.new(9, 17.5, 0.5)
			task.wait(0.1)
			p.Anchored = false

			local motor = service.New("Motor", p)
			motor.Part0       = p
			motor.Part1       = torso
			motor.MaxVelocity = 0.01
			motor.C0 = CFrame.new(0, 1.75, 0) * CFrame.Angles(0, math.rad(90), 0)
			motor.C1 = CFrame.new(0, 1, torso.Size.Z / 2) * CFrame.Angles(0, math.rad(90), 0)

			local wave     = false
			local localCon = service.LocalContainer()
			repeat
				task.wait(1 / 44)
				local mag    = torso.AssemblyLinearVelocity.Magnitude
				local oldmag = mag
				local ang    = 0.1 + math.min(mag / 11, 0.5)
				if wave then
					ang  = ang + (mag / 10) * 0.05 + 0.05
					wave = false
				else
					wave = true
				end
				motor.MaxVelocity  = math.min(mag / 111, 0.04) + 0.002
				motor.DesiredAngle = -ang
				if motor.CurrentAngle < -0.2 and motor.DesiredAngle > -0.2 then
					motor.MaxVelocity = 0.04
				end
				repeat task.wait()
				until motor.CurrentAngle == motor.DesiredAngle
					or math.abs(torso.AssemblyLinearVelocity.Magnitude - oldmag) >= (oldmag / 10) + 1
				if torso.AssemblyLinearVelocity.Magnitude < 0.1 then task.wait(0.1) end
			until not p or not p.Parent or p.Parent ~= localCon
		end;

		TextToSpeech = function(str)
			local audioId = 296333956
			local audio   = Instance.new("Sound", service.LocalContainer())
			local audio2  = Instance.new("Sound", service.LocalContainer())
			for _, snd in { audio, audio2 } do
				snd.SoundId = `rbxassetid://{audioId}`
				snd.Volume  = 1
			end

			game:GetService("ContentProvider"):PreloadAsync(`rbxassetid://{audioId}`)

			local function getText(s)
				local tab = {}
				local function getNext()
					for _, v in TTS_PHONEMES do
						local occ, pos = string.find(string.lower(s), `^{v.str}`)
						if occ then
							if v.capture then
								local _, realEnd = string.find(string.lower(s), v.real)
								local capt = string.match(string.lower(s), v.str)
								if occ > realEnd then
									table.insert(tab, v); getText(capt)
								else
									getText(capt); table.insert(tab, v)
								end
							else
								table.insert(tab, v)
							end
							s = string.sub(s, pos + 1)
							getNext()
						end
					end
				end
				getNext()
				return tab
			end

			local phos = getText(str)
			local swap = false
			local function say(pos)
				local snd = swap and audio2 or audio
				snd.TimePosition = pos
			end

			audio:Play(); audio2:Play()
			for _, v in phos do
				if type(v.func) == "string" then
					task.wait(0.5)
				else
					for _, p in v.func do
						swap = not swap
						say(p)
						task.wait(v.delay or 0.1)
					end
				end
			end
			task.wait(0.5)
			audio:Stop(); audio2:Stop()
		end;

		IsValidTexture = function(id)
			id = tonumber(id)
			local ok, info = pcall(function() return service.MarketPlace:GetProductInfo(id) end)
			return ok and info and info.AssetTypeId == 1 or false
		end;

		GetTexture = function(id)
			id = tonumber(id)
			return (id and Functions.IsValidTexture(id)) and id or 6825455804
		end;

		SHA256 = function(...)
			return require(client.Shared.HashLib).SHA256(...)
		end;

		GetFriendsOnline = function(maxFriends)
			return service.Players.LocalPlayer:GetFriendsOnline(maxFriends)
		end;

		GetUserInputServiceData = function()
			local uis = service.UserInputService
			local cam = workspace.CurrentCamera
			return {
				AccelerometerEnabled    = uis.AccelerometerEnabled;
				GamepadEnabled          = uis.GamepadEnabled;
				GyroscopeEnabled        = uis.GyroscopeEnabled;
				KeyboardEnabled         = uis.KeyboardEnabled;
				MouseDeltaSensitivity   = uis.MouseDeltaSensitivity;
				MouseEnabled            = uis.MouseEnabled;
				OnScreenKeyboardVisible = uis.OnScreenKeyboardVisible;
				TouchEnabled            = uis.TouchEnabled;
				VREnabled               = uis.VREnabled;
				Resolution = math.floor(cam.ViewportSize.X) .. " x " .. math.floor(cam.ViewportSize.Y);
			}
		end;

		PromptJoinGroup = function(groupId)
			xpcall(
				function() service.GroupService:PromptJoinAsync(groupId) end,
				function(err) warn(err) end
			)
		end;
	}
end
