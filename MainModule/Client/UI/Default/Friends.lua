-- Expertcoder2
-- Created: 26/03/2021
-- Updated: 28/03/2021


client = nil
service = nil

return function(data)

	local window = client.UI.Make("Window",{
		Name  = "OnlineFriends";
		Title = "Online Friends";
		Size  = {390, 320};
		MinSize = {180, 120};
		AllowMultiple = false;
	})

	do
		local function locationTypeToStr(int)
			return ({
				[0] = "Mobile Website";
				[1] = "Mobile InGame";
				[2] = "Webpage";
				[3] = "Studio";
				[4] = "InGame";
				[5] = "Xbox";
				[6] = "Team Create";
			})[int]
		end;

		local friendDictionary = game:GetService("Players").LocalPlayer:GetFriendsOnline()
		local sortedFriends = {}
		local friendInfo = {}

		for _, item in pairs(friendDictionary) do
			table.insert(sortedFriends, item.UserName)
			friendInfo[item.UserName] = {id=item.VisitorId;displayName=item.DisplayName;lastLocation=item.LastLocation;locationType=item.LocationType;}
		end

		table.sort(sortedFriends)
		
		local i = 1
		local friendCount = 0
		for _, friendName in ipairs(sortedFriends) do
			friendCount = friendCount + 1
			local entryText = ""
			if friendName == friendInfo[friendName].displayName then
				entryText = friendName
			else
				entryText = friendName.." ("..friendInfo[friendName].displayName..")"
			end
			local entry = window:Add("TextLabel", {
				Text = "             "..entryText;
				ToolTip = "Location: "..friendInfo[friendName].lastLocation;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
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
			i = i + 1
		end
		window:SetTitle("Online Friends ("..friendCount..")")
	end

	window:ResizeCanvas(false, true, false, false, 5, 5)
	window:Ready()
end
