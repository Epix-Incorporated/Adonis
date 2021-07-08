server = nil
service = nil
cPcall = nil

--// Function stuff
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;

		Functions.Init = nil;
		Logs:AddLog("Script", "Functions Module Initialized")
	end;

	local function RunAfterPlugins(data)
			--// AutoClean
			if Settings.AutoClean then
				service.StartLoop("AUTO_CLEAN", Settings.AutoCleanDelay, Functions.CleanWorkspace, true)
			end

			Functions.RunAfterPlugins = nil;
			Logs:AddLog("Script", "Functions Module RunAfterPlugins Finished");
	end

	server.Functions = {
		Init = Init;
		RunAfterPlugins = RunAfterPlugins;
		PlayerFinders = {
			["me"] = {
				Match = "me";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					table.insert(players,plr)
					plus()
				end;
			};

			["all"] = {
				Match = "all";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local everyone = true
					if isKicking then
						for i,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p.Name:lower():sub(1,#msg)==msg:lower() then
								everyone = false
								table.insert(players,p)
								plus()
							end
						end
					end

					if everyone then
						for i,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};

			["@everyone"] = {
				Match = "@everyone";
				Absolute = true;
				Function = function(...)
					return Functions.PlayerFinders.all.Function(...)
				end
			};

			["others"] = {
				Match = "others";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in next,parent:GetChildren() do
						local p = getplr(v)
						if p ~= plr then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["random"] = {
				Match = "random";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					if #players>=#parent:GetChildren() then return end
					local rand = parent:GetChildren()[math.random(#parent:GetChildren())]
					local p = getplr(rand)

					for _,v in pairs(players) do
						if(v.Name == p.Name)then
							Functions.PlayerFinders.random.Function(msg, plr, parent, players, getplr, plus, isKicking)
							return;
						end
					end

					table.insert(players,p)
					plus();
				end;
			};

			["admins"] = {
				Match = "admins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in next,parent:GetChildren() do
						local p = getplr(v)
						if Admin.CheckAdmin(p,false) then
							table.insert(players, p)
							plus()
						end
					end
				end;
			};

			["nonadmins"] = {
				Match = "nonadmins";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in next,parent:GetChildren() do
						local p = getplr(v)
						if not Admin.CheckAdmin(p,false) then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["friends"] = {
				Match = "friends";
				Prefix = true;
				Absolute = true;
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					for i,v in next,parent:GetChildren() do
						local p = getplr(v)
						if p:IsFriendsWith(plr.userId) then
							table.insert(players,p)
							plus()
						end
					end
				end;
			};

			["@username"] = {
				Match = "@";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = tonumber(msg:match("@(.*)"))
					local foundNum = 0

					if matched then
						for i,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p and p.Name == matched then
								table.insert(players,p)
								plus()
								foundNum = foundNum+1
							end
						end
					end
				end;
			};

			["%team"] = {
				Match = "%";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("%%(.*)")
					if matched then
						for i,v in next,service.Teams:GetChildren() do
							if v.Name:lower():sub(1,#matched) == matched:lower() then
								for k,m in next,parent:GetChildren() do
									local p = getplr(m)
									if p.TeamColor == v.TeamColor then
										table.insert(players,p)
										plus()
									end
								end
							end
						end
					end
				end;
			};

			["$group"] = {
				Match = "$";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("%$(.*)")
					if matched and tonumber(matched) then
						for _,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p:IsInGroup(tonumber(matched)) then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};

			["id-"] = {
				Match = "id-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = tonumber(msg:match("id%-(.*)"))
					local foundNum = 0
					if matched then
						for _,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p and p.userId == matched then
								table.insert(players,p)
								plus()
								foundNum = foundNum+1
							end
						end

						if foundNum == 0 then
							local ran,name = pcall(function() return service.Players:GetNameFromUserIdAsync(matched) end)
							if ran and name then
								local fakePlayer = service.Wrap(service.New("Folder"))
								local data = {
									Name = name;
									ToString = name;
									ClassName = "Player";
									AccountAge = 0;
									CharacterAppearanceId = tostring(matched);
									UserId = tonumber(matched);
									userId = tonumber(matched);
									Parent = service.Players;
									Character = Instance.new("Model");
									Backpack = Instance.new("Folder");
									PlayerGui = Instance.new("Folder");
									PlayerScripts = Instance.new("Folder");
									Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
									IsA = function(ignore, arg) if arg == "Player" then return true end end;
								}
								for i,v in next,data do fakePlayer:SetSpecial(i, v) end
								table.insert(players, fakePlayer)
								plus()
							end
						end
					end
				end;
			};

			["displayname-"] = {
				Match = "displayname-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = tonumber(msg:match("displayname%-(.*)"))
					local foundNum = 0

					if matched then
						for _,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p and p.DisplayName == matched then
								table.insert(players,p)
								plus()
								foundNum = foundNum+1
							end
						end
					end
				end;
			};

			["team-"] = {
				Match = "team-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					print(1)
					local matched = msg:match("team%-(.*)")
					if matched then
						for i,v in next,service.Teams:GetChildren() do
							if v.Name:lower():sub(1,#matched) == matched:lower() then
								for k,m in next,parent:GetChildren() do
									local p = getplr(m)
									if p.TeamColor == v.TeamColor then
										table.insert(players, p)
										plus()
									end
								end
							end
						end
					end
				end;
			};

			["group-"] = {
				Match = "group-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("group%-(.*)")
					if matched and tonumber(matched) then
						for _,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p:IsInGroup(tonumber(matched)) then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};

			["-name"] = {
				Match = "-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("%-(.*)")
					if matched then
						local removes = service.GetPlayers(plr,matched,true)
						for i,v in next,players do
							for k,p in next,removes do
								if v.Name == p.Name then
									table.remove(players,i)
									plus()
								end
							end
						end
					end
				end;
			};

			["#number"] = {
				Match = "#";
				Function = function(msg, plr, ...)
					local matched = msg:match("%#(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid number!"})
						end

						for i = 1,num do
							Functions.PlayerFinders.random.Function(msg, plr, ...)
						end
					end
				end;
			};

			["radius-"] = {
				Match = "radius-";
				Function = function(msg, plr, parent, players, getplr, plus, isKicking)
					local matched = msg:match("radius%-(.*)")
					if matched and tonumber(matched) then
						local num = tonumber(matched)
						if not num then
							Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = "Invalid number!"})
						end

						for i,v in next,parent:GetChildren() do
							local p = getplr(v)
							if p ~= plr and plr:DistanceFromCharacter(p.Character.Head.Position) <= num then
								table.insert(players,p)
								plus()
							end
						end
					end
				end;
			};
		};

		GetChatService = function()
			local chatHandler = service.ServerScriptService:WaitForChild("ChatServiceRunner", 120);
			local chatMod = chatHandler and chatHandler:WaitForChild("ChatService", 120);

			if chatMod then
				return require(chatMod);
			end
		end;

		IsClass = function(obj, classList)
			for _,class in next,classList do
				if obj:IsA(class) then
					return true
				end
			end
		end;

		ArgsToString = function(args)
			local str = ""
			for i,arg in next,args do
				str = str.."Arg"..tostring(i)..": "..tostring(arg).."; "
			end
			return str
		end;

		GetPlayers = function(plr, names, dontError, isServer, isKicking, noID)
			local players = {}
			local prefix = Settings.SpecialPrefix
			if isServer then prefix = "" end
			local parent = service.NetworkServer or service.Players

			local function getplr(p)
				if p and p:IsA("Player") then
					return p
				elseif p and p:IsA('NetworkReplicator') then
					if p:GetPlayer()~=nil and p:GetPlayer():IsA('Player') then
						return p:GetPlayer()
					end
				end
			end

			local function checkMatch(msg)
				for ind, data in next, Functions.PlayerFinders do
					if not data.Level or (data.Level and Admin.GetLevel(plr) >= data.Level) then
						local check = ((data.Prefix and Settings.SpecialPrefix) or "")..data.Match
						if (data.Absolute and msg:lower() == check) or (not data.Absolute and msg:lower():sub(1,#check) == check:lower()) then
							return data
						end
					end
				end
			end

			if plr == nil then
				for i,v in pairs(parent:GetChildren()) do
					local p = getplr(v)
					if p then
						table.insert(players,p)
					end
				end
			elseif plr and not names then
				return {plr}
			else
				if names:lower():sub(1,2) == "##" then
					error("String passed to GetPlayers is filtered: "..tostring(names))
				else
					for s in names:gmatch('([^,]+)') do
						local plrs = 0
						local function plus()
							plrs = plrs+1
						end

						local matchFunc = checkMatch(s)
						if matchFunc then
							matchFunc.Function(s, plr, parent, players, getplr, plus, isKicking, isServer, dontError)
						else
							for i,v in next,parent:GetChildren() do
								local p = getplr(v)
								if p and p:IsA("Player") and p.DisplayName:lower():sub(1,#s) == s:lower() then
									table.insert(players,p)
									plus()
								end
							end

							if plrs == 0 then
								for i,v in next,parent:GetChildren() do
									local p = getplr(v)
									if p and p:IsA("Player") and p.Name:lower():sub(1,#s) == s:lower() then
										table.insert(players,p)
										plus()
									end
								end
							end

							if plrs == 0 then
								local ran,userid = pcall(function() return service.Players:GetUserIdFromNameAsync(s) end)
								if ran and tonumber(userid) then
									local fakePlayer = service.Wrap(service.New("Folder"))
									local data = {
										Name = s;
										ToString = s;
										ClassName = "Player";
										AccountAge = 0;
										CharacterAppearanceId = tostring(userid);
										UserId = tonumber(userid);
										userId = tonumber(userid);
										Parent = service.Players;
										Character = Instance.new("Model");
										Backpack = Instance.new("Folder");
										PlayerGui = Instance.new("Folder");
										PlayerScripts = Instance.new("Folder");
										Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
										IsA = function(ignore, arg) if arg == "Player" then return true end end;
									}
									for i,v in next,data do fakePlayer:SetSpecial(i, v) end
									table.insert(players, fakePlayer)
									plus()
								end
							end
						end

						if plrs == 0 and not dontError then
							Remote.MakeGui(plr,'Output',{Title = 'Output'; Message = 'No players matching '..s..' were found!'})
						end
					end
				end
			end

			--// The following is intended to prevent name spamming (eg. :re scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel,scel...)
			--// It will also prevent situations where a player falls within multiple player finders (eg. :re group-1928483,nonadmins,radius-50 (one player can match all 3 of these))
			local filteredList = {};
			local checkList = {};

			for i,v in next, players do
				if not checkList[v] then
					table.insert(filteredList, v);
					checkList[v] = true;
				end
			end

			return filteredList;
		end;

		GetRandom = function(pLen)
			--local str = ""
			--for i=1,math.random(5,10) do str=str..string.char(math.random(33,90)) end
			--return str
			local Len = (type(pLen) == "number" and pLen) or math.random(5,10) --// reru
			local Res = {};
			for Idx = 1, Len do
				Res[Idx] = string.format('%02x', math.random(126));
			end;
			return table.concat(Res)
		end;

		Base64Encode = function(data)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			return ((data:gsub('.', function(x)
				local r,b='',x:byte()
				for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
				return r;
			end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
				if (#x < 6) then return '' end
				local c=0
				for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
				return b:sub(c+1,c+1)
			end)..({ '', '==', '=' })[#data%3+1])
		end;

		Base64Decode = function(data)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			data = string.gsub(data, '[^'..b..'=]', '')
			return (data:gsub('.', function(x)
				if (x == '=') then return '' end
				local r,f='',(b:find(x)-1)
				for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
				return r;
			end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if (#x ~= 8) then return '' end
				local c=0
				for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
				return string.char(c)
			end))
		end;

		Hint = function(message,players,time)
			for i,v in pairs(players) do
				Remote.MakeGui(v,"Hint",{
					Message = message;
					Time = time;
				})
			end
		end;

		Message = function(title,message,players,scroll,tim)
			for i,v in pairs(players) do
				Remote.RemoveGui(v,"Message")
				Remote.MakeGui(v,"Message",{
					Title = title;
					Message = message;
					Scroll = scroll;
					Time = tim;
				})
			end
		end;

		Notify = function(title,message,players,tim)
			for i,v in pairs(players) do
				Remote.RemoveGui(v,"Notify")
				Remote.MakeGui(v,"Notify",{
					Title = title;
					Message = message;
					Time = tim;
				})
			end
		end;

		MakeWeld = function(a, b)
			local weld = service.New("ManualWeld", a)
			weld.Part0 = a
			weld.Part1 = b
			weld.C0 = a.CFrame:inverse() * b.CFrame
			return weld
		end;

		SetLighting = function(prop,value)
			if service.Lighting[prop]~=nil then
				service.Lighting[prop] = value
				Variables.LightingSettings[prop] = value
				for ind,p in pairs(service.GetPlayers()) do
					Remote.SetLighting(p,prop,value)
				end
			end
		end;

		LoadEffects = function(plr)
			for i,v in pairs(Variables.LocalEffects) do
				if (v.Part and v.Part.Parent) or v.NoPart then
					if v.Type == "Cape" then
						Remote.Send(plr,"Function","NewCape",v.Data)
					elseif v.Type == "Particle" then
						Remote.NewParticle(plr,v.Part,v.Class,v.Props)
					end
				else
					Variables.LocalEffects[i] = nil
				end
			end
		end;

		NewParticle = function(target,type,props)
			local ind = Functions.GetRandom()
			Variables.LocalEffects[ind] = {
				Part = target;
				Class = type;
				Props = props;
				Type = "Particle";
			}
			for i,v in next,service.Players:GetPlayers() do
				Remote.NewParticle(v,target,type,props)
			end
		end;

		RemoveParticle = function(target,name)
			for i,v in next,Variables.LocalEffects do
				if v.Type == "Particle" and v.Part == target and (v.Props.Name == name or v.Class == name) then
					Variables.LocalEffects[i] = nil
				end
			end
			for i,v in next,service.Players:GetPlayers() do
				Remote.RemoveParticle(v,target,name)
			end
		end;

		UnCape = function(plr)
			for i,v in pairs(Variables.LocalEffects) do
				if v.Type == "Cape" and v.Player == plr then
					Variables.LocalEffects[i] = nil
				end
			end
			for i,v in pairs(service.GetPlayers()) do
				Remote.Send(v,"Function","RemoveCape",plr.Character)
			end
		end;

		Cape = function(player,isdon,material,color,decal,reflect)
			material = material or "Neon"
			if not Functions.GetEnumValue(Enum.Material, material) then
				error("Invalid material value")
			end

			Functions.UnCape(player)
			local torso = player.Character:FindFirstChild("HumanoidRootPart")
			if torso then
				if type(color) == "table" then
					color = Color3.new(color[1],color[2],color[3])
				end

				local data = {
					Color = color;
					Parent = player.Character;
					Material = material;
					Reflectance = reflect;
					Decal = decal;
				}

				if (isdon and Settings.DonorCapes and Settings.LocalCapes) then
					Remote.Send(player,"Function","NewCape",data)
				else
					local ind = Functions.GetRandom()
					Variables.LocalEffects[ind] = {
						Player = player;
						Part = player.Character.HumanoidRootPart;
						Data = data;
						Type = "Cape";
					}
					for i,v in pairs(service.GetPlayers()) do
						Remote.Send(v,"Function","NewCape",data)
					end
				end
			end
		end;

		PlayAnimation = function(player, animId)
			if player.Character and tonumber(animId) then
				local human = player.Character:FindFirstChildOfClass("Humanoid")
				if human and not human:FindFirstChildOfClass("Animator") then
					service.New("Animator", human)
				end
				Remote.Send(player,"Function","PlayAnimation",animId)
			end
		end;

		GetEnumValue = function(enum, item)
			local valid = false
			for _,v in ipairs(enum:GetEnumItems()) do
				if v.Name == item then
					valid = v.Value
					break
				end
			end
			return valid
		end;

		ApplyBodyPart = function(character, model)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local rigType = humanoid.RigType == Enum.HumanoidRigType.R6 and "R6" or "R15"
				local part = model:FindFirstChild(rigType)

				if not part and rigType == "R15" then
					part = model:FindFirstChild("R15Fixed") -- some bundles dont have the normal R15 folder...
				end

				if part then
					if rigType == "R6" then
						local children = character:GetChildren()
						for _,v in pairs(part:GetChildren()) do
							for _,x in pairs(children) do
								if x:IsA("CharacterMesh") and x.BodyPart == v.BodyPart then
									x:Destroy()
								end
							end
							v:Clone().Parent = character
						end
					elseif rigType == "R15" then
						for _,v in pairs(part:GetChildren()) do
							local value = Functions.GetEnumValue(Enum.BodyPartR15, v.Name)
							if value then
								humanoid:ReplaceBodyPartR15(value, v:Clone())
							end
						end
					end
				end
			end
		end;

		GetJoints = function(character)
			local temp = {}
			for _,v in pairs(character:GetDescendants()) do
				if v:IsA("Motor6D") then
					temp[v.Name] = v -- assumes no 2 joints have the same name, hopefully this wont cause issues
				end
			end
			return temp
		end;

		LoadOnClient = function(player,source,object,name)
			if service.Players:FindFirstChild(player.Name) then
				local parent = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild('PlayerGui', 15) or player:WaitForChild('Backpack')
				local cl = Core.NewScript('LocalScript',source)
				cl.Name = name or Functions.GetRandom()
				cl.Parent = parent
				cl.Disabled = false
				if object then
					table.insert(Variables.Objects,cl)
				end
			end
		end;

		Split = function(msg,key,num)
			if not msg or not key or not num or num <= 0 then return {} end
			if key=="" then key = " " end

			local tab = {}
			local str = ''

			for arg in msg:gmatch('([^'..key..']+)') do
				if #tab>=num then
					break
				elseif #tab>=num-1 then
					table.insert(tab,msg:sub(#str+1,#msg))
				else
					str = str..arg..key
					table.insert(tab,arg)
				end
			end

			return tab
		end;

		BasicSplit = function(msg,key)
			local ret = {}
			for arg in msg:gmatch("([^"..key.."]+)") do
				table.insert(ret,arg)
			end
			return ret
		end;

		CountTable = function(tab)
			local num = 0
			for i in pairs(tab) do
				num = num+1
			end
			return num
		end;

		IsValidTexture = function(id)
			local id = tonumber(id)
			local ran, info = pcall(function() return service.MarketPlace:GetProductInfo(id) end)

			if ran and info and info.AssetTypeId == 1 then
				return true;
			else
				return false;
			end
		end;

		GetTexture = function(id)
			local id = tonumber(id);
			if id and Functions.IsValidTexture(id) then
				return id;
			else
				return 6825455804;
			end
		end;

		Trim = function(str)
			return str:match("^%s*(.-)%s*$")
		end;

		Round = function(num)
			return math.floor(num + 0.5)
		end;

		RoundToPlace = function(num, places)
			return math.floor((num*(10^(places or 0)))+0.5)/(10^(places or 0))
		end;

		CleanWorkspace = function()
			for i,v in pairs(service.Workspace:GetChildren()) do
				if v:IsA("Tool") or v:IsA("Accessory") or v:IsA("Hat") then
					v:Destroy()
				end
			end
		end;

		RemoveSeatWelds = function(seat)
			if seat ~= nil then
				for i,v in ipairs(seat:GetChildren()) do
					if v:IsA("Weld") then
						if v.Part1 ~= nil and v.Part1.Name == "HumanoidRootPart" then
							v:Destroy()
						end
					end
				end
			end
		end;

		GrabNilPlayers = function(name)
			local AllGrabbedPlayers = {}
			for i,v in pairs(service.NetworkServer:GetChildren()) do
				pcall(function()
					if v:IsA("ServerReplicator") then
						if v:GetPlayer().Name:lower():sub(1,#name)==name:lower() or name=='all' then
							table.insert(AllGrabbedPlayers, (v:GetPlayer() or "NoPlayer"))
						end
					end
				end)
			end
			return AllGrabbedPlayers
		end;

		AssignName = function()
			local name=math.random(100000,999999)
			return name
		end;

		Shutdown = function(reason)
			if not Core.PanicMode then
				Functions.Message("SYSTEM MESSAGE", "Shutting down...", service.Players:GetChildren(), false, 5)
				wait(1)
			end

			service.Players.PlayerAdded:Connect(function(p)
				p:Kick("Game shutdown\n\n".. tostring(reason or "No Reason Given"))
			end)

			for i,p in next,service.Players:GetPlayers() do
				p:Kick("Game shutdown\n\n" .. tostring(reason or "No Reason Given"))
			end
		end;

		Donor = function(plr)
			if (Admin.CheckDonor(plr) and Settings.DonorCapes) then
				local PlayerData = Core.GetPlayer(plr) or {Donor = {}}
				local donor = PlayerData.Donor or {}
				if donor and donor.Enabled then
					local img,color,material
					if donor and donor.Cape then
						img,color,material = donor.Cape.Image,donor.Cape.Color,donor.Cape.Material
					else
						img,color,material = '0','White','Neon'
					end
					if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
						Functions.Cape(plr,true,material,color,img)
					end
					--[[
					if Admin.CheckDonor(plr) and (Settings.DonorPerks or Admin.GetLevel(plr)>=4) then
						local gear=service.InsertService:LoadAsset(57902997):GetChildren()[1]
						if not plr.Backpack:FindFirstChild(gear.Name..'DonorTool') then
							gear.Name=gear.Name..'DonorTool'
							gear.Parent=plr.Backpack
						else
							gear:Destroy()
						end
					end --]]
				end
			end
		end;

		CheckMatch = function(check,match)
			if check == match then
				return true
			elseif type(check) == "table" and type(match) == "table" then
				local good = false
				local num = 0
				for k,m in pairs(check) do
					if m == match[k] then
						good = true
					else
						good = false
						break
					end
					num = num+1
				end

				if good and num == Functions.CountTable(check) then
					return true
				end
			end
		end;

		DSKeyNormalize = function(intab, reverse)
			local tab = {}

			if reverse then
				for i,v in next,intab do
					if tonumber(i) then
						tab[tonumber(i)] = v;
					end
				end
			else
				for i,v in next,intab do
					tab[tostring(i)] = v;
				end
			end

			return tab;
		end;

		GetIndex = function(tab,match)
			for i,v in pairs(tab) do
				if v==match then
					return i
				elseif type(v)=="table" and type(match)=="table" then
					local good = false
					for k,m in pairs(v) do
						if m == match[k] then
							good = true
						else
							good = false
							break
						end
					end
					if good then
						return i
					end
				end
			end
		end;

		ConvertPlayerCharacterToRig = function(p, rigType)
			rigType = rigType or "R15"

			local char = p.Character
			if not p.Character then
				p:LoadCharacter()
				p.CharacterAdded:Wait()
				char = p.Character
			end

			local head = char:FindFirstChild"Head"
			local human = char:FindFirstChildOfClass"Humanoid"

			if head then
				local rig = server.Deps.Assets["Rig"..rigType]:Clone()
				local rigHuman = rig:FindFirstChildOfClass"Humanoid"
				local origHeadCF = head.CFrame
				rig.Name = p.Name

				for _,b in pairs(char:GetChildren()) do
					if b:IsA("Accessory") or b:IsA("Pants") or b:IsA("Shirt") or b:IsA("ShirtGraphic") or b:IsA("BodyColors") then
						b.Parent = rig
					elseif b:IsA"BasePart" and b.Name == "Head" and b:FindFirstChild("face") then
						rig.Head.face.Texture = b.face.Texture
					end
				end

				p.Character = rig
				rig.Parent = workspace
				rig.Head.CFrame = origHeadCF

				human.RigType = Enum.HumanoidRigType[rigType]
			end
		end;

		CreateClothingFromImageId = function(clothingtype, Id)
			local Clothing = Instance.new(clothingtype)
			Clothing.Name = clothingtype
			Clothing[clothingtype == "Shirt" and "ShirtTemplate" or clothingtype == "Pants" and "PantsTemplate" or clothingtype == "ShirtGraphic" and "Graphic"] = string.format("rbxassetid://%d", Id)
			return Clothing
		end;
	};
end
