--!strict
local Find = require(script.Parent.find)

--[=[
	@function includes
	@within Array

	@param array {T} -- The array to search.
	@param value any -- The value to search for.
	@param from? number -- The index to start searching from.
	@return boolean -- Whether the array contains the value.

	Checks whether the array contains the value. This is a wrapper
	around `Find`.

	#### Aliases

	`contains`, `has`

	```lua
	local array = { "hello", "world", "goodbye" }

	local value = Includes(array, "hello") -- true
	local value = Includes(array, "sift") -- false
	local value = Includes(array, "hello", 2) -- false
	```
]=]
local function includes<T>(array: { T }, value: any, from: number?): boolean
	return Find(array, value, from) ~= nil
end

return includes
