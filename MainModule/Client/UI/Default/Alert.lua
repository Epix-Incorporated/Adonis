client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local gTable

	local isMuted = false

	local alarm = service.New("Sound", {
		Volume = 1,
		Looped = true,
		SoundId = "rbxassetid://143969658",
	})

	local window = client.UI.Make("Window", {
		Name = "Alert",
		Title = "Alert",
		Size = { 300, 150 },
		Icon = client.MatIcons["Priority high"],
		AllowMultiple = false,
		OnClose = function()
			alarm:Stop()
			task.wait()
			alarm:Destroy()
		end,
	})

	if window then
		local label = window:Add("TextLabel", {
			Text = data.Message,
			BackgroundTransparency = 1,
			TextScaled = true,
			TextWrapped = true,
		})

		local muteButton = window:AddTitleButton({
			Text = "",
		})

		local sImg = muteButton:Add("ImageLabel", {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 5, 0, 0),
			Image = "rbxassetid://1638551696",
			BackgroundTransparency = 1,
		})

		muteButton.MouseButton1Down:Connect(function()
			if isMuted then
				alarm.Volume = 1
				sImg.Image = "rbxassetid://1638551696"
				isMuted = false
			else
				alarm.Volume = 0
				sImg.Image = "rbxassetid://1638584675"
				isMuted = true
			end
		end)

		alarm.Parent = label
		alarm:Play()
		gTable = window.gTable
		window:Ready()
	end
end
