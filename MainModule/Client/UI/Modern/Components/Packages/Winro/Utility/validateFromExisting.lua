--[[
	This function returns a type checker based on the provided value
]]

local Winro = script.Parent.Parent
local Packages = Winro.Parent

local t = require(Packages.t)

local function GetValidator(Value, NoTable)
	
	-- Get the type
	local Type = typeof(Value)

	-- Override for table types
	if Type == 'table' and not NoTable then
		return FromTable(Value, true)
	else
		return t[Type]
	end
end

function FromTable(Table, NoTable)

	-- Return a validator for each key
	local Validators = {}

	-- Pupulate validators
	for Key, Value in pairs(Table) do
		Validators[Key] = GetValidator(Value, NoTable)
	end

	return Validators
end

return GetValidator