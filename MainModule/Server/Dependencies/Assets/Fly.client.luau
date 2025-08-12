local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextService = game:GetService("ContextActionService")

local part = script.Parent

if not part then
	script:Destroy()
end

local player = Players.LocalPlayer
local char = player.Character

local human = char:FindFirstChildOfClass("Humanoid")
local bPos: AlignPosition = part:WaitForChild("ADONIS_FLIGHT_POSITION")
local bGyro: AlignOrientation = part:WaitForChild("ADONIS_FLIGHT_GYRO")

local speedVal: NumberValue = script:WaitForChild("Speed")
local noclip: BoolValue = script:WaitForChild("Noclip")
local flying = true

local dir = {}

local antiLoop, conn
local Check, Start, Stop, Toggle, HandleInput, DPadifyInput

local connections: {RBXScriptConnection} = {}

function Check()
	if script.Parent == part then
		return true
	end
end

function Start()
	local curSpeed = 0
	local topSpeed = speedVal.Value
	local speedInc = topSpeed/25
	local camera = workspace.CurrentCamera
	local antiReLoop = {}

	table.insert(connections, speedVal.Changed:Connect(function(speed)
		topSpeed = speed
		speedInc = topSpeed/25
	end))

	bPos.Position = part.Position
	bPos.MaxForce = math.huge

	bGyro.CFrame = part.CFrame
	bGyro.MaxTorque = 9e9

	antiLoop = antiReLoop

	if noclip.Value then
		conn = RunService.PreSimulation:Connect(function()
			for _, v in ipairs(char:GetDescendants()) do
				if v:IsA("BasePart") and v.CanCollide then
					v.CanCollide = false
				end
			end
		end)
	end

	while flying and antiLoop == antiReLoop do
		if not Check() then
			break
		end

		local new = bGyro.CFrame.Rotation + bPos.Position
		if not dir.Forward and not dir.Backward and not dir.Up and not dir.Down and not dir.Left and not dir.Right then
			curSpeed = 1
		else
			if dir.Up then
				new *= CFrame.new(0, curSpeed, 0)
				curSpeed += speedInc
			end

			if dir.Down then
				new *= CFrame.new(0, -curSpeed, 0)
				curSpeed += speedInc
			end

			if dir.Forward then
				new += camera.CFrame.LookVector * curSpeed
				curSpeed += speedInc
			end

			if dir.Backward then
				new -= camera.CFrame.LookVector * curSpeed
				curSpeed += speedInc
			end

			if dir.Left then
				new *= CFrame.new(-curSpeed, 0, 0)
				curSpeed += speedInc
			end

			if dir.Right then
				new *= CFrame.new(curSpeed, 0, 0)
				curSpeed += speedInc
			end

			if curSpeed > topSpeed then
				curSpeed = topSpeed
			end
		end

		human.PlatformStand = true
		bPos.Position = new.Position

		if dir.Forward then
			bGyro.CFrame = camera.CFrame*CFrame.Angles(-math.rad(curSpeed*7.5), 0, 0)
		elseif dir.Backward then
			bGyro.CFrame = camera.CFrame*CFrame.Angles(math.rad(curSpeed*7.5), 0, 0)
		else
			bGyro.CFrame = camera.CFrame
		end

		RunService.PreRender:Wait()
	end

	Stop()
end

function Stop()
	flying = false
	human.PlatformStand = false

	local collisionPart: BasePart = human.Parent:FindFirstChild("CollisionPart")
	if collisionPart then
		collisionPart.CanCollide = true
	end

	if bPos then
		bPos.MaxForce = 0
	end

	if bGyro then
		bGyro.MaxTorque = 0
	end

	if conn and conn.Connected then
		conn:Disconnect()
	end
end

local debounce = false
function Toggle()
	if not debounce then
		debounce = true
		if not flying then
			flying = true
			task.defer(Start)
		else
			flying = false
			Stop()
		end
		task.wait(0.5)
		debounce = false
	end
end

function HandleInput(input, isGame, bool)
	if input.UserInputType and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.Gamepad1) then
		if input.KeyCode == Enum.KeyCode.ButtonA then
			dir.Up = bool
		end
		if not isGame then
			if input.KeyCode == Enum.KeyCode.W then
				dir.Forward = bool
			elseif input.KeyCode == Enum.KeyCode.A then
				dir.Left = bool
			elseif input.KeyCode == Enum.KeyCode.S then
				dir.Backward = bool
			elseif input.KeyCode == Enum.KeyCode.D then
				dir.Right = bool
			elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.DPadDown or input.KeyCode == Enum.KeyCode.ButtonB then
				dir.Down = bool
			elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.DPadUp then
				dir.Up = bool
			elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonL3 then
				Toggle()
			end
		end
	else
		if input == "Forward" then
			dir.Forward = bool
		elseif input == "Backward" then
			dir.Backward = bool
		elseif input == "Left" then
			dir.Left = bool
		elseif input == "Right" then
			dir.Right = bool
		end
	end
end

function DPadifyInput(direction, isGame)
	-- DPadify input for mobile and controller thumbsticks
	if direction.Magnitude == 0 then
		HandleInput("Forward", false, false)
		HandleInput("Backward", false, false)
		HandleInput("Left", false, false)
		HandleInput("Right", false, false)
	end

	local xDir, yDir, zDir = math.round(direction.X), math.round(direction.Y), math.round(direction.Z)
	if xDir == 1 then HandleInput("Right", isGame, true) end
	if xDir == -1 then HandleInput("Left", isGame, true) end
	if xDir == 0 then HandleInput("Right", isGame, false); HandleInput("Left", isGame, false) end
	if yDir == 1 then HandleInput("Forward", isGame, true) end
	if yDir == -1 then HandleInput("Backward", isGame, true) end
	if yDir == 0 then HandleInput("Forward", isGame, false); HandleInput("Backward", isGame, false) end
end

task.spawn(function()
	while true do
		local Inst = part.DescendantRemoving:Wait()

		if Inst == bPos or Inst == bGyro or Inst == speedVal or Inst == noclip then
			for _, Signal in ipairs(connections) do
				if Signal.Connected then
					Signal:Disconnect()
				end
			end
			table.clear(connections)

			ContextService:UnbindAction("Toggle Flight")
			Stop()
		end
	end
end)

task.spawn(function()
	script.Destroying:Wait()

	for _, Signal in ipairs(connections) do
		if Signal.Connected then
			Signal:Disconnect()
		end
	end
	table.clear(connections)

	ContextService:UnbindAction("Toggle Flight")
	Stop()
end)

table.insert(connections, UserInputService.InputBegan:Connect(function(input, isGame)
	HandleInput(input, isGame, true)
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input, isGame)
	HandleInput(input, isGame, false)
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input, isGame)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		if input.Position.Magnitude < .2 then DPadifyInput(Vector3.zero) return end
		DPadifyInput(input.Position, isGame)
	end
end))

task.defer(Start)

if UserInputService.TouchEnabled then
	local MoveVector = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

	table.insert(connections, UserInputService.TouchMoved:Connect(function(input, isGame)
		local dir = MoveVector:GetMoveVector()
		if dir.Magnitude < .2 then DPadifyInput(Vector3.zero) return end

		local newDirOrder = Vector3.new(dir.X, -dir.Z, 0)
		DPadifyInput(newDirOrder, isGame)
	end))

	table.insert(connections, UserInputService.TouchEnded:Connect(function(input, isGame)
		DPadifyInput(Vector3.zero)
	end))

	if not UserInputService.KeyboardEnabled then
		ContextService:BindAction("Toggle Flight", Toggle, true)
		ContextService:SetTitle("Toggle Flight", "Toggle Flight")

		table.insert(connections, human.Died:Once(function()
			ContextService:UnbindAction("Toggle Flight")
		end))
	end
end