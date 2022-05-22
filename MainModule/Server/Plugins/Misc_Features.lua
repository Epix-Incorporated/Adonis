server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil

--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	Logs:AddLog("Script", "Misc Features Module Loaded");
end;
