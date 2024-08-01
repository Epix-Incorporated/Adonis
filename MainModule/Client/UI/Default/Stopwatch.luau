client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gTable
	local tLimit = 0
	local sImg
	
	local isMuted = false

	local tock = service.New("Sound", {
		Volume = 0.25; Looped = false; SoundId = "rbxassetid://151715959";
	})

	local textSize = service.TextService:GetTextSize(tLimit, 100, Enum.Font.SourceSans, Vector2.new(math.huge,math.huge))	
	if textSize.X < 150 then textSize = Vector2.new(175, textSize.Y) end

	local window = client.UI.Make("Window", {
		Name = "Stopwatch";
		Title = "Stopwatch";
		Icon = client.MatIcons["Hourglass full"];
		Size = {textSize.X + 40, textSize.Y + 20};
		Position = UDim2.new(0, 10, 1, -(textSize.Y + 30));
		OnClose = function()
			tock:Stop()
			tock:Destroy()
		end
	})

	local label = window:Add("TextLabel", {
		Text = tLimit;
		BackgroundTransparency = 1;
		TextScaled = true;
	})

	local muteButton = window:AddTitleButton({
		Text = "";
		OnClick = function()
			if isMuted then
				tock.Volume = 0.25
				sImg.Image = "rbxassetid://1638551696"
				isMuted = false
			else
				tock.Volume = 0
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
	gTable = window.gTable
	gTable:Ready()
	
	local ctime = 0

	while task.wait(1) do
		if not gTable.Active then break end
		tock:Play()
		ctime += 1
		label.Text = ctime
	end
end
