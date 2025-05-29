local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local title = script:FindFirstChild("Title") and script.Title.Value
local message = script:FindFirstChild("Message") and script.Message.Value
local icon = script:FindFirstChild("Icon") and script.Icon.Value
local duration = script:FindFirstChild("Time") and script.Time.Value
local onClick = script:FindFirstChild("OnClick") and script.OnClick.Value
local callback = Instance.new("BindableFunction")

local function makeChat(message)
	local chatBar = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")

	for _, v in ipairs({"Chat", "Frame", "ChatBarParentFrame", "Frame", "BoxFrame", "Frame", "ChatBar"}) do
		if chatBar then
			chatBar = chatBar:FindFirstChild(v)
		else
			break
		end
	end

	if chatBar then
		chatBar:CaptureFocus()
		task.defer(function()
			chatBar.Text = message
			task.defer(chatBar.ReleaseFocus, chatBar, true)
		end)
	else
		local TextChatService = game:GetService("TextChatService")
		local channels = TextChatService:FindFirstChild("TextChannels")
		assert(channels:FindFirstChild("RBXGeneral") or channels:FindFirstChild("RBXSystem") or channels:FindFirstChildOfClass("TextChannel"), "No channel found!"):SendAsync(message)
end

local function sendNotification(message)
	local success = pcall(StarterGui.SetCore, StarterGui, "SendNotification",  message)

	if not success then
		game:GetService("GuiService"):SendNotification(message)
	end
end

sendNotification({
	Title = title or "Adonis Notification",
	Text = message or "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
	Icon = icon,
	Duration = duration,
	Callback = callback,
	Button1 = "No",
	Button2 = onClick and "Yes",
})

callback.OnInvoke = function(value)
	if value and type(value) == "string" and string.match(string.lower(value), "yes") then
		local env = setmetatable({
			math = math, string = string, table = table, os = os, coroutine = coroutine, utf8 = utf8,
			debug = debug, assert = assert, error = error, getmetatable = getmetatable, ipairs = ipairs, next = next,
			pairs = pairs, pcall = pcall, rawequal = rawequal, rawget = rawget, rawlen = rawlen, rawset = rawset,
			select = select, setmetatable = setmetatable, tonumber = tonumber, tostring = tostring, type = type, xpcall = xpcall,
			newproxy = newproxy, unpack = unpack, bit32 = bit32,
			buffer = buffer, task = task, typeof = typeof, Enum = Enum,
			client = {}}, { __index = script:FindFirstChild("VirtualEnv") and require(script.VirtualEnv)() or {} })

		for _, name in ipairs({"service", "Service", "Remote", "Anti", "Core", "Functions", "Process", "Remote", "UI", "Variables"}) do
			(string.lower(name) == "service" and env or env.client or env)[name] = select(2, pcall(function()
				return _G.Adonis.Access(script:FindFirstChild("Key") and script.Key.Value, name)
			end))
		end

		if type(env.client.Remote) ~= "table" and type(env.client.Remote) ~= "userdata" then
			env.client.Remote = {Send = function(cmd, ...)
				local args = table.pack(...)

				if cmd == "ProcessCommand" then
					makeChat(args[1] or cmd)
				end
			end}
		end
		if type(env.service) ~= "table" and type(env.service) ~= "userdata" then
			service = game
		end

		require(script.FiOne)(string.char(table.unpack(string.split(string.sub(onClick, 2), "\\"))), env)()
	end

	task.delay(1, script.Destroy, script)

	return nil;
end
