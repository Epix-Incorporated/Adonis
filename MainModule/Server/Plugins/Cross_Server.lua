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
	
	local ServerId = game.JobId;
	local MsgService = service.MessagingService;
	local subKey = Core.DataStoreEncode("AdonisCrossServerMessaging");
	local counter = 0;
	local lastTick;
	
	local oldCommands = Core.CrossServerCommands;
	
	--// Cross Server Commands
	Core.CrossServerCommands = {
		ServerChat = function(jobId, data)
			if data then
				for i,v in next,service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v,"handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end;
		
		NewRunCommand = function(jobId, plrData, comString)
			local fakePlayer = service.Wrap(service.New("Folder"))
			local data = {
				Name = plrData.Name;
				ToString = plrData.Name;
				ClassName = "Player";
				AccountAge = 0;
				CharacterAppearanceId = plrData.UserId or -1;
				UserId = plrData.UserId or -1;
				userId = plrData.UserId or -1;
				Parent = service.Players;
				Character = Instance.new("Model");
				Backpack = Instance.new("Folder");
				PlayerGui = Instance.new("Folder");
				PlayerScripts = Instance.new("Folder");
				Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
				IsA = function(ignore, arg) if arg == "Player" then return true end end;
			}
			
			for i,v in next,data do fakePlayer:SetSpecial(i, v) end
			
			Process.Command(fakePlayer, comString, {isSystem = true, CrossServer = true})
		end;
		
		DataStoreUpdate = function(jobId, type, data)
			server.Process.DataStoreUpdated(type, data) 
		end;
		
		UpdateSetting = function(jobId, setting, newValue)
			Settings[setting] = newValue;
		end;
		
		LoadData = function(jobId, ...)
			Core.LoadData(...);
		end
	}
	
	--// User Commands
	Commands.CrossServer = {
		Prefix = Settings.Prefix;
		Commands = {"crossserver","cross","allservers"};
		Args = {"command"};
		Description = "Runs the specified command string on all servers; WARNING: RUNS AS SERVER/CREATOR";
		AdminLevel = "Creators";
		CrossServerDenied = true; --// Makes it so this command cannot be ran via itself causing an infinite spammy loop of cross server commands...
		Function = function(plr,args)
			if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId}, args[1]) then
				error("CrossServer Handler Not Ready");
			end
		end;
	};
	
	--// Handlers
	Core.CrossServer = function(...)
		local data = {ServerId, ...};
		service.Queue("CrossServerMessageQueue", function()
			--// rate limiting
			counter = counter+1;
			if not lastTick then lastTick = os.time() end
			if counter >= 150 + 60 * #service.Players:GetPlayers()  then
				repeat wait() until os.time()-lastTick > 60;
			end
			
			if os.time()-lastTick > 60 then
				lastTick = os.time();
				counter = 1;
			end
			
			--// publish
			MsgService:PublishAsync(subKey, data) 
		end)

		return true;
	end
	
	Process.CrossServerMessage = function(msg)
		local data = msg.Data;
		if not data or type(data) ~= "table" then error("CrossServer: Invalid Data Type ".. type(data)); end
		Logs:AddLog("Script", "Cross-Server Message received: ".. tostring(data and data[2] or "nil data[2]"));
		local command = data[2];
		
		table.remove(data, 2);
		
		if Core.CrossServerCommands[command] then
			Core.CrossServerCommands[command](unpack(data));
		end
	end
	
	Core.SubEvent = MsgService:SubscribeAsync(subKey, function(...) return Process.CrossServerMessage(...) end)
	
	--// Check for additions added by other modules in core before this one loaded
	for i,v in next,oldCommands do
		Core.CrossServerCommands[i] = v;
	end
	
	Logs:AddLog("Script", "Cross-Server Messaging Ready");
end;