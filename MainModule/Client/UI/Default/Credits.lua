return function(data, env)
	if env then
		setfenv(1, env)
	end

	local client = env.client
	local service = env.service

	local window = client.UI.Make("Window", {
		Name = "Credits",
		Title = "Credits",
		Icon = client.MatIcons.Grade,
		Size = { 280, 300 },
		AllowMultiple = false,
	})
	if not window then
		return
	end

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
	})

	local Credits = require(client.Shared.Credits)
	for _, tab in ipairs({
		[1] = tabFrame:NewTab("Main", { Text = "Main" }),
		[2] = tabFrame:NewTab("Contributors", { Text = "Contributors" }),
		[3] = tabFrame:NewTab("Misc", { Text = "Everyone Else" }),
	}) do
		local scroller = tab:Add("ScrollingFrame", {
			List = {},
			ScrollBarThickness = 3,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 30),
			Size = UDim2.new(1, -10, 1, -35),
		})

		local search = tab:Add("TextBox", {
			Position = UDim2.new(0, 5, 0, 5),
			Size = UDim2.new(1, -10, 0, 20),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			TextColor3 = Color3.new(1, 1, 1),
			Text = "",
			PlaceholderText = "Search",
			TextStrokeTransparency = 0.8,
		})
		search:Add("ImageLabel", {
			Image = client.MatIcons.Search,
			Position = UDim2.new(1, -20, 0, 2),
			Size = UDim2.new(0, 16, 0, 16),
			ImageTransparency = 0.2,
			BackgroundTransparency = 1,
		})

		local function generate()
			local i = 1
			local filter = search.Text
			scroller:ClearAllChildren()
			for _, credit in ipairs(Credits[tab.Name]) do
				if
					(string.lower(string.sub(credit.Text, 1, #filter)) == string.lower(filter))
					or (tab.Name == "Contributors" and string.lower(string.sub(credit.Text, 9, 8 + #filter)) == string.lower(filter))
				then
					scroller:Add("TextLabel", {
						Text = `  {credit.Text} `,
						ToolTip = credit.Desc,
						BackgroundTransparency = (i % 2 == 0 and 0) or 0.2,
						Size = UDim2.new(1, 0, 0, 26),
						Position = UDim2.new(0, 0, 0, (26 * (i - 1))),
						TextXAlignment = "Left",
					})
					i += 1
				end
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 0)
		end

		search:GetPropertyChangedSignal("Text"):Connect(generate)
		generate()
	end

	window:Ready()
end
