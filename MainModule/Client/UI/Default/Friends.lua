client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local generate = nil

	local window = client.UI.Make("Window", {
		Name = "OnlineFriends";
		Title = "Online Friends";
		Icon = client.MatIcons.People;
		Size = {390, 320};
		MinSize = {180, 120};
		AllowMultiple = false;
		OnRefresh = function()
			generate()
		end
	})

	local function locationTypeToStr(int)
		return ({
			[0] = "Mobile Website"; [1] = "Mobile InGame"; [2] = "Website"; [3] = "Studio"; [4] = "InGame"; [5] = "Xbox"; [6] = "Team Create";
		})[int]
	end;

	local scroller = window:Add("ScrollingFrame", {
		List = {};
		ScrollBarThickness = 3;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 5, 0, 35);
		Size = UDim2.new(1, -10, 1, -40);
	})
	scroller:Add("UIListLayout", {
		SortOrder = "LayoutOrder";
		FillDirection = "Vertical";
		VerticalAlignment = "Top";
	})

	local search = window:Add("TextBox", {
		Position = UDim2.new(0, 5, 0, 5);
		Size = UDim2.new(1, -10, 0, 25);
		BackgroundTransparency = 0.25;
		BorderSizePixel = 0;
		TextColor3 = Color3.new(1, 1, 1);
		Text = "";
		PlaceholderText = "Search";
		TextStrokeTransparency = 0.8;
	})
	search:Add("ImageLabel", {
		Image = client.MatIcons.Search;
		Position = UDim2.new(1, -21, 0, 3);
		Size = UDim2.new(0, 18, 0, 18);
		ImageTransparency = 0.2;
		BackgroundTransparency = 1;
	})

	function generate()
		local friendDictionary = service.Players.LocalPlayer:GetFriendsOnline()
		table.sort(friendDictionary, function(a, b)
			return a.UserName < b.UserName
		end)

		local filter = search.Text

		for _, child in ipairs(scroller:GetChildren()) do 
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		
		for i, friend in ipairs(friendDictionary) do
			if friend.UserName:sub(1, #filter):lower() == filter:lower() or friend.DisplayName:sub(1, #filter):lower() == filter:lower() then
				local entry = scroller:Add("TextLabel", {
					Text = `             {if friend.UserName == friend.DisplayName then friend.UserName else `{friend.DisplayName} (@{friend.UserName})`}`;
					ToolTip = `Location: {friend.LastLocation}`;
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, 0, 0, 30);
					LayoutOrder = i;
					TextXAlignment = "Left";
				})
				entry:Add("TextLabel", {
					Text = ` {locationTypeToStr(friend.LocationType)}  `;
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 120, 1, 0);
					Position = UDim2.new(1, -120, 0, 0);
					TextXAlignment = "Right";
				})
				spawn(function()
					entry:Add("ImageLabel", {
						Image = service.Players:GetUserThumbnailAsync(friend.VisitorId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420);
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 30, 0, 30);
						Position = UDim2.new(0, 0, 0, 0);
					})
				end)
			end
		end
		
		scroller:ResizeCanvas(false, true, false, false, 5, 5)
		window:SetTitle(`Online Friends ({#friendDictionary})`)
	end

	search:GetPropertyChangedSignal("Text"):Connect(generate)
	generate()

	window:Ready()

	window:AddTitleButton({
		Text = "";
		ToolTip = "Invite";
		OnClick = function()
			service.SocialService:PromptGameInvite(service.Players.LocalPlayer)
		end
	}):Add("ImageLabel", {
		Size = UDim2.new(0, 16, 0, 16);
		Position = UDim2.new(0, 8, 0, 2);
		Image = client.MatIcons.Send;
		BackgroundTransparency = 1;
	})
end
