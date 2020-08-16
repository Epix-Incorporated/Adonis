server = nil;
service = nil;

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;
	
	local Core = server.Core;
	local Admin = server.Admin;
	local Remote = server.Remote;
	local Commands = server.Commands;
	local Variables = server.Variables;
	local Settings = server.Settings;
	
	local r,AlertTab = true,require(5479981424) --xpcall(function() return require(5479981424); end, function(err)
		--warn("Something went wrong while requiring the urgent messages module");
	--end); -- Causes an error?
	
	local Alerts = (r and AlertTab) or require(server.Deps.__URGENT_MESSAGES)

	local MessageVersion = Alerts.MessageVersion;			--// Message version/number
	local MessageAdminType = Alerts.MessageAdminType;  		--// Minimum admin level to be notified (Or Donors or Players or nil to not notify)
	local MessageDate = Alerts.MessageDate;					--// Time of message creation
	local MessageDuration = Alerts.MessageDuration; 		--// How long should we notify people about this message
	local LastDateTime = Alerts.LastDateTime;				--// Last message date and time
	local Messages = Alerts.Messages;						--// List of alert messages/lines
	
	local function doNotify(p)
		Remote.MakeGui(p,"Notification",{
			Title = "Urgent Message!";
			Message = "Click to view messages";
			Time = 20;
			OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand',':adonisalerts')");
		})
	end
	
	local function checkDoNotify(p, data)
		local lastMessage = data.LastUrgentMessage or 0;
		
		if lastMessage < MessageVersion and os.time()-MessageDate <= MessageDuration then
			if MessageAdminType == "Players" then
				return true;
			elseif MessageAdminType == "Donors" then
				if Admin.CheckDonor(p) then
					return true;
				end
			elseif type(MessageAdminType) == "number" and Admin.GetLevel(p) >= MessageAdminType then
				return true;
			end
		end
	end
	
	Variables.UrgentMessageCounter = MessageVersion;
	
	Commands.UrgentMessages = {
		Prefix = ":";
		Commands = { "adonisalerts", "urgentmessages", "urgentalerts", "adonismessages", "urgentadonismessages", "ulog"};
		Args = {};
		Description = "URGENT ADONIS RELATED MESSAGES";
		AdminLevel = "Players";
		Function = function(plr,args)
			Remote.MakeGui(plr,"List",{
				Title = "~URGENT MESSAGES~ [Recent: ".. LastDateTime .."]",
				Table = Messages,
				Font = "Code",
				PageSize = 100;
				Size = {700, 400},
			})
		end;
	};
	
	service.Events.PlayerAdded:Connect(function(p)
		if MessageAdminType then
			local data = Core.GetPlayer(p);
			if checkDoNotify(p, data) then
				data.LastUrgentMessage = MessageVersion;
				doNotify(p);
			end
		end
	end)
end