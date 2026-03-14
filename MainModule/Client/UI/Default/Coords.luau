return function(data, env)
	if env then setfenv(1, env) end

	local client = env.client
	local service = env.service

	local Player = service.Player

	local active = true
	local gTable

	local window = client.UI.Make("Window", {
		Name = "Coords",
		Title = "Coordinates",
		Icon = client.MatIcons.Broadcast,
		Size = { 200, 100 },
		Position = UDim2.new(0, 10, 1, -110),
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
			Position = UDim2.new()
		})

		gTable = window.gTable
		window:Ready()

		repeat
			local PrimaryPart = Player.Character and Player.Character.PrimaryPart
			label.Text = if PrimaryPart
				then string.format("X: %.2f\nY: %.2f\nZ: %.2f", PrimaryPart.Position.X, PrimaryPart.Position.Y, PrimaryPart.Position.Z)
				else "..."

			task.wait(0.25)
		until not active or not gTable.Active or gTable.Destroyed
	end
end