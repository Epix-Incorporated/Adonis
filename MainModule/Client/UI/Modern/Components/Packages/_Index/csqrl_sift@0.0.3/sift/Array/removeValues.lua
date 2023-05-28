--!strict
local ToSet = require(script.Parent.toSet)

--[=[
	@function removeValues
	@within Array

	@param array {T} -- The array to remove values from.
	@param ... T -- The values to remove.
	@return {T} -- The array with the values removed.

	Removes values from an array.

	```lua
	local array = { "a", "b", "c", "c", "d", "e" }

	local new = RemoveValues(array, "c", "d") -- { "a", "b", "e" }
	```
]=]
local function removeValues<T>(array: { T }, ...: T): { T }
	local valueSet = ToSet({ ... })
	local result = {}

	for _, value in ipairs(array) do
		if not valueSet[value] then
			table.insert(result, value)
		end
	end

	return result
end

return removeValues
