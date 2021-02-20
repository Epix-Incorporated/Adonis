server = nil
service = nil

return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Admin = server.Admin
	local Remote = server.Remote
	local Functions = server.Functions
	local Core = server.Core
	local Variables = server.Variables
	local HTTP = server.HTTP
	local Deps = server.Deps
	local Logs = server.Logs

	local Commands = {
		Admin = {
			Prefix = Settings.Prefix;
			Commands = {"permadmin","pa","padmin","fulladmin","realadmin"};
			Args = {"player";};
			Hidden = false;
			Description = "Makes the target player(s) an admin; Saves";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr, args, data)
				local sendLevel = data.PlayerData.Level
				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					local targLevel = Admin.GetLevel(v)
					if sendLevel>targLevel then
						Admin.AddAdmin(v,2)
						Remote.MakeGui(v,"Notification",{
							Title = "Notification";
							Message = "You are an administrator. Click to view commands.";
							Time = 10;
							OnClick = Core.Bytecode("client.Remote.Send('ProcessCommand','"..Settings.Prefix.."cmds')");
						})
						Functions.Hint(v.Name..' is now an admin',{plr})
					else
						Functions.Hint(v.Name.." is the same admin level as you or higher",{plr})
					end
				end
			end
		};
		
		CustomRank = {
			Prefix = Settings.Prefix;
			Commands = {"customrank","ca","crank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Adds the player to a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")

				local rank = args[2]
				local customRank = Settings.CustomRanks[rank]

				assert(customRank,"Rank not found!")

				for i,v in pairs(service.GetPlayers(plr,args[1])) do
					Functions.Hint("Added "..v.Name.." to "..rank,{plr})
					table.insert(customRank,v.Name..":"..v.userId)
				end
			end
		};

		UnCustomRank = {
			Prefix = Settings.Prefix;
			Commands = {"uncustomrank","unca","uncrank"};
			Args = {"player";"rankName"};
			Hidden = false;
			Description = "Removes the player from a custom rank set in settings.CustomRanks; Does not save";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1] and args[2],"Argument missing or nil")

				local rank = args[2]
				local customRank = Settings.CustomRanks[rank]

				assert(customRank,"Rank not found!")

				service.Iterate(customRank,function(i,v)
					if v:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(customRank,i)
						Functions.Hint("Removed "..v.Name.." from "..rank,{plr})
					end
				end)
			end
		};

		CustomRanks = {
			Prefix = Settings.Prefix;
			Commands = {"customranks","cranks"};
			Args = {};
			Hidden = false;
			Description = "Shows custom ranks";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local tab = {}
				service.Iterate(Settings.CustomRanks,function(rank,tab)
					table.insert(tab,{Text = rank, Desc = rank})
				end)
				Remote.MakeGui(plr,"List",{Title = "Custom Ranks";Table = tab})
			end
		};
		
		DataBan = {
			Prefix = Settings.Prefix;
			Commands = {"databan";"permban";"gameban"};
			Args = {"player"; "reason"};
			Hidden = false;
			Description = "Data persistent ban the target player(s); Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				local reason = args[2] or "No Reason Provided"
				for i,v in pairs(service.GetPlayers(plr,args[1],false,false,true)) do
					if not Admin.CheckAdmin(v) then
						local ans = Remote.MakeGuiGet(plr,"YesNoPrompt",{
							Question = "Are you sure you want to ban "..v.Name
						})

						if ans == "Yes" then
							local PlayerData = Core.GetPlayer(v)
							PlayerData.Banned = true
							Admin.AddBan(v, "GAME", plr, os.time(), reason, "Permanent")
							Functions.Hint("Data Banned "..tostring(v),{plr})
						end
					else
						error(v.Name.." is currently an admin. Unadmin them before trying to perm ban them (this is so you don't accidentally ban an admin)")
					end
				end
			end
		};
		
		UnDataBan = {
			Prefix = Settings.Prefix;
			Commands = {"undataban";"undban";"untban";"unpermban";};
			Args = {"userid";};
			Hidden = false;
			Description = "Removes any data persistence bans (timeban or permban)";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1],"Argument missing or nil")

				local userId = tonumber(args[1])
				assert(userId,tostring(userId).." is not a valid user ID")
				local PlayerData = Core.GetData(tostring(userId))
				assert(PlayerData,"No saved data found for "..userId)
				PlayerData.TimeBan = false
				PlayerData.Banned = false
				Core.SaveData(tostring(userId),PlayerData)
				Functions.Hint("Removed data ban for "..userId,{plr})
			end
		};
		
		TimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"tban";"timedban";"timeban";};
			Args = {"player";"number<s/m/h/d>"; "reason";};
			Hidden = false;
			Description = "Bans the target player(s) for the supplied amount of time; Data Persistent; Undone using :undataban";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args,data)
				local time = args[2] or '60'
				local reason = args[3] or "No Reason Provided"
				assert(args[1] and args[2], "Argument missing or nil")
				if time:lower():sub(#time)=='s' then
					time = time:sub(1,#time-1)
					time = tonumber(time)
				elseif time:lower():sub(#time)=='m' then
					time = time:sub(1,#time-1)
					time = tonumber(time)*60
				elseif time:lower():sub(#time)=='h' then
					time = time:sub(1,#time-1)
					time = (tonumber(time)*60)*60
				elseif time:lower():sub(#time)=='d' then
					time = time:sub(1,#time-1)
					time = ((tonumber(time)*60)*60)*24
				end

				local level = data.PlayerData.Level;
				for i,v in next,service.GetPlayers(plr, args[1], false, false, true) do
					if level > Admin.GetLevel(v) then
						local endTime = tonumber(os.time())+tonumber(time)
						
						Admin.AddBan(v, "TIME", plr, os.time(), reason, endTime)
						Functions.Hint("Banned "..v.Name.." for "..time,{plr})
					end
				end
			end
		};

		UnTimeBan = {
			Prefix = Settings.Prefix;
			Commands = {"untimeban";};
			Args = {"player";};
			Hidden = false;
			Description = "UnBan";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				assert(args[1], "Argument missing or nil")
				local timebans = Admin.TimeBans or {}
				for i, data in next, timebans do
					if data.Name:lower():sub(1,#args[1]) == args[1]:lower() then
						table.remove(timebans, i)
						Core.DoSave({
							Type = "TableRemove";
							Table = "TimeBans";
							Parent = "Admin";
							Value = data;
						})
						Functions.Hint(tostring(data.Name)..' has been Unbanned',{plr})
					end
				end
			end
		};
		
		GameBan = {
			Prefix = Settings.Prefix;
			Commands = {"gameban", "saveban", "databan"};
			Args = {"player";};
			Description = "Bans the player from the game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args,data)
				local level = data.PlayerData.Level
				local reason = args[2] or "No Reason Provided"
				for i,v in next,service.GetPlayers(plr,args[1],false,false,true) do
					if level > Admin.GetLevel(v) then
						Admin.AddBan(v, "GAME", plr, os.time(), reason, "Permanent")
						Functions.Hint("Game banned "..tostring(v),{plr})
					end
				end
			end
		};

		UnGameBan = {
			Prefix = Settings.Prefix;
			Commands = {"ungameban", "saveunban", "undataban"};
			Args = {"player";};
			Description = "UnBans the player from game (Saves)";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local ret = Admin.RemoveBan(args[1], true)
				if ret then
					Functions.Hint(tostring(ret)..' has been Unbanned',{plr})
				end
			end
		};
		
		FullShutdown = {
			Prefix = Settings.Prefix;
			Commands = {"fullshutdown"};
			Args = {"reason"};
			Description = "Initiates a shutdown for every running game server";
			PanicMode = true;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not Core.PanicMode then
					local logs = Core.GetData("ShutdownLogs") or {}
					if plr then
						table.insert(logs,1,{User=plr.Name,Time=service.GetTime(),Reason=args[2] or "N/A"})
					else
						table.insert(logs,1,{User="Server/Trello",Time=service.GetTime(),Reason=args[2] or "N/A"})
					end
					if #logs>1000 then
						table.remove(logs,#logs)
					end
					Core.SaveData("ShutdownLogs",logs)
				end

				Core.SaveData("FullShutdown", {ID = game.PlaceId; User = tostring(plr or "Server"); Reason = args[2]})
			end
		};
		
		GlobalMessage = {
			Prefix = Settings.Prefix;
			Commands = {"globalmessage","gm","globalannounce"};
			Args = {"message"};
			Description = "Sends a global message to all servers";
			AdminLevel = "Owners";
			Filter = true;
			CrossServerDenied = true;
			Function = function(plr,args)
				assert(args[1], "Argument #1 must be supplied")

				if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, Settings.Prefix.."m "..args[1]) then
					error("CrossServer Handler Not Ready");
				end
			end;	
		};
		
		MakeList = {
			Prefix = Settings.Prefix;
			Commands = {"makelist";"newlist";"newtrellolist";"maketrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Adds a list to the Trello board set in Settings. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.Boards.MakeList(Settings.Trello_Primary,args[1])
				Functions.Hint("Made list "..list.name,{plr})
			end
		};

		ViewList = {
			Prefix = Settings.Prefix;
			Commands = {"viewlist";"viewtrellolist";};
			Args = {"name";};
			Hidden = false;
			Description = "Views the specified Trello list from the board set in Settings.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if not args[1] then error("Missing argument") end
				local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
				local list = trello.Boards.GetList(Settings.Trello_Primary,args[1])
				if not list then error("List not found.") end
				local cards = trello.Lists.GetCards(list.id)
				local temp = {}
				for i,v in pairs(cards) do
					table.insert(temp,{Text=v.name,Desc=v.desc})
				end
				Remote.MakeGui(plr,"List",{Title = list.name; Tab = temp})
			end
		};

		MakeCard = {
			Prefix = Settings.Prefix;
			Commands = {"makecard", "maketrellocard", "createcard"};
			Args = {};
			Hidden = false;
			Description = "Opens a gui to make new Trello cards. AppKey and Token MUST be set and have write perms for this to work.";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeGui(plr,"CreateCard")
			end
		};
		
		FullClear = {
			Prefix = Settings.Prefix;
			Commands = {"fullclear";"clearinstances";"fullclr";};
			Args = {};
			Description = "Removes any instance created server-side by Adonis; May break things";
			AdminLevel = "Owners";
			Function = function(plr,args)
				local objects = service.GetAdonisObjects()

				for i,v in next,objects do
					v:Destroy()
					table.remove(objects, i)
				end

				--for i,v in next,Functions.GetPlayers() do
				--	Remote.Send(v, "Function", "ClearAllInstances")
				--end
			end
		};
		
		BackupMap = {
			Prefix = Settings.Prefix;
			Commands = {"backupmap";"mapbackup";"bmap";};
			Args = {};
			Hidden = false;
			Description = "Changes the backup for the restore map command to the map's current state";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				if plr then
					Functions.Hint('Updating Map Backup...',{plr})
				end

				if server.Variables.BackingupMap then
					error("Backup Map is in progress. Please try again later!")
					return
				end
				if server.Variables.RestoringMap then
					error("Cannot backup map while map is being restored!")
					return
				end

				server.Variables.BackingupMap = true

				local tempmodel = service.New('Model')

				for i,v in pairs(service.Workspace:GetChildren()) do
					if v and not v:IsA('Terrain') then
						wait()
						pcall(function()
							local archive = v.Archivable
							v.Archivable = true
							v:Clone(true).Parent = tempmodel
							v.Archivable = archive
						end)
					end
				end

				Variables.MapBackup = tempmodel:Clone()
				tempmodel:Destroy()
				Variables.TerrainMapBackup = service.Workspace.Terrain:CopyRegion(service.Workspace.Terrain.MaxExtents)

				if plr then
					Functions.Hint('Backup Complete',{plr})
				end

				server.Variables.BackingupMap = false

				Logs.AddLog(Logs.Script,{
					Text = "Backup Complete";
					Desc = "Map was successfully backed up";
				})
			end
		};

		Explore = {
			Prefix = Settings.Prefix;
			Commands = {"explore";"explorer";};
			Args = {};
			Hidden = false;
			Description = "Lets you explore the game, kinda like a file browser";
			Fun = false;
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeGui(plr,"Explorer")
			end
		};

		DexExplore = {
			Prefix = Settings.Prefix;
			Commands = {"dex";"dexexplorer";"dexexplorer"};
			Args = {};
			Description = "Lets you explore the game using Dex [Credit to Raspberry Pi/Raspy_Pi/raspymgx/OpenOffset(?)][Useless buttons disabled]";
			AdminLevel = "Owners";
			Function = function(plr,args)
				Remote.MakeLocal(plr,Deps.Assets.Dex_Explorer:Clone(),"PlayerGui")
			end
		};

		Tornado = {
			Prefix = Settings.Prefix;
			Commands = {"tornado";"twister";};
			Args = {"player";"optional time";};
			Description = "Makes a tornado on the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				for i,v in pairs(service.GetPlayers(plr, args[1])) do
					local p=service.New('Part',service.Workspace)
					table.insert(Variables.Objects,p)
					p.Transparency=1
					p.CFrame=v.Character.HumanoidRootPart.CFrame+Vector3.new(0,-3,0)
					p.Size=Vector3.new(0.2,0.2,0.2)
					p.Anchored=true
					p.CanCollide=false
					p.Archivable=false
					--local tornado=deps.Tornado:clone()
					--tornado.Parent=p
					--tornado.Disabled=false
					local cl=Core.NewScript('Script',[[
						local Pcall=function(func,...) local function cour(...) coroutine.resume(coroutine.create(func),...) end local ran,error=pcall(cour,...) if error then print('Error: '..error) end end
						local parts = {}
						local main=script.Parent
						main.Anchored=true
						main.CanCollide=false
						main.Transparency=1
						local smoke=Instance.new("Smoke",main)
						local sound=Instance.new("Sound",main)
						smoke.RiseVelocity=25
						smoke.Size=25
						smoke.Color=Color3.new(170/255,85/255,0)
						smoke.Opacity=1
						sound.SoundId="rbxassetid://142840797"
						sound.Looped=true
						sound:Play()
						sound.Volume=1
						sound.Pitch=0.8
						local light=Instance

						function fling(part)
							part:BreakJoints()
							part.Anchored=false
							local pos=Instance.new("BodyPosition",part)
							pos.maxForce = Vector3.new(math.huge,math.huge,math.huge)--10000, 10000, 10000)
							pos.position = part.Position
							local i=1
							local run=true
							while main and wait() and run do
								if part.Position.Y>=main.Position.Y+50 then
									run=false
								end
								pos.position=Vector3.new(50*math.cos(i),part.Position.Y+5,50*math.sin(i))+main.Position
								i=i+1
							end
							pos.maxForce = Vector3.new(500, 500, 500)
							pos.position=Vector3.new(main.Position.X+math.random(-100,100),main.Position.Y+100,main.Position.Z+math.random(-100,100))
							pos:Destroy()
						end

						function get(obj)
							if obj ~= main and obj:IsA("Part") then
								table.insert(parts, 1, obj)
							elseif obj:IsA("Model") or obj:IsA("Accoutrement") or obj:IsA("Tool") or obj == workspace then
								for i,v in pairs(obj:children()) do
									Pcall(get,v)
								end
								obj.ChildAdded:connect(function(p)Pcall(get,p)end)
							end
						end

						get(workspace)

						repeat
							for i,v in pairs(parts) do
								if (((main.Position - v.Position).magnitude * 250 * 20) < (5000 * 40)) and v and v:IsDescendantOf(workspace) then
									coroutine.wrap(fling,v)
								elseif not v or not v:IsDescendantOf(workspace) then
									table.remove(parts,i)
								end
							end
							main.CFrame = main.CFrame + Vector3.new(math.random(-3,3), 0, math.random(-3,3))
							wait()
					until main.Parent~=workspace or not main]])
					cl.Parent=p
					cl.Disabled=false
					if args[2] and tonumber(args[2]) then
						for i=1,tonumber(args[2]) do
							if not p or not p.Parent then
								return
							end
							wait(1)
						end
						if p then p:Destroy() end
					end
				end
			end
		};

		Nuke = {
			Prefix = Settings.Prefix;
			Commands = {"nuke";};
			Args = {"player";};
			Description = "Nuke the target player(s)";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local nukes = {}
				local partsHit = {}

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						local p = service.New("Part", {
							Name = "ADONIS_NUKE";
							Anchored = true;
							CanCollide = false;
							formFactor = "Symmetric";
							Shape = "Ball";
							Size = Vector3.new(1,1,1);
							Position = human.Position;
							BrickColor = BrickColor.new("New Yeller");
							Transparency = .5;
							Reflectance = .2;
							TopSurface = 0;
							BottomSurface = 0;
							Parent = service.Workspace;
						})

						p.Touched:Connect(function(hit)
							if not partsHit[hit] then
								partsHit[hit] = true
								hit:BreakJoints()
								service.New("Explosion", {
									Position = hit.Position;
									BlastRadius = 10000;
									BlastPressure = math.huge;
									Parent = service.Workspace;
								})

							end
						end)

						table.insert(Variables.Objects, p)
						table.insert(nukes, p)
					end
				end

				for i = 1, 333 do
					for i,v in next,nukes do
						local curPos = v.CFrame
						v.Size = v.Size + Vector3.new(3, 3, 3)
						v.CFrame = curPos
					end
					wait(1/44)
				end

				for i,v in next,nukes do
					v:Destroy()
				end

				nukes = nil
				partsHit = nil
			end
		};

		UnWildFire = {
			Prefix = Settings.Prefix;
			Commands = {"stopwildfire", "removewildfire", "unwildfire";};
			Args = {};
			Description = "Stops :wildfire from spreading further";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				Variables.WildFire = nil
			end
		};

		WildFire = {
			Prefix = Settings.Prefix;
			Commands = {"wildfire";};
			Args = {"player";};
			Description = "Starts a fire at the target player(s); Ignores locked parts and parts named 'BasePlate' or 'Baseplate'";
			AdminLevel = "Owners";
			Fun = true;
			Function = function(plr,args)
				local finished = false
				local partsHit = {}
				local objs = {}

				Variables.WildFire = partsHit

				function fire(part)
					if finished or not partsHit or not objs then
						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and Variables.WildFire ~= partsHit then
						for i,v in next,objs do
							v:Destroy()
						end

						objs = nil
						partsHit = nil
						finished = true
					elseif partsHit and objs and part:IsA("BasePart") and (not part.Locked or (part.Parent:IsA("Model") and service.Players:GetPlayerFromCharacter(part.Parent))) and part.Name ~= "BasePlate" and part.Name ~= "Baseplate" and not partsHit[part] then
						partsHit[part] = true

						local oColor = part.Color
						local fSize = (part.Size.X + part.Size.Y + part.Size.Z)
						local f = service.New("Fire", {
							Name = "WILD_FIRE";
							Size = fSize;
							Parent = part;
						})

						local l = service.New("PointLight", {
							Name = "WILD_FIRE";
							Range = fSize;
							Color = f.Color;
							Parent = part;
						})

						table.insert(objs, f)
						table.insert(objs, l)

						part.Touched:connect(fire)

						for i = 0.1, 1, 0.1 do
							part.Color = oColor:lerp(Color3.new(0, 0, 0), i)
							wait(math.random(5))
						end

						local ex = service.New("Explosion", {
							Position = part.Position;
							BlastRadius = fSize*2;
							BlastPressure = 0;
						})

						ex.Hit:connect(fire)
						ex.Parent = service.Workspace;
						part.Anchored = false
						part:BreakJoints()
						f:Destroy()
						l:Destroy()
					end
				end

				for i,v in next,Functions.GetPlayers(plr, args[1]) do
					local char = v.Character
					local human = char and char:FindFirstChild("HumanoidRootPart")
					if human then
						fire(human)
					end
				end

				partsHit = nil
			end
		};
	}
	
	for ind, com in pairs(Commands) do
		server.Commands[ind] = com
	end
end