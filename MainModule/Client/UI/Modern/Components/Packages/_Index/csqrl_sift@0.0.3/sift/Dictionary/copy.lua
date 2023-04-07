--!strict
--[=[
  @function copy
  @within Dictionary

  @param dictionary T -- The dictionary to copy.
  @return T -- The copied dictionary.

  Copies a dictionary.

  ```lua
  local dictionary = { hello = "world" }

  local new = Copy(dictionary) -- { hello = "world" }

  print(new == dictionary) -- false
  print(new.hello == dictionary.hello) -- true
  ```
]=]
return table.clone
