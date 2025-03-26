--# selene: allow(incorrect_standard_library_use)
if script.Parent then
	local dTargetVal = script:WaitForChild("Runner")
	local parentVal = script:WaitForChild("mParent")
	local modelVal = script:WaitForChild("Model")
	local modeVal = script:WaitForChild("Mode")

	warn("Reloading in 5 seconds...")
	task.wait(5)
	script.Parent = nil

	local dTarget = dTargetVal.Value
	local tParent = parentVal.Value
	local model = modelVal.Value
	local mode = modeVal.Value

	local function CleanUp()
		warn("TARGET DISABLED")
		dTarget.Disabled = true
		pcall(function() dTarget.Parent = game:GetService("ServerScriptService") end)
		task.wait()
		pcall(function() dTarget:Destroy() end)

		warn("TARGET DESTROYED")
		task.wait()

		warn("CLEANING")

		if not table.isfrozen(_G) then
			rawset(_G, "Adonis", nil)
			rawset(_G, "__Adonis_MODULE_MUTEX", nil)
			rawset(_G, "__Adonis_MUTEX", nil)
		end

		warn("_G VARIABLES CLEARED")

		warn("MOVING MODEL")
		model.Parent = tParent
	end

	if mode == "REBOOT" then
		warn("ATTEMPTING TO RELOAD ADONIS")
		CleanUp()
		task.wait()

		warn("MOVING")
		model.Parent = tParent

		task.wait()

		dTarget.Disabled = false
		warn("RUNNING")
	elseif mode == "STOP" then
		warn("ATTEMPTING TO STOP ADONIS")
		CleanUp()
	end

	warn("COMPLETE")

	warn("Destroying reboot handler...")
	script:Destroy()
end
