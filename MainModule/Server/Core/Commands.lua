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
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps, t

	local RegisterCommandDefinition

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
		t = server.Typechecker;

		local ValidateCommandDefinition = t.interface({
			Prefix = t.string,
			Commands = t.array(t.string),
			Description = t.string,
			AdminLevel = t.union(t.string, t.number, t.nan, t.array(t.union(t.string, t.number, t.nan))),
			Fun = t.boolean,
			Hidden = t.boolean,
			Disabled = t.boolean,
			NoStudio = t.boolean,
			NonChattable = t.boolean,
			AllowDonors = t.boolean,
			Filter = t.boolean,
			Function = t.callback,
			ListUpdater = t.optional(t.union(t.string, t.callback))
		})

		function RegisterCommandDefinition(ind, cmd)
			if type(ind) ~= "string" then
				logError("Non-string command index:", typeof(ind), ind)
				Commands[ind] = nil
				return
			end
			if type(cmd) ~= "table" then
				logError("Non-table command definition:", ind)
				Commands[ind] = nil
				return
			end

			for opt, default in pairs({
				Prefix = Settings.Prefix;
				Commands = {};
				Description = "(No description)";
				Fun = false;
				Hidden = false;
				Disabled = false;
				NoStudio = false;
				NonChattable = false;
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

			if cmd.Chattable ~= nil then
				cmd.NonChattable = not cmd.Chattable
				cmd.Chattable = nil
				logError("Deprecated 'Chattable' property found in command "..ind.."; switched to NonChattable = "..tostring(cmd.NonChattable))
			end

			Admin.PrefixCache[cmd.Prefix] = true

			for _, cmd in ipairs(cmd.Commands) do
				Admin.CommandCache[string.lower((cmd.Prefix..cmd))] = ind
			end

			cmd.Args = cmd.Args or cmd.Arguments or {}

			local lvl = cmd.AdminLevel
			if type(lvl) == "string" then
				cmd.AdminLevel = Admin.StringToComLevel(lvl)
			elseif type(lvl) == "table" then
				for b, v in ipairs(lvl) do
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

			local isValid, fault = ValidateCommandDefinition(cmd)
			if not isValid then
				logError("Invalid command definition table "..ind..":", fault)
				Commands[ind] = nil
			end

			rawset(Commands, ind, cmd)
		end

		--// Automatic New Command Caching and Ability to do server.Commands[":ff"]
		setmetatable(Commands, {
			__index = function(_, ind)
				if type(ind) ~= "string" then return nil end
				local targInd = Admin.CommandCache[string.lower(ind)]
				return if targInd then rawget(Commands, targInd) else rawget(Commands, ind)
			end;

			__newindex = function(_, ind, val)
				if val == nil then
					if rawget(Commands, ind) ~= nil then
						rawset(Commands, ind, nil)
						Logs.AddLog("Script", "Removed command definition:", ind)
					end
				elseif Commands.RunAfterPlugins then
					rawset(Commands, ind, val)
				else
					if rawget(Commands, ind) ~= nil then
						Logs.AddLog("Script", "Overwriting command definition:", ind)
					end
					RegisterCommandDefinition(ind, val)
				end
			end;
		})

		Logs.AddLog("Script", "Loading Command Modules...")

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

					Logs.AddLog("Script", "Loaded Command Module: ".. module.Name)
				elseif not ran then
					warn("CMDMODULE ".. module.Name .. " failed to load:")
					warn(tostring(tab))
					Logs.AddLog("Script", "Loading Command Module Failed: ".. module.Name)
				end
			end
		end

		--// Cache commands
		Admin.CacheCommands()

		Commands.Init = nil
		Logs.AddLog("Script", "Commands Module Initialized")
	end

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

		for ind, cmd in pairs(Commands) do
			RegisterCommandDefinition(ind, cmd)
		end

		Commands.RunAfterPlugins = nil
	end

	server.Commands = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
	};
end
