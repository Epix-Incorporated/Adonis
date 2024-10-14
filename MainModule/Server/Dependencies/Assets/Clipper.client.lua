local Humanoid: Humanoid = script.Parent
local Character = Humanoid.Parent

local R6 = {
	"Torso",
	"HumanoidRootPart",
	"Head"
}

local R15 = {
	"HumanoidRootPart",
	"LowerTorso",
	"UpperTorso"
}

game:GetService("RunService").Stepped:Connect(function()
	if script.Clip.Value then
		for _, Object in pairs(Character:GetDescendants()) do
			if Object:IsA("BasePart") and Object.CanCollide then
				Object.CanCollide = false
			end
		end

		Humanoid:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics) -- Enum.HumanoidStateType.StrafingNoPhysics (semi-depricated but still working and fixes the colliding if in water).
	else
		if Humanoid.RigType == Enum.HumanoidRigType.R6 then
			for _, Object in pairs(Character:GetDescendants()) do
				if table.find(R6,Object.Name) and Object:IsA("BasePart") then
					Object.CanCollide = true
				end
			end
		elseif Humanoid.RigType == Enum.HumanoidRigType.R15 then
			for _, Object in pairs(Character:GetDescendants()) do
				if table.find(R15,Object.Name) and Object:IsA("BasePart") then
					Object.CanCollide = true
				end
			end
		end
		
		Humanoid:ChangeState(Enum.HumanoidStateType.None) -- Enum.HumanoidStateType.None (Allows roblox to set set a state that isn't Enum.HumanoidStateType.StrafingNoPhysics)
		
		script:Destroy()
	end
end)
