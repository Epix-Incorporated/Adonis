local Humanoid = script.Parent
local Character = Humanoid.Parent

game:GetService("RunService").Stepped:Connect(function()
	for _, Object in pairs(Character:GetDescendants()) do
		if Object:IsA("BasePart") and Object.CanCollide then
			Object.CanCollide = false
		end
	end
	Humanoid:ChangeState(11)	--| Enum.HumanoidStateType.StrafingNoPhysics (semi-depricated but still working and fixes the colliding if in water).
end)
