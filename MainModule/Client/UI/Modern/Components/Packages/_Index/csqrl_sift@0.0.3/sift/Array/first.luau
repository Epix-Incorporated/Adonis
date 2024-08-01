--!strict
local At = require(script.Parent.at)

--[=[
	@function first
	@within Array

	@param array {T} -- The array to get the first item from.
	@return T -- The first item in the array.

	Gets the first item in the array.

	```lua
	local array = { 1, 2, 3 }

	local value = First(array) -- 1
	```
]=]
local function first<T>(array: { T }): T
	return At(array, 1)
end

return first
