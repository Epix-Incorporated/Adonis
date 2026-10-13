--!nocheck
return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	local Routine = env.Routine

	return {
		SetRank = {
			Prefix = Settings.Prefix;
			Commands = {"setrank", "permrank", "permsetrank"};
			Args = {"player/user", "rank"};
			Description = "Sets the admin rank of the target user(s); THIS SAVES!";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				assert(args[1], "Missing target user (argument #1)")
				local rankName = assert(args[2], "Missing rank name (argument #2)")

				local newRank = Settings.Ranks[rankName]
				if not newRank then
					for thisRankName, thisRank in Settings.Ranks do
						if thisRankName:lower() == rankName:lower() then
							rankName = thisRankName
							newRank = thisRank
							break
						end
					end
				end
				assert(newRank, `No rank named '{rankName}' exists`)

				local newLevel = newRank.Level
				local senderLevel = data.PlayerData.Level

				assert(newLevel < senderLevel, string.format("Rank level (%s) cannot be equal to or above your own level (%s)", newLevel, senderLevel))
				local v = Functions.GetPlayers(plr, args[1], {UseFakePlayer = true})
				for _, p in v do
					if senderLevel > Admin.GetLevel(p) then
						Admin.AddAdmin(p, rankName)
						Functions.LogAdminAction(plr, "Set Rank", p.Name, `New rank: {rankName}, New level: {newLevel}`)
						Functions.Notification(
							"Notification",
							`You are {if string.lower(string.sub(rankName, 1, 3)) == "the" then "" elseif string.match(rankName, "^[AEIOUaeiou]") and string.lower(string.sub(rankName, 1, 3)) ~= "uni" then "an " else "a "}{rankName}. Click to view commands.`,
							{p}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`)
						)
						Functions.Hint(`{service.FormatPlayer(p, true)} is now rank {rankName} (Permission Level: {newLevel})`, {plr})
					else
						Functions.Hint(`You do not have permission to set the rank of {service.FormatPlayer(p, true)}`, {plr})
					end
				end
			end;
		};

		SetTempRank = {
			Prefix = Settings.Prefix;
			Commands = {"settemprank", "temprank", "tempsetrank"};
			Args = {"player", "rank"};
			Description = `Identical to {Settings.Prefix}setrank, but doesn't save`;
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				assert(args[1], "Missing target player (argument #1)")
				local rankName = assert(args[2], "Missing rank name (argument #2)")

				local newRank = Settings.Ranks[rankName]
				if not newRank then
					for thisRankName, thisRank in Settings.Ranks do
						if thisRankName:lower() == rankName:lower() then
							rankName = thisRankName
							newRank = thisRank
							break
						end
					end
				end
				assert(newRank, `No rank named '{rankName}' exists`)

				local newLevel = newRank.Level
				local senderLevel = data.PlayerData.Level

				assert(newLevel < senderLevel, string.format("Rank level (%s) cannot be equal to or above your own level (%s)", newLevel, senderLevel))

				for _, v in service.GetPlayers(plr, args[1]) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, rankName, true)
						Functions.LogAdminAction(plr, "Set Temporary Rank", v.Name, `Temporary rank set to: {rankName}`)
						Functions.Notification("Notification", `You are a temp {rankName}. Click to view commands.`, {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now rank {rankName} (Permission Level: {newLevel})`, {plr})
					else
						Functions.Hint(`You do not have permission to set the rank of {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end;
		};

		SetLevel = {
			Prefix = Settings.Prefix;
			Commands = {"setlevel", "setadminlevel"};
			Args = {"player", "level"};
			Description = "Sets the target player(s) permission level for the current server; does not save";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level
				local newLevel = assert(tonumber(args[2]), "Level must be a number")

				assert(newLevel < senderLevel, `Level cannot be equal to or above your own permission level ({senderLevel})`);

				for _, v in service.GetPlayers(plr, args[1])do
					if senderLevel > Admin.GetLevel(v) then
						Admin.SetLevel(v, newLevel, args[3] == "true")
						Functions.LogAdminAction(plr, "Set Level", v.Name, `New level: {newLevel}`)
						Functions.Notification("Notification", `Your admin permission level was set to {newLevel} for this server only. Click to view commands.`, {v}, 10, "MatIcon://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now permission level {newLevel}`, {plr})
					else
						Functions.Hint(`You do not have permission to set the permission level of {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end;
		};

		UnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"unadmin", "unmod", "unowner", "unpadmin", "unheadadmin", "unrank"};
			Args = {"player/user / list entry", "temp? (true/false) (default: false)"};
			Description = "Removes admin/moderator ranks from the target player(s); saves unless <temp> is 'true'";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local target = assert(args[1], "Missing target user (argument #1)")
				local temp = args[2] and args[2]:lower() == "true"
				local senderLevel = data.PlayerData.Level
				local userFound = false

				if not string.find(target, ":") then
					for _, v in service.GetPlayers(plr, target, {
						UseFakePlayer = true;
						DontError = true;
						})
					do
						userFound = true
						local targLevel, targRank = Admin.GetLevel(v)
						if targLevel > 0 then
							if senderLevel > targLevel then
								Admin.RemoveAdmin(v, temp)
								Functions.LogAdminAction(plr, "Remove Admin", v.Name, `Temporary: {temp}`)
								Functions.Hint(string.format("Removed %s from rank %s", service.FormatPlayer(v, true), targRank or "[unknown rank]"), {plr})
								Functions.Notification("Notification", `You are no longer a(n) {targRank or "admin"}`, {v}, 10, "MatIcon://Shield")
							else
								Functions.Hint(`You do not have permission to remove {service.FormatPlayer(v, true)}'s rank`, {plr})
							end
						else
							Functions.Hint(`{service.FormatPlayer(v, true)} does not already have any rank to remove`, {plr})
						end
					end

					if userFound then
						return
					else
						Functions.Hint("User not found in server; searching datastore", {plr})
					end
				end

				for rankName, rankData in Settings.Ranks do
					if senderLevel <= rankData.Level then
						continue
					end
					for i, user in rankData.Users do
						if not (user:lower() == target:lower() or user:lower():match(`^{target:lower()}:`) or Admin.DoCheck(target, user)) then
							continue
						end
						if
							Remote.GetGui(plr, "YesNoPrompt", {
								Question = `Remove '{user}' from '{rankName}'?`;
							}) == "Yes"
						then
							table.remove(rankData.Users, i)
							if not temp and Settings.SaveAdmins then
								service.TrackTask("Thread: RemoveAdmin", Core.DoSave, false, {
									Type = "TableRemove";
									Table = {"Settings", "Ranks", rankName, "Users"};
									Value = user;
								});
								Functions.Hint(`Removed entry '{user}' from {rankName}`, {plr})
								Logs:AddLog("Script", `{plr} removed {user} from {rankName}`)
							end
						end
						userFound = true
					end
				end
				assert(userFound, `No table entries matching '{args[1]}' were found`)
			end
		};

		TempUnAdmin = {
			Prefix = Settings.Prefix;
			Commands = {"tempunadmin", "untempadmin", "tunadmin", "untadmin"};
			Args = {"player"};
			Description = "Removes the target players' admin powers for this server; does not save";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {UseFakePlayer = true}) do
					local targetLevel = Admin.GetLevel(v)
					if targetLevel > 0 then
						if senderLevel > targetLevel then
							Admin.RemoveAdmin(v, true)
							Functions.LogAdminAction(plr, "Temporary Unadmin", v.Name, "Admin powers temporarily removed")
							Functions.Hint(`Removed {service.FormatPlayer(v)}'s admin powers`, {plr})
							Functions.Notification("Notification", "Your admin powers have been temporarily removed", {v}, 10, "MatIcons://Remove moderator")
						else
							Functions.Hint(`You do not have permission to remove {service.FormatPlayer(v, true)}'s admin powers`, {plr})
						end
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is not an admin`, {plr})
					end
				end
			end
		};

		TempModerator = {
			Prefix = Settings.Prefix;
			Commands = {"tempmod", "tmod", "tempmoderator", "tmoderator"};
			Args = {"player"};
			Description = "Makes the target player(s) a temporary moderator; does not save";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {UseFakePlayer = true}) do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Moderators", true)
						Functions.LogAdminAction(plr, "Temporary Moderator", v.Name, "N/A")
						Functions.Notification("Notification", "You are a temp moderator. Click to view commands.", {v}, 10, "MatIcons://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a temp moderator`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Moderator = {
			Prefix = Settings.Prefix;
			Commands = {"permmod", "pmod", "mod", "moderator", "pmoderator"};
			Args = {"player/user"};
			Description = "Makes the target player(s) a moderator; saves";
			Category = "Ranks";
			AdminLevel = "Admins";
			Dangerous = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local senderLevel = data.PlayerData.Level

				for _, v in service.GetPlayers(plr, assert(args[1], "Missing target player (argument #1)"), {
					UseFakePlayer = true;
					})
				do
					if senderLevel > Admin.GetLevel(v) then
						Admin.AddAdmin(v, "Moderators")
						Functions.LogAdminAction(plr, "Promoted to Moderator", v.Name, "N/A")
						Functions.Notification("Notification", "You are a moderator. Click to view commands.", {v}, 10, "MatIcons://Shield", Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.Prefix}cmds')`))
						Functions.Hint(`{service.FormatPlayer(v, true)} is now a moderator`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is already the same admin level as you or higher`, {plr})
					end
				end
			end
		};

		Broadcast = {
			-- Delivers explicitly submitted broadcast text through each recipient's native chat channel.
			UserText = {Kind = "Chat", Audience = "AllPlayers", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"broadcast", "bc"};
			Args = {"Message"};
			Description = "Makes a message in the chat window";
			Category = "Messages";
			AdminLevel = "Admins";
			-- The native receipt supplies the text used by the local chat-window presentation.
			Function = function(plr: Player, args: {string}, data: {any})
				server.ChatTransport.SubmitCommand(plr, service.GetPlayers(), assert(args[1], "Missing message"), data and data.ChatInput, "Notification", "ChatMessage", {TitleMode = "Broadcast"})
			end
		};

		ShutdownLogs = {
			Prefix = Settings.Prefix;
			Commands = {"shutdownlogs", "shutdownlog", "slogs", "shutdowns"};
			Args = {};
			Description = "Shows who shutdown or restarted a server and when";
			Category = "Logs";
			AdminLevel = "Admins";
			ListUpdater = function(plr: Player)
				local logs = Core.GetData("ShutdownLogs") or {}
				local tab = {}
				for i, v in logs do
					local authorId = tonumber(v.UserId) or (type(v.ReasonRecord) == "table" and tonumber(v.ReasonRecord.AuthorUserId))
					tab[i] = {
						Text = `{tonumber(v.Time) or 0}{if v.Restart then " [RESTART]" else ""}: {if authorId then `User {authorId}` else "Server"}`;
						Desc = `Reason: {server.TextPolicy.GetRecordText(v.ReasonRecord) or "Reason unavailable"}`;
					}
				end
				return tab
			end;
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "List", {
					Title = "Shutdown Logs";
					Table = Logs.ListUpdaters.ShutdownLogs(plr);
					Update = "ShutdownLogs";
				})
			end
		};

		ServerLock = {
			Prefix = Settings.Prefix;
			Commands = {"slock", "serverlock", "lockserver"};
			Args = {"on/off"};
			Description = "Enables/disables server lock";
			Category = "Server";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local arg = args[1] and string.lower(args[1])
				Functions.LogAdminAction(plr, "Server Lock", "Server is now " .. (if (arg == "on" or arg == "true") then "locked" else "unlocked"), "")
				if (not arg and Variables.ServerLock ~= true) or arg == "on" or arg == "true" then
					Variables.ServerLock = true
					Functions.Hint("Server Locked", service.Players:GetPlayers())
				elseif Variables.ServerLock == true or arg == "off" or arg == "false" then
					Variables.ServerLock = false
					Functions.Hint("Server Unlocked", service.Players:GetPlayers())
				end
			end
		};

		Whitelist = {
			Prefix = Settings.Prefix;
			Commands = {"wl", "enablewhitelist", "whitelist"};
			Args = {"on/off/add/remove/list/clear", "optional player"};
			Description = "Enables/disables the server whitelist; :wl username to add them to the whitelist";
			Category = "Server";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local sub = string.lower(args[1])

				if sub == "on" or sub == "enable" then
					Variables.Whitelist.Enabled = true
					Functions.Hint("Enabled server whitelist", service.Players:GetPlayers())
				elseif sub == "off" or sub == "disable" then
					Variables.Whitelist.Enabled = false
					Functions.Hint("Disabled server whitelist", service.Players:GetPlayers())
				elseif sub == "add" then
					if args[2] then
						local plrs = service.GetPlayers(plr, args[2], {
							DontError = true;
							IsServer = false;
							IsKicking = false;
							UseFakePlayer = true;
						})
						if #plrs>0 then
							for _, v in plrs do
								table.insert(Variables.Whitelist.Lists.Settings, `{v.Name}:{v.UserId}`)
								Functions.Hint(`Added {service.FormatPlayer(v)} to the whitelist`, {plr})
							end
						else
							table.insert(Variables.Whitelist.Lists.Settings, args[2])
						end
					else
						error("Missing user argument")
					end
				elseif sub == "remove" then
					if args[2] then
						for i, v in Variables.Whitelist.Lists.Settings do
							if string.sub(string.lower(v), 1,#args[2]) == string.lower(args[2])then
								table.remove(Variables.Whitelist.Lists.Settings,i)
								Functions.Hint(`Removed {v} from the whitelist`, {plr})
							end
						end
					else
						error("Missing user argument")
					end
				elseif sub == "list" then
					local Tab = {}
					for Key, List in Variables.Whitelist.Lists do
						local Prefix = Key == "Settings" and "" or `[{Key}] `
						for _, User in List do
							table.insert(Tab, {Text = Prefix .. User, Desc = User})
						end
					end
					Remote.MakeGui(plr, "List", {Title = "Whitelist List"; Tab = Tab;})
				elseif sub == "clear" then
					Variables.Whitelist.Lists.Settings = {}
					Functions.Hint("Cleared server whitelist", service.Players:GetPlayers())
				else
					error("Invalid subcommand (on/off/add/remove/list/clear)")
				end
			end
		};

		SystemNotify = {
			-- Keeps the small-message style while attributing user text through native chat.
			UserText = {Kind = "Chat", Audience = "AllPlayers", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"sn", "systemnotify", "sysnotif", "sysnotify", "systemsmallmessage", "snmessage", "snmsg", "ssmsg", "ssmessage"};
			Args = {"message"};
			Description = "Makes an attributed small message for players who can receive your chat";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Leaves recipient delivery and filtering to the author's TextChannel.
			Function = function(plr: Player, args: {string}, data: {})
				server.ChatTransport.SubmitCommand(plr, service.GetPlayers(), assert(args[1], "Missing message"), data and data.ChatInput, "Notification", "Notify", {AutoDuration = true})
			end
		};

		Notif = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}, ExemptValues = {[1] = {off = true, ["false"] = true}}};
			Prefix = Settings.Prefix;
			Commands = {"setmessage", "notif", "setmsg", "permhint"};
			Args = {"message OR off"};
			Filter = true;
			Description = "Sets a small hint message at the top of the screen";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Removes case-insensitive control words without publishing them as persistent text.
			Function = function(plr: Player, args: {string})
				local text = assert(args[1], "Missing message (or enter 'off' to disable)")
				local control = text:lower()
				local message = if control == "off" or control == "false" then nil else text

				if server.PanicMode and server._tempBackupHint then
					server._tempBackupHint.Text = `~= Adonis PanicMode Enabled{message and " - " or ""}{message or ""} =~`
				end
				Variables.NotifMessage = message
				for _, v in service.GetPlayers() do
					if Variables.NotifMessage then
						Remote.MakeGui(v, "Notif", {
							Message = Variables.NotifMessage;
						})
					else
						Remote.RemoveGui(v, "Notif")
					end
				end
			end
		};

		SetBanMessage = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"setbanmessage", "setbmsg"};
			Args = {"message"};
			Filter = true;
			Description = "Sets the ban message banned players see";
			Category = "Moderation";
			AdminLevel = "Admins";
			-- Retains the safe-only author record for later moderation notices.
			Function = function(plr: Player, args: {string}, data)
				Variables.BanMessage = assert(args[1], "Missing message (argument #1)")
				Core.RegisterVariableText("BanMessage", args[1], data and data.UserTextRecords and data.UserTextRecords[1])
			end
		};

		SetLockMessage = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"setlockmessage", "slockmsg", "setlmsg"};
			Args = {"message"};
			Filter = true;
			Description = "Sets the lock message unwhitelisted players see if :whitelist or :slock is on";
			Category = "Server";
			AdminLevel = "Admins";
			-- Retains the safe-only author record for later moderation notices.
			Function = function(plr: Player, args: {string}, data)
				Variables.LockMessage = assert(args[1], "Missing message (argument #1)")
				Core.RegisterVariableText("LockMessage", args[1], data and data.UserTextRecords and data.UserTextRecords[1])
			end
		};

		SystemMessage = {
			-- User-written system-style messages retain their actual native chat author.
			UserText = {Kind = "Chat", Audience = "AllPlayers", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"sm", "systemmessage", "sysmsg"};
			Args = {"message"};
			Description = "Makes an attributed message for players who can receive your chat";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Starts one native send from the caller's explicit submission.
			Function = function(plr: Player, args: {string}, data: {})
				server.ChatTransport.SubmitCommand(plr, service.GetPlayers(), assert(args[1], "Missing message (argument #1)"), data and data.ChatInput, "Notification", "Message", {AutoDuration = true})
			end
		};

		SetCoreGuiEnabled = {
			Prefix = Settings.Prefix;
			Commands = {"setcoreguienabled", "setcoreenabled", "showcoregui", "setcoregui", "setcgui", "setcore", "setcge"};
			Args = {"player", table.concat(Functions.GetAlphabeticalEnumNames(Enum.CoreGuiType), "/"), "true/false"};
			Description = "Enables or disables CoreGui elements for the target player(s)";
			Category = "Screen Effects";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing player(s) (argument #1)")
				assert(args[2], "Missing CoreGuiType (argument #2)")
				-- selene: allow(incorrect_standard_library_use)
				assert(Enum.CoreGuiType:FromName(args[2]), `Invalid CoreGuiType '{args[2]}' (argument #2)`)
				assert(args[3], "Missing state (argument #3)")

				local args3Lowered = args[3]:lower()
				local enable = if args3Lowered == "true" or args3Lowered == "on" then true
					elseif args3Lowered == "false" or args3Lowered == "off" then false
					else nil
				assert(enable ~= nil, `Invalid state '{args[3]}' (argument #3); expected true/false/on/off`)
				
				for _, v in service.GetPlayers(plr, args[1]) do
    				Remote.Send(v, "Function", "SetCoreGuiEnabled", args[2], enable)
				end
			end
		};

		Alert = {
			Prefix = Settings.Prefix;
			Commands = {"alert", "alarm", "annoy"};
			Args = {"player", "message"};
			UserText = {Kind = "Chat", Args = {2}, Audience = "SelectedPlayers"};
			Description = "Get someone's attention";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Sends custom attention text through the author's native chat channel.
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing player name")
				local recipients = service.GetPlayers(plr, args[1])
				if args[2] then
					server.ChatTransport.SubmitCommand(plr, recipients, args[2], data and data.ChatInput, "Notification", "Alert")
				else
					for _, player in recipients do
						Remote.MakeGui(player, "Alert", {Message = "Wake up; Your attention is required"})
					end
				end
			end
		};

		LockMap = {
			Prefix = Settings.Prefix;
			Commands = {"lockmap"};
			Args = {};
			Description = "Locks the map";
			Category = "World";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, obj in workspace:GetDescendants()do
					if obj:IsA("BasePart")then
						obj.Locked = true
					end
				end
			end
		};

		UnlockMap = {
			Prefix = Settings.Prefix;
			Commands = {"unlockmap"};
			Args = {};
			Description = "Unlocks the map";
			Category = "World";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, obj in workspace:GetDescendants()do
					if obj:IsA("BasePart")then
						obj.Locked = false
					end
				end
			end
		};

		BuildingTools = {
			Prefix = Settings.Prefix;
			Commands = {"btools", "f3x", "buildtools", "buildingtools", "buildertools"};
			Args = {"player"};
			Description = "Gives the target player(s) F3X building tools.";
			Category = "Tools";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local F3X = Deps.Assets:FindFirstChild("F3X Deps") and (function(deps)
					local F3X = service.New("Tool", {
						GripPos = Vector3.new(0, 0, 0.4),
						CanBeDropped = false,
						ManualActivationOnly = false,
						ToolTip = "Building Tools by F3X",
						Name = "Building Tools"
					}, true)
					local clonedDeps = deps:Clone()

					for _, obj in clonedDeps:GetDescendants() do
						if obj:IsA("BaseScript") then
							obj.Disabled = false
						end
					end
					for _, obj in clonedDeps:GetChildren() do
						obj.Parent = F3X
					end

					clonedDeps:Destroy()
					return F3X
				end)(Deps.Assets:FindFirstChild("F3X Deps")) or Variables.F3XCached and Variables.F3XCached:Clone()

				if not F3X then
					print(`Requiring F3X Tool MainModule; Model URL: https://www.roblox.com/library/580330877`)
					F3X = require(Deps.FetchF3X:Clone())
					assert(typeof(F3X) == "Instance", "Unable to load F3X.")
				end

				F3X.CanBeDropped = false

				if Variables.F3XCached == nil then
					Variables.F3XCached = F3X:Clone()
				end

				service.New("StringValue", {
					Name = `__ADONIS_VARIABLES_{Variables.CodeName}`,
					Parent = F3X
				})

				for _, v in service.GetPlayers(plr, args[1]) do
					local Backpack = v:FindFirstChildOfClass("Backpack")

					if Backpack then
						F3X:Clone().Parent = Backpack
					end
				end

				F3X:Destroy()
			end
		};

		Insert = {
			Prefix = Settings.Prefix;
			Commands = {"insert", "ins"};
			Args = {"id"};
			Description = "Inserts whatever object belongs to the ID you supply, the object must be in the place owner's or Roblox's inventory";
			Category = "Tools";
			AdminLevel = "Admins";
			CrossServerDenied = true;
			Function = function(plr: Player, args: {string})
				assert(plr ~= false and not service.Wrapped(plr), "A real player must be used to run insert.")
				local id = string.lower(assert(args[1], "ID required (argument #1)"))

				for _, v in Variables.InsertList do
					if id == string.lower(v.Name)then
						id = v.ID
						break
					end
				end

				for _, v in HTTP.Trello.InsertList do
					if id == string.lower(v.Name) then
						id = v.ID
						break
					end
				end

				local obj: Model? = service.Insert(tonumber(id), true)
				if obj and plr.Character then
					obj:SetAttribute("ADONIS_InsertedBy", plr.Name)
					table.insert(Variables.InsertedObjects, obj)
					pcall(obj.MakeJoints, obj)
					obj:PivotTo(plr.Character:GetPivot())
					obj.Parent = workspace
				end
			end
		};

		SaveTool = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {2}};
			Prefix = Settings.Prefix;
			Commands = {"addtool", "savetool", "maketool"};
			Args = {"optional player", "optional new tool name"};
			Description = `Saves the equipped tool to the storage so that it can be inserted using {Settings.Prefix}give`;
			Category = "Tools";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					local tool = v.Character and v.Character:FindFirstChildWhichIsA("BackpackItem")
					if tool then
						tool = tool:Clone()
						if args[2] then tool.Name = args[2] end
						tool.Parent = service.UnWrap(Settings.Storage)
						Variables.SavedTools[tool] = service.FormatPlayer(plr)
						Functions.Hint(`Added tool: {tool.Name}`, {plr})
					elseif not args[1] then
						error("You must have an equipped tool to add to the storage.")
					end
				end
			end
		};

		ClearSavedTools = {
			Prefix = Settings.Prefix;
			Commands = {"clraddedtools", "clearaddedtools", "clearsavedtools", "clrsavedtools"};
			Args = {};
			Description = `Removes any tools in the storage added using {Settings.Prefix}savetool`;
			Category = "Tools";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local count = 0
				for tool in Variables.SavedTools do
					count += 1
					tool:Destroy()
				end
				table.clear(Variables.SavedTools)
				Functions.Hint(string.format("Cleared %d saved tool%s.", count, count == 1 and "" or "s"), {plr})
			end
		};

		NewTeam = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"newteam", "createteam", "maketeam"};
			Args = {"name", "BrickColor"};
			Filter = true;
			Description = "Make a new team with the specified name and color";
			Category = "Teams & Stats";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local teamName = assert(args[1], "Missing team name (argument #1)")
				local teamColor = Functions.ParseBrickColor(args[2])

				if service.Teams:FindFirstChild(teamName) then
					Functions.Hint(string.format("Team '%s' already exists!", teamName), {plr})
					return;
				end

				service.New("Team", {
					Parent = service.Teams;
					Name = teamName;
					TeamColor = teamColor;
					AutoAssignable = false;
				})
				if Settings.CommandFeedback then
					Functions.Hint(string.format("Created new team '%s' (%s)", teamName, teamColor.Name), {plr})
				end
			end
		};

		RemoveTeam = {
			Prefix = Settings.Prefix;
			Commands = {"removeteam", "deleteteam"};
			Args = {"name"};
			Description = "Remove the specified team";
			Category = "Teams & Stats";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.Teams:GetTeams() do
					if string.sub(string.lower(v.Name), 1, #args[1]) == string.lower(args[1]) then
						local ans = Remote.GetGui(plr, "YesNoPrompt", { Question = `Remove team: '{v.Name}'?` })

						if ans == "Yes" then
							v:Destroy()
							return Functions.Hint(`Removed team {v.Name}`, {plr})
						else
							return Functions.Hint("Cancelled team removal operation", {plr})
						end
					end
				end
			end
		};

		RestoreMap = {
			Prefix = Settings.Prefix;
			Commands = {"restoremap", "maprestore", "rmap"};
			Args = {};
			Description = "Restore the map to the the way it was the last time it was backed up";
			Category = "World";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local plrName = plr and service.FormatPlayer(plr) or "<SERVER>"

				if not Variables.MapBackup then
					error("Cannot restore when there are no backup maps!", 0)
					return
				end
				if Variables.RestoringMap then
					error("Map has not been backed up",0)
					return
				end
				if Variables.BackingupMap then
					error("Cannot restore map while backing up map is in process!", 0)
					return
				end

				Variables.RestoringMap = true
				Functions.Hint("Restoring Map...", service.Players:GetPlayers())
				workspace.Gravity = Variables.OriginalGravity

				for _, obj in workspace:GetChildren() do
					if obj.ClassName ~= "Terrain" and not service.Players:GetPlayerFromCharacter(obj) then
						obj:Destroy()
						service.RunService.Stepped:Wait()
					end
				end

				local new = Variables.MapBackup:Clone()
				for _, obj in new:GetChildren() do
					obj.Parent = workspace
					if obj:IsA("Model") then
						obj:MakeJoints()
					end
				end
				new:Destroy()

				local Terrain = workspace.Terrain or workspace:FindFirstChildOfClass("Terrain")
				if Terrain and Variables.TerrainMapBackup then
					Terrain:Clear()
					Terrain:PasteRegion(Variables.TerrainMapBackup, Terrain.MaxExtents.Min, true)
				end

				task.wait()

				Admin.RunCommand(`{Settings.Prefix}fixlighting`)
				Admin.RunCommand(`{Settings.Prefix}respawn`, "all")
				Variables.RestoringMap = false
				Functions.Hint('Map Restore Complete.',service.Players:GetPlayers())

				Logs:AddLog("Script", {
					Text = "Map Restoration Complete",
					Desc = `{plrName} has restored the map.`,
				})
			end
		};

		Note = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {2}};
			Prefix = Settings.Prefix;
			Commands = {"note", "writenote", "makenote"};
			Args = {"player", "note"};
			Filter = true;
			Description = "Makes a note on the target player(s) that says <note>";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[2], "Missing note (argument #2)")
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					local PlayerData = Core.GetPlayer(v)
					if not PlayerData.AdminNotes then PlayerData.AdminNotes = {} end
					table.insert(PlayerData.AdminNotes, data.UserTextRecords[2])
					Functions.Hint(`Added {service.FormatPlayer(v)} Note {args[2]}`, {plr})
					Core.SavePlayer(v, PlayerData)
				end
			end
		};

		DeleteNote = {
			Prefix = Settings.Prefix;
			Commands = {"removenote", "remnote", "deletenote", "clearnote"};
			Args = {"player", "note index, matching text, or all"};
			Description = "Removes a note on the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Missing note (argument #2)")
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					local PlayerData = Core.GetPlayer(v)
					if PlayerData.AdminNotes then
						if string.lower(args[2]) == "all" then
							PlayerData.AdminNotes = {}
						else
							for k = #PlayerData.AdminNotes, 1, -1 do
								local note = server.TextPolicy.GetRecordText(PlayerData.AdminNotes[k])
								if tonumber(args[2]) == k or (note and string.sub(string.lower(note), 1, #args[2]) == string.lower(args[2])) then
									Functions.Hint(`Removed note {k} for {service.FormatPlayer(v)}`, {plr})
									table.remove(PlayerData.AdminNotes, k)
								end
							end
						end
						Core.SavePlayer(v, PlayerData)
					end
				end
			end
		};

		ShowNotes = {
			Prefix = Settings.Prefix;
			Commands = {"notes", "viewnotes"};
			Args = {"player"};
			Description = "Views notes on the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
					local PlayerData = Core.GetPlayer(v)
					local notes = PlayerData.AdminNotes
					if not notes then
						Functions.Hint(`No notes found on {service.FormatPlayer(v)}`, {plr})
						continue
					end
					local displayed = {}
					for index, note in notes do
						displayed[index] = `{index}: {server.TextPolicy.GetRecordText(note) or "Text unavailable"}`
					end
					Remote.MakeGui(plr, "List", {Title = service.FormatPlayer(v), Table = displayed})
				end
			end
		};

		LoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"loopkill"};
			Args = {"player", "num (optional)"};
			Description = "Repeatedly kills the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local num = tonumber(args[2]) or 9999

				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(`{v.UserId}LOOPKILL`)
					local count = 0
					Routine(service.StartLoop, `{v.UserId}LOOPKILL`, 3, function()
						local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
							hum.Health = 0
							count += 1
						end
						if count == num then
							service.StopLoop(`{v.UserId}LOOPKILL`)
						end
					end)
				end
			end
		};

		UnLoopKill = {
			Prefix = Settings.Prefix;
			Commands = {"unloopkill"};
			Args = {"player"};
			Description = "Un-Loop Kill";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.StopLoop(`{v.UserId}LOOPKILL`)
				end
			end
		};

		Lag = {
			Prefix = Settings.Prefix;
			Commands = {"lag", "fpslag"};
			Args = {"player"};
			Description = "Makes the target player(s)'s FPS drop";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1]) do
					if Admin.CheckAuthority(plr, v, "lag") then
						Remote.Send(v, "Function", "SetFPS", 5.6)
					end
				end
			end
		};

		UnLag = {
			Prefix = Settings.Prefix;
			Commands = {"unlag", "unfpslag"};
			Args = {"player"};
			Description = "Un-Lag";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					Remote.Send(v, "Function", "RestoreFPS")
				end
			end
		};

		Crash = {
			Prefix = Settings.Prefix;
			Commands = {"crash"};
			Args = {"player"};
			Description = "Crashes the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {IsKicking = true}) do
					if Admin.CheckAuthority(plr, v, "crash") then
						Remote.Send(v, "Function", "Crash")
					end
				end
			end
		};

		HardCrash = {
			Prefix = Settings.Prefix;
			Commands = {"hardcrash"};
			Args = {"player"};
			Description = "Hard-crashes the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {IsKicking = true}) do
					if Admin.CheckAuthority(plr, v, "hard-crash") then
						Remote.Send(v, "Function", "HardCrash")
					end
				end
			end
		};

		RAMCrash = {
			Prefix = Settings.Prefix;
			Commands = {"ramcrash", "memcrash"};
			Args = {"player"};
			Description = "RAM-crashes the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {IsKicking = true}) do
					if Admin.CheckAuthority(plr, v, "RAM-crash") then
						Remote.Send(v, "Function", "RAMCrash")
					end
				end
			end
		};

		GPUCrash = {
			Prefix = Settings.Prefix;
			Commands = {"gpucrash"};
			Args = {"player"};
			Description = "GPU crashes the target player(s)";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				for _, v in service.GetPlayers(plr, args[1], {IsKicking = true}) do
					if Admin.CheckAuthority(plr, v, "GPU-crash") then
						Remote.Send(v, "Function", "GPUCrash")
					end
				end
			end
		};

		CustomKick = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {2, 3}};
			Prefix = Settings.Prefix;
			Commands = {"ckick", "customkick", "customcrash"};
			Args = {"player", "title", "message"};
			Description = "Disconnects (crashes) the target player with a custom Roblox dialog";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[3], "Argument(s) missing or nil")

				local title = args[2]
				local msg = args[3]

				for _, v in service.GetPlayers(plr, args[1], {IsKicking = true}) do
					if not Admin.CheckAuthority(plr, v, "custom-kick") then
						continue
					end

					local plrgui = v:FindFirstChildOfClass("PlayerGui")
					if not plrgui then
						Remote.MakeGui(plr, "Output", {
							Message = `Failed to custom-kick {service.FormatPlayer(v)} (PlayerGui not found)`;
						})
						continue
					end

					local promptGui = Deps.Assets.RobloxPromptGui:Clone()
					promptGui.promptOverlay.ErrorPrompt.TitleFrame.ErrorTitle.Text = title
					promptGui.promptOverlay.ErrorPrompt.MessageArea.ErrorFrame.ErrorMessage.Text = msg
					promptGui.Parent = plrgui

					Remote.Send(v, "Function", "CustomKick")
					task.delay(5, function()
						if v.Parent == service.Players then
							-- make sure they're really kicked
							v:Kick("Unexpected Error")
						end
					end)
					Functions.Hint(`Custom-kicking {service.FormatPlayer(v)}`, {plr})
				end
			end
		};

		Shutdown = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {1}};
			Prefix = Settings.Prefix;
			Commands = {"shutdown"};
			Args = {"reason"};
			Description = "Shuts the server down";
			Category = "Server";
			Filter = true;
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {})
				if Core.DataStore then
					Core.UpdateData("ShutdownLogs", function(logs)
						table.insert(logs, 1, {
							User = plr and plr.Name or "[Server]",
							UserId = plr and plr.UserId or nil,
							Time = os.time(),
							Reason = args[1] or "N/A",
							ReasonRecord = data.UserTextRecords[1],
						})

						local nlogs = #logs
						if nlogs > Logs.OldCommandLogsLimit then
							table.remove(logs, nlogs)
						end

						return logs
					end)
				end

				Functions.Shutdown(args[1])
			end
		};

		ServerBan = {
			-- Declares user-authored display arguments for filtering and public edit admission.
			UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {2}};
			Prefix = Settings.Prefix;
			Commands = {"serverban", "ban"};
			Args = {"player/user", "reason"};
			Description = "Bans the target player(s) from the server";
			Category = "Moderation";
			AdminLevel = "Admins";
			Filter = true;
			Function = function(plr: Player, args: {string}, data: {any})
				local reason = args[2] or "No reason provided"
				for _, v in service.GetPlayers(plr, args[1], {
					IsKicking = true;
					UseFakePlayer = true;
					})
				do
					if Admin.CheckAuthority(plr, v, "server-ban", false) then
						Admin.AddBan(v, reason, false, plr, "Server", data.UserTextRecords[2])
						Functions.LogAdminAction(plr, "Server Ban", v.Name, `Reason: {reason}`)
						Functions.Hint(`Server-banned {service.FormatPlayer(v, true)}`, {plr})
					end
				end
			end
		};

		UnBan = {
			Prefix = Settings.Prefix;
			Commands = {"unserverban", "unban"};
			Args = {"user"};
			Description = "Unbans the target user(s) from the server";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, assert(args[1], "Missing user (argument #1)"), {
					UseFakePlayer = true;
					})
				do
					if Admin.RemoveBan(v) then
						Functions.LogAdminAction(plr, "Unban", v.Name, "User has been unbanned.")
						Functions.Hint(`{service.FormatPlayer(v, true)} has been unbanned`, {plr})
					else
						Functions.Hint(`{service.FormatPlayer(v, true)} is not currently banned`, {plr})
					end
				end
			end
		};

		BanMenu = {
			Prefix = Settings.Prefix;
			Commands = {"banmenu"};
			Args = {};
			Description = "Opens the ban menu";
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string}, data: {any})
				Remote.MakeGui(plr,"BanMenu",{
					AdminLevel = Admin.GetLevel(plr);
					CanBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.ServerBan.AdminLevel);
					CanTimeBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.TimeBan.AdminLevel);
					CanPermBan = Admin.CheckComLevel(Admin.GetLevel(plr),Commands.PermanentBan.AdminLevel);
					Prefix = Functions.GetMainPrefix()
				})
			end,
		};

		CustomMessage = {
			-- Both displayed fields travel in one authenticated native chat submission.
			UserText = {Kind = "Chat", Audience = "AllPlayers", Args = {1, 2}};
			Prefix = Settings.Prefix;
			Commands = {"cm", "custommessage"};
			Args = {"Upper message", "message"};
			Description = "Same as message but says whatever you want upper message to be instead of your name.";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Recipients reconstruct the custom title only from their delivered channel text.
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing message title (argument #1)")
				assert(args[2], "Missing message (argument #2)")
				server.ChatTransport.SubmitCommand(plr, service.GetPlayers(), args[1] .. "\n" .. args[2], data and data.ChatInput, "Notification", "Message", {TitleMode = "Custom", AutoDuration = true})
			end
		};

		Nil = {
			Prefix = Settings.Prefix;
			Commands = {"nil"};
			Args = {"player"};
			Hidden = true;
			Description = `Deletes the player forcefully, causing them to be kicked for "Player has been removed from the DataModel"`;
			Category = "Moderation";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				local sourcePlayerLevel = Admin.GetLevel(plr)
				for _, v in service.GetPlayers(plr, args[1]) do
					if Admin.GetLevel(v) <= sourcePlayerLevel then
						v.Character = nil
						v.Parent = nil
						Functions.Hint(`Sent {service.FormatPlayer(v)} to nil`, {plr})
					else
						Functions.Hint(`You don't have permission to send {service.FormatPlayer(v)} to nil`, {plr})
					end
				end
			end
		};

		PromptPlusPurchase = {
			Prefix = Settings.Prefix;
			Commands = {"promptpluspurchase", "pluspurchaseprompt", "promptpremiumpurchase", "premiumpurchaseprompt"};
			Args = {"player"};
			Description = "Opens the Roblox Plus purchase prompt for the target player(s)";
			Category = "Messages";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					service.MarketplaceService:PromptRobloxSubscriptionPurchase(v)
				end
			end
		};

		RobloxNotify = {
			Prefix = Settings.Prefix;
			Commands = {"rbxnotify", "robloxnotify", "robloxnotif", "rblxnotify", "rnotif", "rn"};
			Args = {"player", "duration (seconds)", "text"};
			UserText = {Kind = "Chat", Args = {3}, Audience = "SelectedPlayers"};
			Description = "Sends a Roblox-styled notification for the target player(s)";
			Category = "Messages";
			AdminLevel = "Admins";
			-- Sends custom attention text through the author's native chat channel.
			Function = function(plr: Player, args: {string}, data: {})
				assert(args[1], "Missing player name")
				local recipients = service.GetPlayers(plr, args[1])
				if args[3] then
					server.ChatTransport.SubmitCommand(plr, recipients, args[3], data and data.ChatInput, "Notification", "RobloxNotification", {Duration = tonumber(args[2])})
				else
					for _, player in recipients do
						Remote.Send(player, "Function", "SetCore", "SendNotification", {
							Title = "Notification", Text = "Hello, from Adonis!", Duration = math.clamp(tonumber(args[2]) or 5, 1, 30),
						})
					end
				end
			end
		};

		Disguise = {
			-- Resolves account identity before admitting the shared display-name edit once.
			UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {}, RequiresLocalAuthor = true};
			Prefix = Settings.Prefix;
			Commands = {"disguise", "masquerade"};
			Args = {"player", "username"};
			Description = "Names the player, chars the player, and modifies the player's chat tag";
			Category = "Appearance";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				assert(args[2], "Argument missing or nil")
				local userId = Functions.GetUserIdFromNameAsync(args[2])
				assert(userId, "Invalid username supplied/user not found")

				local resolved, username = pcall(service.Players.GetNameFromUserIdAsync, service.Players, userId)
				assert(resolved, "Account name could not be resolved")

				if service.Players:GetPlayerByUserId(userId) then
					error("You cannot disguise as this player (currently in server)")
				end

				local _, records = server.TextPolicy.PrepareArguments(server.TextPolicy.GetCommandAuthor(plr), {username}, {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}})
				local record = records[1]
				-- Respawns reuse the same admitted snapshot and never impersonate the target as its author.
				local function applyName(character)
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					if humanoid then humanoid.DisplayName = server.TextPolicy.GetRecordText(record) or "" end
				end
				Commands.Char.Function(plr, args)

				for _, v in service.GetPlayers(plr, args[1]) do
					applyName(v.Character)
					if Variables.DisguiseBindings[v.UserId] then
						Variables.DisguiseBindings[v.UserId].Rename:Disconnect()
						Variables.DisguiseBindings[v.UserId].Rename = nil
					end

					Variables.DisguiseBindings[v.UserId] = {
						TargetUsername = username;
						Rename = v.CharacterAppearanceLoaded:Connect(function(char)
							applyName(char)
						end);
					}
				end
			end
		};

		UnDisguise = {
			Prefix = Settings.Prefix;
			Commands = {"undisguise", "removedisguise", "cleardisguise", "nodisguise"};
			Args = {"player"};
			Description = "Removes the player's disguise";
			Category = "Appearance";
			AdminLevel = "Admins";
			Function = function(plr: Player, args: {string})
				for _, v in service.GetPlayers(plr, args[1]) do
					if Variables.DisguiseBindings[v.UserId] then
						Variables.DisguiseBindings[v.UserId].Rename:Disconnect()
						Variables.DisguiseBindings[v.UserId].Rename = nil
					end
					Variables.DisguiseBindings[v.UserId] = nil
				end
				Commands.UnChar.Function(plr, args)
				Commands.UnDisplayName.Function(plr, args)
			end
		};
	}
end
