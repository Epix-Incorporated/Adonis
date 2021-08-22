client = nil
service = nil

return function(data)
	local generate = nil

	local window = client.UI.Make("Window",{
		Name  = "OnlineFriends";
		Title = "Online Friends";
		Size  = {390, 320};
		MinSize = {180, 120};
		AllowMultiple = false;
		OnRefresh = function()
			generate()
		end
	})

	do
		local function locationTypeToStr(int)
			return ({
				[0] = "Mobile Website";
				[1] = "Mobile InGame";
				[2] = "Website";
				[3] = "Studio";
				[4] = "InGame";
				[5] = "Xbox";
				[6] = "Team Create";
			})[int]
		end;

		local scroller = window:Add("ScrollingFrame", {
			List = {};
			ScrollBarThickness = 3;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 32);
			Size = UDim2.new(1, 0, 1, -37);
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

		function generate()
			local friendDictionary = game:GetService("Players").LocalPlayer:GetFriendsOnline()
			local sortedFriends = {}
			local friendInfo = {}

			for _, item in pairs(friendDictionary) do
				table.insert(sortedFriends, item.UserName)
				friendInfo[item.UserName] = {id=item.VisitorId;displayName=item.DisplayName;lastLocation=item.LastLocation;locationType=item.LocationType;}
			end

			table.sort(sortedFriends)

			local filter = search.Text
			scroller:ClearAllChildren()
			local i = 1
			local friendCount = 0
			for _, friendName in ipairs(sortedFriends) do
				friendCount = friendCount + 1
				if (friendName:sub(1, #filter):lower() == filter:lower()) or (friendInfo[friendName].displayName:sub(1, #filter):lower() == filter:lower()) then
					local entryText = ""
					if friendName == friendInfo[friendName].displayName then
						entryText = friendName
					else
						entryText = friendInfo[friendName].displayName.." (@"..friendName..")"
					end
					local entry = scroller:Add("TextLabel", {
						Text = "             "..entryText;
						ToolTip = "Location: "..friendInfo[friendName].lastLocation;
						BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
						Size = UDim2.new(1, -10, 0, 30);
						Position = UDim2.new(0, 5, 0, (30*(i-1)));
						TextXAlignment = "Left";
					})
					entry:Add("TextLabel", {
						Text = " "..locationTypeToStr(friendInfo[friendName].locationType).."  ";
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						TextXAlignment = "Right";
					})
					spawn(function()
						entry:Add("ImageLabel", {
							Image = game:GetService("Players"):GetUserThumbnailAsync(friendInfo[friendName].id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420);
							BackgroundTransparency = 1;
							Size = UDim2.new(0, 30, 0, 30);
							Position = UDim2.new(0, 0, 0, 0);
						})
					end)
					i += 1
				end
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 5)
			window:SetTitle("Online Friends ("..friendCount..")")
		end

		search.FocusLost:Connect(generate)
		generate()
	end

	window:Ready()
	
	window:AddTitleButton({
		Text = "";
		OnClick = function()
			service.SocialService:PromptGameInvite(service.Players.LocalPlayer)
		end
	}):Add("ImageLabel", {
		Size = UDim2.new(0, 20, 0, 20);
		Position = UDim2.new(0, 5, 0, 0);
		Image = "rbxassetid://5422934472";
		BackgroundTransparency = 1;
	})
end
