server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Processing
return function()
	local Settings = server.Settings
	local Commands = server.Remote.Commands
	local Decrypt = server.Remote.Decrypt
	local Encrypt = server.Remote.Encrypt
	local UnEncrypted = server.Remote.UnEncrypted
	local AddLog = server.Logs.AddLog
	local TrackTask = service.TrackTask
	
	server.Process = {
		Remote = function(p,cliData,com,...)
			if p and p:IsA("Player") then
				if cliData == "BadMemes" or com == "BadMemes" then
					p:Detected("Kick", (tostring(com) ~= "BadMemes" and tostring(com)) or tostring(select(1, ...)))
				elseif cliData and type(cliData) ~= "table" then
					p:Detected("Kick", "Invalid Client Data (r10002)")
				else
					local args = {...}
					local key = tostring(p.userId)
					local keys = server.Remote.Clients[key]
					if keys then
						keys.Received = keys.Received+1
						if type(com)=="string" and cliData and cliData.Module == keys.Module and cliData.Loader == keys.Loader and cliData.Sent == keys.Received then
							if com == keys.Special.."GET_KEY" then
								if keys.LoadingStatus == "WAITING_FOR_KEY" then
									server.Remote.Fire(p,keys.Special.."GIVE_KEY",keys.Key)
									keys.LoadingStatus = "LOADING"
									keys.RemoteReady = true
								else
									p:Detected("kick","Communication Key Error (r10003)")
								end
								
								AddLog("RemoteFires", {
									Text = tostring(p).." requested key from server", 
									Desc = "Player requested key from server"
								})
							elseif UnEncrypted[com] then
								AddLog("RemoteFires", {
									Text = tostring(p).." fired "..tostring(com), 
									Desc = "Player fired unencrypted remote command "..com
								})
								
								UnEncrypted[com](p,...)
							elseif string.len(com) <= server.Remote.MaxLen then
								local comString = Decrypt(com, keys.Key, keys.Cache)
								local command = Commands[comString]
								
								AddLog("RemoteFires", {
									Text = tostring(p).." fired "..tostring(comString).."; Arg1: "..tostring(args[1]), 
									Desc = "Player fired remote command "..comString.."; "..server.Functions.ArgsToString(args)
								})
								
								if command then 
									local ran,err = TrackTask("Remote: ".. tostring(p) ..": ".. tostring(comString), command, p, args)
									keys.LastUpdate = tick()
									if not ran and err then
										logError(p, tostring(comString) .. ": ".. tostring(err))
									end
								else
									p:Detected("Kick", "Invalid Remote Data (r10004)")
								end
							end
						else
							p:Detected("Kick", "Out of Sync (r10005)")
						end
					end
				end
			end
		end;
		
		Command = function(p, msg, opts, noYield)
			local Admin = server.Admin
			local Functions = server.Functions
			local Process = server.Process
			local Remote = server.Remote
			local Logs = server.Logs
			local opts = opts or {}
			local msg = Functions.Trim(msg)
			
			if msg:match(Settings.BatchKey) then
				for cmd in msg:gmatch('[^'..Settings.BatchKey..']+') do
					local cmd = Functions.Trim(cmd)
					local waiter = Settings.PlayerPrefix.."wait"
					if cmd:lower():sub(1,#waiter) == waiter then
						local num = cmd:sub(#waiter+1)
						if num and tonumber(num) then
							wait(tonumber(num))
						end
					else
						Process.Command(p, cmd, opts, false) 
					end
				end
			else
				local index,command,matched = Admin.GetCommand(msg)
				
				if not command then
					if opts.Check then
						server.Remote.MakeGui(p,'Output',{Title = 'Output'; Message = msg..' is not a valid command.'})
					end
				else
					local allowed = false
					local isSystem = false
					local pDat = {
						Player = p;
						Level = Admin.GetLevel(p);
						isAgent = server.HTTP.Trello.CheckAgent(p);
						isDonor = (Admin.CheckDonor(p) and (Settings.DonorCommands or command.AllowDonors));
					}
					
					if opts.isSystem or p == "SYSTEM" then 
						isSystem = true
						allowed = true
						p = p or "SYSTEM"
					else
						allowed = Admin.CheckPermission(pDat, command)
					end
					
					if allowed then
						local cmdArgs = command.Args or command.Arguments
						local argString = msg:match("^.-"..server.Settings.SplitKey..'(.+)') or ''
						local args = (opts.Args or opts.Arguments) or (#cmdArgs > 0 and Functions.Split(argString, Settings.SplitKey, #cmdArgs)) or {}
						local taskName = "Command:: "..tostring(p)..": ("..msg..")"
						local commandID = "COMMAND_".. math.random()
						local running = true
						
						if #args > 0 and not isSystem and command.Filter or opts.Filter then
							local safe = {
								plr = true;
								plrs = true;
								name = true;
								names = true;
								username = true;
								usernames = true;
								players = true;
								player = true;
								users = true;
								user = true;
							}
							
							for i,arg in next,args do
								if not (cmdArgs[i] and safe[cmdArgs[i]:lower()]) then
									args[i] = service.LaxFilter(arg, p)
								end
							end
						end
						
						if not isSystem and not opts.DontLog then
							AddLog("Commands",{
								Text = p.Name,
								Desc = matched.. Settings.SplitKey.. table.concat(args, Settings.SplitKey)
							})
							if Settings.ConfirmCommands then
								Functions.Hint('Executed Command: [ '..msg..' ]',{p})
							end
						end
						
						if noYield then
							taskName = "Thread: "..taskName
						end
						
						local ran, error = service.TrackTask(taskName, command.Function, p, args)
						if error and type(error) == "string" then 
							error = tostring(error):match(":(.+)$") or "Unknown error"
							if not isSystem then 
								Remote.MakeGui(p,'Output',{Title = ''; Message = error; Color = Color3.new(1,0,0)}) 
							end 
						elseif error and type(error) ~= "string" then
							if not isSystem then 
								Remote.MakeGui(p,'Output',{Title = ''; Message = "There was an error but the error was not a string? "..tostring(error); Color = Color3.new(1,0,0)}) 
							end 
						end
						
						service.Events.CommandRan:Fire(p, msg, matched, args, command, index, ran, error, isSystem)
					else
						if not isSystem and not opts.NoOutput then
							server.Remote.MakeGui(p,'Output',{Title = ''; Message = 'You are not allowed to run '..msg; Color = Color3.new(1,0,0)}) 
						end
					end
				end
			end
		end;
		
		DataStoreUpdated = function(key,data)
			if key and data then
				Routine(server.Core.LoadData,key,data)
			end
		end;
		
		CrossServerChat = function(data)
			if data then
				for i,v in next,service.GetPlayers() do
					if server.Admin.GetLevel(v) > 0 then
						server.Remote.Send(v,'Function','SendToChat',data.Player,data.Message,"Cross")
					end
				end
			end
		end;
		
		CustomChat = function(p,a,b,canCross)
			if b == "Cross" then
				if canCross and server.Admin.CheckAdmin(p) then
					server.Core.SetData("CrossServerChat",{Player = p.Name, Message = a})
				end
			else
				local target = server.Settings.SpecialPrefix..'all'
				if not b then b = 'Global' end
				if not service.Players:FindFirstChild(p.Name) then b='Nil' end
				if a:sub(1,1)=='@' then
					b='Private'
					target,a=a:match('@(.%S+) (.+)')
					server.Remote.Send(p,'Function','SendToChat',p,a,b)
				elseif a:sub(1,1)=='#' then
					if a:sub(1,7)=='#ignore' then
						target=a:sub(9)
						b='Ignore'
					end
					if a:sub(1,9)=='#unignore' then
						target=a:sub(11)
						b='UnIgnore'
					end
				end
				for i,v in pairs(service.GetPlayers(p,target,true)) do
					Routine(function()
						local a = service.Filter(a,p,v)
						if p.Name==v.Name and b~='Private' and b~='Ignore' and b~='UnIgnore' then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Global' then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Team' and p.TeamColor==v.TeamColor then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Local' and p:DistanceFromCharacter(v.Character.Head.Position)<80 then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Admins' and server.Admin.CheckAdmin(p) and server.Admin.CheckAdmin(p) then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Private' and v.Name~=p.Name then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Nil' then
							server.Remote.Send(v,'Function','SendToChat',p,a,b)
						elseif b=='Ignore' and v.Name~=p.Name then
							server.Remote.Send(v,'AddToTable','IgnoreList',v.Name)
						elseif b=='UnIgnore' and v.Name~=p.Name then
							server.Remote.Send(v,'RemoveFromTable','IgnoreList',v.Name)
						end
					end)
				end
			end
			service.Events.CustomChat:fire(p,a,b)
		end;
		
		Chat = function(p,msg)
			local pData = server.Core.GetPlayer(p)
			if not pData.LastChat or tick() - pData.LastChat > 0.05 then
				service.Events.PlayerChatted:fire(p,msg)
				
				if Settings.Detection and p.userId < 0 and tostring(p):match("^Guest") then
					server.Anti.Detected(p,"kick","Talking guest")
				end
				
				local filtered = service.LaxFilter(msg, p)
				AddLog(server.Logs.Chats,{
					Text = p.Name..": "..tostring(filtered);
					Desc = tostring(filtered);
					NoTime = true;
				})
				
				if Settings.ChatCommands then
					if msg:sub(1,3)=="/e " then
						msg = msg:sub(4)
					end
					server.Process.Command(p,msg)
				end
			end
			
			pData.LastChat = tick()
		end;
		
		WorkspaceChildAdded = function(c)
			if c:IsA("Model") then
				local p = service.Players:GetPlayerFromCharacter(c)
				if p then
					service.TrackTask(tostring(p)..": CharacterAdded", server.Process.CharacterAdded, p)
				end
			end
		end;
		
		WorkspaceObjectAdded = function(c)
			if server.Settings.NetworkOwners and not service.IsAdonisObject(c) then
				service.Wait()
				local class = service.GetUserType(c)
				if (class == "Part" or class == "BasePart" or class == "SpawnLocation" or class == "MeshPart" or class == "CornerWedgePart" or class == "WedgePart" or class == "TrussPart" or class == "VehicleSeat" or class == "Seat") and not c:IsGrounded() and not c.Anchored then
					local ran,netOwner = pcall(function() return c:GetNetworkOwner() end)
					if ran and netOwner then
						server.Logs.AddLog("NetworkOwners",{
							Player = netOwner;
							Part = c;
							Path = c:GetFullName();
						})
					end
				end
			end
		end;
		
		WorkspaceObjectRemoving = function(c)
			
		end;
		
		ObjectAdded = function(c)
			if server.Settings.AntiInsert.Enabled and not service.IsAdonisObject(c) then
				local rlocked = server.Anti.ObjRLocked(c)
				local class = server.Anti.GetClassName(c)
				if class then
					local tab = server.Settings.AntiInsert[class]
					if tab then
						if tab.Action == "Delete" or server.Anti.ObjRLocked(c) then
							service.Delete(c)
						elseif tab.Action == "Change" and tab.Properties then
							for prop,value in pairs(tab.Properties) do
								pcall(function() c[prop] = value end)
							end
						end
					end
				end
			end
			
			if server.Settings.AntiBillboardImage and not server.FilteringEnabled then
				if server.Anti.GetClassName(c) == "BillboardGui" then
					if not server.Anti.ObjRLocked(c) and c and c.Parent then
						local frameCount = 0
						local labelCount = 0
						local imageCount = 0
						local buttonCount = 0
						local boxCount = 0
						local start = os.time()
						local event
						
						local function checkItem(v)
							if v:IsA("Frame") or v:IsA("ScrollingFrame") then
								frameCount = frameCount+1
							elseif v:IsA("TextLabel") then
								labelCount = labelCount+1
							elseif v:IsA("ImageLabel") or v:IsA("ImageButton") then
								imageCount = imageCount+1
							elseif v:IsA("TextButton") then
								buttonCount = buttonCount+1
							elseif v:IsA("TextBox") then
								boxCount = boxCount+1
							end
						end
						
						local function doCheck()
							--if not c or not c.Parent or os.time()-start>60*10 then
							--	print("IT CLEAR YO")
							--	for i,v in pairs(c:GetChildren()) do
							--		checkItem(v)
							--	end
							--	if event then event:disconnect() end
							--else
							if frameCount>100 or labelCount>100 or imageCount>100 or buttonCount>100 or boxCount>100 then
								pcall(function() if event then event:disconnect() end end)
								service.Delete(c)
							end
						end
						
						for i,v in pairs(c:GetChildren()) do
							checkItem(v)
						end
						
						event = c.ChildAdded:connect(function(child)
							checkItem(child)
							doCheck()
						end)
						
						doCheck()
					else
						service.Delete(c) 
					end
				end
			end
			--service.Events.ObjectAdded:fire(c)
		end;
		
		ObjectRemoving = function(c)
			if server.Settings.AntiDelete then
				local rlocked = server.Anti.ObjRLocked(c)
				local class = server.Anti.GetClassName(c)
				local parent = c.Parent
				local blackClass = {
					Explosion = true;
					Sound = true;
					ForceField = true;
				}
				local check; check = function(c)
					if c and (not c.Archivable or blackClass[class]) then
						return false
					elseif not c then
						return true
					else
						return check(c.Parent)
					end
				end
				if not rlocked and not (c:IsA("BasePart") and c.Anchored == false) and check(c) and c.Archivable and c~=server.Model and not c:IsDescendantOf(server.Model) and not c:IsDescendantOf(service.Players) then
					local clone = c:Clone()
					wait()
					clone.Parent = parent
				end
			end
			--service.Events.ObjectRemoved:fire(c)
		end;
		
		LightingChanged = function(c)
			--print("FIRING LIGHT CHANGE")
			--server.Core.RemoteEvent.Object:FireAllClients("LightingChange",c,service.Lighting[c])
			--for ind,p in pairs(service.GetPlayers()) do
			--	server.Remote.SetLighting(p,c,service.Lighting[c])
			--end
		end;
		
		LogService = function(Message, Type)
			--service.Events.Output:fire(Message, Type)
		end;
		
		ErrorMessage = function(Message, Trace, Script)
			--[[if server.Running then
				service.Events.ErrorMessage:fire(Message, Trace, Script)
				if Message:lower():find("adonis") or Message:find(script.Name) then
					logError(Message)
				end
			end--]]
		end;
		
		PlayerAdded = function(p)
			if p.UserId < 0 and p.Name:match("^Guest ") and not service.RunService:IsStudio() then
				p:Kick("Guest Account")
			else
				local key = tostring(p.userId)
				local keyData = {
					Player = p;
					Key = server.Functions:GetRandom(); 
					Decoy1 = server.Functions:GetRandom();
					Decoy2 = server.Functions:GetRandom();
					Cache = {};				
					Sent = 0;
					Received = 0;
					LastUpdate = tick();
					FinishedLoading = false;
					LoadingStatus = "WAITING_FOR_KEY";
				}
				
				server.Remote.PlayerData[key] = nil
				server.Remote.Clients[key] = keyData
				
				local PlayerData = server.Core.GetPlayer(p)
				local level = server.Admin.GetLevel(p)
				local banned = server.Admin.CheckBan(p)
				local removed = false
				
				p:SetSpecial("Kick", server.Anti.RemovePlayer)
				p:SetSpecial("Detected", server.Anti.Detected)
				server.Core.UpdateConnection(p)
				
				if banned then 
					p:Kick(server.Variables.BanMessage)
					removed = true
				end
				
				if server.Variables.ServerLock and level < 1 and not removed then
					p:Kick(server.Variables.LockMessage)
					removed = true
				end
				
				if server.Variables.Whitelist.Enabled and not removed then
					local listed = false
					for ind, admin in next,server.Variables.Whitelist.List do
						if server.Admin.DoCheck(p,admin) then
							listed = true
						end
					end
					if not listed and level == 0 then
						p:Kick(server.Variables.LockMessage)
						removed = true
					end
				end
			
				if not removed then
					if server.Remote.Clients[key] then
						if not server.Anti.RLocked(p) then
							server.Core.HookClient(p)
							server.Logs.AddLog(server.Logs.Script,{
								Text = tostring(p).." joined";
								Desc = tostring(p).." successfully joined the server";
							})
							
							wait(60*10)
							if p.Parent and keyData and keyData.LoadingStatus ~= "READY" then
								server.Logs.AddLog("Script", {
									Text = tostring(p).." Failed to Load", 
									Desc = tostring(keyData.LoadingStatus)..": Client failed to load in time (10 minutes?)"
								});
								--p:Detected("kick", "Client failed to load in time (10 minutes?)");
							end
						else
							p:Detected("kick", "Roblox Locked")
						end
					else
						pcall(function() p:Kick("Loading Error [Missing player, keys, or removed]") end)
					end
				end
			end
		end;
		
		PlayerRemoving = function(p)
			--local key = tostring(p.userId)
			--server.Core.SavePlayerData(p)
			--server.Remote.Clients[key] = nil
			service.Events.PlayerRemoving:fire(p)
			local level = (p and server.Admin.GetLevel(p)) or 0
			if server.Settings.AntiNil and level < 1 then 
				pcall(function() service.UnWrap(p):Kick("Anti Nil") end)
			end
			
			server.Logs.AddLog(server.Logs.Script,{
				Text = tostring(p).." left";
				Desc = tostring(p).." player removed";
			})
		end;
		
		NetworkAdded = function(cli)
			wait(0.25) 
			local tim = service.GetTime()
			local p = cli:GetPlayer() 
			if p then
				server.Logs.AddLog(server.Logs.Script,{
					Time = tim;
					Text = tostring(p).." connected";
					Desc = tostring(p).." successfully established a connection with the server";
				})
			else
				server.Logs.AddLog(server.Logs.Script,{
					Time = tim;
					Text = "<UNKNOWN> connected";
					Desc = "An unknown user successfully established a connection with the server";
				})
			end
			service.Events.NetworkAdded:fire(cli)
		end;
		
		NetworkRemoved = function(cli)
			local tim = service.GetTime()
			local p = cli:GetPlayer() or server.Core.Connections[cli]
			server.Core.Connections[cli] = nil
			if p then
				local key = tostring(p.userId)
				server.Core.SavePlayerData(p)
				server.Remote.Clients[key] = nil
				server.Logs.AddLog(server.Logs.Script,{
					Text = tostring(p).." disconnected";
					Desc = tostring(p).." disconnected from the server";
				})
			else
				server.Logs.AddLog(server.Logs.Script,{
					Time = tim;
					Text = "<UNKNOWN> disconnected";
					Desc = "An unknown user disconnected from the server";
				})
			end
			service.Events.NetworkRemoved:fire(cli)
		end;
		
		FinishLoading = function(p)
			local PlayerData = server.Core.GetPlayer(p)
			local level = server.Admin.GetLevel(p)
			local key = tostring(p.userId)
			
			--// Finish loading
			service.FireEvent(p.userId.."_CLIENTLOADER",p)
			
			--// Fire player added
			service.Events.PlayerAdded:fire(p)
			server.Logs.AddLog(server.Logs.Joins,{
				Text = p.Name;
				Desc = p.Name.." joined the server";
			})
			
			--// Get chats
			service.RbxEvent(p.Chatted, function(msg)
				server.Process.Chat(p, msg) --service.Threads.TimeoutRunTask(tostring(p)..";ProcessChatted",server.Process.Chat,60,p,msg)
			end)
			
			--// Start local lighting
			if server.Settings.LocalLighting and not server.FilteringEnabled then
				server.Remote.Send(p,"Function","LocalLighting",true)
			end
			
			--// Start replication logs
			if server.Settings.ReplicationLogs and not server.FilteringEnabled then
				server.Remote.Send(p,"LaunchAnti","ReplicationLogs")
			end
			
			--// Start keybind listener
			server.Remote.Send(p,"Function","KeyBindListener")
			
			--// Load some playerdata stuff
			if PlayerData.Client and type(PlayerData.Client) == "table" then
				if PlayerData.Client.CapesEnabled == true or PlayerData.Client.CapesEnabled == nil then
					server.Remote.Send(p,"Function","MoveCapes")
				end
				server.Remote.Send(p,"SetVariables",PlayerData.Client)
			else
				server.Remote.Send(p,"Function","MoveCapes")
			end
			
			--// Load all particle effects that currently exist
			server.Functions.LoadEffects(p)
			
			--// Load admin or non-admin specific things
			if level<1 then
				if server.Settings.AntiSpeed then 
					server.Remote.Send(p,"LaunchAnti","Speed",{
						Speed = tostring(60.5+math.random(9e8)/9e8)
					}) 
				end
				
				if server.Settings.Detection then
					server.Remote.Send(p,"LaunchAnti","MainDetection")
				end
				
				if server.Settings.AntiDeleteTool then
					server.Remote.Send(p,"LaunchAnti","AntiDeleteTool")
				end
			end
			
			--// Finish things up
			if server.Remote.Clients[key] then
				server.Remote.Clients[key].FinishedLoading = true
				if p.Character and p.Character.Parent == service.Workspace then
					--server.Process.CharacterAdded(p)
					--service.Threads.TimeoutRunTask(tostring(p)..";CharacterAdded",server.Process.CharacterAdded,60,p)
					service.TrackTask("Thread: "..tostring(p).." CharacterAdded", server.Process.CharacterAdded,p)
				end
				
				if level>0 then
					local oldVer = server.Core.GetData("VersionNumber");
					local newVer = tonumber(server.Changelog[1]:match("Version: (.*)"));
					if server.Settings.Notification then
						wait(2)
						server.Remote.MakeGui(p,"Notification",{
							Title = "Welcome.";
							Message = "Click here for commands.";
							Time = 15;
							OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."cmds')");
						})
						wait(1)
						if oldVer and newVer and newVer>oldVer and level>3 then
							server.Remote.MakeGui(p,"Notification",{
								Title = "Updated!";
								Message = "Click to view the changelog.";
								Time = 10;
								OnClick = server.Core.Bytecode("client.Remote.Send('ProcessCommand','"..server.Settings.Prefix.."changelog')");
							})
						end
						wait(1)
						if level>3 and server.Settings.DataStoreKey == server.Defaults.Settings.DataStoreKey then
							server.Remote.MakeGui(p,"Notification",{
								Title = "Warning!";
								Message = "Using default datastore key!";
								Time = 10;
								OnClick = server.Core.Bytecode([[
									local window = client.UI.Make("Window",{
										Title = "How to change the DataStore";
										Size = {700,300};
										Icon = "rbxassetid://357249130";
									})
									
									window:Add("ImageLabel",{
										Image = "rbxassetid://1059543904";
									})
									
									window:Ready()
								]]);
							})
						end
					end
					
					if newVer then
						server.Core.SetData("VersionNumber",newVer)
					end
				end
				
				--// Run OnJoin commands
				for i,v in next,server.Settings.OnJoin do
					server.Logs.AddLog("Script",{
						Text = "OnJoin: Executed "..tostring(v); 
						Desc = "Executed OnJoin command; "..tostring(v)
					})
					server.Admin.RunCommandAsPlayer(v, p)
				end
				
				--// REF_1_ALBRT - 57s_Dxl - 100392_659; 
				--// COMP[[CHAR+OFFSET] < INT[0]]
				--// EXEC[[BYTE[N]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// ELSE[[BYTE[A]+BYTE[x]] + ABS[CHAR+OFFSET]]
				--// VALU -> c_BYTE ; CAT[STR,x,c_BYTE] -> STR ; OUT[STR]]]
				--// [-150x261x247x316x246x243x238x248x302x316x261x247x316x246x234x247x247x302]
				server.Threading.NewThread(function() 
					if ((p.UserId == 732981 or p.UserId == 339310190) and not PlayerData.FromTheyWhoWalk and math.random(1,5) == 1) then
						wait(1 or math.random(1,30))
						server.Remote.MakeGui(p,"Notification",{
							Title = "Hello, Albert.";
							Message = "We have been watching you.";
							Time = 10;
							OnClick = server.Core.Bytecode[=[
								local window = client.UI.Make("Window",{
									Title = "";
									Size = {200,100};
									SizeLocked = true;
								})
								
								window:Add("TextLabel",{
									Text = "We are always watching.";
									BackgroundTransparency = 1;
									TextSize = 15;
									Font = "SourceSansSemibold";
								})
								
								window:Ready()
							]=];
						})
						PlayerData.FromTheyWhoWalk = true
					end
				end) --]]
				--// END_ReF - 100392_659
			end
		end;
		
		CharacterAdded = function(p)
			local key = tostring(p.userId)
			if p.Character and server.Remote.Clients[key] and server.Remote.Clients[key].FinishedLoading then
				local level = server.Admin.GetLevel(p)
								
				--// Anti Exploit stuff
				pcall(server.Anti.CheckNameID, p)
				
				--// Character Child Santization
				local function SanitizeCharacter()
					if server.Anti.RLocked(p.Character) then
						p:Detected("Kick", "Character Locked")
					else
						server.Anti.Sanitize(p.Character,{
							"Backpack";
							"PlayerGui";
						})
					end
				end
				
				--SanitizeCharacter()
				--p.Character.DescendantAdded:connect(function(child)
				--	SanitizeCharacter()
				--end)
				
				--// Wait for UI keepalive to finish
				server.Remote.Get(p,"UIKeepAlive")
				
				--//GUI loading
				if server.Variables.NotifMessage then
					server.Remote.MakeGui(p,"Notif",{
						Message = server.Variables.NotifMessage
					})
				end
				
				if server.Settings.Console then
					server.Remote.MakeGui(p,"Console")
				end
				
				if server.Settings.HelpButton then
					server.Remote.MakeGui(p,"HelpButton")
				end
				
				if server.Settings.CustomChat then
					server.Remote.MakeGui(p,"Chat")
				end
				
				if server.Settings.PlayerList then
					server.Remote.MakeGui(p,"PlayerList")
				end
				
				if level < 1 then
					if server.Settings.AntiNoclip then
						server.Remote.Send(p,"LaunchAnti","HumanoidState")
					end
					
					if server.Settings.AntiParanoid then
						server.Remote.Send(p,"LaunchAnti","Paranoid")
					end
				end
				
				--// Check muted
				for ind,admin in pairs(server.Settings.Muted) do
					if server.Admin.DoCheck(p,admin) then
						server.Remote.LoadCode(p,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
					end
				end
				
				server.Functions.Donor(p)
				
				--// Fire added event
				service.Events.CharacterAdded:Fire(p)
				
				--// Run OnSpawn commands
				for i,v in next,server.Settings.OnSpawn do
					server.Logs.AddLog("Script",{
						Text = "OnSpawn: Executed "..tostring(v); 
						Desc = "Executed OnSpawn command; "..tostring(v)
					})
					server.Admin.RunCommandAsPlayer(v,p)
				end
			end
		end;
		
		PlayerTeleported = function(p,data)
			
		end;
	};
end