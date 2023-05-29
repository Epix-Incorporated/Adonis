local canEditTables = {
	Admins = true;
	HeadAdmins = true;
	Moderators = true;

	Banned = true;
	Muted = true;

	Blacklist = true;
	Whitelist = true;
	Permissions = true;

	MusicList = false;
	InsertList = false;
	CapeList = false;
	CustomRanks = false;

	OnStartup = true;
	OnJoin = true;
	OnSpawn = true;

	Allowed_API_Calls = false;
	HideScript = false;
}

local function tabToString(tab)
	if type(tab) == "table" then
		local str = ""
		for i, v in tab do
			if #str > 0 then
				str ..= "; "
			end

			str ..= `{i}: {v}`
		end
		return str
	else
		return tostring(tab)
	end
end

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local client: table = env.client
	local service: table = env.service
	local gui = env.gui

	local UI = client.UI
	local Remote = client.Remote
	local Variables = client.Variables
	local Deps = client.Deps
	local Functions = client.Functions;
	local keyCodeToName = Functions.KeyCodeToName;

	local gTable
	local window = UI.Make("Window", {
		Name  = "UserPanel";
		Title = "Adonis Critial Incident";
		Icon = "rbxassetid://7495468117"; --"rbxassetid://7681088830"; --"rbxassetid://7681233602"; --"rbxassetid://7681048299";
		Size  = {465, 325};
		AllowMultiple = false;
		OnClose = function()
			Variables.WaitingForBind = false
		end
	})

	local function showTable(tab, setting)
		local tabPath = type(setting) == "table" and setting
		local setting = tabPath and tabPath[#tabPath-1] or setting
		local name = tabPath and table.concat(tabPath, ".") or setting

		local tabWindow = UI.Make("Window",{
			Name  = `{name}EditSettingsTable`;
			Title = name;
			Size  = {320, 300};
			AllowMultiple = false;
		})

		if tabWindow then
			--// Display tab & allow changes
			local items = tabWindow:Add("ScrollingFrame", {
				Size = UDim2.new(1, -10, 1, -35);
				Position = UDim2.new(0, 5, 0, 5);
				BackgroundTransparency = 1;
			})

			if tabPath and tabPath[2] == "Ranks" or canEditTables[setting] then
				local selected
				local inputBlock

				local function showItems()
					local num = 0
					selected = nil
					items:ClearAllChildren();

					local fromOffset = UDim2.fromOffset
					local listSize = UDim2.new(1, 0, 0, 25)

					for i,v in ipairs(tab) do
						items:Add("TextButton", {
							Text = tabToString(v);
							Size = listSize;
							Position = fromOffset(0, num*25);
							Visible = true;
							ZIndex = 100;
							OnClicked = function(button)
								if selected then
									selected.Button.BackgroundTransparency = 0
								end

								button.BackgroundTransparency = 0.5
								selected = {
									Index = i;
									Value = v;
									Button = button;
								}
							end
						})

						num += 1
					end

					items:ResizeCanvas(false, true)
				end

				local entryText
				local entryBox; entryBox = tabWindow:Add("Frame", {
					Visible = false;
					Size = UDim2.new(0, 200, 0, 75);
					Position = UDim2.new(0.5, -100, 0.5, -100);
					ZIndex = 100;
					Children = {
						{
							Class = "TextLabel";
							Text = "Entry:";
							Position = UDim2.new(0, 15, 0, 10);
							Size = UDim2.new(0, 40, 0, 25);
							BackgroundTransparency = 1;
							ZIndex = 100;
						};
						{
							Class = "TextButton";
							Text = "Add";
							Position = UDim2.new(0.5, 0, 1, -30);
							Size = UDim2.new(0.5, -20, 0, 20);
							BackgroundTransparency = 1;
							ZIndex = 100;
							OnClicked = function()
								if not inputBlock then
									inputBlock = true
									if #entryText.Text > 0 then
										Remote.Send("SaveTableAdd", tabPath or setting, entryText.Text)
										table.insert(tab, entryText.Text)
									end
									wait(0.5)
									entryBox.Visible = false
									inputBlock = false
									showItems()
								end
							end
						};
						{
							Class = "TextButton";
							Text = "Cancel";
							Position = UDim2.new(0, 10, 1, -30);
							Size = UDim2.new(0.5, -20, 0, 20);
							BackgroundTransparency = 1;
							ZIndex = 100;
							OnClicked = function()
								if not inputBlock then
									inputBlock = false
									entryBox.Visible = false
								end
							end
						};
					}
				})

				entryText = entryBox:Add("TextBox", {
					Position = UDim2.new(0, 55, 0, 10);
					Size = UDim2.new(1, -60, 0, 25);
					Text = "";
					PlaceholderText = "Type entry here";
					TextScaled = true;
					BackgroundColor3 = Color3.new(1,1,1);
					BackgroundTransparency = 0.8;
					ZIndex = 100;
				})

				tabWindow:Add("TextButton", {
					Text = "Remove";
					Position = UDim2.new(0, 5, 1, -25);
					Size = UDim2.new(0.5, -10, 0, 20);
					OnClicked = function(button)
						if selected and not inputBlock then
							inputBlock = true
							Remote.Send("SaveTableRemove", tabPath or setting, selected.Value)
							table.remove(tab, selected.Index)
							showItems()
							wait(0.5)
							inputBlock = false
						end
					end
				})

				tabWindow:Add("TextButton", {
					Text = "Add",
					Position = UDim2.new(0.5, 0, 1, -25);
					Size = UDim2.new(0.5, -5, 0, 20);
					OnClicked = function()
						if not inputBlock then
							entryText.Text = ""
							entryBox.Visible = true
						end
					end
				})

				entryBox.BackgroundColor3 = entryBox.BackgroundColor3:lerp(Color3.new(1,1,1), 0.25)
				showItems()
			else
				items:Add("TextLabel", {
					Text = "Cannot edit this table in-game";
					Size = UDim2.new(1, 0, 0, 25);
					Position = UDim2.new(0, 0, 0, 0);
				})
			end

			tabWindow:Ready()
		end
	end

	if window then
		local playerData   = Remote.Get("PlayerData")
		local chatMod 	   = Remote.Get("Setting",{"Prefix","SpecialPrefix","BatchKey","AnyPrefix","DonorCommands","DonorCapes"})
		local settingsData = Remote.Get("AllSettings")

		Variables.Aliases = playerData.Aliases or {}

		local tabFrame = window:Add("TabFrame", {
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5);
		})

		local infoTab = tabFrame:NewTab("Info", {
			Text = "Info";
		})

		local donorTab = tabFrame:NewTab("Donate", {
			Text = "Donate";
		})

		local keyTab = tabFrame:NewTab("Keybinds", {
			Text = "Keybinds";
		})

		local aliasTab = tabFrame:NewTab("Aliases", {
			Text = "Aliases";
		})

		local clientTab = tabFrame:NewTab("Client", {
			Text = "Client";
		})

		local gameTab = tabFrame:NewTab("Game", {
			Text = "Game";
		})

		if data.Tab then
			if string.lower(data.Tab) == "donate" then
				donorTab:FocusTab()
			elseif string.lower(data.Tab) == "keybinds" then
				keyTab:FocusTab()
			elseif string.lower(data.Tab) == "aliases" then
				aliasTab:FocusTab()
			elseif string.lower(data.Tab) == "client" then
				clientTab:FocusTab()
			elseif string.lower(data.Tab) == "settings" then
				gameTab:FocusTab()
			else
				infoTab:FocusTab()
			end
		end


		--// Help/Info
		do
			infoTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end


		--// Donor Tab
		do
			donorTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nDonator privilages have temportarily been disabled.\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end


		--// Keybinds
		do
			keyTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nKeybinds have temportarily been disabled.\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end

		--// Alias tab (basically a copy-paste of keyTab stuff with edits don't hurt me their functionality is so similar and I'm lazy)
		do
			aliasTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nAliases have temportarily been disabled.\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end

		--// Client Settings
		do
			clientTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nClient settings have temportarily been disabled.\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end


		--// Game Settings
		do
			gameTab:Add("TextLabel", {
				Text = "RESTRICTED MODE\n\nGame settings have temportarily been disabled.\n\nAdonis is currently running in restricted mode. Most features have been removed and Adonis can now only use core functions limited to basic user moderation functionality. A service failure event has occured, and Adonis has had to fall back to the backup. Error code: 1A.Rx503.\n\nWe are working hard to resolve the issue and normal operations will hopefully resume soon.\nSee our offical group for more information.\n\nhttps://www.roblox.com/groups/886423/Epix-Incorporated";
				TextWrapped = true;
				Size = UDim2.new(1, -10, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
		end

		gTable = window.gTable
		window:Ready()
	end
end
