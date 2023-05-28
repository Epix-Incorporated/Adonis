return function (Style)
	return (
		Style == 'Default'
		or Style == 'Accent'
		or Style == 'Standard'
		or Style == 'Primary'
		or Style == 'Secondary'
	), 'Expected `Accent`, `Standard`, `Primary`, `Secondary` or `Default`'
end