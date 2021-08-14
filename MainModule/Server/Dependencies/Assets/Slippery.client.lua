task.wait(0.5)
local vel = script.Parent.ADONIS_IceVelocity
while true do 
	if script.Parent == nil or vel.Parent == nil then break end
	vel.velocity = Vector3.new(script.Parent.Velocity.X,0,script.Parent.Velocity.Z)
	task.wait(0.1)
end

if vel then vel:Destroy() end