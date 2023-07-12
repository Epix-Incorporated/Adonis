local Character = script.Parent

game:GetService("RunService").Stepped:Connect(function()
	for _, Object in pairs(script.Parent:GetDescendants()) do
		if Object:IsA("BasePart") and Object.CanCollide then
			Object.CanCollide = false
		end
	end
	
	Character.Humanoid:ChangeState(11)								--| Enum.HumanoidStateType.StrafingNoPhysics (semi-depricated but still working and fixes the colliding if in water).
end)
