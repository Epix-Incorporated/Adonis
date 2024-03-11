local players = game:GetService("Players")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local contextService = game:GetService("ContextActionService")

local part = script.Parent

if not part then
	script:Destroy()
end

local player = players.LocalPlayer
local char = player.Character

local MoveVector = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

local human = char:FindFirstChildOfClass("Humanoid")
local bPos: AlignPosition = part:WaitForChild("ADONIS_FLIGHT_POSITION")
local bGyro: AlignOrientation = part:WaitForChild("ADONIS_FLIGHT_GYRO")

local speedVal = script:WaitForChild("Speed")
local noclip = script:WaitForChild("Noclip")
local Create = Instance.new
local flying = true

local keyTab = {}
local dir = {}

local antiLoop, conn
local Check, getCF, dirToCom, Start, Stop, Toggle, HandleInput, listenConnection

local RBXConnections = {}
function listenConnection(Connection, callback)
	local RBXConnection = Connection:Connect(callback)
	table.insert(RBXConnections, RBXConnection)
	return RBXConnection
end

function Check()
	if script.Parent == part then
		return true
	end
end

function getCF(part, isFor)
	local cframe = part.CFrame
	local noRot = CFrame.new(cframe.p)
	local x, y, z = workspace.CurrentCamera.CFrame.Rotation:toEulerAnglesXYZ()
	return noRot * CFrame.Angles(isFor and z or x, y, z)
end

function Start()
	local curSpeed = 0
	local topSpeed = speedVal.Value
	local speedInc = topSpeed/25
	local camera = workspace.CurrentCamera
	local antiReLoop = {}
	local realPos = part.CFrame

	listenConnection(speedVal.Changed, function()
		topSpeed = speedVal.Value
		speedInc = topSpeed/25
	end)

	bPos.Position = part.Position
	bPos.MaxForce = math.huge

	bGyro.CFrame = part.CFrame
	bGyro.MaxTorque = 9e9

	antiLoop = antiReLoop

	if noclip.Value then
		conn = runService.Stepped:Connect(function()
			for _,v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
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
		bPos.Position = new.p

		if dir.Forward then
			bGyro.CFrame = camera.CFrame*CFrame.Angles(-math.rad(curSpeed*7.5), 0, 0)
		elseif dir.Backward then
			bGyro.CFrame = camera.CFrame*CFrame.Angles(math.rad(curSpeed*7.5), 0, 0)
		else
			bGyro.CFrame = camera.CFrame
		end

		runService.RenderStepped:Wait()
	end

	Stop()
end

function Stop()
	flying = false
	human.PlatformStand = false

	if bPos then
		bPos.MaxForce = 0
	end

	if bGyro then
		bGyro.MaxTorque = 0
	end

	if conn then
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
			keyTab.Up = bool
			dir.Up = bool
		end
		if not isGame then
			if input.KeyCode == Enum.KeyCode.W then
				keyTab.Forward = bool
				dir.Forward = bool
			elseif input.KeyCode == Enum.KeyCode.A then
				keyTab.Left = bool
				dir.Left = bool
			elseif input.KeyCode == Enum.KeyCode.S then
				keyTab.Backward = bool
				dir.Backward = bool
			elseif input.KeyCode == Enum.KeyCode.D then
				keyTab.Right = bool
				dir.Right = bool
			elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.DPadDown or input.KeyCode == Enum.KeyCode.ButtonB then
				keyTab.Down = bool
				dir.Down = bool
			elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.DPadUp then
				keyTab.Up = bool
				dir.Up = bool
			elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonL3 then
				Toggle()
			end
		end
	else
		if input == "Forward" then
			keyTab.Forward = bool
			dir.Forward = bool
		elseif input == "Backward" then
			keyTab.Backward = bool
			dir.Backward = bool
		elseif input == "Left" then
			keyTab.Left = bool
			dir.Left = bool
		elseif input == "Right" then
			keyTab.Right = bool
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
	local Inst = part.DescendantRemoving:Wait()

	if Inst == bPos or Inst == bGyro or Inst == speedVal or Inst == noclip then
		if conn then
			conn:Disconnect()
		end

		for _, Signal in pairs(RBXConnections) do
			Signal:Disconnect()
		end

		contextService:UnbindAction("Toggle Flight")

		Stop()
	end
end)

listenConnection(inputService.InputBegan, function(input, isGame)
	HandleInput(input, isGame, true)
end)

listenConnection(inputService.InputEnded, function(input, isGame)
	HandleInput(input, isGame, false)
end)

listenConnection(inputService.InputChanged, function(input, isGame)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		if input.Position.Magnitude < .2 then DPadifyInput(Vector3.new(0,0,0)) return end
		DPadifyInput(input.Position, isGame)
	end
end)

task.defer(Start)

if inputService.TouchEnabled then
	listenConnection(inputService.TouchMoved, function(input, isGame)
		local dir = MoveVector:GetMoveVector()
		if dir.Magnitude < .2 then DPadifyInput(Vector3.new(0,0,0)) return end

		local newDirOrder = Vector3.new(dir.X, -dir.Z, 0)
		DPadifyInput(newDirOrder, isGame)
	end)

	listenConnection(inputService.TouchEnded, function(input, isGame)
		DPadifyInput(Vector3.new(0,0,0))
	end)
	
	if not inputService.KeyboardEnabled then
		contextService:BindAction("Toggle Flight", Toggle, true)
		contextService:SetTitle("Toggle Flight", "Toggle Flight")
		
		listenConnection(human.Died, function()
			contextService:UnbindAction("Toggle Flight")
		end)

		while true do
			if not Check() then
				break
			end

			runService.Stepped:Wait()
		end

		contextService:UnbindAction("Toggle Flight")
	end
end
