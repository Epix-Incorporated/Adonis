local Winro = script.Parent.Parent
local Packages = Winro.Parent
local t = require(Packages.t)

return t.table(t.strictInterface({
	Selected = t.string,
	Label = t.optional(t.string),
	OnClicked = t.callback
}))