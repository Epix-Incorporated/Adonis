client = nil
service = nil

return function(_, env)
	if env then
		setfenv(1, env)
	end

	local client = env.client
	local service = env.service
	local gui = env.gui

	local UI = client.UI
	local Remote = client.Remote
	local Variables = client.Variables
	local Deps = client.Deps

	local window = UI.Make("Window", {
		Name = "Settings",
		Title = "Settings",
		Size = { 225, 200 },
		AllowMultiple = false,
	})

	local cliSettings = {
		{
			Text = "Keybinds: ",
			Desc = "- Enables/Disables Keybinds",
			Entry = "Boolean",
			Value = Variables.KeybindsEnabled,
			Function = function(enabled, toggle)
				Variables.KeybindsEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "KeybindsEnabled", enabled)
				toggle.Text = text
			end,
		},
		{
			Text = "UI Keep Alive: ",
			Desc = "- Prevents Adonis UI deletion on death",
			Entry = "Boolean",
			Value = Variables.UIKeepAlive,
			Function = function(enabled, toggle)
				Variables.UIKeepAlive = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "UIKeepAlive", enabled)
				toggle.Text = text
			end,
		},
		{
			Text = "Particle Effects: ",
			Desc = "- Enables/Disables certain Adonis made effects like sparkles",
			Entry = "Boolean",
			Value = Variables.ParticlesEnabled,
			Function = function(enabled, toggle)
				Variables.ParticlesEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "ParticlesEnabled", enabled)
				toggle.Text = text
			end,
		},
		{
			Text = "Capes: ",
			Desc = "- Allows you to disable all player capes locally",
			Entry = "Boolean",
			Value = Variables.CapesEnabled,
			Function = function(enabled, toggle)
				Variables.CapesEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "CapesEnabled", enabled)
				toggle.Text = text
			end,
		},
		{
			Text = "Hide Chat Commands: ",
			Desc = "- Hide commands ran from the chat",
			Entry = "Boolean",
			Setting = "HideChatCommands",
			Value = Variables.HideChatCommands or false,
			Function = function(enabled, toggle)
				Variables.HideChatCommands = enabled

				local text = toggle.Text
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "HideChatCommands", enabled)
				toggle.Text = text
			end,
		},
		{
			Text = "Console Key: ",
			Desc = "Key used to open the console",
			Entry = "Button",
			Value = Variables.CustomConsoleKey or Remote.Get("Setting", "ConsoleKeyCode"),
			Function = function(toggle)
				local gotKey
				toggle.Text = "Waiting..."
				local event = service.UserInputService.InputBegan:Connect(function(InputObject)
					local textbox = service.UserInputService:GetFocusedTextBox()
					if not textbox and rawequal(InputObject.UserInputType, Enum.UserInputType.Keyboard) then
						gotKey = InputObject.KeyCode.Name
					end
				end)

				repeat
					wait()
				until gotKey

				Variables.CustomConsoleKey = gotKey
				event:Disconnect()
				toggle.Text = "Saving.."
				Remote.Get("UpdateClient", "CustomConsoleKey", Variables.CustomConsoleKey)
				toggle.Text = gotKey
			end,
		},
		{
			Text = "Theme: ",
			Desc = "- Allows you to set the Adonis UI theme",
			Entry = "DropDown",
			Setting = "CustomTheme",
			Function = function(clone)
				local toggle = clone.TextButton
				local themePicker = gui.ThemePicker
				local themeFrame = themePicker.Frame
				local themeEnt = themePicker.Entry
				local function showThemes()
					themeFrame:ClearAllChildren()

					local fromOffset = UDim2.fromOffset

					local Themes = { "Default" }
					for _, v in ipairs(Deps.UI:GetChildren()) do
						table.insert(Themes, v.Name)
					end

					local num = 0
					for _, v in pairs(Themes) do
						local new = themeEnt:Clone()
						new.Text = v
						new.Position = fromOffset(0, 20 * num)
						new.Visible = true
						new.MouseButton1Click:Connect(function()
							service.Debounce("ClientSelectingTheme", function()
								themePicker.Visible = false
								toggle.Text = v
								Variables.CustomTheme = v
								if v == "Default" then
									Remote.Get("UpdateClient", "CustomTheme", nil)
								else
									Remote.Get("UpdateClient", "CustomTheme", v)
								end
							end)
						end)
						new.Parent = themeFrame
						num += 1
					end

					themePicker.Position = fromOffset(toggle.AbsolutePosition.X + 15, toggle.AbsolutePosition.Y)
					themePicker.Visible = true
				end

				toggle.MouseButton1Click:Connect(function()
					service.Debounce("ClientDisplayThemes", function()
						if themePicker.Visible then
							themePicker.Visible = false
						else
							showThemes()
						end
					end)
				end)

				if Variables.CustomTheme then
					toggle.Text = Variables.CustomTheme
				else
					toggle.Text = "Default"
				end
			end,
		},
	}

	if window then
		local tabFrame = window:Add("TabFrame", {
			Size = UDim2.new(1, -10, 1, -10),
			Position = UDim2.new(0, 5, 0, 5),
		})

		local clientTab = tabFrame:NewTab("Client", {
			Text = "Client",
		})

		tabFrame:NewTab("Game", {
			Text = "Game",
		})

		for i, v in next, cliSettings do
			if v.Entry == "Boolean" then
				local new = clientTab:Add("TextLabel", {
					Size = UDim2.new(1, -10, 0, 25),
					Position = UDim2.new(0, 5, 0, 25 * (i - 1)),
					TextXAlignment = "Left",
					Enabled = v.Value,
					Text = v.Text,
					ToolTip = v.Desc,
				})

				new:Add("Boolean", {
					Size = UDim2.new(0, 100, 0, 20),
					Position = UDim2.new(1, -100, 0, 0),
					Enabled = v.Value,
					OnToggle = function()
						print("Toggled thinger")
					end,
				})
			end
		end

		clientTab:ResizeCanvas(false, true)

		window:Ready()
	end
end
