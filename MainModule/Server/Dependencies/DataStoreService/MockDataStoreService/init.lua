--[[
	MockDataStoreService.lua
	This module implements the API and functionality of Roblox's DataStoreService class.

	This module is licensed under APLv2, refer to the LICENSE file or:
	buildthomas/MockDataStoreService/blob/master/LICENSE
]]

local MockDataStoreService = {}

local MockDataStoreManager = require(script.MockDataStoreManager)
local MockGlobalDataStore = require(script.MockGlobalDataStore)
local MockOrderedDataStore = require(script.MockOrderedDataStore)
local Utils = require(script.MockDataStoreUtils)
local Constants = require(script.MockDataStoreConstants)
local HttpService = game:GetService("HttpService") -- for json encode/decode

local function makeGetWrapper(methodName, getObject, isGlobal) -- Helper function to reduce amount of redundant code
	return function(_, name, scope)
		if not game:GetService("RunService"):IsServer() then
			error("DataStore can't be accessed from client", 2)
		end

		if isGlobal then
			return getObject()
		else
			if type(name) ~= "string" then
				error(("bad argument #1 to '%s' (string expected, got %s)")
					:format(methodName, typeof(name)), 2)
			elseif scope ~= nil and type(scope) ~= "string" then
				error(("bad argument #2 to '%s' (string expected, got %s)")
					:format(methodName, typeof(scope)), 2)
			elseif #name == 0 then
				error(("bad argument #1 to '%s' (name can't be empty string)")
					:format(methodName), 2)
			elseif #name > Constants.MAX_LENGTH_NAME then
				error(("bad argument #1 to '%s' (name exceeds %d character limit)")
					:format(methodName, Constants.MAX_LENGTH_NAME), 2)
			elseif scope and #scope == 0 then
				error(("bad argument #2 to '%s' (scope can't be empty string)")
					:format(methodName), 2)
			elseif scope and #scope > Constants.MAX_LENGTH_SCOPE then
				error(("bad argument #2 to '%s' (scope exceeds %d character limit)")
					:format(methodName, Constants.MAX_LENGTH_SCOPE), 2)
			end
			return getObject(name, scope or "global")
		end

	end
end

MockDataStoreService.GetGlobalDataStore = makeGetWrapper(
	"GetGlobalDataStore",
    function()
        local data = MockDataStoreManager.GetGlobalData()

        local interface = MockDataStoreManager.GetDataInterface(data)
        if interface then
            return interface
        end

        local value = {
			__type = "GlobalDataStore";
            __data = data; -- Mapping from <key> to <value>
            __event = Instance.new("BindableEvent"); -- For OnUpdate
			__writeCache = {};
			__writeLock = {};
			__getCache = {};
        }
        interface = setmetatable(value, MockGlobalDataStore)
		MockDataStoreManager.SetDataInterface(data, interface)

		return interface
	end,
	true -- This is the global datastore, no name/scope needed
)

MockDataStoreService.GetDataStore = makeGetWrapper(
	"GetDataStore",
	function(name, scope)
        local data = MockDataStoreManager.GetData(name, scope)

        local interface = MockDataStoreManager.GetDataInterface(data)
        if interface then
            return interface
        end

        local value = {
			__type = "GlobalDataStore";
            __name = name;
            __scope = scope;
            __data = data; -- Mapping from <key> to <value>
            __event = Instance.new("BindableEvent"); -- For OnUpdate
			__writeCache = {};
			__writeLock = {};
			__getCache = {};
        }
        interface = setmetatable(value, MockGlobalDataStore)
		MockDataStoreManager.SetDataInterface(data, interface)

        return interface
	end
)

MockDataStoreService.GetOrderedDataStore = makeGetWrapper(
	"GetOrderedDataStore",
	function(name, scope)
        local data = MockDataStoreManager.GetOrderedData(name, scope)

        local interface = MockDataStoreManager.GetDataInterface(data)
        if interface then
            return interface
        end

        local value = {
			__type = "OrderedDataStore";
            __name = name;
            __scope = scope;
            __data = data; -- Mapping from <key> to <value>
            __sorted = {}; -- List of {Key = <key>, Value = <value>} pairs
            __ref = {}; -- Mapping from <key> to corresponding {Key = <key>, Value = <value>} entry in __sorted
            __changed = false; -- Whether __sorted is guaranteed sorted at the moment
            __event = Instance.new("BindableEvent"); -- For OnUpdate
			__writeCache = {};
			__writeLock = {};
			__getCache = {};
        }
        interface = setmetatable(value, MockOrderedDataStore)
		MockDataStoreManager.SetDataInterface(data, interface)

		return interface
	end
)

local DataStoreRequestTypes = {}

for _, Enumerator in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
	DataStoreRequestTypes[Enumerator] = Enumerator
	DataStoreRequestTypes[Enumerator.Name] = Enumerator
	DataStoreRequestTypes[Enumerator.Value] = Enumerator
end

function MockDataStoreService:GetRequestBudgetForRequestType(requestType) -- luacheck: ignore self
	if not DataStoreRequestTypes[requestType] then
		error(("bad argument #1 to 'GetRequestBudgetForRequestType' (unable to cast '%s' of type %s to DataStoreRequestType)")
			:format(tostring(requestType), typeof(requestType)), 2)
	end

	return MockDataStoreManager.GetBudget(DataStoreRequestTypes[requestType])
end

function MockDataStoreService:ImportFromJSON(json, verbose) -- luacheck: ignore self
	local content
	if type(json) == "string" then
		local parsed, value = pcall(function() return HttpService:JSONDecode(json) end)
		if not parsed then
			error("bad argument #1 to 'ImportFromJSON' (string is not valid json)", 2)
		end
		content = value
	elseif type(json) == "table" then
		content = Utils.deepcopy(json)
	else
		error(("bad argument #1 to 'ImportFromJSON' (string or table expected, got %s)"):format(typeof(json)), 2)
	end
	if verbose ~= nil and type(verbose) ~= "boolean" then
		error(("bad argument #2 to 'ImportFromJSON' (boolean expected, got %s)"):format(typeof(verbose)), 2)
	end

	return MockDataStoreManager.ImportFromJSON(content, verbose)
end

function MockDataStoreService:ExportToJSON() -- luacheck: ignore self
	return MockDataStoreManager.ExportToJSON()
end

return MockDataStoreService
