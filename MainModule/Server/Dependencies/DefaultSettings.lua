------------------------------------------
--------	Welcome to Adonis	----------
------	Scroll down for settings	------
------------------------------------------


------------------------------------------
----------	Basics of Luau code	----------
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

	1. Core Settings
	2. Themes
	3. Storage
	4. Administration
	5. Commands
	6. Lists and logs
	7. Miscellaneous
	8. External HTTP API
	9. _G Access API
	10. Anti-Exploit
	11. Custom Commands

]]--


------------------------------------------
--------------	SETTINGS	--------------
------------------------------------------

local settings = {

	--// 1. Core Settings \\--

	DataStore = "Adonis_1";
		-- The DataStore name that Adonis uses to save data.
		-- Changing this will lose any saved data.

	DataStoreEnabled = true;
		-- Loads settings and admins from the DataStore.
		-- Disable if you do not want this; Player data will still happen.

	DataStoreKey = "CHANGE_THIS";
		-- CHANGE THIS TO SOMETHING RANDOM!
		-- The key used to encrypt all DataStore entries.
		-- Changing this will lose any saved data.

	HideScript = true;
		-- Whether the Adonis Loader model gets hidden.
		-- Disable if your game uses AssetService:SavePlaceAsync()

	LocalDatastore = false;
		-- Makes Adonis use a mock DataStore instead.
		-- Data will never save across servers.



	--// 2. Themes \\--

	Theme = "Default";
		-- The UI theme.

	DefaultTheme = "Default";
		-- Theme to be used as a replacement for "Default".

	MobileTheme = "Mobilius";
		-- The theme used on mobile devices.
		-- Disables some UI Elements.



	--// 3. Storage \\--

	RecursiveTools = false;
		-- Whether Adonis searches for tools in sub-folders.

	Storage = game:GetService("ServerStorage");
		-- Where things like tools are stored.



	--// 4. Administration \\--

	Banned = {};
		-- List of banned players.
		-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";

	BanMessage = "Banned";
		-- The message shown to banned players on joining.

	Blacklist = {};
		-- List of players banned from running commands.
		-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";

	CreatorPowers = true;
		-- Gives me creator level admin. Stictly used for debugging only.

	HelpSystem = true;
		-- Allows players to call for admins using "!help".

	HelpButton = true;
		-- Whether the help button is shown in the bottom right corner.

	HelpButtonImage = "rbxassetid://357249130";
		-- The image the help button uses.

	LoadAdminsFromDS = true;
		-- Whether admins saved in the DataStore will load.

	LockMessage = "Not Whitelisted";
		-- The message shown to players when they try to join a whitelisted locked server.

	Muted = {};
		-- List of people who cannot chat in ROBLOX's chat.
		-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";

	Notification = true;
		-- Whether or not to show the "You're an admin" and "Updated" notifications.

	OverrideChatCallbacks = true;
		-- If the TextChatService ShouldDeliverCallbacks of all channels are overriden by Adonis on load. Required for muting.

	Ranks = {
		["Moderators"] = {
			Level = 100;
			Hidden = false;
				-- Whether this rank is hidden in the list if empty.
			Users = {
				-- Add user here
			}
		};

		["Admins"] = {
			Level = 200;
			Hidden = false;
				-- Whether this rank is hidden in the list if empty.
			Users = {
				-- Add users here
			}
		};

		["HeadAdmins"] = {
			Level = 300;
			Hidden = false;
				-- Whether this rank is hidden in the list if empty.
			Users = {
				"roblox"-- Add users here
			}
		};

		["Creators"] = {
			Level = 900;
			Hidden = false;
				-- Whether this rank is hidden in the list if empty.
			Users = {
				"techally"-- Add users here
			}
		}

	};

	SaveAdmins = true;
		-- Whether players who get admin ranks using ":admin" saves.

	SystemTitle = "System Message";
		-- The title displayed in :sm and :bc

	Whitelist = {};
		-- List of players who can join regardless of whitelist.
		-- Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID"; "GamePass:GamePassID";

	WhitelistEnabled = false;
		-- Prevents players from joining the specific server.
		-- Allows admins and whitelisted players to join.



	--// 5. Commands \\--

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


	Aliases = {
		-- Use this to create aliases of commands.
		-- Format
		-- [":Command <arg1> <arg2>"] = ":Command <arg1> | :Command <arg1> <arg2>"

		-- Examples
		-- [":floop <player> <firecolor>"] = ":Command <player> | :Command <player> <firecolor>"

	};

	ChatCommands = true;
		-- Whether commands said in ROBLOX's chat will execute.

	CodeExecution = true;
		-- Whether commands that can execute code are enabled.

	CommandCooldowns = {
		--[[
			REFERENCE:
			command_full_name: The name of a command (e.g. :cmds)

			[command_full_name] = {
				Player = 0; -- Time in seconds
				Server = 0; -- Time in seconds
				Cross = 0; -- Time in seconds
			};
		]]--
	};

	CommandFeedback = false;
		-- Whether players are notified when commands with non-obious effects are run on them.

	Console = true;
		-- Whether the command console is enabled.

	Console_AdminsOnly = false;
		-- Whether the console is only avalible to admins.

	ConsoleKeycode = "Quote";
		-- Key to open the command console.
		-- KeyCodes: https://developer.roblox.com/en-us/api-reference/enum/KeyCode

	CrossServerCommands = true;
		-- Whether commands that affect other servers are enabled.

	DonorCapes = true;
		-- Allows donors to show off their capes; Not disruptive :)

	DonorCommands = true;
		-- Show your support for the script and let donors use harmless commands like !sparkles.

	FunCommands = true;
		-- Whether fun commands are enabled.

	LocalCapes = false;
		-- Makes Donor capes local so only the donors see their cape.

	OnJoin = {};
		-- List of commands run as player when they join; Ignores admin level.
		-- Format: ":cmds";

	OnStartup = {};
		-- List of commands run at startup.
		-- Format: ":notify all hi";

	OnSpawn = {};
		-- List of commands ran as player on spawn; Ignores admin level.
		-- Format: ":ff me";

	Permission = {
		-- Use this to change permissions of commands.
		-- Format: "Command:NewLevel"; Command:Customrank1,Customrank2,Customrank3";

		-- Examples
		-- "kill:HeadAdmins" - Sets :kill to HeadAdmins and higher.
		-- "ff:300" - Sets :ff to levels 300 and higher.
		-- "ban:100, 300" - Sets :ban to levels 100 and 300 only.
	};

	PlayerCommands = true;
		-- Whether player commands are enabled.

	SilentCommandDenials = false;
		-- Whether error messages appear if a user trys an invalid/unprivilaged command.



	--// 6. Lists and Logs \\--

	CapeList = {};
		-- List of capes.
		--Format: {{Name = "somecape", Material = "Fabric", Color = "Bright yellow", ID = 12345567, Reflectance = 1};

	InsertList = {};
		-- List of models that appear in :insertlist and can be inserted using ":insert name"
		-- Format: {Name = "somemodel", ID = 1234567}; {Name = "anotherone", ID = 1243562}

	MaxLogs = 5000;
		-- Maximum logs to save before deleting the oldest.

	MusicList = {};
		-- List of songs the appear in the music list.
		-- Format: {{Name = "somesong", ID = 1234567}, {Name = "anotherone", ID = 1243562}}

	Messages = {};
		-- List of notifications shown to HeadAdmins and above.

	SaveCommandLogs = true;
		-- If command logs are saved.



	--// 7. Miscellaneous \\--

	AutoBackup = false;
		-- Runs :backupmap automatically when the server starts. To restore the map, run :restoremap.

	AutoClean = false;
		-- Auto-cleans the workspace of things like hats and tools.

	AutoCleanDelay = 60;
		-- Time between auto cleans; Seconds.

	SongHing = true;
		-- Display a hint with the current song and name.

	TopBarShift = false;
		-- By default hints and notifications will appear from the top edge of the window,
		-- this is achieved by offsetting them by -35 into the transparent region where ROBLOX buttons menu/chat/leaderstat buttons are. 
		-- Set this to true if you don't want hints/notifications to appear in that region.



	--// 8. External HTTP Api \\--

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
		-- Whether Trello-assigned ranks are shown in admin lists.



	--// 9. _G Access Api \\--

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

	G_Access_Key = "";
		-- Key required to use the _G access Api.

	G_Access_Perms = "Read";
		-- _G access permissions.



	--// 10. Anti-Exploit \\--

	AntiBuildingTools = false;
		-- (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client.

	AntiClientIdle = false;
		-- (Client-Sided) Kick the player if they are using an anti-idle exploit.

	AntiHumanoidDeletion = false;
		-- (Very important) Prevents invalid humanoid deletion. Un-does the deletion and kills the player.

	AntiGod = false;
		-- If a player does not respawn when they should have they get respawned.

	AntiMultiTool = false;
		-- Prevents multitools and because of that many other exploits.

	AntiNoclip = false;
		-- Attempts to detect noclipping and kills the player if found.

	AntiRootJointDeletion = false;
		-- Attempts to detect paranoid and kills the player if found.

	AntiSpeed = true;
		-- (Client-Sided) Attempts to detect speed exploits.

	CharacterCheckLogs = false;
		-- If the character checks appear in exploit logs and exploit notifications.

	CheckClients = true;
		-- Checks clients every minute or two to make sure they are still active.

	Detection = true;
		-- Attempts to detect certain known exploits.

	ExploitNotifications = true;
		--  Notify all moderators and higher when a player is kicked or crashed from the AntiExploit.

	ProtectedHats = false;
		-- Prevents hats from being un-welded from their characters through unnormal means.
}


--// IGNORE \\--
local Settings = settings;
-- For custom commands that use 'Settings' rather than lowercase 'settings'.
-- NOT AN EDITABLE SETTING


--// 11. Custom Commands \\--

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

descs.DataStore = [[ DataStore the script will use for saving data; Changing this will lose any saved data ]]
descs.DataStoreEnabled = [[ Disable if you don't want settings and admins to be saveable in-game; PlayerData will still save ]]
descs.DataStoreKey = [[ Key used to encode all datastore entries; Changing this will lose any saved data ]]
descs.HideScript = [[ Disable if your game saves; When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module ]]
descs.LocalDatastore = [[ If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers ]]

descs.Theme = [[ UI theme; ]]
descs.DefaultTheme = [[ Theme to be used as a replacement for "Default". The new replacement theme can still use "Default" as its Base_Theme however any other theme which references "Default" as its redirects to this theme. ]]
descs.MobileTheme = [[ Theme to use on mobile devices; Mobile themes are optimized for smaller screens; Some GUIs are disabled ]]

descs.RecursiveTools = [[ Whether tools included in subcontainers within settings.Storage are available via the :give command (useful if your tools are organized into multiple folders) ]]
descs.Storage = [[ Where things like tools are stored ]]

descs.Banned = [[ List of people banned from the game; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.BanMessage = [[ Message shown to banned users ]]
descs.Blacklist = [[ List of people banned from using admin; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.CreatorPowers = [[ When true gives me place owner admin; This is strictly used for debugging; I can't debug without access to the script and specific owner commands ]]
descs.HelpSystem = [[ Allows players to call admins for help using !help ]]
descs.HelpButton = [[ Shows a little help button in the bottom right corner ]]
descs.HelpButtonImage = [[ Change this to change the help button's image ]]
descs.LoadAdminsFromDS = [[ If false, any admins saved in your DataStores will not load ]]
descs.LockMessage = [[ Message shown to people when they are kicked while the game is :slocked ]]
descs.Muted = [[ List of people muted; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Notification = [[ Whether or not to show the "You're an admin" and "Updated" notifications ]]
descs.OverrideChatCallbacks = [[ If the TextChatService ShouldDeliverCallbacks of all channels are overriden by Adonis on load. Required for muting ]]
descs.Ranks = [[ All admin permission level ranks; ]];
descs.Moderators = [[ Mods; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Admins = [[ Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.HeadAdmins = [[ Head Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.Creators = [[ Anyone to be identified as a place owner; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.SaveAdmins = [[ If true anyone you :mod, :admin, or :headadmin in-game will save]]
descs.SystemTitle = [[ Title to display in :sm ]]
descs.Whitelist = [[ People who can join if whitelist enabled; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]]
descs.WhitelistEnabled = [[ If true enables the whitelist/server lock; Only lets admins & whitelisted users join ]]

descs.Prefix = [[ The : in :kill me ]]
descs.PlayerPrefix = [[ The ! in !donate; Mainly used for commands that any player can run ]]
descs.SpecialPrefix = [[ Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me) ]]
descs.SplitKey = [[ The space in :kill me (eg if you change it to / :kill me would be :kill/me) ]]
descs.BatchKey = [[ :kill me | :ff bob | :explode scel ]]

descs.Aliases = [[ Command aliases; Format: {[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."} ]]
descs.ChatCommands = [[ If false you will not be able to run commands via the chat; Instead you MUST use the console or you will be unable to run commands ]]
descs.CodeExecution = [[ Enables the use of code execution in Adonis; Scripting related and a few other commands require this ]]
descs.CommandCooldowns = [[ PLACEHOLDER ]]
descs.CommandFeedback = [[ Should players be notified when commands with non-obvious effects are run on them? ]]
descs.Console = [[ Command console ]]
descs.Console_AdminsOnly = [[ Makes it so if the console is enabled, only admins will see it ]]
descs.ConsoleKeyCode = [[ Keybind to open the console ]]
descs.CrossServerCommands = [[ Are commands which affect more than one server enabled? ]]
descs.DonorCapes = [[ Determines if donors have capes ]]
descs.DonorCommands = [[ Show your support for the script and let donors use commands like !sparkles ]]
descs.FunCommands = [[ Are fun commands enabled? ]]
descs.LocalCapes = [[ Makes Donor capes local instead of removing them ]]
descs.OnJoin = [[ List of commands ran as player on join (ignores adminlevel)		Format: {":cmds"} ]]
descs.OnStartup = [[ List of commands ran at server start								Format: {":notif TestNotif"} ]]
descs.OnSpawn = [[ List off commands ran as player on spawn (ignores adminlevel)	Format: {"!fire Really red",":ff me"} ]]
descs.Permissions = [[ Command permissions; Format: {"Command:NewLevel";} ]]
descs.PlayerCommands = [[ Are players commands enabled? ]]
descs.SilentCommandDenials = [[ If true, there will be no differences between the error messages shown when a user enters an invalid command and when they have insufficient permissions for the command ]]

descs.CapeList = [[ List of capes; Format: {{Name = "somecape",Material = "Fabric",Color = "Bright yellow",ID = 12345567,Reflectance = 1},{etc more stuff here}} ]]
descs.InsertList = [[ List of models to appear in the script; Format: {{Name = "somemodel",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
descs.MaxLogs = [[ Maximum logs to save before deleting the oldest; Too high can lag the game ]]
descs.MusicList = [[ List of songs to appear in the script; Format: {{Name = "somesong",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]]
descs.Messages = [[ A list of notification messages to show HeadAdmins and above on join ]]
descs.SaveCommandLogs = [[ If command logs are saved to the datastores ]]

descs.AutoBackup = [[ (not recommended) Run a map backup command when the server starts, this is mostly useless as clients cannot modify the server. To restore the map run :restoremap ]]
descs.AutoClean = [[ Will auto clean workspace of things like hats and tools ]]
descs.AutoCleanDelay = [[ Time between auto cleans ]]
descs.SongHint = [[ Display a hint with the current song name and ID when a song is played via :music ]]
descs.TopBarShift = [[ By default hints and notifs will appear from the top edge of the window, this is acheived by offsetting them by -35 into the transparent region where roblox buttons menu/chat/leaderstat buttons are. Set this to true if you don't want hints/notifs to appear in that region. ]]

descs.HttpWait = [[ How long things that use the HttpService will wait before updating again ]]
descs.Trello_Enabled = [[ Are the Trello features enabled? ]]
descs.Trello_Primary = [[ Primary Trello board ]]
descs.Trello_Secondary = [[ Secondary Trello boards; Format: {"BoardID";"BoardID2","etc"} ]]
descs.Trello_AppKey = [[ Your Trello AppKey; Link: https://trello.com/app-key ]]
descs.Trello_Token = [[ Trello token (DON'T SHARE WITH ANYONE!); Link: https://trello.com/1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE ]]
descs.Trello_HideRanks = [[ If true, Trello-assigned ranks won't be shown in the admins list UI (accessed via :admins) ]]

descs.Allowed_API_Calls = [[ Allowed calls ]]
descs.G_API = [[ If true allows other server scripts to access certain functions described in the API module through _G.Adonis ]]
descs.G_Access = [[ If enabled allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player) ]]
descs.G_Access_Key = [[ Key required to use the _G access API; Example_Key will not work for obvious reasons ]]
descs.G_Access_Perms = [[ Access perms level ]]

descs.AntiBuildingTools = [[ (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client ]]
descs.AntiClientIdle = [[ (Client-Sided) Kick the player if they are using an anti-idle exploit ]]
descs.AntiHumanoidDeletion = [[ (Very important) Prevents invalid humanoid deletion. Un-does the deletion and kills the player ]]
descs.AntiGod = [[ If a player does not respawn when they should have they get respawned ]]
descs.AntiMultiTool = [[ Prevents multitooling and because of that many other exploits ]]
descs.AntiNoclip = [[ Attempts to detect noclipping and kills the player if found ]]
descs.AntiRootJointDeletion = [[ Attempts to detect paranoid and kills the player if found ]]
descs.AntiSpeed = [[ (Client-Sided) Attempts to detect speed exploits ]]
descs.CharacterCheckLogs = [[If the character checks appear in exploit logs and exploit notifications]]
descs.CheckClients = [[ Checks clients every minute or two to make sure they are still active ]]
descs.Detection = [[ Attempts to detect certain known exploits ]]
descs.ExploitNotifications = [[ Notify all moderators and higher ups when a player is kicked or crashed from the AntiExploit ]]
descs.ProtectHats = [[ Prevents hats from being un-welded from their characters through unnormal means. ]]

descs.Commands = [[ Custom commands ]]

local order = {
	"DataStore";
	"DataStoreEnabled";
	"DataStoreKey";
	"HideScript";
	"LocalDatastore";
	" ";
	"Theme";
	"DefaultTheme";
	"MobileTheme";
	" ";
	"RecursiveTools";
	"Storage";
	" ";
	"Banned";
	"BanMessage";
	"Blacklist";
	"CreatorPowers";
	"HelpSystem";
	"HelpButton";
	"HelpButtonImage";
	"LoadAdminsFromDS";
	"LockMessage";
	"Muted";
	"Notification";
	"OverrideChatCallbacks";
	"Ranks";
	"SaveAdmins";
	"SystemTitle";
	"Whitelist";
	"WhitelistEnabled";
	" ";
	"Prefix";
	"PlayerPrefix";
	"SpecialPrefix";
	"SplitKey";
	"BatchKey";
	"Aliases";
	"ChatCommands";
	"CodeExecution";
	"CommandCooldowns";
	"CommandFeedback";
	"Console";
	"Console_AdminsOnly";
	"ConsoleKeycode";
	"CrossServerCommands";
	"DonorCapes";
	"DonorCommands";
	"FunCommands";
	"LocalCapes";
	"OnJoin";
	"OnStartup";
	"OnSpawn";
	"Permissions";
	"PlayerCommands";
	"SilentCommandDenials";
	" ";
	"CapeList";
	"InsertList";
	"MaxLogs";
	"MusicList";
	"Messages";
	"SaveCommandLogs";
	" ";
	"AutoBackup";
	"AutoClean";
	"AutoCleanDelay";
	"SongHint";
	"TopBarShift";
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
	"AntiBuildingTools";
	"AntiClientIlde";
	"AntiHumanoidDeletion";
	"AntiGod";
	"AntiMultiTool";
	"AntiNoclip";
	"AntiRootJointDeletion";
	"AntiSpeed";
	"CharacterCheckLogs";
	"CheckClients";
	"Detection";
	"ExploitNotifications";
	"ProtectedHats";
	"";
	"Commands"
}

return {Settings = settings, Descriptions = descs, Order = order}
