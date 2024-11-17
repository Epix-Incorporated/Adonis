return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local LastDateTime, Messages = "Loading...", {"The messages haven't loaded. Please comeback later..."}
	Variables.UrgentModuleId = Variables.UrgentModuleId or 8096250407

	task.spawn(xpcall, function()
		local Alerts = require(Deps.__URGENT_MESSAGES)
		local assetInfo = type(Variables.UrgentModuleId) == "number" and service.GetProductInfo(Variables.UrgentModuleId, Enum.InfoType.Asset)
		local version = (assetInfo and assetInfo.Created) and assetInfo.Updated
		local lastVersion = Core.GetData("LastAlertVersion")

		if not version or not lastVersion or version ~= lastVersion then
			Logs:AddLog("Script", "Loading alerts from cloud module")
			xpcall(function()
				if not server.Core.SilentStartup then
					print("Requiring Alerts Module by ID; Expand for module URL > ", {URL = `https://www.roblox.com/library/{Variables.UrgentModuleId}/Adonis-Alerts-Module`})
				end
		
				local alertTab = require(Variables.UrgentModuleId)
		
				if alertTab then
					Alerts = AlertTab
					Logs:AddLog("Script", "Alerts cloud module returned proper data")
					Core.SetData("LastAlertVersion", version)
					Core.SetData("CachedAlerts", service.HttpService:JSONEncode(alertTab))
				end
			end, function(reason)
				warn(`Error occured while requiring the urgent messages module. Reason {reason}`)
				Logs:AddLog("Errors", `Error occured while requiring the urgent messages module. Reason {reason}`)
				table.insert(server.Messages, `Error occured while requiring the urgent messages module. Reason {reason}`)
			end)
		elseif version and lastVersion then
			Logs:AddLog("Script", "Loading alerts from datastore")
			xpcall(function()
				Alerts = service.HttpService:JSONDecode(Core.GetData("CachedAlerts"))
			end, function(reason)
				warn(`Error occured while loading alerts from datastore. Reason {reason}`)
				Logs:AddLog("Errors", `Error occured while loading alerts from datastore. Reason {reason}`)
				table.insert(server.Messages, `Error occured while loading alerts from datastore. Reason {reason}`)
				Core.RemoveData("LastAlertVersion")
				Core.RemoveData("CachedAlerts")
			end)
		end

		local MessageVersion = Alerts.MessageVersion;			--// Message version/number
		local MessageAdminType = Alerts.MessageAdminType;  		--// Minimum admin level to be notified (Or Donors or Players or nil to not notify)
		local MessageDate = Alerts.MessageDate;					--// Time of message creation
		local MessageDuration = Alerts.MessageDuration; 		--// How long should we notify people about this message
		LastDateTime = Alerts.LastDateTime;						--// Last message date and time
		Messages = Alerts.Messages;								--// List of alert messages/lines

		local function checkDoNotify(p, data)
			local lastMessage = data.LastUrgentMessage or 0;

			if lastMessage < MessageVersion and os.time() - MessageDate <= MessageDuration then
				if MessageAdminType == "Players" then
					return true
				elseif MessageAdminType == "Donors" then
					if Admin.CheckDonor(p) then
						return true
					end
				elseif type(MessageAdminType) == "number" and Admin.GetLevel(p) >= MessageAdminType then
					return true
				end
			end
		end

		Variables.UrgentMessageCounter = MessageVersion
		
		local function onPlayerAdded(p: Player)
			if MessageAdminType then
				local data = Core.GetPlayer(p);
				if checkDoNotify(p, data) then
					data.LastUrgentMessage = MessageVersion;
					task.delay(0.5, Functions.Notification, "Urgent Message!", "Click to view messages", {p}, 20, "MatIcon://Announcement", Core.Bytecode("client.Remote.Send('ProcessCommand',':adonisalerts')"))
				end
			end
		end

		for _, p in service.Players:GetPlayers() do
			task.spawn(pcall, onPlayerAdded, p)
		end

		service.Events.PlayerAdded:Connect(onPlayerAdded)
		Logs:AddLog("Script", "Successfully loaded alerts module data")
	end, warn)

	Commands.UrgentMessages = {
		Prefix = ":";
		Commands = {"adonisalerts", "urgentmessages", "urgentalerts", "adonismessages", "urgentadonismessages", "ulog"};
		Args = {};
		Description = "URGENT ADONIS RELATED MESSAGES";
		AdminLevel = "Players";
		Function = function(plr,args)
			Remote.MakeGui(plr,"List",{
				Title = `URGENT MESSAGES [Recent: {LastDateTime}]`,
				Icon = "rbxassetid://7467273592",
				Table = Messages,
				Font = "Code",
				PageSize = 100;
				Size = {700, 400},
			})
		end;
	};

	Logs:AddLog("Script", "Alerts Module Loaded")
end
