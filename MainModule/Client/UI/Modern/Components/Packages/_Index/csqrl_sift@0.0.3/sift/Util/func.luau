local function truthy()
	return true
end

local function noop() end

local function returned(...)
	return ...
end

return {
	truthy = truthy,
	noop = noop,
	returned = returned,
}
