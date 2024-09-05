--!strict
--[=[
	@function freezeDeep
	@within Array

	@param array {T} -- The array to freeze.
	@return {T} -- The frozen array.

	Freezes the entire array, making it read-only, including all
	nested arrays.

	```lua
	local array = { 1, 2, 3, { 4, 5, 6 } }

	local new = FreezeDeep(array)

	new[1] = 4 -- error!
	new[4][1] = 7 -- error!
	```
]=]
local function freezeDeep<T>(array: { T }): { T }
	local result = {}

	for i = 1, #array do
		local value = array[i]

		if type(value) == "table" then
			table.insert(result, freezeDeep(value))
		else
			table.insert(result, value)
		end
	end

	table.freeze(result)

	return result
end

return freezeDeep
