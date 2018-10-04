
client = nil
service = nil

local canEditTables = {
	Admins = true;
	Owners = true;
	Moderators = true;
	Banned = true;
	Muted = true;
	Blacklist = true;
	Whitelist = true;
	Permissions = true;
	MusicList = false;
	CapeList = false;
	CustomRanks = false;
	
	OnStartup = true;
	OnJoin = true;
	OnSpawn = true;
	
	Allowed_API_Calls = false;
	AntiInsert = false;
}

local function tabToString(tab)
	if type(tab) == "table" then
		local str = ""
		for i,v in next,tab do
			if #str > 0 then
				str = str.. "; "
			end
			
			str = str.. tostring(i) ..": ".. tostring(v)
		end
		return str
	else
		return tostring(tab)
	end
end

return function(data)
	local gTable
	local window = client.UI.Make("Window",{
		Name  = "UserPanel";
		Title = "Adonis";
		Size  = {465, 325};
		AllowMultiple = false;
		OnClose = function()
			client.Variables.WaitingForBind = false
		end
	})
	
	local function showTable(tab, setting)
		local tabWindow = client.UI.Make("Window",{
			Name  = setting .. "EditSettingsTable";
			Title = setting .. " Table Editor";
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
			
			if canEditTables[setting] then
				local selected
				local inputBlock
				
				local function showItems()
					local num = 0
					selected = nil
					items:ClearAllChildren();
					
					for i,v in next,tab do
						items:Add("TextButton", {
							Text = tabToString(v);
							Size = UDim2.new(1, 0, 0, 25);
							Position = UDim2.new(0, 0, 0, num*25);
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
						
						num = num + 1
					end
					
					items:ResizeCanvas(false, true)
				end
				
				local entryText
				local entryBox; entryBox = tabWindow:Add("Frame", {
					Visible = false;
					Size = UDim2.new(0, 200, 0, 75);
					Position = UDim2.new(0.5, -100, 0.5, -100);
					Children = {
						{
							Class = "TextLabel";
							Text = "Entry:";
							Position = UDim2.new(0, 15, 0, 10);
							Size = UDim2.new(0, 40, 0, 25);
							BackgroundTransparency = 1;
						};
						{
							Class = "TextButton";
							Text = "Add";
							Position = UDim2.new(0.5, 0, 1, -30);
							Size = UDim2.new(0.5, -20, 0, 20);
							BackgroundTransparency = 1;
							OnClicked = function()
								if not inputBlock then
									inputBlock = true
									if #entryText.Text > 0 then
										client.Remote.Send("SaveTableAdd", setting, entryText.Text)
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
				})
				
				tabWindow:Add("TextButton", {
					Text = "Remove";
					Position = UDim2.new(0, 5, 1, -25);
					Size = UDim2.new(0.5, -10, 0, 20);
					OnClicked = function(button)
						if selected and not inputBlock then
							inputBlock = true
							client.Remote.Send("SaveTableRemove", setting, selected.Value)
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
		local playerData   = client.Remote.Get("PlayerData")
		local chatMod 	   = client.Remote.Get("Setting",{"Prefix","SpecialPrefix","BatchKey","AnyPrefix","DonorCommands","DonorCapes"})
		local settingsData = client.Remote.Get("AllSettings")
		
		local tabFrame = window:Add("TabFrame",{
			Size = UDim2.new(1, -10, 1, -10);
			Position = UDim2.new(0, 5, 0, 5);
		})
		
		local infoTab = tabFrame:NewTab("Info",{
			Text = "Info";
		})
		
		local donorTab = tabFrame:NewTab("Donate",{
			Text = "Donate";
		})
		
		local keyTab = tabFrame:NewTab("Keybinds", {
			Text = "Keybinds";
		})
		
		local clientTab = tabFrame:NewTab("Client",{
			Text = "Client";
		})
		
		local gameTab = tabFrame:NewTab("Game",{
			Text = "Game";
		})
		
		
		--// Help/Info
		do
			infoTab:Add("TextLabel", {
				Text = "Adonis is a script created by Sceleratis.\n\nIt's purpose is to assist in the\nadministration and moderation\nof ROBLOX game servers.\n\nFeel free to take and edit it on\nthe condition that existing credits remain.";
				TextWrapped = true; 
				Size = UDim2.new(1, -145, 1, -10);
				Position = UDim2.new(0, 5, 0, 5);
			})
			
			infoTab:Add("TextButton", {
				Text = "Commands";
				Size = UDim2.new(0, 130, 0, 40);
				Position = UDim2.new(1, -135, 0, 5);
				BackgroundTransparency = 0.5;
				Events = {
					MouseButton1Down = function()
						client.Remote.Send("ProcessCommand",chatMod.Prefix.."cmds")
					end
				}
			})
			
			infoTab:Add("TextButton", {
				Text = "Changelog";
				Size = UDim2.new(0, 130, 0, 40);
				Position = UDim2.new(1, -135, 0, 50);
				BackgroundTransparency = 0.5;
				Events = {
					MouseButton1Down = function()
						client.UI.Make("List", {
							Title = "Changelog";
							Table = require(client.Deps.Changelog);
						})
					end
				}
			})
			
			infoTab:Add("TextButton", {
				Text = "Credits";
				Size = UDim2.new(0, 130, 0, 40);
				Position = UDim2.new(1, -135, 0, 95);
				BackgroundTransparency = 0.5;
				Events = {
					MouseButton1Down = function()
						client.UI.Make("List", {
							Title = "Credits";
							Table = require(client.Deps.Credits);
						})
					end
				}
			})
			
			infoTab:Add("TextButton", {
				Text = "Get Loader";
				Size = UDim2.new(0, 130, 0, 40);
				Position = UDim2.new(1, -135, 0, 140);
				BackgroundTransparency = 0.5;
				Events = {
					MouseButton1Down = function()
						service.MarketPlace:PromptPurchase(service.Players.LocalPlayer, 2373505175)
					end
				}
			})
			
			infoTab:Add("TextButton", {
				Text = "Get Source";
				Size = UDim2.new(0, 130, 0, 40);
				Position = UDim2.new(1, -135, 0, 185);
				BackgroundTransparency = 0.5;
				Events = {
					MouseButton1Down = function()
						service.MarketPlace:PromptPurchase(service.Players.LocalPlayer, 2373501710)
					end
				}
			})
		end
		
		
		--// Donor Tab
		do
			local donorData       = playerData.Donor
			local currentMaterial = donorData and donorData.Cape.Material
			local currentTexture  = donorData and donorData.Cape.Image
			local currentColor    = donorData and donorData.Cape.Color
			
			if type(currentColor) == "table" then
				currentColor = Color3.new(currentColor[1],currentColor[2],currentColor[3])
			else
				currentColor = BrickColor.new(currentColor).Color	
			end
			
			local dStatus = donorTab:Add("TextLabel", {
				Text = " Donor Status: ";
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 5);
				BackgroundTransparency = 0.25;
				TextXAlignment = "Left";
			}):Add("TextLabel", {
				Text = (playerData.isDonor and "Donated") or "Not a Donor";
				Size = UDim2.new(0, 150, 1, 0);
				Position = UDim2.new(1, -155, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = "Right";
			})
			
			local function updateStatus()
				dStatus.Text = "Updating..."
				dStatus.Text = client.Remote.Get("UpdateDonor", playerData.Donor)
				wait(0.5)
				dStatus.Text = "Donated"
			end
			
			donorTab:Add("TextLabel", {
				Text = " Donor Cape: ";
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 25);
				BackgroundTransparency = 0.8;
				TextXAlignment = "Left";
				Children = {
					{
						Class = "Boolean";
						TextXAlignment = "Right";
						Size = UDim2.new(0, 150, 1, 0);
						Position = UDim2.new(1, -155, 0, 0);
						TextTransparency = (playerData.isDonor and 0) or 0.5;
						BackgroundTransparency = 1;
						Enabled = playerData.isDonor and playerData.Donor.Enabled;
						OnToggle = playerData.isDonor and function(enabled)
							service.Debounce("DonorStatusUpdate", function()
								playerData.Donor.Enabled = enabled
								updateStatus()
							end)
						end
					}
				}
			})
			
			donorTab:Add("TextLabel", {
				Text = " Cape Color: ";
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 45);
				BackgroundTransparency = 0.25;
				TextXAlignment = "Left";
				Children = {
					{
						Class = "TextButton";
						Text = "";
						Size = UDim2.new(0, 40, 1, -6);
						Position = UDim2.new(1, -45, 0, 3);
						BackgroundColor3 = currentColor;
						TextTransparency = (playerData.isDonor and 0) or 0.5;
						BackgroundTransparency = 0;
						BorderPixelSize = 1;
						BorderColor3 = Color3.fromRGB(100, 100, 100);
						OnClick = playerData.isDonor and function(new)
							service.Debounce("DonorStatusUpdate", function()
								local newColor = client.UI.Make("ColorPicker", {
									Color = currentColor;
								})
								
								currentColor = newColor or currentColor
								new.BackgroundColor3 = currentColor
								donorData.Cape.Color = currentColor
								updateStatus()
							end)
						end
					}
				}
			})
			
			donorTab:Add("TextLabel", {
				Text = " Cape Material: ";
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 65);
				BackgroundTransparency = 0.8;
				TextXAlignment = "Left";
				Children = {
					{
						Class = "Dropdown";
						Size = UDim2.new(0, 100, 1, 0);
						Position = UDim2.new(1, -105, 0, 0);
						BackgroundTransparency = 1;
						Selected = currentMaterial;
						TextAlignment = "Right";
						NoArrow = true;
						TextProperties = {
							TextTransparency = (playerData.isDonor and 0) or 0.5;
						};
						
						Options = playerData.isDonor and {
							"Brick";
							"Cobblestone";
							"Concrete";
							"CorrodedMetal";
							"DiamondPlate";
							"Fabric";
							"Foil";
							"Granite";
							"Grass";
							"Ice";
							"Marble";
							"Metal";
							"Neon";
							"Pebble";
							"Plastic";
							"Sand";
							"Slate";
							"SmoothPlastic";
							"Wood";
							"WoodPlanks";
							"Glass";
						};
						
						OnSelect = function(selection)
							service.Debounce("DonorStatusUpdate", function()
								donorData.Cape.Material = selection
								updateStatus()
							end)
						end;
					}
				}
			})
			
			donorTab:Add("TextLabel", {
				Text = " Cape Texture: ";
				Size = UDim2.new(1, -10, 0, 20);
				Position = UDim2.new(0, 5, 0, 85);
				BackgroundTransparency = 0.25;
				TextXAlignment = "Left";
				Children = {
					{
						Class = "TextButton";
						TextXAlignment = "Right";
						Text = currentTexture or 0;
						Size = UDim2.new(0, 100, 1, 0);
						Position = UDim2.new(1, -105, 0, 0);
						TextTransparency = (playerData.isDonor and 0) or 0.5;
						BackgroundTransparency = 1;
						OnClick = playerData.isDonor and function(textureButton)
							service.Debounce("DonorStatusUpdate", function()
								local lastValid = currentTexture
								local donePreview = false
								local pWindow = client.UI.Make("Window", {
									Name = "CapeTexture";
									Title = "Texture Preview";
									Size = {200, 250};
									Ready = true;
									OnClose = function()
										donePreview = true;
									end
								})
								
								local img = pWindow:Add("ImageLabel", {
									BackgroundTransparency = 1;
									Image = "rbxassetid://"..currentTexture;
									Size = UDim2.new(1, -10, 1, -80);
									Position = UDim2.new(0, 5, 0, 35);
								})
								
								pWindow:Add("TextBox", {
									Text = currentTexture;
									Size = UDim2.new(1, -10, 0, 30);
									Position = UDim2.new(0, 5, 0, 5);
									TextChanged = function(text, enter, new)
										local num = tonumber(text)
										if num then
											lastValid = num
											img.Image = "rbxassetid://"..num;
										else
											new.Text = lastValid
										end
									end
								})
								
								pWindow:Add("TextButton", {
									Text = "Select";
									Size = UDim2.new(1, -10, 0, 30);
									Position = UDim2.new(0, 5, 1, -35);
									OnClick = function(new)
										currentTexture = lastValid;
										donorData.Cape.Image = lastValid;
										textureButton.Text = lastValid;
										donePreview = true;
										
										pWindow:Close()
										updateStatus()
									end
								})
							end)
						end
					}
				}
			})
			
			local donorPerks = {
				"Perks you get here: "
			}
			
			local capePerks,cmdPerks = {
				"Customizable Cape";
				"Access to !cape";
				"Access to !uncape";
			},{
				"Access to !sparkles <Color>";
				"Access to !unsparkles";
				"Access to !particle";
				"Access to !unparticle";
				"Access to !fire <Color>";
				"Access to !unfire";
				"Access to !light <Color>";
				"Access to !unlight";
				"Access to !hat <ID>";
				"Access to !removehats";
				"Access to !face";
				"Access to !shirt";
				"Access to !pants";
			}
			
			if chatMod.DonorCapes then
				for i,v in ipairs(capePerks) do
					table.insert(donorPerks, v)
				end
			else
				table.insert(donorPerks, "Donor capes are disabled here")
			end
			
			if chatMod.DonorCommands then
				for i,v in ipairs(cmdPerks) do
					table.insert(donorPerks, v)
				end
			else 
				table.insert(donorPerks, "Donor commands are disabled here")
			end
			
			donorTab:Add("ScrollingFrame", {
				Size = UDim2.new(1, -145, 1, -115);
				Position = UDim2.new(0, 5, 0, 110);
			}):GenerateList(donorPerks, {
				TextXAlignment = "Left";
			})
			
			local dFrame = donorTab:Add("Frame", {
				Size = UDim2.new(0, 140, 1, -110);
				Position = UDim2.new(1, -140, 0, 105);
				BackgroundTransparency = 1;
			})
			
			dFrame:Add("TextButton", {
				Text = "Donate (Perks)";
				Size = UDim2.new(1, -10, 0, 40);
				Position = UDim2.new(0, 5, 0, 5);
				BackgroundTransparency = 0.5;
				BackgroundColor3 = Color3.fromRGB(231, 6, 141);
				OnClick = function()
					service.MarketPlace:PromptPurchase(service.Players.LocalPlayer, 497917601)
				end
			})
			
			dFrame:Add("TextLabel", {
				Text = "Extra (No Perks): ";
				TextXAlignment = "Left";
				Size = UDim2.new(1, 0, 0, 30);
				Position = UDim2.new(0, 5, 1, -80);
				BackgroundTransparency = 1;
			})
			
			dFrame:Add("TextButton", {
				Text = "50";
				Size = UDim2.new(0, 60, 0, 20);
				Position = UDim2.new(0, 5, 1, -50);
				BackgroundTransparency = 0.7;
				BackgroundColor3 = Color3.new(0,1,0):lerp(Color3.new(1,0,0), 0.1);
				OnClick = function()
					service.MarketPlace:PromptGamePassPurchase(service.Players.LocalPlayer, 5212076)
				end
			})
			
			dFrame:Add("TextButton", {
				Text = "100";
				Size = UDim2.new(0, 60, 0, 20);
				Position = UDim2.new(0.5, 5, 1, -50);
				BackgroundTransparency = 0.5;
				BackgroundColor3 = Color3.new(0,1,0):lerp(Color3.new(1,0,0), 0.3);
				OnClick = function()
					service.MarketPlace:PromptGamePassPurchase(service.Players.LocalPlayer, 5212077)
				end
			})
			
			dFrame:Add("TextButton", {
				Text = "500";
				Size = UDim2.new(0, 60, 0, 20);
				Position = UDim2.new(0, 5, 1, -25);
				BackgroundTransparency = 0.5;
				BackgroundColor3 = Color3.new(0,1,0):lerp(Color3.new(1,0,0), 0.6);
				OnClick = function()
					service.MarketPlace:PromptGamePassPurchase(service.Players.LocalPlayer, 5212081)
				end
			})
			
			dFrame:Add("TextButton", {
				Text = "1000";
				Size = UDim2.new(0, 60, 0, 20);
				Position = UDim2.new(0.5, 5, 1, -25);
				BackgroundTransparency = 0.5;
				BackgroundColor3 = Color3.new(0,1,0):lerp(Color3.new(1,0,0), 0.9);
				OnClick = function()
					service.MarketPlace:PromptGamePassPurchase(service.Players.LocalPlayer, 5212082)
				end
			})
		end
		
		
		--// Keybinds
		do
			local doneKey
			local selected
			local currentKey
			local editOldKeybind
			local keyInputHandler
			local curCommandText = ""
			local waitingForBind = false
			local keyDebounce = false
			local inputBlock = false
			local commandBox
			local keyBox
			local binds = keyTab:Add("ScrollingFrame", {
				Size = UDim2.new(1, -10, 1, -35);
				Position = UDim2.new(0, 5, 0, 5);
				BackgroundTransparency = 0.5;
			})
			
			local function getBinds()
				local num = 0
				selected = nil
				binds:ClearAllChildren();
				
				for i,v in next,client.Variables.KeyBinds do
					binds:Add("TextButton", {
						Text = "Key: ".. string.upper(string.char(i)) .." | Command: "..v;
						Size = UDim2.new(1, 0, 0, 25);
						Position = UDim2.new(0, 0, 0, num*25);
						OnClicked = function(button)
							if selected then
								selected.Button.BackgroundTransparency = 0
							end
							
							button.BackgroundTransparency = 0.5
							selected = {
								Key = i;
								Command = v;
								Button = button;
							}
						end
					})
					
					num = num + 1
				end
				
				binds:ResizeCanvas(false, true)
			end
			
			local binderBox; binderBox = keyTab:Add("Frame", {
				Visible = false;
				Size = UDim2.new(0, 200, 0, 150);
				Position = UDim2.new(0.5, -100, 0.5, -100);
				Children = {
					{
						Class = "TextLabel";
						Text = "Command:";
						Position = UDim2.new(0, 0, 0, 10);
						Size = UDim2.new(1, 0, 0, 20);
						BackgroundTransparency = 1;
					};
					{
						Class = "TextLabel";
						Text = "Key:";
						Position = UDim2.new(0, 0, 0, 65);
						Size = UDim2.new(1, 0, 0, 20);
						BackgroundTransparency = 1;
					};
					{
						Class = "TextButton";
						Text = "Add";
						Position = UDim2.new(0.5, 0, 1, -30);
						Size = UDim2.new(0.5, -20, 0, 20);
						BackgroundTransparency = 1;
						OnClicked = function()
							inputBlock = true
							
							if currentKey then
								keyBox.Text = "Saving..."
								if editOldKeybind then
									client.Functions.RemoveKeyBind(editOldKeybind)
									editOldKeybind = nil
								end
								client.Functions.AddKeyBind(currentKey.Value, commandBox.Text)
								currentKey = nil
							end
							
							binderBox.Visible = false
							inputBlock = false
							getBinds()
						end
					};
					{
						Class = "TextButton";
						Text = "Cancel";
						Position = UDim2.new(0, 10, 1, -30);
						Size = UDim2.new(0.5, -20, 0, 20);
						BackgroundTransparency = 1;
						OnClicked = function()
							if not inputBlock then
								doneKey = true
								currentKey = nil
								inputBlock = false
								binderBox.Visible = false
								client.Variables.WaitingForBind = false
								if keyInputHandler then
									keyInputHandler:Disconnect()
								end
							end
						end
					};
				}
			})
			
			commandBox = binderBox:Add("TextBox", {
				Position = UDim2.new(0, 10, 0, 35);
				Size = UDim2.new(1, -20, 0, 20);
				TextChanged = function(newText, enter, box)
					curCommandText = newText
				end
			})
			
			keyBox = binderBox:Add("TextButton", {
				Text = "Click To Bind";
				Position = UDim2.new(0, 10, 0, 90);
				Size = UDim2.new(1, -20, 0, 20);
				OnClicked = function(button)
					doneKey = false
					button.Text = "Waiting..."
					client.Variables.WaitingForBind = true
					keyInputHandler = window:BindEvent(service.UserInputService.InputBegan, function(InputObject)
						local textbox = service.UserInputService:GetFocusedTextBox()
						if not (textbox) and not doneKey and rawequal(InputObject.UserInputType, Enum.UserInputType.Keyboard) then
							currentKey = InputObject.KeyCode
							button.Text = string.upper(string.char(currentKey.Value))
							client.Variables.WaitingForBind = false
							if keyInputHandler then
								keyInputHandler:Disconnect()
								keyInputHandler = nil
							end
						end
					end)
				end
			})
			
			commandBox.BackgroundColor3 = commandBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.1)
			keyBox.BackgroundColor3 = commandBox.BackgroundColor3
			binderBox.BackgroundColor3 = binderBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.05)
			
			keyTab:Add("TextButton", {
				Text = "Remove";
				Position = UDim2.new(0, 5, 1, -25);
				Size = UDim2.new(1/3, -(15/3)-1, 0, 20);
				OnClicked = function(button)
					if selected and not inputBlock then
						inputBlock = true
						client.Functions.RemoveKeyBind(selected.Key)
						getBinds()
						inputBlock = false
					end
				end
			})
			
			keyTab:Add("TextButton", {
				Text = "Edit";
				Position = UDim2.new((1/3), 0, 1, -25);
				Size = UDim2.new(1/3, -(15/3)+5, 0, 20);
				OnClicked = function(button)
					if selected and not inputBlock then
						currentKey = nil
						editOldKeybind = selected.Key
						keyBox.Text = string.upper(string.char(selected.Key))
						commandBox.Text = selected.Command
						binderBox.Visible = true
					end
				end
			})
			
			keyTab:Add("TextButton", {
				Text = "Add",
				Position = UDim2.new((1/3)*2, 0, 1, -25);
				Size = UDim2.new(1/3, -(15/3), 0, 20);
				OnClicked = function()
					if not inputBlock then
						editOldKeybind = nil
						currentKey = nil
						keyBox.Text = "Click To Bind"
						commandBox.Text = ""
						binderBox.Visible = true
					end
				end
			})
			
			getBinds()
		end
		
		
		--// Client Settings
		do
			local cliSettings = {
				{
					Text = "Keybinds: ";
					Desc = "- Enabled/Disables Keybinds";
					Entry = "Boolean";
					Value = client.Variables.KeybindsEnabled;
					Function = function(enabled, toggle)
						client.Variables.KeybindsEnabled = enabled
						local text = toggle.Text
						toggle.Text = "Saving.."
						client.Remote.Get("UpdateClient","KeybindsEnabled",enabled)
						toggle.Text = text
					end
				};
				{
					Text = "UI Keep Alive: ";
					Desc = "- Prevents Adonis UI deletion on death";
					Entry = "Boolean";
					Value = client.Variables.UIKeepAlive;
					Function = function(enabled, toggle)
						client.Variables.UIKeepAlive = enabled
						local text = toggle.Text
						toggle.Text = "Saving.."
						client.Remote.Get("UpdateClient","UIKeepAlive",enabled)
						toggle.Text = text
					end
				};
				{
					Text = "Particle Effects: ";
					Desc = "- Enables/Disables Adonis made particles";
					Entry = "Boolean";
					Value = client.Variables.ParticlesEnabled;
					Function = function(enabled, toggle)
						client.Variables.ParticlesEnabled = enabled
						
						if enabled then
							client.Functions.EnableParticles(true)
						else
							client.Functions.EnableParticles(false)
						end
						
						local text = toggle.Text
						toggle.Text = "Saving.."
						client.Remote.Get("UpdateClient","ParticlesEnabled",enabled)
						toggle.Text = text
					end
				};
				{
					Text = "Capes: ";
					Desc = "- Allows you to disable all player capes locally";
					Entry = "Boolean";
					Value = client.Variables.CapesEnabled;
					Function = function(enabled, toggle)
						client.Variables.CapesEnabled = enabled
						
						if enabled then
							client.Functions.HideCapes(false)
						else
							client.Functions.HideCapes(true)
						end
						
						if enabled then
							client.Functions.MoveCapes()
						else
							service.StopLoop("CapeMover")
						end
						
						local text = toggle.Text
						toggle.Text = "Saving.."
						client.Remote.Get("UpdateClient","CapesEnabled",enabled)
						toggle.Text = text
					end
				};
				{
					Text = "Console Key: ";
					Desc = "Key used to open the console";
					Entry = "Keybind";
					Value = client.Variables.CustomConsoleKey or client.Remote.Get("Setting","ConsoleKeyCode");
					Function = function(toggle)
						service.Debounce("CliSettingKeybinder", function()
							local gotKey
							toggle.Text = "Waiting..."
							local event = service.UserInputService.InputBegan:connect(function(InputObject)
								local textbox = service.UserInputService:GetFocusedTextBox()
								if not (textbox) and rawequal(InputObject.UserInputType, Enum.UserInputType.Keyboard) then
									gotKey = InputObject.KeyCode.Name
								end
							end)
							
							repeat wait() until gotKey
							
							client.Variables.CustomConsoleKey = gotKey
							event:Disconnect()
							toggle.Text = "Saving.."
							client.Remote.Get("UpdateClient","CustomConsoleKey",client.Variables.CustomConsoleKey)
							toggle.Text = gotKey
						end)
					end
				};
				{
					Text = "Theme: ";
					Desc = "- Allows you to set the Adonis UI theme";
					Entry = "DropDown";
					Setting = "CustomTheme";
					Value = "Game Theme";
					Options = (function() local themes = {"Game Theme"} for i,v in next,client.Deps.UI:GetChildren() do table.insert(themes, v.Name) end return themes end)();
					Function = function(selection)
						client.Variables.CustomTheme = selection
						if selection == "Game Theme" then
							client.Remote.Get("UpdateClient","CustomTheme",nil)
						else
							client.Remote.Get("UpdateClient","CustomTheme",selection)
						end
					end
				}
			}
			
			local num = 0;
			local cliScroll = clientTab:Add("ScrollingFrame", {
				BackgroundTransparency = 1;
			});
			
			for i, setData in next,cliSettings do
				local label = cliScroll:Add("TextLabel", {
					Text = "  ".. setData.Text;
					ToolTip = setData.Desc;
					TextXAlignment = "Left";
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 0, 0, num*30);
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
				})
				
				if setData.Entry == "Boolean" then
					label:Add("Boolean", {
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						Enabled = setData.Value;
						OnToggle = setData.Function;
						BackgroundTransparency = 1;
					})
				elseif setData.Entry == "Keybind" then
					label:Add("TextButton", {
						Text = tostring(setData.Value);
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						OnClick = setData.Function;
						BackgroundTransparency = 1;
					})
				elseif setData.Entry == "DropDown" then
					label:Add("Dropdown", {
						Size = UDim2.new(0, 120, 1, 0);
						Position = UDim2.new(1, -120, 0, 0);
						Selected = setData.Value;
						OnSelect = setData.Function;
						Options = setData.Options;
						--BackgroundColor3 = label.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.25);
						BackgroundTransparency = 1;
					})
				end
				
				--[[cliScroll:Add("TextLabel", {
					Text = setData.Desc;
					ToolTip = setData.Desc;
					TextXAlignment = "Left";
					Size = UDim2.new(1, -10, 0, 30);
					Position = UDim2.new(0, 5, 0, (num+1)*30);
				})--]]
				
				num = num+1
			end
			
			cliScroll:ResizeCanvas(false, true)
		end
		
		
		--// Game Settings
		do
			if settingsData then
				local settings = settingsData.Settings
				local descs = settingsData.Descs
				local order = settingsData.Order
				
				for i, setting in next,order do
					local value = settings[setting]
					local desc = descs[setting]
					if setting == "" or setting == " " and value == nil then
						
					elseif value == nil then
						gameTab:Add("TextLabel", {
							Text = "  "..setting..": ";
							ToolTip = desc;
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
							TextXAlignment = "Left";
							Children = {
								TextLabel = {
									Text = "Cannot Change";
									Size = UDim2.new(0, 100, 1, 0);
									Position = UDim2.new(1, -100, 0, 0); 
									TextTransparency = 0.5;
									BackgroundTransparency = 1;
								}
							}
						})
					elseif type(value) == "table" then
						gameTab:Add("TextLabel", {
							Text = "  "..setting..": ";
							ToolTip = desc;
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
							TextXAlignment = "Left";
							Children = {
								TextButton = {
									Text = "Open";
									Size = UDim2.new(0, 100, 1, 0);
									Position = UDim2.new(1, -100, 0, 0);
									BackgroundTransparency = 1;
									OnClick = function()
										showTable(value, setting)
									end
								}
							}
						})
					elseif type(value) == "boolean" then
						gameTab:Add("TextLabel", {
							Text = "  ".. tostring(setting)..": ";
							ToolTip = desc;
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
							TextXAlignment = "Left";
							Children = {
								Boolean = {
									Enabled = value;
									Size = UDim2.new(0, 100, 1, 0);
									Position = UDim2.new(1, -100, 0, 0); 
									BackgroundTransparency = 1;
									OnToggle = function(enabled, button)
										--warn("Setting ".. tostring(setting)..": ".. tostring(enabled))
										client.Remote.Send("SaveSetSetting", setting, enabled)
									end
								}
							}
						})
					elseif type(value) == "string" then
						gameTab:Add("TextLabel", {
							Text = "  "..setting..": ";
							ToolTip = desc;
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
							TextXAlignment = "Left";
							Children = {
								TextBox = {
									Text = value;
									Size = UDim2.new(0, 100, 1, 0);
									Position = UDim2.new(1, -100, 0, 0); 
									BackgroundTransparency = 1;
									TextChanged = function(text, enter, new)
										if enter then
											--warn("Setting "..tostring(setting)..": "..tostring(text))
											client.Remote.Send("SaveSetSetting", setting, text)
										end
									end
								}
							}
						})
					elseif type(value) == "number" then
						gameTab:Add("TextLabel", {
							Text = "  "..setting..": ";
							ToolTip = desc;
							BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
							Size = UDim2.new(1, -10, 0, 30);
							Position = UDim2.new(0, 5, 0, (30*(i-1))+5);
							TextXAlignment = "Left";
							Children = {
								TextBox = {
									Text = value;
									Size = UDim2.new(0, 100, 1, 0);
									Position = UDim2.new(1, -100, 0, 0);
									BackgroundTransparency = 1;
									TextChanged = function(text, enter, new)
										if enter then
											--warn("Setting "..tostring(setting)..": "..tonumber(text))
											client.Remote.Send("SaveSetSetting", setting, text)
										end
									end
								}
							}
						})
					end
				end
				
				gameTab:ResizeCanvas(false, true, false, false, 5, 5)
			else
				gameTab:Disable()
			end
		end
		
		gTable = window.gTable
		window:Ready()
	end
end