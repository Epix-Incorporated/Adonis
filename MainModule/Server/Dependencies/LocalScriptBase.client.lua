task.wait()
local execute = script:FindFirstChild("Execute")
local code, runCode = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)
local env = getfenv()

if code then
	runCode(code, env)()
end
