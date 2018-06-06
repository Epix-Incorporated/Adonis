
client = nil
service = nil

return function(data)
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "Settings";
		Title = "Settings";
		Size  = {225, 200};
		AllowMultiple = false;
	})
	
	local cliSettings = {
		{
			Text = "Keybinds: ";
			Desc = "- Enabled/Disables Keybinds";
			Entry = "Boolean";
			Value = client.Variables.KeybindsEnabled;
			Function = function(enabled, toggle)
				client.Variables.KeybindsEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				client.Remote.Get("UpdateClient","KeybindsEnabled",enabled)
				toggle.Text = text
			end
		};
		{
			Text = "UI Keep Alive: ";
			Desc = "- Prevents Adonis UI deletion on death";
			Entry = "Boolean";
			Value = client.Variables.UIKeepAlive;
			Function = function(enabled, toggle)
				client.Variables.UIKeepAlive = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				client.Remote.Get("UpdateClient","UIKeepAlive",enabled)
				toggle.Text = text
			end
		};
		{
			Text = "Particle Effects: ";
			Desc = "- Enables/Disables certain Adonis made effects like sparkles";
			Entry = "Boolean";
			Value = client.Variables.ParticlesEnabled;
			Function = function(enabled, toggle)
				client.Variables.ParticlesEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				client.Remote.Get("UpdateClient","ParticlesEnabled",enabled)
				toggle.Text = text
			end
		};
		{
			Text = "Capes: ";
			Desc = "- Allows you to disable all player capes locally";
			Entry = "Boolean";
			Value = client.Variables.CapesEnabled;
			Function = function(enabled, toggle)
				client.Variables.CapesEnabled = enabled
				local text = toggle.Text
				toggle.Text = "Saving.."
				client.Remote.Get("UpdateClient","CapesEnabled",enabled)
				toggle.Text = text
			end
		};
		{
			Text = "Console Key: ";
			Desc = "Key used to open the console";
			Entry = "Button";
			Value = client.Variables.CustomConsoleKey or client.Remote.Get("Setting","ConsoleKeyCode");
			Function = function(toggle)
				local gotKey
				toggle.Text = "Waiting..."
				local event = service.UserInputService.InputBegan:connect(function(InputObject)
					local textbox = service.UserInputService:GetFocusedTextBox()
					if not (textbox) and rawequal(InputObject.UserInputType, Enum.UserInputType.Keyboard) then
						gotKey = InputObject.KeyCode.Name
					end
				end)
				
				repeat wait() until gotKey
				
				client.Variables.CustomConsoleKey = gotKey
				event:Disconnect()
				toggle.Text = "Saving.."
				client.Remote.Get("UpdateClient","CustomConsoleKey",client.Variables.CustomConsoleKey)
				toggle.Text = gotKey
			end
		};
		{
			Text = "Theme: ";
			Desc = "- Allows you to set the Adonis UI theme";
			Entry = "DropDown";
			Setting = "CustomTheme";
			Function = function(clone)
				local toggle = clone.TextButton
				local themePicker = gui.ThemePicker
				local themeFrame = themePicker.Frame
				local themeEnt = themePicker.Entry
				local function showThemes()
					themeFrame:ClearAllChildren()
					
					local themes = {"Default"}
					local num = 0
					
					for i,v in pairs(client.Deps.UI:GetChildren()) do
						table.insert(themes,v.Name)
					end
					
					for i,v in pairs(themes) do
						local new = themeEnt:Clone()
						new.Text = v
						new.Position = UDim2.new(0,0,0,20*num)
						new.Parent = themeFrame
						new.Visible = true
						new.MouseButton1Click:connect(function()
							service.Debounce("ClientSelectingTheme",function()
								themePicker.Visible = false
								toggle.Text = v
								client.Variables.CustomTheme = v
								if v == "Default" then
									client.Remote.Get("UpdateClient","CustomTheme",nil)
								else
									client.Remote.Get("UpdateClient","CustomTheme",v)
								end
							end)
						end)
						num = num+1
					end
					
					themePicker.Position = UDim2.new(0,toggle.AbsolutePosition.X, 0, toggle.AbsolutePosition.Y)
					themePicker.Visible = true
				end
				
				toggle.MouseButton1Click:connect(function()
					service.Debounce("ClientDisplayThemes",function()
						if themePicker.Visible then
							themePicker.Visible = false
						else
							showThemes()
						end
					end)
				end)
				
				if client.Variables.CustomTheme then
					toggle.Text = client.Variables.CustomTheme
				else
					toggle.Text = "Default"
				end
			end
		}
	}
	
	if window then
		local tabFrame = window:Add("TabFrame",{
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5);
		})
		
		local clientTab = tabFrame:NewTab("Client",{
			Text = "Client";
		})
		
		local gameTab = tabFrame:NewTab("Game",{
			Text = "Game";
		})
		
		--[[local clientList = clientTab:Add
		})("ScrollingFrame",{
			
		
		local gameList = gameTab:Add("ScrollingFrame",{
			
		})--]]
		
		for i,v in next,cliSettings do
			if v.Entry == "Boolean" then
				local new = clientTab:Add("TextLabel", {
					Size = UDim2.new(1, -10, 0, 25);
					Position = UDim2.new(0, 5, 0, 25*(i-1));
					TextXAlignment = "Left";
					Enabled = v.Value;
					Text = v.Text;
					ToolTip = v.Desc;
				})
				
				new:Add("Boolean", {
					Size = UDim2.new(0, 100, 0, 20);
					Position = UDim2.new(1, -100, 0, 0);
					Enabled = v.Value;
					OnToggle = function(enabled, button)
						print("Toggled thinger")
					end
				})
			end
		end
		
		clientTab:ResizeCanvas(false, true)
		
		gTable = window.gTable
		window:Ready()
	end
end