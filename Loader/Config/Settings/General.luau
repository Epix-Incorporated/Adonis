----------------------
-- GENERAL SETTINGS --
----------------------

return {
	Prefix = {":", ";"};		-- A list of prefixes for commands, the : in :kill me
	PlayerPrefix = "!";			-- The ! in !donate; Mainly used for commands that any player can run; Do not make it the same as Prefix
	SpecialPrefix = "";			-- Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me)
	SplitKey = " ";				-- The space in :kill me (eg if you change it to / :kill me would be :kill/me)
	BatchKey = "|";				-- :kill me | :ff bob | :explode scel
	ConsoleKeyCode = "Quote";	-- Keybind to open the console; Rebindable per player in userpanel; KeyCodes: https://developer.roblox.com/en-us/api-reference/enum/KeyCode

	HideScript = true;	-- When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module; Disable if your game uses AssetService:SavePlaceAsync()

	DataStoreEnabled = true;		-- Disable if you don't want to load settings and admins from the datastore; PlayerData will still save
	LocalDatastore = false;			-- If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers
	DataStore = "Adonis_1";			-- DataStore the script will use for saving data; Changing this will lose any saved data
	DataStoreKey = "CHANGE_THIS";	-- CHANGE THIS TO ANYTHING RANDOM! Key used to encrypt all datastore entries; Changing this will lose any saved data

	SaveAdmins = true;			-- If true anyone you :admin or :headadmin in-game will save
	LoadAdminsFromDS = true;	-- If false, any admins saved in your DataStores will not load

	SaveCommandLogs = true;	-- If command logs are saved to the datastores
	MaxLogs = 5000;			-- Maximum logs to save before deleting the oldest

	Storage = game:GetService("ServerStorage");	-- Where things like tools are stored
	RecursiveTools = false;	-- Whether tools that are included in sub-containers within Storage will be available via the :give command (useful if your tools are organized into multiple folders)

	Theme = "Default";			-- UI theme
	MobileTheme = "Mobilius";	-- Theme to use on mobile devices; Some UI elements are disabled
	DefaultTheme = "Default";	-- Theme to be used as a replacement for "Default". The new replacement theme can still use "Default" as its Base_Theme however any other theme that references "Default" as its redirects to this theme.
	HiddenThemes = {};			-- Hide themes from the theme selector tab inside the userpanel. Each theme name must be the specific name such as "Mobilius"

	BanMessage = "Banned";				-- Message shown to banned users upon kick
	LockMessage = "Not Whitelisted";	-- Message shown to people when they are kicked while :slock is on in the server
	SystemTitle = "System Message";		-- Title to display in :sm and :bc

	--[[
		Format example for Banned, Muted, Blacklist and Whitelist:

		Banned, Muted, Blacklist or Whitelist = {
			"Username"; -- Example: "roblox"
			"Username:UserId"; -- Example: "roblox:1"
			UserId; -- Example: 1
			"Group:GroupId:GroupRank"; -- Example: "Group:123456:50"
			"Group:GroupId"; -- Example: "Group:123456"
			"Item:ItemID"; -- Example: "Item:123456"
			"GamePass:GamePassID"; -- Example: "GamePass:123456"
			"Subscription:SubscriptionId"; -- Example: "Subscription:123456"
		}
	--]]

	Banned = {};		-- List of people banned from the game		Format: See the above format example
	Muted = {};			-- List of people muted (cannot send chat messages)		Format: See the above format example
	Blacklist = {};		-- List of people banned from running commands		Format: See the above format example
	Whitelist = {};		-- People who can join if whitelist enabled		Format: See the above format example

	WhitelistEnabled = false; -- If true enables the whitelist/server lock; Only lets admins & whitelisted users join

	MusicList = {}; 	-- List of songs to appear in the :musiclist		Format: {{Name = "somesong", ID = 1234567}, {Name = "anotherone", ID = 1243562}}
	CapeList = {};		-- List of capes		Format: {{Name = "somecape", Material = "Fabric", Color = "Bright yellow", ID = 12345567, Reflectance = 1}; {etc more stuff here}}
	InsertList = {}; 	-- List of models to appear in the :insertlist and can be inserted using ':insert <name>'		Format: {{Name = "somemodel", ID = 1234567}; {Name = "anotherone", ID = 1243562}}

	OnStartup = {};		-- List of commands ran at server start		Format: {":notif TestNotif"}
	OnJoin = {};		-- List of commands ran as player on join (ignores adminlevel)		Format: {":cmds"}
	OnSpawn = {};		-- List of commands ran as player on spawn (ignores adminlevel)		Format: {"!fire Really red",":ff me"}

	FunCommands = true;					-- Are fun commands enabled?
	PlayerCommands = true;				-- Are player-level utility commands enabled?
	AgeRestrictedCommands = true;		-- Are age restricted commands enabled?
	ChatCommands = true;				-- If false you will not be able to run commands via the chat; Instead, you MUST use the console or you will be unable to run commands
	CrossServerCommands = true;			-- Are commands which affect more than one server enabled?
	WarnDangerousCommand = false;		-- Do dangerous commands ask for confirmation?
	CommandFeedback = false;			-- Should players be notified when commands with non-obvious effects are run on them?
	SilentCommandDenials = false;		-- If true, there will be no differences between the error messages shown when a user enters an invalid command and when they have insufficient permissions for the command
	OverrideChatCallbacks = true;		-- If the TextChatService ShouldDeliverCallbacks of all channels are overridden by Adonis on load. Required for slowmode. Mutes use a CanSend method to mute when this is set to false.
	ChatCreateRobloxCommands = false;	-- Whether "/" commands for Roblox should get created in new Chat

	CodeExecution = false;	-- Enables the use of code execution in Adonis. Scripting related (such as :s) and a few other commands require this

	Notification = true;	-- Whether or not to show the "You're an admin" and "Updated" notifications
	SongHint = true;		-- Display a hint with the current song name and ID when a song is played via :music
	TopBarShift = false;	-- By default hints and notifications will appear from the top edge of the window. Set this to true if you don't want hints/notifications to appear in that region.

	AutoClean = false;		-- Will auto clean workspace of things like hats and tools
	AutoCleanDelay = 60;	-- Time between auto cleans
	AutoBackup = false;		-- Run :backupmap automatically when the server starts. To restore the map, run :restoremap
	ReJail = false;			-- If true then when a player rejoins they'll go back into jail. Or if the moderator leaves everybody gets unjailed

	Console = true;				-- Whether the command console is enabled
	Console_AdminsOnly = false; -- If true, only admins will be able to access the console

	HelpSystem = true;	-- Allows players to call admins for help using !help
	HelpButton = true;	-- Shows a little help button in the bottom right corner.
	HelpButtonImage = "rbxassetid://357249130";	-- Sets the image used for the Adonis help button above.

	HttpWait = 60;	-- How long things that use the HttpService will wait before updating again
};