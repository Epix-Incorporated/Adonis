client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local UI = client.UI
	local transport = client.ChatTransport
	local channelId = data.ChannelId
	local player = data.Player

	local gTable
	local debounce = false
	local unsubscribe
	local closed = false

	local window = UI.Make("Window",{
		Name  = "PrivateMessage";
		Title = tostring(player);
		Size  = {300, 150};
		OnClose = function()
			if unsubscribe then unsubscribe() end
		end;
	})

	local label = window:Add("TextLabel",{
		Text = data.Message;
		Size = UDim2.new(1, -10, 1, -40);
		BackgroundTransparency = 1;
		TextScaled = true;
		TextWrapped = true;
		RichText = false;
	})

	local reply = window:Add("TextBox", {
		Text = ""; --"Enter reply";
		PlaceholderText = "Enter reply";
		Size = UDim2.new(1, -65, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		ClearTextOnFocus = false;
		TextScaled = true;
	})

	-- Submits the reply through the participant's native TextChannel.
	local function sendIt(enter)
		if not debounce and not closed then
			debounce = true
			if enter then
				if reply:IsFocused() then
					reply:ReleaseFocus() -- Prevents box text from being checked before it is populated on mobile devices
				end
				
				if service.Trim(reply.Text) == "" then
					debounce = false
					UI.Make("Hint", {
						Message = "Cannot send empty message!"
					})
					return
				end

				local sent, status = transport.Send(channelId, reply.Text)
				if sent then
					window:Close()
				else
					UI.Make("Hint", {Message = transport.StatusText(status)})
				end
			end
			debounce = false
		end
	end

	local send = window:Add("TextButton", {
		Text = "Send";
		Size = UDim2.new(0, 60, 0, 30);
		Position = UDim2.new(1, -65, 1, -35);
		OnClick = function()
			sendIt(true)
		end
	})

	send.BackgroundColor3 = send.BackgroundColor3:lerp(Color3.new(0,0,0), 0.1)
	reply.FocusLost:Connect(sendIt)
	unsubscribe = transport.Subscribe(channelId, function(eventName)
		if eventName == "Closed" then
			closed = true
			reply.TextEditable = false
			reply.PlaceholderText = "This conversation has ended"
			send.Active = false
		end
	end)

	gTable = window.gTable
	UI.Make("Notification", {
		Title = "New Message";
		Message = `Message from {player.DisplayName} ({player.Name})`;
		Icon = player.UserId > 0 and `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=48&h=48` or client.MatIcons.Mail;
		Time = false;
		OnClick = function() window:Ready() end;
		OnClose = function() if unsubscribe then unsubscribe() end window:Destroy() end;
		OnIgnore = function() if unsubscribe then unsubscribe() end window:Destroy() end;
	})
end
