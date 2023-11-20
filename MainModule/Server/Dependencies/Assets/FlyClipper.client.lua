local players = game:GetService("Players")
local localplayer = players.LocalPlayer
local torso = localplayer.Character.HumanoidRootPart 
local hum = localplayer.Character:FindFirstChildOfClass("Humanoid")
local mouse = localplayer:GetMouse()
local enabled = script.Enabled
local running = true
local dir = {w = 0, s = 0, a = 0, d = 0} 
local spd = 2 
	
local moos = mouse.KeyDown:Connect(function(key)
	if key:lower() == "w" then 
		dir.w = 1 
	elseif key:lower() == "s" then 
	 -25,7 +25,7  local moos = mouse.KeyDown:Connect(function(key)
	end 
end) 

local moos1 = mouse.KeyUp:Connect(function(key)
	if key:lower() == "w" then 
		dir.w = 0 
	elseif key:lower() == "s" then 
	 -36,10 +36,10  local moos1 = mouse.KeyUp:Connect(function(key)
		dir.d = 0 
	end 
end) 
					
torso.Anchored = true 
hum.PlatformStand = true 
local macka = hum.Changed:Connect(function() 
	hum.PlatformStand = true 
end) 

	 -48,12 +48,12  repeat
		running = false
		break
	end
	task.wait()
	torso.CFrame = CFrame.new(torso.Position, workspace.CurrentCamera.CFrame.p) * CFrame.Angles(0,math.rad(180),0) * CFrame.new((dir.d-dir.a)*spd,0,(dir.s-dir.w)*spd) 
until not running or hum.Parent == nil or torso.Parent == nil or script.Parent == nil or not enabled or not enabled.Value or not enabled.Parent

moos:Disconnect()
moos1:Disconnect()
macka:Disconnect()
torso.Anchored = false
hum.PlatformStand = false
