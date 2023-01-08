local hum = script.Parent
local char = hum.Parent
local torso = char:FindFirstChild("HumanoidRootPart")
local origY = torso.Position.Y
game:GetService("RunService").Stepped:Connect(function()
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
		end
	end
	local cf = torso.CFrame
	torso.CFrame = (cf - cf.Position) + Vector3.new(cf.X, origY, cf.Z)
	hum:ChangeState(11)
end)
