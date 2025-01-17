task.wait()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local mode = script.Mode.Value--"Teleport"
local name = script.Target.Value
local localplayer = Players.LocalPlayer
local mouse = localplayer:GetMouse()
local tool = script.Parent
local use = false
local holding = false
local target = Players:WaitForChild(name)
local char = target.Character
local humanoid = char:FindFirstChildOfClass("Humanoid")
if not humanoid then tool:Destroy() return end

tool.Name = `{mode} {target.Name}`

local function onButton1Down(mouse)
	if not target.Character or not target.Character:FindFirstChildOfClass("Humanoid") then
		return
	elseif mode == "Teleport" then
		local rootPart = humanoid.RootPart
		if not rootPart then return end
		local FlightPos, FlightGyro = rootPart:FindFirstChild("ADONIS_FLIGHT_POSITION"), rootPart:FindFirstChild("ADONIS_FLIGHT_GYRO")
		local pos = mouse.Hit.Position

		if FlightPos and FlightGyro then  
			FlightPos.Position = rootPart.Position
			FlightGyro.CFrame = rootPart.CFrame
		end

		task.wait()
		rootPart:PivotTo(CFrame.new(Vector3.new(pos.X, pos.Y + 4, pos.Z)))

		if FlightPos and FlightGyro then  
			FlightPos.Position = rootPart.Position
			FlightGyro.CFrame = rootPart.CFrame
		end
	elseif mode == "Walk" then
		humanoid:MoveTo(mouse.Hit.Position)
	end
end

local function rotate()
	local char, rootPart = target.Character, humanoid.RootPart
	if not rootPart then return end

	repeat
		rootPart:PivotTo(CFrame.new(rootPart.Position, Vector3.new(mouse.Hit.Position.X, rootPart.Position.Y, mouse.Hit.Position.Z)))
		task.wait()
	until not holding or not use
end

local function onEquipped(mouse)
	use = true
	mouse.Icon = "rbxasset://textures//ArrowCursor.png"
end

UserInputService.InputBegan:Connect(function(InputObject, gpe)
	if InputObject.UserInputType == Enum.UserInputType.Keyboard and not gpe then
		if InputObject.KeyCode == Enum.KeyCode.R then
			holding = true
			rotate()
		elseif InputObject.KeyCode == Enum.KeyCode.X then
			tool:Destroy()
		end
	end
end)

UserInputService.InputEnded:Connect(function(InputObject)
	if InputObject.UserInputType == Enum.UserInputType.Keyboard then
		if InputObject.KeyCode == Enum.KeyCode.R then
			holding = false
		end
	end
end)

tool.Activated:Connect(function() if use then onButton1Down(mouse) end end)
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(function() use, holding = false, false end)
humanoid.Died:Connect(function() tool:Destroy() end)
