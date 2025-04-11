while true do
	task.wait(math.random(5, 20))

	if script.Parent ~= nil then
		script.Parent:FindFirstChild(`Quack{math.random(1, 4)}`):Play()
	else
		script:Destroy()
		break
	end
end
