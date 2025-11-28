--[[
	Explorer App Module
	
	The main explorer interface
]]

-- ADONIS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook, ModelViewer -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

local function tweenInEntry(entry, fromPos, toPos)
	entry.Position = fromPos
	entry.Indent.EntryName.TextTransparency = 1
	entry.Indent.Icon.ImageTransparency = 1
	entry.Visible = true

	local lengthScale = 1 -- for fun while I test, e.g 10 for 10 times slower

	TweenService:Create(entry, TweenInfo.new(0.2 * lengthScale, Enum.EasingStyle.Sine), { Position = toPos }):Play()
	TweenService:Create(entry.Indent.EntryName, TweenInfo.new(0.15 * lengthScale), { TextTransparency = 0 }):Play()
	TweenService:Create(entry.Indent.Icon, TweenInfo.new(0.15 * lengthScale), { ImageTransparency = 0 }):Play()
end

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	ModelViewer = Apps.ModelViewer
	Notebook = Apps.Notebook
end

local function main()
	local Explorer = {}
	local nodes, tree, listEntries, explorerOrders, searchResults, specResults = {}, {}, {}, {}, {}, {}
	local expanded
	local entryTemplate, treeFrame: Frame, toolBar, descendantAddedCon, descendantRemovingCon, itemChangedCon
	local ffa = game.FindFirstAncestorWhichIsA
	local getDescendants = game.GetDescendants
	local getTextSize = service.TextService.GetTextSize
	local updateDebounce, refreshDebounce = false, false
	local nilNode = { Obj = Instance.new("Folder") } :: any
	local idCounter = 0
	local scrollV, scrollH, selection, clipboard
	local renameBox, renamingNode, searchFunc
	local sortingEnabled, autoUpdateSearch
	local table, math = table, math
	local nilMap, nilCons = {}, {}
	local connectSignal = game.DescendantAdded.Connect
	local addObject, removeObject, moveObject = nil, nil, nil

	-- silencer, absolute hell!!!
	Explorer.NodeSorter = nil
	Explorer.IsNodeVisible = nil
	Explorer.PerformUpdate = nil
	Explorer.PerformRefresh = nil
	Explorer.Window = nil
	Explorer.InitRenameBox = nil
	Explorer.SetRenamingNode = nil
	Explorer.SetSortingEnabled = nil
	Explorer.UpdateView = nil
	Explorer.Update = nil
	Explorer.StartDrag = nil
	Explorer.NewListEntry = nil
	Explorer.Refresh = nil
	Explorer.ForceUpdate = nil
	Explorer.NodeDepth = nil
	Explorer.SetupConnections = nil
	Explorer.ViewNode = nil
	Explorer.ViewObj = nil
	Explorer.MakeNodeVisible = nil
	Explorer.ShowRightClick = nil
	Explorer.InitRightClick = nil
	Explorer.HideNilInstances = nil
	Explorer.RefreshNilInstances = nil
	Explorer.GetInstancePath = nil
	Explorer.InitInsertObject = nil
	Explorer.InitClickToSelect = nil
	Explorer.BuildSearchFunc = nil
	Explorer.DoSearch = nil
	Explorer.ClearSearch = nil
	Explorer.InitSearch = nil
	Explorer.InitEntryTemplate = nil
	Explorer.InitDelCleaner = nil
	Explorer.UpdateSelectionVisuals = nil
	Explorer.Init = nil
	Explorer.ClassIcons = nil
	Explorer.MiscIcons = nil
	Explorer.Selection = nil
	Explorer.ClickSystem = nil
	Explorer.SelectionVisualsHolder = nil
	Explorer.SelectionVisualCons = nil
	Explorer.SelectionVisualGui = nil
	Explorer.SelectionVisualBox = nil
	Explorer.Clipboard = nil
	Explorer.SearchFilters = nil
	Explorer.SearchExpanded = nil
	Explorer.Expanded = nil
	Explorer.Active = nil
	Explorer.Dragging = nil
	Explorer.ViewWidth = nil
	Explorer.Index = nil
	Explorer.EntryIndent = nil
	Explorer.FreeWidth = nil
	Explorer.GuiElems = nil
	Explorer.RightClickContext = nil
	Explorer.InsertObjectContext = nil
	Explorer.ClickToSelect_Connection = nil

	addObject = function(root)
		if nodes[root] then
			return
		end

		local isNil = false
		local rootParObj = ffa(root, "Instance")
		local par = nodes[rootParObj]

		-- Nil Handling
		if not par then
			if nilMap[root] then
				nilCons[root] = nilCons[root]
					or {
						connectSignal(root.ChildAdded, addObject),
						connectSignal(root.AncestryChanged, moveObject),
					}
				par = nilNode
				isNil = true
			else
				return
			end
		elseif nilMap[rootParObj] or par == nilNode then
			nilMap[root] = true
			nilCons[root] = nilCons[root]
				or {
					connectSignal(root.ChildAdded, addObject),
					connectSignal(root.AncestryChanged, moveObject),
				}
			isNil = true
		end

		local newNode = { Obj = root, Parent = par }
		nodes[root] = newNode

		-- Automatic sorting if expanded
		if sortingEnabled and expanded[par] and par.Sorted then
			local left, right = 1, #par
			local floor = math.floor
			local sorter = Explorer.NodeSorter
			local pos = (right == 0 and 1)

			if not pos then
				while true do
					if left >= right then
						if sorter(newNode, par[left]) then
							pos = left
						else
							pos = left + 1
						end
						break
					end

					local mid = floor((left + right) / 2)
					if sorter(newNode, par[mid]) then
						right = mid - 1
					else
						left = mid + 1
					end
				end
			end

			table.insert(par, pos, newNode)
		else
			par[#par + 1] = newNode
			par.Sorted = nil
		end

		local insts = getDescendants(root)
		for i = 1, #insts do
			local obj = insts[i]
			if nodes[obj] then
				continue
			end -- Deferred

			local par = nodes[ffa(obj, "Instance")]
			if not par then
				continue
			end
			local newNode = { Obj = obj, Parent = par }
			nodes[obj] = newNode
			par[#par + 1] = newNode

			-- Nil Handling
			if isNil then
				nilMap[obj] = true
				nilCons[obj] = nilCons[obj]
					or {
						connectSignal(obj.ChildAdded, addObject),
						connectSignal(obj.AncestryChanged, moveObject),
					}
			end
		end

		if searchFunc and autoUpdateSearch then
			searchFunc({ newNode })
		end

		if not updateDebounce and Explorer.IsNodeVisible(par) then
			if expanded[par] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	removeObject = function(root)
		local node = nodes[root]
		if not node then
			return
		end

		-- Nil Handling
		if nilMap[node.Obj] then
			moveObject(node.Obj)
			return
		end

		local par = node.Parent
		if par then
			par.HasDel = true
		end

		local function recur(root)
			for i = 1, #root do
				local node = root[i]
				if not node.Del then
					nodes[node.Obj] = nil
					if #node > 0 then
						recur(node)
					end
				end
			end
		end
		recur(node)
		node.Del = true
		nodes[root] = nil

		if par and not updateDebounce and Explorer.IsNodeVisible(par) then
			if expanded[par] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	moveObject = function(obj)
		local node = nodes[obj]
		if not node then
			return
		end

		local oldPar = node.Parent
		local newPar = nodes[ffa(obj, "Instance")]
		if oldPar == newPar then
			return
		end

		-- Nil Handling
		if not newPar then
			if nilMap[obj] then
				newPar = nilNode
			else
				return
			end
		elseif nilMap[newPar.Obj] or newPar == nilNode then
			nilMap[obj] = true
			nilCons[obj] = nilCons[obj]
				or {
					connectSignal(obj.ChildAdded, addObject),
					connectSignal(obj.AncestryChanged, moveObject),
				}
		end

		if oldPar then
			local parPos = table.find(oldPar, node)
			if parPos then
				table.remove(oldPar, parPos)
			end
		end

		node.Id = nil
		node.Parent = newPar

		if sortingEnabled and expanded[newPar] and newPar.Sorted then
			local left, right = 1, #newPar
			local floor = math.floor
			local sorter = Explorer.NodeSorter
			local pos = (right == 0 and 1)

			if not pos then
				while true do
					if left >= right then
						if sorter(node, newPar[left]) then
							pos = left
						else
							pos = left + 1
						end
						break
					end

					local mid = floor((left + right) / 2)
					if sorter(node, newPar[mid]) then
						right = mid - 1
					else
						left = mid + 1
					end
				end
			end

			table.insert(newPar, pos, node)
		else
			newPar[#newPar + 1] = node
			newPar.Sorted = nil
		end

		if searchFunc and searchResults[node] then
			local currentNode = node.Parent
			while currentNode and (not searchResults[currentNode] or expanded[currentNode] == 0) do
				expanded[currentNode] = true
				searchResults[currentNode] = true
				currentNode = currentNode.Parent
			end
		end

		if not updateDebounce and (Explorer.IsNodeVisible(newPar) or Explorer.IsNodeVisible(oldPar)) then
			if expanded[newPar] or expanded[oldPar] then
				Explorer.PerformUpdate()
			elseif not refreshDebounce then
				Explorer.PerformRefresh()
			end
		end
	end

	Explorer.ViewWidth = 0
	Explorer.Index = 0
	Explorer.EntryIndent = 20
	Explorer.FreeWidth = 32
	Explorer.GuiElems = {}

	Explorer.InitRenameBox = function()
		renameBox = create({
			{
				1,
				"TextBox",
				{
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BorderColor3 = Color3.new(0.062745101749897, 0.51764708757401, 1),
					BorderMode = 2,
					ClearTextOnFocus = false,
					Font = 3,
					Name = "RenameBox",
					PlaceholderColor3 = Color3.new(0.69803923368454, 0.69803923368454, 0.69803923368454),
					Position = UDim2.fromOffset(26, 2),
					Size = UDim2.fromOffset(200, 16),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 0,
					Visible = false,
					ZIndex = 2,
				},
			},
		})

		renameBox.Parent = Explorer.Window.GuiElems.Content.List

		renameBox.FocusLost:Connect(function()
			if not renamingNode then
				return
			end

			pcall(function()
				renamingNode.Obj.Name = renameBox.Text
			end)

			-- ADONIS
			Dex_RemoteFunction:InvokeServer("SetProperty", renamingNode.Obj, "Name", renameBox.Text)

			renamingNode = nil
			Explorer.Refresh()
		end)

		renameBox.Focused:Connect(function()
			renameBox.SelectionStart = 1
			renameBox.CursorPosition = #renameBox.Text + 1
		end)
	end

	Explorer.SetRenamingNode = function(node)
		renamingNode = node
		renameBox.Text = tostring(node.Obj)
		renameBox:CaptureFocus()
		Explorer.Refresh()
	end

	Explorer.SetSortingEnabled = function(val)
		sortingEnabled = val
		Settings.Explorer.Sorting = val
	end

	Explorer.UpdateView = function()
		local maxNodes = math.ceil(treeFrame.AbsoluteSize.Y / 20)
		local maxX = treeFrame.AbsoluteSize.X
		local totalWidth = Explorer.ViewWidth + Explorer.FreeWidth

		scrollV.VisibleSpace = maxNodes
		scrollV.TotalSpace = #tree + 1
		scrollH.VisibleSpace = maxX
		scrollH.TotalSpace = totalWidth

		scrollV.Gui.Visible = #tree + 1 > maxNodes
		scrollH.Gui.Visible = totalWidth > maxX

		local oldSize = treeFrame.Size
		treeFrame.Size = UDim2.new(1, (scrollV.Gui.Visible and -16 or 0), 1, (scrollH.Gui.Visible and -39 or -23))
		if oldSize ~= treeFrame.Size then
			Explorer.UpdateView()
		else
			scrollV:Update()
			scrollH:Update()

			renameBox.Size = UDim2.fromOffset(maxX - 100, 16)

			if scrollV.Gui.Visible and scrollH.Gui.Visible then
				scrollV.Gui.Size = UDim2.new(0, 16, 1, -39)
				scrollH.Gui.Size = UDim2.new(1, -16, 0, 16)
				Explorer.Window.GuiElems.Content.ScrollCorner.Visible = true
			else
				scrollV.Gui.Size = UDim2.new(0, 16, 1, -23)
				scrollH.Gui.Size = UDim2.new(1, 0, 0, 16)
				Explorer.Window.GuiElems.Content.ScrollCorner.Visible = false
			end

			Explorer.Index = scrollV.Index
		end
	end

	Explorer.NodeSorter = function(a, b)
		if a.Del or b.Del then
			return false
		end -- Ghost node

		local aClass = a.Class
		local bClass = b.Class
		if not aClass then
			aClass = a.Obj.ClassName
			a.Class = aClass
		end
		if not bClass then
			bClass = b.Obj.ClassName
			b.Class = bClass
		end

		local aOrder = explorerOrders[aClass]
		local bOrder = explorerOrders[bClass]
		if not aOrder then
			aOrder = RMD.Classes[aClass] and tonumber(RMD.Classes[aClass].ExplorerOrder) or 9999
			explorerOrders[aClass] = aOrder
		end
		if not bOrder then
			bOrder = RMD.Classes[bClass] and tonumber(RMD.Classes[bClass].ExplorerOrder) or 9999
			explorerOrders[bClass] = bOrder
		end

		if aOrder ~= bOrder then
			return aOrder < bOrder
		else
			local aName, bName = tostring(a.Obj), tostring(b.Obj)
			if aName ~= bName then
				return aName < bName
			elseif aClass ~= bClass then
				return aClass < bClass
			else
				local aId = a.Id
				if not aId then
					aId = idCounter
					idCounter = (idCounter + 0.001) % 999999999
					a.Id = aId
				end
				local bId = b.Id
				if not bId then
					bId = idCounter
					idCounter = (idCounter + 0.001) % 999999999
					b.Id = bId
				end
				return aId < bId
			end
		end
	end

	Explorer.Update = function()
		table.clear(tree)
		local maxNameWidth, maxDepth, count = 0, 1, 1
		local nameCache = {}
		local font = Enum.Font.SourceSans
		local size = Vector2.new(math.huge, 20)
		local useNameWidth = Settings.Explorer.UseNameWidth
		local tSort = table.sort
		local sortFunc = Explorer.NodeSorter
		local isSearching = (expanded == Explorer.SearchExpanded)
		local textServ = service.TextService

		local function recur(root, depth)
			if depth > maxDepth then
				maxDepth = depth
			end
			depth = depth + 1
			if sortingEnabled and not root.Sorted then
				tSort(root, sortFunc)
				root.Sorted = true
			end
			for i = 1, #root do
				local n = root[i]

				if (isSearching and not searchResults[n]) or n.Del then
					continue
				end

				if useNameWidth then
					local nameWidth = n.NameWidth
					if not nameWidth then
						local objName = tostring(n.Obj)
						nameWidth = nameCache[objName]
						if not nameWidth then
							nameWidth = getTextSize(textServ, objName, 14, font, size).X
							nameCache[objName] = nameWidth
						end
						n.NameWidth = nameWidth
					end
					if nameWidth > maxNameWidth then
						maxNameWidth = nameWidth
					end
				end

				tree[count] = n
				count = count + 1
				if expanded[n] and #n > 0 then
					recur(n, depth)
				end
			end
		end

		recur(nodes[game], 1)

		-- Nil Instances
		if env.getnilinstances then
			if not (isSearching and not searchResults[nilNode]) then
				tree[count] = nilNode
				count = count + 1
				if expanded[nilNode] then
					recur(nilNode, 2)
				end
			end
		end

		Explorer.MaxNameWidth = maxNameWidth
		Explorer.MaxDepth = maxDepth
		Explorer.ViewWidth = useNameWidth and Explorer.EntryIndent * maxDepth + maxNameWidth + 26
			or Explorer.EntryIndent * maxDepth + 226
		Explorer.UpdateView()
	end

	Explorer.StartDrag = function(offX, offY)
		if Explorer.Dragging then
			return
		end
		Explorer.Dragging = true

		local dragTree = treeFrame:Clone()
		dragTree:ClearAllChildren()

		for i, v in pairs(listEntries) do
			local node = tree[i + Explorer.Index]
			if node and selection.Map[node] then
				local clone = v:Clone()
				clone.Active = false
				clone.Indent.Expand.Visible = false
				clone.Parent = dragTree
			end
		end

		local newGui = Instance.new("ScreenGui")
		newGui.DisplayOrder = Main.DisplayOrders.Menu
		newGui.ResetOnSpawn = false
		dragTree.Parent = newGui
		Lib.ShowGui(newGui)

		local dragOutline = create({
			{
				1,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Name = "DragSelect",
					Size = UDim2.fromScale(1, 1),
				},
			},
			{
				2,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 1 },
					Size = UDim2.fromScale(1, 0),
					ZIndex = 2,
				},
			},
			{
				3,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 1 },
					Position = UDim2.new(0, 0, 1, -1),
					Size = UDim2.new(1, 0, 0, 1),
					ZIndex = 2,
				},
			},
			{
				4,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 1 },
					Size = UDim2.new(0, 1, 1, 0),
					ZIndex = 2,
				},
			},
			{
				5,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 1 },
					Position = UDim2.new(1, -1, 0, 0),
					Size = UDim2.new(0, 1, 1, 0),
					ZIndex = 2,
				},
			},
		})
		dragOutline.Parent = treeFrame

		local mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse()
		local function move()
			local posX = mouse.X - offX
			local posY = mouse.Y - offY
			dragTree.Position = UDim2.fromOffset(posX, posY)

			for i = 1, #listEntries do
				local entry = listEntries[i]
				if Lib.CheckMouseInGui(entry) then
					dragOutline.Position =
						UDim2.fromOffset(entry.Indent.Position.X.Offset - scrollH.Index, entry.Position.Y.Offset)
					dragOutline.Size = UDim2.fromOffset(entry.Size.X.Offset - entry.Indent.Position.X.Offset, 20)
					dragOutline.Visible = true
					return
				end
			end
			dragOutline.Visible = false
		end
		move()

		local input = service.UserInputService
		local mouseEvent, releaseEvent

		mouseEvent = input.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				move()
			end
		end)

		releaseEvent = input.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				releaseEvent:Disconnect()
				mouseEvent:Disconnect()
				newGui:Destroy()
				dragOutline:Destroy()
				Explorer.Dragging = false

				for i = 1, #listEntries do
					if Lib.CheckMouseInGui(listEntries[i]) then
						local node = tree[i + Explorer.Index]
						if node then
							if selection.Map[node] then
								return
							end
							local newPar = node.Obj
							local sList = selection.List
							for i = 1, #sList do
								local n = sList[i]
								pcall(function()
									n.Obj.Parent = newPar

									-- ADONIS
									Dex_RemoteFunction:InvokeServer("SetProperty", n.Obj, "Parent", newPar)
								end)
							end
							Explorer.ViewNode(sList[1])
						end
						break
					end
				end
			end
		end)
	end

	Explorer.NewListEntry = function(index)
		local newEntry = entryTemplate:Clone()
		newEntry.Position = UDim2.fromOffset(0, 20 * (index - 1))

		local isRenaming = false

		newEntry.InputBegan:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or selection.Map[node] or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			newEntry.Indent.BackgroundColor3 = Settings.Theme.Button
			newEntry.Indent.BorderSizePixel = 0
			newEntry.Indent.BackgroundTransparency = 0
		end)

		newEntry.InputEnded:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or selection.Map[node] or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			newEntry.Indent.BackgroundTransparency = 1
		end)

		newEntry.MouseButton1Down:Connect(function() end)

		newEntry.MouseButton1Up:Connect(function() end)

		newEntry.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local releaseEvent, mouseEvent

				local mouse = Main.Mouse or plr:GetMouse()
				local startX = mouse.X
				local startY = mouse.Y

				local listOffsetX = startX - treeFrame.AbsolutePosition.X
				local listOffsetY = startY - treeFrame.AbsolutePosition.Y

				releaseEvent = game:GetService("UserInputService").InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						releaseEvent:Disconnect()
						mouseEvent:Disconnect()
					end
				end)

				mouseEvent = game:GetService("UserInputService").InputChanged:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						local deltaX = mouse.X - startX
						local deltaY = mouse.Y - startY
						local dist = math.sqrt(deltaX ^ 2 + deltaY ^ 2)

						if dist > 5 then
							releaseEvent:Disconnect()
							mouseEvent:Disconnect()
							isRenaming = false
							Explorer.StartDrag(listOffsetX, listOffsetY)
						end
					end
				end)
			end
		end)

		newEntry.MouseButton2Down:Connect(function() end)

		newEntry.Indent.Expand.InputBegan:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			Explorer.MiscIcons:DisplayByKey(
				newEntry.Indent.Expand.Icon,
				expanded[node] and "Collapse_Over" or "Expand_Over"
			)
		end)

		newEntry.Indent.Expand.InputEnded:Connect(function(input)
			local node = tree[index + Explorer.Index]
			if not node or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			Explorer.MiscIcons:DisplayByKey(newEntry.Indent.Expand.Icon, expanded[node] and "Collapse" or "Expand")
		end)

		newEntry.Indent.Expand.MouseButton1Down:Connect(function()
			local node = tree[index + Explorer.Index]
			if not node or #node == 0 then
				return
			end

			expanded[node] = not expanded[node]
			Explorer.Update()
			Explorer.Refresh()

			if expanded[node] then
				local arrowPos = newEntry.Indent.Expand.AbsolutePosition
				local framePos = treeFrame.AbsolutePosition

				for _, v in ipairs(node) do
					local i = table.find(tree, v)
					if i then
						local listIndex = i - Explorer.Index
						local entry = listEntries[listIndex]
						if entry then
							local X = arrowPos.X - framePos.X
							local Y = arrowPos.Y - framePos.Y
							local from = UDim2.fromOffset(X, Y)
							local to = entry.Position
							tweenInEntry(entry, from, to)
						end
					end
				end
			end

			local targetAngle = expanded[node] and 360 or 0 -- don't ask.
			TweenService
				:Create(newEntry.Indent.Expand, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Rotation = targetAngle })
				:Play()
		end)

		newEntry.Parent = treeFrame
		return newEntry
	end

	Explorer.Refresh = function()
		local maxNodes = math.max(math.ceil(treeFrame.AbsoluteSize.Y / 20), 0)
		local renameNodeVisible = false
		local isa = game.IsA

		for i = 1, maxNodes do
			local entry = listEntries[i]
			if not listEntries[i] then
				entry = Explorer.NewListEntry(i)
				listEntries[i] = entry
				Explorer.ClickSystem:Add(entry)
			end

			local node = tree[i + Explorer.Index]
			if node then
				local obj = node.Obj
				local depth = Explorer.EntryIndent * Explorer.NodeDepth(node)

				entry.Visible = true
				entry.Position = UDim2.fromOffset(-scrollH.Index, entry.Position.Y.Offset)
				entry.Size = UDim2.fromOffset(Explorer.ViewWidth, 20)
				entry.Indent.EntryName.Text = tostring(node.Obj)
				entry.Indent.Position = UDim2.fromOffset(depth, 0)
				entry.Indent.Size = UDim2.fromScale(1, 1) - UDim2.fromOffset(depth, 0)
				entry.Indent.EntryName.TextTruncate = (
					Settings.Explorer.UseNameWidth and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
				)

				if (isa(obj, "LocalScript") or isa(obj, "Script")) and obj.Disabled then
					Explorer.MiscIcons:DisplayByKey(
						entry.Indent.Icon,
						isa(obj, "LocalScript") and "LocalScript_Disabled" or "Script_Disabled"
					)
				else
					local rmdEntry = RMD.Classes[obj.ClassName]
					Explorer.ClassIcons:Display(entry.Indent.Icon, rmdEntry and rmdEntry.ExplorerImageIndex or 0)
				end

				if selection.Map[node] then
					entry.Indent.BackgroundColor3 = Settings.Theme.ListSelection
					entry.Indent.BorderSizePixel = 0
					entry.Indent.BackgroundTransparency = 0
				else
					if Lib.CheckMouseInGui(entry) then
						entry.Indent.BackgroundColor3 = Settings.Theme.Button
					else
						entry.Indent.BackgroundTransparency = 1
					end
				end

				if node == renamingNode then
					renameNodeVisible = true
					renameBox.Position = UDim2.fromOffset(depth + 25 - scrollH.Index, entry.Position.Y.Offset + 2)
					renameBox.Visible = true
				end

				if #node > 0 and expanded[node] ~= 0 then
					if Lib.CheckMouseInGui(entry.Indent.Expand) then
						Explorer.MiscIcons:DisplayByKey(
							entry.Indent.Expand.Icon,
							expanded[node] and "Collapse_Over" or "Expand_Over"
						)
					else
						Explorer.MiscIcons:DisplayByKey(
							entry.Indent.Expand.Icon,
							expanded[node] and "Collapse" or "Expand"
						)
					end
					entry.Indent.Expand.Visible = true
				else
					entry.Indent.Expand.Visible = false
				end
			else
				entry.Visible = false
			end
		end

		if not renameNodeVisible then
			renameBox.Visible = false
		end

		for i = maxNodes + 1, #listEntries do
			Explorer.ClickSystem:Remove(listEntries[i])
			listEntries[i]:Destroy()
			listEntries[i] = nil
		end
	end

	Explorer.PerformUpdate = function(instant)
		updateDebounce = true
		Lib.FastWait(not instant and 0.1)
		if not updateDebounce then
			return
		end
		updateDebounce = false
		if not Explorer.Window:IsVisible() then
			return
		end
		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.ForceUpdate = function(norefresh)
		updateDebounce = false
		Explorer.Update()
		if not norefresh then
			Explorer.Refresh()
		end
	end

	Explorer.PerformRefresh = function()
		refreshDebounce = true
		Lib.FastWait(0.1)
		refreshDebounce = false
		if updateDebounce or not Explorer.Window:IsVisible() then
			return
		end
		Explorer.Refresh()
	end

	Explorer.IsNodeVisible = function(node)
		if not node then
			return
		end

		local curNode = node.Parent
		while curNode do
			if not expanded[curNode] then
				return false
			end
			curNode = curNode.Parent
		end
		return true
	end

	Explorer.NodeDepth = function(node)
		local depth = 0

		if node == nilNode then
			return 1
		end

		local curNode = node.Parent
		while curNode do
			if curNode == nilNode then
				depth = depth + 1
			end
			curNode = curNode.Parent
			depth = depth + 1
		end
		return depth
	end

	Explorer.SetupConnections = function()
		if descendantAddedCon then
			descendantAddedCon:Disconnect()
		end
		if descendantRemovingCon then
			descendantRemovingCon:Disconnect()
		end
		if itemChangedCon then
			itemChangedCon:Disconnect()
		end

		if Main.Elevated then
			descendantAddedCon = game.DescendantAdded:Connect(addObject)
			descendantRemovingCon = game.DescendantRemoving:Connect(removeObject)
		else
			descendantAddedCon = game.DescendantAdded:Connect(function(obj)
				pcall(addObject, obj)
			end)
			descendantRemovingCon = game.DescendantRemoving:Connect(function(obj)
				pcall(removeObject, obj)
			end)
		end

		for obj, node in pairs(nodes) do
			obj.AncestryChanged:Connect(function(_, _)
				if nodes[obj] then
					moveObject(obj)
				end
			end)
			if Settings.Explorer.UseNameWidth then
				obj:GetPropertyChangedSignal("Name"):Connect(function()
					if nodes[obj] then
						nodes[obj].NameWidth = nil
					end
				end)
			end
		end
	end

	Explorer.ViewNode = function(node)
		if not node then
			return
		end

		Explorer.MakeNodeVisible(node)
		Explorer.ForceUpdate(true)
		local visibleSpace = scrollV.VisibleSpace

		for i, v in next, tree do
			if v == node then
				local relative = i - 1
				if Explorer.Index > relative then
					scrollV.Index = relative
				elseif Explorer.Index + visibleSpace - 1 <= relative then
					scrollV.Index = relative - visibleSpace + 2
				end
			end
		end

		scrollV:Update()
		Explorer.Index = scrollV.Index
		Explorer.Refresh()
	end

	Explorer.ViewObj = function(obj)
		Explorer.ViewNode(nodes[obj])
	end

	Explorer.MakeNodeVisible = function(node, expandRoot)
		if not node then
			return
		end

		local hasExpanded = false

		if expandRoot and not expanded[node] then
			expanded[node] = true
			hasExpanded = true
		end

		local currentNode = node.Parent
		while currentNode do
			hasExpanded = true
			expanded[currentNode] = true
			currentNode = currentNode.Parent
		end

		if hasExpanded and not updateDebounce then
			task.spawn(Explorer.PerformUpdate, true)
		end
	end

	Explorer.ShowRightClick = function()
		local context = Explorer.RightClickContext
		context:Clear()

		local sList = selection.List
		local sMap = selection.Map
		local emptyClipboard = #clipboard == 0
		local presentClasses = {}
		local apiClasses = API.Classes

		for i = 1, #sList do
			local node = sList[i]
			local class = node.Class
			if not class then
				class = node.Obj.ClassName
				node.Class = class
			end

			local curClass = apiClasses[class]
			while curClass and not presentClasses[curClass.Name] do
				presentClasses[curClass.Name] = true
				curClass = curClass.Superclass
			end
		end

		if not presentClasses["Player"] then
			context:AddRegistered("CUT")
			context:AddRegistered("COPY")
		end
		context:AddRegistered("PASTE", emptyClipboard)
		if not presentClasses["Player"] then
			context:AddRegistered("DUPLICATE")
		end
		context:AddRegistered("DELETE")
		if not presentClasses["Player"] then
			context:AddRegistered("RENAME", #sList ~= 1)
		end

		context:AddDivider()
		if not presentClasses["Player"] then
			context:AddRegistered("GROUP")
			context:AddRegistered("UNGROUP")
		end
		context:AddRegistered("SELECT_CHILDREN")
		context:AddRegistered("JUMP_TO_PARENT")
		context:AddRegistered("EXPAND_ALL")
		context:AddRegistered("COLLAPSE_ALL")

		context:AddDivider()
		if expanded == Explorer.SearchExpanded then
			context:AddRegistered("CLEAR_SEARCH_AND_JUMP_TO")
		end
		if env.setclipboard then
			context:AddRegistered("COPY_PATH")
		end
		context:AddRegistered("INSERT_OBJECT")
		--context:AddRegistered("SAVE_INST")
		if
			presentClasses["RemoteEvent"]
			or presentClasses["RemoteFunction"]
			or presentClasses["BindableEvent"]
			or presentClasses["BindableFunction"]
		then
			context:AddRegistered("CALL_FUNCTION")
		end
		--context:AddRegistered("VIEW_CONNECTIONS")
		--context:AddRegistered("GET_REFERENCES")
		--context:AddRegistered("VIEW_API")
		context:AddRegistered("VIEW_DESCRIPTION")

		context:QueueDivider()

		if presentClasses["BasePart"] or presentClasses["Model"] then
			context:AddRegistered("TELEPORT_TO")
			context:AddRegistered("VIEW_MODEL")
			context:AddRegistered("VIEW_OBJECT")
		end

		if presentClasses["Player"] then
			context:AddRegistered("SELECT_CHARACTER")
		end

		if sMap[nilNode] then
			context:AddRegistered("REFRESH_NIL")
			context:AddRegistered("HIDE_NIL")
		end

		Explorer.LastRightClickX, Explorer.LastRightClickY = Main.Mouse.X, Main.Mouse.Y
		context:Show()
	end

	Explorer.InitRightClick = function()
		local context = Lib.ContextMenu.new()

		context:Register("CUT", {
			Name = "Cut",
			IconMap = Explorer.MiscIcons,
			Icon = "Cut",
			DisabledIcon = "Cut_Disabled",
			Shortcut = "Ctrl+Z",
			OnClick = function()
				local destroy, clone = game.Destroy, game.Clone
				local sList, newClipboard = selection.List, {}
				Dex_RemoteFunction:InvokeServer("ClearClipboard") -- ADONIS

				local count = 1
				for i = 1, #sList do
					local inst = sList[i].Obj

					-- ADONIS
					Dex_RemoteFunction:InvokeServer("Copy", inst)
					if inst then -- Improvise
						newClipboard[count] = inst
						count = count + 1
					end

					--[[local s,cloned = pcall(clone,inst)
				if s and cloned then
					newClipboard[count] = cloned
					count = count + 1
				end
				pcall(destroy,inst)]]

					-- ADONIS
					Dex_RemoteFunction:InvokeServer("Destroy", inst)
				end
				clipboard = newClipboard
				selection:Clear()
			end,
		})

		local CallFunctionWindow = Lib.Window.new()
		CallFunctionWindow:SetTitle("Call: Unknown")
		CallFunctionWindow:Resize(300, 130)
		CallFunctionWindow.Resizable = false
		CallFunctionWindow.GuiElems.Main.Position = UDim2.new(0.5, -300 / 2, 0.5, -130 / 2)

		local content = CallFunctionWindow.GuiElems.Content
		local layout = Instance.new("UIListLayout")
		layout.Parent = content
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -16, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Settings.Theme.TextPrimary or Color3.new(1, 1, 1)
		lbl.Font = Enum.Font.SourceSansBold
		lbl.TextSize = 14
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = "Arguments:"
		lbl.LayoutOrder = 1
		lbl.Parent = content

		local tb = Instance.new("TextBox")
		tb.Size = UDim2.new(1, -16, 0, 30)
		tb.BackgroundColor3 = Settings.Theme.InputBackground or Color3.fromRGB(30, 30, 30)
		tb.TextColor3 = Settings.Theme.TextPrimary or Color3.new(1, 1, 1)
		tb.Font = Enum.Font.SourceSans
		tb.PlaceholderText = [[e.g. "player1", 42, true]]
		tb.Text = ""
		tb.ClearTextOnFocus = false
		tb.TextXAlignment = Enum.TextXAlignment.Left
		tb.TextSize = 14
		tb.LayoutOrder = 2
		tb.Parent = content

		local uiCorner = Instance.new("UICorner")
		uiCorner.Parent = tb
		uiCorner.CornerRadius = UDim.new(0, 4)

		local buttoncontainer = Instance.new("Frame")
		buttoncontainer.Size = UDim2.new(1, -16, 0, 30)
		buttoncontainer.BackgroundTransparency = 1
		buttoncontainer.LayoutOrder = 3
		buttoncontainer.Parent = content

		local filler = Instance.new("Frame")
		filler.Size = UDim2.new(1, -80, 1, 0)
		filler.BackgroundTransparency = 1
		filler.Parent = buttoncontainer

		local call = Instance.new("TextButton")
		call.Size = UDim2.new(0, 80, 1, 0)
		call.Position = UDim2.new(1, -80, 0, 0)
		call.BackgroundColor3 = Settings.Theme.ButtonPrimary or Color3.fromRGB(0, 120, 215)
		call.TextColor3 = Settings.Theme.TextButton or Color3.new(1, 1, 1)
		call.Font = Enum.Font.SourceSansBold
		call.TextSize = 14
		call.Text = "Call"
		call.Parent = buttoncontainer

		local btnCorner = Instance.new("UICorner")
		btnCorner.Parent = call
		btnCorner.CornerRadius = UDim.new(0, 4)

		local function activate()
			local obj = CallFunctionWindow.currentObj
			local text = tb.Text or ""

			local argv = {}
			for token in string.gmatch(text, "[^,]+") do
				local t = token:match("^%s*(.-)%s*$")
				local n = tonumber(t)
				if n then
					argv[#argv + 1] = n
				elseif t:lower() == "true" then
					argv[#argv + 1] = true
				elseif t:lower() == "false" then
					argv[#argv + 1] = false
				else
					local inner = t:match('^"(.-)"$') or t:match("^'(.-)'$")
					argv[#argv + 1] = inner or t
				end
			end

			local ok, err = pcall(function()
				if obj:IsA("RemoteFunction") then
					obj:InvokeServer(unpack(argv))
				elseif obj:IsA("BindableFunction") then
					obj:Invoke(unpack(argv))
				elseif obj:IsA("RemoteEvent") then
					obj:FireServer(unpack(argv))
				elseif obj:IsA("BindableEvent") then
					obj:Fire(unpack(argv))
				end
			end)
			if not ok then
				warn("Failed to call " .. obj:GetFullName() .. ":", err)
			end

			CallFunctionWindow:Hide()
		end

		tb.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				activate()
			end
		end)

		call.MouseButton1Click:Connect(activate)

		local InstanceInfoWindow = Lib.Window.new()
		InstanceInfoWindow:SetTitle("Unknown")
		InstanceInfoWindow:Resize(280, 120)
		InstanceInfoWindow.Resizable = false
		InstanceInfoWindow.GuiElems.Main.Position = UDim2.new(0.5, -280 / 2, 0.5, -120 / 2)

		local content = InstanceInfoWindow.GuiElems.Content

		local layout = Instance.new("UIListLayout")
		layout.Parent = content
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top

		local description = Instance.new("TextLabel")
		description.Size = UDim2.new(1, -16, 0, 80)
		description.BackgroundTransparency = 1
		description.Font = Enum.Font.SourceSans
		description.TextSize = 14
		description.TextWrapped = true
		description.TextXAlignment = Enum.TextXAlignment.Left
		description.TextYAlignment = Enum.TextYAlignment.Top
		description.TextColor3 = Settings.Theme.TextSecondary or Color3.fromRGB(200, 200, 200)
		description.LayoutOrder = 2
		description.Parent = content

		context:Register("COPY", {
			Name = "Copy",
			IconMap = Explorer.MiscIcons,
			Icon = "Copy",
			DisabledIcon = "Copy_Disabled",
			Shortcut = "Ctrl+C",
			OnClick = function()
				local clone = game.Clone
				local sList, newClipboard = selection.List, {}
				Dex_RemoteFunction:InvokeServer("ClearClipboard") -- ADONIS

				local count = 1
				for i = 1, #sList do
					local inst = sList[i].Obj
					local s, cloned = pcall(clone, inst)

					-- ADONIS
					Dex_RemoteFunction:InvokeServer("Copy", inst)

					if s and cloned then
						newClipboard[count] = cloned
						count = count + 1
					end
				end
				clipboard = newClipboard
			end,
		})

		context:Register("PASTE", {
			Name = "Paste Into",
			IconMap = Explorer.MiscIcons,
			Icon = "Paste",
			DisabledIcon = "Paste_Disabled",
			Shortcut = "Ctrl+Shift+V",
			OnClick = function()
				local sList = selection.List
				local newSelection = {}
				local count = 1
				for i = 1, #sList do
					local node = sList[i]
					local inst = node.Obj
					Explorer.MakeNodeVisible(node, true)

					-- ADONIS
					local pastedObjects = Dex_RemoteFunction:InvokeServer("Paste", inst)

					for k, v in ipairs(pastedObjects) do
						local cloned = v

						local clonedNode = nodes[cloned]
						if clonedNode then
							newSelection[count] = clonedNode
							count = count + 1
						end
					end

					--[[for c = 1,#clipboard do
					local cloned = clipboard[c]:Clone()
					if cloned then
						cloned.Parent = inst
						local clonedNode = nodes[cloned]
						if clonedNode then newSelection[count] = clonedNode count = count + 1 end
					end
				end]]
				end
				selection:SetTable(newSelection)

				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				end
			end,
		})

		context:Register("DUPLICATE", {
			Name = "Duplicate",
			IconMap = Explorer.MiscIcons,
			Icon = "Copy",
			DisabledIcon = "Copy_Disabled",
			Shortcut = "Ctrl+D",
			OnClick = function()
				local clone = game.Clone
				local sList = selection.List
				local newSelection = {}
				local count = 1
				for i = 1, #sList do
					local node = sList[i]
					local inst = node.Obj
					local instPar = node.Parent and node.Parent.Obj
					Explorer.MakeNodeVisible(node)

					-- ADONIS
					local cloned = Dex_RemoteFunction:InvokeServer("Duplicate", inst, instPar)

					if cloned then
						local clonedNode = nodes[cloned]
						if clonedNode then
							newSelection[count] = clonedNode
							count = count + 1
						end
					end

					--[[local s,cloned = pcall(clone,inst)
				if s and cloned then
					cloned.Parent = instPar
					local clonedNode = nodes[cloned]
					if clonedNode then newSelection[count] = clonedNode count = count + 1 end
				end]]
				end

				selection:SetTable(newSelection)
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				end
			end,
		})

		context:Register("DELETE", {
			Name = "Delete",
			IconMap = Explorer.MiscIcons,
			Icon = "Delete",
			DisabledIcon = "Delete_Disabled",
			Shortcut = "Del",
			OnClick = function()
				local destroy = game.Destroy
				local sList = selection.List
				for i = 1, #sList do
					pcall(function()
						if not sList[i].Obj:IsA("Player") then
							destroy(sList[i].Obj)
						end
					end)

					-- ADONIS
					Dex_RemoteFunction:InvokeServer("Destroy", sList[i].Obj)
				end
				selection:Clear()
			end,
		})

		context:Register("RENAME", {
			Name = "Rename",
			IconMap = Explorer.MiscIcons,
			Icon = "Rename",
			DisabledIcon = "Rename_Disabled",
			Shortcut = "F2",
			OnClick = function()
				local sList = selection.List
				if sList[1] then
					Explorer.SetRenamingNode(sList[1])
				end
			end,
		})

		context:Register("GROUP", {
			Name = "Group",
			IconMap = Explorer.MiscIcons,
			Icon = "Group",
			DisabledIcon = "Group_Disabled",
			Shortcut = "Ctrl+G",
			OnClick = function()
				local sList = selection.List
				if #sList == 0 then
					return
				end

				--local model = Instance.new("Model",sList[#sList].Obj.Parent)
				local model = Dex_RemoteFunction:InvokeServer("InstanceNew", "Model", sList[#sList].Obj.Parent)
				if not model then
					model = Instance.new("Model")
					model.Parent = sList[#sList].Obj.Parent
				end
				for i = 1, #sList do
					pcall(function()
						sList[i].Obj.Parent = model
					end)

					Dex_RemoteFunction:InvokeServer("SetProperty", sList[i].Obj, "Parent", model)
				end

				if nodes[model] then
					selection:Set(nodes[model])
					Explorer.ViewNode(nodes[model])
				end
			end,
		})

		context:Register("UNGROUP", {
			Name = "Ungroup",
			IconMap = Explorer.MiscIcons,
			Icon = "Ungroup",
			DisabledIcon = "Ungroup_Disabled",
			Shortcut = "Ctrl+U",
			OnClick = function()
				local newSelection = {}
				local count = 1
				local isa = game.IsA

				local function ungroup(node)
					local par = node.Parent.Obj
					local ch = {}
					local chCount = 1

					for i = 1, #node do
						local n = node[i]
						newSelection[count] = n
						ch[chCount] = n
						count = count + 1
						chCount = chCount + 1
					end

					for i = 1, #ch do
						pcall(function()
							ch[i].Obj.Parent = par
						end)

						Dex_RemoteFunction:InvokeServer("SetProperty", ch[i].Obj, "Parent", par or workspace)
					end

					node.Obj:Destroy()
				end

				for i, v in next, selection.List do
					if isa(v.Obj, "Model") then
						ungroup(v)
					end
				end

				selection:SetTable(newSelection)
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				end
			end,
		})

		context:Register("SELECT_CHILDREN", {
			Name = "Select Children",
			IconMap = Explorer.MiscIcons,
			Icon = "SelectChildren",
			DisabledIcon = "SelectChildren_Disabled",
			OnClick = function()
				local newSelection = {}
				local count = 1
				local sList = selection.List

				for i = 1, #sList do
					local node = sList[i]
					for ind = 1, #node do
						local cNode = node[ind]
						if ind == 1 then
							Explorer.MakeNodeVisible(cNode)
						end

						newSelection[count] = cNode
						count = count + 1
					end
				end

				selection:SetTable(newSelection)
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				else
					Explorer.Refresh()
				end
			end,
		})

		context:Register("JUMP_TO_PARENT", {
			Name = "Jump to Parent",
			IconMap = Explorer.MiscIcons,
			Icon = "JumpToParent",
			OnClick = function()
				local newSelection = {}
				local count = 1
				local sList = selection.List

				for i = 1, #sList do
					local node = sList[i]
					if node.Parent then
						newSelection[count] = node.Parent
						count = count + 1
					end
				end

				selection:SetTable(newSelection)
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				else
					Explorer.Refresh()
				end
			end,
		})

		context:Register("TELEPORT_TO", {
			Name = "Teleport To",
			IconMap = Explorer.MiscIcons,
			Icon = "TeleportTo",
			OnClick = function()
				local sList = selection.List
				local isa = game.IsA

				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if not hrp then
					return
				end

				for i = 1, #sList do
					local node = sList[i]

					if isa(node.Obj, "BasePart") then
						hrp.CFrame = node.Obj.CFrame + Settings.Explorer.TeleportToOffset
						break
					elseif isa(node.Obj, "Model") then
						if node.Obj.PrimaryPart then
							hrp.CFrame = node.Obj.PrimaryPart.CFrame + Settings.Explorer.TeleportToOffset
							break
						else
							local part = node.Obj:FindFirstChildWhichIsA("BasePart", true)
							if part and nodes[part] then
								hrp.CFrame = nodes[part].Obj.CFrame + Settings.Explorer.TeleportToOffset
							end
						end
					end
				end
			end,
		})

		context:Register("EXPAND_ALL", {
			Name = "Expand All",
			OnClick = function()
				local sList = selection.List

				local function expand(node)
					expanded[node] = true
					for i = 1, #node do
						if #node[i] > 0 then
							expand(node[i])
						end
					end
				end

				for i = 1, #sList do
					expand(sList[i])
				end

				Explorer.ForceUpdate()
			end,
		})

		context:Register("COLLAPSE_ALL", {
			Name = "Collapse All",
			OnClick = function()
				local sList = selection.List

				local function expand(node)
					expanded[node] = nil
					for i = 1, #node do
						if #node[i] > 0 then
							expand(node[i])
						end
					end
				end

				for i = 1, #sList do
					expand(sList[i])
				end

				Explorer.ForceUpdate()
			end,
		})

		context:Register("CLEAR_SEARCH_AND_JUMP_TO", {
			Name = "Clear Search and Jump to",
			OnClick = function()
				local newSelection = {}
				local count = 1
				local sList = selection.List

				for i = 1, #sList do
					newSelection[count] = sList[i]
					count = count + 1
				end

				selection:SetTable(newSelection)
				Explorer.ClearSearch()
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				end
			end,
		})

		context:Register("COPY_PATH", {
			Name = "Copy Path",
			OnClick = function()
				local sList = selection.List
				if #sList == 1 then
					env.setclipboard(Explorer.GetInstancePath(sList[1].Obj))
				elseif #sList > 1 then
					local resList = { "{" }
					local count = 2
					for i = 1, #sList do
						local path = "\t" .. Explorer.GetInstancePath(sList[i].Obj) .. ","
						if #path > 0 then
							resList[count] = path
							count = count + 1
						end
					end
					resList[count] = "}"
					env.setclipboard(table.concat(resList, "\n"))
				end
			end,
		})

		context:Register("INSERT_OBJECT", {
			Name = "Insert Object",
			IconMap = Explorer.MiscIcons,
			Icon = "InsertObject",
			OnClick = function()
				local mouse = Main.Mouse
				local x, y = Explorer.LastRightClickX or mouse.X, Explorer.LastRightClickY or mouse.Y
				Explorer.InsertObjectContext:Show(x, y)
			end,
		})

		context:Register("CALL_FUNCTION", {
			Name = "Call Function",
			IconMap = Explorer.ClassIcons,
			Icon = 66,
			OnClick = function()
				local node = selection.List[1]
				if not node then
					return
				end
				local obj = node.Obj

				if
					not (
						obj:IsA("RemoteFunction")
						or obj:IsA("RemoteEvent")
						or obj:IsA("BindableFunction")
						or obj:IsA("BindableEvent")
					)
				then
					return
				end

				CallFunctionWindow.currentObj = obj
				CallFunctionWindow:SetTitle("Call: " .. obj:GetFullName():sub(1, 40))
				CallFunctionWindow:Show()
			end,
		})

		context:Register(
			"GET_REFERENCES",
			{ Name = "Get Lua References", IconMap = Explorer.ClassIcons, Icon = 34, OnClick = function() end }
		)

		context:Register(
			"SAVE_INST",
			{ Name = "Save to File", IconMap = Explorer.MiscIcons, Icon = "Save", OnClick = function() end }
		)

		context:Register("VIEW_CONNECTIONS", { Name = "View Connections", OnClick = function() end })

		context:Register(
			"VIEW_API",
			{ Name = "View API Page", IconMap = Explorer.MiscIcons, Icon = "Reference", OnClick = function() end }
		)

		context:Register("VIEW_DESCRIPTION", {
			Name = "View Description",
			IconMap = Explorer.MiscIcons,
			Icon = 34,
			OnClick = function()
				local node = selection.List[1]
				if not node then
					return
				end
				local obj = node.Obj
				local className = obj.ClassName

				local name = RMD.Classes[className].Name
				local summary = RMD.Classes[className].summary
				local additionalDocs = {
					Model = "A Model is a container object, it groups objects together and it's best used to hold collections of BaseParts.",
					BasePart = "BasePart is an abstract base class for in-world objects that render and are physically simulated while in the Workspace.",
					Part = "The Part object is a type of BasePart. It comes in five different primitive shapes: Ball, Block, Cylinder, Wedge, and CornerWedge.",
					MeshPart = "MeshPart is a form of BasePart that includes a physically simulated custom mesh. Unlike with other mesh classes, such as SpecialMesh and BlockMesh, they are not parented to a BasePart but rather behave as a BasePart in their own right.",
					Workspace = "Workspace is a service that holds objects that exist in the 3D world, effectively BaseParts and Attachments. While such objects are descendant of Workspace, they will be active.",
				}

				InstanceInfoWindow:SetTitle(name .. ' "' .. obj.Name .. '"')

				-- as far as I checked, only a few classes have summary for some reason
				description.Text = summary
					or additionalDocs[className]
					or "No description available for this class. The RMD may be missing some information."

				InstanceInfoWindow:Show()
			end,
		})

		context:Register("VIEW_MODEL", {
			Name = "View Model",
			IconMap = Explorer.ClassIcons,
			Icon = 5,
			OnClick = function()
				local sList = selection.List
				local isa = game.IsA

				if #sList == 1 then
					if isa(sList[1].Obj, "BasePart") or isa(sList[1].Obj, "Model") then
						ModelViewer.ViewModel(sList[1].Obj)
						return
					end
				end
			end,
		})

		context:Register("VIEW_OBJECT", {
			Name = "View Object (Right click to reset)",
			IconMap = Explorer.ClassIcons,
			Icon = 5,
			OnClick = function()
				local sList = selection.List
				local isa = game.IsA

				for i = 1, #sList do
					local node = sList[i]

					if isa(node.Obj, "BasePart") or isa(node.Obj, "Model") then
						-- workspace.CurrentCamera.CameraSubject = node.Obj
						break
					end
				end
			end,
			OnRightClick = function()
				-- workspace.CurrentCamera.CameraSubject = plr.Character
			end,
		})

		context:Register("VIEW_SCRIPT", {
			Name = "View Script",
			IconMap = Explorer.MiscIcons,
			Icon = "ViewScript",
			OnClick = function()
				local scr = selection.List[1] and selection.List[1].Obj
				if scr then
					ScriptViewer.ViewScript(scr)
				end
			end,
		})

		context:Register("SELECT_CHARACTER", {
			Name = "Select Character",
			IconMap = Explorer.ClassIcons,
			Icon = 9,
			OnClick = function()
				local newSelection = {}
				local count = 1
				local sList = selection.List
				local isa = game.IsA

				for i = 1, #sList do
					local node = sList[i]
					if isa(node.Obj, "Player") and nodes[node.Obj.Character] then
						newSelection[count] = nodes[node.Obj.Character]
						count = count + 1
					end
				end

				selection:SetTable(newSelection)
				if #newSelection > 0 then
					Explorer.ViewNode(newSelection[1])
				else
					Explorer.Refresh()
				end
			end,
		})

		context:Register("REFRESH_NIL", {
			Name = "Refresh Nil Instances",
			OnClick = function()
				Explorer.RefreshNilInstances()
			end,
		})

		context:Register("HIDE_NIL", {
			Name = "Hide Nil Instances",
			OnClick = function()
				Explorer.HideNilInstances()
			end,
		})

		Explorer.RightClickContext = context
	end

	Explorer.HideNilInstances = function()
		table.clear(nilMap)

		local disconnectCon = Instance.new("Folder").ChildAdded:Connect(function() end).Disconnect
		for i, v in next, nilCons do
			disconnectCon(v[1])
			disconnectCon(v[2])
		end
		table.clear(nilCons)

		for i = 1, #nilNode do
			task.spawn(removeObject, nilNode[i].Obj)
		end

		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.RefreshNilInstances = function()
		if not env.getnilinstances then
			return
		end

		local nilInsts = env.getnilinstances()
		local game = game
		local getDescs = game.GetDescendants
		--local newNilMap = {}
		--local newNilRoots = {}
		--local nilRoots = Explorer.NilRoots
		--local connect = game.DescendantAdded.Connect
		--local disconnect
		--if not nilRoots then nilRoots = {} Explorer.NilRoots = nilRoots end

		for i = 1, #nilInsts do
			local obj = nilInsts[i]
			if obj ~= game then
				nilMap[obj] = true
				--newNilRoots[obj] = true

				local descs = getDescs(obj)
				for j = 1, #descs do
					nilMap[descs[j]] = true
				end
			end
		end

		-- Remove unmapped nil nodes
		--[[for i = 1,#nilNode do
			local node = nilNode[i]
			if not newNilMap[node.Obj] then
				nilMap[node.Obj] = nil
				task.spawn(removeObject, node)
			end
		end]]

		--nilMap = newNilMap

		for i = 1, #nilInsts do
			local obj = nilInsts[i]
			local node = nodes[obj]
			if not node then
				task.spawn(addObject, obj)
			end
		end

		--[[
		-- Remove old root connections
		for obj in next,nilRoots do
			if not newNilRoots[obj] then
				if not disconnect then disconnect = obj[1].Disconnect end
				disconnect(obj[1])
				disconnect(obj[2])
			end
		end
		
		for obj in next,newNilRoots do
			if not nilRoots[obj] then
				nilRoots[obj] = {
					connect(obj.DescendantAdded,addObject),
					connect(obj.DescendantRemoving,removeObject)
				}
			end
		end]]

		--nilMap = newNilMap
		--Explorer.NilRoots = newNilRoots

		Explorer.Update()
		Explorer.Refresh()
	end

	Explorer.GetInstancePath = function(obj)
		local ffc = game.FindFirstChild
		local getCh = game.GetChildren
		local path = ""
		local curObj = obj
		local ts = tostring
		local match = string.match
		local gsub = string.gsub
		local tableFind = table.find
		local useGetCh = Settings.Explorer.CopyPathUseGetChildren
		local formatLuaString = Lib.FormatLuaString

		while curObj do
			if curObj == game then
				path = "game" .. path
				break
			end

			local className = curObj.ClassName
			local curName = ts(curObj)
			local indexName
			if match(curName, "^[%a_][%w_]*$") then
				indexName = "." .. curName
			else
				local cleanName = formatLuaString(curName)
				indexName = '["' .. cleanName .. '"]'
			end

			local parObj = curObj.Parent
			if parObj then
				local fc = ffc(parObj, curName)
				if useGetCh and fc and fc ~= curObj then
					local parCh = getCh(parObj)
					local fcInd = tableFind(parCh, curObj)
					indexName = ":GetChildren()[" .. fcInd .. "]"
				elseif parObj == game and API.Classes[className] and API.Classes[className].Tags.Service then
					indexName = ':GetService("' .. className .. '")'
				end
			end

			path = indexName .. path
			curObj = parObj
		end

		return path
	end

	Explorer.InitInsertObject = function()
		local context = Lib.ContextMenu.new()
		context.SearchEnabled = true
		context.MaxHeight = 400
		context:ApplyTheme({
			ContentColor = Settings.Theme.Main2,
			OutlineColor = Settings.Theme.Outline1,
			DividerColor = Settings.Theme.Outline1,
			TextColor = Settings.Theme.Text,
			HighlightColor = Settings.Theme.ButtonHover,
		})

		local classes = {}
		for i, class in next, API.Classes do
			local tags = class.Tags
			if not tags.NotCreatable and not tags.Service then
				local rmdEntry = RMD.Classes[class.Name]
				classes[#classes + 1] = { class, rmdEntry and rmdEntry.ClassCategory or "Uncategorized" }
			end
		end
		table.sort(classes, function(a, b)
			if a[2] ~= b[2] then
				return a[2] < b[2]
			else
				return a[1].Name < b[1].Name
			end
		end)

		local function onClick(className)
			local sList = selection.List
			local instNew = Instance.new
			for i = 1, #sList do
				local node = sList[i]
				local obj = node.Obj
				Explorer.MakeNodeVisible(node, true)
				--pcall(instNew,className,obj)

				Dex_RemoteFunction:InvokeServer("InstanceNew", className, obj)
			end
		end

		local lastCategory = ""
		for i = 1, #classes do
			local class = classes[i][1]
			local rmdEntry = RMD.Classes[class.Name]
			local iconInd = rmdEntry and tonumber(rmdEntry.ExplorerImageIndex) or 0
			local category = classes[i][2]

			if lastCategory ~= category then
				context:AddDivider(category)
				lastCategory = category
			end
			context:Add({ Name = class.Name, IconMap = Explorer.ClassIcons, Icon = iconInd, OnClick = onClick })
		end

		Explorer.InsertObjectContext = context
	end

	--[[
	]]
	Explorer.InitClickToSelect = function()
		local connection = Explorer.ClickToSelect_Connection

		-- If Setting is ON
		if Settings.Explorer.ClickToSelect == true then
			if not connection then
				local mouse: Mouse = Main.Mouse or service.Players.LocalPlayer:GetMouse()
				connection = mouse.Button1Down:Connect(function()
					local mouseLocation = service.UserInputService:GetMouseLocation()

					-- Create a ray from the 2D mouse location
					local screenToWorldRay =
						workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

					local DISTANCE_LIMIT = 900000
					local dirVector = screenToWorldRay.Direction * DISTANCE_LIMIT

					local raycastResult = workspace:Raycast(screenToWorldRay.Origin, dirVector)

					if raycastResult then
						local node = nodes[raycastResult.Instance]

						if node then
							selection:Set(node)

							Explorer.ViewObj(node.Obj) -- Show in Explorer
						end
					end
				end)

				-- Set connection into the table
				Explorer.ClickToSelect_Connection = connection
			end
		else
			-- If OFF
			if connection then
				-- Disconnect
				connection:Disconnect()

				Explorer.ClickToSelect_Connection = nil
			end
		end
	end

	--[[
		Headers, Setups, Predicate, ObjectDefs
	]]
	Explorer.SearchFilters = { -- TODO: Use data table (so we can disable some if funcs don't exist)
		Comparison = {
			["isa"] = function(argString)
				local lower = string.lower
				local find = string.find
				local classQuery = string.split(argString)[1]
				if not classQuery then
					return
				end
				classQuery = lower(classQuery)

				local className
				for class, _ in pairs(API.Classes) do
					local cName = lower(class)
					if cName == classQuery then
						className = class
						break
					elseif find(cName, classQuery, 1, true) then
						className = class
					end
				end
				if not className then
					return
				end

				return {
					Headers = { "local isa = game.IsA" },
					Predicate = "isa(obj,'" .. className .. "')",
				}
			end,
			["remotes"] = function(argString)
				return {
					Headers = { "local isa = game.IsA" },
					Predicate = "isa(obj,'RemoteEvent') or isa(obj,'RemoteFunction')",
				}
			end,
			["bindables"] = function(argString)
				return {
					Headers = { "local isa = game.IsA" },
					Predicate = "isa(obj,'BindableEvent') or isa(obj,'BindableFunction')",
				}
			end,
			["rad"] = function(argString)
				local num = tonumber(argString)
				if not num then
					return
				end

				if
					not service.Players.LocalPlayer.Character
					or not service.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					or not service.Players.LocalPlayer.Character.HumanoidRootPart:IsA("BasePart")
				then
					return
				end

				return {
					Headers = {
						"local isa = game.IsA",
						"local hrp = service.Players.LocalPlayer.Character.HumanoidRootPart",
					},
					Setups = { "local hrpPos = hrp.Position" },
					ObjectDefs = { "local isBasePart = isa(obj,'BasePart')" },
					Predicate = "(isBasePart and (obj.Position-hrpPos).Magnitude <= " .. num .. ")",
				}
			end,
		},
		Specific = {
			["players"] = function()
				return function()
					return service.Players:GetPlayers()
				end
			end,
			["loadedmodules"] = function()
				return env.getloadedmodules
			end,
		},
		Default = function(argString, caseSensitive)
			local cleanString = argString:gsub('"', '\\"'):gsub("\n", "\\n")
			if caseSensitive then
				return {
					Headers = { "local find = string.find" },
					ObjectDefs = { "local objName = tostring(obj)" },
					Predicate = 'find(objName,"' .. cleanString .. '",1,true)',
				}
			else
				return {
					Headers = { "local lower = string.lower", "local find = string.find", "local tostring = tostring" },
					ObjectDefs = { "local lowerName = lower(tostring(obj))" },
					Predicate = 'find(lowerName,"' .. cleanString:lower() .. '",1,true)',
				}
			end
		end,
		SpecificDefault = function(n)
			return {
				Headers = {},
				ObjectDefs = { "local isSpec" .. n .. " = specResults[" .. n .. "][node]" },
				Predicate = "isSpec" .. n,
			}
		end,
	}

	Explorer.BuildSearchFunc = function(query)
		local specFilterList, specMap = {}, {}
		local finalPredicate = ""
		local rep = string.rep
		local formatQuery = query:gsub("\\.", "  "):gsub('".-"', function(str)
			return rep(" ", #str)
		end)
		local headers = {}
		local objectDefs = {}
		local setups = {}
		local find = string.find
		local sub = string.sub
		local lower = string.lower
		local match = string.match
		local ops = {
			["("] = "(",
			[")"] = ")",
			["||"] = " or ",
			["&&"] = " and ",
		}
		local filterCount = 0
		local compFilters = Explorer.SearchFilters.Comparison
		local specFilters = Explorer.SearchFilters.Specific
		local init = 1
		local lastOp = nil

		local function processFilter(dat)
			if dat.Headers then
				local t = dat.Headers
				for i = 1, #t do
					headers[t[i]] = true
				end
			end

			if dat.ObjectDefs then
				local t = dat.ObjectDefs
				for i = 1, #t do
					objectDefs[t[i]] = true
				end
			end

			if dat.Setups then
				local t = dat.Setups
				for i = 1, #t do
					setups[t[i]] = true
				end
			end

			finalPredicate = finalPredicate .. dat.Predicate
		end

		local found = {}
		local foundData = {}
		local find = string.find
		local sub = string.sub

		local function findAll(str, pattern)
			local count = #found + 1
			local init = 1
			local sz = #pattern
			local x, y, extra = find(str, pattern, init, true)
			while x do
				found[count] = x
				foundData[x] = { sz, pattern }

				count = count + 1
				init = y + 1
				x, y, extra = find(str, pattern, init, true)
			end
		end
		local start = tick()
		findAll(formatQuery, "&&")
		findAll(formatQuery, "||")
		findAll(formatQuery, "(")
		findAll(formatQuery, ")")
		table.sort(found)
		table.insert(found, #formatQuery + 1)

		local function inQuotes(str)
			local len = #str
			if sub(str, 1, 1) == '"' and sub(str, len, len) == '"' then
				return sub(str, 2, len - 1)
			end
		end

		for i = 1, #found do
			local nextInd = found[i]
			local nextData = foundData[nextInd] or { 1 }
			local op = ops[nextData[2]]
			local term = sub(query, init, nextInd - 1)
			term = match(term, "^%s*(.-)%s*$") or "" -- Trim

			if #term > 0 then
				if sub(term, 1, 1) == "!" then
					term = sub(term, 2)
					finalPredicate = finalPredicate .. "not "
				end

				local qTerm = inQuotes(term)
				if qTerm then
					processFilter(Explorer.SearchFilters.Default(qTerm, true))
				else
					local x, y = find(term, "%S+")
					if x then
						local first = sub(term, x, y)
						local specifier = sub(first, 1, 1) == "/" and lower(sub(first, 2))
						local compFunc = specifier and compFilters[specifier]
						local specFunc = specifier and specFilters[specifier]

						if compFunc then
							local argStr = sub(term, y + 2)
							local ret = compFunc(inQuotes(argStr) or argStr)
							if ret then
								processFilter(ret)
							else
								finalPredicate = finalPredicate .. "false"
							end
						elseif specFunc then
							local argStr = sub(term, y + 2)
							local ret = specFunc(inQuotes(argStr) or argStr)
							if ret then
								if not specMap[term] then
									specFilterList[#specFilterList + 1] = ret
									specMap[term] = #specFilterList
								end
								processFilter(Explorer.SearchFilters.SpecificDefault(specMap[term]))
							else
								finalPredicate = finalPredicate .. "false"
							end
						else
							processFilter(Explorer.SearchFilters.Default(term))
						end
					end
				end
			end

			if op then
				finalPredicate = finalPredicate .. op
				if op == "(" and (#term > 0 or lastOp == ")") then -- Handle bracket glitch
					return
				else
					lastOp = op
				end
			end
			init = nextInd + nextData[1]
		end

		local finalSetups = ""
		local finalHeaders = ""
		local finalObjectDefs = ""

		for setup, _ in next, setups do
			finalSetups = finalSetups .. setup .. "\n"
		end
		for header, _ in next, headers do
			finalHeaders = finalHeaders .. header .. "\n"
		end
		for oDef, _ in next, objectDefs do
			finalObjectDefs = finalObjectDefs .. oDef .. "\n"
		end

		return nil, specFilterList
	end

	Explorer.DoSearch = function(query)
		table.clear(Explorer.SearchExpanded)
		table.clear(searchResults)
		expanded = (#query == 0 and Explorer.Expanded or Explorer.SearchExpanded)
		searchFunc = nil

		if #query > 0 then
			local expandTable = Explorer.SearchExpanded
			local specFilters

			local lower = string.lower
			local find = string.find
			local tostring = tostring

			local lowerQuery = lower(query)

			local function defaultSearch(root)
				local expandedpar = false
				for i = 1, #root do
					local node = root[i]
					local obj = node.Obj

					if find(lower(tostring(obj)), lowerQuery, 1, true) then
						expandTable[node] = 0
						searchResults[node] = true
						if not expandedpar then
							local parnode = node.Parent
							while parnode and (not searchResults[parnode] or expandTable[parnode] == 0) do
								expanded[parnode] = true
								searchResults[parnode] = true
								parnode = parnode.Parent
							end
							expandedpar = true
						end
					end

					if #node > 0 then
						defaultSearch(node)
					end
				end
			end

			if Main.Elevated then
				local start = tick()
				searchFunc, specFilters = Explorer.BuildSearchFunc(query)
				--print("BUILD SEARCH",tick()-start)
			else
				searchFunc = defaultSearch
			end

			if specFilters then
				table.clear(specResults)
				for i = 1, #specFilters do -- Specific search filers that returns list of matches
					local resMap = {}
					specResults[i] = resMap
					local objs = specFilters[i]()
					for c = 1, #objs do
						local node = nodes[objs[c]]
						if node then
							resMap[node] = true
						end
					end
				end
			end

			if searchFunc then
				local start = tick()
				searchFunc(nodes[game])
				searchFunc(nilNode)
				--warn(tick()-start)
			end
		end

		Explorer.ForceUpdate()
	end

	Explorer.ClearSearch = function()
		Explorer.GuiElems.SearchBar.Text = ""
		expanded = Explorer.Expanded
		searchFunc = nil
	end

	Explorer.InitSearch = function()
		local searchBox = Explorer.GuiElems.ToolBar.SearchFrame.SearchBox
		Explorer.GuiElems.SearchBar = searchBox

		Lib.ViewportTextBox.convert(searchBox)

		searchBox.FocusLost:Connect(function()
			Explorer.DoSearch(searchBox.Text)
		end)
	end

	Explorer.InitEntryTemplate = function()
		entryTemplate = create({
			{
				1,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0, 0, 0),
					Font = 3,
					Name = "Entry",
					Position = UDim2.fromOffset(1, 1),
					Size = UDim2.fromOffset(250, 20),
					Text = "",
					TextSize = 14,
				},
			},
			{
				2,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.33725491166115, 0.49019610881805, 0.73725491762161),
					BorderSizePixel = 0,
					Name = "Indent",
					Parent = { 1 },
					Position = UDim2.fromOffset(20, 0),
					Size = UDim2.new(1, -20, 1, 0),
				},
			},
			{
				3,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "EntryName",
					Parent = { 2 },
					Position = UDim2.fromOffset(26, 0),
					Size = UDim2.new(1, -26, 1, 0),
					Text = "Workspace",
					TextColor3 = Color3.new(0.86274516582489, 0.86274516582489, 0.86274516582489),
					TextSize = 14,
					TextXAlignment = 0,
				},
			},
			{
				4,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Font = 3,
					Name = "Expand",
					Parent = { 2 },
					Position = UDim2.fromOffset(-20, 0),
					Size = UDim2.fromOffset(20, 20),
					Text = "",
					TextSize = 14,
				},
			},
			{
				5,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5642383285",
					ImageRectOffset = Vector2.new(144, 16),
					ImageRectSize = Vector2.new(16, 16),
					Name = "Icon",
					Parent = { 4 },
					Position = UDim2.fromOffset(2, 2),
					ScaleType = 4,
					Size = UDim2.fromOffset(16, 16),
				},
			},
			{
				6,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxasset://textures/ClassImages.png",
					ImageRectOffset = Vector2.new(304, 0),
					ImageRectSize = Vector2.new(16, 16),
					Name = "Icon",
					Parent = { 2 },
					Position = UDim2.fromOffset(4, 2),
					ScaleType = 4,
					Size = UDim2.fromOffset(16, 16),
				},
			},
		})

		local sys = Lib.ClickSystem.new()
		sys.AllowedButtons = { 1, 2 }
		sys.OnDown:Connect(function(item, combo, button)
			local ind = table.find(listEntries, item)
			if not ind then
				return
			end
			local node = tree[ind + Explorer.Index]
			if not node then
				return
			end

			local entry = listEntries[ind]

			if button == 1 then
				if combo == 2 then
					if node.Obj:IsA("LuaSourceContainer") then
						ScriptViewer.ViewScript(node.Obj)
					elseif #node > 0 and expanded[node] ~= 0 then
						expanded[node] = not expanded[node]
						Explorer.Update()
					end
				end

				if Properties.SelectObject(node.Obj) then
					sys.IsRenaming = false
					return
				end

				sys.IsRenaming = selection.Map[node]

				if Lib.IsShiftDown() then
					if not selection.Piviot then
						return
					end

					local fromIndex = table.find(tree, selection.Piviot)
					local toIndex = table.find(tree, node)
					if not fromIndex or not toIndex then
						return
					end
					fromIndex, toIndex = math.min(fromIndex, toIndex), math.max(fromIndex, toIndex)

					local sList = selection.List
					for i = #sList, 1, -1 do
						local elem = sList[i]
						if selection.ShiftSet[elem] then
							selection.Map[elem] = nil
							table.remove(sList, i)
						end
					end
					selection.ShiftSet = {}
					for i = fromIndex, toIndex do
						local elem = tree[i]
						if not selection.Map[elem] then
							selection.ShiftSet[elem] = true
							selection.Map[elem] = true
							sList[#sList + 1] = elem
						end
					end
					selection.Changed:Fire()
				elseif Lib.IsCtrlDown() then
					selection.ShiftSet = {}
					if selection.Map[node] then
						selection:Remove(node)
					else
						selection:Add(node)
					end
					selection.Piviot = node
					sys.IsRenaming = false
				elseif not selection.Map[node] then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
				end
			elseif button == 2 then
				if Properties.SelectObject(node.Obj) then
					return
				end

				if not Lib.IsCtrlDown() and not selection.Map[node] then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
					Explorer.Refresh()
				end
			end

			Explorer.Refresh()
		end)

		sys.OnRelease:Connect(function(item, combo, button)
			local ind = table.find(listEntries, item)
			if not ind then
				return
			end
			local node = tree[ind + Explorer.Index]
			if not node then
				return
			end

			if button == 1 then
				if selection.Map[node] and not Lib.IsShiftDown() and not Lib.IsCtrlDown() then
					selection.ShiftSet = {}
					selection:Set(node)
					selection.Piviot = node
					Explorer.Refresh()
				end

				local id = sys.ClickId
				Lib.FastWait(sys.ComboTime)
				if combo == 1 and id == sys.ClickId and sys.IsRenaming and selection.Map[node] then
					Explorer.SetRenamingNode(node)
				end
			elseif button == 2 then
				Explorer.ShowRightClick()
			end
		end)
		Explorer.ClickSystem = sys
	end

	Explorer.InitDelCleaner = function()
		task.spawn(function()
			local fw = Lib.FastWait
			while true do
				local processed = false
				local c = 0
				for _, node in next, nodes do
					if node.HasDel then
						local delInd
						for i = 1, #node do
							if node[i].Del then
								delInd = i
								break
							end
						end
						if delInd then
							for i = delInd + 1, #node do
								local cn = node[i]
								if not cn.Del then
									node[delInd] = cn
									delInd = delInd + 1
								end
							end
							for i = delInd, #node do
								node[i] = nil
							end
						end
						node.HasDel = false
						processed = true
						fw()
					end
					c = c + 1
					if c > 10000 then
						c = 0
						fw()
					end
				end
				if processed and not refreshDebounce then
					Explorer.PerformRefresh()
				end
				fw(0.5)
			end
		end)
	end

	Explorer.UpdateSelectionVisuals = function()
		local holder = Explorer.SelectionVisualsHolder
		local isa = game.IsA
		local clone = game.Clone
		if not holder then
			holder = Instance.new("ScreenGui")
			holder.Name = "Dex_ExplorerSelections"
			holder.DisplayOrder = Main.DisplayOrders.Core
			holder.ResetOnSpawn = false
			Lib.ShowGui(holder)
			Explorer.SelectionVisualsHolder = holder
			Explorer.SelectionVisualCons = {}

			local guiTemplate = create({
				{
					1,
					"Frame",
					{
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 1,
						Size = UDim2.fromOffset(100, 100),
					},
				},
				{
					2,
					"Frame",
					{
						BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
						BorderSizePixel = 0,
						Parent = { 1 },
						Position = UDim2.fromOffset(-1, -1),
						Size = UDim2.fromOffset(1, 1),
					},
				},
				{
					3,
					"Frame",
					{
						BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
						BorderSizePixel = 0,
						Parent = { 1 },
						Position = UDim2.new(0, -1, 1, 0),
						Size = UDim2.new(1, 2, 0, 1),
					},
				},
				{
					4,
					"Frame",
					{
						BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
						BorderSizePixel = 0,
						Parent = { 1 },
						Position = UDim2.fromOffset(-1, 0),
						Size = UDim2.new(0, 1, 1, 0),
					},
				},
				{
					5,
					"Frame",
					{
						BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
						BorderSizePixel = 0,
						Parent = { 1 },
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(0, 1, 1, 0),
					},
				},
			})
			Explorer.SelectionVisualGui = guiTemplate

			local boxTemplate = Instance.new("SelectionBox")
			boxTemplate.LineThickness = 0.03
			boxTemplate.Color3 = Color3.fromRGB(0, 170, 255)
			Explorer.SelectionVisualBox = boxTemplate
		end
		holder:ClearAllChildren()

		-- Updates theme
		for i, v in pairs(Explorer.SelectionVisualGui:GetChildren()) do
			v.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		end

		local attachCons = Explorer.SelectionVisualCons
		for i = 1, #attachCons do
			attachCons[i].Destroy()
		end
		table.clear(attachCons)

		local partEnabled = Settings.Explorer.PartSelectionBox
		local guiEnabled = Settings.Explorer.GuiSelectionBox
		if not partEnabled and not guiEnabled then
			return
		end

		local svg = Explorer.SelectionVisualGui
		local svb = Explorer.SelectionVisualBox
		local attachTo = Lib.AttachTo
		local sList = selection.List
		local count = 1
		local boxCount = 0
		local workspaceNode = nodes[workspace]
		for i = 1, #sList do
			if boxCount > 1000 then
				break
			end
			local node = sList[i]
			local obj = node.Obj

			if node ~= workspaceNode then
				if isa(obj, "GuiObject") and guiEnabled then
					local newVisual = clone(svg)
					attachCons[count] = attachTo(newVisual, { Target = obj, Resize = true })
					count = count + 1
					newVisual.Parent = holder
					boxCount = boxCount + 1
				elseif isa(obj, "PVInstance") and partEnabled then
					local newBox = clone(svb)
					newBox.Adornee = obj
					newBox.Parent = holder
					boxCount = boxCount + 1
				end
			end
		end
	end

	Explorer.Init = function()
		Explorer.ClassIcons = Lib.IconMap.newLinear("rbxasset://textures/ClassImages.png", 16, 16)
		Explorer.MiscIcons = Main.MiscIcons

		clipboard = {}

		selection = Lib.Set.new()
		selection.ShiftSet = {}
		selection.Changed:Connect(Properties.ShowExplorerProps)
		Explorer.Selection = selection

		Explorer.InitRightClick()
		Explorer.InitInsertObject()

		Explorer.InitClickToSelect()

		Explorer.SetSortingEnabled(Settings.Explorer.Sorting)
		Explorer.Expanded = setmetatable({}, { __mode = "k" })
		Explorer.SearchExpanded = setmetatable({}, { __mode = "k" })
		expanded = Explorer.Expanded

		nilNode.Obj.Name = "Nil Instances"
		nilNode.Locked = true

		local explorerItems = create({
			{ 1, "Folder", { Name = "ExplorerItems" } },
			{
				2,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					BorderSizePixel = 0,
					Name = "ToolBar",
					Parent = { 1 },
					Size = UDim2.new(1, 0, 0, 22),
				},
			},
			{
				3,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.14901961386204, 0.14901961386204, 0.14901961386204),
					BorderColor3 = Color3.new(0.1176470592618, 0.1176470592618, 0.1176470592618),
					BorderSizePixel = 0,
					Name = "SearchFrame",
					Parent = { 2 },
					Position = UDim2.fromOffset(3, 1),
					Size = UDim2.new(1, -6, 0, 18),
				},
			},
			{
				4,
				"TextBox",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					Font = 3,
					Name = "SearchBox",
					Parent = { 3 },
					PlaceholderColor3 = Color3.new(0.39215689897537, 0.39215689897537, 0.39215689897537),
					PlaceholderText = "Search workspace",
					Position = UDim2.fromOffset(4, 0),
					Size = UDim2.new(1, -24, 0, 18),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 0,
				},
			},
			{ 5, "UICorner", { CornerRadius = UDim.new(0, 2), Parent = { 3 } } },
			{
				6,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.12549020349979, 0.12549020349979, 0.12549020349979),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "Reset",
					Parent = { 3 },
					Position = UDim2.new(1, -17, 0, 1),
					Size = UDim2.fromOffset(16, 16),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				7,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5034718129",
					ImageColor3 = Color3.new(0.39215686917305, 0.39215686917305, 0.39215686917305),
					Parent = { 6 },
					Size = UDim2.fromOffset(16, 16),
				},
			},
			{
				8,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.12549020349979, 0.12549020349979, 0.12549020349979),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "Refresh",
					Parent = { 2 },
					Position = UDim2.new(1, -20, 0, 1),
					Size = UDim2.fromOffset(18, 18),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Visible = false,
				},
			},
			{
				9,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5642310344",
					Parent = { 8 },
					Position = UDim2.fromOffset(3, 3),
					Size = UDim2.fromOffset(12, 12),
				},
			},
			{
				10,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.15686275064945, 0.15686275064945, 0.15686275064945),
					BorderSizePixel = 0,
					Name = "ScrollCorner",
					Parent = { 1 },
					Position = UDim2.new(1, -16, 1, -16),
					Size = UDim2.fromOffset(16, 16),
					Visible = false,
				},
			},
			{
				11,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Name = "List",
					Parent = { 1 },
					Position = UDim2.fromOffset(0, 23),
					Size = UDim2.new(1, 0, 1, -23),
				},
			},
		})

		toolBar = explorerItems.ToolBar
		treeFrame = explorerItems.List

		Explorer.GuiElems.ToolBar = toolBar
		Explorer.GuiElems.TreeFrame = treeFrame

		scrollV = Lib.ScrollBar.new()
		scrollV.WheelIncrement = 3
		scrollV.Gui.Position = UDim2.new(1, -16, 0, 23)
		scrollV:SetScrollFrame(treeFrame)
		scrollV.Scrolled:Connect(function()
			Explorer.Index = scrollV.Index
			Explorer.Refresh()
		end)

		-- Add touch drag scrolling for mobile
		local touchStarting = false
		local dragging = false
		local dragStartY = nil
		local dragIndexStart = nil
		local userInputService = service.UserInputService
		local dragThreshold = 10 -- Pixels to move before starting drag (allows taps to select items)

		userInputService.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or (input.UserInputType == Enum.UserInputType.MouseButton1 and userInputService.TouchEnabled)
			then
				-- Check if touch is within treeFrame bounds
				local pos = input.Position
				local framePos = treeFrame.AbsolutePosition
				local frameSize = treeFrame.AbsoluteSize

				if
					pos.X >= framePos.X
					and pos.X <= framePos.X + frameSize.X
					and pos.Y >= framePos.Y
					and pos.Y <= framePos.Y + frameSize.Y
				then
					touchStarting = true
					dragging = false
					dragStartY = input.Position.Y
					dragIndexStart = scrollV.Index
				end
			end
		end)

		userInputService.InputChanged:Connect(function(input)
			if
				(touchStarting or dragging)
				and (
					input.UserInputType == Enum.UserInputType.Touch
					or (input.UserInputType == Enum.UserInputType.MouseMovement and userInputService.TouchEnabled)
				)
			then
				local dragDelta = math.abs(dragStartY - input.Position.Y)

				-- Start dragging if we've moved past the threshold
				if not dragging and dragDelta > dragThreshold then
					dragging = true
					touchStarting = false
				end
				if dragging then
					local signedDelta = dragStartY - input.Position.Y
					local scrollSensitivity = 0.15 -- Pixels per list index
					local newIndex = math.floor(dragIndexStart + (signedDelta * scrollSensitivity))
					scrollV:ScrollTo(newIndex)
				end
			end
		end)

		userInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				touchStarting = false
				dragging = false
				dragStartY = nil
				dragIndexStart = nil
			end
		end)

		scrollH = Lib.ScrollBar.new(true)
		scrollH.Increment = 5
		scrollH.WheelIncrement = Explorer.EntryIndent
		scrollH.Gui.Position = UDim2.new(0, 0, 1, -16)
		scrollH.Scrolled:Connect(function()
			Explorer.Refresh()
		end)

		local window = Lib.Window.new()
		Explorer.Window = window
		window:SetTitle("Explorer")
		window.GuiElems.Line.Position = UDim2.fromOffset(0, 22)

		Explorer.InitEntryTemplate()
		toolBar.Parent = window.GuiElems.Content
		treeFrame.Parent = window.GuiElems.Content
		explorerItems.ScrollCorner.Parent = window.GuiElems.Content
		scrollV.Gui.Parent = window.GuiElems.Content
		scrollH.Gui.Parent = window.GuiElems.Content

		-- Init stuff that requires the window
		Explorer.InitRenameBox()
		Explorer.InitSearch()
		Explorer.InitDelCleaner()
		selection.Changed:Connect(Explorer.UpdateSelectionVisuals)

		-- Window events
		window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if Explorer.Active then
				Explorer.UpdateView()
				Explorer.Refresh()
			end
		end)
		window.OnActivate:Connect(function()
			Explorer.Active = true
			Explorer.UpdateView()
			Explorer.Update()
			Explorer.Refresh()
		end)
		window.OnRestore:Connect(function()
			Explorer.Active = true
			Explorer.UpdateView()
			Explorer.Update()
			Explorer.Refresh()
		end)
		window.OnDeactivate:Connect(function()
			Explorer.Active = false
		end)
		window.OnMinimize:Connect(function()
			Explorer.Active = false
		end)

		-- Settings
		autoUpdateSearch = Settings.Explorer.AutoUpdateSearch

		-- Fill in nodes
		nodes[game] = { Obj = game }
		expanded[nodes[game]] = true

		-- Nil Instances
		if env.getnilinstances then
			nodes[nilNode.Obj] = nilNode
		end

		Explorer.SetupConnections()

		local insts = getDescendants(game)
		if Main.Elevated then
			for i = 1, #insts do
				local obj = insts[i]
				local par = nodes[ffa(obj, "Instance")]
				if not par then
					continue
				end
				local newNode = {
					Obj = obj,
					Parent = par,
				}
				nodes[obj] = newNode
				par[#par + 1] = newNode
			end
		else
			for i = 1, #insts do
				local obj = insts[i]
				local s, parObj = pcall(ffa, obj, "Instance")
				local par = nodes[parObj]
				if not par then
					continue
				end
				local newNode = {
					Obj = obj,
					Parent = par,
				}
				nodes[obj] = newNode
				par[#par + 1] = newNode
			end
		end
	end

	return Explorer
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
