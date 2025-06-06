local char = script.Parent
local event = script.Event

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
local head = char:FindFirstChild("Head")
local torso = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
local larm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftLowerArm")
local rarm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm")
local lleg = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftLowerLeg")
local rleg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLowerLeg")

local getPath, validTarget
local path = {}
local current
local currentInd = 0

local props = {
	Target = nil;
	AutoTarget = true;
	Swarm = false;
	Damage = 5;
	Distance = 50;
	PatrolDist = 50;
	PatrolZone = torso.Position;
	Attack = false;
	TeamColor = nil;
	CanGiveUp = true;
	SpawnPoint = torso.CFrame;
	CanRespawn = false;
	SpecialKey = "null";
	AttackBots = false;
	isDead = false;
	LastCompute = os.clock();
}

local function tagHumanoid(humanoid, attacker)
	local creatorTag = Instance.new("ObjectValue")
	creatorTag.Name = "creator"
	creatorTag.Value = attacker
	Debris:AddItem(creatorTag, 2)
	creatorTag.Parent = humanoid
end

local function setProp(prop, value)
	if props[prop] then
		props[prop] = value
	end
end

local function getCFrame()
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if humanoidRootPart ~= nil and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart.CFrame
	else
		return CFrame.new()
	end
end

local function jumpCheck()
	local cframe = getCFrame()
	local targ = props.Target and props.Target.Parent and (props.Target:FindFirstChild("HumanoidRootPart") or props.Target:FindFirstChild("Torso") or props.Target:FindFirstChild("UpperTorso"))

	if targ and (targ.Position - cframe.Position).Magnitude < 1 then
		return --// Do something?
	else
		local checkVector = (cframe*CFrame.new(0,0,-3.5)).Position
		local result = workspace:Raycast(cframe.Position, (checkVector - cframe.Position).Unit)
		if result then
			local hit, pos = result.Instance, result.Position
			if hit and (pos-cframe.Position).Magnitude < 0.7 then
				hum.Jump = true
			end
		end
	end
end

local function findTarget()
	local closest
	local prevDist = props.Distance
	for i,v in workspace:GetChildren() do
		local vTorso = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v:FindFirstChild("UpperTorso")
		local human = v:FindFirstChildOfClass("Humanoid")
		if v~=char and v:IsA("Model") and torso and vTorso and human and human.Health>0 then
			local dist = (torso.Position-vTorso.Position).Magnitude
			if dist < prevDist and validTarget(v) then
				prevDist = dist
				closest = v
			end
		end
	end
	return closest
end

local function canSee(targCFrame)
	local myPos = getCFrame().Position
	local targetPos = targCFrame.Position

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {char, props.Target}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(myPos, (targetPos - myPos).Unit, rayParams)

	if result and result.Instance then
		return false
	else
		return true
	end
end

validTarget = function(v)
	local targ = v or props.Target
	local isBot = targ:FindFirstChild("isBot")
	local isPlayer = Players:GetPlayerFromCharacter(targ)
	local canHurt = (not isBot and not isPlayer) or (isBot and props.AttackBots and (isBot.Value ~= props.SpecialKey or isBot.Value == "null")) or (isPlayer and not (props.Friendly and (isPlayer == props.Creator or isPlayer.TeamColor == props.TeamColor)))
	if targ and targ ~= char and canHurt then
		local targetHumanoid = targ:FindFirstChildOfClass("Humanoid")
		if targetHumanoid ~= nil and targetHumanoid.Health < math.huge and (targ:FindFirstChild("HumanoidRootPart") or targ:FindFirstChild("Torso") or targ:FindFirstChild("UpperTorso")) then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function doAttack(v)
	if props.Attack and not props.isDead and v == props.Target then
		local foundHumanoid = v:FindFirstChildOfClass("Humanoid")
		if foundHumanoid and validTarget(v) then
			tagHumanoid(foundHumanoid, hum)
			foundHumanoid:TakeDamage(props.Damage)
		end
	end
end

local function checkPath()
	if props.AutoCompute or os.clock() - props.LastCompute > 1 then
		getPath()
	end
end

getPath = function()
	local targetPos

	if props.Target and props.Target.Parent then
		local target = props.Target:FindFirstChild("HumanoidRootPart") or props.Target:FindFirstChild("Torso") or props.Target:FindFirstChild("UpperTorso")
		if target then
			targetPos = target.CFrame
		else
			targetPos = CFrame.new(props.PatrolZone + Vector3.new(math.random(-props.PatrolDist, props.PatrolDist),0,math.random(-props.PatrolDist, props.PatrolDist)))
			task.wait(math.random())
		end
	else
		targetPos = CFrame.new(props.PatrolZone+Vector3.new(math.random(-props.PatrolDist, props.PatrolDist),0,math.random(-props.PatrolDist, props.PatrolDist)))
		task.wait(math.random())
	end

	if not props.isDead and not props.Computing then
		if canSee(targetPos) then
			props.AutoCompute = true
			path = {getCFrame(), targetPos.Position}
			props.LastCompute = os.clock()
			current = nil
			currentInd = 2
		else
			props.Computing = true
			props.AutoCompute = false

			local pathf = PathfindingService:ComputeSmoothPathAsync(
				getCFrame().Position,
				targetPos.Position,
				500
			)

			path = {}
			path = pathf:GetPointCoordinates()
			props.LastCompute = os.clock()
			props.Computing = false
			current = nil
			currentInd = 2
		end
	end
end

local function walkPath()
	local myPos = getCFrame().Position

	local coord = path[currentInd]
	if coord then
		current = coord
		currentInd = currentInd+1

		if hum ~= nil and hum:IsA("Humanoid") then
			hum:MoveTo(current)

			jumpCheck()
			if (current.Y - getCFrame().Position.Y) > 2.5 then
				hum.Jump = true
			elseif (current.Y - getCFrame().Position.Y) < -2.5 then
				hum:MoveTo(current+Vector3.new(2,0,2))
			end

			if #path > 2 then
				repeat task.wait(0.1) until path[currentInd] ~= coord or (getCFrame().Position - coord).Magnitude < 2.5
			end
		end

		if currentInd == #path then
			props.AutoCompute = true
		end
	end
end

local function updateBot()
	local targ = findTarget()
	if targ and props.Swarm then
		props.Target = targ
	else
		props.Target = nil
	end
	checkPath()
	walkPath()
	task.wait(1/30)
end

local function init()
	local str = Instance.new("StringValue")
	str.Name = "isBot"
	str.Value = props.SpecialKey
	str.Parent = char

	hum.Died:Connect(function()
		Debris:AddItem(char, 1)
		props.isDead = true
	end)

	while task.wait(1/30) and not props.isDead do
		if char and hum and not props.isDead then
			updateBot()
		else
			props.isDead = true
			Debris:AddItem(char, 1)
			break
		end
	end
end

local function doToucher(part)
	part.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") and hit.Parent and hit.Parent:IsA("Model") and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent ~= script.Parent then
			doAttack(hit.Parent)
		end
	end)
end

doToucher(torso)
doToucher(head)
doToucher(lleg)
doToucher(rleg)

event.Event:Connect(function(command,data)
	if command == "SetSetting" then
		for k, v in data do
			props[k] = v
		end
	elseif command == "Init" then
		init()
	end
end)
