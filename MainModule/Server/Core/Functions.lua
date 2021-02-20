server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// HTTP
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

		Logs:AddLog("Script", "HTTP Module Initialized")
	end;

	server.HTTP = {
		Init = Init;
		Service = service.HttpService;
		CheckHttp = function()
			local y,n = pcall(function()
				local hs = service.HttpService
				local get = hs:GetAsync('http://google.com')
			end)
			if y and not n then return true end
		end;

		Trello = {
			API = require(server.Deps.TrelloAPI);
			Helpers = {};
			Moderators = {};
			Admins = {};
			Owners = {};
			Creators = {};
			Mutes = {};
			Bans = {};
			Music = {};
			InsertList = {};
			Agents = {};
			Blacklist = {};
			Whitelist = {};
			PerformedCommands = {};

			Update = function()
				if not HTTP.CheckHttp() and Settings.Trello_Enabled then 
					warn('Http is not enabled! Cannot connect to Trello!')
				elseif Settings.Trello_Enabled then
					local boards = {}
					local lists = {}
					local labels = {}
					local bans = {}
					local admins = {}
					local mods = {}
					local owners = {}
					local helpers = {}
					local creators = {}
					local agents = {}
					local music = {}
					local insertlist = {}
					local mutes = {}
					local perms = {}
					local blacklist = {}
					local whitelist = {}

					local function grabData(board)
						local trello = HTTP.Trello.API(Settings.Trello_AppKey,Settings.Trello_Token)
						local lists = trello.Boards.GetLists(board)
						local banList = trello.GetListObject(lists,{"Banlist","Ban List","Bans"})
						local commandList = trello.GetListObject(lists,{"Commands","Command List"})
						local adminList = trello.GetListObject(lists,{"Admins","Admin List","Adminlist"})
						local modList = trello.GetListObject(lists,{"Moderators","Moderator List","Moderatorlist","Modlist","Mod List","Mods"})
						local creatorList = trello.GetListObject(lists,{"Creators","Creator List","Creatorlist","Place Owners"})
						local ownerList = trello.GetListObject(lists,{"Owners","Owner List","Ownerlist"})
						local musicList = trello.GetListObject(lists,{"Music","Music List","Musiclist","Songs"}) 
						local insertList = trello.GetListObject(lists,{"InsertList","Insert List","Insertlist","Inserts","ModelList","Model List","Modellist","Models"}) 
						local permList = trello.GetListObject(lists,{"Permissions","Permission List","Permlist"})
						local muteList = trello.GetListObject(lists,{"Mutelist","Mute List"})
						local agentList = trello.GetListObject(lists,{"Agents","Agent List","Agentlist"})
						local bList = trello.GetListObject(lists,"Blacklist")
						local wList = trello.GetListObject(lists,"Whitelist")

						if banList then
							local cards = trello.Lists.GetCards(banList.id)
							for l,k in pairs(cards) do
								table.insert(bans,{
									name = k.name;
									time = k.dateLastUpdate;
								})
							end
						end

						if creatorList then
							local cards = trello.Lists.GetCards(creatorList.id)
							for l,k in pairs(cards) do
								table.insert(creators,k.name)
							end
						end

						if modList then
							local cards = trello.Lists.GetCards(modList.id)
							for l,k in pairs(cards) do
								table.insert(mods,k.name)
							end
						end

						if adminList then
							local cards = trello.Lists.GetCards(adminList.id)
							for l,k in pairs(cards) do
								table.insert(admins,k.name)
							end
						end

						if ownerList then
							local cards = trello.Lists.GetCards(ownerList.id)
							for l,k in pairs(cards) do
								table.insert(owners,k.name)
							end
						end

						if agentList then
							local cards = trello.Lists.GetCards(agentList.id)
							for l,k in pairs(cards) do
								table.insert(agents,k.name)
							end
						end

						if musicList then
							local cards = trello.Lists.GetCards(musicList.id)
							for l,k in pairs(cards) do
								if k.name:match('^(.*):(.*)') then
									local a,b=k.name:match('^(.*):(.*)')
									table.insert(music,{Name = a,ID = tonumber(b)})
								end
							end
						end

						if insertList then
							local cards = trello.Lists.GetCards(insertList.id)
							for l,k in pairs(cards) do
								if k.name:match('^(.*):(.*)') then
									local a,b=k.name:match('^(.*):(.*)')
									table.insert(insertlist,{Name = a,ID = tonumber(b)})
								end
							end
						end

						if muteList then		
							local cards = trello.Lists.GetCards(muteList.id)
							for l,k in pairs(cards) do
								table.insert(mutes,k.name)
							end
						end

						if bList then		
							local cards = trello.Lists.GetCards(bList.id)
							for l,k in pairs(cards) do
								table.insert(blacklist,k.name)
							end
						end

						if wList then		
							local cards = trello.Lists.GetCards(wList.id)
							for l,k in pairs(cards) do
								table.insert(whitelist,k.name)
							end
						end

						if permList then
							local cards = trello.Lists.GetCards(permList.id)
							for l,k in pairs(cards) do
								local com,level = k.name:match("^(.*):(.*)") 
								if com and level then 
									Admin.SetPermission(com,level) 
								end
							end
						end

						if commandList then
							local cards = trello.Lists.GetCards(commandList.id)
							for l,k in pairs(cards) do
								if not HTTP.Trello.PerformedCommands[tostring(k.id)] then
									local cmd = k.name
									local placeid
									if cmd:sub(1,1)=="$" then
										placeid = cmd:sub(2):match(".%d+")
										cmd = cmd:sub(#placeid+2)
										placeid = tonumber(placeid)
									end
									if placeid and game.PlaceId~=placeid then return end
									Admin.RunCommand(cmd)
									HTTP.Trello.PerformedCommands[tostring(k.id)] = true 
									Logs.AddLog(Logs.Script,{
										Text = "Trello command executed";
										Desc = cmd;
									})
									if Settings.Trello_Token ~= "" then
										pcall(trello.Cards.AddComment,k.id,"Ran Command: "..cmd.."\nPlace ID: "..game.PlaceId.."\nServer Job Id: "..game.JobId.."\nServer Players: "..#service.GetPlayers().."\nServer Time: "..service.GetTime())
									end
								end
							end
						end
					end

					for i,v in pairs(Settings.Trello_Secondary) do table.insert(boards,v) end
					if Settings.Trello_Primary~="" then table.insert(boards,Settings.Trello_Primary) end
					for i,v in pairs(boards) do pcall(grabData,v) end
					
					HTTP.Trello.Bans = bans
					HTTP.Trello.Creators = creators
					HTTP.Trello.Admins = admins
					HTTP.Trello.Moderators = mods
					HTTP.Trello.Owners = owners
					HTTP.Trello.Music = music
					HTTP.Trello.InsertList = insertlist 
					HTTP.Trello.Mutes = mutes
					HTTP.Trello.Agents = agents
					HTTP.Trello.Blacklist = blacklist
					HTTP.Trello.Whitelist = whitelist
					
					for i,v in pairs(service.GetPlayers()) do
						if Admin.CheckBan(v) then
							v:Kick(Functions.GetKickMessage("Ban"))
						end 

						if v and v.Parent then
							for ind,admin in pairs(HTTP.Trello.Mutes) do
								if Admin.DoCheck(v,admin) then
									Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
								end
							end
						end

						Admin.UpdateCachedLevel(v)
					end

					Logs.AddLog(Logs.Script,{
						Text = "Updated Trello Data";
						Desc = "Data was retreived from Trello";
					}) 
				end
			end;

			CheckAgent = function(p)
				for ind,v in pairs(HTTP.Trello.Agents) do
					if Admin.DoCheck(p,v) then
						return true
					end
				end
			end;
		};
		
		GetTrelloBan = function(plr)
			for _, Ban in pairs(HTTP.Trello.Bans) do
				if tostring(Ban.name):find(plr.Name) or tostring(Ban.name):find(tostring(plr.UserId)) then
					return Ban
				end
			end
		end;
	};
end
