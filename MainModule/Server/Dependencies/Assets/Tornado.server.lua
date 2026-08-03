local Pcall = function(func,...) 
	local function cour(...)
		coroutine.resume(coroutine.create(func),...)
	end 
	local ran,error = pcall(cour,...) 
	if error then 
		print('Error: '..error) 
	end 
end

local parts = {}
local main = script.Parent

main.Anchored = true
main.CanCollide = false
main.Transparency = 1

local smoke = Instance.new("Smoke")
local sound = Instance.new("Sound")

smoke.Parent = main
sound.Parent = main

smoke.RiseVelocity = 25
smoke.Size = 25
smoke.Color = Color3.new(170/255, 85/255, 0)
smoke.Opacity = 1

sound.SoundId = "rbxassetid://134811453767381"
sound.Looped = true
sound:Play()
sound.Volume = 0.8
sound.PlaybackSpeed = 0.8


function fling(part)
	part:BreakJoints()
	part.Anchored = false
	local attachment = Instance.new("Attachment")
	local pos=Instance.new("AlignPosition")

	attachment.Parent = part
	pos.Parent = part

	pos.MaxForce = math.huge
	pos.Position = part.Position
	pos.Attachment0 = attachment
	local i = 1
	local run = true
	while main and task.wait() and run do
		if part.Position.Y>=main.Position.Y+50 then
			run=false
		end
		pos.Position = Vector3.new(50*math.cos(i), part.Position.Y+5, 50*math.sin(i)) + main.Position
		i = i + 1
	end
	pos.MaxForce = 500
	pos.Position = Vector3.new(main.Position.X+math.random(-100, 100), main.Position.Y+100, main.Position.Z+math.random(-100, 100))
	pos:Destroy()
end
function get(obj)
	if obj ~= main and obj:IsA("Part") then
		table.insert(parts, 1, obj)
	elseif obj:IsA("Model") or obj:IsA("Accoutrement") or obj:IsA("Tool") or obj == workspace then
		for i, v in obj:GetChildren() do
			Pcall(get, v)
		end
		obj.ChildAdded:Connect(function(p)Pcall(get, p)end)
	end
end
get(workspace)
repeat
	for i, v in parts do
		if v and v:IsDescendantOf(workspace) and (((main.Position - v.Position).Magnitude * 250 * 20) < (5000 * 40)) then
			task.spawn(fling, v)
		elseif not v or not v:IsDescendantOf(workspace) then
			table.remove(parts, i)
		end
	end
	main.CFrame = main.CFrame + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
	task.wait()
until main.Parent ~= workspace or not main