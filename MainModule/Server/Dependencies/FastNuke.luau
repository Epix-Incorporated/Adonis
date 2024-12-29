--[[
	Author: github@ccuser44/ALE111_boiPNG
	Name: Fast nuke script
	Description: This script allows you to create a nuclear explosion
	License: MIT
	Source: github/ccuser44/Fast-nuclear-explosion
]]
--[[
	MIT License

	Copyright (c) 2023 ccuser44

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- // Constants

local CLOUD_RING_MESH_ID = "http://www.roblox.com/asset/?id=3270017"
local CLOUD_SPHERE_MESH_ID = "http://www.roblox.com/asset/?id=1185246"
local CLOUD_MESH_ID = "http://www.roblox.com/asset/?id=1095708"
local CLOUD_COLOR_TEXTURE = "http://www.roblox.com/asset/?ID=1361097"

-- // Variables

local basePart = Instance.new("Part")
basePart.Anchored = true
basePart.Locked = true
basePart.CanCollide = false
basePart.CanQuery = false
basePart.CanTouch = false
basePart.TopSurface = Enum.SurfaceType.Smooth
basePart.BottomSurface = Enum.SurfaceType.Smooth
basePart.Size = Vector3.new(1, 1, 1)

local baseMesh = Instance.new("SpecialMesh")
baseMesh.MeshType = Enum.MeshType.FileMesh

local sphereMesh, ringMesh = baseMesh:Clone(), baseMesh:Clone()
sphereMesh.MeshId = CLOUD_SPHERE_MESH_ID
ringMesh.MeshId = CLOUD_RING_MESH_ID

local cloudMesh = baseMesh:Clone()
cloudMesh.MeshId, cloudMesh.TextureId = CLOUD_MESH_ID, CLOUD_COLOR_TEXTURE
cloudMesh.VertexColor = Vector3.new(0.9, 0.6, 0)

local skybox = Instance.new("Sky")
skybox.SkyboxFt, skybox.SkyboxBk = "http://www.roblox.com/asset/?version=1&id=1012887", "http://www.roblox.com/asset/?version=1&id=1012890"
skybox.SkyboxLf, skybox.SkyboxRt = "http://www.roblox.com/asset/?version=1&id=1012889", "http://www.roblox.com/asset/?version=1&id=1012888"
skybox.SkyboxDn, skybox.SkyboxUp = "http://www.roblox.com/asset/?version=1&id=1012891", "http://www.roblox.com/asset/?version=1&id=1014449"

local nukeSkyboxes, realSkyboxes = setmetatable({}, {__mode = "v"}), setmetatable({}, {__mode = "v"})
local nukeIgnore = setmetatable({}, {__mode = "v"})
local explosionParams = OverlapParams.new()
explosionParams.FilterDescendantsInstances = nukeIgnore
explosionParams.FilterType = Enum.RaycastFilterType.Exclude
explosionParams.RespectCanCollide = true

-- // Functions

local function basicTween(instance, properties, duration)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.In,
			0,
			false,
			0
		),
		properties
	)

	tween:Play()

	if tween.PlaybackState == Enum.PlaybackState.Playing or tween.PlaybackState == Enum.PlaybackState.Begin then
		tween.Completed:Wait()
	end
end

local function createMushroomCloud(position, container, clouds, shockwave)
	local baseCloud = basePart:Clone()
	baseCloud.Position = position

	local poleBase = basePart:Clone()
	poleBase.Position = position + Vector3.new(0, 0.1, 0)

	local cloud1 = basePart:Clone()
	cloud1.Position = position + Vector3.new(0, 0.75, 0)

	local cloud2 = basePart:Clone()
	cloud2.Position = position + Vector3.new(0, 1.25, 0)

	local cloud3 = basePart:Clone()
	cloud3.Position = position + Vector3.new(0, 1.7, 0)

	local poleRing = basePart:Clone()
	poleRing.Position = position+Vector3.new(0, 1.3, 0)
	poleRing.Transparency = 0.2
	poleRing.BrickColor = BrickColor.new("Dark stone grey")
	poleRing.CFrame = poleRing.CFrame * CFrame.Angles(math.rad(90), 0, 0)

	local mushCloud = basePart:Clone()
	mushCloud.Position = position+Vector3.new(0, 2.3, 0)

	local topCloud = basePart:Clone()
	topCloud.Position = position+Vector3.new(0, 2.7, 0)

	do
		local baseCloudMesh = cloudMesh:Clone()
		baseCloudMesh.Parent = baseCloud 
		baseCloudMesh.Scale = Vector3.new(2.5, 1, 4.5)

		local poleBaseMesh = cloudMesh:Clone()
		poleBaseMesh.Scale = Vector3.new(1.25, 2, 2.5)
		poleBaseMesh.Parent = poleBase

		local cloud1Mesh = cloudMesh:Clone()
		cloud1Mesh.Scale = Vector3.new(0.5, 3, 1)
		cloud1Mesh.Parent = cloud1

		local cloud2Mesh = cloudMesh:Clone()
		cloud2Mesh.Scale = Vector3.new(0.5, 1.5, 1)
		cloud2Mesh.Parent = cloud2

		local cloud3Mesh = cloudMesh:Clone()
		cloud3Mesh.Scale = Vector3.new(0.5, 1.5, 1)
		cloud3Mesh.Parent = cloud3

		local poleRingMesh = ringMesh:Clone()
		poleRingMesh.Scale = Vector3.new(1.2, 1.2, 1.2)
		poleRingMesh.Parent = poleRing

		local topCloudMesh = cloudMesh:Clone()
		topCloudMesh.Scale = Vector3.new(7.5, 1.5, 1.5)
		topCloudMesh.Parent = topCloud

		local mushCloudMesh = cloudMesh:Clone()
		mushCloudMesh.Scale = Vector3.new(2.5, 1.75, 3.5)
		mushCloudMesh.Parent = mushCloud
	end

	table.insert(clouds, baseCloud)
	table.insert(clouds, topCloud)
	table.insert(clouds, mushCloud)
	table.insert(clouds, cloud1)
	table.insert(clouds, cloud2)
	table.insert(clouds, cloud3)
	table.insert(clouds, poleBase)
	table.insert(clouds, poleRing)

	local bigRing = basePart:Clone()
	bigRing.Position = position
	bigRing.CFrame = bigRing.CFrame * CFrame.Angles(math.rad(90), 0, 0)

	local smallRing = basePart:Clone()
	smallRing.Position = position
	smallRing.BrickColor = BrickColor.new("Dark stone grey")
	smallRing.CFrame = smallRing.CFrame * CFrame.Angles(math.rad(90), 0, 0)

	local innerSphere = basePart:Clone()
	innerSphere.Position = position
	innerSphere.BrickColor = BrickColor.new("Bright orange")
	innerSphere.Transparency = 0.5

	local outterSphere = basePart:Clone()
	outterSphere.Position = position
	outterSphere.BrickColor = BrickColor.new("Bright orange")
	outterSphere.Transparency = 0.5

	do
		local bigMesh = ringMesh:Clone()
		bigMesh.Scale = Vector3.new(5, 5, 1)
		bigMesh.Parent = bigRing

		local smallMesh = ringMesh:Clone()
		smallMesh.Scale = Vector3.new(4.6, 4.6, 1.5)
		smallMesh.Parent = smallRing

		local innerSphereMesh = sphereMesh:Clone()	
		innerSphereMesh.Scale = Vector3.new(-6.5, -6.5, -6.5)
		innerSphereMesh.Parent = innerSphere
	
		local outterSphereMesh = sphereMesh:Clone()
		outterSphereMesh.Scale = Vector3.new(6.5, 6.5, 6.5)
		outterSphereMesh.Parent = outterSphere
	end

	table.insert(shockwave, bigRing)	
	table.insert(shockwave, smallRing)
	table.insert(shockwave, outterSphere)
	table.insert(shockwave, innerSphere)

	for _, v in ipairs(shockwave) do
		v.Parent = container
	end
	for _, v in ipairs(clouds) do
		v.Parent = container
	end

	return {
		OutterSphere = outterSphere,
		InnerSphere = innerSphere,
		BigRing = bigRing,
		SmallRing = smallRing,
		BaseCloud = baseCloud,
		PoleBase = poleBase,
		PoleRing = poleRing,
		Cloud1 = cloud1,
		Cloud2 = cloud2,
		Cloud3 = cloud3,
		MushCloud = mushCloud,
		TopCloud = topCloud
	}
end

local function effects(nolighting)
	for i = 1, 2 do
		local explosionSound = Instance.new("Sound")
		explosionSound.Name = "NUKE_SOUND"
		explosionSound.SoundId = "http://www.roblox.com/asset?id=130768997"
		explosionSound.Volume = 0.5
		explosionSound.PlaybackSpeed = i / 2
		explosionSound.RollOffMinDistance, explosionSound.RollOffMaxDistance = 0, 10000
		explosionSound.Archivable = false
		explosionSound.Parent = SoundService
		explosionSound:Play()
		Debris:AddItem(explosionSound, 30)
	end

	if not nolighting then
		local oldBrightness = Lighting.Brightness
		Lighting.Brightness = 5

		basicTween(Lighting, {Brightness = 1}, 4 / 0.01 * (1 / 60))
		Lighting.Brightness = oldBrightness
	end
end

local function tagHumanoid(humanoid, attacker)
	local creatorTag = Instance.new("ObjectValue")
	creatorTag.Name = "creator"
	creatorTag.Value = attacker
	Debris:AddItem(creatorTag, 2)
	creatorTag.Parent = humanoid
end

local function destruction(position, radius, attacker)
	for _, v in ipairs(workspace:GetPartBoundsInRadius(position, radius, explosionParams)) do
		if v.ClassName ~= "Terrain" and v.Anchored == false then
			if attacker then
				local humanoid = v.Parent:FindFirstChildOfClass("Humanoid")

				if humanoid and not humanoid:FindFirstChild("creator") then
					tagHumanoid(humanoid, attacker)
				end
			end

			v:BreakJoints()
			v.Material = Enum.Material.CorrodedMetal
			v.AssemblyLinearVelocity = CFrame.new(v.Position, position):VectorToWorldSpace(Vector3.new(math.random(-5, 5), 5, 1000))
		end
	end
end

local function explode(position: Vector3, explosionSize: number, nolighting: boolean?, attacker: (Player | Humanoid)?)
	-- // Setup
	local shockwaveCompleted = false
	explosionParams.FilterDescendantsInstances = nukeIgnore
	local clouds, shockwave = {}, {}
	local container = Instance.new("Model")
	container.Name = "ADONIS_NUCLEAREXPLOSION"
	container.Archivable = false
	container.Parent = workspace
	table.insert(nukeIgnore, container)

	-- // Create mushroom cloud
	local cloudData = createMushroomCloud(position, container, clouds, shockwave)
	local outterSphere, innerSphere, bigRing, smallRing = cloudData.OutterSphere, cloudData.InnerSphere, cloudData.BigRing, cloudData.SmallRing
	local baseCloud, poleBase, poleRing = cloudData.BaseCloud, cloudData.PoleBase, cloudData.PoleRing
	local cloud1, cloud2, cloud3, mushCloud, topCloud = cloudData.Cloud1, cloudData.Cloud2, cloudData.Cloud3, cloudData.MushCloud, cloudData.TopCloud

	-- // Lighting & audio effects
	local newSky = skybox:Clone()
	table.insert(nukeSkyboxes, newSky)
	newSky.Parent = Lighting
	task.spawn(effects, nolighting)

	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("Sky") and not table.find(nukeSkyboxes, v) and not table.find(realSkyboxes, v) then
			table.insert(realSkyboxes, v)
		end
	end

	-- // Shockwave
	task.spawn(function()
		local maxSize = explosionSize * 3
		local smallSize = explosionSize / 2.5
		local nukeDuration = (maxSize - smallSize) / 2 * (1 / 60)
		local transforms = {
			{innerSphere, Vector3.new(-6.5 * maxSize, -6.5 * maxSize, -6.5 * maxSize)},
			{outterSphere, Vector3.new(6.5 * maxSize, 6.5 * maxSize, 6.5 * maxSize)},
			{smallRing, Vector3.new(4.6 * maxSize, 4.6 * maxSize, 1.5 * maxSize)},
			{bigRing, Vector3.new(5 * maxSize,5 * maxSize,1 * maxSize)},
		}

		for _, v in ipairs(transforms) do
			local object, scale = v[1], v[2]

			if typeof(object) == "Instance" then
				local mesh = object:FindFirstChildOfClass("SpecialMesh")

				if mesh then
					mesh.Scale = scale * (smallSize / maxSize)

					task.spawn(basicTween, mesh, {Scale = scale}, nukeDuration)
				end
			end
		end

		do
			local startclock = os.clock()
			local expGrow, expStat = maxSize - smallSize, smallSize

			repeat
				destruction(
					position,
					(((os.clock() - startclock) / nukeDuration) * expGrow + expStat) * 2,
					attacker
				)
				task.wait(1/25)
			until (os.clock() - startclock) > nukeDuration
		end

		for _, v in ipairs(shockwave) do
			v.Transparency = 0

			task.spawn(
				basicTween,
				v,
				{Transparency = 1},
				100 * (1 / 60)
			)
		end
		task.wait(100 * (1 / 60))

		for _ ,v in ipairs(shockwave) do
			v:Destroy()
		end

		shockwaveCompleted = true
	end)

	-- // Mushroom cloud grow
	task.spawn(function()
		local transforms = {
			{baseCloud, Vector3.new(2.5 * explosionSize, 1 * explosionSize, 4.5 * explosionSize), Vector3.new(0, 0.05 * explosionSize, 0)},
			{poleBase, Vector3.new(1 * explosionSize, 2 * explosionSize, 2.5 * explosionSize), Vector3.new(0, 0.1 * explosionSize, 0)},
			{poleRing, Vector3.new(1.2 * explosionSize, 1.2 * explosionSize, 1.2 * explosionSize), Vector3.new(0, 1.3 * explosionSize, 0)},
			{topCloud, Vector3.new(0.75 * explosionSize, 1.5 * explosionSize, 1.5 * explosionSize), Vector3.new(0, 2.7 * explosionSize, 0)},
			{mushCloud, Vector3.new(2.5 * explosionSize, 1.75 * explosionSize, 3.5 * explosionSize), Vector3.new(0, 2.3 * explosionSize, 0)},
			{cloud1, Vector3.new(0.5 * explosionSize, 3 * explosionSize, 1*  explosionSize), Vector3.new(0, 0.75 * explosionSize, 0)},
			{cloud2, Vector3.new(0.5 * explosionSize, 1.5 * explosionSize, 1 * explosionSize), Vector3.new(0, 1.25 * explosionSize, 0)},
			{cloud3, Vector3.new(0.5 * explosionSize, 1.5 * explosionSize, 1 * explosionSize), Vector3.new(0, 1.7 * explosionSize, 0)},
		}

		for _, v in ipairs(transforms) do
			local object, scale = v[1], v[2]

			if typeof(object) == "Instance" then
				object.Position = position + v[3] / 5
				local mesh = object:FindFirstChildOfClass("SpecialMesh")

				if mesh then
					mesh.Scale = scale / 5

					task.spawn(basicTween, mesh, {Scale = scale}, 2)
				end

				task.spawn(basicTween, object, {Position = position + v[3]}, 2)
			end
		end
	end)
	task.wait(2)

	-- // Mushroom cloud de-heating to red
	for _, v in ipairs(clouds) do
		local mesh = v:FindFirstChildOfClass("SpecialMesh")

		if mesh then
			mesh.VertexColor = Vector3.new(0.9, 0.6, 0)
			task.spawn(
				basicTween,
				mesh,
				{VertexColor = Vector3.new(0.9, 0, 0)},
				0.6 / 0.0025 * (1 / 60)
			)
		end
	end
	task.wait(0.6 / 0.0025 * (1 / 60))

	-- // Mushroom cloud de-heating to black
	for _, v in ipairs(clouds) do
		local mesh = v:FindFirstChildOfClass("SpecialMesh")

		if mesh then
			mesh.VertexColor = Vector3.new(0.9, 0, 0)
			task.spawn(
				basicTween,
				mesh,
				{VertexColor = Vector3.new(0.5, 0, 0)},
				(0.9 - 0.5) / 0.01 * (1 / 60) * 2
			)
		end
	end
	task.wait((0.9 - 0.5) / 0.01 * (1 / 60) * 2)

	local skyConnection
	skyConnection = newSky.AncestryChanged:Connect(function()
		if newSky and newSky.Parent ~= Lighting and table.find(nukeSkyboxes, newSky) then
			table.remove(nukeSkyboxes, table.find(nukeSkyboxes, newSky))
		end

		local hasNukeSkyboxes = false

		for _, v in ipairs(nukeSkyboxes) do
			if v.Parent == Lighting then
				hasNukeSkyboxes = true
				break
			end
		end

		if not hasNukeSkyboxes then
			for i = #realSkyboxes, 1, -1 do
				local v = realSkyboxes[i]

				if v.Parent == Lighting then
					v.Parent = nil

					task.spawn(function()
						task.wait()
						v.Parent = Lighting
					end)
				elseif table.find(realSkyboxes, v) then
					table.remove(realSkyboxes, table.find(realSkyboxes, v))
				end
			end
		end

		skyConnection:Disconnect()
	end)
	Debris:AddItem(newSky, 10)

	-- // De-heated cloud becoming natural cloud like (no longer heat or nuclear)
	for _, v in ipairs(clouds) do
		local mesh = v:FindFirstChildOfClass("SpecialMesh")

		if mesh then
			mesh.VertexColor = Vector3.new(0, 0, 0)
			task.spawn(
				basicTween,
				mesh,
				{VertexColor = Vector3.new(0.5, 0.5, 0.5)},
				0.5 / 0.005 * (1 / 60)
			)
			task.spawn(
				basicTween,
				mesh,
				{Scale = mesh.Scale + Vector3.new(0.1,0.1,0.1) * (0.5 / 0.005)},
				0.5 / 0.005 * (1 / 60)
			)
		end

		task.spawn(
			basicTween,
			v,
			{Transparency = 0.5},
			0.5 / 0.005 * (1 / 60)
		)
	end
	task.wait(0.5 / 0.005 * (1 / 60))

	-- // Cloud dissapate
	for _, v in ipairs(clouds) do
		task.spawn(
			basicTween,
			v,
			{Transparency = 1},
			20
		)

		local mesh = v:FindFirstChildOfClass("SpecialMesh")

		if mesh then
			task.spawn(
				basicTween,
				mesh,
				{Scale = mesh.Scale + Vector3.new(0.1,0.1,0.1) * (1 / 0.005)},
				20
			)
		end
	end
	task.wait(20)

	while true do task.wait(1) if shockwaveCompleted then break end end
	container:Destroy()
end


return explode
