local settings = {}
local descs = {}


			--------------
			-- SETTINGS --
		    --------------
																																																																				--[[

		--// Basic Lua Info

		This is only here to help you when editing settings so you understand how they work
		and don't break something.

		Anything that looks like setting = {} is known as a table.
		Tables contain things; like the Lua version of a box.
		An example of a table would be setting = {"John","Mary","Bill"}
		You can have tables inside of tables, such in the case of setting = {{Group=1234,Rank=123,Type="Admin"}}
		Just like real boxes, tables can contain pretty much anything including other tables.

		Anything that looks like "Bob" is what's known as a string. Strings
		are basically plain text; setting = "Bob" would be correct however
		setting = Bob would not; because if it's not surrounded by quotes Lua will think
		that Bob is a variable; Quotes indicate something is a string and therefor not a variable/number/code

		Numbers do not use quotes. setting = 56

		This green block of text you are reading is called a comment. It's like a message
		from the programmer to anyone who reads their stuff. Anything in a comment will
		not be seen by Lua.

		Incase you don't know what Lua is; Lua is the scripting language Roblox uses...
		so every script you see (such as this one) and pretty much any code on Roblox is
		written in Lua.




		--// Settings [READ IF CONFUSED]

		If you see something like "Format: 'Username:UserId'" it means that anything you put
		in that table must follow one of the formats next to Format:

		For instance if I wanted to give admin to a player using their username, userid, a group they are in
		or an item they own I would do the following with the settings.Admins table:

		The format for the Admins' table's entries is "Username"; or "Username:UserId"; or UserId; or "Group:GroupId:GroupRank" or "Item:ItemID"
		This means that if I want to admin Bobjenkins123 who has a userId of 1234567, is in
		group "BobFans" (group ID 7463213) under the rank number 234, or owns the item belonging to ID 1237465
		I can do any of the following:

		settings.Admins = {"Bobjenkins123","Bobjenkins123:1234567",1234567,"Group:BobFans:7463213:234","Item:1237465"}


		If I wanted to make it so rank 134 in group 1029934 and BobJenkins123 had mod admin I would do
		settings.Moderators = {"Group:1029943:134","BobJenkins123"}


		I was going to change the admin rank stuff but I figured it would confuse people too much, so I left it as mods/admins/HeadAdmins ;p


		--// Admins

			settings.Moderators = {"Sceleratis";"BobJenkins:1237123";1237666;"Group:181:255";"Item:1234567"}
				This will make the person with the username Sceleratis, or the name BobJenkins, or the ID 1237123 OR 123766,
				   or is in group 181 in the rank 255, or owns the item belonging to the ID 1234567 a moderator

				If I wanted to give the rank 121 in group 181 Owner admin I would do:
				   settings.HeadAdmins = {"Group:181:121"}
				   See? Not so hard is it?

				If I wanted to add group 181 and all ranks in it to the :slock whitelist I would do;
					settings.Whitelist = {"Group:181";}

				I can do the above if I wanted to give everyone in a group admin for any of the other admin tables



		--// Command Permissions

			You can set the permission level for specific commands using setting.Permissions
			If I wanted to make it so only HeadAdmins+ can use :ff player then I would do:

				settings.Permissions = {":ff:HeadAdmins"}

				:ff is the Command ":ff scel" and 3 is the NewLevel

				Permissions Levels:
					Players
					Moderators
					Admins
					HeadAdmins
					Creators

				Note that when changing command permissions you MUST include the prefix;
				So if you change the prefix to $ you would need to do $ff instead of :ff


		--// Trello

			The Trello abilities of the script allow you to manage lists and permissions via
			a Trello board; The following will guide you through the process of setting up a board;

				1. Sign up for an account at http://trello.com
				2. Create a new board
					http://prntscr.com/b9xljn
					http://prntscr.com/b9xm53
				3. Get the board ID;
					http://prntscr.com/b9xngo
				4. Set settings.Trello_Primary to your board ID
				5. Set settings.Trello.Enabled to true
				6. Congrats! The board is ready to be used;
				7. Create a list and add cards to it;
					http://prntscr.com/b9xswk

				- You can view lists in-game using :viewlist ListNameHere

			Lists:
				Moderators			- Card Format: Same as settings.Moderators
				Admins				- Card Format: Same as settings.Admins
				HeadAdmins				- Card Format: Same as settings.HeadAdmins
				Creators			- Card Format: Same as settings.Creators
				Agents				- Card Format: Same as settings.Admins
				Banlist				- Card Format: Same as settings.Banned
				Mutelist			- Card Format: Same as settings.Muted
				Blacklist			- Card Format: Same as settings.Blacklist
				Whitelist			- Card Format: Same as settings.Whitelist
				Permissions			- Card Format: Same as settings.Permissions
				Music				- Card Format: SongName:AudioID
				Commands			- Card Format: Command  (eg. :ff bob)

			Card format refers to how card names should look


			MAKE SURE YOU SET settings.DataStoreKey TO SOMETHING ABSOLUTELY RANDOM;
																																																																									--]]


	settings.HideScript = true						 -- Disable if your game saves; When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module
	settings.DataStore = "Adonis_1"					 -- DataStore the script will use for saving data; Changing this will lose any saved data
	settings.DataStoreKey = "CHANGE_THIS"			 -- CHANGE THIS TO SOMETHING RANDOM! Key used to encrypt all datastore entries; Changing this will lose any saved data
	settings.DataStoreEnabled = true				 -- Disable if you don't want to load settings and admins from the datastore; PlayerData will still save
	settings.Storage = game:service("ServerStorage") -- Where things like tools are stored

	settings.Theme = "Default"				-- UI theme;
	settings.MobileTheme = "Mobilius"		-- Theme to use on mobile devices; Some UI elements are disabled

	settings.Moderators = {}	-- Mods;									  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Admins = {}  		-- Admins; 						              Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.HeadAdmins = {}   -- Head Admins;								  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Creators = {}      -- Place Owner;								  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Banned = {}		-- List of people banned from the game 		  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Muted = {}			-- List of people muted				 		  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Blacklist = {}		-- List of people banned from using admin 	  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Whitelist = {}		-- People who can join if whitelist enabled	  Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
	settings.Permissions = {}	-- Command permissions; 					  Format: {"Command:NewLevel"; "Command:Customrank1,Customrank2,Customrank3";}
	settings.MusicList = {}; 	-- List of songs to appear in the script	  Format: {{Name = "somesong",ID = 1234567},{Name = "anotherone",ID = 1243562}}
	settings.CapeList = {};		-- List of capes							  Format: {{Name = "somecape",Material = "Fabric",Color = "Bright yellow",ID = 12345567,Reflectance = 1},{etc more stuff here}}
	settings.InsertList = {}; 	-- List of models to appear in the script	  Format: {{Name = "somemodel",ID = 1234567},{Name = "anotherone",ID = 1243562}}
	settings.CustomRanks = {};	-- List of custom AdminLevel ranks			  Format: {RankName = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";};}

	settings.OnStartup = {};	-- List of commands ran at server start								Format: {":notif TestNotif"}
	settings.OnJoin = {};		-- List of commands ran as player on join (ignores adminlevel)		Format: {":cmds"}
	settings.OnSpawn = {};		-- List off commands ran as player on spawn (ignores adminlevel)	Format: {"!fire Really red",":ff me"}

	settings.SaveAdmins = true		  -- If true anyone you :admin or :owner in-game will save
	settings.WhitelistEnabled = false -- If true enables the whitelist/server lock; Only lets admins & whitelisted users join

	settings.Prefix = ":"				-- The : in :kill me
	settings.PlayerPrefix = "!"			-- The ! in !donate; Mainly used for commands that any player can run; Do not make it the same as settings.Prefix
	settings.SpecialPrefix = ""			-- Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me)
	settings.SplitKey = " "				-- The space in :kill me (eg if you change it to / :kill me would be :kill/me)
	settings.BatchKey = "|"				-- :kill me | :ff bob | :explode scel
	settings.ConsoleKeyCode = "Quote"	-- Keybind to open the console; Rebindable per player in userpanel; KeyCodes: https://developer.roblox.com/en-us/api-reference/enum/KeyCode

	settings.HttpWait = 60;					  -- How long things that use the HttpService will wait before updating again
	settings.Trello_Enabled = false;		  -- Are the Trello features enabled?
	settings.Trello_Primary = ""; 		      -- Primary Trello board
	settings.Trello_Secondary = {}; 		  -- Secondary Trello boards (read-only)		Format: {"BoardID";"BoardID2","etc"}
	settings.Trello_AppKey = "";              -- Your Trello AppKey						  	Link: https://trello.com/app-key
	settings.Trello_Token = "";               -- Trello token (DON'T SHARE WITH ANYONE!)    Link: https://trello.com/1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE

	settings.G_API = true					-- If true allows other server scripts to access certain functions described in the API module through _G.Adonis
	settings.G_Access = false				-- If enabled allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player)
	settings.G_Access_Key = "Example_Key"	-- Key required to use the _G access API; Example_Key will not work for obvious reasons
	settings.G_Access_Perms = "Read" 		-- Access perms
	settings.Allowed_API_Calls = {
		Client = false;				-- Allow access to the Client (not recommended)
		Settings = false;			-- Allow access to settings (not recommended)
		DataStore = false;			-- Allow access to the DataStore (not recommended)
		Core = false;				-- Allow access to the script's core table (REALLY not recommended)
		Service = false;			-- Allow access to the script's service metatable
		Remote = false;				-- Communication table
		HTTP = false; 				-- HTTP related things like Trello functions
		Anti = false;				-- Anti-Exploit table
		Logs = false;
		UI = false;					-- Client UI table
		Admin = false;				-- Admin related functions
		Functions = false;			-- Functions table (contains functions used by the script that don't have a subcategory)
		Variables = true;			-- Variables table
		API_Specific = true;		-- API Specific functions
	}

	settings.FunCommands = true			-- Are fun commands enabled?
	settings.PlayerCommands = true 		-- Are players commands enabled?
	settings.ChatCommands = true 		-- If false you will not be able to run commands via the chat; Instead you MUST use the console or you will be unable to run commands
	settings.CreatorPowers = true		-- Gives me creator level admin; This is strictly used for debugging; I can't debug without full access to the script
	settings.CodeExecution = true		-- Enables the use of code execution in Adonis; Scripting related and a few other commands require this

	settings.BanMessage = "Banned"				-- Message shown to banned users
	settings.LockMessage = "Not Whitelisted"	-- Message shown to people when they are kicked while the game is :slocked
	settings.SystemTitle = "System Message"		-- Title to display in :sm

	settings.MaxLogs = 5000			-- Maximum logs to save before deleting the oldest
	settings.Notification = true	-- Whether or not to show the "You're an admin" and "Updated" notifications
	settings.SongHint = true		-- Display a hint with the current song name and ID when a song is played via :music
	settings.TopBarShift = false	-- By default hints and notifs will appear from the top edge of the window, this is acheived by offsetting them by -35 into the transparent region where roblox buttons menu/chat/leaderstat buttons are. Set this to true if you don't want hints/notifs to appear in that region.

	settings.AutoClean = false		-- Will auto clean service.Workspace of things like hats and tools
	settings.AutoCleanDelay = 60	-- Time between auto cleans
	settings.AutoBackup = false -- (not recommended) Run a map backup command when the server starts, this is mostly useless as clients cannot modify the server. To restore the map run :restoremap

	settings.CustomChat = false 	-- Custom chat
	settings.PlayerList = false		-- Custom playerlist
	settings.Console = true			-- Command console

	settings.HelpSystem = true		-- Allows players to call admins for help using !help
	settings.HelpButton = true              -- Shows a little help button in the bottom right corner.
	settings.HelpButtonImage = "rbxassetid://357249130" -- Change this if you want a different image for a help button!

	settings.DonorCapes = true 		-- Donors get to show off their capes; Not disruptive :)
	settings.DonorCommands = true	-- Show your support for the script and let donors use harmless commands like !sparkles
	settings.LocalCapes = false	 	-- Makes Donor capes local so only the donors see their cape [All players can still disable capes locally]

	settings.Detection = true			-- Attempts to detect certain known exploits
	settings.CheckClients = true		-- Checks clients every minute or two to make sure they are still active

	settings.AntiNil = true				-- Try's to prevent non-admins from hiding in "nil"
	settings.AntiSpeed = true 			-- Attempts to detect speed exploits
	settings.AntiNoclip = true			-- Attempts to detect noclipping and kills the player if found
	settings.AntiParanoid = false		-- Attempts to detect paranoid and kills the player if found
	settings.AntiBuildingTools = false	-- Attempts to detect any HopperBin(s)/Building Tools added to the client
	settings.AntiLeak = false			-- Attempts to prevent place downloading/saving; Do not use if game saves

	---------------------
	-- END OF SETTINGS --
	---------------------

	--// Setting descriptions used for the in-game settings editor;

	descs.HideScript = [[ Disable if your game saves; When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module ]]
	descs.DataStore = [[ DataStore the script will use for saving data; Changing this will lose any saved data ]]
	descs.DataStoreKey = [[ Key used to encode all datastore entries; Changing this will lose any saved data ]]
	descs.DataStoreEnabled = [[ Disable if you don't want settings and admins to be saveable in-game; PlayerData will still save ]]
	descs.Storage = [[ Where things like tools are stored ]]

	descs.Theme = [[ UI theme; ]]
	descs.MobileTheme = [[ Theme to use on mobile devices; Mobile themes are optimized for smaller screens; Some GUIs are disabled ]]

	descs.Moderators = [[ Mods; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Admins = [[ Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.HeadAdmins = [[ Head Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Creators = [[ Anyone to be identified as a place owner; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Banned = [[ List of people banned from the game; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Muted = [[ List of people muted; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Blacklist = [[ List of people banned from using admin; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";}	]]
	descs.Whitelist = [[ People who can join if whitelist enabled; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
	descs.Permissions = [[ Command permissions; Format: {"Command:NewLevel";} ]]
	descs.MusicList = [[ List of songs to appear in the script; Format: {{Name = "somesong",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
	descs.CapeList = [[ List of capes; Format: {{Name = "somecape",Material = "Fabric",Color = "Bright yellow",ID = 12345567,Reflectance = 1},{etc more stuff here}} ]]
	descs.InsertList = [[ List of models to appear in the script; Format: {{Name = "somemodel",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
	descs.CustomRanks = [[ List of custom AdminLevel ranks			  Format: {RankName = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";};} ]]

	descs.OnStartup = [[ List of commands ran at server start								Format: {":notif TestNotif"} ]]
	descs.OnJoin = [[ List of commands ran as player on join (ignores adminlevel)		Format: {":cmds"} ]]
	descs.OnSpawn = [[ List off commands ran as player on spawn (ignores adminlevel)	Format: {"!fire Really red",":ff me"} ]]

	descs.SaveAdmins = [[ If true anyone you :mod, :admin, or :owner in-game will save; This does not apply to helpers as they are considered temporary ]]
	descs.WhitelistEnabled = [[ If true enables the whitelist/server lock; Only lets admins & whitelisted users join ]]

	descs.Prefix = [[ The : in :kill me ]]
	descs.PlayerPrefix = [[ The ! in !donate; Mainly used for commands that any player can run ]]
	descs.SpecialPrefix = [[ Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me) ]]
	descs.SplitKey = [[ The space in :kill me (eg if you change it to / :kill me would be :kill/me) ]]
	descs.BatchKey = [[ :kill me | :ff bob | :explode scel ]]
	descs.ConsoleKeyCode = [[ Keybind to open the console ]]

	descs.HttpWait = [[ How long things that use the HttpService will wait before updating again ]]
	descs.Trello_Enabled = [[ Are the Trello features enabled? ]]
	descs.Trello_Primary = [[ Primary Trello board ]]
	descs.Trello_Secondary = [[ Secondary Trello boards; Format: {"BoardID";"BoardID2","etc"} ]]
	descs.Trello_AppKey = [[ Your Trello AppKey; Link: https://trello.com/app-key ]]
	descs.Trello_Token = [[ Trello token (DON'T SHARE WITH ANYONE!); Link: https://trello.com/1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE ]]

	descs.G_API = [[ If true allows other server scripts to access certain functions described in the API module through _G.Adonis ]]
	descs.G_Access = [[ If enabled allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player) ]]
	descs.G_Access_Key = [[ Key required to use the _G access API; Example_Key will not work for obvious reasons ]]
	descs.G_Access_Perms = [[ Access perms level ]]
	descs.Allowed_API_Calls = [[ Allowed calls ]]

	descs.FunCommands = [[ Are fun commands enabled? ]]
	descs.PlayerCommands = [[ Are players commands enabled? ]]
	descs.ChatCommands = [[ If false you will not be able to run commands via the chat; Instead you MUST use the console or you will be unable to run commands ]]

	descs.BanMessage = [[ Message shown to banned users ]]
	descs.LockMessage = [[ Message shown to people when they are kicked while the game is :slocked ]]
	descs.SystemTitle = [[ Title to display in :sm ]]

	descs.CreatorPowers = [[ When true gives me place owner admin; This is strictly used for debugging; I can't debug without access to the script and specific owner commands ]]
	descs.MaxLogs = [[ Maximum logs to save before deleting the oldest; Too high can lag the game ]]
	descs.Notification = [[ Whether or not to show the "You're an admin" and "Updated" notifications ]]
	descs.CodeExecution = [[ Enables the use of code execution in Adonis; Scripting related and a few other commands require this ]]
	descs.SongHint = [[ Display a hint with the current song name and ID when a song is played via :music ]]
	descs.TopBarHint = [[ By default hints and notifs will appear from the top edge of the window, this is acheived by offsetting them by -35 into the transparent region where roblox buttons menu/chat/leaderstat buttons are. Set this to true if you don't want hints/notifs to appear in that region. ]]

	descs.AutoClean = [[ Will auto clean service.Workspace of things like hats and tools ]]
	descs.AutoBackup = [[ (not recommended) Run a map backup command when the server starts, this is mostly useless as clients cannot modify the server. To restore the map run :restoremap ]]
	descs.AutoCleanDelay = [[ Time between auto cleans ]]

	descs.CustomChat = [[ Custom chat ]]
	descs.PlayerList = [[ Custom playerlist ]]
	descs.Console = [[ Command console ]]

	descs.DonorCommands = [[ Show your support for the script and let donors use commands like !sparkles ]]
	descs.DonorCapes = [[ Determines if donors have capes ]]
	descs.LocalCapes = [[ Makes Donor capes local instead of removing them ]]

	descs.HelpSystem = [[ Allows players to call admins for help using !help ]]
	descs.HelpButton = [[ Shows a little help button in the bottom right corner ]]

	descs.Detection = [[ Attempts to detect certain known exploits ]]
	descs.CheckClients = [[ Checks clients every minute or two to make sure they are still active ]]

	descs.AntiNil = [[ Try's to prevent non-admins from hiding in "nil" ]]
	descs.AntiSpeed = [[ Attempted to detect speed exploits ]]
	descs.AntiNoclip = [[ Attempts to detect noclipping and kills the player if found ]]
	descs.AntiParanoid = [[ Attempts to detect paranoid and kills the player if found ]]
	descs.AntiBuildingTools = [[ Attempts to detect any HopperBin(s)/Building Tools added to the client ]]
	descs.AntiLeak = [[ Attempts to prevent place downloading/saving; Do not use if game saves ]]

	order = {
		"HideScript";
		"DataStore";
		"DataStoreKey";
		"DataStoreEnabled";
		"Storage";
		" ";
		"Theme";
		"MobileTheme";
		" ";
		"Moderators";
		"Admins";
		"HeadAdmins";
		"Creators";
		"Banned";
		"Muted";
		"Blacklist";
		"Whitelist";
		"MusicList";
		"CapeList";
		"CustomRanks";
		" ";
		"OnStartup";
		"OnJoin";
		"OnSpawn";
		" ";
		"SaveAdmins";
		"WhitelistEnabled";
		" ";
		"Prefix";
		"PlayerPrefix";
		"SpecialPrefix";
		"SplitKey";
		"BatchKey";
		"ConsoleKeyCode";
		" ";
		"HttpWait";
		"Trello_Enabled";
		"Trello_Primary";
		"Trello_Secondary";
		"Trello_AppKey";
		"Trello_Token";
		" ";
		"G_API";
		"G_Access";
		"G_Access_Key";
		"G_Access_Perms";
		"Allowed_API_Calls";
		" ";
		"FunCommands";
		"PlayerCommands";
		"ChatCommands";
		"CreatorPowers";
		"CodeExecution";
		" ";
		"BanMessage";
		"LockMessage";
		"SystemTitle";
		" ";
		"MaxLogs";
		"Notification";
		"SongHint";
		"TopBarShift";
		"";
		"AutoClean";
		"AutoCleanDelay";
		" ";
		"CustomChat";
		"PlayerList";
		"Console";
		" ";
		"HelpSystem";
		"HelpButton";
		" ";
		"DonorCommands";
		"DonorCapes";
		"LocalCapes";
		" ";
		"Detection";
		"CheckClients";
		" ";
		"AntiNil";
		"AntiSpeed";
		"AntiNoclip";
		"AntiParanoid";
		"AntiBuildingTools";
		"AntiLeak";
	}

return {Settings = settings, Descriptions = descs, Order = order}
