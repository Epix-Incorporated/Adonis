--!strict
local At = require(script.Parent.at)

--[=[
	@function last
	@within Array

	@param array {T} -- The array to get the last element of.
	@return T -- The last element of the array.

	Gets the last element of the array.

	```lua
	local array = { 1, 2, 3 }

	local value = Last(array) -- 3
	```
]=]
local function last<T>(array: { T }): T
	return At(array, 0)
end

return last
