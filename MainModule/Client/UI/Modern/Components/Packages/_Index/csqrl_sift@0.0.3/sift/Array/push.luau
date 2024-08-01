--!strict
--[=[
	@function push
	@within Array

	@param array {T} -- The array to push an element to.
	@param ... ...T -- The elements to push.
	@return {T} -- The array with the pushed elements.

	Adds elements to the end of the array.

	#### Aliases

	`append`

	```lua
	local array = { 1, 2, 3 }

	local new = Push(array, 4, 5, 6) -- { 1, 2, 3, 4, 5, 6 }
	```
]=]
local function push<T>(array: { T }, ...: T): { T }
	local result = {}

	for index, value in ipairs(array) do
		table.insert(result, value)
	end

	for _, value in ipairs({ ... }) do
		table.insert(result, value)
	end

	return result
end

return push
