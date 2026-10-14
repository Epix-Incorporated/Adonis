-- Run with `lune run Tests/ProfileData.spec.luau`; exercises profile telemetry from producer to display.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local secret = "UNFILTERED_PROFILE_INPUT"
local viewer = {UserId = 17}
local target = {
	UserId = 23, MembershipType = {Name = "None"},
	AutoJumpEnabled = false, CameraMaxZoomDistance = 128, CameraMinZoomDistance = 0.5,
	GetJoinData = function() return {SourcePlaceId = 123} end,
	IsVerified = function() return false end,
}
local payload, output, pending, requests = nil, nil, {}, 0
local isAdmin = true
local env = setmetatable({
	Settings = {PlayerPrefix = "!", SplitKey = " "},
	Admin = {
		CheckAdmin = function() return isAdmin end,
		GetLevel = function() return 0, "Players" end,
		IsMuted = function() return false end,
		CheckDonor = function() return false end,
	},
	Functions = {GetMainPrefix = function() return ":" end},
	Remote = {
		Get = function(player, kind, name)
			assert(player == target and kind == "Function", "Profile queried the wrong client")
			if name == "GetUserInputServiceData" then requests += 1; return payload end
			assert(name == "GetFriendsOnline", "Unexpected profile request")
			return {}
		end,
		RemoveGui = function() end,
		MakeGui = function(player, gui, data)
			assert((player == viewer or player == target) and gui == "Profile", "Profile response changed its recipient or UI")
			output = data
		end,
	},
	service = {
		GetPlayers = function() return {target} end,
		PolicyService = {GetPolicyInfoForPlayerAsync = function() return {AreAdsAllowed = false} end},
		MarketplaceService = {PlayerOwnsAsset = function() return false end},
		TextChatService = {CanUserChatAsync = function() return true end},
	},
	Enum = {VerifiedLevel = {Low = 1, High = 2}},
	game = {PrivateServerOwnerId = -1},
	task = {defer = function(callback) table.insert(pending, callback) end},
}, {__index = getfenv()})
local source = fs.readFile("MainModule/Server/Commands/Players.luau")
local definition = assert(source:match("\n\t\tViewProfile = {(.-)\n\t\t};"), "Missing profile command")
local profile = luau.load("return {" .. definition .. "}", {environment = env})()
local uiSource = fs.readFile("MainModule/Client/UI/Default/Profile.luau")
local uiFirst = assert(uiSource:find("\t\tlocal gameplayDataToDisplay = {", 1, true), "Missing game-tab rows")
local uiFinish = assert(uiSource:find("\n\t\tgametab:Add(\"TextButton\"", uiFirst, true), "Missing game-tab row boundary")
local boolSource = assert(uiSource:match("local function boolToStr%(bool%)(.-)\nend"), "Missing profile boolean display")

-- Executes the real deferred command handler with a controlled client response.
local function inspect(input, requester)
	payload, output, pending = input, nil, {}
	profile.Function(requester or viewer, {"target"})
	assert(#pending == 1, "Profile did not schedule exactly one target")
	pending[1]()
	assert(output and output.Target == target, "Profile response lost its target")
	return output.GameData
end

-- Runs the shipped game-tab row construction and captures the exact value labels.
local function render()
	local cells = {}
	local uiEnv = setmetatable({
		data = output, player = target, UDim2 = {new = function() return {} end},
		gametab = {Add = function(_, _, row)
			return {Add = function(_, _, properties) cells[row.Text] = properties.Text end}
		end},
	}, {__index = getfenv()})
	luau.load("local function boolToStr(bool)" .. boolSource .. "\nend\n" .. uiSource:sub(uiFirst, uiFinish - 1), {environment = uiEnv})()
	for _, value in cells do assert(value ~= secret, "Raw client text reached a profile value label") end
	return cells
end

local forged = inspect({
	AdminLevel = secret, SourcePlaceId = secret, IsMuted = true,
	Resolution = secret, MouseDeltaSensitivity = secret, KeyboardEnabled = secret,
	Unexpected = secret, Nested = {Text = secret},
})
assert(forged.AdminLevel == "[0] Players" and forged.SourcePlaceId == 123 and forged.IsMuted == false, "Client overwrote server-owned profile facts")
assert(forged.Unexpected == nil and forged.Nested == nil and forged[1] == nil, "Unknown client fields entered the profile payload")
assert(forged.Resolution == "Unknown" and forged.MouseDeltaSensitivity == "Unknown" and forged.KeyboardEnabled == nil, "Invalid telemetry did not fail closed")
local cells = render()
assert(cells["  Admin Level: "] == "[0] Players" and cells["  Source Place ID: "] == 123 and cells["  Muted: "] == "No", "Server-owned facts changed at the UI boundary")

local booleanFields = {"AccelerometerEnabled", "GamepadEnabled", "GyroscopeEnabled", "KeyboardEnabled", "MouseEnabled", "OnScreenKeyboardVisible", "TouchEnabled", "VREnabled"}
local inputs = {MouseDeltaSensitivity = 1.25}
for index, key in booleanFields do inputs[key] = index % 2 == 0 end
local clientSource = fs.readFile("MainModule/Client/Core/Functions.luau")
local producerSource = assert(clientSource:match("GetUserInputServiceData = (function.-\n\t\tend);"), "Missing profile client producer")
local produce = luau.load("return " .. producerSource, {environment = setmetatable({
	service = {UserInputService = inputs}, workspace = {CurrentCamera = {ViewportSize = {X = 1920.75, Y = 1080.25}}},
}, {__index = getfenv()})})()
local valid = inspect(produce())
assert(valid.Resolution == "1920 x 1080" and valid.MouseDeltaSensitivity == 1.25, "Legitimate producer values changed")
for _, key in booleanFields do assert(valid[key] == inputs[key], "Boolean telemetry changed: " .. key) end
cells = render()
assert(cells["  Render Resolution: "] == "1920 x 1080" and cells["  Mouse Delta Sensitivity: "] == 1.25, "Legitimate telemetry did not reach the actual value labels")

for _, invalid in {secret, {}, true, -1, 11, math.huge, -math.huge, 0 / 0} do
	local data = inspect({MouseDeltaSensitivity = invalid})
	assert(data.MouseDeltaSensitivity == "Unknown", "Invalid sensitivity was accepted")
end
for _, validNumber in {0, 0.5, 10} do
	assert(inspect({MouseDeltaSensitivity = validNumber}).MouseDeltaSensitivity == validNumber, "Valid sensitivity boundary was rejected")
end
for _, invalid in {secret, {}, true, 1920, "1920x1080", "1920 x 1080 RAW", "1.5 x 1080", "-1 x 1080", "65536 x 1080", "1920 x 65536", "inf x 1080", "1e3 x 1080", string.rep("9", 1000) .. " x 1"} do
	assert(inspect({Resolution = invalid}).Resolution == "Unknown", "Invalid resolution was accepted")
end
for _, validResolution in {"0 x 0", "65535 x 65535", "7680 x 4320"} do
	assert(inspect({Resolution = validResolution}).Resolution == validResolution, "Valid resolution boundary was rejected")
end
for _, invalid in {secret, 0, 1, {}, math.huge, 0 / 0} do
	local input = {}
	for _, key in booleanFields do input[key] = invalid end
	local data = inspect(input)
	for _, key in booleanFields do assert(data[key] == nil, "Nonboolean capability was accepted: " .. key) end
end
for _, invalid in {false, secret, 7} do
	local data = inspect(invalid)
	assert(data.Resolution == "Unknown" and data.MouseDeltaSensitivity == "Unknown", "Malformed response removed fixed telemetry fallbacks")
	render()
end
assert(inspect(nil).Resolution == "Unknown", "Missing response removed the resolution fallback")
local before = requests
isAdmin = false
assert(inspect(produce()) == nil and requests == before, "A non-admin retrieved another player's private telemetry")
assert(inspect(produce(), target).Resolution == "1920 x 1080" and requests == before + 1, "Self-profile telemetry stopped working")
print("Profile data contracts passed: real producer/handler/UI, protected server facts, strict telemetry types/bounds, malformed responses and viewer permissions")
