--!nocheck
-- Centralizes authored non-chat text filtering, edit admission, and safe publication records.
return function(Vargs, GetEnv)
	local server = Vargs.Server
	local service = Vargs.Service
	local nextEdit = {}
	local trustedRecords = setmetatable({}, {__mode = "k"})
	local preparedCalls = setmetatable({}, {__mode = "k"})
	local publishedCalls = setmetatable({}, {__mode = "k"})
	local wrappedCommands = setmetatable({}, {__mode = "k"})
	local publicationContexts = setmetatable({}, {__mode = "k"})
	local publicationIds = {}
	local kinds = table.freeze({Announcement = true, Moderation = true, PublicEdit = true, Audit = true})
	local policy = {}
	local commandErrors = table.freeze({
		["Chat is unavailable."] = true,
		["Enter chat text yourself; generated commands cannot send messages."] = true,
		["This message matches a chat command. Change its opening text before sending."] = true,
		["No available recipients."] = true,
		["Too many pending messages; wait for earlier sends to finish."] = true,
		["Chat capacity reached; please try again later."] = true,
		["Text could not be filtered. Please try again later."] = true,
		["User messages must be sent through TextChannels."] = true,
		["Cross-server player messages are not supported; send the message in the current server."] = true,
		["Cross-server commands require one supported command; aliases, batches, and command loops are unavailable."] = true,
	})

	-- Exposes fixed policy failures while keeping arbitrary plugin and runtime exceptions private.
	function policy.ProjectCommandError(value)
		if type(value) == "string" then
			local message = value:match("^.-:%d+: (.*)$") or value
			if commandErrors[message] then return message end
			local remaining = tonumber(message:match("^Wait (%d+) seconds before editing shared text again$"))
			if remaining and remaining >= 0 and remaining <= 60 then
				return `Wait {remaining} seconds before editing shared text again`
			end
		end
		return "Command failed; details are unavailable."
	end

	-- Resolves a connected real author; fake players and supplied identity tables are not authors.
	local function getAuthor(author)
		local player = service.UnWrap(author)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return nil
		end
		return if service.UnWrap(service.Players:GetPlayerByUserId(player.UserId)) == player then player else nil
	end

	-- Validates the serialized shape without treating persisted fields as proof of filtering.
	local function validRecord(record)
		return type(record) == "table" and record.Version == 1 and kinds[record.Kind] == true
			and type(record.AuthorUserId) == "number" and record.AuthorUserId > 0
			and type(record.Text) == "string" and utf8.len(record.Text) ~= nil
	end

	-- Reserves the author's shared sixty-second public edit allowance before any yielding work.
	function policy.TryPublicEdit(author)
		local player = getAuthor(author)
		if not player then
			return false, 60
		end
		local now = os.clock()
		local remaining = (nextEdit[player.UserId] or 0) - now
		if remaining > 0 then
			return false, remaining
		end
		nextEdit[player.UserId] = now + 60
		return true, 0
	end

	-- Filters one submission for every viewer and exposes failure without returning the source text.
	function policy.FilterBroadcast(text, author)
		return service.TryFilter(text, author, nil, true)
	end

	-- Filters a non-chat submission for one recipient; conversational text uses TextChannels instead.
	function policy.FilterForUser(text, author, recipient)
		return service.TryFilter(text, author, recipient, false)
	end

	-- Creates a safe-only authored record; raw input is never included in the returned record.
	function policy.CreateRecord(text, author, kind)
		if not kinds[kind] then
			return nil, "InvalidKind"
		end
		local player = getAuthor(author)
		if not player then
			return nil, "AuthorUnavailable"
		end
		local filtered, code = policy.FilterBroadcast(text, player)
		if filtered == nil then
			return nil, code
		end
		local record = table.freeze({Version = 1, AuthorUserId = player.UserId, Kind = kind, Text = filtered})
		trustedRecords[record] = filtered
		return record
	end

	-- Refilters stored text with its actual author, failing closed for legacy records or offline authors.
	function policy.ProjectRecord(record)
		if not validRecord(record) then
			return nil, "UnattributedText"
		end
		local author = service.Players:GetPlayerByUserId(record.AuthorUserId)
		if not author then
			return nil, "AuthorUnavailable"
		end
		return policy.FilterBroadcast(record.Text, author)
	end

	-- Uses a privately trusted live snapshot, or freshly projects a record loaded from storage.
	function policy.GetRecordText(record)
		local snapshot = if type(record) == "table" then trustedRecords[record] else nil
		if snapshot ~= nil then
			return snapshot
		end
		return policy.ProjectRecord(record)
	end

	-- Separates the text's actual author from an impersonated command execution identity.
	function policy.GetCommandAuthor(actor)
		local context = publicationContexts[coroutine.running()]
		return if context then context.Author else getAuthor(actor)
	end

	-- Formats only records from the current published invocation with fixed numeric author attribution.
	-- Local commands and untrusted records cannot use this path to authorize arbitrary display text.
	function policy.FormatPublishedRecord(record, presentation)
		local context = publicationContexts[coroutine.running()]
		if not context or not context.Published or type(record) ~= "table" or trustedRecords[record] == nil then return nil end
		local belongsToInvocation = false
		for _, accepted in context.Records do
			if accepted == record then belongsToInvocation = true break end
		end
		if not belongsToInvocation then return nil end
		local attribution = `User {record.AuthorUserId}`
		local text
		if presentation == "Author" then
			text = attribution
		elseif presentation == "AnnouncementTitle" then
			text = `Message from {attribution}`
		elseif presentation == "Hint" then
			text = `{attribution}: {trustedRecords[record]}`
		else
			return nil
		end
		local formatted = table.freeze({Version = 1, AuthorUserId = record.AuthorUserId, Kind = record.Kind, Text = text})
		trustedRecords[formatted] = text
		return formatted
	end

	-- Resolves helper text from an authored record, an explicit author, or the active command author.
	-- Calls outside commands without an author are reserved for developer-authored system text.
	function policy.GetPublicationText(value, authorOrRecord)
		if value == nil then return nil end
		if type(authorOrRecord) == "table" and authorOrRecord.Version == 1 then
			return policy.GetRecordText(authorOrRecord) or "Text unavailable"
		end
		if type(value) ~= "string" and type(value) ~= "number" then return "Text unavailable" end
		local text = tostring(value)
		local context = publicationContexts[coroutine.running()]
		if context then
			for _, record in context.Records do
				if trustedRecords[record] == text then return text end
			end
		end
		local author = if context then context.Author else authorOrRecord
		if author or context then
			return policy.FilterBroadcast(text, author) or "Text unavailable"
		end
		return text
	end

	-- Scopes helper publication to this yielding invocation and restores its parent even after errors.
	local function invoke(command, original, actor, args, data, records, textAuthor, published)
		local thread = coroutine.running()
		local previous = publicationContexts[thread]
		publicationContexts[thread] = {Author = textAuthor, Records = records or {}, Published = published == true}
		local result = table.pack(pcall(original, actor, args, data))
		publicationContexts[thread] = previous
		if not result[1] then error(result[2], 0) end
		if not command.NoLog and not (data and data.Options and data.Options.DontLog) and records and next(records) and server.Logs and server.Logs.AddAudit then
			local _, record = next(records)
			server.Logs.AddAudit("Commands", "Command", textAuthor, {
				CommandKey = command.CommandKey, DetailRecord = record, Outcome = "Completed",
				NoSave = command.AdminLevel == 0 or command.AdminLevel == "Players" or command.AdminLevel == "Donors" or command.Donors == true,
			})
		end
		return table.unpack(result, 2, result.n)
	end

	-- Packages only locally trusted non-chat records for the authenticated server messaging route.
	function policy.CreatePublication(records)
		local safeRecords = {}
		for key, record in records do
			if type(key) ~= "string" or not validRecord(record) or trustedRecords[record] == nil then
				return nil, "UntrustedPublication"
			end
			safeRecords[key] = record
		end
		return {Version = 1, Id = service.HttpService:GenerateGUID(false), Records = safeRecords}
	end

	-- Accepts a typed origin-filtered server publication once; this must never be exposed as a client remote.
	function policy.AcceptPublication(jobId, publication)
		if type(jobId) ~= "string" or type(publication) ~= "table" or publication.Version ~= 1
			or type(publication.Id) ~= "string" or #publication.Id > 100 or type(publication.Records) ~= "table" then
			return nil, "InvalidPublication"
		end
		local now = os.clock()
		for key, expires in publicationIds do
			if expires <= now then publicationIds[key] = nil end
		end
		local key = `{jobId}:{publication.Id}`
		if publicationIds[key] then return nil, "DuplicatePublication" end
		local accepted = {}
		local count = 0
		for name, record in publication.Records do
			count += 1
			if count > 64 or type(name) ~= "string" or not validRecord(record) then
				return nil, "InvalidPublication"
			end
			local copy = table.freeze({Version = 1, AuthorUserId = record.AuthorUserId, Kind = record.Kind, Text = record.Text})
			accepted[name] = copy
		end
		publicationIds[key] = now + 300
		for _, record in accepted do trustedRecords[record] = record.Text end
		return accepted
	end

	-- Recognizes fixed parser control words which remove text instead of publishing user content.
	local function displayedArgument(metadata, index, value)
		local exempt = metadata.ExemptValues and metadata.ExemptValues[index]
		return value ~= nil and not (type(value) == "string" and exempt and exempt[value:lower()])
	end

	-- Filters declared argument positions for every viewer and reserves at most one public edit allowance.
	-- Audience selects the filter projection; command targeting still determines who receives the result.
	function policy.PrepareArguments(author, args, metadata)
		assert(metadata.Kind ~= "Announcement", "User messages must be sent through TextChannels.")
		assert(kinds[metadata.Kind], "Invalid user text policy")
		assert(metadata.Audience == "Broadcast", "Non-chat text requires a broadcast-safe audience")
		local filteredArgs = table.clone(args or {})
		local records = {}
		local hasText = false
		for _, index in metadata.Args or {} do
			if displayedArgument(metadata, index, filteredArgs[index]) then hasText = true end
		end
		if hasText and metadata.Kind == "PublicEdit" then
			local allowed, remaining = policy.TryPublicEdit(author)
			assert(allowed, `Wait {math.ceil(remaining)} seconds before editing shared text again`)
		end
		for _, index in metadata.Args or {} do
			if displayedArgument(metadata, index, filteredArgs[index]) then
				local record = policy.CreateRecord(filteredArgs[index], author, metadata.Kind)
				if record then
					filteredArgs[index] = record.Text
					records[index] = record
				elseif metadata.Kind == "Moderation" then
					filteredArgs[index] = "Reason unavailable"
				else
					error("Text could not be filtered. Please try again later.", 0)
				end
			end
		end
		return filteredArgs, records
	end

	-- Binds accepted server records to one exact command invocation without trusting serialized flags.
	function policy.AuthorizePublishedCommand(command, author, args, records)
		local metadata = command.UserText
		if not metadata or metadata.Kind == "Announcement" or not kinds[metadata.Kind] or metadata.Audience ~= "Broadcast" then return nil end
		local filteredArgs = table.clone(args)
		local commandRecords = {}
		for _, index in metadata.Args or {} do
			if displayedArgument(metadata, index, filteredArgs[index]) then
				local record = records[tostring(index)]
				if record and trustedRecords[record] and record.Kind == metadata.Kind and record.AuthorUserId == author.UserId then
					filteredArgs[index] = record.Text
					commandRecords[index] = record
				elseif metadata.Kind == "Moderation" then
					filteredArgs[index] = "Reason unavailable"
				else
					return nil
				end
			end
		end
		local token = {}
		publishedCalls[token] = {Command = command, Author = author, Args = filteredArgs, Records = commandRecords}
		return token, filteredArgs
	end

	-- Applies declared displayed arguments at the command function boundary, including direct callers.
	function policy.WrapCommand(command, commandKey)
		if wrappedCommands[command] == command.Function then return end
		command.CommandKey = commandKey
		local original = command.Function
		command.Function = function(author, args, data)
			local metadata = command.UserText
			data = data or {}
			local options = data.Options or {}
			local originAuthor = server.ChatTransport and server.ChatTransport.ResolveOriginAuthor(options.UserCommandOrigin)
			local textAuthor = originAuthor or (if options.isSystem then nil else policy.GetCommandAuthor(author))
			if not metadata or metadata.Kind == "Chat" then return invoke(command, original, author, args, data, nil, textAuthor) end
			assert(kinds[metadata.Kind], "Invalid user text policy")
			local token = data.Options and data.Options.TextPublication
			local published = token and publishedCalls[token]
			if published and published.Command == command and published.Author == author and published.Args == args then
				publishedCalls[token] = nil
				data.UserTextRecords = published.Records
				return invoke(command, original, author, args, data, published.Records, author, true)
			end
			local prepared = preparedCalls[data]
			if prepared and prepared.Command == command and prepared.Args == args and prepared.Author == author then
				return invoke(command, original, author, args, data, data.UserTextRecords, prepared.TextAuthor)
			end
			local filteredArgs, records = policy.PrepareArguments(textAuthor, args, metadata)
			local context = table.clone(data)
			context.UserTextRecords = records
			preparedCalls[context] = {Command = command, Args = filteredArgs, Author = author, TextAuthor = textAuthor}
			local result = table.pack(pcall(invoke, command, original, author, filteredArgs, context, records, textAuthor))
			preparedCalls[context] = nil
			if not result[1] then error(result[2], 0) end
			return table.unpack(result, 2, result.n)
		end
		wrappedCommands[command] = command.Function
	end

	server.TextPolicy = policy
end
