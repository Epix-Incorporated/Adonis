server = nil
service = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;
	local DLL = server.DLL;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;
		Logs.MaxLogs = Settings.MaxLogs;

		Logs.Init = nil;
		Logs:AddLog("Script", "Logging Module Initialized");
	end;

	local UseDLL = not (server.Settings.UseLinkedListsInLogs == false or server.Data.DisableLinkedListsInLogs)
	-- Audit event names select fixed display templates; freeform strings never select a template.
	local auditEvents = {
		Command = "Command"; Remote = "Remote request"; Chat = "Chat activity";
		PrivateMessage = "Private message activity"; Join = "Player joined"; Leave = "Player left";
		Error = "Error recorded"; Setting = "Setting changed"; System = "System event";
		Ban = "Player banned"; TimeBan = "Player temporarily banned";
	}
	local outcomes = {Accepted = true, Rejected = true, Completed = true, Failed = true, Requested = true}
	local redacted = "[Text unavailable: source cannot be verified]"

	-- Returns only finite integer metadata, preventing string coercion from exposing input.
	local function integer(value)
		return if type(value) == "number" and value == value and math.abs(value) < math.huge and value % 1 == 0 then value else nil
	end

	-- Copies the supported operational metadata without retaining raw arguments or plugin fields.
	local function auditMetadata(metadata)
		local result = {}
		if type(metadata) ~= "table" then return result end
		if type(metadata.CommandKey) == "string" and server.Commands and rawget(server.Commands, metadata.CommandKey) then
			result.CommandKey = metadata.CommandKey
		end
		if type(metadata.RemoteName) == "string" and server.Remote and
			(server.Remote.Commands[metadata.RemoteName] or server.Remote.Returnables[metadata.RemoteName]) then
			result.RemoteName = metadata.RemoteName
		end
		if outcomes[metadata.Outcome] then result.Outcome = metadata.Outcome end
		result.Count = integer(metadata.Count)
		if type(metadata.TargetUserIds) == "table" then
			result.TargetUserIds = {}
			for _, userId in metadata.TargetUserIds do
				if #result.TargetUserIds >= 100 then break end
				if integer(userId) then table.insert(result.TargetUserIds, userId) end
			end
		end
		return result
	end

	-- Admits only safe-only non-chat records and never retains an unverified record's original text.
	local function auditDetail(record)
		if type(record) ~= "table" or (record.Kind ~= "Moderation" and record.Kind ~= "PublicEdit" and record.Kind ~= "Audit") then return nil end
		local text = server.TextPolicy and server.TextPolicy.GetRecordText(record)
		if not text then return nil end
		local exactShape = true
		for key in record do
			if key ~= "Version" and key ~= "Kind" and key ~= "AuthorUserId" and key ~= "Text" then exactShape = false end
		end
		if record.Text == text and exactShape then return record end
		return {Version = 1, Kind = record.Kind, AuthorUserId = record.AuthorUserId, Text = text}
	end

	server.Logs = {
		Init = Init;
		Chats = if UseDLL then DLL.new() else {};
		Joins = if UseDLL then DLL.new() else {};
		Leaves = if UseDLL then DLL.new() else {};
		Script = if UseDLL then DLL.new() else {};
		RemoteFires = if UseDLL then DLL.new() else {};
		Commands = if UseDLL then DLL.new() else {};
		Exploit = if UseDLL then DLL.new() else {};
		Errors = if UseDLL then DLL.new() else {};
		DateTime = if UseDLL then DLL.new() else {};
		MaxLogs = 1000;
		TempUpdaters = {};
		IndToName = {
			Chats = "Chat";
			Joins = "Join";
			Leaves = "Leave";
			Script = "Script";
			RemoteFires = "RemoteFire";
			Commands = "Command";
			Exploit = "Exploit";
			Errors = "Error";
			DateTime = "DateTime";
		};
		OldCommandLogsLimit = 1000; --// Maximum number of command logs to save to the datastore (the higher the number, the longer the server will take to close)

		-- Creates an audit record from canonical operations and optional explicitly non-chat text.
		AddAudit = function(category, eventId, actor, metadata)
			assert(auditEvents[eventId], "Unknown audit event")
			local userId = actor and integer(actor.UserId)
			local record = {
				SchemaVersion = 1; EventId = eventId; Time = os.time();
				NoSave = type(metadata) == "table" and metadata.NoSave == true;
				Player = if userId then {UserId = userId} else nil;
				Metadata = auditMetadata(metadata);
			}
			local detail = type(metadata) == "table" and metadata.DetailRecord
			if type(detail) == "table" and (detail.Kind == "Moderation" or detail.Kind == "PublicEdit" or detail.Kind == "Audit") then
				record.DetailRecord = auditDetail(detail)
			end
			server.Logs.AddLog(category, record)
			return record
		end;

		-- Projects both current and historical records to the only supported client-facing log shape.
		Project = function(entries, category)
			local result = {}
			if type(entries) ~= "table" then return result end
			if entries.__meta == "DLL" then entries = entries:GetAsTable() end
			for _, entry in entries do
				local row = {Text = redacted, Desc = redacted}
				if type(entry) == "table" then
					row.Time = integer(entry.Time)
					local userId = type(entry.Player) == "table" and integer(entry.Player.UserId)
					if userId then row.Player = {UserId = userId} end
					if entry.SchemaVersion == 1 and auditEvents[entry.EventId] then
						local metadata = auditMetadata(entry.Metadata)
						local parts = {auditEvents[entry.EventId]}
						if metadata.CommandKey then table.insert(parts, metadata.CommandKey) end
						if metadata.RemoteName then table.insert(parts, metadata.RemoteName) end
						if metadata.Outcome then table.insert(parts, metadata.Outcome) end
						if metadata.Count then table.insert(parts, `Count: {metadata.Count}`) end
						if metadata.TargetUserIds and #metadata.TargetUserIds > 0 then
							table.insert(parts, `Targets: {table.concat(metadata.TargetUserIds, ", ")}`)
						end
						row.Text = table.concat(parts, " | ")
						row.Desc = row.Text
						local detail = entry.DetailRecord
						if type(detail) == "table" and (detail.Kind == "Moderation" or detail.Kind == "PublicEdit" or detail.Kind == "Audit") then
							local text = server.TextPolicy and server.TextPolicy.GetRecordText(detail)
							row.Desc ..= ` | {text or redacted}`
						end
					elseif category == "Joins" or category == "Leaves" then
						row.Text = if category == "Joins" then "Player joined" else "Player left"
						row.Desc = row.Text
					end
					if userId then row.Text = `User {userId}: {row.Text}` end
				end
				table.insert(result, row)
			end
			return result
		end;

		-- Console messages have no reliable author; expose timing and severity without their bodies.
		ProjectConsole = function(history)
			local result = {}
			for _, entry in if type(history) == "table" then history else {} do
				if type(entry) == "table" then
					local severity = "Output"
					for _, messageType in Enum.MessageType:GetEnumItems() do
						if entry.messageType == messageType then severity = messageType.Name end
					end
					table.insert(result, {Text = redacted, Desc = severity, Time = integer(entry.timestamp or entry.Time)})
				end
			end
			return result
		end;

		-- Task names can contain submitted command text; retain only fixed state and numeric timing.
		ProjectTasks = function(tasks)
			local result = {}
			for _, entry in if type(tasks) == "table" then tasks else {} do
				if type(entry) == "table" then
					local status = if entry.Status == "Running" or entry.Status == "Waiting" or entry.Status == "Finished" then entry.Status else "Tracked"
					table.insert(result, {Text = `Task: {status}`, Desc = "Task text is unavailable", Time = integer(entry.Created)})
				end
			end
			return result
		end;

		TabToType = function(tab)
			for ind, t in server.Logs do
				if t == tab then
					return server.Logs.IndToName[ind] or ind
				end
			end
		end;

		-- Retains the legacy calling forms while discarding unclassified text at ingestion.
		AddLog = function(tab, log, misc)
			if misc then
				tab = log
				log = misc
			end
			local category = if type(tab) == "string" then tab else Logs.TabToType(tab)
			if type(tab) == "string" then
				tab = Logs[tab]
			end

			if type(log) == "string" then
				log = {
					Text = log;
					Desc = log;
				}
			end

			local player = type(log) == "table" and log.Player
			local userId = player and integer(player.UserId)
			local source = if type(log) == "table" then log else {}
			log = {
				Time = integer(source.Time); NoTime = source.NoTime == true; NoSave = source.NoSave == true;
				Player = if userId then {UserId = userId} else nil;
				SchemaVersion = if source.SchemaVersion == 1 and auditEvents[source.EventId] then 1 else nil;
				EventId = if auditEvents[source.EventId] then source.EventId else nil;
				Metadata = auditMetadata(source.Metadata);
				DetailRecord = auditDetail(source.DetailRecord);
			}
			local projected = Logs.Project({log}, category)[1]
			log.Text, log.Desc = projected.Text, projected.Desc

			if not log.Time and not log.NoTime then
				log.Time = os.time()
			end

			local p = log.Player
			if p and type(p) ~= "table" then
				local pData = Core.PlayerData[tostring(p.UserId)]
				local UserInfo = pData and pData.UserInfo or { Name = p.Name, UserId = p.UserId }
				if pData and not pData.UserInfo then
					pData.UserInfo = UserInfo
				end

				log.Player = UserInfo
			end

			if tab then
				if tab.__meta == "DLL" then
					tab:AddToStartAndRemoveEndIfEnd(log, Logs.MaxLogs)
				else
					table.insert(tab, 1, log)
					if #tab > tonumber(Logs.MaxLogs) then
						table.remove(tab, #tab)
					end
				end

				service.Events.LogAdded:Fire(Logs.TabToType(tab), log, tab)
			end
		end;

		-- // Preliminary support for oldlog encryption
		DeserializeOldlogs = function(data)
			if string.sub(data, 1, 1) ~= "[" and string.match(data, "^[%w%+/=]+$") then
				data = Remote.NewDecrypt(Functions.Base64Decode(data), Settings.DataStoreKey)

				if string.sub(data, 1, 2) == "\x1f\x8b" then -- Check for Gzip header and decode
					data = assert(Functions.GzipDecompress, "No support for Gzip encoding!")(data)
				elseif string.sub(data, 1, 2) == "\x28\xB5\x2F\xFD" then -- Check for Zstd header and decode
					data = assert(Functions.ZstdDecompress, "No support for Zstandard encoding!")(data)
				elseif string.match(data, "^\x78[\x01\x5e\x9c\xda\x20\x7d\xbb\xf9]") then -- Check for Zlib header and decode
					data = assert(Functions.ZlibDecompress, "No support for Zlib encoding!")(data)
				end
			end

			return service.HttpService:JSONDecode(data)
		end;

		SaveCommandLogs = function()
			--// Disable saving command logs in Studio; not required.
			if service.RunService:IsStudio() or service.RunService:IsRunMode() then
				return
			elseif not server.Data or not server.Data.SilentStartup then
				print("Saving command logs...")
			end

			if Settings.SaveCommandLogs ~= true or Settings.DataStoreEnabled ~= true then
				if not server.Data or not server.Data.SilentStartup then
					print("Skipped saving command logs.")
				end

				return
			end

			local logsToSave = {Logs.Commands}
			local maxLogs = Logs.OldCommandLogsLimit

			Core.UpdateData("OldCommandLogs", function(oldLogs)
				if type(oldLogs) == "string" then
					xpcall(function()
						oldLogs = Logs.DeserializeOldlogs(oldLogs)
					end, function()
						oldLogs = {}
						warn("Deserializing oldlogs failed")
					end)
				end

				local temp = table.create((oldLogs and #oldLogs or 0) + #logsToSave + (Logs.Commands.__meta == "DLL" and Logs.Commands.count or 0))

				-- Copies new safe records without mutating the in-memory audit stream.
				local function insertLog(log)
					local isTable = type(log) == "table"
					local newTab = if isTable then table.clone(log) else log

					if (isTable and not log.NoSave) or not isTable then
						if isTable and log.Player and type(log.Player) ~= "table" then
							local p = log.Player
							log.Player = {
								Name = p.Name;
								UserId = p.UserId;
							}
						end
						table.insert(temp, newTab)
					end
				end

				for _, m in logsToSave do
					if m.__meta == "DLL" then
						local newTab = m:GetAsTable()

						for _, v in ipairs(newTab) do
							insertLog(v)
						end
					else
						for _, entry in m do insertLog(entry) end
					end
				end

				if oldLogs then
					for _, m in oldLogs do
						table.insert(temp, m)
					end
				end

				table.sort(temp, function(a, b)
					if a.Time and b.Time and type(a.Time) == "number" and type(b.Time) == "number" then
						return a.Time > b.Time
					else
						return false
					end
				end)

				--// Trim logs, starting from the oldest
				if #temp > maxLogs then
					local diff = #temp - maxLogs

					for i = 1, diff do
						table.remove(temp, #temp)
					end
				end

				return service.HttpService:JSONEncode(temp)
			end)

			if not server.Data or not server.Data.SilentStartup then
				print("Command logs saved!")
			end
		end;

		ListUpdaters = {
			TempUpdate = function(plr, data)
				local updateKey = data.UpdateKey
				local updater = Logs.TempUpdaters[updateKey]
				if updater then
					return updater(data)
				end
			end;
		};
	};

	Logs = Logs
end
