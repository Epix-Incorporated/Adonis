return function(Vargs)
    local settings = Vargs.Server.Settings
    local service = Vargs.Service
    local Core = Vargs.Server.Core
    local Admin = Vargs.Server.Admin
    local Remote = Vargs.Server.Remote
    local Logs = Vargs.Server.Logs
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

    Logs.AddLog("Errors",{
        Text = `ADONIS CRITICAL INCIDENT`;
        Desc = "Adonis MainModule has failed to load. Resorted to backup.";
    })

    Logs.AddLog("Script",{
        Text = `ADONIS CRITICAL INCIDENT`;
        Desc = "Adonis MainModule has failed to load. Resorted to backup.";
    })

    local function onPlayerAdded(p: Player)
        local data = Core.GetPlayer(p);
        if Admin.GetLevel(p) > 0 then
            Remote.MakeGui(p,"Notification",{
				Title = "Adonis Restricted Mode";
				Message = "Click to view more information.";
				Icon = "rbxassetid://7467273592";
				Time = 900;
				OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand',':aciminfo')");
           })
        end
    end

    service.Events.PlayerAdded:Connect(onPlayerAdded)
    
end