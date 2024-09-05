while rawget(_G, "Adonis") == nil do
	task.wait()
end
local execute = script:FindFirstChild("Execute")
local code, loadCode = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)
local env = getfenv()

if code then
	loadCode(code, env)()
end
