client = nil
service = nil

return function(_, env)
	if env then
		setfenv(1, env)
	end

	local getData = nil

	local window = client.UI.Make("Window", {
		Name = "BlockedUsers",
		Title = "Blocked Users",
		Icon = client.MatIcons.Dangerous,
		Size = { 300, 200 },
		MinSize = { 180, 120 },
		AllowMultiple = false,
		OnRefresh = function()
			getData()
		end,
	})

	local scroller = window:Add("ScrollingFrame", {
		List = {},
		ScrollBarThickness = 3,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 35),
		Size = UDim2.new(1, 0, 1, -40),
	})

	local search = window:Add("TextBox", {
		Position = UDim2.new(0, 5, 0, 5),
		Size = UDim2.new(1, -10, 0, 25),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
		PlaceholderText = "Search",
		TextStrokeTransparency = 0.8,
	})
	search:Add("ImageLabel", {
		Image = client.MatIcons.Search,
		Position = UDim2.new(1, -21, 0, 3),
		Size = UDim2.new(0, 18, 0, 18),
		ImageTransparency = 0.2,
		BackgroundTransparency = 1,
	})

	local blockedUsers: { number } = {}

	local function generate()
		local filter = search.Text
		scroller:ClearAllChildren()
		local count = 0
		for i, person in ipairs(blockedUsers) do
			count += 1
			local name = if type(person) == "number"
				then service.Players:GetNameFromUserIdAsync(person)
				elseif person.DisplayName == person.Username then person.Username
				else `{person.DisplayName} (@${person.Username})`
			local userId = if type(person) == "number" then person else person.Id
			local plr = service.Players:GetPlayerByUserId(userId)
			if filter == "" or string.find(name:lower(), filter:lower()) then
				local entry = scroller:Add("TextLabel", {
					Text = `         {name}`,
					ToolTip = `ID: {userId}`,
					BackgroundTransparency = (i % 2 == 0 and 0) or 0.2,
					Size = UDim2.new(1, -10, 0, 30),
					Position = UDim2.new(0, 5, 0, (30 * (i - 1))),
					TextXAlignment = "Left",
				})
				if plr then
					entry:Add("TextLabel", {
						Text = "Unblock",
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 100, 0.9, 0),
						Position = UDim2.new(1, -100, 0.05, 0),
						OnClick = function()
							service.StarterGui:SetCore("PromptUnblockPlayer", plr)
						end,
					})
				end
				task.spawn(function()
					entry:Add("ImageLabel", {
						Image = service.Players:GetUserThumbnailAsync(
							userId,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size420x420
						),
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 30, 0, 30),
						Position = UDim2.new(0, 0, 0, 0),
					})
				end)
			end
		end
		scroller:ResizeCanvas(false, true, false, false, 5, 5)
		window:SetTitle(`Blocked Users ({count})`)
	end

	function getData()
		blockedUsers = service.StarterGui:GetCore("GetBlockedUserIds")
		blockedUsers = select(
			2,
			xpcall(function()
				return service.UserService:GetUserInfosByUserIdsAsync(blockedUsers)
			end, function()
				return blockedUsers
			end)
		)
		generate()
	end

	search:GetPropertyChangedSignal("Text"):Connect(generate)
	service.StarterGui:GetCore("PlayerBlockedEvent").Event:Connect(getData)
	service.StarterGui:GetCore("PlayerUnblockedEvent").Event:Connect(getData)
	getData()

	window:Ready()
end
