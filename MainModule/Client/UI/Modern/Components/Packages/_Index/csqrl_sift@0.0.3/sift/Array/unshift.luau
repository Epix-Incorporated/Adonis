--!strict
--[=[
	@function unshift
	@within Array

	@param array {T} -- The array to insert the values to.
	@param ... ...T -- The values to insert.
	@return {T} -- The array with the values inserted.

	Inserts values to the beginning of an array.

	#### Aliases

	`prepend`

	```lua
	local array = { 1, 2, 3 }

	local new = Unshift(array, 4, 5) -- { 4, 5, 1, 2, 3 }
	```
]=]
local function unshift<T>(array: { T }, ...: T): { T }
	local result = { ... }

	for _, value in ipairs(array) do
		table.insert(result, value)
	end

	return result
end

return unshift
