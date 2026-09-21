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
		pcall(function() dTarget.Parent = model:FindFirstChild("Loader") end)
		task.wait()
		pcall(function() dTarget.Name = "Loader" end)

		warn("TARGET DESTROYED")
		task.wait()

		warn("CLEANING")

		rawset(_G, "Adonis", nil)
		rawset(_G, "__Adonis_MODULE_MUTEX", nil)
		rawset(_G, "__Adonis_MUTEX", nil)

		warn("_G VARIABLES CLEARED")

		if game:GetService("RunService"):FindFirstChild("__Adonis_MUTEX") then
			game:GetService("RunService").__Adonis_MUTEX:Destroy()
			warn("VARIABLE MUTEX CLEARED")
		end

		if game:GetService("RunService"):FindFirstChild("__Adonis_MODULE_MUTEX") then
			game:GetService("RunService").__Adonis_MODULE_MUTEX:Destroy()
			warn("VARIABLE MODULE MUTEX CLEARED")
		end

		if dTarget.Parent and dTarget.Parent:FindFirstChild("Dropper") then
			dTarget.Parent.Dropper.Disabled = true
			warn("DISABLED LEGACY DROPPED")
		end

		warn("MOVING MODEL")
		model.Parent = tParent
		model.Name = "Adonis_Loader"
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
