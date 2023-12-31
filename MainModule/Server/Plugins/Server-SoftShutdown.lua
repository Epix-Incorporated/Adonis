--// Originally written by Merely
--// Edited by GitHub@LolloDev5123 and Irreflexive
--// GitHub@Expertcoderz was here to make things look better

return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server
	local service = Vargs.Service

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local TeleportService: TeleportService = service.TeleportService
	local Players: Players = service.Players
	local teleportedPlayers = setmetatable({}, {__mode = "k"})
	local isPrivateServer = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0

	local PARAMETER_NAME = "ADONIS_SOFTSHUTDOWN"
	local PARAMETER_2_NAME = "ADONIS_SHUTDOWN_REJOIN"
	local MAX_RETRIES = 4
	local RETRY_WAIT = 1.5

	TeleportService.TeleportInitFailed:Connect(function(player, result, message, placeId, options)
		if teleportedPlayers[player] and placeId == game.PlaceId and not table.find({Enum.TeleportResult.Success, Enum.TeleportResult.IsTeleporting}, result) then
			if teleportedPlayers[player] < MAX_RETRIES then
				task.wait(RETRY_WAIT * teleportedPlayers[player])
				teleportedPlayers[player] += 1
				Logs:AddLog("Script", `Failed to teleport {player.Name} {isPrivateServer and "back to the main game" or "to a temporary softshutdown server"} due to {result.Name}. Retrying... Details: {message}`)
				Functions.Notification("Teleport failed", `SoftShutdown failed to teleport {isPrivateServer and "back to the main game" or "to a temporary softshutdown server"}. Retrying...`, {player}, 10, "MatIcon://Warning")
				TeleportService:Teleport(game.PlaceId, player, {[PARAMETER_2_NAME] = true})
			else
				Logs:AddLog("Script", `Failed to teleport {player.Name} {isPrivateServer and "back to the main game" or "to a temporary softshutdown server"} due to {result.Name}. Details: {message}`)
				Logs:AddLog("Error", `Failed to teleport {player.Name} {isPrivateServer and "back to the main game" or "to a temporary softshutdown server"} to {result.Name}. Details: {message}`)
				Functions.Notification("Teleport failed", `SoftShutdown failed to teleport {isPrivateServer and "back to the main game" or "to a temporary softshutdown server"}. Details {message}`, {player}, 35, "MatIcon://Error")
			end
		end
	end)

	if isPrivateServer then
		--// This is a reserved server

		local waitTime = 5
		local function teleport(player)
			local joindata = player:GetJoinData()
			local data = type(joindata) == "table" and joindata.TeleportData

			if type(data) == "table" and data[PARAMETER_NAME] then
				Remote.RemoveGui(player, "Message")
				Remote.MakeGui(player, "Message", {
					Title = "Server Restart";
					Message = "Teleporting back to main server..";
					Scroll = false;
					Time = 1000
				})

				wait(waitTime)
				waitTime /= 2

				Logs:AddLog("Script", `Teleporting {player.Name} back to the main game`)
				teleportedPlayers[player] = 1
				TeleportService:Teleport(game.PlaceId, player, {[PARAMETER_2_NAME] = true})
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
			if #Players:GetPlayers() == 0 then return end

			local newserver = TeleportService:ReserveServer(game.PlaceId)
			Functions.Message("Adonis", "Server Restart", "The server is restarting, please wait...", 'MatIcon://Hourglass empty', service.GetPlayers(), false, 1000)
			task.wait(2)

			for _, v in Players:GetPlayers() do
				teleportedPlayers[v] = 1
			end

			Logs:AddLog("Script", `Teleporting {#Players:GetPlayers()} players to a temporary softshutdown server`)
			TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, Players:GetPlayers(), "", {[PARAMETER_NAME] = true})
			Players.PlayerAdded:Connect(function(player)
				Logs:AddLog("Script", `Teleporting {player.Name} to a temporary softshutdown server`)
				teleportedPlayers[player] = 1
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[PARAMETER_NAME] = true})
			end)

			while #Players:GetPlayers() > 0 do
				Players.PlayerRemoving:Wait()
			end
		end
	}
	Commands.SoftShutdown = {
		Prefix = Settings.Prefix;
		Commands = {"softshutdown", "restart", "sshutdown", "restartserver"};
		Args = {"reason"};
		Description = "Restarts the server";
		Filter = true;
		NoStudio = true; --// TeleportService does not work in Studio 
		AdminLevel = "Admins";
		Function = function(plr: Player, args: {string})
			if #Players:GetPlayers() == 0 then return end

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
			Functions.Message("Adonis", "Server Restart", "The server is restarting, please wait...", 'MatIcon://Hourglass empty', service.GetPlayers(), false, 1000)
			task.wait(1)

			for _, v in Players:GetPlayers() do
				teleportedPlayers[v] = 1
			end

			Logs:AddLog("Script", `Teleporting {#Players:GetPlayers()} players to a temporary softshutdown server`)
			TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, Players:GetPlayers(), "", {[PARAMETER_NAME] = true})
			Players.PlayerAdded:Connect(function(player)
				Logs:AddLog("Script", `Teleporting {player.Name} to a temporary softshutdown server`)
				teleportedPlayers[player] = 1
				TeleportService:TeleportToPrivateServer(game.PlaceId, newserver, { player }, "", {[PARAMETER_NAME] = true})
			end)

			while #Players:GetPlayers() > 0 do
				Players.PlayerRemoving:Wait()
			end
			-- done
		end
	}
end
