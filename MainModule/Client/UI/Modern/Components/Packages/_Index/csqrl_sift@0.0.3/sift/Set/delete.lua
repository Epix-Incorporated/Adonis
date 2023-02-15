--!strict
--[=[
  @function delete
  @within Set

  @param set { [T]: boolean } -- The set to delete from.
  @param ... ...T -- The values to delete.
  @return { [T]: boolean } -- The set with the values deleted.

  Deletes values from a set.

  Aliases: `subtract`

  ```lua
  local set = { hello = true, world = true }

  local newSet = Delete(set, "hello") -- { world = true }
  ```
]=]
local function delete<T>(set: { [T]: boolean }, ...: T): { [T]: boolean }
	local result = {}

	for key, _ in pairs(set) do
		result[key] = true
	end

	for _, value in ipairs({ ... }) do
		result[value] = nil
	end

	return result
end

return delete
