while true do
	task.wait(math.random(5,20))
	if (script.Parent~=nil) then
		local name = "Quack" .. math.random(1,4)
		script.Parent:FindFirstChild(name):Play()
	end
	if not script.Parent then break end
end