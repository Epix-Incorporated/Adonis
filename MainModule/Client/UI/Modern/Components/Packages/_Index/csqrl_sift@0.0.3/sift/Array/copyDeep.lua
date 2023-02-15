--!strict
--[=[
	@function copyDeep
	@within Array

	@param array {T} -- The array to copy.
	@return {T} -- The copied array.

	Copies an array, with deep copies of all nested arrays.

	```lua
	local array = { 1, 2, 3, { 4, 5 } }

	local result = CopyDeep(array) -- { 1, 2, 3, { 4, 5 } }

	print(result == array) -- false
	print(result[4] == array[4]) -- false
	```
]=]
local function copyDeep<T>(array: { T }): { T }
	local result = {}

	for _, value in ipairs(array) do
		if type(value) == "table" then
			table.insert(result, copyDeep(value))
		else
			table.insert(result, value)
		end
	end

	return result
end

return copyDeep
