client, service = nil, nil

-- Displays the filtered request and submits its initial text through the requester-owned channel.
return function(data, env)
	if env then
		setfenv(1, env)
	end

	local channelId = data.ChannelId
	local channel = data.Channel
	if typeof(channel) ~= "Instance" or not channel:IsA("TextChannel") then
		channel = service.TextChatService:WaitForChild(`Adonis_{channelId}`, 10)
	end
	if typeof(channel) ~= "Instance" or not channel:IsA("TextChannel") then
		channel = nil
	end
	local requester = data.Requester
	local messageEvent, channelEvent
	local closed = false

	local window = client.UI.Make("Window", {
		Name = `HelpRequestChat_{channelId}`;
		Title = if data.IsRequester then "Help Request" else `Help Request from {requester.Name}`;
		Icon = client.MatIcons.Forum;
		Size = {400, 240};
		OnClose = function()
			closed = true
			if messageEvent then
				messageEvent:Disconnect()
			end
			if channelEvent then
				channelEvent:Disconnect()
			end
		end;
	})

	local chatlog = window:Add("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
		CanvasSize = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 0.9;
		AutomaticCanvasSize = "Y";
	})

	service.New("UIListLayout", {
		Parent = chatlog;
		FillDirection = "Vertical";
		HorizontalAlignment = "Left";
		VerticalAlignment = "Top";
		SortOrder = "LayoutOrder";
	})

	-- Renders channel event text as plain text rather than interpreting markup.
	local function addMessage(sender, text)
		chatlog:Add("TextLabel", {
			Text = `{sender}: {text}`;
			Size = UDim2.new(1, -10, 0, 0);
			AutomaticSize = "Y";
			BackgroundTransparency = 1;
			TextWrapped = true;
			TextXAlignment = "Left";
			TextYAlignment = "Top";
			RichText = false;
		})
	end

	if channel then
		messageEvent = channel.MessageReceived:Connect(function(message)
			if message.Status == Enum.TextChatMessageStatus.TextFilterFailed then
				local source = message.TextSource
				if source and source.UserId == service.Players.LocalPlayer.UserId then
					addMessage("System", "Roblox could not filter the request, so it was not sent.")
				end
				return
			end
			if message.Status ~= Enum.TextChatMessageStatus.Success or message.Text == "" then return end

			local source = message.TextSource
			local player = source and service.Players:GetPlayerByUserId(source.UserId)
			if player then
				addMessage(player.DisplayName, message.Text)
			end
		end)
		channelEvent = channel.AncestryChanged:Connect(function(_, parent)
			if parent == nil and not closed then
				window:Close()
			end
		end)
	end

	window:Ready()

	if not channel then
		addMessage("System", "The help request channel could not be opened.")
		return
	end

	client.Remote.Send("HelpRequestReady", channelId)
	if data.IsRequester then
		local ok = pcall(channel.SendAsync, channel, data.InitialMessage)
		if not ok then
			addMessage("System", "The request could not be sent through Roblox chat.")
		end
	end
end
