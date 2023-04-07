local ClearColor = {
	Color = Color3.new(),
	Transparency = 1
}
return {
	NoFill = {
		Disabled = {
			Name = 'NoFill/Disabled',
			Check = ClearColor,
			CheckObscureWidth = 1,
			Fill = "colors/Fill_Color/Control_Alt/Disabled",
			Stroke = "colors/Stroke_Color/Control_Strong_Stroke/Disabled",
			Text = "colors/Fill_Color/Text/Disabled",
		},
		Rest = {
			Name = 'NoFill/Rest',
			Check = ClearColor,
			CheckObscureWidth = 1,
			Fill = "colors/Fill_Color/Control_Alt/Secondary",
			Stroke = "colors/Stroke_Color/Control_Strong_Stroke/Default",
			Text = "colors/Fill_Color/Text/Primary"
		},
		Hover = {
			Name = 'NoFill/Hover',
			Check = ClearColor,
			CheckObscureWidth = 1,
			Fill = "colors/Fill_Color/Control_Alt/Tertiary",
			Stroke = "colors/Stroke_Color/Control_Strong_Stroke/Default",
			Text = "colors/Fill_Color/Text/Primary"
		},
		Pressed = {
			Name = 'NoFill/Pressed',
			Check = ClearColor,
			CheckObscureWidth = 1,
			Fill = "colors/Fill_Color/Control_Alt/Quarternary",
			Stroke = "colors/Stroke_Color/Control_Strong_Stroke/Disabled",
			Text = "colors/Fill_Color/Text/Primary"
		}
	},
	Fill = {
		Disabled = {
			Name = 'Fill/Disabled',
			Check = "colors/Fill_Color/Text_On_Accent/Disabled",
			CheckObscureWidth = 0,
			Fill = "colors/Fill_Color/Accent/Disabled",
			Stroke = "colors/Fill_Color/Accent/Disabled",
			Text = "colors/Fill_Color/Text/Disabled"
		},
		Rest = {
			Name = 'Fill/Rest',
			Check = "colors/Fill_Color/Text_On_Accent/Primary",
			CheckObscureWidth = 0,
			Fill = "colors/Fill_Color/Accent/Default",
			Stroke = "colors/Fill_Color/Accent/Default",
			Text = "colors/Fill_Color/Text/Primary"
		},
		Hover = {
			Name = 'Fill/Hover',
			Check = "colors/Fill_Color/Text_On_Accent/Primary",
			CheckObscureWidth = 0,
			Fill = "colors/Fill_Color/Accent/Secondary",
			Stroke = "colors/Fill_Color/Accent/Secondary",
			Text = "colors/Fill_Color/Text/Primary"
		},
		Pressed = {
			Name = 'Fill/Pressed',
			Check = "colors/Fill_Color/Text_On_Accent/Secondary",
			CheckObscureWidth = 0,
			Fill = "colors/Fill_Color/Accent/Tertiary",
			Stroke = "colors/Fill_Color/Accent/Tertiary",
			Text = "colors/Fill_Color/Text/Primary"
		}
	}
}