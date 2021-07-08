local threadScript = script
local threadName = threadScript.Name
local bindEvent = threadScript:WaitForChild("Event")

threadScript.Parent = nil
setfenv(1, {})

bindEvent.Event:Connect(function(func)
	bindEvent.Parent = nil
	threadScript.Name = threadName
	return func()
end)

threadScript.Name = "__READY"