server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// HTTP
return function()
	server.HTTP = {
		Service = service.HttpService;
		CheckHttp = function()
			local y,n = pcall(function()
				local hs = service.HttpService
				local get = hs:GetAsync('http://google.com')
			end)
			if y and not n then return true end
		end;
		
		Trello = {
			Helpers = {};
			Moderators = {};
			Admins = {};
			Owners = {};
			Creators = {};
			Mutes = {};
			Bans = {};
			Music = {};
			Agents = {};
			Blacklist = {};
			Whitelist = {};
			PerformedCommands = {};
			
			Update = function()
				if not server.HTTP.CheckHttp() then 
					--server.HTPP.Trello.Bans = {'Http is not enabled! Cannot connect to Trello!'}
					warn('Http is not enabled! Cannot connect to Trello!')
				elseif not server.Settings.Trello_Enabled then
					-- Do something else?
				else
					local boards = {}
					local bans = {}
					local admins = {}
					local mods = {}
					local owners = {}
					local helpers = {}
					local creators = {}
					local agents = {}
					local music = {}
					local mutes = {}
					local perms = {}
					local blacklist = {}
					local whitelist = {}
					
					local function grabData(board)
						local trello = server.HTTP.Trello.API(server.Settings.Trello_AppKey,server.Settings.Trello_Token)
						local lists = trello.getLists(board)
						local banList = trello.getListObj(lists,{"Banlist","Ban List","Bans"})
						local commandList = trello.getListObj(lists,{"Commands","Command List"})
						local adminList = trello.getListObj(lists,{"Admins","Admin List","Adminlist"})
						local modList = trello.getListObj(lists,{"Moderators","Moderator List","Moderatorlist","Modlist","Mod List","Mods"})
						local creatorList = trello.getListObj(lists,{"Creators","Creator List","Creatorlist","Place Owners"})
						local ownerList = trello.getListObj(lists,{"Owners","Owner List","Ownerlist"})
						local musicList = trello.getListObj(lists,{"Music","Music List","Musiclist","Songs"}) 
						local permList = trello.getListObj(lists,{"Permissions","Permission List","Permlist"})
						local muteList = trello.getListObj(lists,{"Mutelist","Mute List"})
						local agentList = trello.getListObj(lists,{"Agents","Agent List","Agentlist"})
						local bList = trello.getListObj(lists,"Blacklist")
						local wList = trello.getListObj(lists,"Whitelist")
						
						if banList then
							local cards = trello.getCards(banList.id)
							for l,k in pairs(cards) do
								table.insert(bans,k.name)
							end
						end
						
						if creatorList then
							local cards = trello.getCards(creatorList.id)
							for l,k in pairs(cards) do
								table.insert(creators,k.name)
							end
						end
						
						if modList then
							local cards = trello.getCards(modList.id)
							for l,k in pairs(cards) do
								table.insert(mods,k.name)
							end
						end
						
						if adminList then
							local cards = trello.getCards(adminList.id)
							for l,k in pairs(cards) do
								table.insert(admins,k.name)
							end
						end
						
						if ownerList then
							local cards = trello.getCards(ownerList.id)
							for l,k in pairs(cards) do
								table.insert(owners,k.name)
							end
						end
						
						if agentList then
							local cards = trello.getCards(agentList.id)
							for l,k in pairs(cards) do
								table.insert(agents,k.name)
							end
						end
						
						if musicList then
							local cards = trello.getCards(musicList.id)
							for l,k in pairs(cards) do
								if k.name:match('^(.*):(.*)') then
									local a,b=k.name:match('^(.*):(.*)')
									table.insert(music,{Name = a,ID = tonumber(b)})
								end
							end
						end
						
						if muteList then		
							local cards = trello.getCards(muteList.id)
							for l,k in pairs(cards) do
								table.insert(mutes,k.name)
							end
						end
						
						if bList then		
							local cards = trello.getCards(bList.id)
							for l,k in pairs(cards) do
								table.insert(blacklist,k.name)
							end
						end
						
						if wList then		
							local cards = trello.getCards(wList.id)
							for l,k in pairs(cards) do
								table.insert(whitelist,k.name)
							end
						end
						
						if permList then
							local cards = trello.getCards(permList.id)
							for l,k in pairs(cards) do
								local com,level = k.name:match("^(.*):(.*)") 
								if com and level then 
									server.Admin.SetPermission(com,level) 
								end
							end
						end
						
						if commandList then
							local cards = trello.getCards(commandList.id)
							for l,k in pairs(cards) do
								if not server.HTTP.Trello.PerformedCommands[tostring(k.id)] then
									local cmd = k.name
									local placeid
									if cmd:sub(1,1)=="$" then
										placeid = cmd:sub(2):match(".%d+")
										cmd = cmd:sub(#placeid+2)
										placeid = tonumber(placeid)
									end
									if placeid and game.PlaceId~=placeid then return end
									server.Admin.RunCommand(cmd)
									server.HTTP.Trello.PerformedCommands[tostring(k.id)] = true 
									server.Logs.AddLog(server.Logs.Script,{
										Text = "Trello command executed";
										Desc = cmd;
									})
									if server.Settings.Trello_Token ~= "" then
										pcall(trello.makeComment,k.id,"Ran Command: "..cmd.."\nPlace ID: "..game.PlaceId.."\nServer Job Id: "..game.JobId.."\nServer Players: "..#service.GetPlayers().."\nServer Time: "..service.GetTime())
									end
								end
							end
						end
					end
					
					for i,v in pairs(server.Settings.Trello_Secondary) do table.insert(boards,v) end
					if server.Settings.Trello_Primary~="" then table.insert(boards,server.Settings.Trello_Primary) end
					for i,v in pairs(boards) do pcall(grabData,v) end
					
					if #bans>0 then server.HTTP.Trello.Bans = bans end
					if #creators>0 then server.HTTP.Trello.Creators = creators end
					if #admins>0 then server.HTTP.Trello.Admins = admins end
					if #mods>0 then server.HTTP.Trello.Moderators = mods end
					if #owners>0 then server.HTTP.Trello.Owners = owners end
					if #music>0 then server.HTTP.Trello.Music = music end
					if #mutes>0 then server.HTTP.Trello.Mutes = mutes end
					if #agents>0 then server.HTTP.Trello.Agents = agents end
					if #blacklist>0 then server.HTTP.Trello.Blacklist = blacklist end
					if #whitelist>0 then server.HTTP.Trello.Whitelist = whitelist end
					
					for i,v in pairs(service.GetPlayers()) do
						if server.Admin.CheckBan(v) then
							v:Kick(server.Variables.BanMessage)
						end 
						
						if v and v.Parent then
							for ind,admin in pairs(server.HTTP.Trello.Mutes) do
								if server.Admin.DoCheck(v,admin) then
									server.Remote.LoadCode(v,[[service.StarterGui:SetCoreGuiEnabled("Chat",false) client.Variables.ChatEnabled = false client.Variables.Muted = true]])
								end
							end
						end
						
						server.Admin.UpdateCachedLevel(v)
					end
					
					server.Logs.AddLog(server.Logs.Script,{
						Text = "Updated Trello Data";
						Desc = "Data was retreived from Trello";
					}) 
				end
			end;
			
			CheckAgent = function(p)
				for ind,v in pairs(server.HTTP.Trello.Agents) do
					if server.Admin.DoCheck(p,v) then
						return true
					end
				end
			end;
		};
	};
end