local LocalPlayer=game:GetService"Players".LocalPlayer
local RunS=game:GetService"RunService"
local UIS=game:GetService"UserInputService"
local ContextS=game:GetService"ContextActionService"
local speedVal = script:WaitForChild"Speed"
local noclip = script:WaitForChild"Noclip"
local Mouse=LocalPlayer:GetMouse()
local Camera=workspace.CurrentCamera
local ZeroVector=Vector3.new()
local CF=CFrame.new()
local Ch=LocalPlayer.Character
local Hum=Ch:FindFirstChildOfClass"Humanoid"
local RootPart
if Ch then
	RootPart = Ch.PrimaryPart or Ch:FindFirstChild"HumanoidRootPart"
	if RootPart then
		CF=RootPart.CFrame
	end
end
local Enabled=true
UIS.InputBegan:Connect(function(Key,GC)
	if GC then return end
	if Key.KeyCode==Enum.KeyCode.E and not UIS:GetFocusedTextBox()then
		if Ch.Parent and RootPart and Hum then
			CF=RootPart.CFrame
			Enabled=not Enabled
			if Enabled then
				Hum.PlatformStand = true
			else
				Hum.PlatformStand = false
			end
		end
	end
end)
RunS.Heartbeat:Connect(function()
	if Enabled and Ch.Parent and RootPart then
		RootPart.Velocity = ZeroVector
		RootPart.RotVelocity = ZeroVector
		local Direction = UIS:GetFocusedTextBox()and ZeroVector or not UIS.KeyboardEnabled and Hum.MoveDirection or(ZeroVector +
			(UIS:IsKeyDown'W'and Vector3.new(0, 0, -1)or ZeroVector) +
			(UIS:IsKeyDown'S'and Vector3.new(0, 0, 1)or ZeroVector) +
			(UIS:IsKeyDown'D'and Vector3.new(1, 0, 0)or ZeroVector) +
			(UIS:IsKeyDown'A'and Vector3.new(-1, 0, 0)or ZeroVector) +
			(UIS:IsKeyDown'Q'and Vector3.new(0, -1, 0)or ZeroVector) +
			((UIS:IsKeyDown'E'or UIS:IsKeyDown(Enum.KeyCode.Space))and Vector3.new(0, 1, 0)or ZeroVector))
		Direction = Direction*2*(UIS:IsKeyDown'LeftControl'and 3 or speedVal.Value)
		CF = CF * CFrame.new(Direction)
		local CDirection = (Mouse.Hit.Position-Camera.CFrame.Position)
		CDirection = Camera.CFrame.Position + (CDirection.Unit * 10000)
		CF = CFrame.new(CF.Position, not UIS.KeyboardEnabled and Camera.CFrame.Position or CDirection)
		if noclip.Value then
			for Indx, Obj in ipairs(Ch:GetChildren())do
				if Obj:IsA"BasePart"then
					Obj.CanCollide = false
				end
			end
		end
		Ch:SetPrimaryPartCFrame(CF)
		RootPart.CFrame = CF
	end
end)
local Debounce = false
local function Toggle()
	if not Debounce then
		Debounce = true
		if not Enabled then
			Enabled = true
			if Hum then
				Hum.PlatformStand = true
			end
		else
			Enabled = false
			if Hum then
				Hum.PlatformStand = false
			end
		end
		wait(.5)
		Debounce = false
	end
end
if not UIS.KeyboardEnabled then
	ContextS:BindAction("Toggle Flight", Toggle, true)
	-- Tested UnbindingAction's after the script was deleted, it's impossible without another LocalScript, the old fly didn't unbind it either.	
--[[script.AncestryChanged:Connect(function()
		ContextS:UnbindAction("Toggle Flight")
	end)]]--
end
