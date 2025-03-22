--[[
	MockDataStoreUtils.lua
	Contains helper and utility functions used by other classes.

	This module is licensed under APLv2, refer to the LICENSE file or:
	buildthomas/MockDataStoreService/blob/master/LICENSE
]]

local MockDataStoreUtils = {}

local Constants = require(script.Parent.MockDataStoreConstants)
local HttpService = game:GetService("HttpService") -- for json encode/decode
local RunService = game:GetService("RunService")

local rand = Random.new()

local function shorten(s, num)
	if #s > num then
		return s:sub(1,num-2) .. ".."
	end
	return s
end

--[[
	[DataStore] [Name/Scope] [GetAsync] KEY
	[DataStore] [Name/Scope] [UpdateAsync] KEY => VALUE
	[DataStore] [Name/Scope] [SetAsync] KEY => VALUE
	[DataStore] [Name/Scope] [IncrementAsync] KEY by INCR => VALUE
	[DataStore] [Name/Scope] [RemoveAsync] KEY =/> VALUE
	[DataStore] [Name/Scope] [OnUpdate] KEY
	[DataStore] [Name/Scope] [GetSortedAsync]

	[OrderedDataStore] [Name/Scope] [GetAsync] KEY
	[OrderedDataStore] [Name/Scope] [UpdateAsync] KEY => VALUE
	[OrderedDataStore] [Name/Scope] [SetAsync] KEY => VALUE
	[OrderedDataStore] [Name/Scope] [IncrementAsync] KEY + INCR => VALUE
	[OrderedDataStore] [Name/Scope] [RemoveAsync] KEY =/> VALUE
	[OrderedDataStore] [Name/Scope] [OnUpdate] KEY
	[OrderedDataStore] [Name/Scope] [GetSortedAsync]

	[OrderedDataStore] [Name/Scope] [AdvanceToNextPageAsync]
]]

local function logMethod(self, method, key, value, increment)
	if not Constants.LOGGING_ENABLED or type(Constants.LOGGING_FUNCTION) ~= "function" then
		return
	end

	local name = self.__name
	local scope = self.__scope

	local prefix
	if not name then
		prefix = ("[GlobalDataStore] [%s]"):format(method)
	elseif not scope then
		prefix = ("[%s] [%s] [%s]"):format(self.__type, shorten(name, 20), method)
	else
		prefix = ("[%s] [%s/%s] [%s]"):format(self.__type, shorten(name, 15), shorten(scope, 15), method)
	end

	local message
	if value and increment then
		message = key .. " + " .. tostring(increment) .. " => " .. tostring(value)
	elseif increment then
		message = key .. " + " .. tostring(increment)
	elseif value then
		if method == "RemoveAsync" then
			message = key .. " =/> " .. tostring(value)
		else
			message = key .. " => " .. tostring(value)
		end
	else
		message = "key"
	end

	Constants.LOGGING_FUNCTION(prefix .. " " .. message)

end

local function deepcopy(t)
	if type(t) == "table" then
		local n = {}
		for i,v in pairs(t) do
			n[i] = deepcopy(v)
		end
		return n
	else
		return t
	end
end

local function scanValidity(tbl, passed, path) -- Credit to Corecii (edited)
	if type(tbl) ~= "table" then
		return scanValidity({input = tbl}, {}, {})
	end
	passed, path = passed or {}, path or {"root"}
	passed[tbl] = true
	local tblType
	do
		local key = next(tbl)
		if type(key) == "number" then
			tblType = "Array"
		else
			tblType = "Dictionary"
		end
	end
	local last = 0
	for key, value in next, tbl do
		path[#path + 1] = tostring(key)
		if type(key) == "number" then
			if tblType == "Dictionary" then
				return false, path, "cannot store mixed tables"
			elseif key % 1 ~= 0 then
				return false, path, "cannot store tables with non-integer indices"
			elseif key == math.huge or key == -math.huge then
				return false, path, "cannot store tables with (-)infinity indices"
			end
		elseif type(key) ~= "string" then
			return false, path, "dictionaries cannot have keys of type " .. typeof(key)
		elseif tblType == "Array" then
			return false, path, "cannot store mixed tables"
		elseif not utf8.len(key) then
			return false, path, "dictionary has key that is invalid UTF-8"
		end
		if tblType == "Array" then
			if last ~= key - 1 then
				return false, path, "array has non-sequential indices"
			end
			last = key
		end
		if type(value) == "userdata" or type(value) == "function" or type(value) == "thread" then
			return false, path, "cannot store value '" .. tostring(value) .. "' of type " .. typeof(value)
		elseif type(value) == "string" and not utf8.len(value) then
			return false, path, "cannot store strings that are invalid UTF-8"
		end
		if type(value) == "table" then
			if passed[value] then
				return false, path, "cannot store cyclic tables"
			end
			local isValid, keyPath, reason = scanValidity(value, passed, path)
			if not isValid then
				return isValid, keyPath, reason
			end
		end
		path[#path] = nil
	end
	passed[tbl] = nil
	return true
end

local function getStringPath(path)
	return table.concat(path, '.')
end

-- Import into a single datastore:
local function importPairsFromTable(origin, destination, interface, warnFunc, methodName, prefix, isOrdered)
	for key, value in pairs(origin) do
		if type(key) ~= "string" then
			warnFunc(("%s: ignored %s > '%s' (key is not a string, but a %s)")
				:format(methodName, prefix, tostring(key), typeof(key)))
		elseif not utf8.len(key) then
			warnFunc(("%s: ignored %s > '%s' (key is not valid UTF-8)")
				:format(methodName, prefix, tostring(key)))
		elseif #key > Constants.MAX_LENGTH_KEY then
			warnFunc(("%s: ignored %s > '%s' (key exceeds %d character limit)")
				:format(methodName, prefix, key, Constants.MAX_LENGTH_KEY))
		elseif type(value) == "string" and #value > Constants.MAX_LENGTH_DATA then
			warnFunc(("%s: ignored %s > '%s' (length of value exceeds %d character limit)")
				:format(methodName, prefix, key, Constants.MAX_LENGTH_DATA))
		elseif type(value) == "table" and #HttpService:JSONEncode(value) > Constants.MAX_LENGTH_DATA then
			warnFunc(("%s: ignored %s > '%s' (length of encoded value exceeds %d character limit)")
				:format(methodName, prefix, key, Constants.MAX_LENGTH_DATA))
		elseif type(value) == "function" or type(value) == "userdata" or type(value) == "thread" then
			warnFunc(("%s: ignored %s > '%s' (cannot store value '%s' of type %s)")
				:format(methodName, prefix, key, tostring(value), type(value)))
		elseif isOrdered and type(value) ~= "number" then
			warnFunc(("%s: ignored %s > '%s' (cannot store value '%s' of type %s in OrderedDataStore)")
				:format(methodName, prefix, key, tostring(value), type(value)))
		elseif isOrdered and value % 1 ~= 0 then
			warnFunc(("%s: ignored %s > '%s' (cannot store non-integer value '%s' in OrderedDataStore)")
				:format(methodName, prefix, key, tostring(value)))
		elseif type(value) == "string" and not utf8.len(value) then
			warnFunc(("%s: ignored %s > '%s' (string value is not valid UTF-8)")
				:format(methodName, prefix, key, tostring(value), type(value)))
		else
			local isValid = true
			local keyPath, reason
			if type(value) == "table" then
				isValid, keyPath, reason = scanValidity(value)
			end
			if isOrdered then
				value = math.floor(value + .5)
			end
			if isValid then
				local old = destination[key]
				destination[key] = value
				if interface and old ~= value then -- hacky block to fire OnUpdate signals
					if isOrdered and interface then -- hacky block to populate internal structures for OrderedDataStores
						if interface.__ref[key] then
							interface.__ref[key].Value = value
							interface.__changed = true
						else
							interface.__ref[key] = {Key = key, Value = interface.__data[key]}
							table.insert(interface.__sorted, interface.__ref[key])
							interface.__changed = true
						end
					end
					interface.__event:Fire(key, value)
				end
			else
				warnFunc(("%s: ignored %s > '%s' (table has invalid entry at <%s>: %s)")
					:format(methodName, prefix, key, getStringPath(keyPath), reason))
			end
		end
	end
end

-- Trim empty datastores and scopes from an entire datastore type:
local function prepareDataStoresForExport(origin)
	local dataPrepared = {}

	for name, scopes in pairs(origin) do
		local exportScopes = {}
		for scope, data in pairs(scopes) do
			local exportData = table.clone(data)
			if next(exportData) ~= nil then -- Only export datastore when non-empty
				exportScopes[scope] = exportData
			end
		end
		if next(exportScopes) ~= nil then -- Only export scope list when non-empty
			dataPrepared[name] = exportScopes
		end
	end

	if next(dataPrepared) ~= nil then -- Only return datastore type when non-empty
		return dataPrepared
	end
end

local function preprocessKey(key)
	if type(key) == "number" then
		if key ~= key then
			return "NAN"
		elseif key >= math.huge then
			return "INF"
		elseif key <= -math.huge then
			return "-INF"
		end
		return tostring(key)
	end
	return key
end

local function simulateYield()
	if Constants.YIELD_TIME_MAX > 0 then
		task.wait(rand:NextNumber(Constants.YIELD_TIME_MIN, Constants.YIELD_TIME_MAX))
	end
end

local function simulateErrorCheck(method)
	if Constants.SIMULATE_ERROR_RATE > 0 and rand:NextNumber() <= Constants.SIMULATE_ERROR_RATE then
		simulateYield()
		error(method .. " rejected with error (simulated error)", 3)
	end
end

-- Setting these here so the functions above can self-reference just by name:
MockDataStoreUtils.logMethod = logMethod
MockDataStoreUtils.deepcopy = deepcopy
MockDataStoreUtils.scanValidity = scanValidity
MockDataStoreUtils.getStringPath = getStringPath
MockDataStoreUtils.importPairsFromTable = importPairsFromTable
MockDataStoreUtils.prepareDataStoresForExport = prepareDataStoresForExport
MockDataStoreUtils.preprocessKey = preprocessKey
MockDataStoreUtils.simulateYield = simulateYield
MockDataStoreUtils.simulateErrorCheck = simulateErrorCheck

return MockDataStoreUtils
