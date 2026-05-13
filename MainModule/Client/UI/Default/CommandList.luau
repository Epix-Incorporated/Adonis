return function(data, env)
	if env then
		setfenv(1, env)
	end

	local client = env.client
	local service = env.service

	local Remote = client.Remote
	local UI = client.UI

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

	local commands = Remote.Get("SearchCommands", "all") or {}
	local purchasables = Remote.Get("RankPurchasables") or {}
	local rankLevels = Remote.Get("RankLevels") or {}

	local searchTerm = ""
	local groupBy = "Rank"
	
	local scroll = window:Add("ScrollingFrame", {
		Name = "CommandList",
		Position = UDim2.fromOffset(10, 50),
		Size = UDim2.new(1, -20, 1, -60),
		BackgroundTransparency = 1,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
	})
	scroll:Add("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder
	})

	for _, command in commands do
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

	local currentDetails, currentRow

	local function renderCommands()
		local groups = {}
		local groupsInfo = {}

		for _, command in commands do
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
						for _, rank in rankLevels do
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
				if a.Key == "Donors" then
					return true
				elseif b.Key == "Donors" then
					return false
				else
					return tostring(a.Key) < tostring(b.Key)
				end
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

			local groupLabel = frame:Add("TextButton", {
				Text = `<b>{groupInfo.Name}</b> ({#group})`,
				RichText = true,
				TextSize = 18,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = -1
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
		Size = UDim2.new(1, -110, 0, 30),
		Position = UDim2.fromOffset(10, 10),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	box:Add("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5)
	})

	box:GetPropertyChangedSignal("Text"):Connect(function()
		searchTerm = string.lower(box.Text)
		renderCommands()
	end)

	local dropdown = window:Add("Dropdown", {
		Name = "GroupBy",
		Position = UDim2.new(1, -90, 0, 10),
		Size = UDim2.fromOffset(80, 30),
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
