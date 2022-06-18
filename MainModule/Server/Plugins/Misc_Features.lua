server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil

--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs, env)
	if env then
		setfenv(1, env)
	end

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	-- // Remove legacy trello board
	local epix_board_index = type(Settings.Trello_Secondary) == "table" and table.find(Settings.Trello_Secondary, "9HH6BEX2")
	if epix_board_index then
		table.remove(Settings.Trello_Secondary, epix_board_index)
		Logs:AddLog("Script", "Removed legacy trello board");
	end

	Logs:AddLog("Script", "Misc Features Module Loaded");
end;
