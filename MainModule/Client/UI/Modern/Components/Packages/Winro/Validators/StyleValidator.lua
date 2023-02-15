-- StyleValidator: Validates a style

return function (Style, ...)
	local Type = typeof(Style)
	
	return (Type == 'string' or Type == 'table'), 'Invalid style type. expected string or table, got '..typeof(Style)
end