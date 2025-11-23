local SETTINGS_OVERRIDE = { -- Why do these need to be overriden in the first place.
	Theme = "Default"; -- Should the settings override be removed?? I think so, but I'll leave it for now.
	MobileTheme = "Default";
	DefaultTheme = "Default";
	SaveAdmins = false;
	FunCommands = false;
	PlayerCommands = true;
	CommandFeedback = true;
	CrossServerCommands = false;
	ChatCommands = true;
	CodeExecution = false;
	SilentCommandDenials = false;
	Console = false;
	Console_AdminsOnly = false;
	HelpSystem = false;
	HelpButton = false;
	DonorCapes = false;
	DonorCommands = false;
	LocalCapes = false;
	Detection = false;
	CheckClients = false;
	ExploitNotifications = false;
	CharacterCheckLogs = false;
	AntiNoclip = false;
	AntiRootJointDeletion = false;
	AntiMultiTool = false;
	AntiGod = false;
	AntiSpeed = false;
	AntiBuildingTools = false;
	AntiAntiIdle = false;
	ExploitGuiDetection = false;
	Notification = false;
	G_API = false;
	G_Access = false;
}

local ACMI_HEADER = {
	"";
	"ADONIS CRITICAL INCIDENT";
	"";
	"Adonis is currently running in restricted mode.";
	"Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality.";
	"A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.";
	"Scroll down for a list of functionality losses.";
	"";
	"We are working hard to resolve the issue and normal operations will hopefully resume soon.";
	"See our offical group for more information.";
	"";
	"https://www.roblox.com/groups/886423/Epix-Incorporated";
	"";
	"Adonis functionality changes:";
}

local ACMI_FOOTER = {
	"";
    "Core";
    "";
    "Server Plugins         <font color = 'rgb(0,255,0)'>[Services remain operational.]</font>";
    "Client Plugins         <font color = 'rgb(0,255,0)'>[Services remain operational.]</font>";
    "";
    "AntiExploit            <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "(SERVER)AntiCheat      <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "(CLIENT)AntiCheat      <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "HelpSystem             <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "WebPanel               <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "CrossServer Functions  <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "_G Services            <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
    "TrelloAPI              <font color = 'rgb(0,255,0)'>[Services remain operational.]</font>";
    "DataStore              <font color = 'rgb(0,255,0)'>[Services remain operational.]</font>";
    "";
    "Client:";
    "";
    "UI Themes              <font color = 'rgb(255,0,0)'>[Loss of services.]</font>";
}

local AVAILABLE_COMMAND_MODULES = { "Donors", "Fun", "Players", "Moderators", "Admins", "HeadAdmins", "Creators" }

return function(Vargs)
	local service = Vargs.Service
	local server = Vargs.Server
	local Settings = server.Settings

	if not server.Variables then
		server.Variables = { _isBackupByCriticalPlugin = true }
	end

	local Core = server.Core
	local Admin = server.Admin
	local Remote = server.Remote
	local Logs = server.Logs
	local Variables = server.Variables
	local Functions = server.Functions

	if not server.CriticalMode then -- Only run this code if server flips flag. This should *only* be on for the fallback module!
		return
	end

	local function createPaddingForList(list)
		local maxSize = 0

		for i, v in ipairs(list) do
			if type(v) == "table" then
				if string.len(v[1]) > maxSize then
					maxSize = v[1]
				end
			end
		end

		for i, v in ipairs(list) do
			if type(v) == "table" then
				v[2] = string.rep(" ", maxSize - string.len(v[1]))
				list[i] = table.concat(v, " ")
			end
		end
	end

	local function getFormattedStatus(name, status)
		return `<font color = 'rgb({status ~= true and 255 or 0}, {status == true and 255 or status == false and 0 or 162}, {0})'>[{name}]</font>`
	end

	local function getCommandStatusData()
		local list = table.create(#AVAILABLE_COMMAND_MODULES)
		list[1], list[2], list[3] = "", "Commands:", ""

		for i, v in ipairs(AVAILABLE_COMMAND_MODULES) do
			if not server.CommandModules or not server.CommandModules:FindFirstChild(v) or not pcall(require, server.CommandModules[v]) then
				table.insert(list, {v, "", getFormattedStatus("Loss of services.", false)})
			else
				table.insert(list, {v, "", getFormattedStatus("Temporary loss of services. Essential commands remain.", "warn")})
			end
		end
	end

	local function genOverrideListData()
		local list = table.create(#SETTINGS_OVERRIDE)
		list[1], list[2], list[3] = "", "Settings:", ""

		if not Settings then
			table.insert(list, {"All setting data", "", getFormattedStatus("Loss of services.", false)})
		else
			for _, v in ipairs(SETTINGS_OVERRIDE) do
				table.insert(list, {v, "", getFormattedStatus(type(v) ~= "boolean" and "Has been forced to 'Default'." or v and "Has been forced enabled." or "Has been forced disabled.", type(v) ~= "boolean" and "warn" or v)})
			end
		end
	end

	local function getServiceStatusData()
		local list = table.clone(Variables.ACMI_HEADER)

		table.move(getCommandStatusData(), 1, #AVAILABLE_COMMAND_MODULES + 3, #list + 1, list)
		table.move(genOverrideListData(), 1, #SETTINGS_OVERRIDE + 3, #list + 1, list)
		table.move(table.clone(Variables.ACMI_FOOTER), 1, #Variables.ACMI_FOOTER, #list + 1, list) -- TODO: Make this check status dynamically as well
		Variables.CachedACMI = list

		return list
	end

	local function onPlayerAdded(p: Player)
		local data = Core.GetPlayer(p)

		if Admin.GetLevel(p) > 0 then
			Functions.Notification(
				"Adonis Restricted Mode",
				"Click to view more information.",
				{p},
				900,
				"rbxassetid://7467273592",
				Core.Bytecode("client.Remote.Send('ProcessCommand', ':aciminfo')")
		   )
		end
	end

	if server.Panic then
		server.Panic("ADONIS WAS STARTED IN CRITICAL MODE!")
	end

	if Logs and Logs.AddLog then
		Logs.AddLog("Errors", {
			Text = "ADONIS CRITICAL INCIDENT";
			Desc = "Adonis MainModule has failed to load. Resorted to backup.";
		})

		Logs.AddLog("Script", {
			Text = "ADONIS CRITICAL INCIDENT";
			Desc = "Adonis MainModule has failed to load. Resorted to backup.";
		})
	end

	if Settings then
		for k, v in SETTINGS_OVERRIDE do
			Settings[k] = v
		end
	end

	Variables.ACMI_HEADER, Variables.ACMI_FOOTER = ACMI_HEADER, ACMI_FOOTER
	server.Commands.ACIMInfo = {
		Prefix = Settings.Prefix;
		Commands = {"ACIMInfo"};
		Args = {};
		Description = "Show a list of functionality loss.";
		AdminLevel = 0;
		Hidden = false;
		Function = function(plr: Player, args: {string}, data)
			Remote.MakeGui(plr, "List", {
				Title = "Adonis Critical Incident",
				Icon = "rbxassetid://7467273592",
				Table = Variables.CachedACMI or getServiceStatusData(),
				Font = "Code",
				PageSize = 100;
				Size = {750, 400},
				PagesEnabled = false;
				Dots = true;
				Sanitize = false;
				Stacking = true;
				RichText = true;
			})
		end
	};

	service.Events.PlayerAdded:Connect(onPlayerAdded) -- TODO: Check if already in players this fires for, if not then add a getplayers for loop
end
