----------------------------------------------------------------------------------------------------
--------------------------------- MenuManager Definition -------------------------------------------
----------------------------------------------------------------------------------------------------

-- This class is used for managing all the menus.  It stores the menu definitions, keeps track of
-- which menu is open and provides the functionality to close and open menus.

local MenuManager = {}
MenuManager.__index = MenuManager

-- The key that will open the menu
MenuManager.activationKey = {}

-- The table of menus and menu items
MenuManager.menuList = {}

-- The colors to use for showing menus
MenuManager.menuColors = {}

-- The prefixes to use for menu items
MenuManager.menuPrefixes = {}

-- Whether or not to show an item on the macOS menu bar
MenuManager.showMenuBarItems = true

-- The menu bar item
MenuManager.menuBarItem = nil

MenuManager.canvas = nil
MenuManager.activeMenu = nil

MenuManager.menuItems = {}
MenuManager.storedValues = {}

MenuManager.showMenuDelay = 0.0
MenuManager.rootMenu = nil

MenuManager.spoonPath = hs.spoons.scriptPath()

MenuManager.menuCallback = nil

-- Import the Menu class
Menu = dofile(MenuManager.spoonPath .. "/Menu.lua")

-- Import support methods
dofile(MenuManager.spoonPath .. "/Support.lua")

----------------------------------------------------------------------------------------------------
--------------------------------------- MenuManager Init -------------------------------------------
----------------------------------------------------------------------------------------------------

function MenuManager.new(activationKey, menuList, menuColors, menuPrefixes, showMenuBarItem)
	print("Creating menu manager")

	-- Ensure we have the needed values.  showMenuBarItems will default to false.
	assert(activationKey, "No menu activation key provided")
	assert(menuList, "No menu list provided")
	assert(menuColors, "No menu colors provided")
	assert(menuPrefixes, "No menu prefixes provided")

	-- Create the new object
	local self = setmetatable({}, MenuManager)

	-- Set the provided values
	self.activationKey = activationKey
	self.menuList = menuList
	self.menuColors = menuColors
	self.menuPrefixes = menuPrefixes
	self.showMenuBarItem = showMenuBarItem

	return self
end

----------------------------------------------------------------------------------------------------
-- Enter/Activate the menu manager
function MenuManager:enter()
	print("Entering menu manager")

	-- Create the root menu
	self.rootMenu = hs.hotkey.modal.new(self.activationKey[1], self.activationKey[2], "Initialize Modal Environment")

	-- Bind the root menu to the configured key
	self.rootMenu:bind(self.activationKey[1], self.activationKey[2], "Reset Modal Environment", function()
		self.rootMenu:exit()
	end)

	-- Initialize the canvas and give it the default background color.
	self.canvas = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
	self.canvas:level(hs.canvas.windowLevels.tornOffMenu)
	self.canvas[1] = {
		type = "rectangle",
		action = "fill",
		fillColor = { hex = menuItemColors.default.background, alpha = 0.95 },
	}

	-- Determine if the menu bar item should be shown
	if self.showMenuBarItem then
		-- The menu bar item to show current status
		self.menuBarItem = hs.menubar.new()

		self.menuBarItem:setMenu({
			{
				title = "Reload config",
				fn = function()
					hs.reload()
				end,
			},
		})

		-- Clear the menu bar text
		self:setMenuBarText(nil)
	end

	-- Calculate max items across all menus to determine fixed row count
	-- Use the global menuHammerMenuList directly to ensure we get raw config
	print("MenuHammer: Starting max items calculation...")
	local maxItems = 0
	local maxMenuName = ""
	for menuName, menuConfig in pairs(menuHammerMenuList) do
		if menuConfig.menuItems then
			local itemCount = 0
			for _ in pairs(menuConfig.menuItems) do
				itemCount = itemCount + 1
			end
			print("  " .. menuName .. ": " .. itemCount .. " items")
			if itemCount > maxItems then
				maxItems = itemCount
				maxMenuName = menuName
			end
		end
	end

	-- Set fixed row count: min 5, or ceil(maxItems / contentColumns)
	local contentColumns = menuNumberOfColumns - 1
	local calculatedRows = math.ceil(maxItems / contentColumns)
	menuFixedNumberOfRows = math.max(menuMinNumberOfRows or 5, calculatedRows)
	print("MenuHammer: Max items = " .. maxItems .. " in " .. maxMenuName)
	print("MenuHammer: contentColumns = " .. contentColumns .. ", calculatedRows = " .. calculatedRows)
	print("MenuHammer: menuFixedNumberOfRows = " .. menuFixedNumberOfRows)

	-- Build the menus
	self:populateMenus()

	-- Activate the root menu
	self.rootMenu:enter()
end

----------------------------------------------------------------------------------------------------
-- Populate Menus
function MenuManager:populateMenus()
	print("Populating menus")
	for menuName, menuConfig in pairs(self.menuList) do
		-- If a parent menu is provided, ensure it exists
		if menuConfig.parentMenu ~= nil then
			assert(self.menuList[menuConfig.parentMenu], "Parent menu for " .. menuName .. " does not exist.")
		end

		-- Create the menu
		self:createMenu(menuName, menuConfig.parentMenu, menuConfig.menuHotkey, menuConfig.menuItems)
	end
end

----------------------------------------------------------------------------------------------------
-- Create menu
function MenuManager:createMenu(menuName, parentMenu, menuHotkey, menuItems)
	assert(menuName, "Menu name is nil")
	assert(menuItems, "Menu items is nil for " .. menuName)

	-- print(hs.inspect(menuItems))

	local newMenu = Menu.new(menuName, hs.hotkey.modal.new(), parentMenu, menuHotkey, menuItems, self)

	assert(newMenu, "Did not receive a new menu for " .. menuName)

	-- If a key combination was provided, bind it to the root menu.
	if menuHotkey ~= nil then
		print("Adding menu hotkey to " .. menuName)
		assert(self.rootMenu, "Menu manager root menu is nil")
		self.rootMenu:bind(menuHotkey[1], menuHotkey[2], "Open " .. menuName, function()
			self:switchMenu(menuName)
		end)
		-- Also bind the same hotkey to the menu's modal to toggle/close it
		newMenu.modal:bind(menuHotkey[1], menuHotkey[2], "Close " .. menuName, function()
			self:closeMenu()
		end)
	end

	self.menuList[menuName] = newMenu
end

----------------------------------------------------------------------------------------------------
-- Check for menu existence
function MenuManager:checkMenuExists(menuName)
	assert(menuName, "No menu name provided")

	if self.menuList[menuName] ~= nil then
		return true
	end

	return false
end

----------------------------------------------------------------------------------------------------
-- Get number of rows
function MenuManager:getNumberOfRows(menuItems, numberOfColumns)
	local numberOfRows = math.ceil(tableLength(menuItems) / numberOfColumns)

	if numberOfRows < menuMinNumberOfRows then
		numberOfRows = menuMinNumberOfRows
	end

	return numberOfRows
end

----------------------------------------------------------------------------------------------------
----------------------------------------- Menu Controls --------------------------------------------
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Switch menu
function MenuManager:switchMenu(menuName)
	assert(menuName, "Menu name is nil")
	print("")
	print("Switching to new menu: " .. menuName)
	print("")

	-- Close the open menu, if any
	self:closeMenu()

	-- Show the menu
	self:openMenu(menuName)
end

----------------------------------------------------------------------------------------------------
-- Close menus
function MenuManager:closeMenu()
	if MenuManager.menuCallback then
		MenuManager.menuCallback:stop()
		MenuManager.menuCallback = nil
	end
	print("Closing menus")
	-- Shut off the active menu
	if self.activeMenu ~= nil then
		self.menuList[self.activeMenu]:exit()
	end
	self.activeMenu = nil

	-- Clear off the canvas and hide it
	for i = 2, #self.canvas do
		self.canvas:removeElement(2)
	end
	self.canvas:hide()

	-- Reset the menu bar item
	self:setMenuBarText(nil)
end

----------------------------------------------------------------------------------------------------
-- Show menu
function MenuManager:openMenu(menuName)
	assert(menuName, "Menu name is nil")
	assert(self.menuList[menuName], "No menu named " .. menuName)

	print("Showing menu " .. menuName)

	-- Show the menu name on the macOS menu bar
	self:setMenuBarText(menuName)

	-- Set the active menu
	self.activeMenu = menuName

	-- Retrieve the menu
	local currentMenu = self.menuList[menuName]
	assert(currentMenu, "Menu " .. menuName .. " does not exist")

	-- Enter the menu
	currentMenu:enter()

	-- print(hs.inspect(currentMenu))

	-- Get the menu frame from the menu
	self.canvas:frame(currentMenu:getMenuFrame())

	-- Retrieve the canvases from the menu
	local newMenuCanvases = currentMenu:getMenuDisplay()

	-- Append the new canvases
	for _, newCanvas in pairs(newMenuCanvases) do
		table.insert(self.canvas, newCanvas)
	end

	-- Show the menu
	if MenuManager.showMenuDelay > 0 then
		-- this should never be called when a callback is active...
		assert(MenuManager.menuCallback == nil)
		MenuManager.menuCallback = hs.timer.doAfter(MenuManager.showMenuDelay, function()
			self.canvas:show()
		end)
	else
		self.canvas:show()
	end
end

----------------------------------------------------------------------------------------------------
-- Reload the current menu
function MenuManager:reloadMenu()
	self:switchMenu(self.activeMenu)
end

----------------------------------------------------------------------------------------------------
-- Alert MenuHammer an item was selected
function MenuManager:itemActivated(itemType, remainOpen)
	if not remainOpen and (itemType == "action" or itemType == "exit") then
		self:closeMenu()
	end
end

----------------------------------------------------------------------------------------------------
----------------------------------------- Menu Bar Item --------------------------------------------
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- Create a depth icon using hs.canvas
-- Shows a rounded square with dots indicating menu depth
function MenuManager:createDepthIcon(depth)
	local size = 18
	local canvas = hs.canvas.new({ x = 0, y = 0, w = size, h = size })

	-- Determine if we're in dark mode for proper icon coloring
	local isDark = true -- Menubar icons work best as template images (dark)
	local strokeColor = { white = 0, alpha = 0.9 }
	local fillColor = { white = 0, alpha = 0.9 }

	-- Draw rounded square border
	canvas[1] = {
		type = "rectangle",
		action = "stroke",
		frame = { x = 2, y = 2, w = size - 4, h = size - 4 },
		roundedRectRadii = { xRadius = 3, yRadius = 3 },
		strokeColor = strokeColor,
		strokeWidth = 1.5,
	}

	-- Add dots for depth (vertically centered)
	if depth > 0 then
		local maxDots = math.min(depth, 4) -- Cap at 4 dots
		local dotRadius = 1.5
		local dotSpacing = 3.5
		local totalDotsHeight = (maxDots - 1) * dotSpacing
		local startY = (size - totalDotsHeight) / 2

		for i = 1, maxDots do
			canvas[i + 1] = {
				type = "circle",
				action = "fill",
				center = { x = size / 2, y = startY + (i - 1) * dotSpacing },
				radius = dotRadius,
				fillColor = fillColor,
			}
		end
	end

	-- Convert to image and set as template (adapts to light/dark menubar)
	local image = canvas:imageFromCanvas()
	if image then
		image:template(true)
	end

	return image
end

----------------------------------------------------------------------------------------------------
-- Calculate menu depth by traversing parent chain
function MenuManager:getMenuDepth(menuName)
	if menuName == nil then
		return 0
	end

	local depth = 1
	local currentMenu = self.menuList[menuName]

	while currentMenu and currentMenu.parentMenu do
		depth = depth + 1
		currentMenu = self.menuList[currentMenu.parentMenu]
	end

	return depth
end

----------------------------------------------------------------------------------------------------
-- Update the menu bar icon based on current state
function MenuManager:updateMenuBarIcon(menuName)
	if not self.showMenuBarItem or not self.menuBarItem then
		return
	end

	local depth = self:getMenuDepth(menuName)
	local icon = self:createDepthIcon(depth)

	if icon then
		self.menuBarItem:setIcon(icon)
		self.menuBarItem:setTitle("") -- Clear any text
	end
end

----------------------------------------------------------------------------------------------------
-- Set the menu bar text (legacy function, now updates icon)
function MenuManager:setMenuBarText(text)
	self:updateMenuBarIcon(text)
end

return MenuManager
