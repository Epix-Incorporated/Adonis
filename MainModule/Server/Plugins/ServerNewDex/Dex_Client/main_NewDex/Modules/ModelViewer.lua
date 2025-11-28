--[[
	Model Viewer App Module
	
	A model viewer :3
]]

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

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
	Notebook = Apps.Notebook
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function main()
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local ModelViewer = {
		EnableInputCamera = true,
		IsViewing = false,
		AutoRefresh = false,
		ZoomMultiplier = 2,
		AutoRotate = true,
		RotationSpeed = 0.01,
		RefreshRate = 30, -- hertz
	}

	local window, viewportFrame, pathLabel, settingsButton
	local model, camera, originalModel

	ModelViewer.StopViewModel = function(updating)
		if updating then
			viewportFrame:FindFirstChildOfClass("Model"):Destroy()
		else
			if camera then
				camera = nil
			end
			if model then
				model = nil
			end
			viewportFrame:ClearAllChildren()

			ModelViewer.IsViewing = false
			window:SetTitle("Model Viewer")
			pathLabel.Gui.Text = ""
		end
	end

	ModelViewer.ViewModel = function(item, updating)
		if not item then
			return
		end
		ModelViewer.StopViewModel(updating)

		if item ~= workspace and not item:IsA("Terrain") then
			-- why Model == workspace
			-- wtf?

			if item:IsA("BasePart") and not item:IsA("Model") then
				model = Instance.new("Model")
				model.Parent = viewportFrame

				local clone = item:Clone()
				clone.Parent = model
				model.PrimaryPart = clone
				model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
			elseif item:IsA("Model") then
				item.Archivable = true

				--[[if not item.PrimaryPart then
				pathLabel.Gui.Text = "Failed to view model: No PrimaryPart is found."
				return
			end]]
				if #item:GetChildren() == 0 then
					return
				end

				model = item:Clone()
				model.Parent = viewportFrame

				-- fallback
				if not model.PrimaryPart then
					local found = false
					for _, child in model:GetDescendants() do
						if child:IsA("BasePart") then
							model.PrimaryPart = child
							model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
							found = true
							break
						end
					end
					if not found then
						model:Destroy()
						model = nil
						return
					end
				end
			else
				return
			end
		end

		originalModel = item

		if ModelViewer.AutoRefresh and not updating then
			task.spawn(function()
				while model and ModelViewer.AutoRefresh do
					ModelViewer.ViewModel(originalModel, true)
					task.wait(1 / ModelViewer.RefreshRate)
				end
			end)
		end

		if not updating then
			camera = Instance.new("Camera")
			viewportFrame.CurrentCamera = camera

			camera.Parent = viewportFrame
			camera.FieldOfView = 60

			window:SetTitle(item.Name .. " - Model Viewer")
			pathLabel.Gui.Text = "path: " .. getPath(originalModel)
			window:Show()
			ModelViewer.IsViewing = true
		end
	end

	ModelViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Model Viewer")
		window:Resize(350, 200)
		ModelViewer.Window = window

		viewportFrame = Instance.new("ViewportFrame")
		viewportFrame.Parent = window.GuiElems.Content
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Size = UDim2.new(1, 0, 1, 0)

		pathLabel = Lib.Label.new()
		pathLabel.Gui.Parent = window.GuiElems.Content
		pathLabel.Gui.AnchorPoint = Vector2.new(0, 1)
		pathLabel.Gui.Text = ""
		pathLabel.Gui.TextSize = 12
		pathLabel.Gui.TextTransparency = 0.8
		pathLabel.Gui.Position = UDim2.new(0, 1, 1, 0)
		pathLabel.Gui.Size = UDim2.new(1, -1, 0, 15)
		pathLabel.Gui.BackgroundTransparency = 1

		settingsButton = Instance.new("ImageButton", window.GuiElems.Content)
		settingsButton.AnchorPoint = Vector2.new(1, 0)
		settingsButton.BackgroundTransparency = 1
		settingsButton.Size = UDim2.new(0, 15, 0, 15)
		settingsButton.Position = UDim2.new(1, -3, 0, 3)
		settingsButton.Image = "rbxassetid://6578871732"
		settingsButton.ImageTransparency = 0.5
		-- mobile input check
		if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
			settingsButton.Visible = true
		else
			settingsButton.Visible = false
		end

		local rotationX, rotationY = -15, 0
		local distance = 10
		local dragging = false
		local hovering = false
		local lastpos = Vector2.zero

		viewportFrame.InputBegan:Connect(function(input)
			if not ModelViewer.EnableInputCamera then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				lastpos = input.Position
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 10
			end
		end)

		viewportFrame.MouseEnter:Connect(function()
			hovering = true
		end)
		viewportFrame.MouseLeave:Connect(function()
			hovering = false
		end)

		viewportFrame.InputEnded:Connect(function(input)
			if not ModelViewer.EnableInputCamera then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = false
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 2
			end
		end)

		viewportFrame.InputChanged:Connect(function(input)
			if not ModelViewer.EnableInputCamera then
				return
			end
			if
				dragging and input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				local delta = input.Position - lastpos
				lastpos = input.Position

				rotationY -= delta.X * 0.01
				rotationX -= delta.Y * 0.01
				rotationX = math.clamp(rotationX, -math.pi / 2 + 0.1, math.pi / 2 - 0.1)
			end

			if input.UserInputType == Enum.UserInputType.MouseWheel and hovering then
				distance = math.clamp(distance - (input.Position.Z * ModelViewer.ZoomMultiplier), 0.1, math.huge)
			end
		end)

		RunService.RenderStepped:Connect(function()
			if camera and model then
				if not dragging and ModelViewer.AutoRotate then
					rotationY += ModelViewer.RotationSpeed
				end

				local center = model.PrimaryPart.Position
				local offset = CFrame.new(0, 0, distance)
				local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)

				local camCF = CFrame.new(center) * rotation * offset

				camera.CFrame = CFrame.lookAt(camCF.Position, center)
			end
		end)

		-- context stuffs
		local context = Lib.ContextMenu.new()

		local absoluteSize = context.Gui.AbsoluteSize
		context.MaxHeight = (absoluteSize.Y <= 600 and (absoluteSize.Y - 40)) or nil

		-- Registers
		context:Register("STOP", {
			Name = "Stop Viewing",
			OnClick = function()
				ModelViewer.StopViewModel()
			end,
		})
		context:Register("EXIT", {
			Name = "Exit",
			OnClick = function()
				ModelViewer.StopViewModel()
				context:Hide()
				window:Hide()
			end,
		})
		context:Register("COPY_PATH", {
			Name = "Copy Path",
			OnClick = function()
				if model then
					env.setclipboard(getPath(originalModel))
				end
			end,
		})
		context:Register("REFRESH", {
			Name = "Refresh",
			OnClick = function()
				if originalModel then
					ModelViewer.ViewModel(originalModel)
				end
			end,
		})
		context:Register("ENABLE_AUTO_REFRESH", {
			Name = "Enable Auto Refresh",
			OnClick = function()
				if originalModel then
					ModelViewer.AutoRefresh = true
					ModelViewer.ViewModel(originalModel)
				end
			end,
		})
		context:Register("DISABLE_AUTO_REFRESH", {
			Name = "Disable Auto Refresh",
			OnClick = function()
				if originalModel then
					ModelViewer.AutoRefresh = false
					ModelViewer.ViewModel(originalModel)
				end
			end,
		})
		context:Register("SAVE_INST", {
			Name = "Save to File",
			OnClick = function()
				if model then
					window:SetTitle(originalModel.Name .. " - Model Viewer - Saving")
					local success, result = pcall(
						env.saveinstance,
						originalModel,
						"Place_" .. game.PlaceId .. "_" .. originalModel.Name .. "_" .. os.time(),
						{
							Decompile = true,
						}
					)
					if success then
						window:SetTitle(originalModel.Name .. " - Model Viewer - Saved")
						context:Hide()
						task.wait(5)
						if model then
							window:SetTitle(originalModel.Name .. " - Model Viewer")
						end
					else
						window:SetTitle(originalModel.Name .. " - Model Viewer - Error")
						warn("Error while saving model: " .. result)
						context:Hide()
						task.wait(5)
						if model then
							window:SetTitle(originalModel.Name .. " - Model Viewer")
						end
					end
				end
			end,
		})

		context:Register("ENABLE_AUTO_ROTATE", {
			Name = "Enable Auto Rotate",
			OnClick = function()
				ModelViewer.AutoRotate = true
			end,
		})
		context:Register("DISABLE_AUTO_ROTATE", {
			Name = "Disable Auto Rotate",
			OnClick = function()
				ModelViewer.AutoRotate = false
			end,
		})
		context:Register("LOCK_CAM", {
			Name = "Lock Camera",
			OnClick = function()
				ModelViewer.EnableInputCamera = false
			end,
		})
		context:Register("UNLOCK_CAM", {
			Name = "Unlock Camera",
			OnClick = function()
				ModelViewer.EnableInputCamera = true
			end,
		})

		context:Register("ZOOM_IN", {
			Name = "Zoom In",
			OnClick = function()
				distance = math.clamp(distance - (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
			end,
		})

		context:Register("ZOOM_OUT", {
			Name = "Zoom Out",
			OnClick = function()
				distance = math.clamp(distance + (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
			end,
		})

		local function ShowContext()
			context:Clear()

			context:AddRegistered("STOP", not ModelViewer.IsViewing)
			context:AddRegistered("REFRESH", not ModelViewer.IsViewing)
			context:AddRegistered("COPY_PATH", not ModelViewer.IsViewing)
			context:AddRegistered("SAVE_INST", not ModelViewer.IsViewing)
			context:AddDivider()

			if env.isonmobile then
				context:AddRegistered("ZOOM_IN")
				context:AddRegistered("ZOOM_OUT")
				context:AddDivider()
			end

			if ModelViewer.AutoRotate then
				context:AddRegistered("DISABLE_AUTO_ROTATE")
			else
				context:AddRegistered("ENABLE_AUTO_ROTATE")
			end
			if ModelViewer.AutoRefresh then
				context:AddRegistered("DISABLE_AUTO_REFRESH")
			else
				context:AddRegistered("ENABLE_AUTO_REFRESH")
			end
			if ModelViewer.EnableInputCamera then
				context:AddRegistered("LOCK_CAM")
			else
				context:AddRegistered("UNLOCK_CAM")
			end

			context:AddDivider()

			context:AddRegistered("EXIT")

			context:Show()
		end

		local function HideContext()
			context:Hide()
		end

		viewportFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				ShowContext()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 and Lib.CheckMouseInGui(context.Gui) then
				HideContext()
			end
		end)
		settingsButton.MouseButton1Click:Connect(function()
			ShowContext()
		end)
	end

	return ModelViewer
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
