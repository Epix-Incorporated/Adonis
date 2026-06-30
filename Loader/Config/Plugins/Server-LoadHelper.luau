--[[
	Assist in loader related issues
]]

local StarterGui = game:GetService("StarterGui")
local loaderFolder = script.Parent and script.Parent.Parent and script.Parent.Parent.Parent:FindFirstChild("Loader")
local debugHelper = loaderFolder and loaderFolder:FindFirstChild("LoadDebugHelper")
local sCopy = nil

local function checkSandbox()
	local success, value = pcall(function()
		return (
			script.Sandboxed or
			script.Parent and (script.Parent.Sandboxed or script.Parent.Parent and script.Parent.Parent.Sandboxed) or
			loaderFolder:FindFirstChild("Loader") and loaderFolder.Loader.Sandboxed or
			loaderFolder.Sandboxed or loaderFolder.Parent and loaderFolder.Parent.Sandboxed
		)
	end)

	return not success or value or false
end

if debugHelper and checkSandbox() then
	xpcall(function()
		sCopy = debugHelper:Clone()
		sCopy.Enabled = true
		sCopy.Parent = StarterGui
		local val = Instance.new("BoolValue")
		val.Name = "__DISPLAY_SANDBOX_MESSAGE"
		val.Value = true
		val.Archivable = false
		val.Parent = sCopy
	end, function()
		xpcall(function()
			debugHelper:SetAttribute("__DISPLAY_SANDBOX_MESSAGE", true)
			debugHelper.Enabled = true
			debugHelper.Parent = StarterGui
		end, warn)
	end)
end

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	local Pcall = server.Pcall
	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps
	loaderFolder, debugHelper, StarterGui, sCopy = server.Model and server.Model:FindFirstChild("Loader") or service.Wrap(loaderFolder), service.Wrap(debugHelper), service.StarterGui, sCopy and service.Wrap(sCopy) or nil

	service.New("BoolValue", {
		Parent = loaderFolder;
		Name = "__ADONIS_LOAD_HELP_MUTEX";
		Value = true;
		Archivable = false;
	})
	Logs:AddLog("Script", "Created mutex for load helper")

	if sCopy then
		Pcall(sCopy.ClearAllChildren, sCopy)
		service.Delete(sCopy)
		Logs:AddLog("Script", "Removed copy of load helper")
	elseif loaderFolder then
		debugHelper.Parent = loaderFolder
		Pcall(debugHelper.ClearAllChildren, debugHelper)
		debugHelper:SetAttribute("__DISPLAY_SANDBOX_MESSAGE", nil)
		Logs:AddLog("Script", "Adonis failed to create a copy of debug helper. Parenting raw script back to loader")
	end
end
