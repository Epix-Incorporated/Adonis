client = nil
service = nil

local function boolToStr(bool)
	if bool then
		return "Yes"
	else
		return "No"
	end
end

local function formatColor3(color)
	return "RGB "..math.floor(color.r*255)..", "..math.floor(color.g*255)..", "..math.floor(color.b*255)
end

return function(data)

	local window = client.UI.Make("Window", {
		Name  = "ServerDetails";
		Title = "Server Details";
		Size  = {420, 360};
		AllowMultiple = false;
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local overviewtab = tabFrame:NewTab("Overview", {
		Text = "Overview"
	})

	local playerstab = tabFrame:NewTab("Players", {
		Text = "Players"
	})

	local workspacetab = tabFrame:NewTab("Workspace", {
		Text = "Workspace"
	})

	local securitytab = tabFrame:NewTab("Security", {
		Text = "Security"
	})

	do

		local function getServerType()
			if game:GetService("RunService"):IsStudio() then
				return "Studio"
			else
				if data.PrivateServerId ~= "" then
					if data.PrivateServerOwnerId ~= 0 then
						return "Private"
					else
						return "Reserved"
					end
				else
					return "Standard"
				end
			end
		end






		local i = 1
		local function addOverviewEntry(name, value, toolTip)
			local entry = overviewtab:Add("TextLabel", {
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

		addOverviewEntry("Place Name:", service.MarketPlace:GetProductInfo(game.PlaceId).Name)
		addOverviewEntry("Place ID:", game.PlaceId)
		addOverviewEntry("Place Version:", game.PlaceVersion)
		addOverviewEntry("Game ID:", game.GameId)
		addOverviewEntry("Creator:", service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name.." ("..data.CreatorId..")")
		addOverviewEntry("Creator Type:", string.sub((tostring(game.CreatorType)), 18))
		--[[if game.Genre then
			addOverviewEntry("Genre:", tostring(game.Genre))
		end]]
		i = i + 1
		addOverviewEntry("Job ID:", game.JobId or "[Error]")
		addOverviewEntry("Server Type:", getServerType())
		if getServerType() == "Reserved" then
			addOverviewEntry("Private Server ID:", data.PrivateServerId)
		elseif getServerType() == "Private" then
			addOverviewEntry("Private Server ID:", data.PrivateServerId)
			addOverviewEntry("Private Server Owner:", (game:GetService("Players"):GetNameFromUserIdAsync(data.PrivateServerOwnerId) or "[Unknown Username]").." ("..game.PrivateServerOwnerId..")")
		end
		if data.ServerInternetInfo then
			--Server Internet Info
			local serii = data.ServerInternetInfo
			addOverviewEntry("Timezone:", serii.timezone or "[Error]")
			addOverviewEntry("Country:", serii.country or "[Error]")
			if game:GetService("RunService"):IsStudio() then else
				addOverviewEntry("Region:", serii.region or "[Error]")
				addOverviewEntry("City:", serii.city or "[Error]")
			  addOverviewEntry("Zipcode:", serii.zipcode or "[Error]")
				addOverviewEntry("IP Address:", serii.query or "[Error]")
				addOverviewEntry("Coordinates:", serii.coords or "[Error]") --"0 LAT 0 LON"
				--Sensitive Data when running on studio
			end
		end
		i = i + 1
		addOverviewEntry("Server Speed:", math.round(workspace:GetRealPhysicsFPS()))
		addOverviewEntry("Server Start Time:", data.ServerStartTime)
		addOverviewEntry("Server Age:", data.ServerAge)

		overviewtab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	do
		local i = 1
		local function addWorkspaceEntry(name, valueType, value, toolTip)
			local entry = workspacetab:Add("TextLabel", {
				Text = "  "..name.." ";
				ToolTip = toolTip;
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
				TextXAlignment = "Left";
			})

			i = i + 1
			return entry:Add(valueType, value)
		end

		addWorkspaceEntry("Streaming Enabled:", "TextLabel", {Text = " "..boolToStr(workspace.StreamingEnabled).."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addWorkspaceEntry("Interpolation Throttling:", "TextLabel", {Text = " "..string.sub(tostring(workspace.InterpolationThrottling),34).."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addWorkspaceEntry("Gravity:", "TextLabel", {Text = " "..workspace.Gravity.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -125, 0, 0);TextXAlignment = "Right";})
		addWorkspaceEntry("Fallen Parts Destroy Height:", "TextLabel", {Text = " "..workspace.FallenPartsDestroyHeight.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -125, 0, 0);TextXAlignment = "Right";})
		i = i + 1
		addWorkspaceEntry("Objects:", "TextLabel", {Text = " "..data.ObjectCount.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addWorkspaceEntry("Cameras:", "TextLabel", {Text = " "..data.CameraCount.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})
		addWorkspaceEntry("Nil Players:", "TextLabel", {Text = " "..data.NilPlayerCount.."  ";BackgroundTransparency = 1;Size = UDim2.new(0, 120, 1, 0);Position = UDim2.new(1, -120, 0, 0);TextXAlignment = "Right";})

		if client.Remote.Get("AdminLevel") >= 300 then
			workspacetab:Add("TextButton", {
				Text = "Open Game Explorer";
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 35);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+10);
				OnClicked = function()
					client.UI.Make("Explorer", {})
				end
			})
		else
			workspacetab:Add("TextButton", {
				Text = "Open Game Explorer (Insufficient Permissions)";
				BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				Size = UDim2.new(1, -10, 0, 35);
				Position = UDim2.new(0, 5, 0, (30*(i-1))+10);
				AutoButtonColor = false
			})
		end

		workspacetab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	do

		local Players = service.Players
		local sortedPlayers = {}

		for _, player in ipairs(Players:GetPlayers()) do
			table.insert(sortedPlayers, player.Name)
		end

		table.sort(sortedPlayers)

		local i = 2
		local playerCount = 0
		local adminCount = 0
		for _, playerName in ipairs(sortedPlayers) do
			local entryText = ""
			local player = Players:FindFirstChild(playerName);
			if player then
				if playerName == player.DisplayName then
					entryText = playerName
				else
					entryText = player.DisplayName.." (@"..playerName..")"
				end

				local entry = playerstab:Add("TextLabel", {
					Text = "             "..entryText;
					ToolTip = "ID: "..Players[playerName].UserId;
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
					TextXAlignment = "Left";
					--[[OnClicked = function()
						client.Remote.Send("InspectPlayer")
					end;]]
				})

				local subEntryText = data.Admins[playerName]
				if subEntryText and subEntryText ~= "Player" then
					adminCount = adminCount + 1

					if table.find(data.Donors, playerName) then
						subEntryText = subEntryText.." | Donor"
					end

					entry:Add("TextLabel", {
						Text = " "..subEntryText.."  ";
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						TextXAlignment = "Right";
					})
				elseif table.find(data.Donors, playerName) then
					playerCount = playerCount + 1
					entry:Add("TextLabel", {
						Text = " Donor  ";
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						TextXAlignment = "Right";
					})
				else
					playerCount = playerCount + 1
				end

				spawn(function()
					entry:Add("ImageLabel", {
						Image = game:GetService("Players"):GetUserThumbnailAsync(Players[playerName].UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 30, 0, 30);
						Position = UDim2.new(0, 0, 0, 0);
					})
				end)
				i = i + 1
			end
		end

		playerstab:Add("TextLabel", {
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			Text = "Players: "..playerCount.." | Admins: "..adminCount.." | Donors: "..#data.Donors;
		})
	end

	do
		local i = 1
		local function addSecurityEntry(name, value, toolTip)
			local entry = securitytab:Add("TextLabel", {
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

		addSecurityEntry("HTTP Service:", boolToStr(data.HttpEnabled))
		addSecurityEntry("Loadstring Enabled:", boolToStr(data.LoadstringEnabled))

		securitytab:ResizeCanvas(false, true, false, false, 5, 5)
	end

	window:Ready()
end
