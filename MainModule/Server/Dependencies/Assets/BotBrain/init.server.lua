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

local clone
local getPath, validTarget
local path, blockedPath = {}, {}
local current
local currentInd = 0
local lastHealth = hum.Health
local hipHeight = hum.hipHeight - (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0)
local _, pathf = pcall(function()
	return PathfindingService:CreatePath({
		AgentRadius = torso and math.max(math.max(torso.Size.X, torso.Size.Z) * 0.75, math.min(torso.Size.X, torso.Size.Z)) or 1;
		AgentHeight = hum and torso and (hipHeight + torso.Size.Y / 2) * 0.85 or 2;
		AgentCanJump = true;
		AgentCanClimb = true;
		Costs = {
			CrackedLaval = 5000;
			Water = 500;
			ForceField = 10;
			Glass = 10;
			Foil = 1.7;
			Climb = 1.5;
			Jump = 1.1;
			CorrodedMetal = 0.75;
			Sandstone = 0.6;
			CobbleStone = 0.3;
			Slate = 0.1;
		};
	})
end)
local props = {
	Target = nil;
	MainTarget = nil;
	AngerTarget = nil;
	CacheTarget = nil;
	AutoTarget = true;
	Walk = true;
	Swarm = false;
	Anger = 0;
	Damage = 5;
	Distance = 512;
	LastSearch = 0;
	TargetReset = 7;
	ScanInterval = 4;
	PatrolDist = 50;
	PatrolZone = torso.Position;
	Attack = false;
	TeamColor = nil;
	CanGiveUp = true;
	SpawnPoint = torso.CFrame;
	CanRespawn = false;
	SpecialKey = "nil";
	AttackBots = false;
	isDead = false;
	LastCompute = 0;
	ComputeReset = 20;
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

local function checkHeightNormalized(cf, dest, rad)
	local point = cf:PointToObjectSpace(dest)
	local plane, hipVector = Vector3.new(1, 0, 1), Vector3.new(1, hum.HipHeight * 1.25, 1)

	return ((point / hipVector - point * plane):Abs():Floor() * hipVector + point * plane).Magnitude < rad or (cf.Position - dest).Magnitude < rad
end

local function jumpCheck()
	local cframe = getCFrame()
	local targ = props.Target and props.Target.Parent and (props.Target:FindFirstChild("HumanoidRootPart") or props.Target:FindFirstChild("Torso") or props.Target:FindFirstChild("UpperTorso"))

	if targ and (targ.Position - cframe.Position).Magnitude < 1 then
		return --// Do something?
	else
		local checkVector = (cframe*CFrame.new(0,0,-3.5)).Position
		local rayParams = RaycastParams.new()
		rayParams.IgnoreWater = true
		rayParams.CollisionGroup = torso and torso.CollisionGroup or "Default"
		rayParams.ExcludeInstances = {char}
		local result = workspace:Raycast(cframe.Position, checkVector - cframe.Position, rayParams)
		if result then
			local hit, pos = result.Instance, result.Position
			if hit and (pos - cframe.Position).Magnitude < 0.7 then
				hum.Jump = true
			end
		end
	end
end

local function findTarget()
	local closest
	local prevDist = props.Distance
	for _, v in workspace:GetChildren() do
		local vTorso = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Torso") or v:FindFirstChild("UpperTorso")
		local human = v:FindFirstChildOfClass("Humanoid")
		if v ~= char and v:IsA("Model") and vTorso and human and human.Health > 0 then
			local dist = (torso.Position - vTorso.Position).Magnitude
			if dist < prevDist and validTarget(v) then
				prevDist = dist
				closest = v
			end
		end
	end
	return closest
end

local function rayFilter(results, isVisual)
	local obj = results.Instance

	if
		not obj.Parent or not obj.CanCollide or obj.Size.Magnitude < 1 or
		obj.Name == "Handle" or obj.Parent:IsA("Accoutrement") or obj.Parent:IsA("BackpackItem") or
		obj.Parent:FindFirstChildOfClass("Humanoid") or
		obj:IsA("WedgePart") or obj:IsA("CornerWedgePart") or
		string.sub(obj.Name, 1, 6) == "Effect" or
		isVisual and obj.Transparency <= 0.75
	then
		return true
	end

	return false
end

local function canSee(targCFrame, maxCalls, myPos, isVisual)
	maxCalls, myPos = maxCalls or math.huge, myPos or getCFrame().Position
	local calls, result = 0, nil
	local targetPos = targCFrame.Position
	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = true
	rayParams.CollisionGroup = torso and torso.CollisionGroup or "Default"
	rayParams.ExcludeInstances = {char, props.Target}
		
	while calls <= maxCalls do
		local targetVector = targetPos - myPos
		result = workspace:Raycast(myPos, targetVector, rayParams)
		local obj = result and result.Instance

		if obj then
			if rayFilter(result, isVisual) then
				local blacklist = table.clone(rayParams.ExcludeInstances)
				table.insert(blacklist, obj)
				rayParams.ExcludeInstances = blacklist
				myPos += targetVector.Unit * result.Distance * 0.75
				calls += 1

				if obj.Parent and (obj.Parent:FindFirstChildOfClass("Humanoid") or obj.Parent:IsA("Accoutrement") or obj.Parent:IsA("BackpackItem")) then
					table.insert(blacklist, obj.Parent)
				end
			else
				return false, result.Position
			end
		else
			return true, nil
		end
	end

	return false, nil
end

local function broadcastAnger(level, attacker, rad)
	for _, v in ipairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("isBot") and v ~= char then
			local isBot = v.isBot

			if not props.AttackBots or props.Swarm and isBot:IsA("ValueBase") and isBot.Value == props.SpecialKey then
				local brain = v:FindFirstChild("BotBrain")
				local event = brain and brain:FindFirstChild("Event")

				if event then
					event:Fire("Anger", {Level = level, Attacker = attacker})
				end
			end
		end
	end
end

local function onAnger(level, attacker, isPrimary)
	local doBroadcast = level * 0.75 > props.Anger or attacker and attacker ~= props.AngerTarget
	props.Anger = math.max(props.Anger, level)
	props.AngerTarget = attacker or props.AngerTarget

	if doBroadcast then
		broadcastAnger(props.Anger * 0.5, isPrimary and attacker or nil, isPrimary and props.Distance * 1.75 or props.Distance + math.random() * 0.25)
	end
end

validTarget = function(v)
	local targ = v or props.Target
	local isBot = targ:FindFirstChild("isBot")
	local isPlayer = Players:GetPlayerFromCharacter(targ)
	local canHurt = (not isBot and not isPlayer) or (isBot and props.AttackBots and (isBot.Value ~= props.SpecialKey or isBot.Value == "nil")) or (isPlayer and not (props.Friendly and (isPlayer == props.Creator or isPlayer.TeamColor == props.TeamColor)))
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
	local foundHumanoid = v:FindFirstChildOfClass("Humanoid")
	if foundHumanoid then
		tagHumanoid(foundHumanoid, hum)
		foundHumanoid:TakeDamage(props.Damage)
	end
end

local function checkPath()
	if props.AutoCompute or os.clock() - props.LastCompute > props.ComputeReset then
		getPath()
	end
end

getPath = function()
	local targetPos, targetPart
	local target = props.target and props.target.Parent and (props.Target:FindFirstChild("HumanoidRootPart") or props.Target:FindFirstChild("Torso") or props.Target:FindFirstChild("UpperTorso"))

	if target then
		targetPos, targetPart = target.CFrame, target
	elseif props.Walk then
		targetPos = CFrame.new(props.PatrolZone + Vector3.new(math.random(-props.PatrolDist, props.PatrolDist), 0, math.random(-props.PatrolDist, props.PatrolDist)))
		task.wait(math.random())
	end

	if targetPos and not props.isDead and not props.Computing then
		if canSee(targetPos, 32) then
			props.AutoCompute = true
			path = {{Position = getCFrame().Position}, {Position = targetPos.Position, Action = Enum.PathWaypointAction.Custom, Label = "_targetObj"}, Parts = {_targetObj = targetPart}}
			props.LastCompute = os.clock()
			current = nil
			currentInd = 2
		else
			local mustCompute = props.AutoCompute
			props.Computing = true
			props.AutoCompute = false

			local success, err = pcall(function()
				pathf:ComputeAsync(
					getCFrame().Position,
					targetPos.Position
				)
			end)

			if not success or pathf.Status ~= Enum.PathStatus.Success then
				if err then
					warn("Failed to compute path due to:", err)
				end

				if mustCompute then
					local pos = getCFrame().Position
					local offset = (targetPos.Position - pos).Unit
					path, blockedPath = {{Position = pos}, Parts = {_targetObj = targetPart}}, {}

					for i = 1, 20 do -- Fill waypoints with auxiliary positions
						local newPos = pos + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)) + offset * 5
						local _, hit = canSee(CFrame.new(newPos), 16, pos)
						pos = hit and pos:Lerp(hit, 0.9) or newPos
						table.insert(path, {Position = pos})
					end

					table.insert(path, {Position = targetPos.Position, Action = Enum.PathWaypointAction.Custom, Label = "_targetObj"})
					props.LastCompute = os.clock()
					current = nil
					currentInd = 2
				end

				props.Computing = false
				return
			end

			path, blockedPath = {}, {}
			path = pathf:GetWaypoints()
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
		current = coord.Position
		currentInd += 1

		if hum ~= nil and hum:IsA("Humanoid") then
			hum:MoveTo(current, path.Parts and path.Parts[coord.Label] or nil)

			jumpCheck()
			if coord.Action and coord.Action.Name == "Jump" or current.Y - getCFrame().Position.Y > 2.5 then
				hum.Jump = true
			elseif current.Y - getCFrame().Position.Y < -2.5 then
				hum:MoveTo(current + Vector3.new(2, 0, 2))
			end

			if #path > 2 then
				local attempt, target = false, os.clock() + (getCFrame().Position - current).Magnitude / hum.WalkSpeed * 2

				repeat
					if attempt then
						hum:MoveTo(current, path.Parts and path.Parts[coord.Label] or nil)
						hum.Jump = true
					end
					hum.MoveToFinished:Wait()
					attempt = true
				until path[currentInd] ~= coord or checkHeightNormalized(getCFrame(), current, 2.5) or os.clock() < target
			end
		end

		if currentInd == #path then
			props.AutoCompute = true
		end
	else
		props.AutoCompute = true
		print("Coordinates didn't exist. Requiring recomputation")
	end
end

local function onDamage()
	if hum.Health < lastHealth then
		local creator = hum:FindFirstChild("creator")

		if creator and creator:IsA("ObjectValue") and creator.Value and creator.Value.Parent then
			local newTarget = creator.Value:IsA("Player") and creator.Value.Character:FindFirstChildOfClass("Humanoid") or creator.Value:IsA("Humanoid") and creator.Value
			props.MainTarget = newTarget.Parent
			onAnger(math.max(props.Anger, 10) + 50 + math.ceil((lastHealth - hum.Health) / hum.MaxHealth * 200), newTarget.Parent, true)
		elseif math.random() < (lastHealth - hum.Health) / hum.MaxHealth * 0.5 then
			onAnger(math.max(props.Anger, 10) + 10 + math.ceil((lastHealth - hum.Health) / hum.MaxHealth * 50), nil, true)
		end
	end

	lastHealth = hum.Health
end

local function updateBot()
	local targ = props.MainTarget or props.Anger > 0 and props.AngerTarget or props.Attack and (os.clock() < props.LastSearch + props.TargetReset and props.CachedTarget or os.clock() > props.LastSearch + props.ScanInterval and findTarget())

	if targ ~= props.Target then
		props.AutoCompute = true
	end

	if targ then
		local targHum = targ:FindFirstChildOfClass("Humanoid")

		if not targ.Parent or not targHum or targHum.Health <= 0 then
			targ = nil
			props.MainTarget, props.AngerTarget, props.CachedTarget, props.Target = nil, nil, nil, nil
		end
	end

	props.Target = targ
	checkPath()
	walkPath()
	props.Anger -= 1

	if props.Anger > 0 and math.random() < math.clamp(props.Anger / 1000, 0, 0.75) / 60 then
		broadcastAnger(props.Anger * 0.3, nil, props.Distance * 0.75 + math.random() * 0.25)
	end
end

local function respawn()
	props.isDead = true

	if props.RespawnTime == false then
		return
	elseif props.CanRespawn and clone then
		task.wait(props.RespawnTime or Players.RespawnTime)
		clone.Parent = workspace

		if props.SpawnPoint then
			clone:PivotTo(props.SpawnPoint)
		end

		local event = clone:FindFirstChild("BotBrain") and clone.BotBrain:FindFirstChild("Event")

		if event then
			task.defer(event.Fire, event, "SetSetting", props)
			task.defer(task.defer, event.Fire, event, "Init")
		end
		task.delay(0.1, char.Destroy, char)
	else
		Debris:AddItem(char, props.RespawnTime or 1)
	end
end

local function init()
	local str = Instance.new("StringValue")
	str.Name = "isBot"
	str.Value = props.SpecialKey
	str.Parent = char

	if props.CanRespawn then
		if clone then
			clone:Destroy()
		end

		local oldArchivable = char.Archivable
		char.Archivable = true
		clone = char:Clone()
		char.Archivable = oldArchivable
	end

	hum.Died:Connect(respawn)
	hum.HealthChanged:Connect(onDamage)
	local took = 0

	while task.wait(not props.Targ and 1/30 or nil) and not props.isDead do
		if char and hum and not props.isDead then
			updateBot()
		else
			respawn()
			break
		end
	end
end

local function doToucher(part)
	part.Touched:Connect(function(hit)
		if hit and hit:IsA("BasePart") and hit.Parent and hit.Parent == props.Target and not props.isDead then
			doAttack(hit.Parent)
		end
	end)
end

doToucher(torso)
doToucher(head)
doToucher(lleg)
doToucher(rleg)

event.Event:Connect(function(command, data)
	if command == "SetSetting" then
		for k, v in data do
			props[k] = v
		end
	elseif command == "Anger" then
		onAnger(data.Level, data.Attacker)
	elseif command == "Init" then
		init()
	end
end)

if pathf and pathf.Blocked and pathf.Unblocked then
	pathf.Blocked:Connect(function(i)
		if i >= currentInd and path[i] then
			blockedPath[i], path[i] = path[i], nil
		end
	end)

	pathf.Unblocked:Connect(function(i)
		if i >= currentInd and blockedPath[i] then
			path[i], blockedPath[i] = blockedPath[i], nil
		end
	end)
end
