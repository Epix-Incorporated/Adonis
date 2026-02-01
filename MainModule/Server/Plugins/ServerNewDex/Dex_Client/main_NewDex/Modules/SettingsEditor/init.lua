--[[
	Settings Module
	
	The Module to configure settings
]]

-- half of the module was written using ai by someone
-- why.

-- ADONIS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local SettingsEditor = {}

	local scrollV, scrollH
	local settingsListFrame
	local expanded, viewList = {}, {}

	local topOffset = 0 --23 for that search bar thingy

	local scrollbarThickness = 6 -- for layout

	SettingsEditor.SettingsInfo = require(script.settingsInfo)
	-- Pass Vargs
	SettingsEditor.SettingsInfo.initDeps({
		Main = Main,
		Lib = Lib,
		Apps = Apps,
		Settings = Settings,
	})

	-- silencer
	SettingsEditor.ColorEditor = nil
	SettingsEditor.InfoDescBox = nil
	SettingsEditor.Window = nil

	SettingsEditor.EntryTemplate = function()
		local Entry = Instance.new("TextButton")
		Entry.Name = "Entry"
		Entry.Size = UDim2.new(1, 0, 0, 22)
		Entry.BorderColor3 = Color3.fromRGB(33, 33, 33)
		Entry.BackgroundTransparency = 0.2
		Entry.Position = UDim2.new(0, 1, 0, 1)
		Entry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		Entry.AutoButtonColor = false
		Entry.FontSize = Enum.FontSize.Size14
		Entry.TextSize = 14
		Entry.Text = ""
		Entry.Font = Enum.Font.SourceSans

		local NameFrame = Instance.new("Frame")
		NameFrame.Name = "NameFrame"
		NameFrame.Size = UDim2.new(1, -40, 1, 0)
		NameFrame.BorderColor3 = Color3.fromRGB(86, 125, 188)
		NameFrame.BackgroundTransparency = 1
		NameFrame.Position = UDim2.new(0, 20, 0, 0)
		NameFrame.BorderSizePixel = 0
		NameFrame.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		NameFrame.Parent = Entry

		local PropName = Instance.new("TextLabel")
		PropName.Name = "PropName"
		PropName.Size = UDim2.new(1, -2, 1, 0)
		PropName.BackgroundTransparency = 1
		PropName.Position = UDim2.new(0, 2, 0, 0)
		PropName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		PropName.FontSize = Enum.FontSize.Size14
		PropName.TextTruncate = Enum.TextTruncate.AtEnd
		PropName.TextSize = 14
		PropName.TextColor3 = Color3.fromRGB(255, 255, 255)
		PropName.Text = "Anchored"
		PropName.Font = Enum.Font.SourceSans
		PropName.TextTransparency = 0.1
		PropName.TextXAlignment = Enum.TextXAlignment.Left
		PropName.Parent = NameFrame

		local Expand = Instance.new("TextButton")
		Expand.Name = "Expand"
		Expand.Visible = false
		Expand.Size = UDim2.new(0, 20, 0, 20)
		Expand.ClipsDescendants = true
		Expand.BackgroundTransparency = 1
		Expand.Position = UDim2.new(0, -20, 0, 1)
		Expand.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Expand.FontSize = Enum.FontSize.Size14
		Expand.TextSize = 14
		Expand.Text = ""
		Expand.Font = Enum.Font.SourceSans
		Expand.Parent = NameFrame

		local Icon = Instance.new("ImageLabel")
		Icon.Name = "Icon"
		Icon.Size = UDim2.new(0, 16, 0, 16)
		Icon.BackgroundTransparency = 1
		Icon.Position = UDim2.new(0, 2, 0, 2)
		Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon.ScaleType = Enum.ScaleType.Crop
		Icon.ImageRectOffset = Vector2.new(144, 16)
		Icon.ImageRectSize = Vector2.new(16, 16)
		Icon.Image = "rbxassetid://5642383285"
		Icon.Parent = Expand

		local ToggleAttributes = Instance.new("TextButton")
		ToggleAttributes.Name = "ToggleAttributes"
		ToggleAttributes.Visible = false
		ToggleAttributes.Size = UDim2.new(0, 85, 0, 22)
		ToggleAttributes.BackgroundTransparency = 1
		ToggleAttributes.Position = UDim2.new(1, -85, 0, 0)
		ToggleAttributes.BorderSizePixel = 0
		ToggleAttributes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ToggleAttributes.FontSize = Enum.FontSize.Size14
		ToggleAttributes.TextSize = 14
		ToggleAttributes.TextColor3 = Color3.fromRGB(255, 255, 255)
		ToggleAttributes.Text = "[SETTING: OFF]"
		ToggleAttributes.Font = Enum.Font.SourceSansBold
		ToggleAttributes.TextTransparency = 0.1
		ToggleAttributes.Parent = NameFrame

		local ValueFrame = Instance.new("Frame")
		ValueFrame.Name = "ValueFrame"
		ValueFrame.Size = UDim2.new(0, 80, 1, 0)
		ValueFrame.BorderColor3 = Color3.fromRGB(86, 125, 188)
		ValueFrame.BackgroundTransparency = 1
		ValueFrame.Position = UDim2.new(1, -100, 0, 0)
		ValueFrame.BorderSizePixel = 0
		ValueFrame.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
		ValueFrame.Parent = Entry

		local Line = Instance.new("Frame")
		Line.Name = "Line"
		Line.Size = UDim2.new(0, 1, 1, 0)
		Line.BorderColor3 = Color3.fromRGB(86, 125, 188)
		Line.Position = UDim2.new(0, -1, 0, 0)
		Line.BorderSizePixel = 0
		Line.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
		Line.Parent = ValueFrame

		local EnumArrow = Instance.new("Frame")
		EnumArrow.Name = "EnumArrow"
		EnumArrow.Visible = false
		EnumArrow.Size = UDim2.new(0, 16, 0, 16)
		EnumArrow.BackgroundTransparency = 1
		EnumArrow.Position = UDim2.new(1, -16, 0, 3)
		EnumArrow.Parent = ValueFrame

		local Frame = Instance.new("Frame")
		Frame.Size = UDim2.new(0, 1, 0, 1)
		Frame.Position = UDim2.new(0, 8, 0, 9)
		Frame.BorderSizePixel = 0
		Frame.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		Frame.Parent = EnumArrow

		local Frame1 = Instance.new("Frame")
		Frame1.Size = UDim2.new(0, 3, 0, 1)
		Frame1.Position = UDim2.new(0, 7, 0, 8)
		Frame1.BorderSizePixel = 0
		Frame1.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		Frame1.Parent = EnumArrow

		local Frame2 = Instance.new("Frame")
		Frame2.Size = UDim2.new(0, 5, 0, 1)
		Frame2.Position = UDim2.new(0, 6, 0, 7)
		Frame2.BorderSizePixel = 0
		Frame2.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		Frame2.Parent = EnumArrow

		local ValueBox = Instance.new("TextButton")
		ValueBox.Name = "ValueBox"
		ValueBox.Size = UDim2.new(1, -8, 1, 0)
		ValueBox.BackgroundTransparency = 1
		ValueBox.Position = UDim2.new(0, 4, 0, 0)
		ValueBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ValueBox.FontSize = Enum.FontSize.Size14
		ValueBox.TextTruncate = Enum.TextTruncate.AtEnd
		ValueBox.TextSize = 14
		ValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		ValueBox.Text = ""
		ValueBox.Font = Enum.Font.SourceSans
		ValueBox.TextTransparency = 0.1
		ValueBox.TextXAlignment = Enum.TextXAlignment.Left
		ValueBox.Parent = ValueFrame

		local RightButton = Instance.new("TextButton")
		RightButton.Name = "RightButton"
		RightButton.Visible = false
		RightButton.Size = UDim2.new(0, 20, 0, 22)
		RightButton.BackgroundTransparency = 1
		RightButton.Position = UDim2.new(1, -20, 0, 0)
		RightButton.BorderSizePixel = 0
		RightButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		RightButton.FontSize = Enum.FontSize.Size14
		RightButton.TextSize = 14
		RightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		RightButton.Text = "..."
		RightButton.Font = Enum.Font.SourceSans
		RightButton.Parent = ValueFrame

		local SettingsButton = Instance.new("TextButton")
		SettingsButton.Name = "SettingsButton"
		SettingsButton.Visible = false
		SettingsButton.Size = UDim2.new(0, 20, 0, 22)
		SettingsButton.BackgroundTransparency = 1
		SettingsButton.Position = UDim2.new(1, -20, 0, 0)
		SettingsButton.BorderSizePixel = 0
		SettingsButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SettingsButton.FontSize = Enum.FontSize.Size14
		SettingsButton.TextSize = 14
		SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		SettingsButton.Text = ""
		SettingsButton.Font = Enum.Font.SourceSans
		SettingsButton.Parent = ValueFrame

		local SoundPreview = Instance.new("Frame")
		SoundPreview.Name = "SoundPreview"
		SoundPreview.Visible = false
		SoundPreview.Size = UDim2.new(1, 0, 1, 0)
		SoundPreview.BackgroundTransparency = 1
		SoundPreview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SoundPreview.Parent = ValueFrame

		local ControlButton = Instance.new("TextButton")
		ControlButton.Name = "ControlButton"
		ControlButton.Size = UDim2.new(0, 20, 0, 22)
		ControlButton.BackgroundTransparency = 1
		ControlButton.BorderSizePixel = 0
		ControlButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ControlButton.FontSize = Enum.FontSize.Size14
		ControlButton.TextSize = 14
		ControlButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		ControlButton.Text = ""
		ControlButton.Font = Enum.Font.SourceSans
		ControlButton.Parent = SoundPreview

		local Icon1 = Instance.new("ImageLabel")
		Icon1.Name = "Icon"
		Icon1.Size = UDim2.new(0, 16, 0, 16)
		Icon1.BackgroundTransparency = 1
		Icon1.Position = UDim2.new(0, 2, 0, 3)
		Icon1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon1.ScaleType = Enum.ScaleType.Crop
		Icon1.ImageRectOffset = Vector2.new(144, 16)
		Icon1.ImageRectSize = Vector2.new(16, 16)
		Icon1.Image = "rbxassetid://5642383285"
		Icon1.Parent = ControlButton

		local TimeLine = Instance.new("Frame")
		TimeLine.Name = "TimeLine"
		TimeLine.Size = UDim2.new(1, -34, 0, 2)
		TimeLine.Position = UDim2.new(0, 26, 0.5, -1)
		TimeLine.BorderSizePixel = 0
		TimeLine.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		TimeLine.Parent = SoundPreview

		local Slider = Instance.new("Frame")
		Slider.Name = "Slider"
		Slider.Size = UDim2.new(0, 8, 0, 18)
		Slider.BorderColor3 = Color3.fromRGB(33, 33, 33)
		Slider.Position = UDim2.new(0, -4, 0, -8)
		Slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Slider.Parent = TimeLine

		local InfoButton = Instance.new("TextButton")
		InfoButton.Name = "InfoButton"
		InfoButton.Size = UDim2.new(0, 20, 0, 22)
		InfoButton.BackgroundTransparency = 1
		InfoButton.Position = UDim2.new(1, -20, 0, 0)
		InfoButton.BorderSizePixel = 0
		InfoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		InfoButton.FontSize = Enum.FontSize.Size14
		InfoButton.TextSize = 14
		InfoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		InfoButton.Text = ""
		InfoButton.Font = Enum.Font.SourceSans
		InfoButton.Parent = Entry

		local Icon2 = Instance.new("ImageLabel")
		Icon2.Name = "Icon"
		Icon2.Size = UDim2.new(0, 16, 0, 16)
		Icon2.BackgroundTransparency = 1
		Icon2.Position = UDim2.new(0, 2, 0, 3)
		Icon2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Icon2.ImageTransparency = 0.2
		Icon2.Image = "rbxassetid://6578933307"
		Icon2.Parent = InfoButton

		return Entry
	end

	SettingsEditor.StringToValue = function(settingInfo, str)
		local typeName = settingInfo.typeName

		-- For numbers and stuff
		if Apps.Properties.TypeNameConvert[typeName] then
			typeName = Apps.Properties.TypeNameConvert[typeName]
		end

		if typeName == "string" or typeName == "Content" then
			return str
		elseif Apps.Properties.ToNumberTypes[typeName] then
			return tonumber(str)
		elseif typeName == "Vector2" then
			local vals = str:split(",")
			local x, y = tonumber(vals[1]), tonumber(vals[2])
			if x and y and #vals >= 2 then
				return Vector2.new(x, y)
			end
		elseif typeName == "Vector3" then
			local vals = str:split(",")
			local x, y, z = tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3])
			if x and y and z and #vals >= 3 then
				return Vector3.new(x, y, z)
			end
		elseif typeName == "UDim" then
			local vals = str:split(",")
			local scale, offset = tonumber(vals[1]), tonumber(vals[2])
			if scale and offset and #vals >= 2 then
				return UDim.new(scale, offset)
			end
		elseif typeName == "UDim2" then
			local vals = str:gsub("[{}]", ""):split(",")
			local xScale, xOffset, yScale, yOffset =
				tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3]), tonumber(vals[4])
			if xScale and xOffset and yScale and yOffset and #vals >= 4 then
				return UDim2.new(xScale, xOffset, yScale, yOffset)
			end
		elseif typeName == "CFrame" then
			local vals = str:split(",")
			local s, result = pcall(CFrame.new, unpack(vals))
			if s and #vals >= 12 then
				return result
			end
		elseif typeName == "Rect" then
			local vals = str:split(",")
			local s, result = pcall(Rect.new, unpack(vals))
			if s and #vals >= 4 then
				return result
			end
		elseif typeName == "Ray" then
			local vals = str:gsub("[{}]", ""):split(",")
			local s, origin = pcall(Vector3.new, unpack(vals, 1, 3))
			local s2, direction = pcall(Vector3.new, unpack(vals, 4, 6))
			if s and s2 and #vals >= 6 then
				return Ray.new(origin, direction)
			end
		elseif typeName == "NumberRange" then
			local vals = str:split(",")
			local s, result = pcall(NumberRange.new, unpack(vals))
			if s and #vals >= 1 then
				return result
			end
		elseif typeName == "Color3" then
			local vals = str:gsub("[{}]", ""):split(",")
			local s, result = pcall(Color3.fromRGB, unpack(vals))
			if s and #vals >= 3 then
				return result
			end
		end

		return nil
	end

	SettingsEditor.ValueToString = function(val)
		local typeName = typeof(val)

		if typeName == "Color3" then
			return Lib.ColorToBytes(val)
		elseif typeName == "NumberRange" then
			return val.Min .. ", " .. val.Max
		end

		return tostring(val)
	end

	-- InputBox
	SettingsEditor.CreateInputBox = function(valueBox)
		local inputBox = create({
			{
				1,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.14901961386204, 0.14901961386204, 0.14901961386204),
					BorderSizePixel = 0,
					Name = "InputBox",
					Size = UDim2.new(0, 200, 0, 22),
					Visible = false,
					ZIndex = 2,
				},
			},
			{
				2,
				"TextBox",
				{
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.062745101749897, 0.51764708757401, 1),
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					Font = 3,
					Parent = { 1 },
					PlaceholderColor3 = Color3.new(0.69803923368454, 0.69803923368454, 0.69803923368454),
					Position = UDim2.new(0, 3, 0, 0),
					Size = UDim2.new(1, -6, 1, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 0,
					ZIndex = 2,
				},
			},
		})
		local inputTextBox = inputBox.TextBox
		inputBox.BackgroundColor3 = Settings.Theme.TextBox

		inputTextBox.FocusLost:Connect(function()
			valueBox.Visible = true
			inputBox.Visible = false
		end)

		inputTextBox.Focused:Connect(function()
			inputTextBox.SelectionStart = 1
			inputTextBox.CursorPosition = #inputTextBox.Text + 1
		end)

		valueBox.Changed:Connect(function(property)
			if property == "Text" then
				inputTextBox.Text = valueBox.Text
			end
		end)

		valueBox.MouseButton1Click:Connect(function()
			inputBox.Visible = true
			valueBox.Visible = false
		end)

		Lib.ViewportTextBox.convert(inputTextBox)

		return inputBox
	end

	SettingsEditor.DisplayColorEditor = function(obj, currentColor)
		local editor = SettingsEditor.ColorEditor

		if not editor then
			editor = Lib.ColorPicker.new()

			SettingsEditor.ColorEditor = editor
		end

		if editor then
			if SettingsEditor.ColorEditor.con_OnSelect then
				SettingsEditor.ColorEditor.con_OnSelect:Disconnect()
				SettingsEditor.ColorEditor.con_OnSelect = nil
			end

			local connection
			connection = editor.OnSelect:Connect(function(col)
				if not editor.CurrentProp then
					return
				end
				if not (editor.CurrentProp == obj) then
					return
				end

				local colVal = (col or BrickColor.new(col))

				obj:SetColor3Value(colVal)

				obj.OnColorChange:Fire()
			end)

			SettingsEditor.ColorEditor.con_OnSelect = connection
		end

		editor.CurrentProp = obj
		if currentColor then
			editor:SetColor(currentColor)
		end

		editor:Show()

		return editor
	end

	SettingsEditor.NewPropEntry = function()
		local newEntry = SettingsEditor.EntryTemplate():Clone()
		local nameFrame = newEntry.NameFrame
		local valueFrame = newEntry.ValueFrame

		local iconFrame = Main.MiscIcons:GetLabel()
		iconFrame.Position = UDim2.new(0, 2, 0, 3)
		iconFrame.Parent = newEntry.ValueFrame.RightButton

		return {
			Gui = newEntry,
			GuiElems = {
				NameFrame = nameFrame,
				ValueFrame = valueFrame,
				PropName = nameFrame.PropName,
				ValueBox = valueFrame.ValueBox,
				Expand = nameFrame.Expand,
				EnumArrow = valueFrame.EnumArrow,
				RightButton = valueFrame.RightButton,
				RightButtonIcon = iconFrame,
				SoundPreview = valueFrame.SoundPreview,
				SoundPreviewSlider = valueFrame.SoundPreview.TimeLine.Slider,
				InfoButton = newEntry.InfoButton,
			},
		}
	end

	SettingsEditor.ColorButton = (function()
		local funcs = {}

		local function createButton()
			local ColorButton = Instance.new("TextButton")
			ColorButton.Name = "ColorButton"
			ColorButton.Visible = false
			ColorButton.Size = UDim2.new(0, 20, 0, 22)
			ColorButton.BackgroundTransparency = 1
			ColorButton.BorderSizePixel = 0
			ColorButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ColorButton.FontSize = Enum.FontSize.Size14
			ColorButton.TextSize = 14
			ColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			ColorButton.Text = ""
			ColorButton.Font = Enum.Font.SourceSans

			local ColorPreview = Instance.new("Frame")
			ColorPreview.Name = "ColorPreview"
			ColorPreview.Size = UDim2.new(0, 10, 0, 10)
			ColorPreview.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ColorPreview.Position = UDim2.new(0, 5, 0, 6)
			ColorPreview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ColorPreview.Parent = ColorButton

			local UIGradient = Instance.new("UIGradient")
			UIGradient.Parent = ColorPreview

			return ColorButton
		end

		function funcs:SetPreviewColor(color)
			self.GuiElems.Gradient.Color = ColorSequence.new(color)
		end

		function funcs:SetColor3Value(color)
			self.CurrentColor3 = color
			self:SetPreviewColor(color)
		end

		local mt = { __index = funcs }

		local function new()
			local colorButton = createButton()

			local obj = setmetatable({
				Gui = colorButton,
				GuiElems = {
					ColorButton = colorButton,
					ColorPreview = colorButton.ColorPreview,
					Gradient = colorButton.ColorPreview.UIGradient,
				},

				OnColorChange = Lib.Signal.new(),
			}, mt)

			obj.CurrentColor3 = Color3.fromRGB(255, 255, 255)

			colorButton.ZIndex = 2 -- so it's clickable because ColorPreview obstructs it

			colorButton.MouseButton1Click:Connect(function()
				SettingsEditor.DisplayColorEditor(obj, obj.CurrentColor3)
			end)

			return obj
		end

		return { new = new }
	end)()

	SettingsEditor.Update = function() end

	SettingsEditor.UpdateView = function() end

	SettingsEditor.Refresh = function() end

	SettingsEditor.ScrollBarFrame = function()
		local ScrollingFrame = Instance.new("ScrollingFrame")
		ScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
		ScrollingFrame.BackgroundTransparency = 1
		ScrollingFrame.BorderSizePixel = 0

		ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		ScrollingFrame.ScrollBarThickness = 12

		local UILIstLayout = Instance.new("UIListLayout")
		UILIstLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UILIstLayout.Parent = ScrollingFrame

		return ScrollingFrame
	end

	SettingsEditor.CategoryListFrame = function()
		local List = Instance.new("Frame")
		List.Name = "List"
		List.AutomaticSize = Enum.AutomaticSize.Y
		List.Size = UDim2.new(1, -6, 0.1, 0)
		List.ClipsDescendants = true
		List.BackgroundTransparency = 1
		List.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

		local UILIstLayout = Instance.new("UIListLayout")
		UILIstLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UILIstLayout.Parent = List

		return List
	end

	-- Creates a dropdown
	SettingsEditor.CategoryDropdown = (function()
		local funcs = {}

		local function createFrame(self)
			local Expander = Instance.new("TextButton")
			Expander.Name = "Expander"
			Expander.Size = UDim2.new(1, -scrollbarThickness, 0, 22)
			Expander.BorderColor3 = Color3.fromRGB(33, 33, 33)
			Expander.BackgroundTransparency = 0.2
			Expander.Position = UDim2.new(0, 1, 0, 1)
			Expander.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			Expander.AutoButtonColor = false
			Expander.FontSize = Enum.FontSize.Size14
			Expander.TextSize = 14
			Expander.Text = ""
			Expander.Font = Enum.Font.SourceSans

			local NameFrame = Instance.new("Frame")
			NameFrame.Name = "NameFrame"
			NameFrame.Size = UDim2.new(1, -40, 1, 0)
			NameFrame.BorderColor3 = Color3.fromRGB(86, 125, 188)
			NameFrame.BackgroundTransparency = 1
			NameFrame.Position = UDim2.new(0, 20, 0, 0)
			NameFrame.BorderSizePixel = 0
			NameFrame.BackgroundColor3 = Color3.fromRGB(11, 90, 175)
			NameFrame.Parent = Expander

			local PropName = Instance.new("TextLabel")
			PropName.Name = "PropName"
			PropName.Size = UDim2.new(1, -2, 1, 0)
			PropName.BackgroundTransparency = 1
			PropName.Position = UDim2.new(0, 2, 0, 0)
			PropName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			PropName.FontSize = Enum.FontSize.Size14
			PropName.TextTruncate = Enum.TextTruncate.AtEnd
			PropName.TextSize = 14
			PropName.TextColor3 = Color3.fromRGB(255, 255, 255)
			PropName.Text = "Category"
			PropName.Font = Enum.Font.SourceSansBold
			PropName.TextTransparency = 0.1
			PropName.TextXAlignment = Enum.TextXAlignment.Left
			PropName.Parent = NameFrame

			local Expand = Instance.new("TextButton")
			Expand.Name = "Expand"
			Expand.Size = UDim2.new(0, 20, 0, 20)
			Expand.ClipsDescendants = true
			Expand.BackgroundTransparency = 1
			Expand.Position = UDim2.new(0, -20, 0, 1)
			Expand.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Expand.FontSize = Enum.FontSize.Size14
			Expand.TextSize = 14
			Expand.Text = ""
			Expand.Font = Enum.Font.SourceSans
			Expand.Parent = NameFrame

			local Icon = Instance.new("ImageLabel")
			Icon.Name = "Icon"
			Icon.Size = UDim2.new(0, 16, 0, 16)
			Icon.BackgroundTransparency = 1
			Icon.Position = UDim2.new(0, 2, 0, 2)
			Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Icon.ScaleType = Enum.ScaleType.Crop
			Icon.ImageRectOffset = Vector2.new(144, 16)
			Icon.ImageRectSize = Vector2.new(16, 16)
			Icon.Image = "rbxassetid://5642383285"
			Icon.Parent = Expand

			return Expander
		end

		local function setupGuiFuncs(self)
			local Expander = self.Gui

			local Expand = Expander.NameFrame.Expand

			-- Functions
			local function updateIcon()
				Apps.Explorer.MiscIcons:DisplayByKey(self.GuiElems.Icon, self.Expanded and "Collapse" or "Expand")
			end

			Expand.MouseButton1Click:Connect(function()
				if self.ToggleFrame then
					self.ToggleFrame.Visible = not self.ToggleFrame.Visible
				end

				if self.ToggleFrame.Visible then
					self.Expanded = true
				else
					self.Expanded = false
				end

				-- Update Icon
				updateIcon()
			end)

			-- Init
			updateIcon()
		end

		function funcs:SetDisplayName(displayName)
			if self.Gui:FindFirstChild("NameFrame") then
				self.Gui.NameFrame.PropName.Text = displayName
			end
		end

		-- Set the frame to toggle
		function funcs:SetToggleFrame(toggleFrame)
			self.ToggleFrame = toggleFrame

			return self.ToggleFrame
		end

		local mt = {}
		mt.__index = funcs

		local function new(toggleFrame, displayName)
			local obj = setmetatable({}, mt)

			obj.Gui = createFrame(obj)

			obj.GuiElems = {
				Icon = obj.Gui.NameFrame.Expand.Icon,
			}

			obj.Expanded = true -- Whether expanded

			setupGuiFuncs(obj)

			obj:SetDisplayName(displayName)

			obj:SetToggleFrame(toggleFrame)

			return obj
		end

		return { new = new }
	end)()

	-- Change a setting
	SettingsEditor.SetSettingValue = function(categoryName, settingName, settingInfo, newValue)
		if settingInfo.OnChange then
			settingInfo.OnChange(newValue)
		else
			Settings[categoryName][settingName] = newValue
		end
	end

	SettingsEditor.SetupInfoDesc = function()
		local infoDescBox = SettingsEditor.InfoDescBox
		-- TODO: Maybe change this

		if not infoDescBox then
			local newFrame = Instance.new("Frame")
			newFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			newFrame.BackgroundTransparency = 0.2
			newFrame.BorderSizePixel = 0
			newFrame.Size = UDim2.new(0, 0, 0, 0)
			newFrame.AutomaticSize = Enum.AutomaticSize.XY
			newFrame.Visible = false -- not visible

			local newTextBox = Instance.new("TextBox")
			newTextBox.BackgroundTransparency = 1
			newTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			newTextBox.Size = UDim2.new(0, 0, 0, 0)
			newTextBox.AutomaticSize = Enum.AutomaticSize.XY
			newTextBox.Parent = newFrame

			infoDescBox = newFrame
			SettingsEditor.InfoDescBox = infoDescBox

			infoDescBox.Parent = SettingsEditor.Window.Gui
		end

		return infoDescBox
	end

	SettingsEditor.CreateSettingEntry = function(categoryName, settingName, settingInfo)
		local newEntry = SettingsEditor.NewPropEntry()
		newEntry.Gui.Parent = settingsListFrame

		newEntry.GuiElems.PropName.Text = settingName

		local InfoButton: TextBox = newEntry.GuiElems.InfoButton

		if settingInfo.desc then
			local infoDescBox: Frame = SettingsEditor.InfoDescBox
			local isEnter = false

			InfoButton.MouseEnter:Connect(function(x, y)
				isEnter = true

				-- Set setting description
				(infoDescBox:WaitForChild("TextBox") :: TextBox).Text = settingInfo.desc

				infoDescBox.Position = UDim2.new(0, x, 0, y)
				infoDescBox.Visible = true
			end)

			InfoButton.MouseMoved:Connect(function(x, y)
				infoDescBox.Position = UDim2.new(0, x, 0, y)
				infoDescBox.Visible = true
			end)

			InfoButton.MouseLeave:Connect(function(x, y)
				if isEnter == true then
					isEnter = false
					infoDescBox.Visible = false
				end
			end)
		else
			-- Don't show info button, if there's no description.
			InfoButton.Visible = false
		end

		-- ValueBox
		local ValueBox: TextButton = newEntry.Gui.ValueFrame.ValueBox

		-- Boolean
		if settingInfo.typeName == "boolean" then
			-- Checkbox
			local newCheckbox = Lib.Checkbox.new()

			-- Set current value
			newCheckbox:SetState(Settings[categoryName][settingName], false)

			-- Whenever Checkbox value changes
			newCheckbox.OnInput:Connect(function()
				local newValue = newCheckbox.Toggled

				-- Sets the value
				SettingsEditor.SetSettingValue(categoryName, settingName, settingInfo, newValue)
			end)

			newCheckbox.Gui.Parent = newEntry.Gui.ValueFrame

			-- Color3
		elseif settingInfo.typeName == "Color3" then
			local colorButton = SettingsEditor.ColorButton.new()
			colorButton.Gui.Parent = newEntry.Gui.ValueFrame

			-- Set current Color3
			colorButton:SetColor3Value(Settings[categoryName][settingName])

			colorButton.Gui.Visible = true

			-- Fired once color input was changed
			colorButton.OnColorChange:Connect(function()
				local newColor = colorButton.CurrentColor3

				SettingsEditor.SetSettingValue(categoryName, settingName, settingInfo, newColor)
			end)
		else
			-- For anything else
			local inputBox = SettingsEditor.CreateInputBox(ValueBox)
			local inputTextBox = inputBox.TextBox.Input

			inputBox.Parent = newEntry.Gui.ValueFrame

			inputTextBox.FocusLost:Connect(function()
				local convertedVal = SettingsEditor.StringToValue(settingInfo, inputTextBox.Text)

				if convertedVal then
					ValueBox.Text = SettingsEditor.ValueToString(convertedVal)

					-- Sets value
					SettingsEditor.SetSettingValue(categoryName, settingName, settingInfo, convertedVal)
				end
			end)

			-- Set current value
			ValueBox.Text = SettingsEditor.ValueToString(Settings[categoryName][settingName])
		end

		return newEntry
	end

	-- Set up the settings.
	SettingsEditor.SetupSettings = function(categoryIndex, parentTo)
		local infoTable = SettingsEditor.SettingsInfo[categoryIndex]

		for _, settingName in ipairs(infoTable.Order) do
			if infoTable.Info[settingName] then
				local settingInfo = infoTable.Info[settingName]

				local newEntry = SettingsEditor.CreateSettingEntry(categoryIndex, settingName, settingInfo)

				newEntry.Gui.Parent = parentTo
			end
		end
	end

	-- Create new Category
	SettingsEditor.NewCategory = function(indexName, displayName, parentTo)
		-- indexName, how it should be indexed
		-- displayName, how the category should show up

		local categoryListFrame = SettingsEditor.CategoryListFrame():Clone()
		categoryListFrame.Name = indexName
		--categoryListFrame.Visible = false

		-- Setup settings
		SettingsEditor.SetupSettings(indexName, categoryListFrame)

		local category = SettingsEditor.CategoryDropdown.new(categoryListFrame, displayName)
		category.Gui.Parent = parentTo

		-- parent category list
		categoryListFrame.Parent = parentTo

		return category
	end

	-- Generate Setting buttons and stuff
	SettingsEditor.RenderSettings = function()
		for _, categoryName in ipairs(SettingsEditor.SettingsInfo._Categories) do
			SettingsEditor.NewCategory(categoryName, categoryName, settingsListFrame)
		end
	end

	-- Init
	SettingsEditor.Init = function()
		local window = Lib.Window.new()
		SettingsEditor.Window = window

		window:SetTitle("Settings")
		window.Resizable = true

		-- Setup Results ScrollingFrame
		settingsListFrame = SettingsEditor.ScrollBarFrame()

		SettingsEditor.Window.GuiElems.Main.Parent.Name = "Dex_SettingsWindow" -- Change ScreenGui name

		-- Setup Gui
		SettingsEditor.SetupInfoDesc() -- Hover text description

		SettingsEditor.RenderSettings() -- Sets up UI to change settings

		-- Window Add, adds things to the "Content"
		window:Add(settingsListFrame)
	end

	return SettingsEditor
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
