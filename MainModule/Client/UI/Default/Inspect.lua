-- Expertcoder2
-- Created 20/03/2021
-- Updated 28/03/2021


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

local function assetTypeToStr(int)
	return ({
		[2] = "T-Shirt";
		[8] = "Hat";
		[11] = "Shirt";
		[12] = "Pants";
		[17] = "Head";
		[18] = "Face";
		[19] = "Gear";
		[27] = "Torso";
		[28] = "Right Arm";
		[29] = "Left Arm";
		[30] = "Left Leg";
		[31] = "Right Leg";
		[41] = "Hair";
		[42] = "Face Accessory";
		[42] = "Face Accessory";
		[43] = "Neck Accessory";
		[44] = "Shoulder Accessory";
		[45] = "Front Accessory";
		[46] = "Back Accessory";
		[47] = "Waist Accessory";
		[48] = "Climb Animation";
		[49] = "Death Animation";
		[50] = "Fall Animation";
		[51] = "Idle Animation";
		[52] = "Jump Animation";
		[53] = "Run Animation";
		[54] = "Swim Animation";
		[55] = "Walk Animation";
		[56] = "Pose Animation";
		[61] = "Emote Animation";

	})[int] or "Unknown"
end

local function formatColor3(color)
	return "RGB "..math.floor(color.r*255)..", "..math.floor(color.g*255)..", "..math.floor(color.b*255)
end

return function(data)
	local player = data.Target

	local window = client.UI.Make("Window", {
		Name  = "Inspect_"..player.UserId;
		Title = "Inspect ("..player.Name..")";
		Size  = {400, 360};
		AllowMultiple = false;
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local generaltab = tabFrame:NewTab("General", {
		Text = "General"
	})

	local avatartab = tabFrame:NewTab("Avatar", {
		Text = "Avatar"
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
		addGeneralEntry("Safe Chat Enabled:", boolToStr(data.SafeChat), "Does the player have safe chat enabled?")
		addGeneralEntry("Can Chat:", boolToStr(data.CanChat), "Does the player's account settings allow them to chat?")
		addGeneralEntry("Locale ID:", player.LocaleId, "The player's locale ID")
		addGeneralEntry("Country/Region Code:", data.Code, "The player's country or region code based on geolocation")
		addGeneralEntry("Is Roblox Staff:", boolToStr(player:IsInGroup(1200769) or player:IsInGroup(2868472)), "Is the player an official Roblox employee?")

		generaltab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	window:Ready()

	do
		local i = 1
		local function addAvatarEntry(name, valueType, value, toolTip)
			local entry = avatartab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add(valueType, value)

			i = i + 1
		end
		
		local humDesc = game:GetService("Players"):GetHumanoidDescriptionFromUserId(player.UserId)
		
		addAvatarEntry("Head Shot Thumbnail:", "ImageLabel", {BackgroundTransparency = 1;Size = UDim2.new(0, 30, 1, 0);Position = UDim2.new(1, -30, 0, 0);Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);})
		addAvatarEntry("Avatar Bust Thumbnail:", "ImageLabel", {BackgroundTransparency = 1;Size = UDim2.new(0, 30, 1, 0);Position = UDim2.new(1, -30, 0, 0);Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48);})
		addAvatarEntry("Avatar Thumbnail:", "ImageLabel", {BackgroundTransparency = 1;Size = UDim2.new(0, 30, 1, 0);Position = UDim2.new(1, -30, 0, 0);Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size48x48);})
		addAvatarEntry("Body Type Scale:", "TextLabel", {Text = " "..humDesc.BodyTypeScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "The factor by which the shape of the Humanoid rig is interpolated from the standard R15 body shape shape (0) to a taller and more slender body type (1)")
		addAvatarEntry("Depth Scale:", "TextLabel", {Text = " "..humDesc.DepthScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "The factor by which the depth (back-to-front distance) of the Humanoid rig is scaled")
		addAvatarEntry("Height Scale:", "TextLabel", {Text = " "..humDesc.HeightScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "The factor by which the height (top-to-bottom distance) of the Humanoid rig is scaled")
		addAvatarEntry("Width Scale:", "TextLabel", {Text = " "..humDesc.WidthScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "The factor by which the width (left-to-right distance) of the Humanoid is scaled")
		addAvatarEntry("Head Scale:", "TextLabel", {Text = " "..humDesc.HeadScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "The factor the Head of the Humanoid is scaled")
		addAvatarEntry("Proportion Scale:", "TextLabel", {Text = " "..humDesc.ProportionScale.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "How wide (0) or narrow (1) the Humanoid rig is")
		addAvatarEntry("Head Color:", "TextLabel", {Text = " "..formatColor3(humDesc.HeadColor).."  ";TextColor3=humDesc.HeadColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addAvatarEntry("Torso Color:", "TextLabel", {Text = " "..formatColor3(humDesc.TorsoColor).."  ";TextColor3=humDesc.TorsoColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addAvatarEntry("Left Arm Color:", "TextLabel", {Text = " "..formatColor3(humDesc.LeftArmColor).."  ";TextColor3=humDesc.LeftArmColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addAvatarEntry("Right Arm Color:", "TextLabel", {Text = " "..formatColor3(humDesc.RightArmColor).."  ";TextColor3=humDesc.RightArmColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addAvatarEntry("Left Leg Color:", "TextLabel", {Text = " "..formatColor3(humDesc.LeftLegColor).."  ";TextColor3=humDesc.LeftLegColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addAvatarEntry("Right Leg Color:", "TextLabel", {Text = " "..formatColor3(humDesc.RightLegColor).."  ";TextColor3=humDesc.RightLegColor;BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})

		avatartab:ResizeCanvas(false, true, false, false, 5, 5)

		i = i + 1

		spawn(function()
			for _, category in ipairs({{humDesc.ClimbAnimation,humDesc.Face,humDesc.FallAnimation,humDesc.Head,humDesc.IdleAnimation,humDesc.JumpAnimation,humDesc.LeftArm,humDesc.LeftLeg,humDesc.Pants,humDesc.RightArm,humDesc.RightLeg,humDesc.RunAnimation,humDesc.Shirt,humDesc.SwimAnimation,humDesc.Torso,humDesc.WalkAnimation},string.split(humDesc.BackAccessory),string.split(humDesc.FaceAccessory),string.split(humDesc.FrontAccessory),string.split(humDesc.HairAccessory),string.split(humDesc.HatAccessory),string.split(humDesc.ShouldersAccessory),string.split(humDesc.WaistAccessory),string.split(humDesc.NeckAccessory)}) do
				for _, itemId in ipairs(category) do
					if itemId and itemId ~= 0 and tonumber(itemId) ~= nil then
						local info = game:GetService("MarketplaceService"):GetProductInfo(itemId)
						addAvatarEntry(info.Name, "TextLabel", {Text = " "..assetTypeToStr(info.AssetTypeId).."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";}, "ID: "..itemId.." | Creator: "..(info.Creator.Name or ("[None]")).." | Price: "..(info.PriceInRobux or "0").." Robux")
					end
				end
			end

			avatartab:ResizeCanvas(false, true, false, false, 5, 5)
		end)

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

		addGameEntry("Source Place ID:", data.SourcePlace, "The ID of the place from which the player was teleported to this game, if applicable")
		addGameEntry("Character Appearance ID:", player.CharacterAppearanceId, "The player's character appearance ID")
		addGameEntry("Auto Jump Enabled:", boolToStr(player.AutoJumpEnabled), "Does the player have auto jump enabled?")
		addGameEntry("Camera Max Zoom Distance:", tostring(player.CameraMaxZoomDistance), "How far in studs the player can zoom their camera")
		addGameEntry("Camera Min Zoom Distance:", tostring(player.CameraMinZoomDistance), "How close in studs the player can zoom their camera")
		addGameEntry("Character Appearance ID:", player.CharacterAppearanceId, "The player's character appearance ID")
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
