local hum = script.Parent:FindFirstChildOfClass("Humanoid")

hum.Jump = true
hum:GetPropertyChangedSignal("Jump"):Connect(function()
	hum.Jump = true
end)
hum.Jump = not hum.Jump -- in some unreliable cases this line might be needed to make GetPropertyChangedSignal trigger immediately
