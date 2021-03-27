-- Expertcoder2
-- 20/03/2021


client = nil
service = nil

local function boolToStr(bool)
	if bool then
		return "Yes"
	else
		return "No"
	end
end

local function msTypeToStr(enum)
	if enum == Enum.MembershipType.None then
		return "None"
	elseif enum == Enum.MembershipType.Premium then
		return "Premium"
	else
		return "?"
	end
end

return function(data)
	local player = data.Target

	local window = client.UI.Make("Window", {
		Name  = "Inspect_"..player.UserId;
		Title = "Inspect ("..player.Name..")";
		Size  = {400, 350};
		AllowMultiple = false;
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local generaltab = tabFrame:NewTab("General", {
		Text = "General"
	})

	local backgroundtab = tabFrame:NewTab("Background", {
		Text = "Background"
	})

	local friendstab = tabFrame:NewTab("Friends", {
		Text = "Friends"
	})

	local adonistab = tabFrame:NewTab("Adonis", {
		Text = "Adonis"
	})

	local gametab = tabFrame:NewTab("Game", {
		Text = "Game"
	})

	do
		local i = 1
		local function addGeneralEntry(name, value, toolTip)
			local entry = generaltab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add("TextLabel", {
				Text = " "..value.."  ";
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -120, 0, 0);
				TextXAlignment = "Right";
			})

			i = i + 1
		end

		addGeneralEntry("Username:", player.Name, "The player's Roblox username")
		addGeneralEntry("User ID:", player.UserId, "The player's unique Roblox user ID")
		addGeneralEntry("Account Age:", player.AccountAge, "How long (in days) the player has been registered on Roblox")
		addGeneralEntry("Membership:", msTypeToStr(player.MembershipType), "The player's Roblox membership type")

		spawn(function()
			generaltab:Add("ImageLabel", {
				Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420);
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(0, 90, 0, 90);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+10);
			})
			generaltab:Add("ImageLabel", {
				Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420);
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(0, 90, 0, 90);
				Position = UDim2.new(0, 100, 0, (30*(i-1))+10);
			})
			generaltab:Add("ImageLabel", {
				Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size420x420);
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(0, 90, 0, 90);
				Position = UDim2.new(0, 195, 0, (30*(i-1))+10);
			})
		end)


		generaltab:ResizeCanvas(false, true, false, false, 5, 5)
	end
	
	window:Ready()

	do
		local i = 1
		local function addBackgroundEntry(name, value, toolTip)
			local entry = backgroundtab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add("TextLabel", {
				Text = " "..value.."  ";
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -120, 0, 0);
				TextXAlignment = "Right";
			})
			i = i + 1
		end

		addBackgroundEntry("Safe Chat Enabled:", boolToStr(data.SafeChat), "Does the player have safe chat enabled?")
		addBackgroundEntry("Locale ID:", player.LocaleId, "The player's locale ID")
		addBackgroundEntry("Country/Region Code:", data.Code, "The player's country or region code based on geolocation")
		addBackgroundEntry("Is Roblox Staff:", boolToStr(player:IsInGroup(1200769) or player:IsInGroup(2868472)), "Is the player an official Roblox employee?")

		backgroundtab:ResizeCanvas(false, true, false, false, 5, 5)
	end

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
		local friendInfo = {}

		for item, pageNo in iterPageItems(friendPages) do
			table.insert(sortedFriends, item.Username)
			friendInfo[item.Username] = {id=item.Id;displayName=item.DisplayName;isOnline=item.IsOnline;}
		end

		table.sort(sortedFriends)

		local i = 2
		local friendCount = 0
		local onlineCount = 0
		for _, friendName in ipairs(sortedFriends) do
			friendCount = friendCount + 1
			local entryText = ""
			if friendName == friendInfo[friendName].displayName then
				entryText = friendName
			else
				entryText = friendName.." ("..friendInfo[friendName].displayName..")"
			end
			local entry = friendstab:Add("TextLabel", {
				Text = "             "..entryText;
				ToolTip = "ID: "..friendInfo[friendName].id;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			if friendInfo[friendName].isOnline then
				onlineCount = onlineCount + 1
				entry:Add("TextLabel", {
					Text = " Online  ";
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 120, 1, 0);
					Position = UDim2.new(1, -120, 0, 0);
					TextXAlignment = "Right";
				})
			end
			spawn(function()
				entry:Add("ImageLabel", {
					Image = game:GetService("Players"):GetUserThumbnailAsync(friendInfo[friendName].id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 30, 0, 30);
					Position = UDim2.new(0, 0, 0, 0);
				})
			end)
			i = i + 1
		end

		friendstab:Add("TextLabel", {
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			Text = friendCount.." Friends | "..onlineCount.." Online";
		})

		friendstab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	do
		local i = 1
		local function addAdonisEntry(name, value, toolTip)
			local entry = adonistab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add("TextLabel", {
				Text = " "..value.."  ";
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -120, 0, 0);
				TextXAlignment = "Right";
			})
			i = i + 1
		end

		addAdonisEntry("Admin Level:", data.AdminLevel, "The player's Adonis rank")
		addAdonisEntry("Donor:", boolToStr(data.IsDonor), "Is the player an Adonis donor?")
		addAdonisEntry("Muted:", boolToStr(data.IsMuted), "Is the player muted? (IGNORES TRELLO MUTELIST)")
		addAdonisEntry("Banned:", boolToStr(data.IsBanned), "Is the player banned? (IGNORES TRELLO BANLIST)")

		adonistab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	do
		local i = 1
		local function addGameEntry(name, value, toolTip)
			local entry = gametab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add("TextLabel", {
				Text = " "..value.."  ";
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -120, 0, 0);
				TextXAlignment = "Right";
			})
			i = i + 1
		end

		addGameEntry("Character Appearance ID:", player.CharacterAppearanceId, "The player's character appearance ID")
		addGameEntry("Auto Jump Enabled:", boolToStr(player.AutoJumpEnabled), "Does the player have auto jump enabled?")
		addGameEntry("Camera Max Zoom Distance:", tostring(player.CameraMaxZoomDistance), "How far in studs the player can zoom their camera")
		addGameEntry("Camera Min Zoom Distance:", tostring(player.CameraMinZoomDistance), "How close in studs the player can zoom their camera")
		addGameEntry("Gameplay Paused:", boolToStr(player.GameplayPaused), "Is the player's gameplay paused?")
		addGameEntry("Character Exists:", boolToStr(player.Character), "Does the player have a character?")

		local tools = {}
		table.insert(tools,{Text="==== "..player.Name.."'s Tools ====",Desc=player.Name:lower()})
		for k,t in pairs(player.Backpack:children()) do
			if t:IsA("Tool") then
				table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | ToolTip: "..t.ToolTip.." | Name: "..t.Name})
			elseif t:IsA("HopperBin") then
				table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | BinType: "..tostring(t.BinType).." | Name: "..t.Name})
			else
				table.insert(tools,{Text=t.Name,Desc="Class: "..t.ClassName.." | Name: "..t.Name})
			end
		end

		gametab:Add("TextButton", {
			Text = "View Tools";
			BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
			Size = UDim2.new(1, -10, 0, 35);
			Position = UDim2.new(0, 5, 0, (30*(i-1))+10);
			OnClicked = function()
				client.UI.Make("List", {
					Title = player.Name;
					Table = tools;
				})
			end
		})

		gametab:ResizeCanvas(false, true, false, false, 5, 5)
	end
end
