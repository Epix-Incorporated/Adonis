--[[
	New Dex
	Final Version
	Developed by Moon
	
	Dex is a debugging suite designed to help the user debug games and find any potential vulnerabilities.
	
	This is the final version of this script.
	You are encouraged to edit, fork, do whatever with this. I pretty much won't be updating it anymore.
	Though I would appreciate it if you kept the credits in the script if you enjoy this hard work.
	
	If you want more info, you can join the server: https://discord.io/zinnia
	Note that very limited to no support will be provided.
]]

-- Main vars
local Main, Explorer, Properties, ScriptViewer, Console, ModelViewer, DefaultSettings, Notebook, Serializer, Lib
local API, RMD
local SettingsEditor
local AboutMenu

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction
-- Default Settings
DefaultSettings = (function()
	local rgb = Color3.fromRGB
	return {
		--[[Main = {
			ResetOnSpawn = true,
		},]]

		Explorer = {
			_Recurse = true,
			Sorting = true,
			TeleportToOffset = Vector3.new(0, 0, 0),
			ClickToSelect = false, -- Click part to select
			ClickToRename = true,
			AutoUpdateSearch = true,
			AutoUpdateMode = 0, -- 0 Default, 1 no tree update, 2 no descendant events, 3 frozen
			PartSelectionBox = true,
			GuiSelectionBox = true,
			CopyPathUseGetChildren = true,
		},
		Properties = {
			_Recurse = true,
			MaxConflictCheck = 50,
			ShowDeprecated = false,
			ShowHidden = false,
			ClearOnFocus = false,
			LoadstringInput = true,
			NumberRounding = 3,
			ShowAttributes = false,
			MaxAttributes = 50,
			ShowTags = true,
			ScaleType = 1, -- 0 Full Name Shown, 1 Equal Halves
		},
		Theme = {
			_Recurse = true,
			Main1 = rgb(52, 52, 52),
			Main2 = rgb(45, 45, 45),
			Outline1 = rgb(33, 33, 33), -- Mainly frames
			Outline2 = rgb(55, 55, 55), -- Mainly button
			Outline3 = rgb(30, 30, 30), -- Mainly textbox
			TextBox = rgb(38, 38, 38),
			Menu = rgb(32, 32, 32),
			ListSelection = rgb(11, 90, 175),
			Button = rgb(60, 60, 60),
			ButtonHover = rgb(68, 68, 68),
			ButtonPress = rgb(40, 40, 40),
			Highlight = rgb(75, 75, 75),
			Text = rgb(255, 255, 255),
			PlaceholderText = rgb(100, 100, 100),
			Important = rgb(255, 0, 0),
			ExplorerIconMap = "",
			MiscIconMap = "",
			Syntax = {
				Text = rgb(204, 204, 204),
				Background = rgb(36, 36, 36),
				Selection = rgb(255, 255, 255),
				SelectionBack = rgb(11, 90, 175),
				Operator = rgb(204, 204, 204),
				Number = rgb(255, 198, 0),
				String = rgb(173, 241, 149),
				Comment = rgb(102, 102, 102),
				Keyword = rgb(248, 109, 124),
				Error = rgb(255, 0, 0),
				FindBackground = rgb(141, 118, 0),
				MatchingWord = rgb(85, 85, 85),
				BuiltIn = rgb(132, 214, 247),
				CurrentLine = rgb(45, 50, 65),
				LocalMethod = rgb(253, 251, 172),
				LocalProperty = rgb(97, 161, 241),
				Nil = rgb(255, 198, 0),
				Bool = rgb(255, 198, 0),
				Function = rgb(248, 109, 124),
				Local = rgb(248, 109, 124),
				Self = rgb(248, 109, 124),
				FunctionName = rgb(253, 251, 172),
				Bracket = rgb(204, 204, 204),
			},
		},
		Window = {
			TitleOnMiddle = false,
			Transparency = 0.2,
		},
	}
end)()

-- Vars
local Settings: any = {}
local Apps = {}
local env = {}
local service = setmetatable({}, {
	__index = function(self, name)
		local serv = game:GetService(name)
		self[name] = serv
		return serv
	end,
})
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:wait()

local create = function(data: { [number]: any }): Instance
	-- now Luau knows insts can be indexed by numbers
	local insts = {}

	for _, v in ipairs(data) do
		insts[v[1]] = Instance.new(v[2])
	end

	for _, v in ipairs(data) do
		for prop, val in pairs(v[3]) do
			if typeof(val) == "table" then
				-- val[1] is a number → insts[val[1]] is an Instance
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1] -- guaranteed to be the root
end

local createSimple = function(class, props)
	local inst = Instance.new(class)
	for i, v in next, props do
		inst[i] = v
	end
	return inst
end

Main = (function()
	local Main = {}

	Main.ModuleList = { "Explorer", "Properties", "Console", "ModelViewer" } --Main.ModuleList = {"Explorer","Properties","ScriptViewer"}
	Main.Elevated = false
	Main.MissingEnv = {}
	Main.Version = "Beta 1.0.6 Adonis"
	Main.Mouse = plr:GetMouse()
	Main.AppControls = {}
	Main.Apps = Apps
	Main.MenuApps = {}
	Main.GitRepoName = "LorekeeperZinnia/Dex"

	-- silencer
	Main.MainGui = nil
	Main.AppsFrame = nil
	Main.AppsContainer = nil
	Main.AppsContainerGrid = nil
	Main.AppTemplate = nil
	Main.SettingsGuiButton = nil
	Main.InformationGuiButton = nil
	Main.MainGuiOpen = false
	Main.LargeIcons = nil
	Main.DepsVersionData = nil
	Main.ClientVersion = nil
	Main.MainGuiMouseEvent = nil

	Main.DisplayOrders = {
		SideWindow = 8,
		Window = 10,
		Menu = 100000,
		Core = 101000,
	}

	-- Dex_Client for Adonis
	Main.LocalScript_Gui = script.Parent

	Main.GetInitDeps = function()
		return {
			Main = Main,
			Lib = Lib,
			Apps = Apps,
			Settings = Settings,

			API = API,
			RMD = RMD,
			env = env,
			service = service,
			plr = plr,
			create = create,
			createSimple = createSimple,
		}
	end

	Main.Error = function(str: string)
		error(str)
	end

	Main.LoadModule = function(name)
		local module = script:WaitForChild("Modules"):WaitForChild(name, 2)
		if not module then
			Main.Error("Cannot find module " .. name)
		end

		local control = require(module) :: any
		Main.AppControls[name] = control
		control.InitDeps(Main.GetInitDeps())

		local moduleData = control.Main()
		Apps[name] = moduleData
		return moduleData
	end

	Main.LoadModules = function()
		for i, v in pairs(Main.ModuleList) do
			local s, e = pcall(Main.LoadModule, v)
			if not s then
				Main.Error("Failed loading " .. v .. " because " .. e)
			end
		end

		-- Init Major Apps and define them in modules
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		ModelViewer = Apps.ModelViewer
		Notebook = Apps.Notebook
		local appTable = {
			Explorer = Explorer,
			Properties = Properties,
			Console = Console,
			ModelViewer = ModelViewer,
			ScriptViewer = ScriptViewer,
			Notebook = Notebook,
		}

		Main.AppControls.Lib.InitAfterMain(appTable)
		for i, v in pairs(Main.ModuleList) do
			local control = Main.AppControls[v]
			if control then
				control.InitAfterMain(appTable)
			end
		end
	end

	Main.InitEnv = function()
		local done = false
		setmetatable(env, {
			__newindex = function(self, name, func)
				if not done and not func then
					Main.MissingEnv[#Main.MissingEnv + 1] = name
					return
				end
				rawset(self, name, func)
			end,
		})

		-- file
		env.readfile = nil
		env.writefile = nil
		env.appendfile = nil
		env.makefolder = nil
		env.listfiles = nil
		env.loadfile = nil
		env.saveinstance = nil

		-- debug
		env.getupvalues = nil
		env.getconstants = nil
		env.islclosure = nil
		env.checkcaller = nil
		env.getreg = nil
		env.getgc = nil

		-- other
		env.setfflag = nil
		env.decompile = nil
		env.protectgui = nil
		env.gethui = nil
		env.setclipboard = nil
		env.getnilinstances = nil
		env.getloadedmodules = nil

		Main.GuiHolder = Main.Elevated and service.CoreGui or plr:FindFirstChildOfClass("PlayerGui")

		done = true -- luau typing complains if I try to just reset the new index to rawset
	end

	Main.ResetSettings = function()
		local function recur(t, res)
			for set, val in pairs(t) do
				if type(val) == "table" and val._Recurse then
					if type(res[set]) ~= "table" then
						res[set] = {}
					end
					recur(val, res[set])
				else
					res[set] = val
				end
			end
			return res
		end
		recur(DefaultSettings :: any, Settings)
	end

	Main.LoadSettings = function()
		local s, data = pcall(env.readfile or error, "DexSettings.json")
		if s and data and data ~= "" then
			local s, decoded = service.HttpService:JSONDecode(data)
			if s and decoded then
				for i, v in next, decoded do
				end
			else
				-- TODO: Notification
			end
		else
			Main.ResetSettings()
		end
	end

	Main.FetchAPI = function()
		local api, rawAPI
		local didwedoit = Dex_RemoteFunction:InvokeServer("fetchapi")

		if didwedoit and type(didwedoit) == "table" then
			rawAPI = didwedoit
		else
			if script:FindFirstChild("API") then
				rawAPI = require(script.API)
			else
				error("No API exists")
			end
		end

		Main.RawAPI = rawAPI

		local success, result = pcall(service.HttpService.JSONDecode, service.HttpService, rawAPI)
		if not success or type(result) ~= "table" then
			if type(result) ~= "table" then
				error(`Error while decoding Decoded data {result} is not type "table"`)
			else
				error(`Error while decoding {result}`)
			end
		else
			api = result
		end

		local classes, enums = {}, {}
		local categoryOrder, seenCategories = {}, {}

		local function insertAbove(t, item, aboveItem)
			local findPos = table.find(t, item)
			if not findPos then
				return
			end
			table.remove(t, findPos)

			local pos = table.find(t, aboveItem)
			if not pos then
				return
			end
			table.insert(t, pos, item)
		end

		for _, class in pairs(api.Classes) do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then
				for c, tag in pairs(class.Tags) do
					newClass.Tags[tag] = true
				end
			end
			for __, member in pairs(class.Members) do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags = {}
				if member.Tags then
					for c, tag in pairs(member.Tags) do
						newMember.Tags[tag] = true
					end
				end

				local mType = member.MemberType
				if mType == "Property" then
					local propCategory = member.Category or "Other"
					propCategory = propCategory:match("^%s*(.-)%s*$")
					if not seenCategories[propCategory] then
						categoryOrder[#categoryOrder + 1] = propCategory
						seenCategories[propCategory] = true
					end
					newMember.ValueType = member.ValueType
					newMember.Category = propCategory
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties, newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType.Name
					for c, param in pairs(member.Parameters) do
						table.insert(newMember.Parameters, { Name = param.Name, Type = param.Type.Name })
					end
					table.insert(newClass.Functions, newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c, param in pairs(member.Parameters) do
						table.insert(newMember.Parameters, { Name = param.Name, Type = param.Type.Name })
					end
					table.insert(newClass.Events, newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _, class in pairs(classes) do
			class.Superclass = classes[class.Superclass]
		end

		for _, enum in pairs(api.Enums) do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then
				for c, tag in pairs(enum.Tags) do
					newEnum.Tags[tag] = true
				end
			end
			for __, item in pairs(enum.Items) do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items, newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class, member)
			if not classes[class] or not classes[class][member] then
				return
			end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _, entry in pairs(currentClass[member]) do
					result[#result + 1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result, function(a, b)
				return a.Name < b.Name
			end)
			return result
		end

		insertAbove(categoryOrder, "Behavior", "Tuning")
		insertAbove(categoryOrder, "Appearance", "Data")
		insertAbove(categoryOrder, "Attachments", "Axes")
		insertAbove(categoryOrder, "Cylinder", "Slider")
		insertAbove(categoryOrder, "Localization", "Jump Settings")
		insertAbove(categoryOrder, "Surface", "Motion")
		insertAbove(categoryOrder, "Surface Inputs", "Surface")
		insertAbove(categoryOrder, "Part", "Surface Inputs")
		insertAbove(categoryOrder, "Assembly", "Surface Inputs")
		insertAbove(categoryOrder, "Character", "Controls")
		categoryOrder[#categoryOrder + 1] = "Unscriptable"
		categoryOrder[#categoryOrder + 1] = "Attributes"

		local categoryOrderMap = {}
		for i = 1, #categoryOrder do
			categoryOrderMap[categoryOrder[i]] = i
		end

		return {
			Classes = classes,
			Enums = enums,
			CategoryOrder = categoryOrderMap,
			GetMember = getMember,
		}
	end

	Main.FetchRMD = function()
		local rawXML
		local didwedoit = Dex_RemoteFunction:InvokeServer("fetchrmd")

		if didwedoit then
			rawXML = didwedoit
		else
			if script:FindFirstChild("RMD") then
				rawXML = require(script.RMD)
			else
				error("No RMD exists")
			end
		end

		Main.RawRMD = rawXML
		local parsed = Lib.ParseXML(rawXML)
		local classList = parsed.children[1].children[1].children
		local enumList = parsed.children[1].children[2].children
		local propertyOrders = {}

		local classes, enums = {}, {}
		for _, class in pairs(classList) do
			local className = ""
			for _, child in pairs(class.children) do
				if child.tag == "Properties" then
					local data = { Properties = {}, Functions = {} }
					local props = child.children
					for _, prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1, 1):upper() .. name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _, member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1, 1):upper() .. name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								if data.PropertyOrder then
									local orders = propertyOrders[className]
									if not orders then
										orders = {}
										propertyOrders[className] = orders
									end
									orders[data.Name] = tonumber(data.PropertyOrder)
								end
								classes[className].Properties[data.Name] = data
							end
						end
					end
				elseif child.attrs.class == "ReflectionMetadataFunctions" then
					local members = child.children
					for _, member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in pairs(props) do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1, 1):upper() .. name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								classes[className].Functions[data.Name] = data
							end
						end
					end
				end
			end
		end

		for _, enum in pairs(enumList) do
			local enumName = ""
			for _, child in pairs(enum.children) do
				if child.tag == "Properties" then
					local data = { Items = {} }
					local props = child.children
					for _, prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1, 1):upper() .. name:sub(2)
						data[name] = prop.children[1].text
					end
					enumName = data.Name
					enums[enumName] = data
				elseif child.attrs.class == "ReflectionMetadataEnumItem" then
					local data = {}
					if child.children[1].tag == "Properties" then
						local props = child.children[1].children
						for _, prop in pairs(props) do
							local name = prop.attrs.name
							name = name:sub(1, 1):upper() .. name:sub(2)
							data[name] = prop.children[1].text
						end
						enums[enumName].Items[data.Name] = data
					end
				end
			end
		end

		return { Classes = classes, Enums = enums, PropertyOrders = propertyOrders }
	end

	Main.ShowGui = function(gui)
		if env.protectgui then
			env.protectgui(gui)
		end
		gui.Parent = Main.GuiHolder
	end

	Main.CreateIntro = function(initStatus) -- TODO: Must theme and show errors
		local gui = create({
			{ 1, "ScreenGui", { Name = "Dex_Intro", ResetOnSpawn = false } },
			{
				2,
				"Frame",
				{
					Active = true,
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					BorderSizePixel = 0,
					Name = "Main",
					Parent = { 1 },
					Position = UDim2.new(0.5, -175, 0.5, -100),
					Size = UDim2.new(0, 350, 0, 200),
				},
			},
			{
				3,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Name = "Holder",
					Parent = { 2 },
					Size = UDim2.new(1, 0, 1, 0),
				},
			},
			{
				4,
				"UIGradient",
				{
					Parent = { 3 },
					Rotation = 30,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1, 0),
						NumberSequenceKeypoint.new(1, 1, 0),
					}),
				},
			},
			{
				5,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 4,
					Name = "Title",
					Parent = { 3 },
					Position = UDim2.new(0, -190, 0, 15),
					Size = UDim2.new(0, 100, 0, 50),
					Text = "Dex",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 50,
					TextTransparency = 1,
				},
			},
			{
				6,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "Desc",
					Parent = { 3 },
					Position = UDim2.new(0, -230, 0, 60),
					Size = UDim2.new(0, 180, 0, 25),
					Text = "Ultimate Debugging Suite",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 18,
					TextTransparency = 1,
				},
			},
			{
				7,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "StatusText",
					Parent = { 3 },
					Position = UDim2.new(0, 20, 0, 110),
					Size = UDim2.new(0, 180, 0, 25),
					Text = "Fetching API",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 1,
				},
			},
			{
				8,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					BorderSizePixel = 0,
					Name = "ProgressBar",
					Parent = { 3 },
					Position = UDim2.new(0, 110, 0, 145),
					Size = UDim2.new(0, 0, 0, 4),
				},
			},
			{
				9,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.2392156869173, 0.56078433990479, 0.86274510622025),
					BorderSizePixel = 0,
					Name = "Bar",
					Parent = { 8 },
					Size = UDim2.new(0, 0, 1, 0),
				},
			},
			{
				10,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://2764171053",
					ImageColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					Parent = { 8 },
					ScaleType = 1,
					Size = UDim2.new(1, 0, 1, 0),
					SliceCenter = Rect.new(2, 2, 254, 254),
				},
			},
			{
				11,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "Creator",
					Parent = { 2 },
					Position = UDim2.new(1, -110, 1, -20),
					Size = UDim2.new(0, 105, 0, 20),
					Text = "Developed by Moon",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 1,
				},
			},
			{
				12,
				"UIGradient",
				{
					Parent = { 11 },
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1, 0),
						NumberSequenceKeypoint.new(1, 1, 0),
					}),
				},
			},
			{
				13,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "Version",
					Parent = { 2 },
					Position = UDim2.new(1, -110, 1, -35),
					Size = UDim2.new(0, 105, 0, 20),
					Text = "Beta 1.0.0",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 1,
				},
			},
			{
				14,
				"UIGradient",
				{
					Parent = { 13 },
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1, 0),
						NumberSequenceKeypoint.new(1, 1, 0),
					}),
				},
			},
			{
				15,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Image = "rbxassetid://1427967925",
					Name = "Outlines",
					Parent = { 2 },
					Position = UDim2.new(0, -5, 0, -5),
					ScaleType = 1,
					Size = UDim2.new(1, 10, 1, 10),
					SliceCenter = Rect.new(6, 6, 25, 25),
					TileSize = UDim2.new(0, 20, 0, 20),
				},
			},
			{
				16,
				"UIGradient",
				{
					Parent = { 15 },
					Rotation = -30,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1, 0),
						NumberSequenceKeypoint.new(1, 1, 0),
					}),
				},
			},
			{
				17,
				"UIGradient",
				{
					Parent = { 2 },
					Rotation = -30,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1, 0),
						NumberSequenceKeypoint.new(1, 1, 0),
					}),
				},
			},
		})
		Main.ShowGui(gui)
		local backGradient = gui.Main.UIGradient
		local outlinesGradient = gui.Main.Outlines.UIGradient
		local holderGradient = gui.Main.Holder.UIGradient
		local titleText = gui.Main.Holder.Title
		local descText = gui.Main.Holder.Desc
		local versionText = gui.Main.Version
		local versionGradient = versionText.UIGradient
		local creatorText = gui.Main.Creator
		local creatorGradient = creatorText.UIGradient
		local statusText = gui.Main.Holder.StatusText
		local progressBar = gui.Main.Holder.ProgressBar
		local tweenS = service.TweenService

		-- Change versionText
		versionText.Text = Main.Version

		local renderStepped = service.RunService.RenderStepped
		local signalWait = renderStepped.wait
		local fastwait = function(s)
			if not s then
				return signalWait(renderStepped)
			end
			local start = tick()
			while tick() - start < s do
				signalWait(renderStepped)
			end
		end

		statusText.Text = initStatus

		local function tweenNumber(n, ti, func)
			local tweenVal = Instance.new("IntValue")
			tweenVal.Value = 0
			tweenVal.Changed:Connect(func)
			local tween = tweenS:Create(tweenVal, ti, { Value = n })
			tween:Play()
			tween.Completed:Connect(function()
				tweenVal:Destroy()
			end)
		end

		local ti = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		tweenNumber(100, ti, function(val)
			val = val / 200
			local start = NumberSequenceKeypoint.new(0, 0)
			local a1 = NumberSequenceKeypoint.new(val, 0)
			local a2 = NumberSequenceKeypoint.new(math.min(0.5, val + math.min(0.05, val)), 1)
			if a1.Time == a2.Time then
				a2 = a1
			end
			local b1 = NumberSequenceKeypoint.new(1 - val, 0)
			local b2 = NumberSequenceKeypoint.new(math.max(0.5, 1 - val - math.min(0.05, val)), 1)
			if b1.Time == b2.Time then
				b2 = b1
			end
			local goal = NumberSequenceKeypoint.new(1, 0)
			backGradient.Transparency = NumberSequence.new({ start, a1, a2, b2, b1, goal })
			outlinesGradient.Transparency = NumberSequence.new({ start, a1, a2, b2, b1, goal })
		end)

		fastwait(0.4)

		tweenNumber(100, ti, function(val)
			val = val / 166.66
			local start = NumberSequenceKeypoint.new(0, 0)
			local a1 = NumberSequenceKeypoint.new(val, 0)
			local a2 = NumberSequenceKeypoint.new(val + 0.01, 1)
			local goal = NumberSequenceKeypoint.new(1, 1)
			holderGradient.Transparency = NumberSequence.new({ start, a1, a2, goal })
		end)

		tweenS:Create(titleText, ti, { Position = UDim2.new(0, 60, 0, 15), TextTransparency = 0 }):Play()
		tweenS:Create(descText, ti, { Position = UDim2.new(0, 20, 0, 60), TextTransparency = 0 }):Play()

		local function rightTextTransparency(obj)
			tweenNumber(100, ti, function(val)
				val = val / 100
				local a1 = NumberSequenceKeypoint.new(1 - val, 0)
				local a2 = NumberSequenceKeypoint.new(math.max(0, 1 - val - 0.01), 1)
				if a1.Time == a2.Time then
					a2 = a1
				end
				local start = NumberSequenceKeypoint.new(0, a1 == a2 and 0 or 1)
				local goal = NumberSequenceKeypoint.new(1, 0)
				obj.Transparency = NumberSequence.new({ start, a2, a1, goal })
			end)
		end
		rightTextTransparency(versionGradient)
		rightTextTransparency(creatorGradient)

		fastwait(0.9)

		local progressTI = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		tweenS:Create(statusText, progressTI, { Position = UDim2.new(0, 20, 0, 120), TextTransparency = 0 }):Play()
		tweenS
			:Create(progressBar, progressTI, { Position = UDim2.new(0, 60, 0, 145), Size = UDim2.new(0, 100, 0, 4) })
			:Play()

		fastwait(0.25)

		local function setProgress(text, n)
			statusText.Text = text
			tweenS:Create(progressBar.Bar, progressTI, { Size = UDim2.new(n, 0, 1, 0) }):Play()
		end

		local function close()
			tweenS:Create(titleText, progressTI, { TextTransparency = 1 }):Play()
			tweenS:Create(descText, progressTI, { TextTransparency = 1 }):Play()
			tweenS:Create(versionText, progressTI, { TextTransparency = 1 }):Play()
			tweenS:Create(creatorText, progressTI, { TextTransparency = 1 }):Play()
			tweenS:Create(statusText, progressTI, { TextTransparency = 1 }):Play()
			tweenS:Create(progressBar, progressTI, { BackgroundTransparency = 1 }):Play()
			tweenS:Create(progressBar.Bar, progressTI, { BackgroundTransparency = 1 }):Play()
			tweenS:Create(progressBar.ImageLabel, progressTI, { ImageTransparency = 1 }):Play()

			tweenNumber(100, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), function(val)
				val = val / 250
				local start = NumberSequenceKeypoint.new(0, 0)
				local a1 = NumberSequenceKeypoint.new(0.6 + val, 0)
				local a2 = NumberSequenceKeypoint.new(math.min(1, 0.601 + val), 1)
				if a1.Time == a2.Time then
					a2 = a1
				end
				local goal = NumberSequenceKeypoint.new(1, a1 == a2 and 0 or 1)
				holderGradient.Transparency = NumberSequence.new({ start, a1, a2, goal })
			end)

			fastwait(0.5)
			gui.Main.BackgroundTransparency = 1
			outlinesGradient.Rotation = 30

			tweenNumber(100, ti, function(val)
				val = val / 100
				local start = NumberSequenceKeypoint.new(0, 1)
				local a1 = NumberSequenceKeypoint.new(val, 1)
				local a2 = NumberSequenceKeypoint.new(math.min(1, val + math.min(0.05, val)), 0)
				if a1.Time == a2.Time then
					a2 = a1
				end
				local goal = NumberSequenceKeypoint.new(1, a1 == a2 and 1 or 0)
				outlinesGradient.Transparency = NumberSequence.new({ start, a1, a2, goal })
				holderGradient.Transparency = NumberSequence.new({ start, a1, a2, goal })
			end)

			fastwait(0.45)
			gui:Destroy()
		end

		return { SetProgress = setProgress, Close = close }
	end

	Main.CreateApp = function(data)
		if Main.MenuApps[data.Name] then
			return
		end -- TODO: Handle conflict
		local control = {}

		local app = Main.AppTemplate:Clone()

		local iconIndex = data.Icon
		if data.IconMap and iconIndex then
			if type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon, iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon, iconIndex)
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
		else
			app.Main.Icon.Image = ""
		end

		local function updateState()
			app.Main.BackgroundTransparency = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			app.Main.Highlight.Visible = data.Open
		end

		local function enable(silent)
			if data.Open then
				return
			end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then
					data.Window:Show()
				end
				if data.OnClick then
					data.OnClick(data.Open)
				end
			end
		end

		local function disable(silent)
			if not data.Open then
				return
			end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then
					data.Window:Hide()
				end
				if data.OnClick then
					data.OnClick(data.Open)
				end
			end
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name, 14, Enum.Font.SourceSans, Vector2.new(62, 999999)).Y
		app.Main.Size = UDim2.new(1, 0, 0, math.clamp(46 + ySize, 60, 74))
		app.Main.AppName.Text = data.Name

		app.Main.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				app.Main.BackgroundTransparency = 0
				app.Main.BackgroundColor3 = Settings.Theme.ButtonHover
			end
		end)

		app.Main.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				app.Main.BackgroundTransparency = data.Open and 0 or 1
				app.Main.BackgroundColor3 = Settings.Theme.Button
			end
		end)

		app.Main.MouseButton1Click:Connect(function()
			if data.Open then
				disable()
			else
				enable()
			end
		end)

		local window = data.Window
		if window then
			window.OnActivate:Connect(function()
				enable(true)
			end)
			window.OnDeactivate:Connect(function()
				disable(true)
			end)
		end

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0, 0, 0, Main.AppsContainerGrid.AbsoluteCellCount.Y * 82 + 8)

		control.Enable = enable
		control.Disable = disable
		Main.MenuApps[data.Name] = control
		return control
	end

	Main.SetMainGuiOpen = function(val)
		Main.MainGuiOpen = val

		Main.MainGui.OpenButton.Text = val and "X" or "Dex"
		if val then
			Main.MainGui.OpenButton.MainFrame.Visible = true
		end
		Main.MainGui.OpenButton.MainFrame:TweenSize(
			val and UDim2.new(0, 224, 0, 200) or UDim2.new(0, 0, 0, 0),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.2,
			true
		)
		--Main.MainGui.OpenButton.BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2)
		service.TweenService
			:Create(
				Main.MainGui.OpenButton,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(Main.MainGui.OpenButton) and 0 or 0.2) }
			)
			:Play()

		if Main.MainGuiMouseEvent then
			Main.MainGuiMouseEvent:Disconnect()
		end

		if not val then
			local startTime = tick()
			Main.MainGuiCloseTime = startTime
			task.spawn(function()
				Lib.FastWait(0.2)
				if not Main.MainGuiOpen and startTime == Main.MainGuiCloseTime then
					Main.MainGui.OpenButton.MainFrame.Visible = false
				end
			end)
		else
			Main.MainGuiMouseEvent = service.UserInputService.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					and not Lib.CheckMouseInGui(Main.MainGui.OpenButton)
					and not Lib.CheckMouseInGui(Main.MainGui.OpenButton.MainFrame)
				then
					Main.SetMainGuiOpen(false)
				end
			end)
		end
	end

	Main.CreateMainGui = function()
		local gui = create({
			{ 1, "ScreenGui", { IgnoreGuiInset = true, Name = "Dex_MainMenu", ResetOnSpawn = false } },
			{
				2,
				"TextButton",
				{
					AnchorPoint = Vector2.new(0.5, 0),
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BorderSizePixel = 0,
					Font = 4,
					Name = "OpenButton",
					Parent = { 1 },
					Position = UDim2.new(0.5, 0, 0, 2),
					Size = UDim2.new(0, 32, 0, 32),
					Text = "Dex",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 16,
					TextTransparency = 0.20000000298023,
				},
			},
			{ 3, "UICorner", { CornerRadius = UDim.new(0, 4), Parent = { 2 } } },
			{
				4,
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					ClipsDescendants = true,
					Name = "MainFrame",
					Parent = { 2 },
					Position = UDim2.new(0.5, 0, 1, -4),
					Size = UDim2.new(0, 224, 0, 200),
				},
			},
			{ 5, "UICorner", { CornerRadius = UDim.new(0, 4), Parent = { 4 } } },
			{
				6,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					Name = "BottomFrame",
					Parent = { 4 },
					Position = UDim2.new(0, 0, 1, -24),
					Size = UDim2.new(1, 0, 0, 24),
				},
			},
			{ 7, "UICorner", { CornerRadius = UDim.new(0, 4), Parent = { 6 } } },
			{
				8,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					BorderSizePixel = 0,
					Name = "CoverFrame",
					Parent = { 6 },
					Size = UDim2.new(1, 0, 0, 4),
				},
			},
			{
				9,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.1294117718935, 0.1294117718935, 0.1294117718935),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 8 },
					Position = UDim2.new(0, 0, 0, -1),
					Size = UDim2.new(1, 0, 0, 1),
				},
			},
			{
				10,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "Settings",
					Parent = { 6 },
					Position = UDim2.new(1, -48, 0, 0),
					Size = UDim2.new(0, 24, 1, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				11,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://6578871732",
					ImageTransparency = 0.20000000298023,
					Name = "Icon",
					Parent = { 10 },
					Position = UDim2.new(0, 4, 0, 4),
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				12,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "Information",
					Parent = { 6 },
					Position = UDim2.new(1, -24, 0, 0),
					Size = UDim2.new(0, 24, 1, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				13,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://6578933307",
					ImageTransparency = 0.20000000298023,
					Name = "Icon",
					Parent = { 12 },
					Position = UDim2.new(0, 4, 0, 4),
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				14,
				"ScrollingFrame",
				{
					Active = true,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.1294117718935, 0.1294117718935, 0.1294117718935),
					BorderSizePixel = 0,
					Name = "AppsFrame",
					Parent = { 4 },
					Position = UDim2.new(0.5, 0, 0, 0),
					ScrollBarImageColor3 = Color3.new(0, 0, 0),
					ScrollBarThickness = 12,
					Size = UDim2.new(0, 222, 1, -25),
				},
			},
			{
				15,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Name = "Container",
					Parent = { 14 },
					Position = UDim2.new(0, 7, 0, 8),
					Size = UDim2.new(1, -14, 0, 2),
				},
			},
			{ 16, "UIGridLayout", { CellSize = UDim2.new(0, 66, 0, 74), Parent = { 15 }, SortOrder = 2 } },
			{
				17,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Name = "App",
					Parent = { 1 },
					Size = UDim2.new(0, 100, 0, 100),
					Visible = false,
				},
			},
			{
				18,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.2352941185236, 0.2352941185236, 0.2352941185236),
					BorderSizePixel = 0,
					Font = 3,
					Name = "Main",
					Parent = { 17 },
					Size = UDim2.new(1, 0, 0, 60),
					Text = "",
					TextColor3 = Color3.new(0, 0, 0),
					TextSize = 14,
				},
			},
			{
				19,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://6579106223",
					ImageRectSize = Vector2.new(32, 32),
					Name = "Icon",
					Parent = { 18 },
					Position = UDim2.new(0.5, -16, 0, 4),
					ScaleType = 4,
					Size = UDim2.new(0, 32, 0, 32),
				},
			},
			{
				20,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "AppName",
					Parent = { 18 },
					Position = UDim2.new(0, 2, 0, 38),
					Size = UDim2.new(1, -4, 1, -40),
					Text = "Explorer",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 0.10000000149012,
					TextTruncate = 1,
					TextWrapped = true,
					TextYAlignment = 0,
				},
			},
			{
				21,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0, 0.66666668653488, 1),
					BorderSizePixel = 0,
					Name = "Highlight",
					Parent = { 18 },
					Position = UDim2.new(0, 0, 1, -2),
					Size = UDim2.new(1, 0, 0, 2),
				},
			},
		})
		Main.MainGui = gui
		Main.AppsFrame = gui.OpenButton.MainFrame.AppsFrame
		Main.AppsContainer = Main.AppsFrame.Container
		Main.AppsContainerGrid = Main.AppsContainer.UIGridLayout
		Main.AppTemplate = gui.App
		Main.SettingsGuiButton = gui.OpenButton.MainFrame.BottomFrame.Settings -- Settings Button
		Main.InformationGuiButton = gui.OpenButton.MainFrame.BottomFrame.Information -- Information Button
		Main.MainGuiOpen = false

		local openButton = gui.OpenButton
		openButton.BackgroundTransparency = 0.2
		openButton.MainFrame.Size = UDim2.new(0, 0, 0, 0)
		openButton.MainFrame.Visible = false
		openButton.MouseButton1Click:Connect(function()
			Main.SetMainGuiOpen(not Main.MainGuiOpen)
		end)

		openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				service.TweenService
					:Create(
						Main.MainGui.OpenButton,
						TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 0 }
					)
					:Play()
			end
		end)

		openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				service.TweenService
					:Create(
						Main.MainGui.OpenButton,
						TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = Main.MainGuiOpen and 0 or 0.2 }
					)
					:Play()
			end
		end)

		-- Settings Button
		local settingsButton = Main.SettingsGuiButton
		settingsButton.MouseButton1Click:Connect(function()
			SettingsEditor.Window:Show()
		end)

		-- About Menu
		local infoButton = Main.InformationGuiButton
		infoButton.MouseButton1Click:Connect(function()
			AboutMenu.Window:Show()
		end)

		-- Create Main Apps
		Main.CreateApp({
			Name = "Explorer",
			IconMap = Main.LargeIcons,
			Icon = "Explorer",
			Open = true,
			Window = Explorer.Window,
		})

		Main.CreateApp({
			Name = "Properties",
			IconMap = Main.LargeIcons,
			Icon = "Properties",
			Open = true,
			Window = Properties.Window,
		})

		Main.CreateApp({ Name = "Console", IconMap = Main.LargeIcons, Icon = "Output", Window = Console.Window })

		Main.CreateApp({ Name = "Model Viewer", IconMap = Main.LargeIcons, Icon = 6, Window = ModelViewer.Window })
		--Main.CreateApp({Name = "Script Viewer", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window})

		Lib.ShowGui(gui)
	end

	Main.SetupFilesystem = function()
		if not env.writefile or not env.makefolder then
			return
		end

		local writefile, makefolder = env.writefile, env.makefolder

		makefolder("dex")
		makefolder("dex/assets")
		makefolder("dex/saved")
		makefolder("dex/plugins")
		makefolder("dex/ModuleCache")
	end

	Main.LocalDepsUpToDate = function()
		return Main.DepsVersionData and Main.ClientVersion == Main.DepsVersionData[1]
	end

	Main.Init = function()
		Main.Elevated = pcall(function()
			local a = game:GetService("CoreGui"):GetFullName()
		end)
		Main.InitEnv()
		Main.LoadSettings()
		Main.SetupFilesystem()

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		-- Init other stuff
		--Main.IncompatibleTest()

		-- Init icons
		Main.MiscIcons = Lib.IconMap.new("rbxassetid://6511490623", 256, 256, 16, 16)
		Main.MiscIcons:SetDict({
			Reference = 0,
			Cut = 1,
			Cut_Disabled = 2,
			Copy = 3,
			Copy_Disabled = 4,
			Paste = 5,
			Paste_Disabled = 6,
			Delete = 7,
			Delete_Disabled = 8,
			Group = 9,
			Group_Disabled = 10,
			Ungroup = 11,
			Ungroup_Disabled = 12,
			TeleportTo = 13,
			Rename = 14,
			JumpToParent = 15,
			ExploreData = 16,
			Save = 17,
			CallFunction = 18,
			CallRemote = 19,
			Undo = 20,
			Undo_Disabled = 21,
			Redo = 22,
			Redo_Disabled = 23,
			Expand_Over = 24,
			Expand = 25,
			Collapse_Over = 26,
			Collapse = 27,
			SelectChildren = 28,
			SelectChildren_Disabled = 29,
			InsertObject = 30,
			ViewScript = 31,
			AddStar = 32,
			RemoveStar = 33,
			Script_Disabled = 34,
			LocalScript_Disabled = 35,
			Play = 36,
			Pause = 37,
			Rename_Disabled = 38,
		})
		Main.LargeIcons = Lib.IconMap.new("rbxassetid://6579106223", 256, 256, 32, 32)
		Main.LargeIcons:SetDict({
			Explorer = 0,
			Properties = 1,
			Script_Viewer = 2,
		})

		-- Fetch external deps
		intro.SetProgress("Fetching API", 0.35)
		API = Main.FetchAPI()
		Lib.FastWait()
		intro.SetProgress("Fetching RMD", 0.5)
		RMD = Main.FetchRMD()
		Lib.FastWait()

		-- Load other modules
		intro.SetProgress("Loading Modules", 0.75)
		SettingsEditor = Main.LoadModule("SettingsEditor")
		AboutMenu = Main.LoadModule("AboutMenu")

		Main.AppControls.Lib.InitDeps(Main.GetInitDeps()) -- Missing deps now available
		Main.LoadModules()
		Lib.FastWait()

		-- Init other modules
		intro.SetProgress("Initializing Modules", 0.9)
		Explorer.Init()
		Properties.Init()
		Console.Init()
		ModelViewer.Init()
		--ScriptViewer.Init()

		SettingsEditor.Init() -- init this last
		AboutMenu.Init()
		Lib.FastWait()

		-- Done
		intro.SetProgress("Complete", 1)
		task.spawn(function()
			Lib.FastWait(1.25)
			intro.Close()
		end)

		-- Init window system, create main menu, show explorer and properties
		Lib.Window.Init()
		Main.CreateMainGui()
		Explorer.Window:Show({ Align = "right", Pos = 1, Size = 0.5, Silent = true })
		Properties.Window:Show({ Align = "right", Pos = 2, Size = 0.5, Silent = true })
		Lib.DeferFunc(function()
			Lib.Window.ToggleSide("right")
		end)

		-- SettingsEditor GUI
		--SettingsEditor.Window:Show()
	end

	return Main
end)()

-- Start
Main.Init()

--for i,v in pairs(Main.MissingEnv) do print(i,v) end
