client = nil
service = nil

return function(data)

	local window = client.UI.Make("Window", {
		Name  = "Notepad";
		Title = "Notepad";
		AllowMultiple = false;
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
		table.insert(fonts, tostring(font):sub(11))
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

	window:Ready()

	content:GetPropertyChangedSignal("Text"):Connect(function()
		charCount.Text = tostring(#content.Text).." characters"
	end)
end
