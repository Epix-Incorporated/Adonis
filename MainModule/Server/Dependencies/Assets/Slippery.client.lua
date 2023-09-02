task.wait(0.5)
local vel = script.Parent:WaitForChild("ADONIS_IceVelocity")

while script.Parent ~= nil and vel and vel.Parent  ~= nil do 
	vel.Velocity = Vector3.new(script.Parent.AssemblyLinearVelocity.X, 0, script.Parent.AssemblyLinearVelocity.Z)
	task.wait(0.1)
end

if vel then vel:Destroy() end
