task.wait()
local torso = script.Parent
local posed = false
local type = script:WaitForChild("Type").Value
local int = script:WaitForChild("Num").Value

game:GetService("RunService").RenderStepped:Connect(function()
	if posed then
		if type == "ghost" then
			torso.CFrame = torso.CFrame + Vector3.new(((tonumber(int) or 100) * 2), 0, 0)
		elseif type == "trippy" then
			torso.CFrame = torso.CFrame * CFrame.new(((tonumber(int) or 100) * 2), 0, 0)
		elseif type == "vibrate" then
			local num = math.random(1, 4)
			if num == 1 then
				torso.CFrame = torso.CFrame * CFrame.new(((tonumber(int) * 2) or 100), 0, 0)
			elseif num == 2 then
				torso.CFrame = torso.CFrame * CFrame.new(-((tonumber(int) * 2) or 100), 0, 0)
			elseif num == 3 then
				torso.CFrame = torso.CFrame * CFrame.new(0, 0, -((tonumber(int) * 2) or 100))
			elseif num == 4 then
				torso.CFrame=torso.CFrame * CFrame.new(0, 0, ((tonumber(int) * 2) or 100))
			end
		end
		posed = false
	else
		if type == "ghost" then
			torso.CFrame = torso.CFrame + Vector3.new(-((tonumber(int) * 2) or 100), 0, 0)
		elseif type == "trippy" then
			torso.CFrame = torso.CFrame * CFrame.new(-((tonumber(int) * 2) or 100), 0, 0)
		elseif type == "vibrate" then
			local num = math.random(1, 4)
			if num == 1 then
				torso.CFrame = torso.CFrame * CFrame.new(((tonumber(int) * 2) or 100), 0, 0)
			elseif num == 2 then
				torso.CFrame = torso.CFrame * CFrame.new(-((tonumber(int) * 2) or 100), 0, 0)
			elseif num == 3 then
				torso.CFrame = torso.CFrame * CFrame.new(0, 0, -((tonumber(int) * 2) or 100))
			elseif num == 4 then
				torso.CFrame = torso.CFrame * CFrame.new(0, 0, ((tonumber(int) * 2) or 100))
			end
		end
		posed = true
	end
end)
