local hum = script.Parent
local torso = hum.Parent:FindFirstChild("HumanoidRootPart")
local origY = torso.Position.Y
local event = game:service("RunService").RenderStepped:connect(function()
	torso.CFrame = CFrame.new(torso.CFrame.X,origY,torso.CFrame.Z)
	hum:ChangeState(11)
end)