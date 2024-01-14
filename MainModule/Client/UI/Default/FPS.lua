client,service = nil,nil

return function(data,env)
	if env then
		setfenv(1, env)
	end
	
	local gfps = true
	local gTable
	
	--warn(math.floor(1/game:GetService("RunService").RenderStepped:Wait()))
	
	local window = client.UI.Make("Window",{
		Name  = "FPS";
		Title = "FPS";
		Icon = client.MatIcons.Leaderboard;
		Size  = {150, 70};
		Position = UDim2.new(0, 10, 1, -80);
		AllowMultiple = false;
		NoHide = true;
		Walls = true;
		SizeLocked = true;
		CanKeepAlive = true;
		OnClose = function()
			gfps = false
		end
	})
	
	if window then
		local label = window:Add("TextLabel",{
			Text = "...";
			BackgroundTransparency = 1;
			TextSize = 20;
			Size = UDim2.new(1, 0, 1, 0);
			Position = UDim2.new(0, 0, 0, 0);
			--TextScaled = true;
			--TextWrapped = true;
		})

		gTable = window.gTable
		window:Ready()

		repeat
			label.Text = `Render: {math.round(1/service["RunService"].RenderStepped:Wait())} fps\nPhysics: {math.round(workspace:GetRealPhysicsFPS())} fps\nPing: {math.floor(service.Players.LocalPlayer:GetNetworkPing()*1000)} ms`
			task.wait(1)
		until not gfps or not gTable.Active
	end
end
