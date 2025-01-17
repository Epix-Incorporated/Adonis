task.wait()
local torso = script.Parent
local posed = false
local type = script:WaitForChild("Type").Value
local int = tonumber(script:WaitForChild("Num").Value) or 50

game:GetService("RunService").RenderStepped:Connect(function()
	if type == "ghost" then
		torso.CFrame += Vector3.new(tonumber(int) * (posed and 4 or -2), 0, 0)
	elseif type == "trippy" then
		torso.CFrame *= CFrame.new(tonumber(int) * (posed and 4 or -2), 0, 0)
	elseif type == "vibrate" then
		local num = math.random(1,4)

		if num == 1 then
			torso.CFrame *= CFrame.new(tonumber(int) * 2, 0, 0)
		elseif num == 2 then
			torso.CFrame *= CFrame.new(-tonumber(int) * 2, 0, 0)
		elseif num == 3 then
			torso.CFrame *= CFrame.new(0, 0, -tonumber(int) * 2)
		elseif num == 4 then
			torso.CFrame *= CFrame.new(0 ,0, tonumber(int) * 2)
		end
	end
	posed = not posed
end)
