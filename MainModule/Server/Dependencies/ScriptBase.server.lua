task.wait()
local execute = script:FindFirstChild("Execute")
local code, lbi = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)

local canUseLoadstring = loadstring and pcall(loadstring, "local a = 5 local b = a + 5") or false

if code then
	local func = canUseLoadstring and loadstring(code) or lbi(code, getfenv())
	if func then
		func()
	end
end
