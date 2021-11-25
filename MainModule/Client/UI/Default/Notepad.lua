client = nil
service = nil

return function(data)

	local window = client.UI.Make("Window", {
		Name  = "Notepad";
		Title = "Notepad";
		Icon = client.MatIcons.Description;
	})

	local topbar = window:Add("Frame", {
		Size = UDim2.new(1, 0, 0, 28);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 1;
	})

	local charCount = topbar:Add("TextLabel", {
		Size = UDim2.new(0, 100, 1, -8);
		Position = UDim2.new(1, -105, 0, 4);
		Text = "0 characters";
		TextXAlignment = "Right";
		BackgroundTransparency = 1;
	})
	
	local container = window:Add("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 30);
		Size = UDim2.new(1, 0, 1, -30);
		CanvasSize = UDim2.new(0, 0, 10, 0);
		BackgroundTransparency = 1;
	})
	
	local content = container:Add("TextBox", {
		Size = UDim2.new(1, -4, 1, 0);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundColor3 = Color3.new(1, 1, 1);
		TextColor3 = Color3.new(0,0,0);
		Font = "Code";
		FontSize = "Size18";
		TextXAlignment = "Left";
		TextYAlignment = "Top";
		TextWrapped = true;
		TextScaled = false;
		ClearTextOnFocus = false;
		MultiLine = true;
		Text = "";
	})
	
	local fonts = {}
	for _, font in ipairs(Enum.Font:GetEnumItems()) do
		table.insert(fonts, font.Name)
	end
	local fontSelector = topbar:Add("Dropdown", {
		Size = UDim2.new(0, 140, 1, -8);
		Position = UDim2.new(0, 5, 0, 4);
		Text = "Font";
		BackgroundTransparency = 0;
		Options = fonts;
		Selected = "Code";
		OnSelect = function(selection)
			content.Font = selection
		end;
	})
	
	local sizeControl = topbar:Add("TextLabel", {
		Text = "  Size: ";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 80, 1, -8);
		Position = UDim2.new(0, 155, 0, 4);
		TextXAlignment = "Left";
		Children = {
			TextBox = {
				Text = "";
				PlaceholderText = "18";
				Size = UDim2.new(0, 26, 1, 0);
				Position = UDim2.new(1, -31, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = "Right";
				ClipsDescendants = true;
				TextChanged = function(text, enter, new)
					if enter and tonumber(text) then
						if tonumber(text) < 100 then
							content.TextSize = text;
						else
							content.TextSize = 99;
						end
					end
				end
			}
		}
	})

	window:Ready()

	content:GetPropertyChangedSignal("Text"):Connect(function()
		charCount.Text = tostring(#content.Text).." characters"
	end)
end
