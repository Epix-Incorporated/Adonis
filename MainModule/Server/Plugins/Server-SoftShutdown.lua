--// Originally written by Merely
--// Edited by GitHub@LolloDev5123 and Irreflexive
--// GitHub@Expertcoderz was here to make things look better

return function(Vargs, env)
	if env then
		setfenv(1, env)
	end

	local server = Vargs.Server
	local service = Vargs.Service

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local TeleportService = service.TeleportService
	local parameterName = "ADONIS_SOFTSHUTDOWN"

	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0  then
		--// This is a reserved server

		local waitTime = 5
		local function teleport(player)
			local joindata = player:GetJoinData()
			local data = joindata.TeleportData
			if type(data) == "table" and data[parameterName] then
				Functions.Message("Server Restart", "Teleporting back to main ..", {player}, false, 1000)
				wait(waitTime)
				waitTime /= 2
				TeleportService:Teleport(game.PlaceId, player)
			end
		end

		service.Events.PlayerAdded:Connect(teleport)

		for _, player in ipairs(service.GetPlayers()) do
			teleport(player)
		end

	end
	Remote.Terminal.Commands.SoftShutdown = {
		Usage = "restart";
		Command = "restart";
		Arguments = 0;
		Description = "Restart the server, placing all of the players in a reserved server and teleporting each of them to the new server";
		Function = function(p,args,data)
			if service.RunService:IsStudio() then return end

			if #service.Players:GetPlayers() == 0 then return end

			local newserver = TeleportService:ReserveServer(game.PlaceId)
			Functions.Message("Server Restart", "The server is restarting, please wait...", service.GetPlayers(), false, 1000)

			task.wait(2)

			for _, player in pairs(service.Players:GetPlayers()) do
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end
			service.Players.PlayerAdded:Connect(function(player)
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end)
			while #service.Players:GetPlayers() > 0 do
				service.Players.PlayerRemoving:Wait()
			end

		end
	}
	Commands.SoftShutdown = {
		Prefix = Settings.Prefix;
		Commands = {"softshutdown", "restart", "sshutdown", "restartserver"};
		Args = {"reason"};
		Description = "Restarts the server";
		Hidden = false;
		Fun = false;
		NoStudio = true; --// TeleportService does not work in Studio
		AdminLevel = "Admins";
		Function = function(plr: Player, args: {string})
			if #service.Players:GetPlayers() == 0 then return end

			if Core.DataStore then
				Core.UpdateData("ShutdownLogs", function(logs)
					if plr then
						table.insert(logs, 1, {
							User = plr.Name,
							Restart = true,
							Time = os.time(),
							Reason = args[1] or "N/A"
						})
					else
						table.insert(logs, 1, {
							User = "[Server]",
							Restart = true,
							Time = os.time(),
							Reason = args[1] or "N/A"
						})
					end

					if #logs > 1000 then
						table.remove(logs, #logs)
					end

					return logs
				end)
			end


			local newserver = TeleportService:ReserveServer(game.PlaceId)
			Functions.Message("Server Restart", "The server is restarting, please wait...", service.GetPlayers(), false, 1000)
			task.wait(1)

			for _, player in pairs(service.Players:GetPlayers()) do
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end
			service.Players.PlayerAdded:Connect(function(player)
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[parameterName] = true})
			end)
			while #service.Players:GetPlayers() > 0 do
				task.wait(1)
			end
			-- done
		end
	}
end
