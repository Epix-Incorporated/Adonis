server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, { script = script })
	setfenv(1, env)

	server = Vargs.Server
	service = Vargs.Service

	local MaxLogs = 1000
	local Core, Logs, Settings
	local function Init()
		Core = server.Core
		Logs = server.Logs
		Settings = server.Settings

		MaxLogs = Settings.MaxLogs

		Logs.Init = nil
		Logs:AddLog("Script", "Logging Module Initialized")
	end

	server.Logs = {
		Init = Init,
		Chats = {},
		Joins = {},
		Leaves = {},
		Script = {},
		RemoteFires = {},
		Commands = {},
		Exploit = {},
		Errors = {},
		DateTime = {},
		TempUpdaters = {},
		OldCommandLogsLimit = 1000, --// Maximum number of command logs to save to the datastore (the higher the number, the longer the server will take to close)

		TabToType = function(tab)
			local indToName = {
				Chats = "Chat",
				Joins = "Join",
				Leaves = "Leave",
				Script = "Script",
				RemoteFires = "RemoteFire",
				Commands = "Command",
				Exploit = "Exploit",
				Errors = "Error",
				DateTime = "DateTime",
			}

			for ind, t in server.Logs do
				if t == tab then
					return indToName[ind] or ind
				end
			end
		end,

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
					Text = log,
					Desc = log,
				}
			end

			if not log.Time and not log.NoTime then
				log.Time = os.time()
			end

			table.insert(tab, 1, log)
			if #tab > tonumber(MaxLogs) then
				table.remove(tab, #tab)
			end

			service.Events.LogAdded:Fire(server.Logs.TabToType(tab), log, tab)
		end,

		SaveCommandLogs = function()
			--// Disable saving command logs in Studio; not required.
			if service.RunService:IsStudio() or service.RunService:IsRunMode() then
				return
			end

			warn("Saving command logs...")

			if Settings.SaveCommandLogs ~= true or Settings.DataStoreEnabled ~= true then
				warn("Skipped saving command logs.")
				return
			end

			local logsToSave = Logs.Commands --{}
			local maxLogs = Logs.OldCommandLogsLimit

			Core.UpdateData("OldCommandLogs", function(oldLogs)
				local temp = {}

				for _, m in logsToSave do
					local newTab = type(m) == "table" and service.CloneTable(m) or m
					if type(m) == "table" and newTab.Player then
						local p = newTab.Player
						newTab.Player = {
							Name = p.Name,
							UserId = p.UserId,
						}
					end
					table.insert(temp, newTab)
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
						table.remove(temp, 1)
					end
				end

				return temp
			end)

			warn("Command logs saved!")
		end,

		ListUpdaters = {
			TempUpdate = function(_, data)
				local updateKey = data.UpdateKey
				local updater = Logs.TempUpdaters[updateKey]
				if updater then
					return updater(data)
				end
			end,
		},
	}

	Logs = Logs
end
