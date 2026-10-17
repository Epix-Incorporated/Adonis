client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	local Owner = data.FromPlayer;
	local SessionKey = data.SessionKey;
	local SessionName = data.SessionName;
	local Channel = data.Channel;
	local CanManageUsers = data.CanManageUsers;

	local debounce, gTable, selectedPlayer = false, nil, nil
	local peerList, messageObjs = {}, {}

	local window, chatlog, reply, playerList, send, layout, sessionEvent, messageEvent, channelEvent;
	local systemMessage

	local function sendIt()
		local text = service.Trim(reply.Text)
		if text ~= "" and Channel then
			local commandToken = text:match("^(%S+)")
			local chatService = service.TextChatService
			if commandToken and chatService then
				for _, command in chatService:GetDescendants() do
					if command:IsA("TextChatCommand") and command.Enabled then
						for _, alias in {command.PrimaryAlias, command.SecondaryAlias} do
							if type(alias) == "string" and alias ~= "" then
								local token = commandToken
								if token:sub(1, 1) == "/" then
									token = token:sub(2)
								end
								local normalizedAlias = if alias:sub(1, 1) == "/" then alias:sub(2) else alias
								if string.lower(commandToken) == string.lower(alias)
									or string.lower(token) == string.lower(normalizedAlias) then
									systemMessage("Commands can't be sent as private chat messages.")
									return
								end
							end
						end
					end
				end
			end
			local ok, err = pcall(Channel.SendAsync, Channel, text)
			if not ok then
				systemMessage("Unable to send this message through Roblox chat.")
				warn(`Adonis private chat send failed: {tostring(err)}`)
			end
		elseif text ~= "" then
			systemMessage("Roblox chat is unavailable for this private conversation.")
		end
	end

	local function promptAddUser()
		local list = {}
		local searchBar, playerList

		local window = client.UI.Make("Window", {
			Name = "Add User";
			Title = "Add User";
			Size = {300, 400};
		})

		searchBar = window:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 30);
			Position = UDim2.new(0, 5, 0, 5);
			Text = "";
			PlaceholderText = "Search player...";
			ClearTextOnFocus = false;
		})

		playerList = window:Add("ScrollingFrame", {
			Size = UDim2.new(1, -10, 1, -45);
			Position = UDim2.new(0, 5, 0, 40);
			BackgroundTransparency = 0.9;
		})

		local function updateList()
			playerList:ClearAllChildren()
			local searchText = searchBar.Text:lower()
			local yPos = 0
			for _, v in service.Players:GetPlayers() do
				local good = true
				for _, peer in peerList do
					if peer.UserId == v.UserId then
						good = false
						break
					end
				end
				if good and (searchText == "" or v.Name:lower():find(searchText) or v.DisplayName:lower():find(searchText)) then
					local button = playerList:Add("TextButton", {
						Text = service.FormatPlayer(v);
						Size = UDim2.new(1, 0, 0, 30);
						Position = UDim2.new(0, 0, 0, yPos);
						BackgroundTransparency = 0.5;
					})
					button.MouseButton1Click:Connect(function()
						window:Close()
						client.Remote.Send("Session", SessionKey, "AddPlayerToSession", service.UnWrap(v))
					end)
					yPos = yPos + 35
				end
			end
			playerList.CanvasSize = UDim2.new(0, 0, 0, yPos)
		end

		searchBar:GetPropertyChangedSignal("Text"):Connect(updateList)
		updateList()

		window:Ready()
	end
	
	local function updatePeerList(peers)
		playerList:ClearAllChildren()
		peerList = peers

		local lObj = service.New("UIListLayout", {
			Parent = playerList;
			FillDirection = "Vertical";
			HorizontalAlignment = "Center";
			VerticalAlignment = "Top";
			SortOrder = "LayoutOrder";
		})

		for i,peer in peers do
			local pBut = playerList:Add("TextButton", {
				Text = service.FormatPlayer(peer);
				Size = UDim2.new(1, 0, 0, 25);
				TextScaled = true;
				TextWarped = true;
				BackgroundTransparency = 1;
			})

			if CanManageUsers then
				local ogColor = pBut.BackgroundColor3
				local lerpColor = ogColor:Lerp(Color3.fromRGB(9, 67, 255), 0.1)

				if peer.UserId and peer.UserId ~= service.Players.LocalPlayer.UserId then
					pBut.MouseButton1Down:Connect(function()
						for i,v in ipairs(playerList:GetChildren()) do
							if v:IsA("TextButton") or v:IsA("Frame") then
								v.BackgroundTransparency = 1
							end
						end

						selectedPlayer = peer
						pBut.BackgroundTransparency = 0
						pBut.BackgroundColor3 = lerpColor
					end)
				end
			end
		end

		playerList.CanvasSize = UDim2.new(0, 0, 0, lObj.AbsoluteContentSize.Y)
	end;

	function newMessage(data)
		local pName = data.PlayerName;
		local pDisplayName = pName ~= "*SYSTEM*" and data.PlayerDisplayName
		local msg = data.Message;
		local icon = data.Icon or 0;

		local newMsg

		if pName == "* SYSTEM *" then
			newMsg = chatlog:Add("Frame", {
				Size = UDim2.new(1, 0, 0, 25);
				BackgroundTransparency = 1;
				AutomaticSize = "Y";
				Children = {
					{ClassName = "Frame";
						Name = "CHATFRAME";
						Size = UDim2.new(1, -10, 1, -10);
						Position = UDim2.new(0, 5, 0, 5);
						BackgroundTransparency = 0.5;
						AutomaticSize = "Y";
						Children = {

							{ClassName = "TextLabel";
								Name = "PlayerName";
								Size = UDim2.new(0, 0, 0, 14);
								Position = UDim2.new(0, 1, 0, 1);
								Text = `   {pName}`;
								TextSize = "14";
								TextXAlignment = "Left";
								BackgroundTransparency = 1;
							};

							{ClassName = "TextLabel";
								Name = "Message";
								Size = UDim2.new(1, 0, 0, 10);
								Position = UDim2.new(0, 0, 0, 14);
								Text = `   {msg or "<font color='rgb(230,0,0)'>An error has occured</font>"}`;
								TextXAlignment = "Left";
								TextYAlignment = "Top";
								AutomaticSize = "Y";
								TextWrapped = true;
								TextScaled = false;
								RichText = true;
								BackgroundTransparency = 1;
							};
						}
					}
				}
			})
		else
			newMsg = chatlog:Add("Frame", {
				Size = UDim2.new(1, 0, 0, 50);
				BackgroundTransparency = 1;
				AutomaticSize = "Y";
				Children = {
					{ClassName = "Frame";
						Name = "CHATFRAME";
						Size = UDim2.new(1, -10, 1, -10);
						Position = UDim2.new(0, 5, 0, 5);
						BackgroundTransparency = 0.5;
						AutomaticSize = "Y";
						Children = {
							{ClassName = "ImageButton";
								Name = "Icon";
								Size = UDim2.new(0, 48, 0, 48);
								Position = UDim2.new(0, 1, 0, 1);
								Image = icon;
							};

							{ClassName = "TextLabel";
								Name = "PlayerName";
								Size = UDim2.new(1, -55, 0, 15);
								Position = UDim2.new(0, 55, 0, 0);
								Text = if pDisplayName then pDisplayName == pName and (`@{pName}`) or string.format("%s (@%s)", pDisplayName, pName) else pName;
								TextSize = "14";
								TextXAlignment = "Left";
								BackgroundTransparency = 1;
							};

							{ClassName = "TextLabel";
								Name = "Message";
								Size = UDim2.new(1, -55, 0, 10);
								Position = UDim2.new(0, 55, 0, 15);
								Text = msg;
								TextXAlignment = "Left";
								TextYAlignment = "Top";
								AutomaticSize = "Y";
								TextWrapped = true;
								TextScaled = false;
								RichText = data.RichText;
								BackgroundTransparency = 1;
							};
						}
					}
				}
			})
		end

		table.insert(messageObjs, newMsg)

		if #messageObjs > 200 then
			messageObjs[1]:Destroy()
			table.remove(messageObjs, 1)
		end
	end
	systemMessage = function(msg)
		newMessage({
			PlayerName = "* SYSTEM *";
			Message = msg;
			Icon = 0;
		})
	end

	if client.UI.Get(`PrivateChat{SessionName}`) then
		return
	end

	window = client.UI.Make("Window", {
		Name  = `"PrivateChat{SessionName}`;
		Title = "Private Chat";
		Icon = client.MatIcons.Forum;
		Size  = {500,300};
		OnClose = function()
			if sessionEvent then
				sessionEvent:Disconnect()
			end
			if messageEvent then
				messageEvent:Disconnect()
			end
			if channelEvent then
				channelEvent:Disconnect()
			end

			client.Remote.Send("Session", SessionKey, "LeaveSession")
		end;
	})

	chatlog = window:Add("ScrollingFrame", {
		Size = UDim2.new(1, -105, 1, -45);
		CanvasSize = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 0.9;
		AutomaticCanvasSize = "Y";
	})

	reply = window:Add("TextBox", {
		Text = "";
		PlaceholderText = "";
		Size = UDim2.new(1, -70, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		ClearTextOnFocus = false;
		TextScaled = true;
	})

	playerList = window:Add("ScrollingFrame", {
		Size = UDim2.new(0, 100, 1, -75);
		Position = UDim2.new(1, -100, 0, 0);
		BackgroundTransparency = 0.5;
		AutomaticCanvasSize = "Y";
	})

	local add = window:Add("TextButton", {
		Text = "+";
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(1, -100, 1, -70);
		OnClick = function()
			if CanManageUsers then
				promptAddUser()
			else
				systemMessage("<i>You are not allowed to manage users</i>")
			end
		end
	})

	local remove = window:Add("TextButton", {
		Text = "-";
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(1, -35, 1, -70);
		OnClick = function()
			if CanManageUsers then
				if selectedPlayer then
					client.Remote.Send("Session", SessionKey, "RemovePlayerFromSession", selectedPlayer)
					selectedPlayer = nil
				end
			else
				systemMessage("<i>You are not allowed to manage users</i>")
			end
		end
	})

	send = window:Add("TextButton", {
		Text = "Send";
		Size = UDim2.new(0, 60, 0, 30);
		Position = UDim2.new(1, -65, 1, -35);
		OnClick = function()
			sendIt()
			reply.Text = ""
		end
	})

	layout = service.New("UIListLayout", {
		Parent = chatlog;
		FillDirection = "Vertical";
		HorizontalAlignment = "Left";
		VerticalAlignment = "Top";
		SortOrder = "LayoutOrder";
	})

	send.BackgroundColor3 = send.BackgroundColor3:lerp(Color3.new(0,0,0), 0.1)
	reply.FocusLost:Connect(function(isEnter)
		if isEnter then
			sendIt()
			reply.Text = ""
			reply:CaptureFocus()
		end
	end)

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		chatlog.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		chatlog.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
	end)

	if Channel and Channel.MessageReceived then
		messageEvent = Channel.MessageReceived:Connect(function(message)
			if message.Status == Enum.TextChatMessageStatus.TextFilterFailed then
				local source = message.TextSource
				if source and source.UserId == service.Players.LocalPlayer.UserId then
					systemMessage("Roblox could not filter that message, so it was not sent.")
				end
				return
			elseif message.Status ~= Enum.TextChatMessageStatus.Success or message.Text == "" then
				return
			end
			local source = message.TextSource
			local player = source and service.Players:GetPlayerByUserId(source.UserId)
			if player then
				newMessage({
					PlayerName = player.Name;
					PlayerDisplayName = player.DisplayName;
					Message = message.Text;
					Icon = player.UserId > 0 and `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=48&h=48` or 0;
				})
			end
		end)
		channelEvent = Channel.AncestryChanged:Connect(function(_, parent)
			if parent == nil and window and not window.Destroyed then
				window:Close()
			end
		end)
	end

	sessionEvent = service.Events.SessionData:Connect(function(sessionKey, cmd, ...)
		local vargs = {...};
		if SessionKey == sessionKey then
			if cmd == "UpdatePeerList" then
				updatePeerList(vargs[1])
			elseif cmd == "SessionNotice" then
				systemMessage(vargs[1])
			elseif cmd == "RemovedFromSession" then
				systemMessage("<i>You have been removed from this chat session</i>")
				window:Close()
			elseif cmd == "AddedToSession" then
				systemMessage("<i>You have been added to this chat session</i>")
			elseif cmd == "SessionEnded" then
				window:Close()
			end
		end
	end)

	client.Remote.Send("Session", SessionKey, "GetPeerList")
	gTable = window.gTable
	window:Ready()
	if data.InitialMessage and Channel then
		reply.Text = data.InitialMessage
		sendIt()
		reply.Text = ""
	end
end
