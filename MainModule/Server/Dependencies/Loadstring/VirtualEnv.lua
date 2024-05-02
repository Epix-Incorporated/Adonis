local vEnv = getfenv()
vEnv.script = nil

return function()
	return vEnv
end
