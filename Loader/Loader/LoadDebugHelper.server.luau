local StarterGui = game:GetService("StarterGui")

local SANDBOX_HELP_MESSAGE = [[Adonis has likely failed to load due to Sandboxing restrictions. To fix this disable the `.Sandboxed` property of all Adonis loader scripts and enable `Allow Loading Third Party Assets` in the game settings.]]

local warn = function(...)
	warn(":: Adonis ::", ...)
end

local print = function(...)
	print(":: Adonis ::", ...)
end

local function checkSandbox()
	local success, value = pcall(function()
		return (
			script.Sandboxed or
			script.Parent.Sandboxed or
			script.Parent:FindFirstChild("Loader") and script.Parent.Loader.Sandboxed or
			script.Parent.Parent and script.Parent.Parent.Sandboxed
		)
	end)

	return not success or value or false
end

task.wait(10)

xpcall(function()
	if script:FindFirstChild("__SANDBOX_MESSAGE") then
		SANDBOX_HELP_MESSAGE = script.__SANDBOX_MESSAGE.Value or SANDBOX_HELP_MESSAGE
	end
end, warn)

if script:FindFirstChild("__DISPLAY_SANDBOX_MESSAGE") or script:GetAttribute("__DISPLAY_SANDBOX_MESSAGE") or not script.Parent:FindFirstChild("__ADONIS_LOAD_HELP_MUTEX") and checkSandbox() then
	xpcall(print, warn, SANDBOX_HELP_MESSAGE)
	xpcall(StarterGui.SetCore, warn, StarterGui, "SendNotification", {
		Title = "Adonis Notification";
		Text = SANDBOX_HELP_MESSAGE;
		Icon = "rbxassetid://7501176860";
		Duration = 15;
		-- TODO: Add button to click for show the same help GUI that exists with coresponding server message
	})
end
