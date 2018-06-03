local torso = script.Parent
local bg = Instance.new("BodyGyro", torso)
bg.Name = "SPINNER"
bg.maxTorque = Vector3.new(0,math.huge,0)
bg.P = 11111
bg.cframe = torso.CFrame
repeat
  wait(1/44)
  bg.cframe = bg.cframe * CFrame.Angles(0,math.rad(30),0)
until not bg or bg.Parent ~= torso