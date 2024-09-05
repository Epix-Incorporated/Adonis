--// This copy may be outdated

return {
	MessageVersion = 5;					--// Message version/number
	MessageAdminType = 900;  			--// Minimum admin level to be notified (Or Donors or Players or nil to not notify)
	MessageDate = "1707264000";			--// Time of message creation
	MessageDuration = 60*60*24*7; 	--// How long should we notify people about this message
	LastDateTime = "2024-02-07 00:00:01 UTC";
	Messages = {
		"YOU WILL ONLY BE NOTIFIED ONCE PER GAME ON JOIN, WHEN THERE ARE NEW MESSAGES.";
		"THESE ARE IMPORTANT ANNOUNCEMENTS RELATED TO ADONIS AND ADONIS USERS.";
		"IMPACTED USERS WILL BE NOTIFIED ONCE ON THEIR FIRST JOIN AFTER AN URGENT MESSAGE.";
		"NOTIFICATIONS WILL ONLY HAPPEN FOR A SET TIME (WEEK AVG) AFTER THE MESSAGE WAS ADDED.";
		"PLEASE READ THE MOST RECENT MESSAGE CAREFULLY AS IT LIKELY AFFECTS YOU AND YOUR USERS.";
		"";
		"[LOW - DATE: 2024-02-07 00:00 UTC]";
		"[DURATION: 7 DAYS]";
		"[NOTIFY: ALL LEVEL 900 AND HIGHER]";
		"VERSION 240 DISABLED THE CLIENT SIDE ANTI CHEAT BY DEFAULT!";
		"THIS WILL CAUSE ALL OF THE CLIENT SIDE PROTECTIONS TO BE DISABLED!";
		"IF YOU WANT TO RE-ENABLE THEM CHANGE settings.AllowClientAntiExploit TO `true`;";
		"IF NO SUCH SETTING EXISTS ADD `settings.AllowClientAntiExploit = TRUE` IN YOUR SETTINGS FILE";
		"IF YOU'D LIKE TO RE-ENABLE THE ANTI CHEAT;";
		"THIS ALERT IS TO PREVENT UNINTENDED CONSEQUENCES FROM THE DEFAULT DISABLING OF THE CLIENT-SIDE AC";
		"Completely unrelated to this, we have also disabled the serverside AC protections for HumanoidDeletion and HatProtection";
		"so enable workspace.RejectCharacterDeletions if you haven't already.";
		"[END_OF_MESSAGE 2024-02-07 00:00 UTC]";
		"";
		"";
		"PREVIOUS ALERTS:";
		"";
		"[LOW - DATE: 2021-9-4 19:27 UTC]";
		"[DURATION: 7 DAYS]";
		"[NOTIFY: ALL LEVEL 200 AND HIGHER]";
		"VERSION 227.1 CHANGES THE FUNCTIONALITY OF ':admin'";
		"':admin' WILL NOW ASSIGN THE EXPECTED RANK (Admins)";
		"RATHER THAN TEMP MODERATOR PERMS;";
		"THIS ALERT IS TO PREVENT CONFUSION/UNINTENDED ACCIDENTAL RANK ADMIN ASSIGNMENT";
		"";
		"[HIGH - DATE: 2021-9-4 19:27 UTC]";
		"A VULNERABILITY THAT ALLOWED UNAUTHORIZED ACCESS TO Settings.WebPanel_ApiKey";
		"HAS BEEN FOUND & PATCHED; IF YOU USE THE WEBPANEL, PLEASE REGENERATE";
		"YOUR API KEY VIA YOUR ACCOUNT'S SETTINGS (Under Security)";
		"[END_OF_MESSAGE 2021-9-4 19:27 UTC]";
		"";
		"[IMPORTANCE LEVEL: LOW - DATE: 2021-7-4 01:12 UTC]";
		"[NOTIFY DURATION: 1 DAY (24 HOURS)]";
		"[NOTIFYING ALL LEVEL 900+ (Creators+)]";
		"VERSION 211 MAY CAUSE ISSUES WITH ADONIS PLUGINS THAT EXPECT";
		"ADMIN LEVELS TO BE BETWEEN 0 AND 4. ADDITIONALLY, OUTDATED SERVERS";
		"MAY BE RUNNING A VERSION IN WHICH TRELLO INTEGRATION AND COMMAND";
		"PERMISSIONS ARE BROKEN. IF YOU ENCOUNTER ISSUES, BE SURE TO CHECK";
		"YOUR PLUGIN CODE AND ENSURE YOU ARE TESTING ON ***NEW*** SERVERS.";
		"[END_OF_MESSAGE 2021-7-4 01:12 UTC]";
		"";
		"[IMPORTANCE LEVEL: MEDIUM - DATE: 29-12-2020 00:40 UTC]";
		"[NOTIFY DURATION: 7 DAYS]";
		"[NOTIFYING ALL RANK \"CREATOR\" AND HIGHER]";
		"MALICIOUS STUDIO PLUGINS HAVE BEEN AUTOMATICALLY \"BACKDOORING\" ADONIS.";
		"THESE PLUGINS WATCH WORKSPACE WAITING FOR THE ADONIS_LOADER MODEL TO BE INSERTED.";
		"ONCE ADONIS_LOADER IS FOUND, THE MODULEID IN ADONIS' LOADER SCRIPT IS CHANGED TO THE ATTACKER'S MODULE.";
		"THE \"ModuleID\" SETTING IN THE \"data\" TABLE OF THE LOADER SCRIPT SHOULD CURRENTLY BE 2373501710.";
		"IF YOUR MODULEID DOES NOT MATCH, CONSIDER CHECKING YOUR STUDIO PLUGINS AND REINSERTING ADONIS.";
		"MAKE SURE YOU ARE USING THE LOADER UPLOADED TO THE \"Davey_Bones\" ACCOUNT.";
		"THIS IS A ROBLOX STUDIO ISSUE. THIS IS NOT A FLAW WITH ADONIS.";
		"OTHER SCRIPTS/RESOURCES ARE LIKELY ALSO BEING TARGETTED.";
		"ONLY USE STUDIO PLUGINS FROM TRUSTED SOURCES.";
		"[END_OF_MESSAGE 2020-12-29 00:40 UTC]";
		"";
		"";
		"[IMPORTANCE LEVEL: HIGH - DATE: 2020-1-8 23:38 UTC]";
		"[NOTIFY DURATION: 7 DAYS]";
		"[NOTIFYING ALL RANK \"ADMIN\" AND HIGHER]";
		"A ROBLOX (NOT ADONIS) EXPLOIT ALLOWED USERS TO SPOOF USERNAMES, IMPERSONATING OTHER USERS.";
		"EXPLOITERS IMPERSONATING GAME ADMINS WERE ABLE TO CHANGE SETTINGS AND ADD ADMINS.";
		"ALL DATASTORE SAVED ADMINS AND SETTINGS ARE BEING CLEARED TO PROTECT USERS/GAMES.";
		"GAME BANS AND OTHER SAVED LISTS/TABLES WILL ALSO LIKELY BE CLEARED";
		"PLAYER DATA WILL NOT BE AFFECTED.";
		"FULL DETAILS BELOW.";
		"";
		"=What Happened?=";
		"A Roblox exploit (not Adonis) allowed users to change their usernames, allowing them to impersonate users.";
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
		"[END_OF_MESSAGE 2020-1-8 23:38 UTC]";
	}
}
