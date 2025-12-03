----------------------------------------------------------------------------------------------------
---------------------------------------- Menu Definition -------------------------------------------
----------------------------------------------------------------------------------------------------

local Menu = {}
Menu.__index = Menu

Menu.name = nil
Menu.menuItemDefinitions = nil
Menu.modal = nil
Menu.hotkey = nil
Menu.parentMenu = nil

Menu.menuManager = nil
Menu.numberOfRows = nil
Menu.numberOfColumns = nil

Menu.windowHeight = nil
Menu.entryWidth = nil
Menu.entryHeight = nil

-- Internal function used to find our location, so we know where to load files from
local function scriptPath()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*/)")
end
MenuItem = dofile(scriptPath() .. "/MenuItem.lua")

----------------------------------------------------------------------------------------------------
-- Constructor
function Menu.new(menuName, modal, parentMenu, hotkey, menuItemDefinitions, menuManager)
	assert(menuName, "Menu name is nil")
	assert(menuItemDefinitions, "Menu " .. menuName .. " has no menu item definitions")
	assert(menuManager, "Menu " .. menuName .. " has nil manager")

	local self = setmetatable({}, Menu)

	self.name = menuName
	self.menuItemDefinitions = menuItemDefinitions
	self.modal = modal
	self.hotkey = hotkey
	self.parentMenu = parentMenu
	self.menuManager = menuManager

	self.menuItems = {}

	self:buildMenu()

	return self
end

----------------------------------------------------------------------------------------------------
----------------------------------------- Modal Access ---------------------------------------------
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Enter the modal
function Menu:enter()
	self.modal:enter()
end

----------------------------------------------------------------------------------------------------
-- Exit the modal
function Menu:exit()
	self.modal:exit()
end

----------------------------------------------------------------------------------------------------
-- Get the keys from the menu modal.
function Menu:keys()
	return self.modal.keys
end

----------------------------------------------------------------------------------------------------
----------------------------------------- Build Menu -----------------------------------------------
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Build the menu
function Menu:buildMenu()
	assert(self.menuItemDefinitions, "Menu " .. self.name .. " has no menu items")
	assert(self.menuManager, "Menu " .. self.name .. " has nil menu manager")

	-- Set the number of columns and rows
	self.numberOfColumns = menuNumberOfColumns
	-- Use fixed row count calculated from largest menu (set by MenuManager)
	self.numberOfRows = menuFixedNumberOfRows or menuMinNumberOfRows or 5

	-- Set the window height
	self.windowHeight = menuRowHeight * self.numberOfRows

	-- Set the entry width
	self.entryWidth = 1 / self.numberOfColumns

	-- Set the entry height
	self.entryHeight = 1 / self.numberOfRows

	-- Build the menu items
	self:buildMenuItemList()
end

----------------------------------------------------------------------------------------------------
-- Build the list of menu items
function Menu:buildMenuItemList()
	local menuItemList = {}

	-- If there is a parent menu, escape goes back; otherwise escape exits
	if self.parentMenu ~= nil then
		-- Escape = back to parent menu
		table.insert(menuItemList, {
			cons.cat.back,
			"",
			"escape",
			"Back",
			{
				{
					cons.act.func,
					function()
						self.menuManager:switchMenu(self.parentMenu)
					end,
				},
			},
		})
	else
		-- No parent = root menu, escape exits
		table.insert(menuItemList, {
			cons.cat.exit,
			"",
			"escape",
			"Exit",
			{
				{
					cons.act.func,
					function()
						self.menuManager:closeMenu()
					end,
				},
			},
		})
	end

	-- Add blank spaces to the first column until it's full
	while #menuItemList < self.numberOfRows do
		table.insert(menuItemList, { cons.cat.navigation, nil, nil, "" })
	end

	-- Sort menu items by key (lowercase first, then uppercase, then special keys)
	local sortedItems = {}
	for _, newMenuItem in pairs(self.menuItemDefinitions) do
		table.insert(sortedItems, newMenuItem)
	end
	table.sort(sortedItems, function(a, b)
		local keyA = a[3] or ""
		local keyB = b[3] or ""

		-- Categorize keys: 1=lowercase, 2=uppercase, 3=special
		local function keyCategory(k)
			if k:match("^%l$") then return 1  -- lowercase letter
			elseif k:match("^%u$") then return 2  -- uppercase letter
			else return 3  -- special keys (space, escape, etc.)
			end
		end

		local catA, catB = keyCategory(keyA), keyCategory(keyB)
		if catA ~= catB then
			return catA < catB
		end
		return keyA < keyB
	end)

	-- Add sorted menu items
	for _, newMenuItem in ipairs(sortedItems) do
		table.insert(menuItemList, newMenuItem)
	end

	self.menuItemDefinitions = menuItemList

	self:createMenuItems()
end

----------------------------------------------------------------------------------------------------
-- Create the menu items
function Menu:createMenuItems()
	local boundKeys = {}

	-- Loop through the menu items
	-- Calculate content item distribution across columns
	local contentColumns = self.numberOfColumns - 1
	local contentItemCount = #self.menuItemDefinitions - self.numberOfRows  -- items after nav column
	local basePerCol = math.floor(contentItemCount / contentColumns)
	local extraItems = contentItemCount % contentColumns

	-- Build array of how many items in each content column
	local itemsPerColumn = {}
	for col = 1, contentColumns do
		itemsPerColumn[col] = basePerCol + (col <= extraItems and 1 or 0)
	end

	for index, menuItem in ipairs(self.menuItemDefinitions) do
		-- Adjust the index to 0 indexed
		local adjustedIndex = index - 1

		-- Get the key combo and description
		local category = menuItem[1]
		local modifier = nil
		local key = nil
		local desc
		local commands
		-- Default to closing the menu
		local remainOpen = false
		if category ~= cons.cat.display then
			modifier = menuItem[2]
			key = menuItem[3]
			desc = menuItem[4]
			commands = menuItem[5]
			-- If remain open is set then use it
			if menuItem[6] ~= nil then
				remainOpen = menuItem[6]
			end
		else
			desc = menuItem[2]
			commands = menuItem[3]
		end

		-- Validate that the key isn't already bound on this menu
		if key ~= nil then
			local keyCombo = modifier .. key
			assert(boundKeys[keyCombo] == nil, "Key " .. keyCombo .. " double bound")
			boundKeys[keyCombo] = true
		end

		local column, row

		if adjustedIndex < self.numberOfRows then
			-- Nav column items (Back/Exit + blanks)
			column = 0
			row = adjustedIndex
		else
			-- Content items - spread across all columns evenly
			local contentIndex = adjustedIndex - self.numberOfRows  -- 0-indexed within content
			local itemsSoFar = 0
			for col = 1, contentColumns do
				if contentIndex < itemsSoFar + itemsPerColumn[col] then
					column = col
					row = contentIndex - itemsSoFar
					break
				end
				itemsSoFar = itemsSoFar + itemsPerColumn[col]
			end
		end

		-- Create the menuItem object
		self:createMenuItem(category, modifier, key, desc, index, row, column, commands, remainOpen)
	end
end

----------------------------------------------------------------------------------------------------
-- Create a single menu item
function Menu:createMenuItem(category, modifier, key, description, index, row, column, commands, remainOpen)
	local newMenuItem = MenuItem.new(
		category,
		modifier,
		key,
		description,
		row,
		column,
		self.entryWidth,
		self.entryHeight,
		commands,
		self.menuManager,
		self
	)

	assert(newMenuItem, self.name .. " has nil menu item")

	-- Add the menu item to the list
	self.menuItems[index] = newMenuItem

	self:bindToMenu(newMenuItem, function()
		newMenuItem:runAction()
	end, remainOpen, description)
end

----------------------------------------------------------------------------------------------------
-- Bind a single item to the menu
function Menu:bindToMenu(menuItem, pressedFunction, remainOpen, originalDescription)
	if pressedFunction ~= nil then
		assert(type(pressedFunction) == "function", "Pressed function is of type " .. type(pressedFunction))
	end

	assert(menuItem, "Menu item is nil")

	-- Alert the menu manager the item was activated
	local preprocessFunction = function()
		self.menuManager:itemActivated(menuItem.category, remainOpen)
	end

	local finalFunction = function()
		preprocessFunction()

		-- If a function was provided, run it.
		if pressedFunction ~= nil then
			pressedFunction()
		end
	end

	local displayTitle = menuItem:displayTitle()

	-- If we have a key defined, bind it
	if menuItem.key ~= nil then
		local newModalBind = self.modal:bind(menuItem.modifier, menuItem.key, displayTitle, finalFunction)
		-- Use the original key instead of the transformed one from Hammerspoon
		if #menuItem.key == 1 then
			-- For single character keys, use the original key with the original description
			menuItem.desc = menuItem.key .. menuKeyItemSeparator .. originalDescription
		else
			-- For other keys (like "escape", "delete", etc.), use Hammerspoon's message
			menuItem.desc = newModalBind.keys[tableLength(newModalBind.keys)].msg
		end
	end
end

----------------------------------------------------------------------------------------------------
----------------------------------- Drawing Functions ----------------------------------------------
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Get the frame to put the menu in
function Menu:getMenuFrame()
	local topPadding = menuTopPadding or 0
	local windowHeight = self.windowHeight + topPadding

	-- Calculate the dimensions using the size of the main screen.
	local cscreen = hs.screen.mainScreen()
	local cres = cscreen:frame()
	local menuFrame = {
		x = cres.x,
		y = cres.y + (cres.h - windowHeight),
		w = cres.w,
		h = windowHeight,
	}

	return menuFrame
end

----------------------------------------------------------------------------------------------------
-- Return the canvases to display
function Menu:getMenuDisplay()
	assert(self.menuItems, "Menu " .. self.name .. " has no menu items defined")

	local newCanvases = {}

	-- Add cheat sheet if enabled
	local cheatSheetCanvases = self:getCheatSheetCanvases()
	for _, canvas in pairs(cheatSheetCanvases) do
		table.insert(newCanvases, canvas)
	end

	-- Loop through each menu item and build them
	for _, menuItem in pairs(self.menuItems) do
		-- Create the background canvas
		local menuItemCanvases = menuItem:getBackgroundCanvas()

		-- Create the text canvas, if necessary
		if menuItem.desc ~= nil then
			table.insert(menuItemCanvases, menuItem:getTextCanvas())
		end

		-- Append the new canvases
		for _, newCanvas in pairs(menuItemCanvases) do
			table.insert(newCanvases, newCanvas)
		end
	end

	return newCanvases
end

----------------------------------------------------------------------------------------------------
-- Generate cheat sheet canvas elements (positioned as right-most column)
function Menu:getCheatSheetCanvases()
	local canvases = {}

	-- Check if cheat sheet is enabled
	if not menuCheatSheet or not menuCheatSheet.enabled then
		return canvases
	end

	local cs = menuCheatSheet
	local frame = self:getMenuFrame()
	local topPadding = menuTopPadding or 0

	-- Calculate cheat sheet dimensions
	local lineHeight = (cs.fontSize or 12) + 4
	local titleHeight = (cs.titleFontSize or 13) + 4
	local padding = cs.padding or 8
	local boxWidth = cs.width or 200

	-- Position: right column, flush against padding on top, bottom, and right
	local margin = topPadding
	local boxX = frame.w - boxWidth - margin  -- Right margin
	local boxY = margin  -- Top margin
	local boxHeight = frame.h - (margin * 2)  -- Full height minus top/bottom margins

	-- Background rectangle (full column height)
	table.insert(canvases, {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = cs.backgroundColor or "#1a1a1a", alpha = 0.95 },
		frame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight },
		roundedRectRadii = { xRadius = 4, yRadius = 4 },
	})

	-- Border rectangle
	table.insert(canvases, {
		type = "rectangle",
		action = "stroke",
		strokeColor = { hex = cs.borderColor or "#444444", alpha = 1 },
		strokeWidth = cs.borderWidth or 1,
		frame = { x = boxX, y = boxY, w = boxWidth, h = boxHeight },
		roundedRectRadii = { xRadius = 4, yRadius = 4 },
	})

	-- Title text
	table.insert(canvases, {
		type = "text",
		text = cs.title or "Cheat Sheet",
		textFont = cs.font or "Menlo-Bold",
		textSize = cs.titleFontSize or 13,
		textColor = { hex = cs.titleColor or "#ffffff", alpha = 1 },
		textAlignment = "left",
		frame = { x = boxX + padding, y = boxY + padding, w = boxWidth - (padding * 2), h = titleHeight },
	})

	-- Item texts
	for i, item in ipairs(cs.items or {}) do
		table.insert(canvases, {
			type = "text",
			text = item,
			textFont = cs.font or "Menlo",
			textSize = cs.fontSize or 12,
			textColor = { hex = cs.textColor or "#88ccff", alpha = 1 },
			textAlignment = "left",
			frame = {
				x = boxX + padding,
				y = boxY + padding + titleHeight + ((i - 1) * lineHeight),
				w = boxWidth - (padding * 2),
				h = lineHeight,
			},
		})
	end

	return canvases
end

return Menu
