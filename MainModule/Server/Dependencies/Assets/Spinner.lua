local torso = script.Parent
local bg = torso:FindFirstChild("SPINNER_GYRO")
repeat
  wait(1/44)
  bg.cframe = bg.cframe * CFrame.Angles(0,math.rad(30),0)
until not bg or bg.Parent ~= torso