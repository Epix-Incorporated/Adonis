--!strict
local Sift = script.Parent.Parent

local Util = require(Sift.Util)

--[=[
	@function count
	@within Array

	@param array {T} -- The array to count the number of items in.
	@param predicate? (value: T, index: number, array: {T}) -> any -- The predicate to use to filter the array.
	@return number -- The number of items in the array.

	Counts the number of items in an array.

	```lua
	local array = { 1, 2, 3 }

	local value = Count(array) -- 3
	local value = Count(array, function(item, index)
		return item == 2
	end) -- 1
	```
]=]
local function count<T>(array: { T }, predicate: ((value: T, index: number, array: { T }) -> any)?): number
	local counter = 0

	predicate = if type(predicate) == "function" then predicate else Util.func.truthy

	for index, value in ipairs(array) do
		if predicate(value, index, array) then
			counter += 1
		end
	end

	return counter
end

return count
