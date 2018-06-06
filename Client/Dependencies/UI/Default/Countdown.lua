
client = nil
service = nil

return function(data)
	local gTable
	local tLimit = data.Time
	local sImg
	
	local isMuted = false
	
	local tock = service.New('Sound')
	tock.Volume = 0.25
	tock.Looped = false
	tock.SoundId = 'http://www.roblox.com/asset/?id=151715959'
	
	local buzzer = service.New('Sound')
	buzzer.Volume = 0.25
	buzzer.Looped = false
	buzzer.SoundId = 'http://www.roblox.com/asset/?id=267883066'
	
	local window = client.UI.Make("Window", {
		Name = "Countdown";
		Title = "Countdown";
		Size = {300, 150};
		Position = UDim2.new(0, 10, 1, -160);
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
				sImg.Image = "rbxassetid://1638584675";
				isMuted = true
			end
		end
	})
	
	sImg = muteButton:Add("ImageLabel", {
		Size = UDim2.new(0, 20, 0, 20);
		Position = UDim2.new(0, 5, 0, 0);
		Image = "rbxassetid://1638551696";
		BackgroundTransparency = 1;
	})
	
	tock.Parent = label
	buzzer.Parent = label
	gTable = window.gTable
	gTable:Ready()						
	
	for i = tLimit, 0, -1 do
		if gTable.Active then
			tock:Play()
			label.Text = i
		else
			break
		end
		wait(1)
	end
	
	buzzer:Play()
	
	for k = 0,3 do
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