------------------------------------------
--------	Welcome to Adonis	----------
------	Scroll down for settings	------
------------------------------------------


------------------------------------------
-----------	   Help Section		----------
------------------------------------------

--[[

	This is only here to help you when editing settings so you understand how they work.
	And don't break something.

	In case you don't know what Luau is; Luau is the scripting language Roblox uses...
	so every script you see (such as this one) and pretty much any code on Roblox is
	written in Luau.

	Anything that looks like {} is known as a table.
	Tables contain things, like the Luau version of a box.
	An example of a table would be setting = {"John", "Mary", "Bill"}
	You can have tables inside of tables, such in the case of setting = {{Group = 1234, Rank = 123, Type = "Admin"}}
	Just like real boxes, tables can contain pretty much anything including other tables.

	Note: Commas (,) as well as semicolons (;) can both be used to separate things inside a table.

	Anything that looks like "Bob" is what's known as a string. Strings
	are basically plain text; setting = "Bob" would be correct however
	setting = Bob would not; because if it's not surrounded by quotes Luau will think
	that Bob is a variable; Quotes indicate something is a string and therefore not a variable/number/code

	Numbers do not use quotes. setting = 56

	This green block of text you are reading is called a comment. It's like a message
	from the programmer to anyone who reads their stuff. Anything in a comment will
	not be seen by Luau when the script is run.


	Built-In Permissions Levels:
		Players - 0
		Moderators - 100
		Admins - 200
		HeadAdmins - 300
		Creators - 900

	Note that when changing command permissions you MUST include the prefix;
	So if you change the prefix to $ you would need to do $ff instead of :ff


	------------------------------------------
	------------	Trello		--------------
	------------------------------------------

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
		Moderators - Card Format: Same as settings.Moderators
		Admins - Card Format: Same as settings.Admins
		HeadAdmins - Card Format: Same as settings.HeadAdmins
		Creators - Card Format: Same as settings.Creators
		Banlist - Card Format: Same as settings.Banned
		Mutelist - Card Format: Same as settings.Muted
		Blacklist - Card Format: Same as settings.Blacklist
		Whitelist - Card Format: Same as settings.Whitelist
		Permissions - Card Format: Same as settings.Permissions
		Music - Card Format: SongName:AudioID
		Commands - Card Format: Command (e.g. :ff bob)

	Card format refers to how card names should look.


	------------------------------------------
	------------	Adonis		--------------
	------------------------------------------

	--// How to add administrators \\--

	Below are the administrator permission levels/ranks (Mods, Admins, HeadAdmins, Creators, StuffYouAdd, etc)
	Simply place users into the respective "Users" table for whatever level/rank you want to give them.

	Format Example:
		settings.Ranks = {
			["Moderators"] = {
				Level = 100;
				Users = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
			};
			
			["ExampleCustomRank"] = {
				Level = 150;
				Users = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}
			};
		}

	If you use custom ranks, existing custom ranks will be imported with a level of 1.
	Add all new CustomRanks to the table below with the respective level you want them to be.

	NOTE: Changing the level of built-in ranks (Moderators, Admins, HeadAdmins, Creators)
	- Will also change the permission level for any built-in commands associated with that rank.


	MAKE SURE YOU SET settings.DataStoreKey TO SOMETHING ABSOLUTELY RANDOM!!

]]--


------------------------------------------
------------- 	Contents	 -------------
------------------------------------------

--[[

	1. Datastore
	2. Themes
	3. Storage
	4. Administration
	5. External HTTP Api
	6. _G Access Api
	7. Commands
	8. Anti-Exploit
	9. Custom Commands

]]--


------------------------------------------
--------------	SETTINGS	--------------
------------------------------------------

local settings = {

	HideScript = true;
	-- Hides the script from the player's screen.
	-- This is recommended to prevent players from accessing your settings.



	--// 1. Datastore \\--

	DataStore = "Adonis_1";
	-- The datastore to use for saving data.
	-- This is used for storing the data. Changing this will erase all saved data.

	DataStoreKey = "CHANGE_THIS";
	-- The key to use when accessing the datastore.
	-- MAKE SURE YOU SET THIS TO SOMETHING ABSOLUTELY RANDOM!!

	DataStoreEnabled = true;
	-- Whether or not to save data to the datastore.

	LocalDatastore = false;
	-- If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers.


	--// 2. Themes \\--

	Theme = "Default";
	-- The UI Theme.


	MobileTheme = "Mobilius";
	-- The UI Theme for mobile devices.


	DefaultTheme = "Default";
	-- The default theme to use if a player has not set one.



	--// 3. Storage \\--

	Storage = game:GetService("ServerStorage");
	-- The storage location to use for tools.


	RecursiveTools = false;
	-- Whether or not to search for tools in subfolders.



	--// 4. Administration \\--

	SaveAdmins = true;
	-- Whether or not admins ranked in-game save.


	LoadAdminsFromDS = true;
	-- Whether or not to load admins from the datastore.


	CreatorPowers = true;
	-- Gives me creator level admin.
	-- This is strictly used for debugging; I cannot debug without full access to Adonis.

	HelpSystem = true;
	-- Allows players to call admins for help using "!help".


	HelpButton = true;
	-- Shows a little icon in the bottom left of the player's screen.


	HelpButtonImage = "rbxassetid://357249130";
	-- The icon used for the help icon.


	Ranks = {
		["Moderators"] = {
			Level = 100;
			Hidden = false;
			-- Whether this rank is hidden in the admins list.
			Users = {
				""; -- Add user here. See help above for more info.
			}
		};

		["Admins"] = {
			Level = 200;
			Hidden = false;
			-- Whether this rank is hidden in the admins list.
			Users = {
				""; -- Add users here. See help above for more info.
			}
		};

		["HeadAdmins"] = {
			Level = 300;
			Hidden = false;
			-- Whether this rank is hidden in the admins list.
			Users = {
				""; -- Add users here. See help above for more info.
			}
		};

		["Creators"] = {
			Level = 900;
			Hidden = false;
			-- Whether this rank is hidden in the admins list.
			Users = {
				""; -- Add users here. See help above for more info.
			}
		}
	};

	Banned = {};
	-- List of banned players.
	-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}

	BanMessage = "Banned";
	-- The message shown to banned players on joining.


	Muted = {};
	-- List of people who cannot chat in ROBLOX's chat.
	-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}

	Blacklist = {};
	-- List of players banned from running commands.
	-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}

	Whitelist = {};
	-- List of players who can join regardless of whitelist.
	-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";}

	WhitelistEnabled = false;
	-- Prevents players from joining the specific server.
	-- Allows admins and whitelisted players to join.

	LockMessage = "Not whitelisted";
	-- The message shown to players who are not whitelisted on joining a slocked server.


	SystemTitle = "System Message";
	-- The title of system messages.


	Messages = {};
	-- List of messages to be sent to HeadAdmins and above on join.
	-- Format: {"Message1"; "Message2";}

	MaxLogs = 5000;
	-- The maximum amount of command logs to be stored.


	SaveCommandLogs = true;
	-- Whether to save command logs to the datastore.


	Notification = true;
	-- Whether or not to show the "You're and admin" and "Updated" notifications.


	SongHint = true;
	-- Whether or not to show a hint or the current song.


	TopBarShift = false;
	-- By default hints and notifications will appear from the top edge of the window.
	-- Set this to true if you don't want hints/notifications to appear in that region.

	AutoClean = false;
	-- Will auto clean workspace of things like hats and tools.


	AutoCleanDelay = 60;
	-- Time between auto cleans.


	AutoBackup = false;
	-- Run :backupmap automatically when the server starts. To restore the map, run :restoremap



	--// 5. External HTTP Api \\--

	HttpsWait = 60;
	-- How long HttpService wil wait before updating again; In seconds.


	Trello_Enabled = false;
	-- Are Trello features enabled.


	Trello_Primary = "";
	-- Primary Trello board.


	Trello_Secondary = {};
	-- Secondary Trello boards.
	-- Format: "BoardID1";"BoardID2","etc";

	Trello_AppKey = "";
	-- Your Trello Api key.
	-- Link: https://trello.com/app-key

	Trello_Token = "";
	-- DO NOT SHARE WITH ANYONE!!
	-- Your Trello token.

	Trello_HideRanks = false;
	-- If true, Trello-assigned ranks won't be shown in the admins list UI.



	--// 6. _G Access Api \\--

	Allowed_API_Calls = {
		Client = false;
		-- Allow access to the Client (not recommended).

		Settings = false;
		-- Allow access to settings (not recommended).

		DataStore = false;
		-- Allow access to the DataStore (not recommended).

		Core = false;
		-- Allow access to the script's core table (REALLY not recommended).

		Service = false;
		-- Allow access to the script's service metatable.

		Remote = false;
		-- Communication table.

		HTTP = false;
		-- HTTP-related things like Trello functions.

		Anti = false;
		-- Anti-Exploit table.

		Logs = false;

		UI = false;
		-- Client UI table.

		Admin = false;
		-- Admin related functions.

		Functions = false;
		-- Functions table (contains functions used by the script that don't have a subcategory).

		Variables = true;
		-- Variables table.

		API_Specific = true;
		-- API Specific functions.
	};

	G_API = true;
	-- Allows other non-Adonis scripts access to certain features.


	G_Access = false;
	-- Allows other non-Adonis scripts access using _G.Adonis.Access.


	G_Access_Key = "Example_Key";
	-- Key required to use the _G access Api.


	G_Access_Perms = "Read";
	-- _G access permissions.



	--// 7. Commands \\--

	Prefix = ":";
	-- Prefix for admin commands.


	PlayerPrefix = "!";
	-- Prefix for player commands.
	-- Do not make the same as Prefix.

	SpecialPrefix = "";
	-- Used for playerfinders.
	-- Example ":kill !others"

	SplitKey = " ";
	-- The space in commands.
	-- Example ":fling all"

	BatchKey = "|";
	-- The key used to split commands.
	-- Example: ":kill me | :fling others"

	Console = true;
	-- Whether the command console is enabled.


	Console_AdminsOnly = false;
	-- Whether the console is only avalible to admins.


	ConsoleKeyCode = "Quote";
	-- The key used to open the commands console.
	-- KeyCodes: https://developer.roblox.com/en-us/api-reference/enum/KeyCode

	Permissions = {

		-- Use this to change permissions of commands.
		-- Format: "Command:NewLevel"; "Command:Customrank1,Customrank2,Customrank3";

		-- Examples
		-- "kill:HeadAdmins" - Sets :kill to HeadAdmins and higher.
		-- "ff:300" - Sets :ff to levels 300 and higher.
		-- "ban:100, 300" - Sets :ban to levels 100 and 300 only.
	};


	Aliases = {

		-- Use this to create aliases of commands.
		-- Format
		-- [":Command <arg1> <arg2>"] = ":Command <arg1> | :Command <arg1> <arg2>"

		-- Examples
		-- [":floop <player> <firecolor>"] = ":Command <player> | :Command <player> <firecolor>"
	};

	OnStartup = {};
	-- Commands to run on server startup.
	-- Format: {":Command"; ":Command <arg1> <arg2>";}

	OnJoin = {};
	-- Commands to run on player join.
	-- Format: {":Command"; ":Command <arg1> <arg2>";}

	OnSpawn = {};
	-- Commands to run on player spawn.
	-- Format: {":Command"; ":Command <arg1> <arg2>";}

	CommandCooldowns = {
		--[[
			REFERENCE:
				command_full_name: The name of a command (e.g. :cmds)

			[command_full_name] = {
				Player = 0; -- Time in seconds.
				Server = 0;
				Cross = 0;
			}
		]]	
	};

	MusicList = {};
	-- List of music ids.
	-- Format: {{Name = "somesong", ID = 1234567}, {Name = "anotherone", ID = 1243562}}

	CapeList = {};
	-- List of capes.
	-- Format: {{Name = "somecape", Material = "Fabric", Color = "Bright yellow", ID = 12345567, Reflectance = 1};

	InsertList = {};
	-- List of insertable models.
	-- Format: {{Name = "someinsert", ID = 1234567}, {Name = "anotherone", ID = 1243562}}

	FunCommands = true;
	-- Whether fun commands are enabled.


	PlayerCommands = true;
	-- Whether player commands are enabled.


	CommandFeedback = false;
	-- Whether command feedback is enabled.
	-- Players are notified when non-obvious commands are run on them.

	CrossServerCommands = true;
	-- Whether cross server commands are enabled.


	ChatCommands = true;
	-- Whether commands can be run on ROBLOX's chat.


	CodeExecution = true;
	-- Whether code execution is enabled.
	-- This allows players to run code ediotor commands on the server.

	SilentCommandDenials = false;
	-- Whether command denials are silent.
	-- If true, players will not be notified when they do not have permission to run a command.

	OverrideChatCallbacks = true;
	-- If the TextChatService ShouldDeliverCallbacks of all channels are overridden by Adonis on load. Required for muting.


	DonorCapes = true;
	-- Donors get to show off their capes; Not disruptive :)


	DonorCommands = true;
	-- Show your support for the script and let donors use harmless commands like !sparkles


	LocalCapes = false;
	--Makes Donor capes local so only the donors see their cape [All players can still disable capes locally]	



	--// 8. Anti-Exploit \\--
	Detection = true;
	-- (Extremely important, makes all protection systems work)
	-- A global toggle for all the other protection settings.


	CheckClients = true;
	-- (Important, makes sure Adonis clients are connected to the server)
	-- Check clients every minute or two to make sure they're still active.


	ExploitNotifications = true;
	-- Notify modorators and higher that an a player was kicked by the AntiExploit.


	CharacterCheckLogs = false;
	-- If the character checks appear in exploit logs and exploit notifications.


	AntiNoclip = false;
	-- Attempts to detect noclipping and kills the player if found.


	AntiRootJointDeletion = false;
	-- Attempts to detect paranoid and kills the player if found.


	AntiMultiTool = false;
	-- Prevents multitooling and because of that many other exploits.


	AntiGod = false;
	-- If a player does not respawn when they should have they get respawned.


	AntiSpeed = true;
	-- (Client-Sided) Attempts to detect speed exploits.


	AntiBuildingTools = false;
	--  (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client.


	AntiAntiIdle = false;
	-- (Client-Sided) Kick the player if they are using an anti-idle exploit.
	--  Highly useful for grinding/farming games.


	ExploitGuiDetection = false;
	-- (Client-Sided) If any exploit GUIs are found in the CoreGui the exploiter gets kicked.
	-- (If you use StarterGui:SetCore("SendNotification") with an image this will kick you)
}


--// IGNORE \\--
local Settings = settings;
-- For custom commands that use 'Settings' rather than lowercase 'settings'.
-- NOT AN EDITABLE SETTING


--// 9. Custom Commands \\--

settings.Commands = {
	ExampleCommand1 = {
		Prefix = Settings.Prefix;
		--// The prefix the command will use defined above.
		-- This is the ':' in ':ff me'

		Commands = {"examplecommand1", "examplealias1", "examplealias2"};
		--// A table containing the command strings (the things you say in chat to run the command).
		-- This is the 'ff' in ':ff me'.

		Args = {"arg1", "arg2", "etc"};
		--// Command arguments, these will be available in order as args[1], args[2], args[3], etc.
		-- This is the 'me' in ':ff me'.

		Description = "Example command";
		--// The description of the command.

		AdminLevel = 100;
		--// The commands minimum admin level; Can be either the rank name or level number
		-- This can also be a table containing specific levels rather than a minimum level: {124, 152, "HeadAdmins", etc}

		Filter = true;
		--// Should user-supplied text passed to this command be filtered automatically?
		-- Use this if you plan to display a user-defined message to other players

		Hidden = true;
		--// Should this command be hidden from the command list?

		Disabled = true;
		--// If set to true this command won't be usable.

		Function = function(plr: Player, args: {string}, data)
			--// The command's function; This is the actual code of the command which runs when you run the command

			--// "plr" is the player running the command
			--// "args" is an array of strings containing command arguments supplied by the user
			--// "data" is a table containing information related to the command and the player running it, such as data.PlayerData.Level (the player's admin level) [Refer to API docs]

			print("This is 'arg1':", tostring(args[1]))
			print("This is 'arg2':", tostring(args[2]))
			print("This is 'etc'(arg 3):", tostring(args[3]))
			error("this is an example error :O !") --// Errors raised in the function during command execution will be displayed to the user.
		end
	};
}

------------------------------------------
---------	END OF THE SETTINGS	----------
------------------------------------------



------------------------------------------
-----------	DESCRIPTIONS	--------------
------------------------------------------

--// Setting descriptions used for the in-game settings editor;

local descs = {}

descs.HideScript = [[ When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module. ]]
descs.DataStore = [[ The datastore to use for saving data. This is used for storing the data. Changing this will erase all saved data.]]
descs.DataStoreKey = [[ The key to use when accessing the datastore. ]]
descs.DataStoreEnabled = [[ Whether or not to save data to the datastore. ]]
descs.LocalDatastore = [[ If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers. ]]

descs.Theme = [[ The UI Theme. ]]
descs.DefaultTheme = [[ The default theme to use if a player has not set one. ]]
descs.MobileTheme = [[ Theme to use on mobile devices. Mobile themes are optimized for smaller screens. Some GUIs are disabled ]]

descs.Storage = [[ The storage location to use for tools. ]]
descs.RecursiveTools = [[ Whether or not to search for tools in subfolders. ]]

descs.SaveAdmins = [[ Whether or not admins ranked in-game save. ]]
descs.LoadAdminsFromDS = [[ Whether or not to load admins from the datastore. ]]
descs.CreatorPowers = [[ Gives me creator level admin. This is strictly used for debugging; I cannot debug without full access to Adonis.]]

descs.HelpSystem = [[ Allows players to call admins for help using "!help". ]]
descs.HelpButton = [[ Shows a little icon in the bottom left of the player's screen. ]]
descs.HelpButtonImage = [[ The icon used for the help icon. ]]

descs.Ranks = [[ All admin permission level ranks. ]];
descs.Moderators = [[ Moderators. ]]
descs.Admins = [[ Administrators. ]]
descs.HeadAdmins = [[ Head Administrators. ]]
descs.Creators = [[ Creators. ]]

descs.Banned = [[ List of banned players. ]]
descs.BanMessage = [[ The message shown to banned players on joining. ]]
descs.Muted = [[ List of people who cannot chat in ROBLOX's chat. ]]
descs.Blacklist = [[ List of players banned from running commands. ]]
descs.Whitelist = [[ List of players who can join regardless of whitelist. ]]
descs.WhitelistEnabled = [[ Prevents players from joining the specific server. ]]
descs.LockMessage = [[ The message shown to players who are not whitelisted on joining a slocked server. ]]
descs.SystemTitle = [[ The title of system messages. ]]
descs.Messages = [[ List of messages to be sent to HeadAdmins and above on join. ]]

descs.MaxLogs = [[ The maximum amount of command logs to be stored. ]]
descs.SaveCommandLogs = [[ Whether to save command logs to the datastore. ]]
descs.Notification = [[ Whether or not to show the "You're and admin" and "Updated" notifications. ]]
descs.SongHint = [[ Whether or not to show a hint or the current song. ]]
descs.TopBarShift = [[ By default hints and notifications will appear from the top edge of the window. Set this to true if you don't want hints/notifications to appear in that region. ]]

descs.AutoClean = [[ Will auto clean workspace of things like hats and tools. ]]
descs.AutoCleanDelay = [[ Time between auto cleans.  ]]
descs.AutoBackup = [[ Runs :backupmap automatically when the server starts. To restore the map, run :restoremap. ]]

descs.HttpWait = [[ How long HttpService wil wait before updating again; In seconds. ]]
descs.Trello_Enabled = [[ Are Trello features enabled. ]]
descs.Trello_Primary = [[ Primary Trello board. ]]
descs.Trello_Secondary = [[ Secondary Trello boards. ]]
descs.Trello_AppKey = [[ Your Trello Api key. ]]
descs.Trello_Token = [[ Your Trello token. ]]
descs.Trello_HideRanks = [[ If true, Trello-assigned ranks won't be shown in the admins list UI. ]]

descs.Allowed_API_Calls = [[ Allowed calls. ]]
descs.G_API = [[ Allows other non-Adonis scripts access to certain features. ]]
descs.G_Access = [[ Allows other non-Adonis scripts access using _G.Adonis.Access ]]
descs.G_Access_Key = [[ Key required to use the _G access Api. ]]
descs.G_Access_Perms = [[ _G access permissions. ]]

descs.Prefix = [[ Prefix for admin commands. ]]
descs.PlayerPrefix = [[ Prefix for player commands. Do not make the same as Prefix. ]]
descs.SpecialPrefix = [[ Used for playerfinders. ]]
descs.SplitKey = [[ The space in commands. ]]
descs.BatchKey = [[ The key used to split commands. ]]
descs.Console = [[ Whether the command console is enabled. ]]
descs.Console_AdminsOnly = [[ Whether the console is only avalible to admins. ]]
descs.ConsoleKeyCode = [[ The key used to open the commands console.  ]]

descs.Permissions = [[ Change the permissions of commands. ]]
descs.Aliases = [[ Create command aliases. ]]

descs.OnStartup = [[ Commands to run on server startup. ]]
descs.OnJoin = [[ Commands to run on player join. ]]
descs.OnSpawn = [[ Commands to run on player spawn. ]]

descs.CommandCooldowns = [[ Command cooldowns. ]]

descs.MusicList = [[ List of music ids. ]]
descs.CapeList = [[ List of capes. ]]
descs.InsertList = [[ List of insertable models. ]]

descs.FunCommands = [[ Whether fun commands are enabled. ]]
descs.PlayerCommands = [[ Whether player commands are enabled. ]]
descs.CommandFeedback = [[ Whether command feedback is enabled. Players are notified when non-obvious commands are run on them. ]]
descs.CrossServerCommands = [[ Whether cross server commands are enabled. ]]
descs.ChatCommands = [[ Whether commands can be run on ROBLOX's chat. ]]
descs.CodeExecution = [[  Whether code execution is enabled. This allows players to run code editor commands on the server. ]]
descs.SilentCommandDenials = [[ Whether command denials are silent. If true, players will not be notified when they do not have permission to run a command. ]]
descs.OverrideChatCallbacks = [[ If the TextChatService ShouldDeliverCallbacks of all channels are overriden by Adonis on load. Required for muting. ]]

descs.DonorCapes = [[ Donors get to show off their capes; Not disruptive :) ]]
descs.DonorCommands = [[ Show your support for the script and let donors use harmless commands like !sparkles ]]
descs.LocalCapes = [[ Makes Donor capes local so only the donors see their cape [All players can still disable capes locally] ]]

descs.Detection = [[ (Extremely important, makes all protection systems work) A global toggle for all the other protection settings. ]]
descs.CheckClients = [[ (Important, makes sure Adonis clients are connected to the server). Check clients every minute or two to make sure they're still active. ]]
descs.ExploitNotifications = [[ Notify modorators and higher that an a player was kicked by the AntiExploit. ]]
descs.CharacterCheckLogs = [[ If the character checks appear in exploit logs and exploit notifications. ]]
descs.AntiNoclip = [[ Attempts to detect noclipping and kills the player if found. ]]
descs.AntiRootJointDeletion = [[ Attempts to detect paranoid and kills the player if found. ]]
descs.AntiMultiTool = [[ Prevents multitooling and because of that many other exploits. ]]
descs.AntiGod = [[ If a player does not respawn when they should have they get respawned. ]]
descs.AntiSpeed = [[ (Client-Sided) Attempts to detect speed exploits. ]]
descs.AntiBuildingTools = [[ (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client. ]]
descs.AntiAntiIdle  = [[ (Client-Sided) Kick the player if they are using an anti-idle exploit. Highly useful for grinding/farming games. ]]
descs.ExploitGuiDetection = [[(Client-Sided) If any exploit GUIs are found in the CoreGui the exploiter gets kicked (If you use StarterGui:SetCore("SendNotification") with an image this will kick you) ]]
descs.Commands = [[ Custom commands. ]]

local order = {
	"HideScript";
	"DataStore";
	"DataStoreEnabled";
	"DataStoreKey";
	"LocalDatastore";
	" ";
	"DataStore";
	"DataStoreEnabled";
	"DataStoreKey";
	"LocalDatastore";
	" ";
	"Theme";
	"DefaultTheme";
	"MobileTheme";
	" ";
	"Storage";
	"RecursiveTools";
	" ";
	"SaveAdmins";
	"LoadAdminsFromDS";
	"CreatorPowers";
	" ";
	"HelpSystem";
	"HelpButton";
	"HelpButtonImage";
	" ";
	"Ranks";
	" ";
	"Banned";
	"BanMessage";
	"Muted";
	"Blacklist";
	"Whitelist";
	"WhitelistEnabled";
	"LockMessage";
	"SystemTitle";
	"Messages";
	" ";
	"MaxLogs";
	"SaveCommandLogs";
	"Notification";
	"SongHint";
	"TopBarShift";
	" ";
	"AutoBackup";
	"AutoClean";
	"AutoCleanDelay";
	" ";
	"HttpsWait";
	"Trello_Enabled";
	"Trello_Primary";
	"Trello_Secondary";
	"Trello_AppKey";
	"Trello_Token";
	"Trello_HideRanks";
	" ";
	"Allowed_Api_Calls";
	"G_API";
	"G_Access";
	"G_Access_Key";
	"G_Access_Perms";
	" ";
	"Prefix";
	"PlayerPrefix";
	"SpecialPrefix";
	"SplitKey";
	"BatchKey";
	"Console";
	"Console_AdminsOnly";
	"ConsoleKeycode";
	" ";
	"Permissions";
	"Aliases";
	" ";
	"OnStartup";
	"OnJoin";	
	"OnSpawn";
	" ";
	"CommandCooldowns";
	" ";
	"MusicList";
	"CapeList";
	"InsertList";
	" ";
	"FunCommands";
	"PlayerCommands";
	"CommandFeedback";
	"CrossServerCommands";
	"ChatCommands";
	"CodeExecution";
	"SilentCommandDenials";
	"OverrideChatCallbacks";
	" ";
	"DonorCapes";
	"DonorCommands";
	"LocalCapes";
	" ";
	"Detection";
	"CheckClients";
	"ExploitNotifications";
	"CharacterCheckLogs";
	"AntiNoclip";
	"AntiRootJointDeletion";
	"AntiMultiTool";
	"AntiGod";
	"AntiSpeed";
	"AntiBuildingTools";
	"AntiAntiIdle";
	"ExploitGuiDetection";
	"";
	"Commands"
}

return {Settings = settings, Descriptions = descs, Order = order}
