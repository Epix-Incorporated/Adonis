-- Run with `lune run Tests/PrivateChatLifecycle.spec.luau` from the repository root.
-- Exercises the actual conversation window with mocked registration and transport events.
local fs = require("@lune/fs")
local luau = require("@lune/luau")

-- Models event subscriptions so closed windows can be checked for retained listeners.
local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			callbacks[callback] = true
			return {Disconnect = function() callbacks[callback] = nil end}
		end,
		Fire = function(_, ...)
			for callback in table.clone(callbacks) do callback(...) end
		end,
		-- Releases channel subscribers after delivering its final closure event.
		Clear = function() table.clear(callbacks) end,
		Count = function()
			local count = 0
			for _ in callbacks do count += 1 end
			return count
		end,
	}
end

-- Supplies the layout and interaction properties used by the real window module.
local function node(properties)
	local color = {lerp = function(self) return self end}
	local result = table.clone(properties or {})
	result.Children = {}
	result.BackgroundColor3 = color
	result.AbsoluteContentSize = {Y = 0}
	result.FocusLost = signal()
	result.MouseButton1Click = signal()
	result.MouseButton1Down = signal()
	result.GetPropertyChangedSignal = function() return signal() end
	result.ClearAllChildren = function(self) table.clear(self.Children) end
	result.GetChildren = function(self) return self.Children end
	result.Destroy = function(self) self.Destroyed = true end
	result.CaptureFocus = function() end
	result.Add = function(self, class, props)
		local child = node(props)
		child.ClassName = class
		table.insert(self.Children, child)
		return child
	end
	return result
end

-- Uses the shipped theme close callbacks and UI registry cleanup with inert animation substitutes.
local function installThemeClose(themeName, window, data, registered, options)
	local theme = fs.readFile(`MainModule/Client/UI/{themeName}/Window.rbxmx`)
	local ui = fs.readFile("MainModule/Client/Core/UI.luau")
	local closeBody = assert(theme:match("\tfunction doClose%(%)\n(.-)\n\tfunction isVisible"), "Missing theme close implementation")
	local customDestroyBody = assert(theme:match("\tgTable.CustomDestroy = function%(%)\n(.-)\n\tfor i,child"), "Missing theme destruction implementation")
	local destroyBody = assert(ui:match("\t\t\t\tDestroy = function%(%)\n(.-)\n\t\t\t\tUnRegister"), "Missing UI destruction implementation"):gsub(",%s*$", "")
	local clearEventsBody = assert(ui:match("\t\t\t\tClearEvents = function%(%)\n(.-)\n\t\t\t\tDestroy"), "Missing UI event cleanup implementation"):gsub(",%s*$", "")
	local closeEnv = setmetatable({
		gTable = window.gTable, gIndex = data.Name, GUI = window, onClose = data.OnClose,
		client = {Variables = {}, GUIs = registered}, service = {UnWrap = function(value) return value end},
		Drag = {GetChildren = function() return {} end, TweenSize = function() end},
		Main = {TweenSize = function() end}, Mouse = {},
		UDim2 = {new = function() return {} end},
		Enum = {EasingDirection = {Out = "Out"}, EasingStyle = {Quad = "Quad"}},
		task = {wait = function() if options.DuringAnimation then options.DuringAnimation() end end},
	}, {__index = getfenv()})
	window.Close = luau.load("local isClosed = false\n"
		.. "gTable.ClearEvents = function()\n" .. clearEventsBody .. "\n"
		.. "gTable.Destroy = function()\n" .. destroyBody .. "\n"
		.. "gTable.CustomDestroy = function()\n" .. customDestroyBody .. "\n"
		.. "local function doClose()\n" .. closeBody .. "\nreturn doClose", {environment = closeEnv})()
end

-- Loads the real UI against a registered-window store and observable channel lifecycle.
local function fixture(themeName, options)
	options = options or {}
	local windows, registered, remoteSends, drafts = {}, {}, {}, {}
	local messages, sessionData = signal(), signal()
	local transport = {
		GetHistory = function() return {} end,
		Subscribe = function(_, callback)
			local connection = messages:Connect(callback)
			return function() connection:Disconnect() end
		end,
		Send = function(channelId, text)
			table.insert(drafts, {ChannelId = channelId, Text = text})
			return true, "Success"
		end,
	}
	local client = {
		ChatTransport = transport,
		MatIcons = {Forum = "Forum"},
		Remote = {Send = function(...)
			local args = {...}
			table.insert(remoteSends, args)
			if options.FailLeave and args[3] == "LeaveSession" then error("fixture remote unavailable") end
		end},
		UI = {
			Get = function(name) return registered[name] or false end,
			Make = function(kind, data)
				assert(kind == "Window", "Unexpected UI presentation")
				local window = node(data)
				-- Observes listener state at native GUI destruction, before registry cleanup.
				window.Destroy = function(self)
					if options.BeforeDestroy then options.BeforeDestroy() end
					self.Destroyed = true
				end
				window.gTable = {Name = data.Name, Object = window, Events = {}}
				window.Ready = function() end
				-- Matches Window's synchronous close callback and UI registry cleanup.
				window.Close = function()
					if window.Destroyed then return end
					window.Destroyed = true
					if data.OnClose then data.OnClose() end
					registered[data.Name] = nil
				end
				if themeName then installThemeClose(themeName, window, data, registered, options) end
				registered[data.Name] = window.gTable
				table.insert(windows, window)
				return window
			end,
		},
	}
	local service = {
		UnWrap = function(value) return value end,
		Players = {LocalPlayer = {UserId = 2}, GetPlayerByUserId = function() return nil end},
		Events = {SessionData = sessionData},
		New = function(_, props) return node(props) end,
		Trim = function(value) return value:match("^%s*(.-)%s*$") end,
	}
	local env = setmetatable({
		client = client, service = service,
		UDim2 = {new = function(...) return {...} end},
		Vector2 = {new = function(...) return {...} end},
		Color3 = {new = function() return {} end},
	}, {__index = getfenv()})
	local loadPrivateChat = luau.load(fs.readFile("MainModule/Client/UI/Default/PrivateChat.luau"))()
	local data = {ChannelId = "conversation", SessionName = "conversation", SessionKey = "session", CanManageUsers = false}
	return {
		Open = function() loadPrivateChat(data, env) end,
		-- Mirrors the transport's final event followed by removal of its subscribers.
		CloseChannel = function()
			messages:Fire("Closed", "Removed")
			messages.Clear()
		end,
		Windows = windows, Registered = registered, Messages = messages, SessionData = sessionData,
		RemoteSends = remoteSends, Drafts = drafts,
	}
end

local f = fixture()
f.Open()
f.Open()
assert(#f.Windows == 1 and f.Messages.Count() == 1, "An active conversation must not open twice")
assert(f.SessionData.Count() == 1, "The active window must receive session updates")

f.CloseChannel()
assert(f.Windows[1].Destroyed and not next(f.Registered), "Removal must release the registered conversation window")
assert(f.Messages.Count() == 0 and f.SessionData.Count() == 0, "Removal must disconnect window listeners")
assert(#f.RemoteSends == 1 and f.RemoteSends[1][3] == "GetPeerList", "Server removal must not send LeaveSession")

f.Open()
assert(#f.Windows == 2 and f.Messages.Count() == 1 and f.SessionData.Count() == 1, "Rejoining must create one active window and subscription")
local replacement = f.Windows[2]
local reply = replacement.Children[2]
assert(reply.ClassName == "TextBox" and reply.TextEditable ~= false, "The rejoined participant must be able to type")
f.Messages:Fire("Message", {SenderUserId = 1, SenderName = "Sender", Text = "Delivered message"})
assert(#replacement.Children[1].Children == 1, "Delivered messages must reach the replacement window")
assert(#f.Windows[1].Children[1].Children == 0, "The removed window must not receive later messages")
reply.Text = "Reply after rejoining"
for _, child in replacement.Children do
	if child.ClassName == "TextButton" and child.Text == "Send" then child.OnClick() end
end
assert(#f.Drafts == 1 and f.Drafts[1].Text == "Reply after rejoining" and reply.Text == "", "The replacement window must send replies")

replacement:Close()
replacement:Close()
assert(f.Messages.Count() == 0 and f.SessionData.Count() == 0 and not next(f.Registered), "Manual closure must release listeners and registration")
assert(#f.RemoteSends == 3 and f.RemoteSends[3][3] == "LeaveSession", "Manual closure must leave the session exactly once")

for _, themeName in {"Unity", "Aero"} do
	local themed = fixture(themeName)
	for cycle = 1, 3 do
		themed.Open()
		assert(#themed.Windows == cycle and themed.SessionData.Count() == 1, `{themeName} rejoin must retain only the active session listener`)
		themed.CloseChannel()
		assert(themed.Windows[cycle].Destroyed and not next(themed.Registered), `{themeName} removal must release the window`)
		assert(themed.Messages.Count() == 0 and themed.SessionData.Count() == 0, `{themeName} removal must disconnect listeners without relying on OnClose`)
		assert(#themed.RemoteSends == cycle and themed.RemoteSends[cycle][3] == "GetPeerList", `{themeName} server removal must not send LeaveSession`)
	end
end
for _, themeName in {"Default", "Unity", "Aero"} do
	local options = {}
	local manual = fixture(themeName, options)
	options.BeforeDestroy = function()
		assert(manual.Messages.Count() == 0 and manual.SessionData.Count() == 0, `{themeName} must disconnect listeners before destroying the GUI`)
	end
	for cycle = 1, 2 do
		manual.Open()
		local window = manual.Windows[cycle]
		window:Close()
		window:Close()
		assert(window.Destroyed and not next(manual.Registered), `{themeName} manual close must release registration`)
		assert(manual.Messages.Count() == 0 and manual.SessionData.Count() == 0, `{themeName} manual close must release listeners`)
		assert(#manual.RemoteSends == cycle * 2 and manual.RemoteSends[cycle * 2][3] == "LeaveSession", `{themeName} manual close must leave exactly once across rejoin`)
		manual.Messages:Fire("Message", {SenderUserId = 1, SenderName = "Sender", Text = "After closure"})
		assert(#window.Children[1].Children == 0, `{themeName} destroyed windows must not receive later messages`)
	end
	manual.Open()
	manual.Windows[3].gTable:Destroy()
	manual.Windows[3].gTable:Destroy()
	assert(#manual.RemoteSends == 6 and manual.RemoteSends[6][3] == "LeaveSession", `{themeName} direct registry destruction must leave exactly once`)
end

local animationOptions = {}
local animation = fixture("Aero", animationOptions)
animation.Open()
animationOptions.DuringAnimation = function()
	assert(not animation.Windows[1].Destroyed, "The removal must arrive during the close animation")
	animation.CloseChannel()
end
animation.Windows[1]:Close()
assert(animation.Windows[1].Destroyed and not next(animation.Registered), "Removal during an animated close must release the window")
assert(animation.Messages.Count() == 0 and animation.SessionData.Count() == 0, "Removal during animated closure must release listeners")
assert(#animation.RemoteSends == 1 and animation.RemoteSends[1][3] == "GetPeerList", "Server removal during animated closure must not send LeaveSession")

local unavailable = fixture("Unity", {FailLeave = true})
unavailable.Open()
unavailable.Windows[1]:Close()
unavailable.Windows[1]:Close()
assert(unavailable.Windows[1].Destroyed and not next(unavailable.Registered), "A failed leave submission must not prevent GUI destruction")
assert(unavailable.Messages.Count() == 0 and unavailable.SessionData.Count() == 0, "A failed leave submission must not retain listeners")
assert(#unavailable.RemoteSends == 2, "A failed leave submission must not be retried by theme destruction")
print("Private chat lifecycle passed: removal, rejoin, message delivery, replies, Default/Unity/Aero manual and registry closure, and animated removal")
