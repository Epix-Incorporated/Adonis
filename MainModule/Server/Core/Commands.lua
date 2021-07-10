server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil
sortedPairs = nil

--// Commands
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
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

		--// Cache all commands into a dictionary
		setmetatable(Commands, {
			__index = function(self, ind)
				local targInd = Admin.CommandCache[ind:lower()]
				if targInd then
					return rawget(Commands, targInd)
				end
			end;

			__newindex = function(self, ind, val)
				rawset(Commands, ind, val)
				if val and type(val) == "table" and val.Commands and val.Prefix then
					for i,cmd in next,val.Commands do
						Admin.PrefixCache[val.Prefix] = true;
						Admin.CommandCache[(val.Prefix..cmd):lower()] = ind;
					end
				end
			end;
		})

		Logs:AddLog("Script", "Loading Command Modules...")

		--// Load command modules
		if server.CommandModules then
			for i,module in next,server.CommandModules:GetChildren() do
				local func = require(module)
				local ran,tab = pcall(func, Vargs, getfenv())

				if ran and tab and type(tab) == "table" then
					for ind,cmd in next,tab do
						Commands[ind] = cmd;
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
		Admin.CacheCommands();

		Commands.Init = nil;
		Logs:AddLog("Script", "Commands Module Initialized")
	end;

	function RunAfterPlugins()
		--// Load custom user-supplied commands (settings.Commands)
		for ind,cmd in next,Settings.Commands do
			setfenv(cmd.Function, getfenv());
			Commands[ind] = cmd;
		end

		--// Change command permissions based on settings
		for ind, cmd in next, Settings.Permissions or {} do
			local com, level = cmd:match("^(.*):(.*)")
			if com and level then
				if level:find(",") then
					local newLevels = {}
					for lvl in level:gmatch("[^%,]+") do
						table.insert(newLevels, service.Trim(lvl))
					end

					Admin.SetPermission(com, newLevels)
				else
					Admin.SetPermission(com, level)
				end
			end
		end

		--// Update existing permissions to new levels
		for i, cmd in next, Commands do
			if type(cmd) == "table" and cmd.AdminLevel then
				local lvl = cmd.AdminLevel;
				if type(lvl) == "string" then
					cmd.AdminLevel = Admin.StringToComLevel(lvl);
				elseif type(lvl) == "table" then
					for b,v in next,lvl do
						if type(v) == "string" then
							lvl[b] = Admin.StringToComLevel(v);
						end
					end
				end

				if not cmd.Prefix then
					cmd.Prefix = Settings.Prefix;
				end
			end
		end

		Commands.RunAfterPlugins = nil;
	end;

	server.Commands = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
	};
end
