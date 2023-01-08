server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil

--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;

	local Settings = server.Settings
	local Logs =
		server.Logs

	-- // Remove legacy trello board
	local epix_board_index = type(Settings.Trello_Secondary) == "table" and table.find(Settings.Trello_Secondary, "9HH6BEX2")
	if epix_board_index then
		table.remove(Settings.Trello_Secondary, epix_board_index)
		Logs:AddLog("Script", "Removed legacy trello board")
	end

	Logs:AddLog("Script", "Misc Features Module Loaded")
end
