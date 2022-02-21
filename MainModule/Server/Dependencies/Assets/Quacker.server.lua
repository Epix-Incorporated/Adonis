while true do
	wait(math.random(5, 20))
	if script.Parent ~= nil then
		local name = "Quack" .. math.random(1, 4)
		script.Parent:FindFirstChild(name):Play()
	else
		break
	end
end