client, service = nil, nil

return function(data)
	local window = client.UI.Make("Window", {
		Name  = "ToolCenter";
		Title = "Tools Center";
		Icon = client.MatIcons["Inventory 2"];
		Size  = {400, 290};
		MinSize  = {300, 200};
	})

	local tabFrame = window:Add("TabFrame", {
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})

	do
		local tab = tabFrame:NewTab("Tools", {
			Text = "Tools"
		})
		local scroller = tab:Add("ScrollingFrame", {
			Size = UDim2.new(1, -10, 1, -10); Position = UDim2.new(0, 5, 0, 5);
		})

		table.sort(data.Tools)
		for i, toolName in ipairs(data.Tools) do
			scroller:Add("TextLabel", {
				Size = UDim2.new(1, -10, 0, 30);
				Position = UDim2.new(0, 5, 0, (i-1)*30);
				BackgroundTransparency = 1;
				TextXAlignment = "Left";
				Text = "  "..toolName;
			}):Add("TextButton", {
				Size = UDim2.new(0, 80, 1, -4);
				Position = UDim2.new(1, -82, 0, 2);
				Text = "Spawn";
				OnClick = function(self)
					if self.Active then
						self.Active = false
						self.AutoButtonColor = false
						self.Text = ". . ."
						task.defer(function()
							local backpack = service.Players.LocalPlayer:FindFirstChildOfClass("Backpack")
							if backpack then backpack.ChildAdded:Wait() end
							self.Active = true
							self.AutoButtonColor = true
							self.Text = "Spawn"
						end)
						client.Remote.Send("ProcessCommand", data.Prefix.."give"..data.SplitKey..data.SpecialPrefix.."me"..data.SplitKey..toolName)
					end
				end
			})
		end
		scroller:ResizeCanvas(false, true, false, false, 5, 0)
	end

	spawn(function()
		local tab = tabFrame:NewTab("Inventories", {
			Text = "Inventory Monitor"
		})

		local selected: Player? = nil
		local connections: {RBXScriptConnection} = {}

		local inv = tab:Add("ScrollingFrame", {
			Size = UDim2.new(1, -195, 1, -10); Position = UDim2.new(0, 5, 0, 5);
		})
		inv.BackgroundColor3 = inv.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.05)
		inv.Visible = false
		local plrs = tab:Add("ScrollingFrame", {
			Size = UDim2.new(0, 180, 1, -10); Position = UDim2.new(1, -185, 0, 5);
		})
		plrs:Add("UIListLayout", {SortOrder = Enum.SortOrder.Name})

		local function displayInv()
			if not selected then return end
			local backpack = selected:FindFirstChildOfClass("Backpack")
			for _, v in pairs(connections) do if v then v:Disconnect() end end
			inv:ClearAllChildren()
			if not backpack then
				inv:Add("TextLabel", {
					Text = "This player has no backpack(!)";
					Size = UDim2.new(1, -10, 0, 26);
					Position = UDim2.new(0, 5, 0, 0);
					BackgroundTransparency = 1;
				})
				inv:ResizeCanvas(false, true, false, false, 5, 0)
				return
			end
			table.insert(connections, backpack.ChildAdded:Connect(displayInv))
			table.insert(connections, backpack.ChildRemoved:Connect(displayInv))
			table.insert(connections, selected.CharacterAdded:Connect(displayInv))
			local char = selected.Character
			local tools = backpack:GetChildren()
			if char then for _, v in ipairs(char:GetChildren()) do table.insert(tools, v) end end
			local i = 0
			for _, v: Tool in ipairs(tools) do
				if v and v:IsA("BackpackItem") then
					inv:Add("TextLabel", {
						Text = " "..v.Name;
						ToolTip = "Class: "..v.ClassName..(v.ToolTip ~= "" and (" | ToolTip: "..v.ToolTip) or "");
						TextXAlignment = "Left";
						TextColor3 = v.Parent == char and Color3.new(0.666667, 1, 1) or Color3.new(1, 1, 1);
						Size = UDim2.new(1, -10, 0, 26);
						Position = UDim2.new(0, 5, 0, i*26);
						BackgroundTransparency = 1;
					}):Add("ImageButton", {
						Image = client.MatIcons.Clear;
						Size = UDim2.new(0, 20, 0, 20);
						Position = UDim2.new(1, -20, 0, 3);
						OnClick = function(self)
							if self.Active then
								self.Active = false
								self.AutoButtonColor = false
								self.Image = client.MatIcons["Hourglass empty"]
								client.Remote.Send("ProcessCommand", string.format("%sremovetool%s%s%s%s%s", data.Prefix, data.SplitKey, data.SpecialPrefix, selected.Name, data.SplitKey, v.Name))
								if self then
									self.Image = client.MatIcons.Clear
									self.AutoButtonColor = true
									self.Active = true
								end
							end
						end
					})
					i += 1
				end
			end
			if i > 0 then
				inv:Add("TextButton", {
					Text = "Remove All Tools";
					Size = UDim2.new(1, -10, 0, 26);
					Position = UDim2.new(0, 5, 0, i*26+5);
					OnClick = function(self)
						if self.Active then
							self.Active = false
							self.AutoButtonColor = false
							self.Text = ". . ."
							client.Remote.Send("ProcessCommand", string.format("%sremovetools%s%s%s", data.Prefix, data.SplitKey, data.SpecialPrefix, selected.Name))
							wait(2)
							if self then
								self.Text = "Remove All Tools"
								self.AutoButtonColor = true
								self.Active = true
							end
						end
					end
				})
			else
				inv:Add("TextLabel", {
					Text = "This player has no tools.";
					Size = UDim2.new(1, -10, 0, 26);
					Position = UDim2.new(0, 5, 0, 0);
					BackgroundTransparency = 1;
				})
			end
			inv:ResizeCanvas(false, true, false, false, 5, 0)
		end

		local function addPlr(plr: Player)
			if plrs:FindFirstChild(plr.Name) or not plr or not plr.Parent then return end
			local backpack = plr:FindFirstChildOfClass("Backpack")
			local entry = plrs:Add("TextButton", {
				Size = UDim2.new(1, 0, 0, 35);
				Text = "  "..plr.Name;
				ToolTip = "("..plr.DisplayName..")";
				TextXAlignment = "Left";
				OnClick = function(self)
					if self.Active then
						self.Active = false
						self.AutoButtonColor = false
						selected = plr
						inv.Visible = true
						for _, v in pairs(connections) do if v then v:Disconnect() end end
						displayInv()
						self.TextColor3 = Color3.new(0.666667, 1, 1)
						for _, v in ipairs(plrs:GetChildren()) do
							if v:IsA("TextButton") and v ~= self then
								v.AutoButtonColor = true
								v.TextColor3 = Color3.new(1, 1, 1)
							end
						end
					else
						selected = nil
						inv.Visible = false
						for _, v in pairs(connections) do if v then v:Disconnect() end end
						self.AutoButtonColor = true
						self.Active = true
						self.TextColor3 = Color3.new(1, 1, 1)
					end
				end,
			})
			entry:Add("ImageLabel", {
				AnchorPoint = Vector2.new(1, 0.5);
				Size = UDim2.new(0, 16, 0, 16);
				Position = UDim2.new(1, -5, 0.5, 0);
				BackgroundTransparency = 1;
				Image = client.MatIcons.Build;
			})
			local toolCount = entry:Add("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5);
				Size = UDim2.new(0, 30, 0, 20);
				Position = UDim2.new(1, -25, 0.5, 0);
				Text = "";
				TextXAlignment = "Right";
				BackgroundTransparency = 1;
			})
			local function countTools()
				local backpack = plr:FindFirstChildOfClass("Backpack")
				if not backpack then
					toolCount.Text = "?"
					return
				end
				local c = 0
				for _, v in ipairs(backpack:GetChildren()) do
					if v:IsA("BackpackItem") then c += 1 end
				end
				if plr.Character then
					for _, v in ipairs(plr.Character:GetChildren()) do
						if v:IsA("BackpackItem") then
							c += 1
						end
					end
				end
				toolCount.Text = c
			end
			if backpack then
				backpack.ChildAdded:Connect(countTools)
				backpack.ChildRemoved:Connect(countTools)
			end
			plr.CharacterAdded:Connect(countTools)
			countTools()
			plrs:ResizeCanvas(false, true, false, false, 5, 0)
		end
		service.Players.PlayerAdded:Connect(addPlr)
		for _, p: Player in ipairs(service.Players:GetPlayers()) do addPlr(p) end
		service.Players.PlayerRemoving:Connect(function(plr: Player)
			if selected == plr then selected = nil inv:ClearAllChildren() end
			if plrs:FindFirstChild(plr.Name) then inv[plr.Name]:Destroy() end
		end)
	end)

	spawn(function()
		local tab = tabFrame:NewTab("Gear", {
			Text = "Insert Gear"
		})

		local currentId, currentAssetType = nil, nil

		tab:Add("UIPadding", {
			PaddingLeft = UDim.new(0, 5); PaddingRight = UDim.new(0, 5); PaddingTop = UDim.new(0, 5); PaddingBottom = UDim.new(0, 5);
		})

		tab:Add("TextLabel", {
			BackgroundTransparency = 1;
			Text = "Gear ID:";
			TextXAlignment = "Left";
			Size = UDim2.new(0, 60, 0, 25);
			Position = UDim2.new(0, 0, 0, 0);
		})

		local input: TextBox = tab:Add("TextBox", {
			Text = "";
			Size = UDim2.new(1, -90, 0, 25);
			Position = UDim2.new(0, 60, 0, 0);
			ClearTextOnFocus = false;
		})

		local spawnBtn = tab:Add("TextButton", {
			Size = UDim2.new(0, 130, 0, 30);
			Position = UDim2.new(1, -130, 1, -30);
			Text = "Spawn";
			TextTransparency = 0.4;
			AutoButtonColor = false;
			OnClick = function(self)
				if self.Active and currentId then
					if currentAssetType == 19 then
					self.Active = false
					self.AutoButtonColor = false
					self.Text = ". . ."
					client.Remote.Send("ProcessCommand", string.format("%sgear%s%sme%s%s", data.Prefix, data.SplitKey, data.SpecialPrefix, data.SplitKey, currentId))
					wait(2)
					if self then
						self.Text = "Spawn"
						self.AutoButtonColor = true
						self.Active = true
						end
					else
						client.UI.Make("Output", {Message = "Selected asset is not a valid gear."})
					end
				end
			end
		})

		local function load(assetId: number)
			for _, v in ipairs(tab:GetChildren()) do if v.Name == "Info" then v:Destroy() end end
			if not assetId then
				currentId, currentAssetType = nil, nil
				spawnBtn.TextTransparency = 0.4
				spawnBtn.AutoButtonColor = false
				return
			end
			spawnBtn.TextTransparency = 0
			spawnBtn.AutoButtonColor = true
			local info = service.MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset)
			currentAssetType = info.AssetTypeId
			currentId = assetId
			for i, v in ipairs({
				{"Name", info.Name},
				{"Creator", info.Creator.Name},
				{"Price", info.PriceInRobux},
				{"For sale", info.IsForSale and "Yes" or "No"},
				{"Limited", info.IsLimited and "Yes" or "No"},
				{"Limited Unique", info.IsLimitedUnique and "Yes" or "No"},
				}) do
				tab:Add("TextLabel", {
					Name = "Info";
					Text = "  "..v[1]..": ";
					BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
					Size = UDim2.new(1, -135, 0, 30);
					Position = UDim2.new(0, 0, 0, (30*(i-1))+30);
					TextXAlignment = "Left";
				}):Add("TextLabel", {
					Text = v[2];
					BackgroundTransparency = 1;
					Size = UDim2.new(0, 120, 1, 0);
					Position = UDim2.new(1, -130, 0, 0);
					TextXAlignment = "Right";
				})
			end
			local desc = tab:Add("TextLabel", {
				Name = "Info";
				Text = info.Description;
				TextScaled = true;
				TextWrapped = true;
				Size = UDim2.new(0, 130, 1, -65);
				Position = UDim2.new(1, -130, 0, 30)
			})
			desc:Add("UIPadding", {
				PaddingLeft = UDim.new(0, 5); PaddingRight = UDim.new(0, 5); PaddingTop = UDim.new(0, 5); PaddingBottom = UDim.new(0, 5);
			})
			desc:Add("UITextSizeConstraint", {
				MaxTextSize = 18; MinTextSize = 8;
			})
		end

		local submit: TextButton = tab:Add("TextButton", {
			Text = ">";
			Size = UDim2.new(0, 25, 0, 25);
			Position = UDim2.new(1, -25, 0, 0);
			OnClick = function(self)
				if self.Active then
					self.Active = false
					self.AutoButtonColor = false
					load(tonumber(input.Text))
					self.AutoButtonColor = true
					self.Active = true
				end
			end
		})

		input:GetPropertyChangedSignal("Text"):Connect(function()
			if #input.Text > 18 then input.Text = input.Text:sub(1, 18) end
		end)
		input.FocusLost:Connect(function(entered)
			input.Text = tonumber(input.Text) or ""
			if entered then load(tonumber(input.Text)) end
		end)
	end)

	window:Ready()
end
