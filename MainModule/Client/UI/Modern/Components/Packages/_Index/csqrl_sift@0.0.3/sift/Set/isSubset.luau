--!strict
--[=[
  @function isSubset
  @within Set

  @param subset { [any]: boolean } -- The subset to check.
  @param superset { [any]: boolean } -- The superset to check against.
  @return boolean -- Whether the subset is a subset of the superset.

  Checks whether a set is a subset of another set.

  ```lua
  local set = { hello = true, world = true }
  local subset = { hello = true }

  local isSubset = IsSubset(subset, set) -- true
  ```
]=]
local function isSubset(subset: { [any]: boolean }, superset: { [any]: boolean }): boolean
	for key, value in pairs(subset) do
		if superset[key] ~= value then
			return false
		end
	end

	return true
end

return isSubset
