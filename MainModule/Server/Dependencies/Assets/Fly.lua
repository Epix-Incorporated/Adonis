local part = script.Parent
local players = game:GetService("Players")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local contextService = game:GetService("ContextActionService")
local player = players.LocalPlayer
local char = player.Character
local human = char:FindFirstChildOfClass("Humanoid")
local bPos = part:WaitForChild("ADONIS_FLIGHT_POSITION")
local bGyro = part:WaitForChild("ADONIS_FLIGHT_GYRO")
local speedVal = script:WaitForChild("Speed")
local noclip = script:WaitForChild("Noclip")
local Create = Instance.new
local flying = true
local keyTab = {}
local dir = {}
local conn -- used for noclip
local antiLoop, humChanged = nil, nil

function Check()
	if script.Parent == part then
		return true
	end
end

function getCF(part, isFor)
	local cframe = part.CFrame
	local noRot = CFrame.new(cframe.p)
	local x, y, z = (workspace.CurrentCamera.CoordinateFrame - workspace.CurrentCamera.CoordinateFrame.p):toEulerAnglesXYZ()
	return noRot * CFrame.Angles(isFor and z or x, y, z)
end

function dirToCom(part, mdir)
	local dirs = {
		Forward = ((getCF(part, true)*CFrame.new(0, 0, -1)) - part.CFrame.p).p;
		Backward = ((getCF(part, true)*CFrame.new(0, 0, 1)) - part.CFrame.p).p;
		Right = ((getCF(part)*CFrame.new(1, 0, 0)) - part.CFrame.p).p;
		Left = ((getCF(part)*CFrame.new(-1, 0, 0)) - part.CFrame.p).p;
	}
	
	for i,v in next,dirs do
		if (v - mdir).magnitude <= 1.05 and mdir ~= Vector3.new(0,0,0) then
			dir[i] = true
		elseif not keyTab[i] then
			dir[i] = false
		end
	end
end

function Start()
	local curSpeed = 0
	local topSpeed = speedVal.Value
	local speedInc = topSpeed/25
	local camera = workspace.CurrentCamera
	local antiReLoop = {}
	local realPos = part.CFrame
	
	speedVal.Changed:Connect(function()
		topSpeed = speedVal.Value
		speedInc = topSpeed/25
	end)
	
	bPos.position = part.Position
	bPos.maxForce = Vector3.new(math.huge, math.huge, math.huge)

	bGyro.cframe = part.CFrame
	bGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	
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
	
	while flying and antiLoop == antiReLoop and Check() do
		local new = bGyro.cframe - bGyro.cframe.p + bPos.position
		if not dir.Forward and not dir.Backward and not dir.Up and not dir.Down and not dir.Left and not dir.Right then
			curSpeed = 1
		else
			if dir.Up then
				new = new * CFrame.new(0, curSpeed, 0)
				curSpeed = curSpeed + speedInc
			end
			
			if dir.Down then
				new = new * CFrame.new(0, -curSpeed, 0)
				curSpeed = curSpeed + speedInc
			end
			
			if dir.Forward then
				new = new + camera.CoordinateFrame.lookVector * curSpeed
				curSpeed = curSpeed + speedInc
			end
			
			if dir.Backward then
				new = new - camera.CoordinateFrame.lookVector * curSpeed
				curSpeed = curSpeed + speedInc
			end
			
			if dir.Left then
				new = new * CFrame.new(-curSpeed, 0, 0)
				curSpeed = curSpeed + speedInc
			end
			
			if dir.Right then
				new = new * CFrame.new(curSpeed, 0, 0)
				curSpeed = curSpeed + speedInc
			end
		
			if curSpeed > topSpeed then
				curSpeed = topSpeed
			end
		end
		
		human.PlatformStand = true
		bPos.position = new.p
	
		if dir.Forward then
			bGyro.cframe = camera.CoordinateFrame*CFrame.Angles(-math.rad(curSpeed*7.5), 0, 0)
		elseif dir.Backward then
			bGyro.cframe = camera.CoordinateFrame*CFrame.Angles(math.rad(curSpeed*7.5), 0, 0)
		else
			bGyro.cframe = camera.CoordinateFrame
		end
		
		runService.RenderStepped:Wait()
	end
	
	Stop()
end

function Stop()
	flying = false
	human.PlatformStand = false
	
	if humChanged then
		humChanged:Disconnect()
	end
	
	if bPos then
		bPos.maxForce = Vector3.new(0, 0, 0)
	end
	
	if bGyro then
		bGyro.maxTorque = Vector3.new(0, 0, 0)
	end
	
	if conn then
		conn:Disconnect()
	end
end

part.ChildRemoved:Connect(function(inst)
	if inst.Name == "ADONIS_FLIGHT_POSITION" or inst.Name == "ADONIS_FLIGHT_GYRO" then
		Stop()
	end
end)

local debounce = false
function Toggle()
	if not debounce then
		debounce = true
		if not flying then
			flying = true
			coroutine.wrap(Start)()
		else
			flying = false
			Stop()
		end
		wait(0.5)
		debounce = false
	end
end

local function HandleInput(input, isGame, bool)
	if not isGame then
		if input.UserInputType == Enum.UserInputType.Keyboard then
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
			elseif input.KeyCode == Enum.KeyCode.Q then
				keyTab.Down = bool
				dir.Down = bool
			elseif input.KeyCode == Enum.KeyCode.Space then
				keyTab.Up = bool
				dir.Up = bool
			elseif input.KeyCode == Enum.KeyCode.E and bool == true then
				Toggle()
			elseif input.KeyCode == Enum.KeyCode.R and flying then
				if speedVal.Value >= 12 then
					speedVal.Value = 12
					return
				end
				speedVal.Value = speedVal.Value + 2
			elseif input.KeyCode == Enum.KeyCode.F and flying then
				if speedVal.Value <= 2 then
					speedVal.Value = 2
					return
				end
				speedVal.Value = speedVal.Value - 2
			end
		end
	end
end

inputService.InputBegan:Connect(function(input, isGame)
	HandleInput(input, isGame, true)
end)

inputService.InputEnded:Connect(function(input, isGame)
	HandleInput(input, isGame, false)
end)
	
coroutine.wrap(Start)()

if not inputService.KeyboardEnabled then
	human.Changed:connect(function()
		dirToCom(part, human.MoveDirection)
	end)
	
	contextService:BindAction("Toggle Flight", Toggle, true)
	while Check() and wait(0.05) do end
	contextService:UnbindAction("Toggle Flight")
	script:Destroy()
end