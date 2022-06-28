server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil

--// Commands
--// Highly recommended you disable Intellesense before editing this...
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps

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
		Commands = server.Commands;
		Deps = server.Deps;

		--// Automatic New Command Caching and Ability to do server.Commands[":ff"]
		setmetatable(Commands, {
			__index = function(self, ind)
				local targInd = Admin.CommandCache[string.lower(ind)]
				if targInd then
					return rawget(Commands, targInd)
				end
			end;

			__newindex = function(self, ind, val)
				rawset(Commands, ind, val)
				if val and type(val) == "table" and val.Commands and val.Prefix then
					for i, cmd in pairs(val.Commands) do
						Admin.PrefixCache[val.Prefix] = true
						Admin.CommandCache[string.lower((val.Prefix..cmd))] = ind
					end
				end
			end;
		})

		Logs:AddLog("Script", "Loading Command Modules...")

		--// Load command modules
		if server.CommandModules then
			local env = GetEnv()
			for i, module in ipairs(server.CommandModules:GetChildren()) do
				local func = require(module)
				local ran, tab = pcall(func, Vargs, env)

				if ran and tab and type(tab) == "table" then
					for ind, cmd in pairs(tab) do
						Commands[ind] = cmd
					end

					Logs:AddLog("Script", "Loaded Command Module: ".. module.Name)
				elseif not ran then
					warn("CMDMODULE ".. module.Name .. " failed to load:")
					warn(tostring(tab))
					Logs:AddLog("Script", "Loading Command Module Failed: ".. module.Name)
				end
			end
		end

		--// Cache commands
		Admin.CacheCommands()

		Commands.Init = nil
		Logs:AddLog("Script", "Commands Module Initialized")
	end;

	local function RunAfterPlugins()
		--// Load custom user-supplied commands in settings.Commands

		local commandEnv = GetEnv(nil, {
			script = server.Config and server.Config:FindFirstChild("Settings") or script;
		})
		for ind, cmd in pairs(Settings.Commands or {}) do
			if type(cmd) == "table" and cmd.Function then
				setfenv(cmd.Function, commandEnv)
				Commands[ind] = cmd
			end
		end

		--// Change command permissions based on settings
		local Trim = service.Trim
		for ind, cmd in pairs(Settings.Permissions or {}) do
			local com, level = string.match(cmd, "^(.*):(.*)")
			if com and level then
				if string.find(level, ",") then
					local newLevels = {}
					for lvl in string.gmatch(level, "[^%s,]+") do
						table.insert(newLevels, Trim(lvl))
					end

					Admin.SetPermission(com, newLevels)
				else
					Admin.SetPermission(com, level)
				end
			end
		end

		--// Update existing permissions to new levels
		for ind, cmd in pairs(Commands) do
			if type(ind) ~= "string" then
				warn("Non-string command index found:", typeof(ind), ind)
				Commands[ind] = nil
				continue
			end
			if type(cmd) ~= "table" then
				warn("Non-table command definition found:", ind)
				Commands[ind] = nil
				continue
			end

			for opt, default in pairs({
				Prefix = Settings.Prefix;
				Commands = {};
				Description = "(No description)";
				Fun = false;
				Hidden = false;
				Disabled = false;
				NoStudio = false;
				Chattable = true;
				AllowDonors = false;
				CrossServerDenied = false;
				IsCrossServer = false;
				Filter = false;
				Function = function(plr)
					Remote.MakeGui(plr, "Output", {Message = "No command implementation"})
				end
				})
			do
				if cmd[opt] == nil then
					cmd[opt] = default
				end
			end

			cmd.Args = cmd.Args or cmd.Arguments or {}

			local lvl = cmd.AdminLevel
			if type(lvl) == "string" then
				cmd.AdminLevel = Admin.StringToComLevel(lvl)
				--print("Changed " .. tostring(lvl) .. " to " .. tostring(cmd.AdminLevel))
			elseif type(lvl) == "table" then
				for b, v in pairs(lvl) do
					lvl[b] = Admin.StringToComLevel(v)
				end
			elseif type(lvl) == "nil" then
				cmd.AdminLevel = 0
			end

			if cmd.ListUpdater then
				Logs.ListUpdaters[ind] = function(plr, ...)
					if not plr or Admin.CheckComLevel(Admin.GetLevel(plr), cmd.AdminLevel) then
						if type(cmd.ListUpdater) == "function" then
							return cmd.ListUpdater(plr, ...)
						end

						return Logs[cmd.ListUpdater]
					end
				end
			end
		end

		Commands.RunAfterPlugins = nil
	end;

	server.Commands = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
	};
end
