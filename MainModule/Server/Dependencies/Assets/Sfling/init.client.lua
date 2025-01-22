task.wait()
local cam = workspace.CurrentCamera
local torso = script.Parent
local humanoid = torso.Parent:FindFirstChildOfClass("Humanoid")
local strength = script:WaitForChild("Strength").Value

for i = 1, 100 do
	task.wait(0.1)
	humanoid.Sit = true
	local ex = Instance.new("Explosion")
	ex.Position = torso.Position + Vector3.new(math.random(-5, 5), -10, math.random(-5, 5))
	ex.BlastRadius = 35
	ex.BlastPressure = strength
	ex.ExplosionType = Enum.ExplosionType.NoCraters--Enum.ExplosionType.Craters
	ex.DestroyJointRadiusPercent = 0
	ex.Archivable = false
	ex.Parent = cam
end
script:Destroy()
