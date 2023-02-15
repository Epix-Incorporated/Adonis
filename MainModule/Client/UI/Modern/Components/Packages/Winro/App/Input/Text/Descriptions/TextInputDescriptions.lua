local TRANSPARENT = {
	Color = Color3.new(),
	Transparency = 1,
}

return {
	Rest = {
		Focus = {
			Button = 'colors/Fill_Color/Text/Secondary',
			Highlight = 'colors/Fill_Color/Accent/Default',
			Stroke = 'colors/Stroke_Color/Control_Stroke/Default',
			Text = 'colors/Fill_Color/Text/Primary',
		},
		Rest = {
			Button = TRANSPARENT,
			Highlight = 'colors/Elevation/Text_Control/Border',
			Stroke = 'colors/Stroke_Color/Control_Stroke/Default',
			Text = 'colors/Fill_Color/Text/Primary',
		},
	},
}