local settings = {
	DataStore = "Adonis_1";
	DataStoreEnabled = true;
	DataStoreKey = "CHANGE_THIS";
	HideScript = true;
	LocalDatastore = false;
	Theme = "Default";
	DefaultTheme = "Default";
	MobileTheme = "Mobilius";
	RecursiveTools = false;
	Storage = game:GetService("ServerStorage");
	Banned = {};
	BanMessage = "Banned";
	Blacklist = {};
	CreatorPowers = true;
	HelpSystem = true;
	HelpButton = true;
	HelpButtonImage = "rbxassetid://357249130";
	LoadAdminsFromDS = true;
	LockMessage = "Not Whitelisted";
	Muted = {};
	Notification = true;
	OverrideChatCallbacks = true;
	Ranks = {
		["Moderators"] = {
			Level = 100;
			Hidden = false;
			Users = {}
		};

		["Admins"] = {
			Level = 200;
			Hidden = false;
			Users = {}
		};

		["HeadAdmins"] = {
			Level = 300;
			Hidden = false;
			Users = {}
		};

		["Creators"] = {
			Level = 900;
			Hidden = false;
			Users = {}
		}

	};
	SaveAdmins = true;
	SystemTitle = "System Message";
	Whitelist = {};
	WhitelistEnabled = false;
	Prefix = ":";
	PlayerPrefix = "!";
	SpecialPrefix = "";
	SplitKey = " ";
	Aliases = {};
	ChatCommands = true;
	CodeExecution = true;
	CommandCooldowns = {};
	CommandFeedback = false;
	Console = true;
	Console_AdminsOnly = false;
	ConsoleKeycode = "Quote";
	CrossServerCommands = true;
	DonorCapes = true;
	DonorCommands = true;
	FunCommands = true;
	LocalCapes = false;
	OnJoin = {};
	OnStartup = {};
	OnSpawn = {};
	Permission = {};
	PlayerCommands = true;
	SilentCommandDenials = false;
	CapeList = {};
	InsertList = {};
	MaxLogs = 5000;
	MusicList = {};
	Messages = {};
	SaveCommandLogs = true;
	AutoBackup = false;
	AutoClean = false;
	AutoCleanDelay = 60;
	SongHing = true;
	TopBarShift = false;
	HttpsWait = 60;
	Trello_Enabled = false;
	Trello_Primary = "";
	Trello_Secondary = {};
	Trello_AppKey = "";
	Trello_Token = "";
	Trello_HideRanks = false;
	Allowed_API_Calls = {
		Client = false;
		Settings = false;
		DataStore = false;
		Core = false;
		Service = false;
		Remote = false;
		HTTP = false;
		Anti = false;
		Logs = false;
		UI = false;
		Admin = false;
		Functions = false;
		Variables = true;
		API_Specific = true;
	};
G_API = true;
	G_Access = false;
	G_Access_Key = "";
	G_Access_Perms = "Read";
	AntiBuildingTools = false;
	AntiClientIdle = false;
	AntiHumanoidDeletion = false;
	AntiGod = false;
	AntiMultiTool = false;
	AntiNoclip = false;
	AntiRootJointDeletion = false;
	AntiSpeed = true;
	CharacterCheckLogs = false;
	CheckClients = true;
	Detection = true;
	ExploitNotifications = true;
	ProtectedHats = false;
}
local Settings = settings;
settings.Commands = {
	ExampleCommand1 = {
		Prefix = Settings.Prefix;
		Commands = {"examplecommand1", "examplealias1", "examplealias2"};
		Args = {"arg1", "arg2", "etc"};
		Description = "Example command";
		AdminLevel = 100;
		Filter = true;
		Hidden = true;
		Disabled = true;
		Function = function(plr: Player, args: {string}, data)
			print("This is 'arg1':", tostring(args[1]))
			print("This is 'arg2':", tostring(args[2]))
			print("This is 'etc'(arg 3):", tostring(args[3]))
			error("this is an example error :O !")
		end
	};
}
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
