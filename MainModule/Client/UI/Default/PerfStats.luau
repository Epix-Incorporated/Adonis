client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local gfps = true
	local colorData = {
		["Bad"] = "#ff3300",
		["Mid"] = "#ffbf00",
		["Ok"] = "#00ff5e"
	}

	function getColorForStat(statValue: number, isPing: boolean)
		return isPing
		and (statValue >= 350 and colorData.Bad
			or statValue >= 125 and colorData.Mid
			or colorData.Ok)
		or (statValue <= 25 and colorData.Bad
			or statValue <= 50 and colorData.Mid
			or colorData.Ok)
	end

	local gTable

	local window = client.UI.Make("Window", {
		Name = "Performance stats",
		Title = "Stats",
		Icon = client.MatIcons.Leaderboard,
		Size = { 150, 120 },
		Position = UDim2.new(0, 10, 1, -130),
		AllowMultiple = false,
		NoHide = true,
		Walls = true,
		CanKeepAlive = true,
		OnClose = function()
			gfps = false
		end,
	})

	if window then
		local label = window:Add("TextLabel", {
			Text = "...",
			BackgroundTransparency = 1,
			TextSize = 20,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			RichText = true,
			--TextScaled = true;
			--TextWrapped = true;
		})

		gTable = window.gTable
		window:Ready()

		local prevPing = 50
		repeat

			local fps = 1 / service["RunService"].RenderStepped:Wait()
			local physicsFps = workspace:GetRealPhysicsFPS()
			local rawPing = service.Players.LocalPlayer:GetNetworkPing() * 1000
			local realPing = client.Remote.Ping()
			local correctPing = realPing

			-- If we somehow get ratelimited, fall back to
			-- old ping so we dont error out
			if realPing == false then
				correctPing = prevPing
			else
				prevPing = correctPing
			end

			label.Text = string.format(
				`<font color="{getColorForStat(fps)}">Render: %.1f fps</font> \n<font color="{getColorForStat(physicsFps)}">Physics: %.1f fps</font>\n<font color="{getColorForStat(rawPing, true)}">Raw Ping: %d ms</font>\n<font color="{getColorForStat(correctPing, true)}">Real Ping: %d ms</font>`,
				fps,
				physicsFps,
				rawPing,
				correctPing
			)
			task.wait(0.5)
		until not gfps or not gTable.Active
	end
end
