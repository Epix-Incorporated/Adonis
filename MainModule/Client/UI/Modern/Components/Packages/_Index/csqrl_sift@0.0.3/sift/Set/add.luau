--!strict
--[=[
  @function add
  @within Set

  @param set { [T]: boolean } -- The set to add the value to.
  @param ... ...T -- The values to add.
  @return { [T]: boolean } -- The set with the values added.

  Adds values to a set.

  ```lua
  local set = { hello = true }

  local newSet = Add(set, "world") -- { hello = true, world = true }
  ```
]=]
local function add<T>(set: { [T]: boolean }, ...: T): { [T]: boolean }
	local result = {}

	for key, _ in pairs(set) do
		result[key] = true
	end

	for _, value in ipairs({ ... }) do
		result[value] = true
	end

	return result
end

return add
