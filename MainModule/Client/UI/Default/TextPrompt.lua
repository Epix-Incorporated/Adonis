client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	local answer

	local window = client.UI.Make("Window", {
		Name  = data.Name or "Prompt";
		Title = data.Title or "Prompt";
		Size  = data.Size or {225, 150};
		SizeLocked = true;
		OnClose = function()
			if not answer then
				answer = data.DefaultAnswer or ""
			end
		end
	})

	local label = window:Add("TextLabel", {
		Text = data.Question;
		Font = "SourceSans";
		TextScaled = true;
		BackgroundTransparency = 1;
		TextWrapped = true;
		Size = UDim2.new(1, -10, 1, -35);
	})

	local input = window:Add("TextBox", {
		Text = "";
		TextSize = 18;
		PlaceholderText = data.PlaceholderText or "";
		ClearTextOnFocus = data.ClearTextOnFocus or false;
		Size = UDim2.new(1, -40, 0, 25);
		Position = UDim2.new(0, 5, 1, -30);
	})
	input.FocusLost:Connect(function(entered)
		if entered then
			answer = input.Text
			window:Close()
		end
	end)

	local submit = window:Add("TextButton", {
		Text = ">";
		Font = "Arial";
		TextSize = 22;
		Size = UDim2.new(0, 25, 0, 25);
		Position = UDim2.new(1, -30, 1, -30);
		OnClick = function()
			answer = input.Text
			window:Close()
		end;
	})

	gTable = window.gTable
	window:Ready()
	repeat wait() until answer 
	return answer
end
