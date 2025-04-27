return function(Vargs)
    local service = Vargs.Service
    local server = Vargs.Server
    local settings = server.Settings

    local Core = server.Core
    local Admin = server.Admin
    local Remote = server.Remote
    local Logs = server.Logs

	if server.CriticalMode or Core.DebugMode and Core.PanicMode then
	end

    local function onPlayerAdded(p: Player)
        local data = Core.GetPlayer(p)

        if Admin.GetLevel(p) > 0 then
            Remote.MakeGui(p,"Notification",{
				Title = "Adonis Restricted Mode";
				Message = "Click to view more information.";
				Icon = "rbxassetid://7467273592";
				Time = 900;
				OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand', ':aciminfo')");
           })
        end
    end

    settings.Theme = "Default"
    settings.MobileTheme = "Default"
    settings.DefaultTheme = "Default"
    settings.SaveAdmins = false
    settings.FunCommands = false
    settings.PlayerCommands = true
    settings.CommandFeedback = true
    settings.CrossServerCommands = false
    settings.ChatCommands = true
    settings.CodeExecution = false
    settings.SilentCommandDenials = false
    settings.Console = false
    settings.Console_AdminsOnly = false
    settings.HelpSystem = false
    settings.HelpButton = false
    settings.DonorCapes = false
    settings.DonorCommands = false
    settings.LocalCapes = false
    settings.Detection = false
    settings.CheckClients = false
    settings.ExploitNotifications = false
    settings.CharacterCheckLogs = false
    settings.AntiNoclip = false
    settings.AntiRootJointDeletion = false
    settings.AntiMultiTool = false
    settings.AntiGod = false
    settings.AntiSpeed = false
    settings.AntiBuildingTools = false
    settings.AntiAntiIdle = false
    settings.ExploitGuiDetection = false
    settings.Notification = false
    settings.G_API = false
    settings.G_Access = false

    Logs.AddLog("Errors", {
        Text = `ADONIS CRITICAL INCIDENT`;
        Desc = "Adonis MainModule has failed to load. Resorted to backup.";
    })

    Logs.AddLog("Script", {
        Text = `ADONIS CRITICAL INCIDENT`;
        Desc = "Adonis MainModule has failed to load. Resorted to backup.";
    })

	if Core.Panic then -- TODO: Maybe re-add panic mode?!?!? Lol
		Core.Panic("ADONIS WAS STARTED IN CRITICAL MODE!")
	end

	ACIMInfo = {
		Prefix = Settings.Prefix;
		Commands = {"ACIMInfo"};
		Args = {};
		Description = "Show a list of functionality loss.";
		AdminLevel = 1;
		Hidden = false;
		Function = function(plr: Player, args: {string}, data)
			Remote.MakeGui(plr, "List", {
				Title = "Adonis Critical Incident",
				Icon = "rbxassetid://7467273592",
				Table = require(server.Dependencies.ACIMInfo),
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

    service.Events.PlayerAdded:Connect(onPlayerAdded)
end
