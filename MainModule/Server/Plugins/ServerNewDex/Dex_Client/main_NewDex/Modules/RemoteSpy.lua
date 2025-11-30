local RemoteSpy = {}

-- Common Locals
local Main, Lib, Settings
local createSimple
local Dex_RemoteFunction

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Settings = data.Settings

	createSimple = data.createSimple

	Dex_RemoteFunction = game:GetService("ReplicatedStorage"):WaitForChild("NewDex_Event")
end

local function initAfterMain()
	-- Nothing needed here for now
end

local function main()
	local RemoteSpy = {}

	local window
	local LogList
	local DetailPanel
	local RemoteLogs = {}
	local MaxLogs = 500
	local IsPaused = false
	local IsMonitoring = false
	local MonitoringClient = false
	local LogEventConnection
	local ClientHooks = {} -- Store client-side hooks for cleanup
	local SelectedLogIndex = nil
	local BlockList = {} -- List of blocked remote names/patterns
	local AutoScroll = true -- Auto-scroll to top when new logs arrive
	local blockListWindow -- Block list editor window
	local blockListRefreshCallback = nil -- Callback to refresh block list UI

	-- Get RemoteEvent for receiving logs from server
	local RemoteSpy_LogEvent

	-- Check if a remote name is blocked
	local function isBlocked(remoteName)
		for _, pattern in ipairs(BlockList) do
			if remoteName:match(pattern) or remoteName == pattern then
				return true
			end
		end
		return false
	end

	-- Add to block list
	local function addToBlockList(remoteName)
		for _, pattern in ipairs(BlockList) do
			if pattern == remoteName then
				return false -- Already blocked
			end
		end
		table.insert(BlockList, remoteName)

		-- Refresh block list UI if it's open
		if blockListRefreshCallback then
			blockListRefreshCallback()
		end

		return true
	end

	-- Remove from block list
	local function removeFromBlockList(remoteName)
		for i, pattern in ipairs(BlockList) do
			if pattern == remoteName then
				table.remove(BlockList, i)

				-- Refresh block list UI if it's open
				if blockListRefreshCallback then
					blockListRefreshCallback()
				end

				return true
			end
		end
		return false
	end

	-- Utility: Serialize a value to a readable string
	local function serializeValue(value, indent, visited)
		indent = indent or 0
		visited = visited or {}
		local indentStr = string.rep("  ", indent)

		if type(value) == "table" then
			if visited[value] then
				return "<circular reference>"
			end
			visited[value] = true

			local result = "{\n"
			local hasContent = false
			for k, v in pairs(value) do
				hasContent = true
				result = result
					.. indentStr
					.. "  ["
					.. serializeValue(k, indent + 1, visited)
					.. "] = "
					.. serializeValue(v, indent + 1, visited)
					.. ",\n"
			end
			if hasContent then
				result = result .. indentStr .. "}"
			else
				result = "{}"
			end
			return result
		elseif type(value) == "string" then
			return '"' .. value .. '"'
		elseif typeof(value) == "Instance" then
			return value:GetFullName() .. " (" .. value.ClassName .. ")"
		elseif type(value) == "userdata" then
			return tostring(value)
		else
			return tostring(value)
		end
	end

	-- Format arguments for display
	local function formatArgsPreview(args)
		if #args == 0 then
			return "none"
		end
		local preview = {}
		for i, arg in ipairs(args) do
			if i > 3 then
				table.insert(preview, "...")
				break
			end
			local argStr = tostring(arg)
			if #argStr > 30 then
				argStr = argStr:sub(1, 27) .. "..."
			end
			table.insert(preview, argStr)
		end
		return table.concat(preview, ", ")
	end

	-- Update detail panel with selected log
	local function updateDetailPanel(logData)
		if not DetailPanel then
			return
		end

		-- Clear existing detail content
		for _, child in ipairs(DetailPanel:GetChildren()) do
			if child.Name ~= "TitleLabel" and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				child:Destroy()
			end
		end

		if not logData then
			DetailPanel.TitleLabel.Text = "No packet selected"
			return
		end

		DetailPanel.TitleLabel.Text = "Packet Details"

		local yOffset = 25

		-- Remote Type
		local typeLabel = createSimple("TextLabel", {
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, yOffset),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = "Type: " .. logData.remoteType,
			TextColor3 = Settings.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		yOffset = yOffset + 20

		-- Remote Name
		local nameLabel = createSimple("TextLabel", {
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, yOffset),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSans,
			Text = "Remote: " .. logData.remoteName,
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		yOffset = yOffset + 20

		-- Caller
		local callerLabel = createSimple("TextLabel", {
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, yOffset),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSans,
			Text = "Caller: " .. tostring(logData.caller),
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		yOffset = yOffset + 20

		-- Timestamp
		local timeLabel = createSimple("TextLabel", {
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, yOffset),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.Code,
			Text = "Time: " .. os.date("%H:%M:%S", logData.timestamp),
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		yOffset = yOffset + 25

		-- Arguments Section
		local argsHeader = createSimple("TextLabel", {
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, yOffset),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = "Arguments (" .. #logData.rawArgs .. "):",
			TextColor3 = Settings.Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		yOffset = yOffset + 20

		-- Display each argument
		if #logData.rawArgs == 0 then
			local noArgsLabel = createSimple("TextLabel", {
				Parent = DetailPanel,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, yOffset),
				Size = UDim2.new(1, -20, 0, 15),
				Font = Enum.Font.Code,
				Text = "(none)",
				TextColor3 = Color3.fromRGB(150, 150, 150),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			yOffset = yOffset + 20
		else
			for i, arg in ipairs(logData.rawArgs) do
				-- Argument index
				local argIndexLabel = createSimple("TextLabel", {
					Parent = DetailPanel,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, yOffset),
					Size = UDim2.new(1, -15, 0, 15),
					Font = Enum.Font.SourceSansBold,
					Text = "[" .. i .. "] " .. typeof(arg),
					TextColor3 = Color3.fromRGB(100, 200, 255),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				yOffset = yOffset + 18

				-- Argument value (in scrollable text box for long values)
				local serialized = serializeValue(arg)
				local argValueBox = createSimple("TextBox", {
					Parent = DetailPanel,
					BackgroundColor3 = Settings.Theme.Main1,
					BorderSizePixel = 1,
					BorderColor3 = Settings.Theme.Outline1,
					Position = UDim2.new(0, 20, 0, yOffset),
					Size = UDim2.new(1, -25, 0, math.min(100, math.max(30, #serialized / 2))),
					Font = Enum.Font.Code,
					Text = serialized,
					TextColor3 = Color3.fromRGB(220, 220, 220),
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					TextEditable = false,
					ClearTextOnFocus = false,
					MultiLine = true,
				})
				yOffset = yOffset + argValueBox.Size.Y.Offset + 10
			end
		end

		DetailPanel.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
	end

	-- Add log entry to UI (forward declaration)
	local addLogEntry

	-- Create UI
	local function createUI()
		-- Create Window
		window = Lib.Window.new()
		window:SetTitle("Remote Spy")
		window:Resize(800, 450)
		RemoteSpy.Window = window

		-- Main Content Frame
		local RemoteSpyFrame = createSimple("Frame", {
			Name = "RemoteSpyContent",
			Parent = window.GuiElems.Content,
			BackgroundColor3 = Settings.Theme.Main1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
		})

		-- Control Bar
		local ControlBar = createSimple("Frame", {
			Name = "ControlBar",
			Parent = RemoteSpyFrame,
			BackgroundColor3 = Settings.Theme.Main2,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 30),
		})

		-- Pause/Resume Button
		local PauseButton = createSimple("TextButton", {
			Name = "PauseButton",
			Parent = ControlBar,
			BackgroundColor3 = Settings.Theme.Button,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0, 5),
			Size = UDim2.new(0, 60, 0, 20),
			Font = Enum.Font.SourceSans,
			Text = "Pause",
			TextColor3 = Settings.Theme.Text,
			TextSize = 12,
		})

		-- Clear Button
		local ClearButton = createSimple("TextButton", {
			Name = "ClearButton",
			Parent = ControlBar,
			BackgroundColor3 = Settings.Theme.Button,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 70, 0, 5),
			Size = UDim2.new(0, 60, 0, 20),
			Font = Enum.Font.SourceSans,
			Text = "Clear",
			TextColor3 = Settings.Theme.Text,
			TextSize = 12,
		})

		-- Server Monitor Button
		local ServerMonitorButton = createSimple("TextButton", {
			Name = "ServerMonitorButton",
			Parent = ControlBar,
			BackgroundColor3 = Color3.fromRGB(120, 40, 40),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 135, 0, 5),
			Size = UDim2.new(0, 110, 0, 20),
			Font = Enum.Font.SourceSansBold,
			Text = "Server: OFF",
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
		})

		-- Client Monitor Button
		local ClientMonitorButton = createSimple("TextButton", {
			Name = "ClientMonitorButton",
			Parent = ControlBar,
			BackgroundColor3 = Color3.fromRGB(120, 40, 40),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 250, 0, 5),
			Size = UDim2.new(0, 110, 0, 20),
			Font = Enum.Font.SourceSansBold,
			Text = "Client: OFF",
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
		})

		-- Auto-Scroll Toggle Button
		local AutoScrollButton = createSimple("TextButton", {
			Name = "AutoScrollButton",
			Parent = ControlBar,
			BackgroundColor3 = Color3.fromRGB(40, 120, 40),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 365, 0, 5),
			Size = UDim2.new(0, 90, 0, 20),
			Font = Enum.Font.SourceSans,
			Text = "Auto-Scroll",
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
		})

		-- Block List Editor Button
		local BlockListButton = createSimple("TextButton", {
			Name = "BlockListButton",
			Parent = ControlBar,
			BackgroundColor3 = Settings.Theme.Button,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 460, 0, 5),
			Size = UDim2.new(0, 80, 0, 20),
			Font = Enum.Font.SourceSans,
			Text = "Block List",
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
		})

		-- Status Label
		local StatusLabel = createSimple("TextLabel", {
			Name = "StatusLabel",
			Parent = ControlBar,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 545, 0, 0),
			Size = UDim2.new(1, -550, 1, 0),
			Font = Enum.Font.Code,
			Text = "Not monitoring",
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- Left Panel (Log List)
		local LeftPanel = createSimple("Frame", {
			Name = "LeftPanel",
			Parent = RemoteSpyFrame,
			BackgroundColor3 = Settings.Theme.Main1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0, 35),
			Size = UDim2.new(0.5, -10, 1, -40),
		})

		-- Log List (ScrollingFrame)
		LogList = createSimple("ScrollingFrame", {
			Name = "LogList",
			Parent = LeftPanel,
			BackgroundColor3 = Settings.Theme.Main1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = Settings.Theme.Outline2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		})

		createSimple("UIListLayout", {
			Parent = LogList,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		})

		-- Right Panel (Detail View)
		local RightPanel = createSimple("Frame", {
			Name = "RightPanel",
			Parent = RemoteSpyFrame,
			BackgroundColor3 = Settings.Theme.Main2,
			BorderSizePixel = 1,
			BorderColor3 = Settings.Theme.Outline1,
			Position = UDim2.new(0.5, 5, 0, 35),
			Size = UDim2.new(0.5, -10, 1, -40),
		})

		-- Detail Panel (ScrollingFrame)
		DetailPanel = createSimple("ScrollingFrame", {
			Name = "DetailPanel",
			Parent = RightPanel,
			BackgroundColor3 = Settings.Theme.Main2,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = Settings.Theme.Outline2,
			CanvasSize = UDim2.new(0, 0, 0, 0),
		})

		-- Detail Panel Title
		createSimple("TextLabel", {
			Name = "TitleLabel",
			Parent = DetailPanel,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 5),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = "No packet selected",
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- Client-side monitoring setup
		local function setupClientMonitoring()
			if MonitoringClient then
				return
			end
			MonitoringClient = true

			-- Hook all existing RemoteEvents and RemoteFunctions
			for _, descendant in ipairs(game:GetDescendants()) do
				if descendant:IsA("RemoteEvent") then
					local remoteName = descendant:GetFullName()
					local connection = descendant.OnClientEvent:Connect(function(...)
						if IsPaused then
							return
						end

						local args = { ... }
						local formattedArgs = {}
						for _, arg in ipairs(args) do
							table.insert(formattedArgs, tostring(arg))
						end

						local logData = {
							remoteType = "FireClient",
							remoteName = remoteName,
							caller = "Server",
							args = formattedArgs,
							rawArgs = args,
							timestamp = os.time(),
						}

						table.insert(RemoteLogs, 1, logData)
						if not IsPaused then
							addLogEntry(logData, 1)
						end
					end)
					table.insert(ClientHooks, connection)
				end
			end

			-- Monitor future RemoteEvents
			local connection = game.DescendantAdded:Connect(function(descendant)
				if MonitoringClient and descendant:IsA("RemoteEvent") then
					task.wait(0.1)
					local remoteName = descendant:GetFullName()
					local conn = descendant.OnClientEvent:Connect(function(...)
						if IsPaused then
							return
						end

						local args = { ... }
						local formattedArgs = {}
						for _, arg in ipairs(args) do
							table.insert(formattedArgs, tostring(arg))
						end

						local logData = {
							remoteType = "FireClient",
							remoteName = remoteName,
							caller = "Server",
							args = formattedArgs,
							rawArgs = args,
							timestamp = os.time(),
						}

						table.insert(RemoteLogs, 1, logData)
						if not IsPaused then
							addLogEntry(logData, 1)
						end
					end)
					table.insert(ClientHooks, conn)
				end
			end)
			table.insert(ClientHooks, connection)
		end

		local function stopClientMonitoring()
			MonitoringClient = false
			for _, connection in ipairs(ClientHooks) do
				connection:Disconnect()
			end
			ClientHooks = {}
		end

		local function updateStatus()
			local status = {}
			if IsMonitoring then
				table.insert(status, "Server")
			end
			if MonitoringClient then
				table.insert(status, "Client")
			end
			if #status > 0 then
				StatusLabel.Text = "Monitoring: " .. table.concat(status, " + ")
				StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			else
				StatusLabel.Text = "Not monitoring"
				StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			end
		end

		-- Button Handlers
		PauseButton.MouseButton1Click:Connect(function()
			IsPaused = not IsPaused
			PauseButton.Text = IsPaused and "Resume" or "Pause"
			PauseButton.BackgroundColor3 = IsPaused and Color3.fromRGB(120, 40, 40) or Settings.Theme.Button
		end)

		ClearButton.MouseButton1Click:Connect(function()
			for _, child in ipairs(LogList:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
			RemoteLogs = {}
			SelectedLogIndex = nil
			updateDetailPanel(nil)
			LogList.CanvasSize = UDim2.new(0, 0, 0, 0)
		end)

		ServerMonitorButton.MouseButton1Click:Connect(function()
			if not IsMonitoring then
				-- Start server monitoring
				local success = Dex_RemoteFunction:InvokeServer("StartRemoteSpy")
				if success then
					IsMonitoring = true
					ServerMonitorButton.Text = "Server: ON"
					ServerMonitorButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
					updateStatus()
				else
					warn("Failed to start server remote monitoring")
				end
			else
				-- Stop server monitoring
				local success = Dex_RemoteFunction:InvokeServer("StopRemoteSpy")
				if success then
					IsMonitoring = false
					ServerMonitorButton.Text = "Server: OFF"
					ServerMonitorButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
					updateStatus()
				end
			end
		end)

		ClientMonitorButton.MouseButton1Click:Connect(function()
			if not MonitoringClient then
				setupClientMonitoring()
				ClientMonitorButton.Text = "Client: ON"
				ClientMonitorButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
				updateStatus()
			else
				stopClientMonitoring()
				ClientMonitorButton.Text = "Client: OFF"
				ClientMonitorButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
				updateStatus()
			end
		end)

		AutoScrollButton.MouseButton1Click:Connect(function()
			AutoScroll = not AutoScroll
			AutoScrollButton.BackgroundColor3 = AutoScroll and Color3.fromRGB(40, 120, 40)
				or Color3.fromRGB(120, 40, 40)
		end)

		-- Create Block List Editor Window
		local function createBlockListEditor()
			if blockListWindow then
				blockListWindow:Show()
				blockListWindow.Gui.DisplayOrder = 100 -- Always on top
				return
			end

			blockListWindow = Lib.Window.new()
			blockListWindow:SetTitle("Block List Editor")
			blockListWindow:Resize(500, 300)
			blockListWindow.Gui.DisplayOrder = 100 -- Always on top

			local editorFrame = createSimple("Frame", {
				Name = "BlockListEditorContent",
				Parent = blockListWindow.GuiElems.Content,
				BackgroundColor3 = Settings.Theme.Main1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
			})

			-- Info Note
			createSimple("TextLabel", {
				Parent = editorFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 5),
				Size = UDim2.new(1, -10, 0, 15),
				Font = Enum.Font.Code,
				Text = "Note: Blocking only hides remotes from view, it does not prevent them from firing.",
				TextColor3 = Color3.fromRGB(200, 200, 100),
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
			})

			-- Add Remote Input Section
			local inputLabel = createSimple("TextLabel", {
				Parent = editorFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 22),
				Size = UDim2.new(1, -10, 0, 15),
				Font = Enum.Font.SourceSansBold,
				Text = "Add Remote to Block List:",
				TextColor3 = Settings.Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local inputBox = createSimple("TextBox", {
				Name = "InputBox",
				Parent = editorFrame,
				BackgroundColor3 = Settings.Theme.TextBox,
				BorderSizePixel = 1,
				BorderColor3 = Settings.Theme.Outline3,
				Position = UDim2.new(0, 5, 0, 42),
				Size = UDim2.new(1, -90, 0, 25),
				Font = Enum.Font.Code,
				PlaceholderText = "Enter remote name or pattern...",
				Text = "",
				TextColor3 = Settings.Theme.Text,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
			})

			local addButton = createSimple("TextButton", {
				Parent = editorFrame,
				BackgroundColor3 = Settings.Theme.Button,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -80, 0, 42),
				Size = UDim2.new(0, 75, 0, 25),
				Font = Enum.Font.SourceSansBold,
				Text = "Add",
				TextColor3 = Settings.Theme.Text,
				TextSize = 12,
			})

			-- Block List Display
			local listLabel = createSimple("TextLabel", {
				Parent = editorFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 77),
				Size = UDim2.new(1, -10, 0, 15),
				Font = Enum.Font.SourceSansBold,
				Text = "Blocked Remotes:",
				TextColor3 = Settings.Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local blockListScroll = createSimple("ScrollingFrame", {
				Name = "BlockListScroll",
				Parent = editorFrame,
				BackgroundColor3 = Settings.Theme.Main2,
				BorderSizePixel = 1,
				BorderColor3 = Settings.Theme.Outline1,
				Position = UDim2.new(0, 5, 0, 97),
				Size = UDim2.new(1, -10, 1, -102),
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = Settings.Theme.Outline2,
				CanvasSize = UDim2.new(0, 0, 0, 0),
			})

			createSimple("UIListLayout", {
				Parent = blockListScroll,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			})

			-- Function to refresh block list display
			local function refreshBlockList()
				for _, child in ipairs(blockListScroll:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end

				for i, pattern in ipairs(BlockList) do
					local entryFrame = createSimple("Frame", {
						Name = "BlockEntry",
						Parent = blockListScroll,
						BackgroundColor3 = Settings.Theme.Main1,
						BorderSizePixel = 1,
						BorderColor3 = Settings.Theme.Outline1,
						Size = UDim2.new(1, -10, 0, 25),
						LayoutOrder = i,
					})

					createSimple("TextLabel", {
						Parent = entryFrame,
						BackgroundTransparency = 1,
						Position = UDim2.new(0, 5, 0, 0),
						Size = UDim2.new(1, -35, 1, 0),
						Font = Enum.Font.Code,
						Text = pattern,
						TextColor3 = Settings.Theme.Text,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
					})

					local removeBtn = createSimple("TextButton", {
						Parent = entryFrame,
						BackgroundColor3 = Color3.fromRGB(150, 50, 50),
						BorderSizePixel = 0,
						Position = UDim2.new(1, -28, 0, 3),
						Size = UDim2.new(0, 25, 0, 19),
						Font = Enum.Font.SourceSansBold,
						Text = "X",
						TextColor3 = Settings.Theme.Text,
						TextSize = 12,
					})

					removeBtn.MouseButton1Click:Connect(function()
						removeFromBlockList(pattern)
						-- refreshBlockList is called automatically via callback
					end)
				end

				blockListScroll.CanvasSize = UDim2.new(0, 0, 0, #BlockList * 27)
			end

			-- Set the refresh callback so block buttons can update this UI
			blockListRefreshCallback = refreshBlockList

			-- Add button handler
			addButton.MouseButton1Click:Connect(function()
				local pattern = inputBox.Text
				if pattern and pattern ~= "" then
					if addToBlockList(pattern) then
						inputBox.Text = ""
						refreshBlockList()
					end
				end
			end)

			-- Enter key handler
			inputBox.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					local pattern = inputBox.Text
					if pattern and pattern ~= "" then
						if addToBlockList(pattern) then
							inputBox.Text = ""
							refreshBlockList()
						end
					end
				end
			end)

			refreshBlockList()
			blockListWindow:Show()
		end

		BlockListButton.MouseButton1Click:Connect(function()
			createBlockListEditor()
		end)
	end

	-- Add log entry to UI (implementation)
	addLogEntry = function(logData, index)
		if IsPaused then
			return
		end

		-- Check if this remote is blocked
		if isBlocked(logData.remoteName) then
			return
		end

		local logIndex = index or #RemoteLogs

		-- Create log entry frame
		local LogEntry = createSimple("TextButton", {
			Name = "LogEntry",
			Parent = LogList,
			BackgroundColor3 = Settings.Theme.Main2,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 60),
			LayoutOrder = index and -index or logIndex,
			Text = "",
			AutoButtonColor = false,
		})

		createSimple("UIStroke", {
			Parent = LogEntry,
			Color = Settings.Theme.Outline1,
			Thickness = 1,
		})

		-- Timestamp
		createSimple("TextLabel", {
			Name = "Timestamp",
			Parent = LogEntry,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 2),
			Size = UDim2.new(0, 60, 0, 15),
			Font = Enum.Font.Code,
			Text = os.date("%H:%M:%S", logData.timestamp),
			TextColor3 = Color3.fromRGB(150, 150, 150),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- Remote Type
		local typeColor = logData.remoteType:match("FireServer") and Color3.fromRGB(100, 200, 255)
			or logData.remoteType:match("InvokeServer") and Color3.fromRGB(255, 200, 100)
			or logData.remoteType:match("FireClient") and Color3.fromRGB(100, 255, 200)
			or logData.remoteType:match("InvokeClient") and Color3.fromRGB(255, 150, 255)
			or Color3.fromRGB(255, 150, 100)

		createSimple("TextLabel", {
			Name = "Type",
			Parent = LogEntry,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 70, 0, 2),
			Size = UDim2.new(0, 100, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = logData.remoteType,
			TextColor3 = typeColor,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- Remote Name
		createSimple("TextLabel", {
			Name = "RemoteName",
			Parent = LogEntry,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 18),
			Size = UDim2.new(1, -10, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = logData.remoteName,
			TextColor3 = Settings.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- Caller
		local callerText = "From: " .. tostring(logData.caller)
		createSimple("TextLabel", {
			Name = "Caller",
			Parent = LogEntry,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 33),
			Size = UDim2.new(1, -10, 0, 12),
			Font = Enum.Font.Code,
			Text = callerText,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- Arguments Preview
		local argsText = "Args: " .. formatArgsPreview(logData.rawArgs or logData.args)
		createSimple("TextLabel", {
			Name = "Args",
			Parent = LogEntry,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 45),
			Size = UDim2.new(1, -45, 0, 12),
			Font = Enum.Font.Code,
			Text = argsText,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		-- Block Button
		local blockButton = createSimple("TextButton", {
			Name = "BlockButton",
			Parent = LogEntry,
			BackgroundColor3 = Color3.fromRGB(150, 50, 50),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -38, 0, 43),
			Size = UDim2.new(0, 35, 0, 15),
			Font = Enum.Font.SourceSansBold,
			Text = "Block",
			TextColor3 = Settings.Theme.Text,
			TextSize = 9,
			AutoButtonColor = false,
		})

		blockButton.MouseButton1Click:Connect(function()
			addToBlockList(logData.remoteName)
			-- Remove this entry from the display
			LogEntry:Destroy()
		end)

		-- Click handler to show details
		LogEntry.MouseButton1Click:Connect(function()
			-- Deselect previous
			if SelectedLogIndex then
				local prevEntry = LogList:FindFirstChild("LogEntry")
				if prevEntry then
					for _, child in ipairs(LogList:GetChildren()) do
						if child:IsA("TextButton") and child.LayoutOrder == (index and -index or SelectedLogIndex) then
							child.BackgroundColor3 = Settings.Theme.Main2
						end
					end
				end
			end

			-- Select this one
			SelectedLogIndex = logIndex
			LogEntry.BackgroundColor3 = Settings.Theme.ListSelection
			updateDetailPanel(logData)
		end)

		-- Limit logs
		if #RemoteLogs > MaxLogs then
			local oldest = LogList:FindFirstChild("LogEntry")
			if oldest then
				oldest:Destroy()
			end
			table.remove(RemoteLogs, #RemoteLogs)
		end

		-- Update canvas size
		LogList.CanvasSize = UDim2.new(0, 0, 0, #RemoteLogs * 62)

		-- Auto-scroll to top for new entries if enabled
		if AutoScroll then
			LogList.CanvasPosition = Vector2.new(0, 0)
		end
	end

	-- Setup listener for server-side remote spy logs
	local function setupLogListener()
		RemoteSpy_LogEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteSpy_LogEvent", 10)
		if RemoteSpy_LogEvent then
			LogEventConnection = RemoteSpy_LogEvent.OnClientEvent:Connect(function(logData)
				if logData and not IsPaused then
					-- Add rawArgs field (server sends it as args)
					logData.rawArgs = logData.args or {}
					-- Convert args to strings for preview
					local formattedArgs = {}
					for _, arg in ipairs(logData.rawArgs) do
						table.insert(formattedArgs, tostring(arg))
					end
					logData.args = formattedArgs

					table.insert(RemoteLogs, 1, logData)
					addLogEntry(logData, 1)
				end
			end)
		end
	end

	-- Initialize
	local function init()
		createUI()
		setupLogListener()
	end

	-- Public API
	RemoteSpy.Init = init

	return RemoteSpy
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
