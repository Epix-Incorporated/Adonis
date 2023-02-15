--!strict
local Copy = require(script.Parent.copy)

--[=[
	@function sort
	@within Array

	@param array {T} -- The array to sort.
	@param comparator? (a: T, b: T) -> boolean -- The comparator function.
	@return {T} -- The sorted array.

	Sorts an array.

	```lua
	local array = { "a", "b", "c", "d", "e" }

	local new = Sort(array, function(a, b)
		return a > b
	end) -- { "e", "d", "c", "b", "a" }
	```
]=]
local function sort<T>(array: { T }, comparator: ((firstValue: T, secondValue: T) -> boolean)?): { T }
	local result = Copy(array)

	table.sort(result, comparator)

	return result
end

return sort
