-- Receives Roblox-filtered chat and connects it to Adonis conversation windows.
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local client = Vargs.Client
	local service = Vargs.Service
	local textChatService = service.UnWrap(service.TextChatService)
	local channels = {}
	local operations = {}
	local operationOrder = {}
	local presentationVersions = {}
	local history = {}
	local historyIds = {}
	local transport
	local activeSpeech
	local speechMuted = false
	local MAX_CHANNEL_HISTORY = 200
	local MAX_HISTORY = 500
	local READY_TIMEOUT = 10
	local SEND_TIMEOUT = 10
	local kinds = {PrivateMessage = true, PrivateChat = true, Help = true, Notification = true, Bubble = true, Speech = true}
	local presentations = {Message = true, Hint = true, Notify = true, Notification = true, RobloxNotification = true, ChatMessage = true, Alert = true}

	-- Returns a fixed explanation without exposing a raw transport error or draft.
	local function statusText(status)
		local explanations = {
			EmptyMessage = "Cannot send an empty message.",
			ChannelClosed = "This conversation has ended.",
			ChannelNotReady = "This conversation is not ready yet.",
			ReadOnly = "You cannot send messages in this conversation.",
			DeliveryUnconfirmed = "Roblox has not confirmed this message. It has not been retried.",
			Floodchecked = "Please wait before sending another message.",
			TextFilterFailed = "Roblox could not filter this message. Please try again later.",
			InvalidPrivacySettings = "Your chat settings do not allow this message.",
			InvalidTextChannelPermissions = "You cannot send messages in this conversation.",
			MessageTooLong = "This message is too long.",
			CommandText = "This message matches a chat command. Change its opening text before sending.",
		}
		return explanations[status] or "Roblox could not send this message."
	end

	-- Converts a delivered engine message into the recipient's local history entry.
	local function messageEntry(message)
		local source = message.TextSource
		if not source or message.Status ~= Enum.TextChatMessageStatus.Success or message.MessageId == ""
			or type(message.Text) ~= "string" or message.Text == "" then
			return nil
		end
		local sender = service.Players:GetPlayerByUserId(source.UserId)
		return {
			MessageId = message.MessageId,
			Text = message.Text,
			SenderUserId = source.UserId,
			SenderName = sender and sender.Name or tostring(source.UserId),
			Time = os.time(),
		}
	end

	-- Keeps a bounded, deduplicated record of messages Roblox delivered to this client.
	local function recordHistory(entry)
		if historyIds[entry.MessageId] then
			return
		end
		historyIds[entry.MessageId] = true
		table.insert(history, entry)
		if #history > MAX_HISTORY then
			historyIds[table.remove(history, 1).MessageId] = nil
		end
	end

	-- Notifies live window subscribers; one failed window cannot break delivery.
	local function emit(record, eventName, payload)
		for callback in record.Subscribers do
			pcall(callback, eventName, payload)
		end
	end

	-- Cancels the current utterance once, releasing audio before closing its window.
	local function stopSpeech()
		local speech = activeSpeech
		if speech then
			activeSpeech = nil
			speech.Cancelled = true
			for _, sound in speech.Sounds do
				pcall(function()
					sound:Stop()
					sound:Destroy()
				end)
			end
			local window = speech.Window
			speech.Window = nil
			if window then
				window:Close()
			end
		end
	end

	-- Plays only received filtered text, with one utterance and recipient controls.
	local function presentSpeech(record, entry)
		stopSpeech()
		if speechMuted then
			return
		end
		local speech = {Cancelled = false, Sounds = {}, ChannelId = record.Descriptor.ChannelId}
		activeSpeech = speech
		-- Detaches a closing window before cancellation so destruction cannot close it recursively.
		local function cancelWindowSpeech()
			speech.Window = nil
			if activeSpeech == speech then
				stopSpeech()
			end
		end
		local window = client.UI.Make("Window", {
			Name = "ChatSpeech",
			Title = `Speech from {entry.SenderName}`,
			Size = {360, 160},
			OnClose = cancelWindowSpeech,
		})
		if not window then
			stopSpeech()
			return
		end
		speech.Window = window
		local gTable = window.gTable
		local destroyWindow = gTable.CustomDestroy
		-- Cancels playback for every registered-window destruction path, including theme close buttons.
		gTable.CustomDestroy = function()
			cancelWindowSpeech()
			if destroyWindow then
				destroyWindow()
			else
				service.UnWrap(gTable.Object):Destroy()
			end
		end
		window:Add("TextLabel", {
			Text = entry.Text,
			RichText = false,
			TextWrapped = true,
			Size = UDim2.new(1, -10, 1, -45),
			BackgroundTransparency = 1,
		})
		window:Add("TextButton", {
			Text = "Stop",
			Size = UDim2.new(0.4, -10, 0, 30),
			Position = UDim2.new(0, 5, 1, -35),
			OnClick = stopSpeech,
		})
		window:Add("TextButton", {
			Text = "Mute speech for this session",
			Size = UDim2.new(0.6, -5, 0, 30),
			Position = UDim2.new(0.4, 0, 1, -35),
			OnClick = function()
				speechMuted = true
				stopSpeech()
			end,
		})
		window:Ready()
		task.spawn(function()
			pcall(client.Functions.TextToSpeech, entry.Text, function()
				return activeSpeech == speech and not speech.Cancelled
			end, function(sound)
				table.insert(speech.Sounds, sound)
			end)
			for _, sound in speech.Sounds do
				pcall(function() sound:Destroy() end)
			end
		end)
	end

	-- Presents received text; the newest Message or Notify receipt owns replacement across yielding cleanup.
	local function present(record, entry)
		local descriptor = record.Descriptor
		local sender = service.Players:GetPlayerByUserId(entry.SenderUserId)
		if entry.SenderUserId == service.Player.UserId and not descriptor.PresentToSender then
			return
		end
		if descriptor.Kind == "PrivateMessage" then
			if sender then
				client.UI.Make("PrivateMessage", {
					ChannelId = descriptor.ChannelId,
					Player = sender,
					Message = entry.Text,
					Title = `Message from {entry.SenderName}`,
				})
			end
		elseif descriptor.Kind == "Help" then
			client.UI.Make("Notification", {
				Title = `Help request from {entry.SenderName}`,
				Message = entry.Text,
				Time = 30,
				OnClick = function()
					if channels[descriptor.ChannelId] == record then
						client.Remote.Send("ChatHelpAccept", descriptor.ChannelId)
					end
				end,
			})
		elseif descriptor.Kind == "Bubble" then
			if sender and sender.Character then
				pcall(function() textChatService:DisplayBubble(service.UnWrap(sender.Character), entry.Text) end)
			end
		elseif descriptor.Kind == "Speech" then
			presentSpeech(record, entry)
		elseif descriptor.Kind == "Notification" then
			local title = `Message from {entry.SenderName}`
			local body = entry.Text
			local presentation = descriptor.Presentation
			if descriptor.TitleMode == "Broadcast" then
				title = "Broadcast"
			elseif descriptor.TitleMode == "Custom" then
				-- Filtering may change framing; malformed results keep a fixed title and the delivered text.
				local boundary = string.find(body, "\n", 1, true)
				if boundary and boundary > 1 and boundary < #body then
					title, body = string.sub(body, 1, boundary - 1), string.sub(body, boundary + 1)
				end
			end
			local duration = tonumber(descriptor.Duration)
			if not duration or duration ~= duration or duration <= 0 or duration == math.huge then duration = nil end
			duration = if duration then math.clamp(duration, 1, 3600)
				else if descriptor.AutoDuration == true then #body / 19 + 2.5 else 10
			if presentation == "RobloxNotification" then
				pcall(function()
					service.StarterGui:SetCore("SendNotification", {Title = title, Text = body, Duration = math.clamp(duration, 1, 30)})
				end)
			elseif presentation == "ChatMessage" then
				local systemChannel = textChatService:FindFirstChild("RBXSystem", true)
				if systemChannel and systemChannel:IsA("TextChannel") then
					local escapedText = body:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
					local attribution = if descriptor.TitleMode == "Broadcast" then `Broadcast from {entry.SenderName}` else entry.SenderName
					systemChannel:DisplaySystemMessage(`{attribution}: {escapedText}`)
				else
					client.UI.Make("Hint", {Title = title, Message = `{entry.SenderName}: {body}`, Time = duration})
				end
			elseif presentations[presentation] then
				if presentation == "Hint" then body = `{entry.SenderName}: {body}` end
				if presentation == "Message" or presentation == "Notify" then
					local version = {}
					presentationVersions[presentation] = version
					client.UI.Remove(presentation)
					if presentationVersions[presentation] ~= version then return end
				end
				client.UI.Make(presentation, {Title = title, Message = body, Time = duration})
			end
		end
	end

	-- Stores an engine result before notifying windows or starting presentation work.
	local function receive(record, message)
		if channels[record.Descriptor.ChannelId] ~= record then
			return
		end
		local messageId = message.MessageId
		if messageId ~= "" and not record.Results[messageId] then
			table.insert(record.ResultOrder, messageId)
			if #record.ResultOrder > MAX_CHANNEL_HISTORY then record.Results[table.remove(record.ResultOrder, 1)] = nil end
		end
		if messageId ~= "" then
			record.Results[messageId] = message.Status.Name
		end
		local entry = messageEntry(message)
		if not entry or record.MessageIds[entry.MessageId] then
			return
		end
		record.MessageIds[entry.MessageId] = true
		table.insert(record.History, entry)
		if #record.History > MAX_CHANNEL_HISTORY then
			local removed = table.remove(record.History, 1)
			record.MessageIds[removed.MessageId] = nil
			record.Results[removed.MessageId] = nil
		end
		recordHistory(entry)
		emit(record, "Message", table.clone(entry))
		task.spawn(function()
			if channels[record.Descriptor.ChannelId] == record then
				present(record, entry)
			end
		end)
	end

	-- Ends subscriptions and native listeners without retaining channel objects.
	local function closeChannel(channelId, reason)
		local record = channels[channelId]
		if not record then
			return
		end
		channels[channelId] = nil
		for _, connection in record.Connections do
			connection:Disconnect()
		end
		if activeSpeech and activeSpeech.ChannelId == channelId then
			stopSpeech()
		end
		emit(record, "Closed", reason or "This conversation has ended.")
		table.clear(record.Subscribers)
	end

	-- Finds a replicated managed channel and installs reception before acknowledging it.
	local function openChannel(descriptor)
		if type(descriptor) ~= "table" or type(descriptor.ChannelId) ~= "string"
			or type(descriptor.ChannelName) ~= "string" or not kinds[descriptor.Kind] then
			return
		end
		local existing = channels[descriptor.ChannelId]
		if existing then
			existing.Descriptor = descriptor
			if existing.Ready then
				client.Remote.Send("ChatChannelReady", descriptor.ChannelId)
			end
			return
		end
		local record = {Descriptor = descriptor, History = {}, MessageIds = {}, Results = {}, ResultOrder = {}, Subscribers = {}, Connections = {}}
		channels[descriptor.ChannelId] = record
		task.spawn(function()
			local deadline = os.clock() + READY_TIMEOUT
			repeat
				if channels[descriptor.ChannelId] ~= record then
					return
				end
				local channel = textChatService:FindFirstChild(descriptor.ChannelName, true)
				if channel and channel:IsA("TextChannel") and channel:GetAttribute("AdonisChannelId") == descriptor.ChannelId then
					for _, source in channel:GetChildren() do
						if source:IsA("TextSource") and source.UserId == service.Player.UserId then
							record.Channel = channel
							record.Source = source
							table.insert(record.Connections, channel.MessageReceived:Connect(function(message) receive(record, message) end))
							table.insert(record.Connections, channel.AncestryChanged:Connect(function()
								if not channel:IsDescendantOf(textChatService) then closeChannel(descriptor.ChannelId) end
							end))
							table.insert(record.Connections, source.AncestryChanged:Connect(function()
								if source.Parent ~= channel then closeChannel(descriptor.ChannelId) end
							end))
							record.Ready = true
							if descriptor.Kind == "PrivateChat" then
								task.spawn(function()
									client.UI.Make("PrivateChat", {
										ChannelId = descriptor.ChannelId,
										SessionKey = descriptor.SessionKey,
										SessionName = descriptor.ChannelId,
										Owner = service.Players:GetPlayerByUserId(descriptor.RequesterUserId),
										CanManageUsers = descriptor.CanManageUsers,
									})
								end)
							end
							client.Remote.Send("ChatChannelReady", descriptor.ChannelId)
							return
						end
					end
				end
				task.wait(0.1)
			until os.clock() >= deadline
			closeChannel(descriptor.ChannelId, "This conversation could not be opened.")
		end)
	end

	-- Detects command aliases that Roblox would intercept instead of delivering chat.
	local function isCommandText(text)
		local lower = string.lower(text)
		for _, command in textChatService:GetDescendants() do
			if command:IsA("TextChatCommand") and command.Enabled then
				for _, alias in {command.PrimaryAlias, command.SecondaryAlias} do
					if alias ~= "" then
						alias = string.lower(alias)
						local withSlash = string.sub(alias, 1, 1) == "/" and alias or "/" .. alias
						for _, candidate in {alias, withSlash} do
							if lower == candidate or (string.sub(lower, 1, #candidate) == candidate
								and string.match(string.sub(lower, #candidate + 1, #candidate + 1), "%s")) then return true end
						end
					end
				end
			end
		end
		return false
	end

	-- Sends a locally submitted draft through Roblox; raw drafts are never rendered.
	local function send(channelId, text, operationId)
		local record = channels[channelId]
		if not record then return false, "ChannelClosed" end
		if not record.Ready then return false, "ChannelNotReady" end
		if not record.Descriptor.CanSend or not record.Source.CanSend then return false, "ReadOnly" end
		if type(text) ~= "string" or service.Trim(text) == "" then return false, "EmptyMessage" end
		if isCommandText(text) then return false, "CommandText" end
		local deadline = os.clock() + SEND_TIMEOUT
		local completed, ok, message = false, false, nil
		local sendThread = task.spawn(function()
			ok, message = pcall(function() return record.Channel:SendAsync(text, operationId or "") end)
			completed = true
		end)
		while not completed and channels[channelId] == record and os.clock() < deadline do task.wait(0.05) end
		if not completed then
			-- Cancelling the waiting task is not a delivery cancellation or retry.
			-- The native reception listener remains available for any late delivery.
			pcall(task.cancel, sendThread)
			return false, "DeliveryUnconfirmed"
		end
		if not ok or not message then return false, "SendFailed" end
		local messageId = message.MessageId
		local status = record.Results[messageId] or message.Status.Name
		while status == "Sending" and channels[channelId] == record and os.clock() < deadline do
			task.wait(0.05)
			status = record.Results[messageId] or message.Status.Name
		end
		if status == "Sending" then status = "DeliveryUnconfirmed" end
		return status == "Success", status, messageId
	end

	-- Deduplicates server-authorized initial sends without retaining their text.
	local function autoSend(operationId, channelId, text)
		if type(operationId) ~= "string" or #operationId > 200 or operations[operationId] then return end
		operations[operationId] = true
		table.insert(operationOrder, operationId)
		if #operationOrder > 256 then operations[table.remove(operationOrder, 1)] = nil end
		task.delay(120, function() operations[operationId] = nil end)
		local _, status, messageId = send(channelId, text, operationId)
		client.Remote.Send("ChatSendResult", operationId, status, messageId)
		if status ~= "Success" then client.UI.Make("Hint", {Message = statusText(status)}) end
	end

	-- Registers handlers before client-ready events can trigger server setup messages.
	local function init()
		client.Remote.Commands.ChatChannelOpened = function(args) openChannel(args[1]) end
		client.Remote.Commands.ChatChannelClosed = function(args) closeChannel(args[1], args[2]) end
		client.Remote.Commands.ChatSend = function(args) autoSend(args[1], args[2], args[3]) end
		client.Remote.Commands.ChatHistory = function()
			local entries = {}
			for _, entry in history do
				table.insert(entries, {Text = `{entry.SenderName}: {entry.Text}`, Desc = os.date("%X", entry.Time)})
			end
			client.UI.Make("List", {Title = "Your received chat history", Table = entries})
		end
		textChatService.MessageReceived:Connect(function(message)
			local entry = messageEntry(message)
			if entry then recordHistory(entry) end
		end)
		transport.Init = nil
	end

	-- Announces support only after the client has obtained its remote key.
	local function runAfterLoaded()
		client.Remote.Send("ChatTransportReady")
		transport.RunAfterLoaded = nil
	end

	transport = {
		Init = init,
		RunAfterLoaded = runAfterLoaded,
		Send = send,
		IsCommandText = isCommandText,
		StatusText = statusText,
		-- Returns metadata for an open managed conversation.
		GetDescriptor = function(channelId)
			local record = channels[channelId]
			return record and table.clone(record.Descriptor)
		end,
		-- Returns copies of this recipient's delivered messages, never server replay.
		GetHistory = function(channelId)
			local record = channels[channelId]
			local result = {}
			for _, entry in record and record.History or {} do table.insert(result, table.clone(entry)) end
			return result
		end,
		-- Subscribes a window to Message and Closed events; returns an unsubscribe function.
		Subscribe = function(channelId, callback)
			local record = channels[channelId]
			if not record then
				task.defer(callback, "Closed", "This conversation has ended.")
				return function() end
			end
			record.Subscribers[callback] = true
			return function() record.Subscribers[callback] = nil end
		end,
	}
	client.ChatTransport = transport
end
