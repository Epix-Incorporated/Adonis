# Plan: Add Tag Viewing and Editing to Dex Explorer

## Feature Request
Add the ability to view and edit instance tags in the Dex Properties panel using CollectionService API (`Instance:GetTags()`, `Instance:AddTag()`, `Instance:RemoveTag()`).

## Implementation Approach

### Follow the Attributes Pattern
Tags are very similar to Attributes - both are dynamic collections attached to instances. We'll create a "Tags" category in the Properties panel that displays all tags and allows adding/removing them.

### Architecture Overview

**Client Side (Properties.lua)**:
1. Gather tags when showing instance properties
2. Display tags in a "Tags" category
3. Provide UI to add/remove tags
4. Send tag operations to server

**Server Side (init.lua)**:
1. Handle `addtag` action
2. Handle `removetag` action
3. Use CollectionService to apply changes

## Detailed Implementation Plan

### 1. Client-Side Changes (Properties.lua)

#### A. Define ViewTagsProp (Around line 65)
Create a special property object for the "Add Tag" button:
```lua
Properties.ViewTagsProp = {
  Name = "Add Tag...",
    Class = "Instance",
	  ValueType = {Name = "string", Category = "Primitive"},
	    Category = "Tags",
		  Tags = {},
		    SpecialRow = "AddTag",
			  Depth = 1
			  }
			  ```

			  #### B. Gather Tags in ShowExplorerProps() (Around lines 533-540)
			  After gathering attributes, get tags from selected instances:

			  ```lua
			  -- After attributes section
			  if Settings.Properties.ShowTags then  -- Add new setting
			    local CollectionService = service.CollectionService

				  for i = 1, #selection do
				      local obj = selection[i]
					      local tags = obj:GetTags()

						      for _, tagName in ipairs(tags) do
							        local tagProp = {
									        Name = tagName,
											        DisplayName = tagName,
													        Class = className,
															        ValueType = {Name = "string", Category = "Primitive"},
																	        Category = "Tags",
																			        Tags = {},
																					        IsTag = true,
																							        TagName = tagName,
																									        Depth = 1
																											      }
																												        props[#props+1] = tagProp
																														    end
																															  end

																															    -- Add "Add Tag" button
																																  props[#props+1] = Properties.ViewTagsProp
																																  end
																																  ```

																																  #### C. Handle Tag Display in DisplayProp() (Around lines 1351-1461)
																																  Add tag-specific rendering:

																																  ```lua
																																  -- Around line 1400, add check for IsTag
																																  if prop.IsTag then
																																    -- Show tag name
																																	  valueBox.Text = prop.TagName

																																	    -- Show delete button
																																		  local deleteButton = entryFrame.ValueFrame.RightButton
																																		    deleteButton.Visible = true
																																			  deleteButton.Icon.Image = "rbxassetid://5034718129"  -- X icon
																																			    deleteButton.Icon.ImageRectSize = Vector2.new(16, 16)

																																				  -- Handle delete click
																																				    -- (Connect in SetInputProp)
																																					end

																																					-- Handle AddTag special row
																																					if prop.SpecialRow == "AddTag" then
																																					  valueBox.Text = "+"
																																					    valueBox.TextColor3 = Settings.Theme.Main1
																																						end
																																						```

																																						#### D. Handle Tag Input in SetInputProp() (Around lines 1808-1854)
																																						Handle adding and removing tags:

																																						```lua
																																						if prop.SpecialRow == "AddTag" then
																																						  -- Show add tag dialog
																																						    Properties.DisplayAddTagWindow()

																																							elseif prop.IsTag then
																																							  if special == "right" then
																																							      -- Remove tag button clicked
																																								      Properties.RemoveTag(prop)
																																									    end
																																										end
																																										```

																																										#### E. Add Tag Management Functions (New functions)

																																										**DisplayAddTagWindow()** (Around line 1112, after DisplayAddAttributeWindow):
																																										```lua
																																										DisplayAddTagWindow = function()
																																										  -- Create window similar to AddAttribute window
																																										    -- Text input for tag name
																																											  -- Validate tag name (no special chars, not empty)
																																											    -- On confirm: call AddTag()
																																												end

																																												AddTag = function(tagName)
																																												  local selection = Explorer.Selection.List
																																												    for i = 1, #selection do
																																													    local obj = selection[i]
																																														    Dex_RemoteFunction:InvokeServer("addtag", obj, tagName)

																																															    -- Update local display
																																																    obj:AddTag(tagName)
																																																	  end

																																																	    -- Refresh properties panel
																																																		  Properties.ShowExplorerProps(selection)
																																																		  end

																																																		  RemoveTag = function(prop)
																																																		    local selection = Explorer.Selection.List
																																																			  local tagName = prop.TagName

																																																			    for i = 1, #selection do
																																																				    local obj = selection[i]
																																																					    Dex_RemoteFunction:InvokeServer("removetag", obj, tagName)

																																																						    -- Update local display
																																																							    obj:RemoveTag(tagName)
																																																								  end

																																																								    -- Refresh properties panel
																																																									  Properties.ShowExplorerProps(selection)
																																																									  end
																																																									  ```

																																																									  #### F. Update Entry Template (Around line 1869)
																																																									  Ensure RightButton is available for tag delete:
																																																									  - Already exists in template, just need to show/hide appropriately

																																																									  #### G. Add Settings Toggle (Around line 33)
																																																									  ```lua
																																																									  ShowTags = true,  -- Add to Settings.Properties
																																																									  ```

																																																									  ### 2. Server-Side Changes (init.lua)

																																																									  #### Add Tag Action Handlers (Around line 155, in Actions table)

																																																									  ```lua
																																																									  addtag = function(Player: Player, args)
																																																									    local obj = args[1]
																																																										  local tagName = args[2]

																																																										    if obj and obj:IsA("Instance") and tagName and type(tagName) == "string" then
																																																											    local success, err = pcall(function()
																																																												      obj:AddTag(tagName)
																																																													      end)

																																																														      if not success then
																																																															        warn("Failed to add tag:", err)
																																																																	    end
																																																																		    return success
																																																																			  end
																																																																			    return false
																																																																				end,

																																																																				removetag = function(Player: Player, args)
																																																																				  local obj = args[1]
																																																																				    local tagName = args[2]

																																																																					  if obj and obj:IsA("Instance") and tagName and type(tagName) == "string" then
																																																																					      local success, err = pcall(function()
																																																																						        obj:RemoveTag(tagName)
																																																																								    end)

																																																																									    if not success then
																																																																										      warn("Failed to remove tag:", err)
																																																																											      end
																																																																												      return success
																																																																													    end
																																																																														  return false
																																																																														  end,
																																																																														  ```

																																																																														  ### 3. UI Design

																																																																														  **Tags Category Appearance**:
																																																																														  ```
																																																																														  ┌─ Tags ────────────────────────────┐
																																																																														  │ ▼ Tags                            │
																																																																														  │   TagName1              [×]       │
																																																																														  │   TagName2              [×]       │
																																																																														  │   AnotherTag            [×]       │
																																																																														  │   + Add Tag...                    │
																																																																														  └───────────────────────────────────┘
																																																																														  ```

																																																																														  **Add Tag Dialog**:
																																																																														  ```
																																																																														  ┌─ Add Tag ─────────────────┐
																																																																														  │                           │
																																																																														  │ Tag Name:                 │
																																																																														  │ ┌───────────────────────┐ │
																																																																														  │ │                       │ │
																																																																														  │ └───────────────────────┘ │
																																																																														  │                           │
																																																																														  │         [OK]   [Cancel]   │
																																																																														  └───────────────────────────┘
																																																																														  ```

																																																																														  ## Files to Modify

																																																																														  1. **MainModule/Server/Plugins/ServerNewDex/Dex_Client/main_NewDex/Modules/Properties.lua**
																																																																														     - Line ~65: Add ViewTagsProp definition
																																																																															    - Line ~33: Add ShowTags setting
																																																																																   - Line ~533-540: Gather tags in ShowExplorerProps()
																																																																																      - Line ~1400: Handle tag display in DisplayProp()
																																																																																	     - Line ~1808-1854: Handle tag input in SetInputProp()
																																																																																		    - Line ~1112: Add DisplayAddTagWindow(), AddTag(), RemoveTag() functions

																																																																																			2. **MainModule/Server/Plugins/ServerNewDex/init.lua**
																																																																																			   - Line ~155: Add `addtag` and `removetag` action handlers in Actions table

																																																																																			   ## Expected Behavior

																																																																																			   ✓ Tags category appears in Properties panel below Attributes
																																																																																			   ✓ All tags on selected instance(s) are displayed
																																																																																			   ✓ Click "Add Tag..." to add new tags
																																																																																			   ✓ Click [×] button next to tag to remove it
																																																																																			   ✓ Tag changes replicate to server
																																																																																			   ✓ Works with multiple instances selected
																																																																																			   ✓ Category can be collapsed like other categories
																																																																																			   ✓ Tags are sorted alphabetically
