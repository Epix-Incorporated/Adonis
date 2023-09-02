task.wait()
local execute = script:FindFirstChild("Execute")
local code, lbi = rawget(_G, "Adonis").Scripts.ExecutePermission(script, execute and execute.Value)

if code then
	local func = lbi(code, getfenv())
	if func then
		func()
	end
end
