-- Exercises real AFK preparation and cleanup with separate asynchronous effect coroutines.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local commandSource = fs.readFile("MainModule/Server/Commands/Moderators.luau")
local policySource = fs.readFile("MainModule/Server/Core/TextPolicy.luau")
local runCommandSource = assert(fs.readFile("MainModule/Server/Core/Admin.luau"):match("RunCommand = (function.-\n\t\tend);"))
local passed = 0

-- Creates isolated actors, character effects, and author-sensitive filtering for one scenario.
local function fixture()
	local current = {Now = 0, FilterCalls = {}, Pending = {}, Threads = {}, ForceFields = {}, FailFilter = nil}
	local online, allTools = {}, {}
	local server, admin = {}, {}
	local service = {}

	-- Supplies the Player identity contract checked by the real text policy.
	local function isPlayer(_, class)
		return class == "Player"
	end

	-- Builds a target with observable AFK effects and a manually triggered jump event.
	local function player(userId, name)
		local result = {UserId = userId, Name = name, DisplayName = `Display {name}`, IsA = isPlayer}
		local humanoid = {DisplayName = result.DisplayName, MaxHealth = 100, Health = 100}
		humanoid.Jumping = {
			-- Retains the same one-shot cleanup listener that Roblox fires on a jump.
			Once = function(_, callback)
				result.Jump = callback
			end,
		}
		result.Backpack = {
			-- Finds the tools currently held by the player, including after cleanup.
			GetChildren = function(backpack)
				local children = {}
				for _, tool in allTools do
					if tool.Parent == backpack then table.insert(children, tool) end
				end
				return children
			end,
		}
		result.Tool = {Parent = result.Backpack}
		table.insert(allTools, result.Tool)
		result.Character = {
			Humanoid = humanoid,
			HumanoidRootPart = {CFrame = "original position", Parent = true},
			-- Exposes the humanoid lookup used by the actual name-reset command.
			FindFirstChildOfClass = function(_, class)
				return if class == "Humanoid" then humanoid else nil
			end,
		}
		online[userId] = result
		return result
	end

	current.Author = player(101, "Author")
	current.Actor = player(202, "Actor")
	current.Targets = {player(303, "First"), player(404, "Second")}
	service.UnWrap = function(value) return value end
	service.Players = {GetPlayerByUserId = function(_, id) return online[id] end}
	service.FormatPlayer = function(value) return value.Name end
	-- Resolves selection for AFK and its existing per-player unname cleanup.
	service.GetPlayers = function(_, selector)
		if selector == "all" then return current.Targets end
		for _, target in current.Targets do
			if target.Name == selector then return {target} end
		end
		return {}
	end
	-- Records attribution and can reject a later label after earlier filtering succeeds.
	service.TryFilter = function(text, author, _, broadcast)
		assert(broadcast == true, "AFK labels require broadcast filtering")
		table.insert(current.FilterCalls, {Text = text, Author = author})
		if #current.FilterCalls == current.FailFilter then return nil, "FilterUnavailable" end
		return `filtered:{text}`
	end
	-- Makes force fields and tool containers observable without changing engine state.
	service.New = function(class, parent)
		local object = {ClassName = class, Parent = parent}
		object.Destroy = function() object.Destroyed = true end
		object.GetChildren = function()
			local children = {}
			for _, tool in allTools do
				if tool.Parent == object then table.insert(children, tool) end
			end
			return children
		end
		if class == "ForceField" then table.insert(current.ForceFields, object) end
		return object
	end
	local env = {
		server = server, service = service, Admin = admin, Settings = {Prefix = ":"},
		Functions = {GetMainPrefix = function() return ":" end},
		os = {clock = function() return current.Now end},
		typeof = function(value)
			return if type(value) == "table" and online[value.UserId] == value then "Instance" else typeof(value)
		end,
		-- Defers each effect onto its own coroutine, outside the command's author context.
		Routine = function(callback) table.insert(current.Pending, callback) end,
		wait = function() coroutine.yield() end,
		-- Uses the same synchronous xpcall boundary as non-Thread service.TrackTask calls.
		TrackTask = function(_, callback, handler, ...) return xpcall(callback, handler, ...) end,
		warn = function(message) error(message) end,
	}
	luau.load(policySource, {environment = env})()({Server = server, Service = service})
	current.Policy = server.TextPolicy
	current.Origin = {}
	server.ChatTransport = {
		-- Resolves only the fixture's original submitting player for a sudo invocation.
		ResolveOriginAuthor = function(origin)
			return if origin == current.Origin then current.Author else nil
		end,
	}

	-- Loads complete real command definitions, including their declared publication metadata.
	local function loadCommand(key)
		local definition = assert(commandSource:match("\n\t\t" .. key .. " = {(.-)\n\t\t};"))
		local command = luau.load("return {" .. definition .. "}", {environment = env})()
		server.TextPolicy.WrapCommand(command, key)
		return command
	end
	current.Command = loadCommand("AFK")
	local unname = loadCommand("UnName")
	admin.GetCommand = function(command)
		assert(command == ":unname", "AFK must not submit already prepared names as new edits")
		return "UnName", unname
	end
	admin.GetArgs = function(_, _, ...) return {...} end
	admin.RunCommand = luau.load("return " .. runCommandSource, {environment = env})()

	-- Advances every effect through tool removal and naming, leaving it waiting for a jump.
	current.StartEffects = function()
		for _, callback in current.Pending do
			local thread = coroutine.create(callback)
			assert(coroutine.resume(thread))
			assert(coroutine.resume(thread))
			table.insert(current.Threads, thread)
		end
	end
	return current
end

-- Verifies that a rejected operation has neither queued nor applied any AFK side effects.
local function assertUntouched(current)
	assert(#current.Pending == 0 and #current.ForceFields == 0, "Rejected AFK scheduled effects")
	for _, target in current.Targets do
		local humanoid = target.Character.Humanoid
		assert(humanoid.DisplayName == target.DisplayName and humanoid.MaxHealth == 100 and humanoid.Health == 100, "Rejected AFK changed a character")
		assert(target.Tool.Parent == target.Backpack and target.Jump == nil, "Rejected AFK moved tools or installed cleanup")
	end
end

-- Reports focused regression scenarios without hiding their assertion failures.
local function check(name, callback)
	callback()
	passed += 1
	print(`PASS {name}`)
end

check("multiple AFK targets share admission and retain filtered labels through jump cleanup", function()
	local current = fixture()
	current.Command.Function(current.Author, {"all"})
	assert(#current.FilterCalls == 2 and #current.Pending == 2, "Every selected target must have a prepared label")
	assert(not current.Policy.TryPublicEdit(current.Author), "AFK must consume the author's shared public-edit allowance")
	for index, call in current.FilterCalls do
		assert(call.Author == current.Author and call.Text == `-AFK-_{current.Targets[index].Name}_-AFK-`, "AFK lost its author or existing label format")
	end
	current.StartEffects()
	for index, target in current.Targets do
		local humanoid = target.Character.Humanoid
		assert(humanoid.DisplayName == `filtered:-AFK-_{target.Name}_-AFK-`, "AFK did not apply its prepared visible label")
		assert(humanoid.MaxHealth == math.huge and target.Tool.Parent ~= target.Backpack, "AFK effects were not applied")
		target.Jump()
		assert(coroutine.resume(current.Threads[index]))
		assert(coroutine.status(current.Threads[index]) == "dead", "Jump did not stop the freeze loop")
		assert(humanoid.DisplayName == target.DisplayName and humanoid.MaxHealth == 100 and humanoid.Health == 100, "Jump did not restore name and health")
		assert(target.Tool.Parent == target.Backpack and current.ForceFields[index].Destroyed, "Jump did not restore tools and remove the force field")
	end
end)

check("sudo AFK filters and charges the original author rather than the execution actor", function()
	local current = fixture()
	current.Command.Function(current.Actor, {"all"}, {Options = {isSystem = true, UserCommandOrigin = current.Origin}})
	for _, call in current.FilterCalls do assert(call.Author == current.Author, "Sudo reattributed an AFK label") end
	assert(not current.Policy.TryPublicEdit(current.Author), "Sudo bypassed the origin's shared allowance")
	assert(current.Policy.TryPublicEdit(current.Actor), "Sudo charged the execution actor's allowance")
end)

check("cooldown denial leaves all selected players untouched", function()
	local current = fixture()
	assert(current.Policy.TryPublicEdit(current.Author))
	assert(not pcall(current.Command.Function, current.Author, {"all"}), "AFK bypassed an existing public-edit cooldown")
	assert(#current.FilterCalls == 0, "A denied edit should not reach filtering")
	assertUntouched(current)
end)

check("a later filter failure applies no partial AFK effects", function()
	local current = fixture()
	current.FailFilter = 2
	assert(not pcall(current.Command.Function, current.Author, {"all"}), "AFK accepted a failed target-label filter")
	assert(#current.FilterCalls == 2 and not current.Policy.TryPublicEdit(current.Author), "A failed operation must retain its single reservation")
	assertUntouched(current)
end)

check("unattributed AFK calls fail before effects and empty selections consume no admission", function()
	local current = fixture()
	assert(not pcall(current.Command.Function, false, {"all"}), "Unattributed AFK bypassed authorship")
	assertUntouched(current)
	current.Command.Function(current.Author, {"missing"})
	assert(current.Policy.TryPublicEdit(current.Author), "An empty selection consumed public-edit admission")
	assertUntouched(current)
end)

print(`AFK: {passed} checks passed`)
