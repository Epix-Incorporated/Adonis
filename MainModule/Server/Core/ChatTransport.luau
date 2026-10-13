--!nocheck
-- Owns direct TextChannels and author-bound command submissions. Message bodies
-- are sent only to their original author; Roblox delivers them to recipients.
return function(Vargs, GetEnv)
	setfenv(1, GetEnv(nil, {script = script}))
	local server, service = Vargs.Server, Vargs.Service
	local transport = {}
	local channels, pairsById, clients, pending = {}, {}, {}, {}
	local pairLocks = {}
	local origins = setmetatable({}, {__mode = "k"})
	local inputs = setmetatable({}, {__mode = "k"})
	local count = 0
	local kinds = {PrivateMessage = true, PrivateChat = true, Help = true, Notification = true, Bubble = true, Speech = true}
	local presentations = {Message = true, Notify = true, Hint = true, Notification = true, RobloxNotification = true, ChatMessage = true, Alert = true}
	local titleModes = {Author = true, Broadcast = true, Custom = true}

	-- Returns a current server player, without accepting client-shaped tables.
	local function livePlayer(player)
		local raw = service.UnWrap(player)
		return typeof(raw) == "Instance" and raw:IsA("Player") and raw.Parent == service.UnWrap(service.Players)
	end

	-- Reports transport errors without echoing user input or provider exceptions.
	local function notify(player, message)
		if livePlayer(player) then
			server.Remote.MakeGui(player, "Output", {Title = "Chat", Message = message})
		end
	end

	-- Resolves the original actor only at an explicitly submitted command ingress.
	function transport.NewOrigin(player, submission)
		if not livePlayer(player) or type(submission) ~= "string" then return nil end
		local origin = {}
		origins[origin] = {Player = player, Text = submission, Expires = os.clock() + 30, InvocationId = service.HttpService:GenerateGUID(false)}
		return origin
	end

	-- Resolves only a live actor from a private, unexpired command-ingress capability.
	function transport.ResolveOriginAuthor(origin)
		local source = origins[origin]
		return if source and source.Expires >= os.clock() and livePlayer(source.Player) then source.Player else nil
	end

	-- Seeds byte provenance only from the actual caller's explicit submission.
	function transport.OriginMask(origin, player, text)
		local source = origins[origin]
		if source and source.Player == player and source.Expires >= os.clock() and string.find(source.Text, text, 1, true) then
			return string.rep("1", #text)
		end
		return string.rep("0", #text)
	end

	-- Binds one parsed command's text fields to the original author's submission.
	function transport.CommandInput(player, command, args, options)
		local origin = origins[options.UserCommandOrigin]
		if not origin or origin.Player ~= player or origin.Expires < os.clock() or options.isSystem
			or options.Args or options.Arguments or (options.OverrideArgs and next(options.OverrideArgs)) then return nil end
		local fields = {}
		for _, index in command.UserText.Args do
			local value = args[index]
			if value ~= nil then
				if type(value) ~= "string" or not string.find(origin.Text, value, 1, true)
					or (options.LiteralArguments and not options.LiteralArguments[index]) then return nil end
				table.insert(fields, value)
			end
		end
		local input = {}
		inputs[input] = {Player = player, Text = table.concat(fields, "\n"), Fields = fields, Expires = origin.Expires, InvocationId = origin.InvocationId}
		return input
	end

	-- Prevents conversational text from invoking registered native commands.
	function transport.IsCommandText(text)
		local lower = string.lower(text)
		for _, command in service.TextChatService:GetDescendants() do
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

	-- Identifies channels whose delivery and send permissions this core owns.
	function transport.IsManaged(channel)
		return channel and channel:GetAttribute("AdonisChannelId") ~= nil
	end

	-- Builds a recipient-specific descriptor containing no user-authored body.
	local function descriptor(record, player)
		local ids = {}
		for peer in record.Members do table.insert(ids, peer.UserId) end
		local member = record.Members[player]
		return {
			ChannelId = record.Id, ChannelName = record.Channel.Name, Kind = record.Kind,
			Presentation = record.Presentation, RequesterUserId = record.Owner.UserId,
			ParticipantUserIds = ids, CanSend = member and member.CanSend or false,
			SessionKey = record.Session and record.Session.SessionKey,
			CanManageUsers = player == record.Owner or server.Admin.CheckAdmin(player),
			PresentToSender = record.PresentToSender,
			Duration = record.Duration,
			TitleMode = record.TitleMode, AutoDuration = record.AutoDuration,
		}
	end

	-- Bounds display timing without putting any user-authored content in control metadata.
	local function displayDuration(value, presentation)
		local duration = tonumber(value)
		if presentation == "RobloxNotification" then return duration and duration == duration and math.clamp(duration, 1, 30) or 5 end
		if not duration or duration ~= duration or duration <= 0 or duration == math.huge then duration = nil end
		return duration and math.clamp(duration, 1, 3600)
	end

	-- Announces membership after the client transport has installed its listeners.
	local function announce(record, player)
		if clients[player] and record.Members[player] then
			server.Remote.Send(player, "ChatChannelOpened", descriptor(record, player))
		end
	end

	-- Tears down all channel resources and outstanding send authorizations.
	function transport.Close(id, reason)
		local record = channels[id]
		if not record then return end
		channels[id] = nil
		count -= 1
		if record.PairKey then pairsById[record.PairKey] = nil end
		for operation, permit in pending do
			if permit.Record == record then pending[operation] = nil end
		end
		for player in record.Members do
			server.Remote.Send(player, "ChatChannelClosed", id, reason or "Closed")
		end
		if record.Session and not record.Session.Ended then record.Session:End() end
		if record.OnClose then record.OnClose() end
		record.Channel:Destroy()
		table.clear(record.Members)
	end

	-- Adds a player using Roblox eligibility and rechecks closure after yielding.
	function transport.AddMember(id, player, canSend)
		local record = channels[id]
		if not record or not livePlayer(player) then return false end
		if record.Members[player] then return true end
		if record.Joining[player] then return false end
		record.Joining[player] = true
		local finished, abandoned, ok, source = false, false, false, nil
		task.spawn(function()
			ok, source = pcall(function() return record.Channel:AddUserAsync(player.UserId) end)
			finished = true
			record.Joining[player] = nil
			if abandoned and ok and source then source:Destroy() end
		end)
		local deadline = os.clock() + 10
		while not finished and channels[id] == record and os.clock() < deadline do task.wait(0.05) end
		if not finished then abandoned = true; return false end
		if not ok or not source then return false end
		if channels[id] ~= record or not livePlayer(player) then source:Destroy(); return false end
		source.CanSend = canSend and not server.Admin.IsMuted(player)
		record.Members[player] = {Source = source, CanSend = canSend == true, Ready = false}
		if record.Session then record.Session:AddUser(player) end
		announce(record, player)
		return true
	end

	-- Revokes membership before removing its native TextSource.
	function transport.RemoveMember(id, player)
		local record = channels[id]
		if not record or not record.Members[player] then return end
		if record.Owner == player or record.Kind == "PrivateMessage" then transport.Close(id, "ParticipantLeft"); return end
		local member = record.Members[player]
		record.Members[player] = nil
		server.Remote.Send(player, "ChatChannelClosed", id, "Removed")
		member.Source:Destroy()
		if record.Session and not record.Session.Ended then record.Session:RemoveUser(player) end
	end

	-- Creates a managed direct channel; callbacks never call yielding permission APIs.
	local function create(owner, recipients, kind, presentation, options)
		if count >= 1024 then return nil, "Chat capacity reached; please try again later." end
		local id = service.HttpService:GenerateGUID(false)
		local channel = Instance.new("TextChannel")
		channel.Name = "Adonis_" .. id
		channel:SetAttribute("AdonisChannelId", id)
		local record = {Id = id, Channel = channel, Owner = owner, Kind = kind, Presentation = presentation,
			Members = {}, Joining = {}, LastActivity = os.clock(), Created = os.clock(), PresentToSender = options.PresentToSender == true,
			Session = options.Session, OnAccept = options.OnAccept, OnClose = options.OnClose,
			Duration = displayDuration(options.Duration, presentation), TitleMode = options.TitleMode or "Author", AutoDuration = options.AutoDuration == true}
		channels[id] = record
		count += 1
		task.delay(10, function()
			if channels[id] == record then
				for _, member in record.Members do
					if not member.Ready then transport.Close(id, "SetupTimeout"); return end
				end
				if not record.Initialized then transport.Close(id, "SetupTimeout") end
			end
		end)
		channel.ShouldDeliverCallback = function(message, receiver)
			if channels[id] ~= record or not message.TextSource then return false end
			local sender = service.Players:GetPlayerByUserId(message.TextSource.UserId)
			local recipient = service.Players:GetPlayerByUserId(receiver.UserId)
			local from, to = record.Members[sender], record.Members[recipient]
			if not from or not to or not from.CanSend or not from.Ready or not to.Ready or server.Admin.IsMuted(sender) then return false end
			record.LastActivity = os.clock()
			return true
		end
		channel.Parent = service.UnWrap(service.TextChatService)
		local ok = pcall(function() channel:SetDirectChatRequester(service.UnWrap(owner)) end)
		if not ok or not transport.AddMember(id, owner, true) then
			transport.Close(id, "Unavailable")
			return nil, "Chat is unavailable for this player."
		end
		local joined = 0
		for _, recipient in recipients do
			if recipient ~= owner then
				if transport.AddMember(id, recipient, kind == "PrivateMessage" or kind == "PrivateChat") then
					joined += 1
				else
					notify(owner, "A selected recipient could not join the conversation.")
				end
			else
				joined += 1
			end
		end
		if channels[id] ~= record then return nil, "Conversation setup timed out." end
		if joined == 0 then transport.Close(id, "Unavailable"); return nil, "No selected recipients can join this conversation." end
		record.Initialized = true
		for player in record.Members do announce(record, player) end
		return record
	end

	-- Waits for transport listeners and membership replication, with a fixed bound.
	local function ready(record, author)
		local deadline = os.clock() + 10
		repeat
			if channels[record.Id] ~= record or not livePlayer(author) then return false end
			local all = true
			for player, member in record.Members do
				if not livePlayer(player) or not member.Ready then all = false; break end
			end
			if all then return true end
			task.wait(0.05)
		until os.clock() >= deadline
		return false
	end

	-- Returns an initial body only to its verified author, exactly once per permit.
	local function submit(record, author, text, expires, recipients)
		local active = 0
		for _, permit in pending do if permit.Player == author then active += 1 end end
		if active >= 32 then return false end
		local operation = service.HttpService:GenerateGUID(false)
		local targetIds = {}
		for _, recipient in recipients do
			if record.Members[recipient] then table.insert(targetIds, recipient.UserId) end
		end
		local permit = {Record = record, Player = author, Expires = expires, TargetUserIds = targetIds}
		pending[operation] = permit
		if not ready(record, author) or os.clock() >= expires or pending[operation] ~= permit then
			pending[operation] = nil
			transport.Close(record.Id, "SetupTimeout")
			return false
		end
		server.Remote.Send(author, "ChatSend", operation, record.Id, text)
		return true
	end

	-- Starts an authorized command conversation without relaying text to recipients.
	function transport.SubmitCommand(author, recipients, text, input, kind, presentation, options)
		options = options or {}
		assert(livePlayer(author) and kinds[kind] and (presentation == nil or presentations[presentation])
			and (options.TitleMode == nil or titleModes[options.TitleMode]), "Chat is unavailable.")
		local submitted = inputs[input]
		assert(submitted and submitted.Player == author and submitted.Expires >= os.clock()
			and submitted.Text == (text or ""), "Enter chat text yourself; generated commands cannot send messages.")
		inputs[input] = nil
		if options.TitleMode == "Custom" then
			assert(kind == "Notification" and #submitted.Fields == 2, "A custom message requires an authored title and body.")
			-- Only title whitespace is normalized; both fields remain inside the native message.
			text = string.gsub(submitted.Fields[1], "[\r\n]+", " ") .. "\n" .. submitted.Fields[2]
		end
		assert(not transport.IsCommandText(text or ""), "This message matches a chat command. Change its opening text before sending.")
		local selected, seen = {}, {}
		for _, player in recipients do
			if livePlayer(player) and not seen[player] then table.insert(selected, player); seen[player] = true end
		end
		options.PresentToSender = seen[author] == true
		assert(#selected > 0, "No available recipients.")
		local required = kind == "PrivateMessage" and #selected or 1
		local active = 0
		for _, permit in pending do if permit.Player == author then active += 1 end end
		assert(active + required <= 32, "Too many pending messages; wait for earlier sends to finish.")
		local newChannels = required
		if kind == "PrivateMessage" then
			for _, target in selected do
				local key = tostring(math.min(author.UserId, target.UserId)) .. ":" .. tostring(math.max(author.UserId, target.UserId))
				if pairsById[key] and channels[pairsById[key]] then newChannels -= 1 end
			end
		end
		assert(count + newChannels <= 1024, "Chat capacity reached; please try again later.")
		local records = {}
		local groups = kind == "PrivateMessage" and selected or {selected}
		for _, target in groups do
			local targets = kind == "PrivateMessage" and {target} or target
			local pairKey = kind == "PrivateMessage" and tostring(math.min(author.UserId, target.UserId)) .. ":" .. tostring(math.max(author.UserId, target.UserId)) or nil
			if pairKey then
				local deadline = os.clock() + 10
				while pairLocks[pairKey] and os.clock() < deadline do task.wait(0.05) end
				if pairLocks[pairKey] then notify(author, "Conversation setup is already pending."); continue end
			end
			local record = pairKey and channels[pairsById[pairKey]]
			if not record then
				local err
				if pairKey then pairLocks[pairKey] = true end
				record, err = create(author, targets, kind, presentation, options)
				if pairKey then pairLocks[pairKey] = nil end
				if not record then notify(author, err); continue end
				if pairKey then record.PairKey = pairKey; pairsById[pairKey] = record.Id end
			end
			table.insert(records, record)
			if text and text ~= "" then
				task.spawn(function()
					if not submit(record, author, text, submitted.Expires, targets) then notify(author, "Message setup failed; no fallback message was sent.") end
				end)
			elseif kind == "PrivateChat" then
				task.spawn(function()
					if not ready(record, author) then transport.Close(record.Id, "SetupTimeout") end
				end)
			end
		end
		return records[1] and records[1].Id, records
	end

	-- Initializes control endpoints; every client argument is checked against server state.
	function transport.Init()
		local commands = server.Remote.Commands
		commands.ChatTransportReady = function(player)
			clients[player] = true
			for _, record in channels do announce(record, player) end
		end
		commands.ChatChannelReady = function(player, args)
			local record = type(args[1]) == "string" and channels[args[1]]
			if record and record.Members[player] then record.Members[player].Ready = true end
		end
		commands.ChatSendResult = function(player, args)
			local permit = type(args[1]) == "string" and pending[args[1]]
			if not permit or permit.Player ~= player or permit.Expires < os.clock() then return end
			pending[args[1]] = nil
			-- Client reports are telemetry, never proof of recipient delivery or authority.
			server.Logs.AddAudit("Script", "PrivateMessage", player, {
				Outcome = args[2] == "Success" and "Accepted" or "Failed", TargetUserIds = permit.TargetUserIds,
			})
		end
		commands.ChatHelpAccept = function(player, args)
			local record = type(args[1]) == "string" and channels[args[1]]
			if record and record.Kind == "Help" and record.Members[player] and server.Admin.CheckAdmin(player)
				and not record.Accepted and os.clock() - record.Created < 30 then
				record.Accepted = true
				if record.OnAccept then record.OnAccept(player) end
				transport.Close(record.Id, "Answered")
			end
		end
		service.Players.PlayerRemoving:Connect(function(player)
			clients[player] = nil
			for id, record in channels do if record.Members[player] then transport.RemoveMember(id, player) end end
		end)
		service.StartLoop("ChatTransportCleanup", 1, function()
			local now = os.clock()
			for operation, permit in pending do if permit.Expires < now then pending[operation] = nil end end
			for id, record in channels do
				if (record.Kind == "PrivateMessage" and now - record.LastActivity >= 900)
					or (record.Kind ~= "PrivateMessage" and record.Kind ~= "PrivateChat" and now - record.Created >= 30) then
					transport.Close(id, "Expired")
				else
					for player, member in record.Members do
						member.Source.CanSend = member.CanSend and not server.Admin.IsMuted(player)
					end
				end
			end
		end, true)
	end

	server.ChatTransport = transport
end
