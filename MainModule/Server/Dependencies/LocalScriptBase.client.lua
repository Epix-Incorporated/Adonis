task.wait()
local execute = script:FindFirstChild("Execute")
local code, loadCode = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)
local env = getfenv()

if code then
	loadCode(code, env)()
end
