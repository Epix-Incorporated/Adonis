--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

--[=[
	@function filter
	@within Array

	@param array {T} -- The array to filter.
	@param filterer? (value: T, index: number, array: {T}) -> any -- The callback to use to filter the array.
	@return {T} -- The filtered array.

	Filters an array using a filterer callback. Any items that do not pass the filterer will be removed from the array.

	If no filterer is provided, all items will be kept.

	```lua
	local array = { 1, 2, 3 }

	local result = Filter(array, function(item, index)
		return item > 1
	end) -- { 2, 3 }
	```
]=]
local function filter<T>(array: { T }, predicate: ((value: T, index: number, array: { T }) -> boolean?)?): { T }
	local result = {}

	predicate = if type(predicate) == "function" then predicate else Util.func.truthy

	for index, value in ipairs(array) do
		if predicate(value, index, array) then
			table.insert(result, value)
		end
	end

	return result
end

return filter
