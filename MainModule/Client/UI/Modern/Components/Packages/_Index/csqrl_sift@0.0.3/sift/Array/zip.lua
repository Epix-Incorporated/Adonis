--!strict
local Reduce = require(script.Parent.reduce)

--[=[
	@function zip
	@within Array

	@param ... {any} -- The arrays to zip together.
	@return {any} -- The zipped array.

	Zips multiple arrays together into a single array.

	```lua
	local table1 = { 1, 2, 3 }
	local table2 = { "hello", "world", "goodbye" }

	local new = Zip(table1, table2) -- { { 1, "hello" }, { 2, "world" }, { 3, "goodbye" } }
	```
]=]
local function zip<T>(...: { any }): T
	local argCount = select("#", ...)
	local arguments = { ... }

	local result = {}

	if argCount == 0 then
		return result
	end

	local minLength: number = Reduce(arguments, function(acc, val)
		return math.min(acc, #val)
	end, #arguments[1])

	for index = 1, minLength do
		local values = {}

		for _, argArray in ipairs(arguments) do
			table.insert(values, argArray[index])
		end

		table.insert(result, values)
	end

	return result
end

return zip
