client = nil
service = nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local gTable

	local isMuted = false

	local alarm = service.New('Sound')
	alarm.Volume = 1
	alarm.Looped = true
	alarm.SoundId = 'http://www.roblox.com/asset/?id=138081509'

	local window = client.UI.Make("Window",{
		Name  = "Alert";
		Title = "Alert";
		Size  = {300,150};
		Icon = "rbxassetid://7467248902";
		AllowMultiple = false;
		OnClose = function()
			alarm:Stop()
			wait()
			alarm:Destroy()
		end
	})

	if window then
		local label = window:Add("TextLabel",{
			Text = data.Message;
			BackgroundTransparency = 1;
			TextScaled = true;
			TextWrapped = true;
		})

		local muteButton = window:AddTitleButton({
			Text = "";
		})

		local sImg = muteButton:Add("ImageLabel", {
			Size = UDim2.new(0, 20, 0, 20);
			AnchorPoint = Vector2.new(0.5,0.5);
			ScaleType = Enum.ScaleType.Fit;
			Position = UDim2.new(0.5, 0 ,0.536, 0);
			Image = "rbxassetid://7463478056";
			BackgroundTransparency = 1;
		})

		muteButton.MouseButton1Down:Connect(function()
			if isMuted then
				alarm.Volume = 1
				sImg.Image = "rbxassetid://7463478056"
				isMuted = false
			else
				alarm.Volume = 0
				sImg.Image = "rbxassetid://7463462018";
				isMuted = true
			end
		end)

		alarm.Parent = label
		alarm:Play()
		gTable = window.gTable
		window:Ready()
	end
end
