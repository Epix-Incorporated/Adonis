local root = script.Parent
local humanoid = script.Parent.Parent:FindFirstChildOfClass("Humanoid")
local origvel = root.AssemblyLinearVelocity
local origrot = root.AssemblyAngularVelocity

repeat
	task.wait(0.1)
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), -5, math.random(-10, 10))
	root.AssemblyAngularVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
until not root or not humanoid

humanoid.PlatformStand = false
root.AssemblyLinearVelocity = origvel
root.AssemblyAngularVelocity = origrot
