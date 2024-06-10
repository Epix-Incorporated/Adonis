client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local gTable
	local answer
	local startTick = os.clock()

	local window = client.UI.Make("Window", {
		Name  = data.Name or "Prompt";
		Title = data.Title or "Prompt";
		Size = data.Size or {225, 150};
		SizeLocked = true;
		Icon = data.Icon or client.MatIcons.Help;
		OnClose = function()
			if not answer then
				answer = "No"
			end
		end
	})

	local label = window:Add("TextLabel", {
		Text = data.Question;
		Font = Enum.Font.SourceSans;
		TextScaled = true;
		BackgroundTransparency = 1;
		TextWrapped = true;
		Size = UDim2.new(1, -10, 1, -45);
	})

	local yes = window:Add("TextButton", {
		Text = "Yes";
		Font = Enum.Font.Arial;
		TextSize = 18;
		AnchorPoint = Vector2.new(0, 1);
		Size = UDim2.new(0.5, -7, 0, 30);
		Position = UDim2.new(0, 5, 1, -5);
		BackgroundColor3 = Color3.fromRGB(74, 195, 56);
		BackgroundTransparency = 0.5;
	})

	local no = window:Add("TextButton", {
		Text = "No";
		Font = Enum.Font.Arial;
		TextSize = 18;
		AnchorPoint = Vector2.new(0, 1);
		Size = UDim2.new(0.5, -7, 0, 30);
		Position = UDim2.new(0.5, 2, 1, -5);
		BackgroundColor3 = Color3.fromRGB(206, 72, 45);
		BackgroundTransparency = 0.5;
	})

	yes.MouseButton1Down:Connect(function()
		if data.Delay and os.clock() < startTick + data.Delay then
			return
		end

		answer = "Yes"
		window:Close()
	end)

	no.MouseButton1Down:Connect(function()
		answer = "No"
		window:Close()
	end)

	gTable = window.gTable
	window:Ready()

	if data.Delay then
		yes.BackgroundColor3 = Color3.fromRGB(38, 100, 28)

		repeat
			yes.Text = string.format("%s", math.ceil(startTick + data.Delay - os.clock()))
			task.wait(1)
		until os.clock() > startTick + data.Delay

		yes.Text = "Yes"
		yes.BackgroundColor3 = Color3.fromRGB(74, 195, 56)
	end

	repeat task.wait() until answer 
	return answer
end
