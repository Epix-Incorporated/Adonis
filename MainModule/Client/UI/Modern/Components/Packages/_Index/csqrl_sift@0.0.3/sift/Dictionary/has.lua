--!strict
local _T = require(script.Parent.Parent.Types)

--[=[
  @function has
  @within Dictionary

  @param dictionary {[K]: V} -- The dictionary to check.
  @param key any -- The key to check for.
  @return boolean -- Whether or not the dictionary has the given key.

  Checks whether or not the given dictionary has the given key.

  ```lua
  local dictionary = { hello = "roblox", goodbye = "world" }

  local hasHello = Has(dictionary, "hello") -- true
  local hasCat = Has(dictionary, "cat") -- false
  ```
]=]
local function has(dictionary: _T.AnyDictionary, key: any): boolean
	return dictionary[key] ~= nil
end

return has
