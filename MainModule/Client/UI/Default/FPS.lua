client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local measuring = true
	local gTable

	local window = client.UI.Make("Window", {
		Name  = "FPS";
		Title = "FPS";
		Icon = client.MatIcons.Leaderboard;
		Size  = {150, 70};
		Position = UDim2.new(0, 10, 1, -80);
		AllowMultiple = false;
		NoHide = true;
		OnClose = function()
			measuring = false
		end
	})

	if window then
		local label = window:Add("TextLabel", {
			Text = "...";
			BackgroundTransparency = 1;
			TextSize = 20;
			Size = UDim2.fromScale(1, 1);
			Position = UDim2.new(0, 0, 0, 0);
			--TextScaled = true;
			--TextWrapped = true;
		})

		gTable = window.gTable
		window:Ready()

		repeat
			label.Text = tostring(client.Remote.FPS())
			wait(2)
		until not measuring or not gTable.Active
	end
end
