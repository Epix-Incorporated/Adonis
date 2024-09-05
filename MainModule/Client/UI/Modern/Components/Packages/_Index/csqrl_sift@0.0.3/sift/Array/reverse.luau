--!strict
--[=[
	@function reverse
	@within Array

	@param array {T} -- The array to reverse.
	@return {T} -- The reversed array.

	Reverses the order of the items in an array.

	```lua
	local array = { 1, 2, 3 }

	local new = Reverse(array) -- { 3, 2, 1 }
	```
]=]
local function reverse<T>(array: { T }): { T }
	local result = {}

	for index = #array, 1, -1 do
		table.insert(result, array[index])
	end

	return result
end

return reverse
