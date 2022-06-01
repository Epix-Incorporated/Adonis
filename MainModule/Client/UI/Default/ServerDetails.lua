client, service = nil, nil

local function boolToStr(bool)
	if bool then
		return "Yes"
	else
		return "No"
	end
end

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local genPlayerList = nil
	local genWorkspaceInfo = nil
	local window = client.UI.Make("Window", {
		Name  = "ServerDetails";
		Title = "Server Details";
		Icon = client.MatIcons.Topic;
		Size  = {420, 360};
		MinSize = {374, 155};
		AllowMultiple = false;
		OnRefresh = function()
			local newData = client.Remote.Get("UpdateList", "ServerDetails")
			if newData then
				data.Refreshables = newData
				genPlayerList()
				genWorkspaceInfo()
			else
				client.UI.Make("Output", {Message = "Error fetching data; try again later";})
			end
		end;
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	local overviewtab = tabFrame:NewTab("Overview", {
		Text = "Overview"
	})

	local locationtab = tabFrame:NewTab("Location", {
		Text = "Location"
	})

	local playerstab = tabFrame:NewTab("Players", {
		Text = "Players"
	})

	local workspacetab = tabFrame:NewTab("Workspace", {
		Text = "Workspace"
	})

	if data.Refreshables.WorkspaceInfo then
		window:AddTitleButton({
			Text = "";
			ToolTip = "Advanced stats";
			OnClick = function()
				client.Remote.Send("ProcessCommand", data.CmdPrefix.."perfstats")
			end
		}):Add("ImageLabel", {
			Size = UDim2.new(0, 18, 0, 18);
			Position = UDim2.new(0, 6, 0, 1);
			Image = client.MatIcons.Leaderboard;
			BackgroundTransparency = 1;
		})
		window:AddTitleButton({
			Text = "";
			ToolTip = "Game explorer";
			OnClick = function()
				client.Remote.Send("ProcessCommand", data.CmdPrefix.."explorer")
			end
		}):Add("ImageLabel", {
			Size = UDim2.new(0, 18, 0, 18);
			Position = UDim2.new(0, 6, 0, 1);
			Image = client.MatIcons.Folder;
			BackgroundTransparency = 1;
		})
	end

	do

		local serverType = "[Error]"
		if service.RunService:IsStudio() then
			serverType = "Studio"
		else
			if data.PrivateServerId ~= "" then
				if data.PrivateServerOwnerId ~= 0 then
					serverType = "Private"
				else
					serverType = "Reserved"
				end
			else
				serverType = "Standard"
			end
		end

		local entries = {
			{"Game ID", game.GameId},
			{"Game Creator", service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name.." (#"..data.CreatorId..")"},
			-- selene: allow(incorrect_standard_library_use)
			{"Creator Type", game.CreatorType.Name},
			{"Place ID", game.PlaceId},
			{"Place Name", service.MarketPlace:GetProductInfo(game.PlaceId).Name or "[Error]"},
			{"Place Version", game.PlaceVersion},
			"",
			{"Server Job ID", game.JobId or "[Error]"},
			{"Server Type", serverType},
			"",
			{"Server Speed", "Loading..."},
			{"Server Age", "Loading..."},
			{"Server Start Time", service.FormatTime(data.ServerStartTime, true)}
		}

		if serverType == "Reserved" then
			table.insert(entries, 10, {"Private Server ID", data.PrivateServerId})
		elseif serverType == "Private" then
			table.insert(entries, 10, {"Private Server ID", data.PrivateServerId})
			table.insert(entries, 11, {"Private Server Owner", (service.Players:GetNameFromUserIdAsync(data.PrivateServerOwnerId) or "[Unknown Username]").." ("..data.PrivateServerOwnerId..")"})
		end

		local i, currentPos = 0, 0
		local displays = {}
		for _, v in ipairs(entries) do
			if type(v) == "table" then
				i += 1
				displays[v[1]] = overviewtab:Add("TextLabel", {
					Text = "  "..v[1]..":";
					ToolTip = v[3];
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, currentPos+5);
					TextXAlignment = "Left";
				}):Add("TextLabel", {
					Text = v[2];
					BackgroundTransparency = 1;
					AnchorPoint = Vector2.new(1, 0);
					Size = UDim2.new(1, -150, 1, 0);
					Position = UDim2.new(1, -5, 0, 0);
					TextXAlignment = "Right";
					TextEditable = false;
					ClearTextOnFocus = false;
				})
				currentPos += 30
			else
				currentPos += 10
			end
		end

		overviewtab:ResizeCanvas(false, true, false, false, 5, 5)

		spawn(function()
			while wait(0.5) do
				local timeNow = os.time()
				if not displays["Server Speed"] or not displays["Server Age"] then break end
				displays["Server Speed"].Text = math.round(service.Workspace:GetRealPhysicsFPS())
				displays["Server Age"].Text = string.format("%ds (%d min)", string.format(timeNow - data.ServerStartTime, "%.1f"), math.round((timeNow - data.ServerStartTime)/60))
			end
		end)

	end

	do

		local function show()
			local entries = {}
			if data.ServerInternetInfo then
				local serii = data.ServerInternetInfo
				for _, v in ipairs({
					{"Timezone", serii.timezone or "[Error]"},
					{"Country", serii.country or "[Error]"},
					{"Region", serii.region or "[Error]"},
					{"City", serii.city or "[Error]"},
					{"Zipcode", serii.zipcode or "[Error]"},
					{"IP Address", serii.query or "[Error]"},
					{"Coordinates", serii.coords or "[Error]"},
					}) do table.insert(entries, v) end
			else
				table.insert(entries, {"Error: Unable to retrieve server location info", "HTTP requests may be disabled for this game."})
			end

			local i = 1
			for _, v in ipairs(entries) do
				locationtab:Add("TextLabel", {
					Text = "  "..v[1]..":";
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
					TextXAlignment = "Left";
				}):Add("TextLabel", {
					Text = v[2];
					BackgroundTransparency = 1;
					AnchorPoint = Vector2.new(1, 0);
					Size = UDim2.new(1, -150, 1, 0);
					Position = UDim2.new(1, -5, 0, 0);
					TextXAlignment = "Right";
				})
				i += 1
			end

			locationtab:Add("TextLabel", {
				Text = "Server IP and coordinates are only shown to admins.";
				TextWrapped = true;
				TextYAlignment = "Top";
				BackgroundTransparency = 1;
				Size = UDim2.new(1, -10, 0, 40);
				Position = UDim2.new(0, 5, 0, i*30);
			})

			locationtab:ResizeCanvas(false, true, false, false, 5, 5)
		end

		if service.RunService:IsStudio() then
			local notice = locationtab:Add("TextLabel", {
				Text = "Server location info has been hidden in a Studio environment for your privacy, since it may be based on your device's location.";
				BackgroundTransparency = 0.4;
				Size = UDim2.new(1, -10, 0, 80);
				Position = UDim2.new(0, 5, 0, 5);
				TextXAlignment = "Left";
				TextYAlignment = "Top";
				TextWrapped = true;
			})
			notice:Add("UIPadding", {
				PaddingLeft = UDim.new(0, 5);PaddingRight = UDim.new(0, 5);PaddingTop = UDim.new(0, 5);PaddingBottom = UDim.new(0, 5);
			})
			notice:Add("ImageLabel", {
				Image = client.MatIcons["Privacy tip"];
				ImageTransparency = 0.2;
				BackgroundTransparency = 1;
				Size = UDim2.new(0, 24, 0, 24);
				Position = UDim2.new(1, -140, 1, -28);
			})
			notice:Add("TextButton", {
				Text = "Show Anyway";
				Size = UDim2.new(0, 110, 0, 30);
				Position = UDim2.new(1, -110, 1, -30);
				TextXAlignment = "Center";
				OnClick = function()
					show()
					notice:Destroy()
				end
			})
		else
			show()
		end

	end

	do

		local search = playerstab:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 25);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			TextStrokeTransparency = 0.8;
		})
		search:Add("ImageLabel", {
			Image = client.MatIcons.Search;
			Position = UDim2.new(1, -21, 0, 3);
			Size = UDim2.new(0, 18, 0, 18);
			ImageTransparency = 0.2;
			BackgroundTransparency = 1;
		})
		local scroller = playerstab:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 2;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 32);
			Size = UDim2.new(1, -10, 1, -37);
		})

		local playerCount, adminCount = 0, 0
		function genPlayerList()
			local filter = search.Text

			playerCount, adminCount = 0, 0
			local sortedPlayers = {}
			for _, player in ipairs(service.Players:GetPlayers()) do
				table.insert(sortedPlayers, player.Name)
			end
			table.sort(sortedPlayers)

			local i = 1
			scroller:ClearAllChildren()
			for _, playerName in ipairs(sortedPlayers) do
				local player: Player = service.Players:FindFirstChild(playerName)
				if not player then continue end
				if not (playerName:sub(1, #filter):lower() == filter:lower() or (player.DisplayName:sub(1, #filter):lower() == filter:lower())) then continue end
				local entry = scroller:Add("TextButton", {
					Text = "           "..service.FormatPlayer(player);
					ToolTip = "User ID: "..service.Players[playerName].UserId.." [Click to open profile]";
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, 0, 0, 30);
					Position = UDim2.new(0, 0, 0, (30*(i-1))+5);
					TextXAlignment = "Left";
					OnClicked = function()
						client.Remote.Send("ProcessCommand", data.CmdPlayerPrefix.."profile"..data.SplitKey..playerName)
						window:Close()
					end;
				})

				local subEntryText = data.Refreshables.Admins and data.Refreshables.Admins[playerName]
				if subEntryText and subEntryText ~= "Player" then
					adminCount += 1

					if table.find(data.Refreshables.Donors, playerName) then
						subEntryText ..= " | Donor"
					end

					entry:Add("TextLabel", {
						Text = " "..subEntryText.."  ";
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						TextXAlignment = "Right";
					})
				elseif table.find(data.Refreshables.Donors, playerName) then
					playerCount += 1
					entry:Add("TextLabel", {
						Text = " Donor  ";
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						TextXAlignment = "Right";
					})
				else
					playerCount += 1
				end

				spawn(function()
					entry:Add("ImageLabel", {
						Image = service.Players:GetUserThumbnailAsync(service.Players[playerName].UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48);
						BackgroundTransparency = 1;
						Size = UDim2.new(0, 30, 0, 30);
						Position = UDim2.new(0, 0, 0, 0);
					})
				end)
				i += 1
			end
			if data.Refreshables.Admins then
				scroller:Add("TextLabel", {
					Text = "Note: Only admins can see other admins' permission level.";
					TextWrapped = true;
					TextYAlignment = "Top";
					BackgroundTransparency = 1;
					Size = UDim2.new(1, -10, 0, 40);
					Position = UDim2.new(0, 5, 0, i*30);
				})
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 5)
			search.PlaceholderText = "Players: "..playerCount..(data.Refreshables.Admins and " | Admins: "..adminCount or "").." | Donors: "..#data.Refreshables.Donors
		end

		search:GetPropertyChangedSignal("Text"):Connect(function()
			genPlayerList()
		end)

		genPlayerList()
	end

	function genWorkspaceInfo()
		workspacetab:ClearAllChildren()
		local workspaceInfo = data.Refreshables.WorkspaceInfo
		if workspaceInfo then
			local i, currentPos = 0, 0
			for _, v in ipairs({
				{"Streaming Enabled", boolToStr(service.Workspace.StreamingEnabled)},
				{"Interpolation Throttling", service.Workspace.InterpolationThrottling.Name},
				{"Gravity", service.Workspace.Gravity},
				{"Fallen Parts Destroy Height", service.Workspace.FallenPartsDestroyHeight},
				{"Adonis Objects", workspaceInfo.ObjectCount},
				{"Adonis Cameras", workspaceInfo.CameraCount},
				{"Nil Players", workspaceInfo.NilPlayerCount},
				"",
				{"HTTP Service Enabled", boolToStr(workspaceInfo.HttpEnabled)},
				{"Loadstring Enabled", boolToStr(workspaceInfo.LoadstringEnabled)},
				"",
				}) do
				if type(v) == "table" then
					i += 1
					workspacetab:Add("TextLabel", {
						Text = "  "..v[1]..":";
						ToolTip = v[3];
						BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
						Size = UDim2.new(1, -10, 0, 25);
						Position = UDim2.new(0, 5, 0, currentPos+5);
						TextXAlignment = "Left";
					}):Add("TextLabel", {
						Text = v[2];
						BackgroundTransparency = 1;
						AnchorPoint = Vector2.new(1, 0);
						Size = UDim2.new(1, -150, 1, 0);
						Position = UDim2.new(1, -5, 0, 0);
						TextXAlignment = "Right";
					})
					currentPos += 25
				else
					currentPos += 10
				end
			end

			workspacetab:Add("TextLabel", {
				Text = "Click on the title bar buttons to view technical performance statistics or to open the game hierarchy explorer. (Permission-locked)";
				TextWrapped = true;
				TextYAlignment = "Top";
				BackgroundTransparency = 1;
				Size = UDim2.new(1, -10, 0, 40);
				Position = UDim2.new(0, 5, 0, currentPos+10);
			})

			workspacetab:ResizeCanvas(false, true, false, false, 5, 5)
		else
			workspacetab:Disable()
		end
	end
	genWorkspaceInfo()

	window:Ready()
end
