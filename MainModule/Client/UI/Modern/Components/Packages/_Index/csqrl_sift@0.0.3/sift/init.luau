--!strict
local Types = require(script.Types)

--[=[
	@class Sift

	Sift is a library for manipulating arrays. It provides a number of
	functions for manipulating arrays (lists), dictionaries, and sets.

	Sift is comprised of a number of submodules. Each submodule provides
	a number of functions for manipulating a specific type of data, and
	can be accessed via their respective names within the Sift module
	(e.g. `Sift.Array.At()`), or accessed directly (e.g. `local At = require(Sift.Array.At)`).

	Some methods and modules also have aliases, which can are documented in the
	corresponding submodule/method's documentation.

	See the individual submodule pages for full documentation.

	The Luau types `Dictionary<K, V>`, `Array<T>` (aliased as `List<T>`) and `Set<T>` are exported from the Sift module (e.g. they can be used via `Sift.Array<string>`), but are also available from [Sift.Types].
]=]
local Sift = {
	Array = require(script.Array),
	Dictionary = require(script.Dictionary),
	Set = require(script.Set),

	None = require(script.None),
	Types = require(script.Types),

	equalObjects = require(script.Util.equalObjects),
	isEmpty = require(script.Util.isEmpty),
}

Sift.List = Sift.Array

--- @prop Array Array
--- @within Sift

--- @prop List Array
--- @within Sift
--- @tag Alias

--- @prop Dictionary Dictionary
--- @within Sift

--- @prop Set Set
--- @within Sift

--- @prop Types Types
--- @within Sift

export type Dictionary<K, V> = Types.Dictionary<K, V>

export type Array<T> = Types.Array<T>
export type List<T> = Array<T>
export type Set<T> = Types.Set<T>

return Sift
