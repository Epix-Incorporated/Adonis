server, service = nil, nil
--// Originally written by Merely
--// Edited by GitHub@LolloDev5123 and Irreflexive

return function()
	
	local TeleportService = game:GetService("TeleportService")
	local parameterName = "ADONIS_SOFTSHUTDOWN"
	
	if (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0)  then
		--// This is a reserved server
		
		local waitTime = 5
		local function teleport(player)
			local joindata = player:GetJoinData()
			local data = joindata.TeleportData
			if typeof(data) == "table" and data[parameterName] then
				server.Functions.Message("Server Restart", "Teleporting back to main server...", {player}, false, 1000)
				wait(waitTime)
				waitTime = waitTime / 2
				TeleportService:Teleport(game.PlaceId, player)
			end
		end
	
		service.Events.PlayerAdded:Connect(teleport)
		
		for _,player in ipairs(service.GetPlayers()) do
			teleport(player)
		end
	
	end
	server.Remote.Terminal.Commands.SoftShutdown = {
		Usage = "restart";
		Command = "restart";
		Arguments = 0;
		Description = "Restart the server, placing all of the players in a reserved server and teleporting each of them to the new server";
		Function = function(p,args,data)
			if (game:GetService("RunService"):IsStudio()) then
				return
			end

			if (#game.Players:GetPlayers() == 0) then
				return
			end
			
			local newserver = TeleportService:ReserveServer(game.PlaceId)
			server.Functions.Message("Server Restart", "The server is restarting, please wait...", service.GetPlayers(), false, 1000)
			
			wait(2)
			
			for _,player in pairs(game.Players:GetPlayers()) do
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end
			game.Players.PlayerAdded:connect(function(player)
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end)
			while (#game.Players:GetPlayers() > 0) do
				wait(1)
			end	
			
		end
	}
	server.Commands.SoftShutdown = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"softshutdown","restart","sshutdown"};	-- Commands
		Args = {"restart"};	-- Command arguments
		Description = "Restarts the server";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Admins";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			if (game:GetService("RunService"):IsStudio()) then
				return
			end
			
			if (#game.Players:GetPlayers() == 0) then
				return
			end

			if server.Core.DataStore and not server.Core.PanicMode then
				server.Core.UpdateData("ShutdownLogs", function(logs)
					if plr then
						table.insert(logs, 1, {
							User = plr.Name,
							Time = service.GetTime(),
							Reason = ("SoftShutdown/Restart: " + args[1]) or "N/A"
						})
					else
						table.insert(logs,1,{
							User = "[Server]",
							Time = service.GetTime(),
							Reason = ("SoftShutdown/Restart: " + args[1]) or "N/A"
						})
					end

					if #logs > 1000 then
						table.remove(logs,#logs)
					end

					return logs
				end)
			end

		
			local newserver = TeleportService:ReserveServer(game.PlaceId)
			server.Functions.Message("Server Restart", "The server is restarting, please wait...", service.GetPlayers(), false, 1000)
			wait(1)
			
			for _,player in pairs(game.Players:GetPlayers()) do
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end
			game.Players.PlayerAdded:connect(function(player)
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end)
			while (#game.Players:GetPlayers() > 0) do
				wait(1)
			end	
			wait(2)
			server.Functions.Shutdown(args[1])

			-- done
		end
	}
end
