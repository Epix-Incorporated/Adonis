local RunService = game:GetService("RunService")

local LIMB_NAMES = {
	R6 = {
		"CollisionPart",

		"Torso",
		"HumanoidRootPart",
		"Head"
	},
	R15 = {
		"CollisionPart",

		"HumanoidRootPart",
		"LowerTorso",
		"UpperTorso"
	}
}

local humanoid: Humanoid = script.Parent
local character = humanoid.Parent
local wasInside = false
local ignoreParams = OverlapParams.new()

ignoreParams.FilterDescendantsInstances = {character, humanoid}
ignoreParams.FilterType = Enum.RaycastFilterType.Exclude
ignoreParams.MaxParts = 1
ignoreParams.CollisionGroup = humanoid.RootPart and humanoid.RootPart.CollisionGroup or "Default"
ignoreParams.RespectCanCollide = true

local function isInsideTerrain(position)
	return workspace.Terrain:ReadVoxelChannels(Region3.new(position, position + Vector3.one):ExpandToGrid(4), 4, {"SolidOccupancy"}).SolidOccupancy[1][1][1] > 0
end

RunService.PreSimulation:Connect(function()
	if script.Clip.Value then
		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") and object.CanCollide then
				object.CanCollide = false
			end
		end

		local rootPart = humanoid.RootPart
		local velocity = rootPart and rootPart.AssemblyLinearVelocity

		if velocity and velocity.Y <= 0 and (#workspace:GetPartsInPart(rootPart, ignoreParams) > 0 or isInsideTerrain(rootPart.Position - Vector3.new(0, humanoid.HipHeight, 0))) then
			wasInside = true
			rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, math.clamp(velocity.Y, 0, math.huge), velocity.Z)
			--humanoid:ChangeState(Enum.HumanoidStateType.StrafingNoPhysics) -- Enum.HumanoidStateType.StrafingNoPhysics (semi-depricated but still working and fixes the colliding if in water).

			if humanoid.Jump then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		elseif wasInside then
			wasInside = false
			humanoid:ChangeState(Enum.HumanoidStateType.None)
		end
	else
		for _, object in ipairs(character:GetDescendants()) do
			if table.find(LIMB_NAMES[humanoid.RigType.Name] or {}, object.Name) and object:IsA("BasePart") then
				object.CanCollide = true
			end
		end

		humanoid:ChangeState(Enum.HumanoidStateType.None) -- Enum.HumanoidStateType.None (Allows roblox to set set a state that isn't Enum.HumanoidStateType.StrafingNoPhysics)
		script:Destroy()
	end
end)
