server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil
sortedPairs = nil

--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;

	--// *Try?* to enable AllowThirdPartySales (honestly, this obviously wouldn't work but roblox be kinda weird sometimes so yolo)
	pcall(function() service.Workspace.AllowThirdPartySales = true end)

	--// Worksafe
	if Settings.AntiLeak and not service.ServerScriptService:FindFirstChild("ADONIS_AntiLeak") then
		local ancsafe = server.Deps.Assets.WorkSafe:Clone()
		ancsafe.Mode.Value = "AntiLeak"
		ancsafe.Name = "ADONIS_AntiLeak"
		ancsafe.Archivable = false
		ancsafe.Parent = service.ServerScriptService
		ancsafe.Disabled = false
	end

	Logs:AddLog("Script", "Misc Features Module Loaded");
end;
