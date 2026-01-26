-- The description of each in-game settings editor setting.

------------------------------------------------
-- DESCRIPTIONS INGAMESETTINGSEDITOR SETTINGS --
------------------------------------------------

return {
	HideScript = [[ Disable if your game saves; When the game starts the Adonis_Loader model will be hidden so other scripts cannot access the settings module ]];
	DataStore = [[ DataStore the script will use for saving data; Changing this will lose any saved data ]];
	DataStoreKey = [[ Key used to encode all datastore entries; Changing this will lose any saved data ]];
	DataStoreEnabled = [[ Disable if you don't want settings and admins to be saveable in-game; PlayerData will still save ]];
	LocalDatastore = [[ If this is turned on, a mock DataStore will forcibly be used instead and shall never save across servers ]];

	Storage = [[ Where things like tools are stored ]];
	RecursiveTools = [[ Whether tools that are included in sub-containers within settings.Storage will be available via the :give command (useful if your tools are organized into multiple folders) ]];

	Theme = [[ UI theme; ]];
	MobileTheme = [[ Theme to use on mobile devices; Mobile themes are optimized for smaller screens; Some GUIs are disabled ]];

	Ranks = [[ All admin permission level ranks; ]];
	Moderators = [[ Mods; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	Admins = [[ Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	HeadAdmins = [[ Head Admins; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	Creators = [[ Anyone to be identified as a place owner; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];

	Permissions = [[ Command permissions; Format: {"Command:NewLevel";} ]];
	Aliases = [[ Command aliases; Format: {[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."} ]];
	Cameras = [[ Cameras; Format: {Name = "CamName", Position = Vector3.new(X, Y, Z)} ]];

	Commands = [[ Custom commands ]];
	Banned = [[ List of people banned from the game; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	Muted = [[ List of people muted; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	Blacklist = [[ List of people banned from using admin; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";}	]];
	Whitelist = [[ People who can join if whitelist enabled; Format: {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";} ]];
	MusicList = [[ List of songs to appear in the script; Format: {{Name = "somesong",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]];
	CapeList = [[ List of capes; Format: {{Name = "somecape",Material = "Fabric",Color = "Bright yellow",ID = 12345567,Reflectance = 1},{etc more stuff here}} ]];
	InsertList = [[ List of models to appear in the script; Format: {{Name = "somemodel",ID = 1234567},{Name = "anotherone",ID = 1243562}} ]];
	Waypoints = [[ List of waypoints you can teleport via ':to wp-WAYPOINTNAME' or ':teleport PLAYER tp.WAYPOINTNAME' Format {YOURNAME1 = Vector3.new(1,2,3), YOURNAME2 = Vector(231,666,999)} ]];
	CustomRanks = [[ List of custom AdminLevel ranks			  Format: {RankName = {"Username"; "Username:UserId"; UserId; "Group:GroupId:GroupRank"; "Group:GroupId"; "Item:ItemID";};} ]];

	OnStartup = [[ List of commands ran at server start								Format: {":notif TestNotif"} ]];
	OnJoin = [[ List of commands ran as player on join (ignores adminlevel)		Format: {":cmds"} ]];
	OnSpawn = [[ List off commands ran as player on spawn (ignores adminlevel)	Format: {"!fire Really red",":ff me"} ]];

	SaveAdmins = [[ If true anyone you :mod, :admin, or :headadmin in-game will save]];
	LoadAdminsFromDS = [[ If false, any admins saved in your DataStores will not load ]];
	WhitelistEnabled = [[ If true enables the whitelist/server lock; Only lets admins & whitelisted users join ]];

	Prefix = [[ The : in :kill me ]];
	PlayerPrefix = [[ The ! in !donate; Mainly used for commands that any player can run ]];
	SpecialPrefix = [[ Used for things like "all", "me" and "others" (If changed to ! you would do :kill !me) ]];
	SplitKey = [[ The space in ;kill me (eg if you change it to / :kill me would be :kill/me) ]];
	BatchKey = [[ :kill me | :ff bob | :explode scel ]];
	ConsoleKeyCode = [[ Keybind to open the console ]];

	HttpWait = [[ How long things that use the HttpService will wait before updating again ]];
	Trello_Enabled = [[ Are the Trello features enabled? ]];
	Trello_Primary = [[ Primary Trello board ]];
	Trello_Secondary = [[ Secondary Trello boards; Format: {"BoardID";"BoardID2","etc"} ]];
	Trello_AppKey = [[ Your Trello AppKey; ]];
	Trello_Token = [[ Trello token (DON'T SHARE WITH ANYONE!) ]];
	Trello_HideRanks = [[ If true, Trello-assigned ranks won't be shown in the admins list UI (accessed via :admins) ]];

	G_API = [[ If true, allows other server scripts to access certain functions described in the API module through _G.Adonis ]];
	G_Access = [[ If enabled, allows other scripts to access Adonis using _G.Adonis.Access; Scripts will still be able to do things like _G.Adonis.CheckAdmin(player) ]];
	G_Access_Key = [[ Key required to use the _G access API; Example_Key will not work for obvious reasons ]];
	G_Access_Perms = [[ Access perms level ]];
	Allowed_API_Calls = [[ Allowed calls ]];

	FunCommands = [[ Are fun commands enabled? ]];
	PlayerCommands = [[ Are players commands enabled? ]];
	AgeRestrictedCommands = [[ Are age-restricted commands enabled? ]];
	WarnDangerousCommand = [[ Do dangerous commands ask for confirmation before executing?]];
	CommandFeedback = [[ Should players be notified when commands with non-obvious effects are run on them? ]];
	CrossServerCommands = [[ Are commands which affect more than one server enabled? ]];
	ChatCommands = [[ If false you will not be able to run commands via the chat; Instead, you MUST use the console or you will be unable to run commands ]];
	SilentCommandDenials = [[ If true, there will be no differences between the error messages shown when a user enters an invalid command and when they have insufficient permissions for the command ]];
	OverrideChatCallbacks = [[ If the TextChatService ShouldDeliverCallbacks of all channels are overridden by Adonis on load. Required for muting ]];

	BanMessage = [[ Message shown to banned users ]];
	LockMessage = [[ Message shown to people when they are kicked while the game is :slocked ]];
	SystemTitle = [[ Title to display in :sm ]];

	MaxLogs = [[ Maximum logs to save before deleting the oldest; Too high can lag the game ]];
	SaveCommandLogs = [[ If command logs are saved to the datastores ]];
	Notification = [[ Whether or not to show the "You're an admin" and "Updated" notifications ]];
	CodeExecution = [[ Enables the use of code execution in Adonis; Scripting related and a few other commands require this ]];
	SongHint = [[ Display a hint with the current song name and ID when a song is played via :music ]];
	TopBarShift = [[ By default hints and notifs will appear from the top edge of the window. Set this to true if you don't want hints/notifications to appear in that region. ]];
	DefaultTheme = [[ Theme to be used as a replacement for "Default". The new replacement theme can still use "Default" as its Base_Theme however any other theme that references "Default" as its redirects to this theme. ]];
	ReJail = [[ If true then when a player rejoins they'll go back into jail. Or if the moderator leaves everybody gets unjailed ]];

	Messages = [[ A list of notifications shown on join. Messages can either be strings or tables. Messages are shown to HeadAdmins+ by default but tables can define a different minimum level via .Level ]];

	AutoClean = [[ Will auto clean workspace of things like hats and tools ]];
	AutoBackup = [[ (not recommended) Run a map backup command when the server starts, this is mostly useless as clients cannot modify the server. To restore the map run :restoremap ]];
	AutoCleanDelay = [[ Time between auto cleans ]]
;
	PlayerList = [[ Custom playerlist ]];

	Console = [[ Command console ]];
	Console_AdminsOnly = [[ Makes it so if the console is enabled, only admins will see it ]];

	DonorCommands = [[ Show your support for the script and let donors use commands like !sparkles ]];
	DonorCapes = [[ Determines if donors have capes ]];
	LocalCapes = [[ Makes Donor capes local instead of removing them ]];

	HelpSystem = [[ Allows players to call admins for help using !help ]];
	HelpButton = [[ Shows a little help button in the bottom right corner ]];
	HelpButtonImage = [[ Change this to change the help button's image ]];

	AllowClientAntiExploit = [[ Enables client-sided anti-exploit functionality ]];
	Detection = [[ (Extremely important, makes all protection systems work) A global toggle for all the other protection settings ]];
	CheckClients = [[ (Important, makes sure Adonis clients are connected to the server) Checks clients every minute or two to make sure they are still active ]];

	ExploitNotifications = [[ Notify all moderators and higher-ups when a player is kicked or crashed from the AntiExploit ]];
	CharacterCheckLogs = [[If the character checks appear in exploit logs and exploit notifications]];
	AntiNoclip = [[ Attempts to detect noclipping and kills the player if found ]];
	AntiRootJointDeletion = [[ Attempts to detect paranoid and kills the player if found ]];
	AntiMultiTool = [[ Prevents multitool and because of that many other exploits ]];
	AntiGod = [[ If a player does not respawn when they should have they get respawned ]];

	AntiSpeed = [[ (Client-Sided) Attempts to detect speed exploits ]];
	AntiBuildingTools = [[ (Client-Sided) Attempts to detect any HopperBin(s)/Building Tools added to the client ]];
	AntiAntiIdle = [[ (Client-Sided) Kick the player if they are using an anti-idle exploit. Highly useful for grinding/farming games ]];
};