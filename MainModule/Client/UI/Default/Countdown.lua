client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	local tLimit = data.Time
	local sImg

	local isMuted = false

	local tock = service.New("Sound", {
		Volume = 0.25; Looped = false; SoundId = "rbxassetid://151715959";
	})
	local buzzer = service.New("Sound", {
		Volume = 0.25; Looped = false; SoundId = "rbxassetid://267883066";
	})

	local textSize = service.TextService:GetTextSize(tLimit, 100, Enum.Font.SourceSans, Vector2.new(math.huge,math.huge))	
	if textSize.X < 150 then textSize = Vector2.new(175, textSize.Y) end

	local window = client.UI.Make("Window", {
		Name = "Countdown";
		Title = "Countdown";
		Icon = client.MatIcons["Hourglass full"];
		Size = {textSize.X + 40, textSize.Y + 20};
		Position = UDim2.new(0, 10, 1, -(textSize.Y + 30));
		OnClose = function()
			tock:Stop()
			buzzer:Stop()
			tock:Destroy()
			buzzer:Destroy()
		end
	})

	local label = window:Add("TextLabel", {
		Text = tLimit;
		BackgroundTransparency = 1;
		TextScaled = true;
	})

	local elapsed = window:Add("TextLabel", {
		Text = "0";
		TextXAlignment = Enum.TextXAlignment.Right;
		BackgroundTransparency = 1;
		Size = UDim2.fromOffset(25, 25);
		Position = UDim2.new(1, -30, 1, -25);
	})

	local muteButton = window:AddTitleButton({
		Text = "";
		OnClick = function()
			if isMuted then
				tock.Volume = 0.25
				buzzer.Volume = 0.25
				sImg.Image = "rbxassetid://1638551696"
				isMuted = false
			else
				tock.Volume = 0
				buzzer.Volume = 0
				sImg.Image = "rbxassetid://1638584675"
				isMuted = true
			end
		end
	})

	sImg = muteButton:Add("ImageLabel", {
		Size = UDim2.new(1,0,1,0);
		Position = UDim2.new(0,0,0,0);
		ScaleType = Enum.ScaleType.Fit;
		Image = "rbxassetid://1638551696";
		BackgroundTransparency = 1;
	})

	tock.Parent = label
	buzzer.Parent = label
	gTable = window.gTable
	gTable:Ready()

	local startTime = os.clock()
	local expectedDelay = 0
	local timeOff = 0

	for i = tLimit, 1, -1 do
		if not gTable.Active then break end
		tock:Play()
		label.Text = i
		elapsed.Text = tLimit - i
		wait(1 - timeOff)
		expectedDelay += 1
		timeOff = os.clock() - startTime - expectedDelay
	end

	label.Text = "0"
	elapsed.Text = tLimit

	buzzer:Play()

	for k = 0, 3 do
		buzzer:Play()
		for i = 1, 0, -0.1 do
			label.TextTransparency = i
			wait(0.05)
		end

		for i = 0, 1, 0.1 do
			label.TextTransparency = i
			wait(0.05)
		end
	end

	window:Close()
end
