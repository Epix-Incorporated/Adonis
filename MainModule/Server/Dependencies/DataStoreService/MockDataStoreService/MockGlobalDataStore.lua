--[[
	MockGlobalDataStore.lua
	This module implements the API and functionality of Roblox's GlobalDataStore class.

	This module is licensed under APLv2, refer to the LICENSE file or:
	buildthomas/MockDataStoreService/blob/master/LICENSE
]]

local MockGlobalDataStore = {}
MockGlobalDataStore.__index = MockGlobalDataStore

local MockDataStoreManager = require(script.Parent.MockDataStoreManager)
local Utils = require(script.Parent.MockDataStoreUtils)
local Constants = require(script.Parent.MockDataStoreConstants)
local HttpService = game:GetService("HttpService") -- for json encode/decode

local rand = Random.new()

function MockGlobalDataStore:OnUpdate(key, callback)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'OnUpdate' (string expected, got %s)"):format(typeof(key)), 2)
	elseif type(callback) ~= "function" then
		error(("bad argument #2 to 'OnUpdate' (function expected, got %s)"):format(typeof(callback)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'OnUpdate' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'OnUpdate' (key name exceeds %d character limit)"):format(Constants.MAX_LENGTH_KEY), 2)
	end

	Utils.simulateErrorCheck("OnUpdate")

	local success = MockDataStoreManager.YieldForBudget(
		function()
			warn(("OnUpdate request was throttled due to lack of budget. Try sending fewer requests. Key = %s"):format(key))
		end,
		{Enum.DataStoreRequestType.OnUpdate}
	)

	if not success then
		error("OnUpdate rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	Utils.logMethod(self, "OnUpdate", key)

	return self.__event.Event:Connect(function(k, v)
		if k == key then
			if Constants.YIELD_TIME_UPDATE_MAX > 0 then
				task.wait(rand:NextNumber(Constants.YIELD_TIME_UPDATE_MIN, Constants.YIELD_TIME_UPDATE_MAX))
			end
			callback(v) -- v was implicitly deep-copied
		end
	end)
end

function MockGlobalDataStore:GetAsync(key)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'GetAsync' (string expected, got %s)"):format(typeof(key)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'GetAsync' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'GetAsync' (key name exceeds %d character limit)"):format(Constants.MAX_LENGTH_KEY), 2)
	end

	if self.__getCache[key] and tick() - self.__getCache[key] < Constants.GET_COOLDOWN then
		return Utils.deepcopy(self.__data[key])
	end

	Utils.simulateErrorCheck("GetAsync")

	local success = MockDataStoreManager.YieldForBudget(
		function()
			warn(("GetAsync request was throttled due to lack of budget. Try sending fewer requests. Key = %s"):format(key))
		end,
		{Enum.DataStoreRequestType.GetAsync}
	)

	if not success then
		error("GetAsync rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	self.__getCache[key] = tick()

	local retValue = Utils.deepcopy(self.__data[key])

	Utils.simulateYield()

	Utils.logMethod(self, "GetAsync", key)

	return retValue
end

function MockGlobalDataStore:IncrementAsync(key, delta)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'IncrementAsync' (string expected, got %s)"):format(typeof(key)), 2)
	elseif delta ~= nil and type(delta) ~= "number" then
		error(("bad argument #2 to 'IncrementAsync' (number expected, got %s)"):format(typeof(delta)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'IncrementAsync' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'IncrementAsync' (key name exceeds %d character limit)")
			:format(Constants.MAX_LENGTH_KEY), 2)
	end

	Utils.simulateErrorCheck("IncrementAsync")

	local success

	if self.__writeLock[key] or tick() - (self.__writeCache[key] or 0) < Constants.WRITE_COOLDOWN then
		success = MockDataStoreManager.YieldForWriteLockAndBudget(
			function()
				warn(("IncrementAsync request was throttled, a key can only be written to once every %d seconds. Key = %s")
					:format(Constants.WRITE_COOLDOWN, key))
			end,
			key,
			self.__writeLock,
			self.__writeCache,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
	else
		self.__writeLock[key] = true
		success = MockDataStoreManager.YieldForBudget(
			function()
				warn(("IncrementAsync request was throttled due to lack of budget. Try sending fewer requests. Key = %s")
					:format(key))
			end,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
		self.__writeLock[key] = nil
	end

	if not success then
		error("IncrementAsync rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	local old = self.__data[key]

	if old ~= nil and (type(old) ~= "number" or old % 1 ~= 0) then
		Utils.simulateYield()
		error("IncrementAsync rejected with error (cannot increment non-integer value)", 2)
	end

	self.__writeLock[key] = true

	delta = delta and math.floor(delta + .5) or 1

	self.__data[key] = (old or 0) + delta

	if old == nil or delta ~= 0 then
		self.__event:Fire(key, self.__data[key])
	end

	local retValue = self.__data[key]

	Utils.simulateYield()

	self.__writeLock[key] = nil
	self.__writeCache[key] = tick()

	self.__getCache[key] = tick()

	Utils.logMethod(self, "IncrementAsync", key, retValue, delta)

	return retValue
end

function MockGlobalDataStore:RemoveAsync(key)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'RemoveAsync' (string expected, got %s)"):format(typeof(key)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'RemoveAsync' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'RemoveAsync' (key name exceeds %d character limit)"):format(Constants.MAX_LENGTH_KEY), 2)
	end

	Utils.simulateErrorCheck("RemoveAsync")

	local success

	if self.__writeLock[key] or tick() - (self.__writeCache[key] or 0) < Constants.WRITE_COOLDOWN then
		success = MockDataStoreManager.YieldForWriteLockAndBudget(
			function()
				warn(("RemoveAsync request was throttled, a key can only be written to once every %d seconds. Key = %s")
					:format(Constants.WRITE_COOLDOWN, key))
			end,
			key,
			self.__writeLock,
			self.__writeCache,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
	else
		self.__writeLock[key] = true
		success = MockDataStoreManager.YieldForBudget(
			function()
				warn(("RemoveAsync request was throttled due to lack of budget. Try sending fewer requests. Key = %s")
					:format(key))
			end,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
		self.__writeLock[key] = nil
	end

	if not success then
		error("RemoveAsync rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	self.__writeLock[key] = true

	local value = Utils.deepcopy(self.__data[key])
	self.__data[key] = nil

	if value ~= nil then
		self.__event:Fire(key, nil)
	end

	Utils.simulateYield()

	self.__writeLock[key] = nil
	self.__writeCache[key] = tick()

	Utils.logMethod(self, "RemoveAsync", key, value)

	return value
end

function MockGlobalDataStore:SetAsync(key, value)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'SetAsync' (string expected, got %s)"):format(typeof(key)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'SetAsync' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'SetAsync' (key name exceeds %d character limit)"):format(Constants.MAX_LENGTH_KEY), 2)
	elseif value == nil or type(value) == "function" or type(value) == "userdata" or type(value) == "thread" then
		error(("bad argument #2 to 'SetAsync' (cannot store value '%s' of type %s)")
			:format(tostring(value), typeof(value)), 2)
	end

	if type(value) == "table" then
		local isValid, keyPath, reason = Utils.scanValidity(value)
		if not isValid then
			error(("bad argument #2 to 'SetAsync' (table has invalid entry at <%s>: %s)")
				:format(Utils.getStringPath(keyPath), reason), 2)
		end
		local pass, content = pcall(function() return HttpService:JSONEncode(value) end)
		if not pass then
			error("bad argument #2 to 'SetAsync' (table could not be encoded to json)", 2)
		elseif #content > Constants.MAX_LENGTH_DATA then
			error(("bad argument #2 to 'SetAsync' (encoded data length exceeds %d character limit)")
				:format(Constants.MAX_LENGTH_DATA), 2)
		end
	elseif type(value) == "string" then
		if #value > Constants.MAX_LENGTH_DATA then
			error(("bad argument #2 to 'SetAsync' (data length exceeds %d character limit)")
				:format(Constants.MAX_LENGTH_DATA), 2)
		elseif not utf8.len(value) then
			error("bad argument #2 to 'SetAsync' (string value is not valid UTF-8)", 2)
		end
	end

	Utils.simulateErrorCheck("SetAsync")

	local success

	if self.__writeLock[key] or tick() - (self.__writeCache[key] or 0) < Constants.WRITE_COOLDOWN then
		success = MockDataStoreManager.YieldForWriteLockAndBudget(
			function()
				warn(("SetAsync request was throttled, a key can only be written to once every %d seconds. Key = %s")
					:format(Constants.WRITE_COOLDOWN, key))
			end,
			key,
			self.__writeLock,
			self.__writeCache,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
	else
		self.__writeLock[key] = true
		success = MockDataStoreManager.YieldForBudget(
			function()
				warn(("SetAsync request was throttled due to lack of budget. Try sending fewer requests. Key = %s")
					:format(key))
			end,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
		self.__writeLock[key] = nil
	end

	if not success then
		error("SetAsync rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	self.__writeLock[key] = true

	if type(value) == "table" or value ~= self.__data[key] then
		self.__data[key] = Utils.deepcopy(value)
		self.__event:Fire(key, self.__data[key])
	end

	Utils.simulateYield()

	self.__writeLock[key] = nil
	self.__writeCache[key] = tick()

	Utils.logMethod(self, "SetAsync", key, self.__data[key])

end

function MockGlobalDataStore:UpdateAsync(key, transformFunction)
	key = Utils.preprocessKey(key)
	if type(key) ~= "string" then
		error(("bad argument #1 to 'UpdateAsync' (string expected, got %s)"):format(typeof(key)), 2)
	elseif type(transformFunction) ~= "function" then
		error(("bad argument #2 to 'UpdateAsync' (function expected, got %s)"):format(typeof(transformFunction)), 2)
	elseif #key == 0 then
		error("bad argument #1 to 'UpdateAsync' (key name can't be empty)", 2)
	elseif #key > Constants.MAX_LENGTH_KEY then
		error(("bad argument #1 to 'UpdateAsync' (key name exceeds %d character limit)"):format(Constants.MAX_LENGTH_KEY), 2)
	end

	Utils.simulateErrorCheck("UpdateAsync")

	local success

	if self.__writeLock[key] or tick() - (self.__writeCache[key] or 0) < Constants.WRITE_COOLDOWN then
		success = MockDataStoreManager.YieldForWriteLockAndBudget(
			function()
				warn(("UpdateAsync request was throttled, a key can only be written to once every %d seconds. Key = %s")
					:format(Constants.WRITE_COOLDOWN, key))
			end,
			key,
			self.__writeLock,
			self.__writeCache,
			{Enum.DataStoreRequestType.SetIncrementAsync}
		)
	else
		self.__writeLock[key] = true
		local budget
		if self.__getCache[key] and tick() - self.__getCache[key] < Constants.GET_COOLDOWN then
			budget = {Enum.DataStoreRequestType.SetIncrementAsync}
		else
			budget = {Enum.DataStoreRequestType.GetAsync, Enum.DataStoreRequestType.SetIncrementAsync}
		end
		success = MockDataStoreManager.YieldForBudget(
			function()
				warn(("UpdateAsync request was throttled due to lack of budget. Try sending fewer requests. Key = %s")
					:format(key))
			end,
			budget
		)
		self.__writeLock[key] = nil
	end

	if not success then
		error("UpdateAsync rejected with error (request was throttled, but throttled queue was full)", 2)
	end

	local value = transformFunction(Utils.deepcopy(self.__data[key]))

	if value == nil then -- cancel update after remote call
		Utils.simulateYield()
		return nil -- this is what datastores do even though it should be old value
	end

	if type(value) == "function" or type(value) == "userdata" or type(value) == "thread" then
		error(("UpdateAsync rejected with error (resulting value '%s' is of type %s that cannot be stored)")
			:format(tostring(value), typeof(value)), 2)
	end

	if type(value) == "table" then
		local isValid, keyPath, reason = Utils.scanValidity(value)
		if not isValid then
			error(("UpdateAsync rejected with error (resulting table has invalid entry at <%s>: %s)")
				:format(Utils.getStringPath(keyPath), reason), 2)
		end
		local pass, content = pcall(function() return HttpService:JSONEncode(value) end)
		if not pass then
			error("UpdateAsync rejected with error (resulting table could not be encoded to json)", 2)
		elseif #content > Constants.MAX_LENGTH_DATA then
			error(("UpdateAsync rejected with error (resulting encoded data length exceeds %d character limit)")
				:format(Constants.MAX_LENGTH_DATA), 2)
		end
	elseif type(value) == "string" then
		if #value > Constants.MAX_LENGTH_DATA then
			error(("UpdateAsync rejected with error (resulting data length exceeds %d character limit)")
				:format(Constants.MAX_LENGTH_DATA), 2)
		elseif not utf8.len(value) then
			error("UpdateAsync rejected with error (string value is not valid UTF-8)", 2)
		end
	end

	self.__writeLock[key] = true

	if type(value) == "table" or value ~= self.__data[key] then
		self.__data[key] = Utils.deepcopy(value)
		self.__event:Fire(key, self.__data[key])
	end

	local retValue = Utils.deepcopy(value)

	self.__writeLock[key] = nil
	self.__writeCache[key] = tick()

	self.__getCache[key] = tick()

	Utils.logMethod(self, "UpdateAsync", key, retValue)

	return retValue
end

function MockGlobalDataStore:ExportToJSON()
	return HttpService:JSONEncode(self.__data)
end

function MockGlobalDataStore:ImportFromJSON(json, verbose)
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

	Utils.importPairsFromTable(
		content,
		self.__data,
		MockDataStoreManager.GetDataInterface(self.__data),
		(verbose == false and function() end or warn),
		"ImportFromJSON",
		((type(self.__name) == "string" and type(self.__scope) == "string")
			and ("DataStore > %s > %s"):format(self.__name, self.__scope)
			or "GlobalDataStore"),
		false
	)
end

return MockGlobalDataStore
