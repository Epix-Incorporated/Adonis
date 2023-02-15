--!strict
--[=[
	@function pop
	@within Array

	@param array {T} -- The array to pop an element from.
	@param count? number = 1 -- The number of elements to pop.
	@return {T} -- An array with the popped elements removed.

	Removes an element from the end of the array, and returns
	the array with the popped elements removed.

	```lua
	local array = { 1, 2, 3 }

	local new = Pop(array) -- { 1, 2 }
	local new = Pop(array, 2) -- { 1 }
	```
]=]
local function pop<T>(array: { T }, count: number?): { T }
	local length = #array
	local result = {}

	count = if type(count) == "number" then count else 1

	for i = 1, length - count do
		table.insert(result, array[i])
	end

	return result
end

return pop
