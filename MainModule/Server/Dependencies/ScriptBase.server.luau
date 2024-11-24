while rawget(_G, "Adonis") == nil do
	task.wait()
end
local execute = script:FindFirstChild("Execute")
local code, loadCode = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)
local canUseLoadstring = loadstring and pcall(loadstring, "local a = 5 local b = a + 5") or false
local env = getfenv()

if code then
	(canUseLoadstring and loadstring(code) or loadCode(code, env))()
end
