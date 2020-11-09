local LocalPlayer=game:GetService'Players'.LocalPlayer
local RunS=game:GetService'RunService'
local UIS=game:GetService'UserInputService'
local speedVal = script:WaitForChild("Speed")
local Mouse=LocalPlayer:GetMouse()
local Camera=workspace.CurrentCamera
local ZeroVector=Vector3.new()
local CF=CFrame.new()
local Ch=LocalPlayer.Character
if Ch then
	local RootPart = Ch.PrimaryPart or Ch:FindFirstChild'HumanoidRootPart'
	if RootPart then
		CF=RootPart.CFrame
	end
end
local Enabled=true
UIS.InputBegan:Connect(function(Key,GC)
	if GC then return end
	if Key.KeyCode==Enum.KeyCode.E and not UIS:GetFocusedTextBox()then
		local Ch=LocalPlayer.Character
		if Ch then
			local Hum = Ch:FindFirstChild'Humanoid'
			local RootPart = Ch.PrimaryPart or Ch:FindFirstChild'HumanoidRootPart'
			if RootPart and Hum then
				CF=RootPart.CFrame
				Enabled=not Enabled
				if Enabled then
					Hum.PlatformStand = true
				else
					Hum.PlatformStand = false
				end
			end
		end
	end
end)
local MaxY=2e9
RunS.Heartbeat:Connect(function()
	local Ch=LocalPlayer.Character
	if Enabled and Ch then
		local RootPart = Ch.PrimaryPart or Ch:FindFirstChild'HumanoidRootPart'
		if RootPart then
			RootPart.Velocity = ZeroVector
			RootPart.RotVelocity = ZeroVector
			local Direction = UIS:GetFocusedTextBox()and ZeroVector or(ZeroVector +
				(UIS:IsKeyDown'W'and Vector3.new(0, 0, -1)or ZeroVector) +
				(UIS:IsKeyDown'S'and Vector3.new(0, 0, 1)or ZeroVector) +
				(UIS:IsKeyDown'D'and Vector3.new(1, 0, 0)or ZeroVector) +
				(UIS:IsKeyDown'A'and Vector3.new(-1, 0, 0)or ZeroVector) +
				(UIS:IsKeyDown'Q'and Vector3.new(0, -1, 0)or ZeroVector) +
				((UIS:IsKeyDown'E'or UIS:IsKeyDown(Enum.KeyCode.Space))and Vector3.new(0, 1, 0)or ZeroVector))
			Direction = Direction*2*(UIS:IsKeyDown'LeftControl'and 3 or speedVal.Value)
			CF = CF * CFrame.new(Direction)
			local Direction=(Mouse.Hit.Position-Camera.CFrame.Position)
			Direction = Camera.CFrame.Position + (Direction.Unit * 10000)
			if CF.Y > MaxY then
				CF = CFrame.new(CF.X, math.clamp(CF.Y, -1000, MaxY), CF.Z)
			end
			CF = CFrame.new(CF.Position, Direction)
			Ch:SetPrimaryPartCFrame(CF)
			RootPart.CFrame = CF
		end
	end
end)
