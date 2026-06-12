return function(data, env)
	if env then
		setfenv(1, env)
	end

	local client = env.client
	local service = env.service

	local Remote = client.Remote
	local UI = client.UI

	local CanBulkPurchaseTypes = {
		2, 8, 11, 12, 17, 18, 27, 28, 29, 30, 31, 32, -- Classic
		41, 42, 43, 44, 45, 46, 47, 57, 58, -- Accessories
		48, 49, 50, 51, 52, 53, 54, 55, 56, 61, -- Animations
		64, 65, 66, 67, 68, 69, 70, 71, 72, 76, 77, -- Layered Clothing
		78, 79, 88, 89, 90 -- Other
	}

	local window = UI.Make("Window", {
		Name = "Commands",
		Title = "Commands",
		Icon = client.MatIcons["Format list bulleted"],
		Size = { 320, 340 },
		AllowMultiple = false,
	})
	if not window then
		return
	end

	local cmdData = Remote.Get("CommandListData")
	if not cmdData then
		error("Failed to get command list data")
	end

	local searchTerm = ""
	local groupBy = "Rank"
	
	local scroll = window:Add("ScrollingFrame", {
		Name = "CommandList",
		Position = UDim2.fromOffset(5, 35),
		Size = UDim2.new(1, -10, 1, -40),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	})
	if window.Dragger then
		window.Dragger.Modal = true
	end
	scroll:Add("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	for _, command in cmdData.Commands do
		command.Aliases = {}
		for _, prefix in (typeof(command.Prefix) == "table" and command.Prefix or {command.Prefix}) do
			for _, cmd in command.Commands do
				table.insert(command.Aliases, prefix .. cmd)
			end
			if #command.Commands == 0 then
				table.insert(command.Aliases, prefix)
			end
		end
	end

	local function renderCommandDetailsRow(parent, label, value)
		local row = parent:Add("Frame", {
			Size = UDim2.new(1, 0, 0, 16),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Name = label
		})
		row:Add("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5)
		})
		row:Add("TextLabel", {
			Text = label,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 14,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(0, 40, 1, 0)
		})
		row:Add("TextLabel", {
			Text = value,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 14,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, -50, 0, 16),
			Position = UDim2.fromOffset(50, 0)
		})
		return row
	end

	local function renderCommandDetails(parent, command, layoutOrder)
		local container = parent:Add("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = layoutOrder or 0
		})
		container:Add("UIPadding", {
			PaddingTop = UDim.new(0, 3),
			PaddingBottom = UDim.new(0, 3)
		})
		container:Add("UIListLayout", {
			SortOrder = Enum.SortOrder.Name,
			Padding = UDim.new(0, 3)
		})
		local cmdRank
		for _, rank in cmdData.Ranks do
			if rank.Level == command.AdminLevel then
				cmdRank = rank
				break
			end
		end
		renderCommandDetailsRow(container, "Rank", if cmdRank then `{cmdRank.Rank} ({cmdRank.Level})` else command.AdminLevel)
		if #command.Aliases > 1 then
			local str = ``
			for _, alias in command.Aliases do
				if alias == command.PrimaryAlias then continue end
				str ..= `, {alias}`
			end
			renderCommandDetailsRow(container, "Aliases", string.sub(str, 3))
		end
		if command.Description then
			renderCommandDetailsRow(container, "Desc", command.Description)
		end

		return container
	end

	local function renderRankPurchase(parent, label, buttonText, layoutOrder)
		local buyFrame = parent:Add("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = layoutOrder or 0,
		})
		buyFrame:Add("TextLabel", {
			Text = label,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromOffset(5, 0),
			TextTruncate = Enum.TextTruncate.SplitWord,
			Size = UDim2.new(1, -110, 1, -5)
		})
		local buyButton = buyFrame:Add("TextButton", {
			Text = buttonText,
			BackgroundColor3 = Color3.new(0,1,0):lerp(Color3.new(1,0,0), 0.1);
			BackgroundTransparency = 0.7;
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(1, -95, 0, 0),
			Size = UDim2.fromOffset(90, 25)
		})
		return buyFrame, buyButton
	end

	local currentDetails, currentRow

	local function renderCommands()
		local groups = {}
		local groupsInfo = {}

		for _, command in cmdData.Commands do
			if command.Hidden then continue end

			if searchTerm and #searchTerm > 0 then
				local found = false
				for _, alias in command.Aliases do
					if string.find(string.lower(alias), searchTerm, 1, true) then
						command.PrimaryAlias = alias
						found = true
						break
					end
				end
				if not found then continue end
			else
				command.PrimaryAlias = command.Aliases[1]
			end

			local groupKey
			if groupBy == "Rank" then
				groupKey = command.AdminLevel or 0
			elseif groupBy == "Category" then
				groupKey = command.Category or "Uncategorized"
			else
				groupKey = "All Commands"
			end

			if not groups[groupKey] then
				local name = tostring(groupKey)
				if groupBy == "Rank" then
					if groupKey == 0 then
						name = "Players"
					else
						for _, rank in cmdData.Ranks do
							if rank.Level == command.AdminLevel then
								name = rank.Rank
								break
							end
						end
					end
				end
				table.insert(groupsInfo, {
					Key = groupKey,
					Name = name
				})

				groups[groupKey] = {}
			end
			table.insert(groups[groupKey], command)
		end

		if groupBy == "Rank" then
			table.sort(groupsInfo, function(a, b) 
				local av = if a.Key == "Donors" then 0.5 else a.Key
				local bv = if b.Key == "Donors" then 0.5 else b.Key
				return av < bv
			end)
		else
			table.sort(groupsInfo, function(a, b) return tostring(a.Key) < tostring(b.Key) end)
		end

		for _, commands in groups do
			table.sort(commands, function(a, b) return a.Aliases[1] < b.Aliases[1] end)
		end

		for _,v in scroll:GetChildren() do
			if v:IsA("UIListLayout") then continue end
			v:Destroy()
		end

		for _, groupInfo in groupsInfo do
			local group = groups[groupInfo.Key]
			local frame = scroll:Add("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				BackgroundTransparency = 1,
			})
			frame:Add("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder
			})
			frame:Add("UIPadding", {
				PaddingBottom = UDim.new(0, 5)
			})

			if #groupsInfo > 1 then
				local groupLabel = frame:Add("TextButton", {
					Text = `<b>{groupInfo.Name}</b> ({#group})`,
					RichText = true,
					TextSize = 18,
					AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, 30),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = -2
				})

				groupLabel:Add("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5)
				})

				local expanded = true
				local arrow = groupLabel:Add("TextLabel", {
					Text = ">",
					Size = UDim2.fromOffset(20, 20),
					Position = UDim2.new(1, -20, 0.5, -10),
					BackgroundTransparency = 1,
					Rotation = 90
				})
				groupLabel.Activated:Connect(function()
					expanded = not expanded
					arrow.Rotation = (if expanded then 90 else 0)
					for _, cmd in frame:GetChildren() do
						if cmd == groupLabel or not cmd:IsA("GuiObject") then continue end
						cmd.Visible = expanded
					end
				end)
			end

			if groupBy == "Rank" then
				local rank
				for _, r in cmdData.Ranks do
					if r.Level == groupInfo.Key then
						rank = r
						break
					end
				end
				if rank and ((rank.Rank == "Donors" and not cmdData.PlayerData.isDonor) or (typeof(rank.Level) == "number" and cmdData.PlayerData.Level < rank.Level)) then
					local hasOneTime, hasSubscription = false, false
					local cheapestOneTime, cheapestSubscription = nil, nil
					local oneTimeRow, subscriptionRow = nil, nil
					local oneTimeButton, subscriptionButton = nil, nil
					local oneTimeChecking, subscriptionChecking = 0, 0
					for _, v in rank.Purchasables do
						if v.Type == Enum.InfoType.Subscription then
							hasSubscription = true
							subscriptionChecking += 1
							task.spawn(function()
								local info = service.GetSubscriptionInfo(v.Id)
								info.Id = v.Id
								info.Type = v.Type
								if not info or not info.Created or not info.IsForSale then
									subscriptionChecking -= 1
									if subscriptionChecking <= 0 and not cheapestSubscription then
										subscriptionRow:Destroy()
									end
									return
								end
								local priceTier = if info.PriceInRobux == 0 then info.PriceTier else info.PriceInRobux
								info.AppliedPriceTier = priceTier
								local displayString = `{if info.PriceInRobux == 0 then info.DisplayPrice else ` {info.PriceInRobux}`}{info.DisplaySubscriptionPeriod}`
								info.DisplayString = displayString
								if cheapestSubscription == nil or priceTier < cheapestSubscription.AppliedPriceTier then
									cheapestSubscription = info
									if subscriptionButton then
										subscriptionButton.Text = displayString
									end
								end
								subscriptionChecking -= 1
							end)
						else
							hasOneTime = true
							task.spawn(function()
								local info = service.GetProductInfo(v.Id, v.Type)
								info.Id = v.Id
								info.Type = v.Type
								if not info or not info.Created or not info.IsForSale then
									oneTimeChecking -= 1
									if oneTimeChecking <= 0 and not cheapestOneTime then
										oneTimeRow:Destroy()
									end
									return
								end
								if cheapestOneTime == nil or info.PriceInRobux < cheapestOneTime.PriceInRobux then
									cheapestOneTime = info
									if oneTimeButton then
										oneTimeButton.Text = ` {info.PriceInRobux}`
									end
								end
								oneTimeChecking -= 1
							end)
						end
					end
					if hasOneTime then
						oneTimeRow, oneTimeButton = renderRankPurchase(frame, `Unlock permanently`, if cheapestOneTime then ` {cheapestOneTime.PriceInRobux}` else `...`, -1)
						oneTimeButton.Activated:Connect(function()
							if not cheapestOneTime then return end
							if table.find(CanBulkPurchaseTypes, cheapestOneTime.AssetTypeId) then
								client.Remote.Send("PromptBulkPurchase", {cheapestOneTime.Id})
							else
								local func = if cheapestOneTime.Type == Enum.InfoType.Asset then service.MarketPlace.PromptPurchase else service.MarketPlace.PromptGamePassPurchase
								func(service.MarketPlace, service.Player, cheapestOneTime.Id)
							end
						end)
					end
					if hasSubscription then
						subscriptionRow, subscriptionButton = renderRankPurchase(frame, `Unlock with subscription`, if cheapestSubscription then cheapestSubscription.DisplayString else `...`, 0)
						subscriptionButton.Activated:Connect(function()
							if not cheapestSubscription then return end
							service.MarketPlace:PromptSubscriptionPurchase(service.Player, cheapestSubscription.Id)
						end)
					end
				end
			end

			for i, command in group do
				local str = `{command.PrimaryAlias}`
				local argStr = "";
				for _,v in (command.Args or command.Arguments) do
					argStr ..= `  &lt;{v}&gt;`
				end
				str ..= `<font color="rgb(150,150,150)">{argStr}</font>`
				local commandLabel = frame:Add("TextButton", {
					Text = str,
					RichText = true,
					TextWrapped = true,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextTransparency = if command.HasPermission then 0 else 0.4,
					LayoutOrder = i * 2
				})
				commandLabel:Add("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5)
				})
				commandLabel.Activated:Connect(function()
					if currentRow then
						currentRow:Destroy()
					end
					if currentDetails == commandLabel then
						currentDetails = nil
						return
					end
					currentDetails = commandLabel
					currentRow = renderCommandDetails(frame, command, commandLabel.LayoutOrder + 1)
				end)
			end
		end
	end

	local box = window:Add("TextBox", {
		Text = "",
		PlaceholderText = "Search...",
		Size = UDim2.new(1, -95, 0, 25),
		Position = UDim2.fromOffset(5, 5),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	box:Add("UIPadding", {
		PaddingLeft = UDim.new(0, 25),
		PaddingRight = UDim.new(0, 5)
	})
	box:Add("ImageLabel", {
		Image = client.MatIcons.Search,
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.fromOffset(-5, 5),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
	})

	box:GetPropertyChangedSignal("Text"):Connect(function()
		searchTerm = string.lower(box.Text)
		renderCommands()
	end)

	local dropdown = window:Add("Dropdown", {
		Name = "GroupBy",
		Position = UDim2.new(1, -85, 0, 5),
		Size = UDim2.fromOffset(80, 25),
		Options = { "Rank", "Category", "None" },
		Selected = groupBy,
		OnSelect = function(option)
			groupBy = option
			renderCommands()
		end
	})

	renderCommands()

	window:Ready()
end
