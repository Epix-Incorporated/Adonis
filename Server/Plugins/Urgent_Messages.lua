server = nil;
service = nil;

return function()
	local Core = server.Core;
	local Admin = server.Admin;
	local Remote = server.Remote;
	local Commands = server.Commands;
	local Variables = server.Variables;
	local Settings = server.Settings;
	local MessageVersion = 1;					--// Message version/number
	local MessageAdminType = 2;  				--// Minimum admin level to be notified (Or Donors or Players or nil to not notify)
	local MessageDate = "1596318516";			--// Time of message creation
	local MessageDuration = 60*60*24 * 7; 		--// How long should we notify people about this message
	local LastDateTime = "8.1.2020 18:38 EST";
	local Messages = {
		"YOU WILL ONLY BE NOTIFIED ONCE PER GAME ON JOIN WHEN THERE'S NEW MESSAGES.";
		"THESE ARE IMPORTANT ANNOUNCEMENTS RELATED TO ADONIS AND ADONIS USERS.";
		"IMPACTED USERS WILL BE NOTIFED ONCE ON THEIR FIRST JOIN AFTER AN URGENT MESSAGE.";
		"NOTIFICATIONS WILL ONLY HAPPEN FOR A SET TIME (WEEK AVG) AFTER THE MESSAGE WAS ADDED.";
		"PLEASE READ THE MOST RECENT MESSAGE CAREFULLY AS IT LIKELY AFFECTS YOU AND YOUR USERS!";
		"";
		"";
		"[IMPORTANCE LEVEL: HIGH - DATE: 8.1.2020 18:38 EST]";
		"[NOTIFY DURATION: 7 DAYS]";
		"[NOTIFYING ALL RANK \"ADMIN\" AND HIGHER]";
		"A ROBLOX (NOT ADONIS) EXPLOIT ALLOWED USERS TO SPOOF USERNAMES, IMPERSONATING OTHER USERS.";
		"EXPLOITERS IMPERSONATING GAME ADMINS WERE ABLE TO CHANGE SETTINGS AND ADD ADMINS.";
		"ALL DATASTORE SAVED ADMINS AND SETTINGS ARE BEING CLEARED TO PROTECT USERS/GAMES.";
		"PLAYER DATA WILL NOT BE AFFECTED.";
		"FULL DETAILS BELOW.";
		"";
		"=What Happened?=";
		"A ROBLOX exploit (not Adonis) allowed users to change their usernames, allowing them to impersonate users.";
		"This also allowed them to impersonate admins, such as the place owner.";
		"Adonis, as well as all other scripts, would see the exploiter's Name property as their desired fake name.";
		"I have been informed that this was patched at some point earlier today.";
		"";
		"=How Does This Affect You?=";
		"I don't know the extent of damage that has been done. Because of this, in addition";
		"to a new check to attempt to avoid this in the future, I am also CLEARING ALL DATASTORE";
		"SAVED SETTINGS AND ADMINS! This is being done due to people impersonating admin accounts to";
		"edit settings/add admins, so I'm clearing these from the datastore to prevent potential abuse";
		"and protect users and games.";
		"";
		"I apologize for any inconvience this may pose, and anything that was written in the settings module";
		"in studio will be completely unaffected. SAVED PLAYER DATA WILL NOT BE AFFECTED. Any admins or settings";
		"that were added/altered and saved in-game will be cleared/reset to prevent backdoor/abuse.";
		"Again, the cause of this was entirely out of my control and was not caused by anything Adonis did.";
		"Personally, I'd prefer not to do this but the risk and severity is high enough to warrant it.";
		"- Davey_Bones (Sceleratis)";
		"[END_OF_MESSAGE 8.1.2020 18:38 EST]";
	}
	
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
	
	local function doNotify(p)
		Remote.MakeGui(p,"Notification",{
			Title = "URGENT ALERT!";
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