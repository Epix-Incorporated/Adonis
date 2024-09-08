client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local active = true
	local gTable

	local window = client.UI.Make("Window", {
		Name = "Coords",
		Title = "Coordinates",
		Icon = client.MatIcons.LocationOn,
		Size = { 200, 60 },
		Position = UDim2.new(0, 10, 1, -120),
		AllowMultiple = false,
		NoHide = true,
		Walls = true,
		CanKeepAlive = true,
		OnClose = function()
			active = false
		end,
	})

	if window then
		local label = window:Add("TextLabel", {
			Text = "...",
			BackgroundTransparency = 1,
			TextSize = 18,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
		})

		gTable = window.gTable
		window:Ready()

		local function updateCoords()
			if service.Players.LocalPlayer.Character then
				local rootPart = service.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					return string.format("X: %.2f\nY: %.2f\nZ: %.2f", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z)
				end
			end
			return "..."
		end

		repeat
			label.Text = updateCoords()
			task.wait(0.5)
		until not active or not gTable.Active
	end
end