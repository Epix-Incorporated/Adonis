--[[
	Notice:
		All themes MUST include a StringValue named "Base_Theme" that tells the script where to pull GUIs and Configs from
		if they aren't found in the selected theme. Generally this should have it's value set to "Default" unless
		the theme is derived from another existing theme (such as if you made a new theme using the "Hydris" theme,
		the Base_Theme value would be set to "Hydris" so you don't need to copy all the code modules and all that)
		
		Alternatively, each individual GUI can include a StringValue in their Config folder named "BaseTheme" which
		acts identical to Base_Theme, however is instead on a per-GUI basis instead of theme-wide. This allows you 
		to mix GUIs based on GUIs in different themes together into one theme. 
		
		It should be noted that this functionality has a capped depth of 10 themes deep.
		Here's somewhat of a visual to help you better understand what I mean by depth:
		
		ThemeToFind		<- First GUI/Theme Checked (the one selected)
		> BaseTheme1	<- Next theme checked (first theme's Base_Theme)
		>> BaseTheme2	<- BaseTheme1's Base_Theme
		>>> BaseTheme3	<- BaseTheme2's Base_Theme
		>>>> BaseTheme4 <- BaseTheme3's Base_Theme
		
		The above will go on until it either reaches a depth of 10 (BaseTheme10) or reaches 
		a theme with no Base_Theme set. Usually the last theme in the sequence will be
		the "Default" theme as it's Base_Theme is empty because it should never need to pull
		from any other themes.
	
	Basic theming related information;
		
		All Adonis GUIs have a code module that makes them run. If you are only changing minor things on an
		existing GUI (such as colors) then you do not need to include a code module, instead it will use the
		default's. If you need to change the code for the GUI then you MUST include a code module inside a Config
		folder.
		
		GUIs can avoid clearing the chat every time they appear by using client.UI.Prepare(gui)
		To see an example of this refer to the Message GUI; In it the only line that needed to be
		changed was local gui = script.Parent.Parent to local gui = client.UI.Prepare(script.Parent.Parent)
		When PrepareGui is called on an already registered GUI the script will handle updating everything
		accordingly.
		
		The function for every GUI has a global named gTable. gTable contains all GUI related functions and information
		used by the script. When a GUI is ready to appear use gTable:Ready() instead of gui.Parent = playergui. 
		For removing the GUI it is prefered that you use gTable:Destroy() as it will unregister the GUI when it 
		destroys it. It is not required and just ensures that the GUI is properly cleaned up, however it should 
		also clean itself up when it's destroyed normally.
		
		GUI themes do NOT need to be folders containing GUIs! You can made a new module that alters or creates
		GUIs (refer to Colorize theme.) These modules can also contain GUIs like a normal theme folder aswell.
		If the theme module creates its own GUI on the fly, it must return something when it's done and handle all
		of the GUI related code itself. Including registering the new GUi it created via 
		local gTable,gIndex = client.UI.Register(GUIObjectHere). The module must handle every aspect of the GUI's
		creation process that normally client.UI.Make would. If it returns a ScreenGui, the default code for the 
		GUI will be used from the Hybrid theme, and it will be registered by the script like normal. If something 
		other than nil that isn't a ScreenGui is returned, the script will ignore the rest of the normal loading 
		process and return whatever the module returned. 
		
		
		Refer to the code and GUIs in the hybrid theme folder for examples. 
		
		NOTE:
			The config folder will be parented to nil once gTable:Ready() is called, before the GUI is parented.
			You should preference all GUI elements instead of using script.Parent.X, as otherwise there will be
			an error about indexing a nil value (the parent). It will only become nil AFTER gTable:Ready() is called
			so anything after the call cannot reference script.Parent directly. You must use gTable:Ready() when the
			GUI is ready to be displayed, otherwise unintended behaviour may occur. 
	
	
	
	Client UI Functions;
	
		client.UI.GetHolder()
			- This will return the primary ScreenGui object that all GUIs will go into after becoming a TextLabel (not currently used)
		
		client.UI.Prepare(gui) 
			- If gui is a ScreenGui; Transfers content to a new TextLabel and returns the new TextLabel; Else returns gui
			
		client.UI.Make(guiName, guiData, themeData)
			- Responsible for handling the creation and registering of new UI elements
			- guiName is the name of the GUI to find/create
			- guiData is the data table passed to the GUI's code module function
			- themeData is a table containing information about what theme to use
			- Returns whatever GUI's code module returns
			
		client.UI.Get(Name, Ignore, returnOne)
			- Finds and returns registered GUI gTables matching name
			- Name is the name of the GUI to find
			- Ignore is a GUI to ignore when trying to find the target
			- if returnOne is true, return a single found gTable instead of a table containing all found ones
			
		client.UI.Remove(Name, Ignore)
			- Finds registered GUIs matching Name and removes them
			- If Ignore is set to a GUI; don't remove it when/if found
			
		client.UI.Register(gui)
			- Handles the registration of new GUIs
			- Returns gTable,gIndex
--]]
return function() end
