--!strict
--[=[
	@function removeValue
	@within Array

	@param array {T} -- The array to remove the value from.
	@param value T -- The value to remove.
	@return {T} -- The array with the value removed.

	Removes a value from an array.

	```lua
	local array = { 1, 2, 3 }

	local new = RemoveValue(array, 2) -- { 1, 3 }
	```
]=]
local function removeValue<T>(array: { T }, value: T): { T }
	local result = {}

	for index, arrValue in ipairs(array) do
		if arrValue ~= value then
			table.insert(result, arrValue)
		end
	end

	return result
end

return removeValue
