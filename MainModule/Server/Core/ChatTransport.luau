server = nil
service = nil

return function(Vargs, GetEnv)
	local server = Vargs.Server
	local service = Vargs.Service
	local Settings = server.Settings
	local Functions = server.Functions
	local origins = setmetatable({}, {__mode = "k"})
	local inputs = setmetatable({}, {__mode = "k"})
	local channels = {}
	local nextCleanup = 0

	local function isLivePlayer(player)
		return typeof(player) == "Instance"
			and player:IsA("Player")
			and player.Parent == service.Players
	end

	local function getOrigin(token)
		local origin = origins[token]
		if origin and os.clock() - origin.Created <= 30 and isLivePlayer(origin.Player) then
			return origin
		end
		if origin then
			origins[token] = nil
		end
		return nil
	end

	local function getCommandArguments(text)
		local _, commandEnd = text:find("^%s*%S+")
		if not commandEnd then return nil end

		local splitKey = Settings.SplitKey
		if splitKey == "" then splitKey = " " end
		local remaining = text:sub(commandEnd + 1)
		if splitKey:match("%s") then
			return remaining:match("^%s*(.+)$")
		end
		if remaining:sub(1, #splitKey) ~= splitKey then return nil end
		return remaining:sub(#splitKey + 1)
	end

	local function getNativeCommandToken(text)
		local token = text:match("^%s*(%S+)")
		if token and token:sub(1, 1) == "/" then
			token = token:sub(2)
		end
		return token
	end

	local function commandMatches(command, token)
		local prefixes = if type(command.Prefix) == "table" then command.Prefix else {command.Prefix}
		for _, prefix in prefixes do
			for _, name in command.Commands do
				if string.lower(token) == string.lower(prefix .. name) then
					return true
				end
			end
		end
		return false
	end

	local function createChannel(owner, participants)
		assert(service.TextChatService and service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService,
			"Private messaging requires TextChatService.")
		assert(isLivePlayer(owner), "The chat requester is unavailable.")

		local textService = service.TextChatService
		local channel = Instance.new("TextChannel")
		local channelId = service.HttpService:GenerateGUID(false)
		local members = {[owner.UserId] = owner}
		local sources = {}
		local addedParticipants = {}
		local skippedParticipants = {}
		local deliveryDecisions = setmetatable({}, {__mode = "k"})
		local record = {
			Channel = channel,
			LastActive = os.clock(),
			Members = members,
			Owner = owner,
			Ready = {},
			Sources = sources,
		}
		channel.Name = `Adonis_{channelId}`

		local ok, err = pcall(function()
			channel:SetAttribute("AdonisManagedChatChannel", channelId)
			channel:SetAttribute("AdonisChatRequester", owner.UserId)
			channel.Parent = textService
			channel:SetDirectChatRequester(owner)
			for _, source in channel:GetChildren() do
				if source:IsA("TextSource") and source.UserId == owner.UserId then
					sources[owner.UserId] = source
					break
				end
			end

			for _, player in participants do
				if player ~= owner and typeof(player) == "Instance" and player:IsA("Player")
					and not members[player.UserId] then
					local added = false
					if isLivePlayer(player) then
						local chatOk, canChat = pcall(textService.CanUserChatAsync, textService, player.UserId)
						if chatOk and canChat and isLivePlayer(player) then
							local addOk, source = pcall(channel.AddUserAsync, channel, player.UserId)
							if addOk and source and isLivePlayer(player) then
								members[player.UserId] = player
								sources[player.UserId] = source
								table.insert(addedParticipants, player)
								added = true
							elseif source and source.Parent == channel then
								source:Destroy()
							end
						end
					end
					if not added then
						table.insert(skippedParticipants, player)
					end
				end
			end

			assert(isLivePlayer(owner), "The chat requester is no longer available.")
			channel.ShouldDeliverCallback = function(message, recipient)
				local sender = message.TextSource
				local senderPlayer = sender and members[sender.UserId]
				local recipientPlayer = recipient and members[recipient.UserId]
				local deliver = senderPlayer ~= nil
					and recipientPlayer ~= nil
					and isLivePlayer(senderPlayer)
					and isLivePlayer(recipientPlayer)
				local decision = deliveryDecisions[message]
				if not decision then
					decision = {Allowed = true}
					if senderPlayer and isLivePlayer(senderPlayer) and server.Admin.IsMuted(senderPlayer) then
						decision.Allowed = false
						decision.Reason = "You are muted; your message was not sent."
					elseif senderPlayer and isLivePlayer(senderPlayer) then
						local slowCache = server.Admin.SlowCache
						local now = os.time()
						if server.Admin.SlowMode and not server.Admin.CheckAdmin(senderPlayer)
							and slowCache[senderPlayer] and now - slowCache[senderPlayer] < server.Admin.SlowMode then
							decision.Allowed = false
							decision.Reason = `Slow mode is enabled. Wait {server.Admin.SlowMode - (now - slowCache[senderPlayer])} seconds before sending again.`
						elseif server.Admin.SlowMode and not server.Admin.CheckAdmin(senderPlayer) then
							slowCache[senderPlayer] = now
						end
					end
					deliveryDecisions[message] = decision
				end
				if deliver then
					record.LastActive = os.clock()
				end
				if recipientPlayer == senderPlayer and not decision.Allowed and decision.Reason then
					server.Remote.Send(senderPlayer, "Function", "DisplaySystemMessageInTextChat", nil,
						`<font color="rgb(130, 100, 130)">[Adonis Chat]: </font><b>{decision.Reason}</b>`)
				end
				return deliver and decision.Allowed
			end
		end)

		if not ok then
			channel:Destroy()
			error(err, 0)
		end

		channels[channelId] = record
		return channelId, channel, addedParticipants, skippedParticipants
	end

	local function removeMember(channelId, player)
		local record = channels[channelId]
		if not record or record.Members[player.UserId] ~= player then return end
		record.Members[player.UserId] = nil
		local source = record.Sources[player.UserId]
		record.Sources[player.UserId] = nil
		if source and source.Parent == record.Channel then
			source:Destroy()
		end
		if not next(record.Members) then
			server.ChatTransport.Close(channelId, "Empty")
		end
	end

	server.ChatTransport = {
		-- Creates a short-lived, server-authenticated token for a native chat command.
		NewOrigin = function(player, text)
			if not isLivePlayer(player) or type(text) ~= "string" then return nil end
			local token = {}
			origins[token] = {Player = player, Text = text, Created = os.clock()}
			return token
		end;

		-- Resolves only tokens created here and invalidates expired or disconnected authors.
		ResolveOriginAuthor = function(token)
			local origin = getOrigin(token)
			return origin and origin.Player or nil
		end;

		-- Authorizes unmodified literal chat arguments for commands that publish conversation text.
		CommandInput = function(player, command, args, options)
			options = options or {}
			if options.isSystem or options.CrossServer or options.Args or options.OverrideArgs then return nil end
			local origin = getOrigin(options.UserCommandOrigin)
			if not origin or origin.Player ~= player or type(command.UserText) ~= "table"
				or command.UserText.Kind ~= "Chat" or type(command.UserText.Args) ~= "table"
				or #command.UserText.Args == 0 or #args ~= #command.Args then
				return nil
			end

			local commandToken = getNativeCommandToken(origin.Text)
			if not commandToken or not commandMatches(command, commandToken) then return nil end
			local rawArgs = getCommandArguments(origin.Text)
			if not rawArgs then return nil end
			local parsed = Functions.Split(rawArgs, Settings.SplitKey, #args)
			if not parsed then return nil end
			for index, value in args do
				if parsed[index] ~= value then return nil end
			end

			local token = {}
			inputs[token] = {
				Player = player,
				Origin = options.UserCommandOrigin,
				Args = table.clone(args),
				Created = os.clock(),
			}
			return token
		end;

		-- Consumes a command-input authorization exactly once before forwarding its body to TextChannel.
		ConsumeInput = function(token, player, args)
			local input = inputs[token]
			if not input or input.Player ~= player or os.clock() - input.Created > 30
				or getOrigin(input.Origin) == nil or #args ~= #input.Args then
				if input then inputs[token] = nil end
				return false
			end
			for index, value in args do
				if value ~= input.Args[index] then
					inputs[token] = nil
					return false
				end
			end
			inputs[token] = nil
			return true
		end;

		Create = createChannel;
		Close = function(channelId, reason)
			local record = channels[channelId]
			if not record then return end
			channels[channelId] = nil
			for _, player in record.Members do
				if isLivePlayer(player) then
					server.Remote.Send(player, "ChatChannelClosed", channelId, reason or "Closed")
				end
			end
			record.Channel:Destroy()
		end;

		AddMember = function(channelId, player)
			local record = channels[channelId]
			if not record or not isLivePlayer(player) or record.Members[player.UserId] then return false end
			local chatOk, canChat = pcall(service.TextChatService.CanUserChatAsync, service.TextChatService, player.UserId)
			if not chatOk or not canChat then return false end
			local ok, source = pcall(record.Channel.AddUserAsync, record.Channel, player.UserId)
			if not ok or not source then return false end
			if channels[channelId] ~= record or not isLivePlayer(player) or not record.Channel.Parent then
				if source.Parent == record.Channel then source:Destroy() end
				return false
			end
			record.Members[player.UserId] = player
			record.Sources[player.UserId] = source
			return true
		end;

		-- Marks a channel member ready after their client subscribes to channel messages.
		MarkReady = function(channelId, player)
			local record = channels[channelId]
			if not record or record.Members[player.UserId] ~= player then return false end
			record.Ready[player.UserId] = true
			return true
		end;

		-- Waits for channel listeners before the requester sends the initial message.
		WaitForReady = function(channelId, timeout, includeOwner)
			local deadline = os.clock() + timeout
			repeat
				local record = channels[channelId]
				if not record then return {} end

				local ready = {}
				local waiting = false
				for userId, player in record.Members do
					if player ~= record.Owner or includeOwner then
						if record.Ready[userId] then
							if player ~= record.Owner then
								table.insert(ready, player)
							end
						else
							waiting = true
						end
					end
				end
				if not waiting then return ready, record.Ready[record.Owner.UserId] == true end
				task.wait(0.1)
			until os.clock() >= deadline

			local record = channels[channelId]
			local ready = {}
			if record then
				for userId, player in record.Members do
					if player ~= record.Owner and record.Ready[userId] then
						table.insert(ready, player)
					end
				end
				return ready, record.Ready[record.Owner.UserId] == true
			end
			return ready
		end;

		RemoveMember = removeMember;
		GetChannel = function(channelId)
			local record = channels[channelId]
			return record and record.Channel
		end;
	}

	service.Players.PlayerRemoving:Connect(function(player)
		local remove = {}
		local close = {}
		for channelId, record in channels do
			if record.Members[player.UserId] == player then
				table.insert(if record.Owner == player then close else remove, channelId)
			end
		end
		for _, channelId in remove do
			removeMember(channelId, player)
		end
		for _, channelId in close do
			server.ChatTransport.Close(channelId, "ParticipantLeft")
		end
		for token, origin in origins do
			if origin.Player == player then origins[token] = nil end
		end
	end)

	service.StartLoop("AdonisChatChannelCleanup", 60, function()
		nextCleanup = os.clock()
		for channelId, record in channels do
			if nextCleanup - record.LastActive > 900 then
				server.ChatTransport.Close(channelId, "Expired")
			end
		end
		for token, input in inputs do
			if nextCleanup - input.Created > 30 then inputs[token] = nil end
		end
	end, true)
end
