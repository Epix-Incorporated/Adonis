client = nil
service = nil

local function boolToStr(bool)
	if bool then
		return "Yes"
	else
		return "No"
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
		Size  = {420, 360};
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

	local groupstab = tabFrame:NewTab("Groups", {
		Text = "Groups"
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
		addGeneralEntry("Account Age:", player.AccountAge .. " days ("..string.format("%.2f", player.AccountAge/365).." years)", "How long the player has been registered on Roblox")
		addGeneralEntry("Membership:", player.MembershipType.Name, "The player's Roblox membership type")
		i = i + 1
		addGeneralEntry("Safe Chat Enabled:", boolToStr(data.SafeChat), "Does the player have safe chat enabled?")
		addGeneralEntry("Can Chat:", boolToStr(data.CanChat), "Does the player's account settings allow them to chat?")
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
				entryText = friendInfo[friendName].displayName.." (@"..friendName..")"
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
			Text = friendCount.." Friend(s) | "..onlineCount.." Online";
		})

		friendstab:ResizeCanvas(false, true, false, false, 5, 5)
	end
	

	local sortedGroups = {}           -- Putting this code outside the DO for groupstab
	local groupInfoRef = {}           -- because it'll be used by adonistab later to
	for _, groupInfo in pairs(service.GroupService:GetGroupsAsync(player.UserId) or {}) do -- get the Epix Incorporated group logo.
		table.insert(sortedGroups, groupInfo.Name)
		groupInfoRef[groupInfo.Name] = {Id=groupInfo.Id;Rank=groupInfo.Rank;Role=groupInfo.Role;IsPrimary=groupInfo.IsPrimary;EmblemUrl=groupInfo.EmblemUrl}
	end
	table.sort(sortedGroups)
	
	do
		local i = 2
		local groupCount = 0
		local ownCount = 0
		for _, groupName in ipairs(sortedGroups) do
			local groupInfo = groupInfoRef[groupName]
			groupCount = groupCount + 1
			if groupInfo.Rank == 255 then
				ownCount = ownCount + 1
			end
			local entry = groupstab:Add("TextLabel", {
				Text = "             "..groupName.." ";
				ToolTip = "ID: "..groupInfo.Id.." | Rank: "..groupInfo.Rank.." | Is Primary Group: "..boolToStr(groupInfo.IsPrimary);
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})
			entry:Add("TextLabel", {
				Text = " "..groupInfo.Role.."  ";
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 120, 1, 0);
				Position = UDim2.new(1, -120, 0, 0);
				TextXAlignment = "Right";
			})
			spawn(function()
				entry:Add("ImageLabel", {
					Image = groupInfo.EmblemUrl;
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 30, 0, 30);
					Position = UDim2.new(0, 0, 0, 0);
				})
			end)
			i = i + 1
		end

		groupstab:Add("TextLabel", {
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			Text = "Member of "..#sortedGroups-ownCount.." groups | Owner of "..ownCount.." groups";
		})

		groupstab:ResizeCanvas(false, true, false, false, 5, 5)
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
		addAdonisEntry("Donor:", boolToStr(data.IsDonor), "Is the player an Adonis Donor?")
		addAdonisEntry("Muted:", boolToStr(data.IsMuted), "Is the player muted? (IGNORES TRELLO MUTELIST)")
		addAdonisEntry("Banned:", boolToStr(data.IsBanned), "Is the player banned? (IGNORES TRELLO BANLIST)")

		local extrainfo = nil
		if player:GetRankInGroup(886423) == 10 then
			extrainfo = "User has contributed to Adonis via GitHub"
		elseif player:GetRankInGroup(886423) == 12 then
			extrainfo = "User is an official developer of Adonis"
		elseif player.UserId == 698712377 or player.UserId == 1237666 then
			extrainfo = "You are inspecting Sceleratis/Davey_Bones (Adonis creator)!"
		end
		if extrainfo then
			adonistab:Add("TextLabel", {
				Size = UDim2.new(1, -10, 0, 25);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				BackgroundTransparency = 0.5;
				Text = extrainfo;
			}):Add("ImageLabel", {
				Image = groupInfoRef["Epix Incorporated"].EmblemUrl;
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 21, 0, 21);
				Position = UDim2.new(0, 4, 0, 2);
			})
		end

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
		for k,t in pairs(player.Backpack:GetChildren()) do
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
