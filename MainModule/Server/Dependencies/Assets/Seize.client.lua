local char = script.Parent.Parent
local torso = script.Parent
local hum = char.Humanoid
local origvel = torso.Velocity
local origrot = torso.RotVelocity

repeat
	task.wait(0.1)
	hum.PlatformStand = true
	torso.Velocity = Vector3.new(math.random(-10, 10), -5, math.random(-10, 10))
	torso.RotVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
until not torso or not hum

hum.PlatformStand = false
torso.Velocity = origvel
torso.RotVelocity = origrot
