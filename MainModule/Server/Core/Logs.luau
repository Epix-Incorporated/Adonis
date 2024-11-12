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

	local MaxLogs = 1000
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

		MaxLogs = Settings.MaxLogs;

		Logs.Init = nil;
		Logs:AddLog("Script", "Logging Module Initialized");
	end;

	local UseDLL = not (server.Settings.UseLinkedListsInLogs == false or server.Data.DisableLinkedListsInLogs)

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
		TempUpdaters = {};
		OldCommandLogsLimit = 1000; --// Maximum number of command logs to save to the datastore (the higher the number, the longer the server will take to close)

		TabToType = function(tab)
			local indToName = {
				Chats = "Chat";
				Joins = "Join";
				Leaves = "Leave";
				Script = "Script";
				RemoteFires = "RemoteFire";
				Commands = "Command";
				Exploit = "Exploit";
				Errors = "Error";
				DateTime = "DateTime";
			}

			for ind, t in server.Logs do
				if t == tab then
					return indToName[ind] or ind
				end
			end
		end;

		AddLog = function(tab, log, misc)
			if misc then
				tab = log
				log = misc
			end
			if type(tab) == "string" then
				tab = Logs[tab]
			end

			if type(log) == "string" then
				log = {
					Text = log;
					Desc = log;
				}
			end

			if not log.Time and not log.NoTime then
				log.Time = os.time()
			end

			if tab.__meta == "DLL" then
				tab:AddToStartAndRemoveEndIfEnd(log, MaxLogs)
			else
				table.insert(tab, 1, log)
				if #tab > tonumber(MaxLogs) then
					table.remove(tab, #tab)
				end
			end

			service.Events.LogAdded:Fire(Logs.TabToType(tab), log, tab)
		end;

		-- // Preliminary support for oldlog encryption
		DeserializeOldlogs = function(data)
			if string.sub(data, 1, 1) ~= "[" and string.match(data, "^[%w%+/=]+$") then
				data = Remote.Decrypt(Functions.Base64Decode(data), Settings.DataStoreKey)

				if string.sub(data, 1, 2) == "\x1f\x8b" then -- Check for Gzip header and decode
					data = assert(Functions.GzipDecompress, "No support for Gzip encoding!")(data)
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
			end

			print("Saving command logs...")

			if Settings.SaveCommandLogs ~= true or Settings.DataStoreEnabled ~= true then
				print("Skipped saving command logs.")
				return
			end

			local logsToSave = {Logs.Commands}
			local maxLogs = Logs.OldCommandLogsLimit

			Core.UpdateData("OldCommandLogs", function(oldLogs)
				if type(oldLogs) == "string" then
					xpcall(function()
						oldLogs = Logs.DeserializeOldlogs(oldLogs)
					end, function(reason)
						oldLogs = {}
						warn(`Deserializing oldlogs failed due to {reason}`)
					end)
				end

				local temp = {}

				for _, m in logsToSave do
					if m.__meta == "DLL" then
						local newTab = m:GetAsTable()

						for i,v in pairs(newTab) do
							table.insert(temp,v)
						end
					else
						local isTable = type(m) == "table"
						local newTab = if isTable then table.clone(m) else m

						if (isTable and not newTab.NoSave) or not isTable then
							if isTable and newTab.Player then
								local p = newTab.Player
								newTab.Player = {
									Name = p.Name;
									UserId = p.UserId;
								}
							end
							table.insert(temp, newTab)--{Time = m.Time; Text = `{m.Text}: {m.Desc}`; Desc = m.Desc})
						end
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

			print("Command logs saved!")
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
