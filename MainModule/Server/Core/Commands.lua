server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil
sortedPairs = nil

--// Commands
--// Highly recommended you disable Intellesense before editing this...
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

		--// Automatic New Command Caching and Ability to do server.Commands[":ff"]
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
		
		Logs:AddLog("Script", "Commands Module Initialized")
	end;

	server.Commands = {
		Init = Init;
	};
end
