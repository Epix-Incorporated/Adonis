client = nil
service = nil
Routine = nil

local function boolToStr(bool)
	return bool and "Yes" or "No"
end

return function(data)
	local client = client
	local service = client.Service

	local Routine = Routine

	local player = data.Target

	local window = client.UI.Make("Window", {
		Name  = "Profile_"..player.UserId;
		Title = "Profile (@"..player.Name..")";
		Size  = {400, 400};
		AllowMultiple = false;
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local generaltab = tabFrame:NewTab("General", {
		Text = "General"
	})

	local friendstab = tabFrame:NewTab("Friends", {
		Text = "Friends"
	})

	local groupstab = tabFrame:NewTab("Groups", {
		Text = "Groups"
	})

	local gametab = tabFrame:NewTab("Game", {
		Text = "Game"
	})

	local isFriends = player:IsFriendsWith(service.Players.LocalPlayer.UserId)
	if player ~= service.Players.LocalPlayer then
		window:AddTitleButton({
			Text = "";
			OnClick = isFriends and function()
				service.StarterGui:SetCore("PromptUnfriend", player)
			end
				or function()
				service.StarterGui:SetCore("PromptSendFriendRequest", player)
			end
		}):Add("ImageLabel", {
			Size = UDim2.new(0, 20, 0, 20);
			Position = UDim2.new(0, 5, 0, 0);
			Image = (isFriends and "rbxassetid://5422934472") or "rbxassetid://5107197931";
			BackgroundTransparency = 1;
		})
	end
	window:AddTitleButton({
		Text = "";
		OnClick = function()
			service.GuiService:InspectPlayerFromUserId(player.UserId)
		end
	}):Add("ImageLabel", {
		Size = UDim2.new(0, 18, 0, 18);
		Position = UDim2.new(0, 6, 0, 1);
		Image = "rbxassetid://7495451175";
		BackgroundTransparency = 1;
	})

	do
		generaltab:Add("ImageLabel", {
			Size = UDim2.new(0, 120, 0, 120);
			Position = UDim2.new(0, 5, 0, 5);
			Image = service.Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size150x150);
		})

		for i, v in ipairs({
			{"Display Name", player.DisplayName, "The player's custom display name"},
			{"Username", player.Name, "The player's unique Roblox username"},
			{"User ID", player.UserId, "The player's unique Roblox user ID"},
			{"Acc. Age", player.AccountAge .. " days ("..string.format("%.2f", player.AccountAge/365).." years)", "How long the player has been registered on Roblox"},
			}) do
			generaltab:Add("TextLabel", {
				Text = "  "..v[1]..": ";
				ToolTip = v[3];
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -135, 0, 30);
				Position = UDim2.new(0, 130, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			}):Add("TextLabel", {
				Text = v[2];
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -130, 0, 0);
				TextXAlignment = "Right";
			})
		end

		for i, v in ipairs({
			{"Membership", player.MembershipType.Name, "The player's Roblox membership type (premium)"},
			{"Safe Chat Enabled", (data.SafeChat), "Does the player have safe chat applied?"},
			{"Can Chat", boolToStr(data.CanChat), "Does the player's account settings allow them to chat?"},
			{"Country/Region Code", data.Code, "The player's country or region code based on geolocation"}
			}) do
			generaltab:Add("TextLabel", {
				Text = "  "..v[1]..": ";
				ToolTip = v[3];
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+130);
				TextXAlignment = "Left";
			}):Add("TextLabel", {
				Text = v[2];
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -130, 0, 0);
				TextXAlignment = "Right";
			})
		end

		local credentials = {
			{data.IsDonor, "Adonis Donor", "rbxassetid://6877822142", "User has purchased the Adonis donation pass/shirt"},
			{player:GetRankInGroup(886423) == 10, "Adonis Contributor (GitHub)", "rbxassetid://6878433601", "User has contributed to the Adonis admin system (see credit list)"},
			{player:GetRankInGroup(886423) == 12, "Adonis Developer", "rbxassetid://6878433601", "User is an official developer of the Adonis admin system"},
			-- haha? {player.UserId == 644946329, "I invented this profile interface! [Expertcoderz]", "rbxthumb://type=AvatarHeadShot&id=644946329&w=48&h=48", "yes"},
			{player.UserId == (1237666 or 698712377), "Adonis Creator [Sceleratis/Davey_Bones]", "rbxassetid://6878433601", "You are looking at the creator of the Adonis admin system!"},
			{player:IsInGroup(1200769) or player:IsInGroup(2868472), "ROBLOX Staff", "rbxassetid://6811962259", "User is an official Roblox employee (!)"},
			{player:IsInGroup(3514227), "DevForum Member", "rbxassetid://6383940476", "User is a member of the Roblox Developer Forum"},
		}
		for i, v in ipairs(credentials) do
			if v[1] then
				generaltab:Add("TextLabel", {
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, (32*(i-1))+255);
					BackgroundTransparency = 0.4;
					Text = v[2];
					ToolTip = v[4]
				}):Add("ImageLabel", {
					Image = v[3];
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 24, 0, 24);
					Position = UDim2.new(0, 4, 0, 3);
				})
			end
		end

		generaltab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	window:Ready()

	do
		local function iterPageItems(pages)
			return coroutine.wrap(function()
				local pagenum = 1
				while true do
					for _, item in ipairs(pages:GetCurrentPage()) do
						coroutine.yield(item, pagenum)
					end
					if pages.IsFinished then
						break
					end
					pages:AdvanceToNextPageAsync()
					pagenum = pagenum + 1
				end
			end)
		end

		local friendPages = service.Players:GetFriendsAsync(player.UserId)
		local sortedFriends = {}
		local friendInfoRef = {}

		local friendCount = 0
		local onlineCount = 0

		Routine(function()
			for item, pageNo in iterPageItems(friendPages) do
				table.insert(sortedFriends, item.Username)
				friendInfoRef[item.Username] = {
					id=item.Id;
					displayName=item.DisplayName;
					isOnline=item.IsOnline;
				}
				if item.IsOnline then 
					onlineCount += 1
				end
				friendCount += 1
			end
			table.sort(sortedFriends)

			local search = friendstab:Add("TextBox", {
				Size = UDim2.new(1, -10, 0, 25);
				Position = UDim2.new(0, 5, 0, 5);
				BackgroundTransparency = 0.5;
				PlaceholderText = ("Search %d friends (%d online)"):format(friendCount, onlineCount);
				Text = "";
				TextStrokeTransparency = 0.8;
			})
			local scroller = friendstab:Add("ScrollingFrame",{
				List = {};
				ScrollBarThickness = 2;
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 5, 0, 35);
				Size = UDim2.new(1, -10, 1, -40);
			})

			local function getList()
				scroller:ClearAllChildren()
				local i = 1
				for _, friendName in ipairs(sortedFriends) do
					local friendInfo = friendInfoRef[friendName]
					if (friendName:sub(1, #search.Text):lower() == search.Text:lower()) or (friendInfo.displayName:sub(1, #search.Text):lower() == search.Text:lower()) then
						local entryText = ""
						if friendName == friendInfo.displayName then
							entryText = friendName
						else
							entryText = friendInfo.displayName.." (@"..friendName..")"
						end
						local entry = scroller:Add("TextLabel", {
							Text = "             "..entryText;
							ToolTip = "User ID: "..friendInfo.id;
							BackgroundTransparency = ((i-1)%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, 0, 0, 30);
							Position = UDim2.new(0, 0, 0, (30*(i-1)));
							TextXAlignment = "Left";
						})
						if friendInfo.isOnline then
							entry:Add("TextLabel", {
								Text = "Online";
								BackgroundTransparency = 1;
								Size = UDim2.new(0, 120, 1, 0);
								Position = UDim2.new(1, -130, 0, 0);
								TextXAlignment = "Right";
							})
						end
						Routine(function()
							entry:Add("ImageLabel", {
								Image = service.Players:GetUserThumbnailAsync(friendInfo.id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
								BackgroundTransparency = 1;
								Size = UDim2.new(0, 30, 0, 30);
								Position = UDim2.new(0, 0, 0, 0);
							})
						end)
						i += 1
					end
				end
				scroller:ResizeCanvas(false, true, false, false, 5, 5)
			end

			search:GetPropertyChangedSignal("Text"):Connect(getList)
			getList()
		end)

	end

	do
		local sortedGroups = {}    
		local groupInfoRef = {}

		local groupCount = 0
		local ownCount = 0

		for _, groupInfo in pairs(service.GroupService:GetGroupsAsync(player.UserId) or {}) do
			Routine(service.ContentProvider.PreloadAsync, service.ContentProvider, {
				groupInfo.EmblemUrl
			})

			table.insert(sortedGroups, groupInfo.Name)
			groupInfoRef[groupInfo.Name] = groupInfo

			groupCount += 1
			if groupInfo.Rank == 255 then
				ownCount += 1
			end
		end
		table.sort(sortedGroups)


		local search = groupstab:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			PlaceholderText = ("Search %d groups (%d owned)"):format(groupCount, ownCount);
			Text = "";
			TextStrokeTransparency = 0.8;
		})
		local scroller = groupstab:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 2;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 35);
			Size = UDim2.new(1, -10, 1, -40);
		})

		local function getList()
			scroller:ClearAllChildren()
			local i = 1
			for _, groupName in ipairs(sortedGroups) do
				local groupInfo = groupInfoRef[groupName]
				if (groupName:sub(1, #search.Text):lower() == search.Text:lower()) or (groupInfo.Role:sub(1, #search.Text):lower() == search.Text:lower()) then
					local entry = scroller:Add("TextLabel", {
						Text = "             "..groupName.." ";
						ToolTip = "ID: "..groupInfo.Id.." | Rank: "..groupInfo.Rank.." | Is Primary Group: "..boolToStr(groupInfo.IsPrimary);
						BackgroundTransparency = ((i-1)%2 == 0 and 0) or 0.2;
						Size = UDim2.new(1, -10, 0, 30);
						Position = UDim2.new(0, 5, 0, (30*(i-1)));
						TextXAlignment = "Left";
					})
					entry:Add("TextLabel", {
						Text = groupInfo.Role;
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -130, 0, 0);
						TextXAlignment = "Right";
					})
					Routine(function()
						entry:Add("ImageLabel", {
							Image = groupInfo.EmblemUrl;
							BackgroundTransparency = 1;
							Size = UDim2.new(0, 30, 0, 30);
							Position = UDim2.new(0, 0, 0, 0);
						})
					end)
					i += 1
				end
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 5)
		end

		search:GetPropertyChangedSignal("Text"):Connect(getList)
		getList()
	end

	if data.GameData then
		local gameplayDataToDisplay = {
			{"Admin Level", data.GameData.AdminLevel, "The player's Adonis rank"},
			{"Muted", boolToStr(data.GameData.IsMuted), "Is the player muted? (IGNORES TRELLO MUTELIST)"},
			{"Auto Jump Enabled", boolToStr(player.AutoJumpEnabled), "Does the player have auto jump enabled?"},
			{"Camera Max Zoom Distance", player.CameraMaxZoomDistance, "How far in studs the player can zoom out their camera"},
			{"Camera Min Zoom Distance", player.CameraMinZoomDistance, "How close in studs the player can zoom in their camera"},
			-- NEEDS REFRESHABILITY {"Gameplay Paused", boolToStr(player.GameplayPaused), "Is the player's gameplay paused? (for content streaming)"},
			-- NEEDS REFRESHABILITY {"Character Exists", boolToStr(player.Character), "Does the player currently have a character?"},
			{"Accelerometer Enabled", boolToStr(data.GameData.AccelerometerEnabled), "Whether the user’s device has an accelerometer"},
			{"Gamepad Enabled", boolToStr(data.GameData.GamepadEnabled), "Whether the user's device has an available gamepad"},
			{"Gyroscope Enabled", boolToStr(data.GameData.GyroscopeEnabled), "Whether the user’s device has a gyroscope"},
			{"Keyboard Enabled", boolToStr(data.GameData.KeyboardEnabled), "Whether the user’s device has a keyboard available"},
			{"Mouse Delta Sensitivity", data.GameData.MouseDeltaSensitivity, "The scale of the delta (change) output of the user’s Mouse"},
			{"Mouse Enabled", boolToStr(data.GameData.MouseEnabled), "Whether the user’s device has a mouse available"},
			-- NEEDS REFRESHABILITY {"OnScreenKeyboardVisible", data.GameData.OnScreenKeyboardVisible, "Whether an on-screen keyboard is currently visible on the user’s screen"},
			{"Touch Enabled", boolToStr(data.GameData.TouchEnabled), "Whether the user’s current device has a touch-screen available"},
			{"VR Enabled", boolToStr(data.GameData.VREnabled), "Whether the user is using a virtual reality headset"},
			{"Source Place ID", data.GameData.SourcePlaceId, "The ID of the place from which the player was teleported to this game, if applicable"},
		}

		local i = 1
		for _, v in ipairs(gameplayDataToDisplay) do
			local entry = gametab:Add("TextLabel", {
				Text = "  "..v[1]..": ";
				ToolTip = v[3];
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			}):Add("TextBox", {
				Text = v[2];
				TextEditable = false;
				ClearTextOnFocus = false;
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -130, 0, 0);
				TextXAlignment = "Right";
			})
			i += 1
		end

		gametab:Add("TextButton", {
			Text = "View Tools";
			BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
			Size = UDim2.new(1, -10, 0, 35);
			Position = UDim2.new(0, 5, 0, (30*(i-1))+10);
			OnClicked = function()
				local tools = {}
				for k,t in pairs(player.Backpack:GetChildren()) do
					if t:IsA("Tool") then
						table.insert(tools, {Text=t.Name,Desc="Class: "..t.ClassName.." | ToolTip: "..t.ToolTip})
					elseif t:IsA("HopperBin") then
						table.insert(tools, {Text=t.Name,Desc="Class: "..t.ClassName.." | BinType: "..tostring(t.BinType)})
					else
						table.insert(tools, {Text=t.Name,Desc="Class: "..t.ClassName})
					end
				end
				client.UI.Make("List", {
					Title = "@"..player.Name.."'s tools";
					Table = tools;
				})
			end
		})

		gametab:ResizeCanvas(false, true, false, false, 5, 5)

	else
		gametab:Disable()
	end
end
