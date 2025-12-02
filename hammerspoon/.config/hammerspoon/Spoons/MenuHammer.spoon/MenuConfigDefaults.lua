----------------------------------------------------------------------------------------------------
--------------------------------------- General Config ---------------------------------------------
----------------------------------------------------------------------------------------------------

-- If enabled, the menus will appear over full screen applications.
-- However, the Hammerspoon dock icon will also be disabled (required for fullscreen).
menuShowInFullscreen = false

-- If enabled, a menu bar item will appear that shows what menu is currently being displayed or
-- "idle" if no menu is open.
showMenuBarItem = true

-- The number of seconds that a hotkey alert will stay on screen.
-- 0 = alerts are disabled.
hs.hotkey.alertDuration = 0

-- Show no titles for Hammerspoon windows.
hs.hints.showTitleThresh = 0

-- Disable animations
hs.window.animationDuration = 0

-- Editor path
menuTextEditor = "/usr/local/bin/emacsclient -c"

-- Location of the askpass executable.  Required for running script with admin privs.
askpassLocation = "/usr/local/bin/ssh-askpass"

----------------------------------------------------------------------------------------------------
----------------------------------------- Menu options ---------------------------------------------
----------------------------------------------------------------------------------------------------

-- The number of columns to display in the menus.  Setting this too high or too low will
-- probably have odd results.
menuNumberOfColumns = 5

-- The minimum number of rows to show in menus
menuMinNumberOfRows = 4

-- The height of menu rows in pixels
menuRowHeight = 30

-- The padding to apply to each side of the menu
menuOuterPadding = 50

-- Top padding inside the menu (pixels) - includes space for cheat sheet
menuTopPadding = 50

-- Cheat sheet configuration
menuCheatSheet = {
	enabled = true,
	title = "Claude Code",
	items = {
		"⌃⌥R  Search prompts",
	},
	font = "CaskaydiaCove Nerd Font Mono",
	fontSize = 12,
	titleFontSize = 13,
	textColor = "#88ccff",
	titleColor = "#ffffff",
	borderColor = "#444444",
	backgroundColor = "#1a1a1a",
	borderWidth = 1,
	padding = 8,
}

----------------------------------------------------------------------------------------------------
----------------------------------------- Font options ---------------------------------------------
----------------------------------------------------------------------------------------------------

-- The font to apply to menu items.
menuItemFont = "Courier-Bold"

-- The font size to apply to menu items.
menuItemFontSize = 16

-- The text alignment to apply to menu items.
menuItemTextAlign = "left"

----------------------------------------------------------------------------------------------------
---------------------------------------- Color options ---------------------------------------------
----------------------------------------------------------------------------------------------------

menuItemColors = {
	-- The default colors to use.
	default = {
		background = "#000000",
		text = "#aaaaaa",
	},
	-- The colors to use for the Exit menu item
	exit = {
		background = "#000000",
		text = "#C1666B",
	},
	-- The colors to use for the Back menu items
	back = {
		background = "#000000",
		text = "#E76F51",
	},
	-- The colors to use for menu menu items
	submenu = {
		background = "#000000",
		text = "#9A879D",
	},
	-- The colors to use for navigation menu items
	navigation = {
		background = "#000000",
		text = "#4281A4",
	},
	-- The colors to use for empty menu items
	empty = {
		background = "#000000",
		text = "#aaaaaa",
	},
	-- The colors to use for action menu items
	action = {
		background = "#000000",
		text = "#7A3B69",
	},
	menuBarActive = {
		background = "#ff0000",
		text = "#000000",
	},
	menuBarIdle = {
		background = "#00ff00",
		text = "#000000",
	},
	display = {
		background = "#000000",
		text = "#48A9A6",
	},
}

----------------------------------------------------------------------------------------------------
-------------------------------------- Menu bar options --------------------------------------------
----------------------------------------------------------------------------------------------------

-- Key bindings

-- The hotkey that will enable/disable MenuHammer
menuHammerToggleKey = { { "cmd", "shift", "ctrl" }, "Q" }

-- Menu Prefixes
menuItemPrefix = {
	action = "↩",
	submenu = "→",
	back = "←",
	exit = "x",
	navigation = "↩",
	-- navigation = '⎋',
	empty = "",
	display = "",
}

-- Menu item separator
menuKeyItemSeparator = " → "

----------------------------------------------------------------------------------------------------
--------------------------------------- Default Menus ----------------------------------------------
----------------------------------------------------------------------------------------------------

-- Menus
local mainMenu = "mainMenu"

-- Help menu
local helpMenu = "helpMenu"

-- Applications Menus
local applicationMenu = "applicationMenu"
local utilitiesMenu = "utilitiesMenu"

-- Browser menus
local browserMenu = "browserMenu"

-- Documents menu
local documentsMenu = "documentsMenu"

-- Finder menu
local finderMenu = "finderMenu"

-- Games menu
local gamesMenu = "gamesMenu"

-- Hammerspoon menu
local hammerspoonMenu = "hammerspoonMenu"

-- Help menu
local helpMenu = "helpMenu"

-- Layout menu
local layoutMenu = "layoutMenu"

-- Media menu
local mediaMenu = "mediaMenu"

-- Resolution menu
local resolutionMenu = "resolutionMenu"

-- Scripts menu
local scriptsMenu = "scriptsMenu"

-- System menus
local systemMenu = "systemMenu"

-- Text menu
local textMenu = "textMenu"

-- Toggles menu
local toggleMenu = "toggleMenu"

-- Window menu
local resizeMenu = "resizeMenu"

-- WezTerm workspaces menu
local weztermMenu = "weztermMenu"

-- Projects menu
local projectsMenu = "projectsMenu"

-- Helper function to open WezTerm at a directory, optionally on AeroSpace workspace
-- Uses hs.task for async execution to avoid blocking Hammerspoon
local function openWezTermAt(dir, workspace)
	-- Expand ~ to home directory
	local expandedDir = dir:gsub("^~", os.getenv("HOME"))

	local function launchWezTerm()
		hs.task.new("/opt/homebrew/bin/wezterm", nil, { "start", "--cwd", expandedDir }):start()
	end

	-- Check if AeroSpace is available (async)
	hs.task.new("/opt/homebrew/bin/aerospace", function(exitCode, stdOut, stdErr)
		local aerospaceEnabled = (exitCode == 0)

		if aerospaceEnabled and workspace then
			-- Switch to workspace first, then open WezTerm
			hs.task.new("/opt/homebrew/bin/aerospace", function()
				hs.timer.doAfter(0.15, launchWezTerm)
			end, { "workspace", workspace }):start()
		else
			launchWezTerm()
		end
	end, { "list-workspaces", "--all" }):start()
end

menuHammerMenuList = {

	------------------------------------------------------------------------------------------------
	-- Main Menu
	------------------------------------------------------------------------------------------------
	[mainMenu] = {
		parentMenu = nil,
		menuHotkey = { { "ctrl", "alt" }, "space" },
		menuItems = {
			{
				cons.cat.submenu,
				"",
				"a",
				"Applications",
				{
					{ cons.act.menu, applicationMenu },
				},
			},
			{ cons.cat.submenu, "", "f", "Finder", {
				{ cons.act.menu, finderMenu },
			} },
			{
				cons.cat.submenu,
				"",
				"h",
				"Hammerspoon",
				{
					{ cons.act.menu, hammerspoonMenu },
				},
			},
			{ cons.cat.submenu, "", "m", "Media Controls", {
				{ cons.act.menu, mediaMenu },
			} },
			{ cons.cat.submenu, "", "p", "Projects", {
				{ cons.act.menu, projectsMenu },
			} },
			{
				cons.cat.submenu,
				"",
				"s",
				"System Preferences",
				{
					{ cons.act.menu, systemMenu },
				},
			},
			{ cons.cat.submenu, "", "t", "Toggles", {
				{ cons.act.menu, toggleMenu },
			} },
			{ cons.cat.submenu, "", "w", "WezTerm Workspaces", {
				{ cons.act.menu, weztermMenu },
			} },
			{ cons.cat.submenu, "", "x", "Text", {
				{ cons.act.menu, textMenu },
			} },
			{
				cons.cat.action,
				"",
				"space",
				"Spotlight",
				{
					{ cons.act.keycombo, { "cmd" }, "space" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Help Menu
	------------------------------------------------------------------------------------------------
	helpMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"h",
				"Hammerspoon Manual",
				{
					{
						cons.act.func,
						function()
							hs.doc.hsdocs.forceExternalBrowser(true)
							hs.doc.hsdocs.moduleEntitiesInSidebar(true)
							hs.doc.hsdocs.help()
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"m",
				"MenuHammer Documentation",
				{
					{ cons.act.openurl, "https://github.com/FryJay/MenuHammer" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Application Menu
	------------------------------------------------------------------------------------------------
	applicationMenu = {
		parentMenu = mainMenu,
		menuHotkey = { { "cmd", "alt", "ctrl" }, "a" },
		menuItems = {
			{ cons.cat.action, "", "a", "App Store", {
				{ cons.act.launcher, "App Store" },
			} },
			{
				cons.cat.action,
				"",
				"c",
				"Chrome",
				{
					{ cons.act.launcher, "Google Chrome" },
				},
			},
			{
				cons.cat.action,
				"",
				"d",
				"Microsoft Remote Desktop",
				{
					{ cons.act.launcher, "Microsoft Remote Desktop" },
				},
			},
			{ cons.cat.action, "", "f", "Finder", {
				{ cons.act.launcher, "Finder" },
			} },
			{ cons.cat.action, "", "h", "Firefox", {
				{ cons.act.launcher, "Firefox" },
			} },
			{ cons.cat.action, "", "i", "iTerm", {
				{ cons.act.launcher, "iTerm" },
			} },
			{
				cons.cat.action,
				"",
				"k",
				"Karabiner",
				{
					{ cons.act.launcher, "Karabiner-Elements" },
				},
			},
			{
				cons.cat.action,
				"",
				"l",
				"Sublime Text",
				{
					{ cons.act.launcher, "Sublime Text" },
				},
			},
			{ cons.cat.action, "", "m", "MacVim", {
				{ cons.act.launcher, "MacVim" },
			} },
			{ cons.cat.action, "", "s", "Safari", {
				{ cons.act.launcher, "Safari" },
			} },
			{ cons.cat.action, "", "t", "Terminal", {
				{ cons.act.launcher, "Terminal" },
			} },
			{ cons.cat.submenu, "", "u", "Utilities", {
				{ cons.act.menu, utilitiesMenu },
			} },
			{ cons.cat.action, "", "x", "Xcode", {
				{ cons.act.launcher, "Xcode" },
			} },
		},
	},

	------------------------------------------------------------------------------------------------
	-- Utilities Menu
	------------------------------------------------------------------------------------------------
	utilitiesMenu = {
		parentMenu = applicationMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"a",
				"Activity Monitor",
				{
					{ cons.act.launcher, "Activity Monitor" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"A",
				"Airport Utility",
				{
					{ cons.act.launcher, "Airport Utility" },
				},
			},
			{ cons.cat.action, "", "c", "Console", {
				{ cons.act.launcher, "Console" },
			} },
			{
				cons.cat.action,
				"",
				"d",
				"Disk Utility",
				{
					{ cons.act.launcher, "Disk Utility" },
				},
			},
			{
				cons.cat.action,
				"",
				"k",
				"Keychain Access",
				{
					{ cons.act.launcher, "Keychain Access" },
				},
			},
			{
				cons.cat.action,
				"",
				"s",
				"System Information",
				{
					{ cons.act.launcher, "System Information" },
				},
			},
			{ cons.cat.action, "", "t", "Terminal", {
				{ cons.act.launcher, "Terminal" },
			} },
		},
	},

	------------------------------------------------------------------------------------------------
	-- Browser Menu
	------------------------------------------------------------------------------------------------
	browserMenu = {
		parentMenu = mainMenu,
		meunHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"c",
				"Chrome",
				{
					{ cons.act.launcher, "Google Chrome" },
				},
			},
			{ cons.cat.action, "", "f", "Firefox", {
				{ cons.act.launcher, "Firefox" },
			} },
			{
				cons.cat.action,
				"",
				"m",
				"Movie Lookup",
				{
					{
						cons.act.userinput,
						"movieLookup",
						"Movie Lookup",
						"Enter search criteria",
					},
					{
						cons.act.openurl,
						"http://www.google.com/search?q=@@movieLookup@@%20film%20site:wikipedia.org&meta=&btnI",
					},
					{
						cons.act.openurl,
						"http://www.google.com/search?q=@@movieLookup@@%20site:imdb.com&meta=&btnI",
					},
					{
						cons.act.openurl,
						"http://www.google.com/search?q=@@movieLookup@@%20site:rottentomatoes.com&meta=&btnI",
					},
				},
			},
			{ cons.cat.action, "", "S", "Safari", {
				{ cons.act.launcher, "Safari" },
			} },
		},
	},

	------------------------------------------------------------------------------------------------
	-- Documents Menu
	------------------------------------------------------------------------------------------------
	[documentsMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"c",
				".config",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "g" },
					{ cons.act.typetext, "~/.config\n" },
				},
			},
			{
				cons.cat.action,
				"",
				"d",
				"Google Drive (local)",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "g" },
					{ cons.act.typetext, "~/Google Drive\n" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"D",
				"Google Drive (online)",
				{
					{ cons.act.openurl, "https://drive.google.com/" },
				},
			},
			{
				cons.cat.action,
				"",
				"i",
				"iCloud Drive (local)",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "i" },
				},
			},
			{
				cons.cat.action,
				"",
				"h",
				"Hammerspoon",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "g" },
					{ cons.act.typetext, "~/.hammerspoon\n" },
				},
			},
			{
				cons.cat.action,
				"",
				"m",
				"MenuHammer Custom Config",
				{
					{ cons.act.openfile, "~/.hammerspoon/menuHammerCustomConfig.lua" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"M",
				"MenuHammer Default Config",
				{
					{ cons.act.openfile, "~/.hammerspoon/Spoons/MenuHammer.spoon/MenuConfigDefaults.lua" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"H",
				"Hammerspoon init.lua",
				{
					{ cons.act.openfile, "~/.hammerspoon/init.lua" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Finder Menu
	------------------------------------------------------------------------------------------------
	finderMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"a",
				"Applications Folder",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "a" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"A",
				"Airdrop",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "r" },
				},
			},
			{
				cons.cat.action,
				"",
				"c",
				"Computer",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "c" },
				},
			},
			{
				cons.cat.action,
				"",
				"d",
				"Desktop",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "d" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"D",
				"Downloads",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "alt" }, "l" },
				},
			},
			{ cons.cat.action, "", "F", "Finder", {
				{ cons.act.launcher, "Finder" },
			} },
			{
				cons.cat.action,
				"",
				"g",
				"Go to Folder...",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "g" },
				},
			},
			{
				cons.cat.action,
				"",
				"h",
				"Home",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "h" },
				},
			},
			{
				cons.cat.action,
				"shift",
				"H",
				"Hammerspoon",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "g" },
					{ cons.act.typetext, "~/.hammerspoon\n" },
				},
			},
			{
				cons.cat.action,
				"",
				"i",
				"iCloud Drive",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "i" },
				},
			},
			{
				cons.cat.action,
				"",
				"k",
				"Connect to Server...",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd" }, "K" },
				},
			},
			{
				cons.cat.action,
				"",
				"l",
				"Library",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "l" },
				},
			},
			{
				cons.cat.action,
				"",
				"n",
				"Network",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "k" },
				},
			},
			{
				cons.cat.action,
				"",
				"o",
				"Documents",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "o" },
				},
			},
			{
				cons.cat.action,
				"",
				"r",
				"Recent",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "f" },
				},
			},
			{
				cons.cat.action,
				"",
				"u",
				"Utilities",
				{
					{ cons.act.launcher, "Finder" },
					{ cons.act.keycombo, { "cmd", "shift" }, "u" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Games Menu
	------------------------------------------------------------------------------------------------
	[gamesMenu] = {
		parentMenu = applicationMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"g",
				"GOG Galaxy",
				{
					{ cons.act.launcher, "GOG Galaxy" },
				},
			},
			{ cons.cat.action, "", "S", "Steam", {
				{ cons.act.launcher, "Steam" },
			} },
		},
	},

	------------------------------------------------------------------------------------------------
	-- Hammerspoon Menu
	------------------------------------------------------------------------------------------------
	hammerspoonMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"c",
				"Hammerspoon Console",
				{
					{
						cons.act.func,
						function()
							hs.toggleConsole()
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"h",
				"Hammerspoon Manual",
				{
					{
						cons.act.func,
						function()
							hs.doc.hsdocs.forceExternalBrowser(true)
							hs.doc.hsdocs.moduleEntitiesInSidebar(true)
							hs.doc.hsdocs.help()
						end,
					},
				},
			},
			{
				cons.cat.action,
				"shift",
				"R",
				"Reload Hammerspoon",
				{
					{
						cons.act.func,
						function()
							hs.reload()
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"q",
				"Quit Hammerspoon",
				{
					{
						cons.act.func,
						function()
							os.exit()
						end,
					},
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Layout Menu
	------------------------------------------------------------------------------------------------
	[layoutMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"e",
				"Split Safari/iTunes",
				{
					{
						cons.act.func,
						function()
							-- See Hammerspoon layout documentation for more info on this
							local mainScreen = hs.screen({ x = 0, y = 0 })
							hs.layout.apply({
								{ "Safari", nil, mainScreen, hs.layout.left50, nil, nil },
								{ "iTunes", nil, mainScreen, hs.layout.right50, nil, nil },
							})
						end,
					},
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Media Menu
	------------------------------------------------------------------------------------------------
	mediaMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{ cons.cat.action, "", "A", "iTunes", {
				{ cons.act.launcher, "iTunes" },
			} },
			{
				cons.cat.action,
				"",
				"h",
				"Previous Track",
				{
					{ cons.act.mediakey, "previous" },
				},
			},
			{
				cons.cat.action,
				"",
				"j",
				"Volume Down",
				{
					{ cons.act.mediakey, "volume", -10 },
				},
			},
			{
				cons.cat.action,
				"",
				"k",
				"Volume Up",
				{
					{ cons.act.mediakey, "volume", 10 },
				},
			},
			{ cons.cat.action, "", "L", "Next Track", {
				{ cons.act.mediakey, "next" },
			} },
			{ cons.cat.action, "", "X", "Mute/Unmute", {
				{ cons.act.mediakey, "mute" },
			} },
			{
				cons.cat.action,
				"",
				"s",
				"Play/Pause",
				{
					{ cons.act.mediakey, "playpause" },
				},
			},
			{
				cons.cat.action,
				"",
				"i",
				"Brightness Down",
				{
					{ cons.act.mediakey, "brightness", -10 },
				},
			},
			{
				cons.cat.action,
				"",
				"o",
				"Brightness Up",
				{
					{ cons.act.mediakey, "brightness", 10 },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Open Files Menu
	------------------------------------------------------------------------------------------------
	openFilesMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {},
	},

	------------------------------------------------------------------------------------------------
	-- Resolution Menu
	------------------------------------------------------------------------------------------------
	resolutionMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = resolutionMenuItems,
	},

	------------------------------------------------------------------------------------------------
	-- Scripts Menu
	------------------------------------------------------------------------------------------------
	[scriptsMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {},
	},

	------------------------------------------------------------------------------------------------
	-- System Menu
	------------------------------------------------------------------------------------------------
	systemMenu = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"shift",
				"F",
				"Force Quit Frontmost App",
				{
					{ cons.act.system, cons.sys.forcequit },
				},
			},
			{
				cons.cat.action,
				"",
				"l",
				"Lock Screen",
				{
					{ cons.act.system, cons.sys.lockscreen },
				},
			},
			{
				cons.cat.action,
				"shift",
				"R",
				"Restart System",
				{
					{ cons.act.system, cons.sys.restart, true },
				},
			},
			{
				cons.cat.action,
				"",
				"s",
				"Start Screensaver",
				{
					{ cons.act.system, cons.sys.screensaver },
				},
			},
			{
				cons.cat.action,
				"shift",
				"S",
				"Shutdown System",
				{
					{ cons.act.system, cons.sys.shutdown, true },
				},
			},
			{ cons.cat.action, "", "Q", "Logout", {
				{ cons.act.system, cons.sys.logout },
			} },
			{
				cons.cat.action,
				"shift",
				"Q",
				"Logout Immediately",
				{
					{ cons.act.system, cons.sys.logoutnow },
				},
			},
			{
				cons.cat.action,
				"",
				"u",
				"Switch User",
				{
					{ cons.act.system, cons.sys.switchuser, true },
				},
			},
			{
				cons.cat.action,
				"",
				"v",
				"Activity Monitor",
				{
					{ cons.act.launcher, "Activity Monitor" },
				},
			},
			{
				cons.cat.action,
				"",
				"x",
				"System Preferences",
				{
					{ cons.act.launcher, "System Preferences" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Text Menu
	------------------------------------------------------------------------------------------------
	[textMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"c",
				"Remove clipboard format",
				{
					{
						cons.act.func,
						function()
							local pasteboardContents = hs.pasteboard.getContents()
							hs.pasteboard.setContents(pasteboardContents)
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"e",
				"Empty the clipboard",
				{
					{
						cons.act.func,
						function()
							hs.pasteboard.setContents("")
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"t",
				"Type clipboard contents",
				{
					{ cons.act.typetext, "@@mhClipboardText@@" },
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Toggle menu
	------------------------------------------------------------------------------------------------
	[toggleMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"c",
				"Caffeine",
				{
					{
						cons.act.func,
						function()
							toggleCaffeine()
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"d",
				"Hide/Show Dock",
				{
					{ cons.act.keycombo, { "cmd", "alt" }, "d" },
				},
			},
			{
				cons.cat.action,
				"",
				"s",
				"Start Screensaver",
				{
					{ cons.act.system, cons.sys.screensaver },
				},
			},
			{
				cons.cat.action,
				"shift",
				"W",
				"Disable wi-fi",
				{
					{
						cons.act.func,
						function()
							hs.wifi.setPower(false)
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"w",
				"Enable wi-fi",
				{
					{
						cons.act.func,
						function()
							hs.wifi.setPower(true)
						end,
					},
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- WezTerm Workspaces Menu
	------------------------------------------------------------------------------------------------
	[weztermMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"d",
				"Dotfiles (T)",
				{
					{
						cons.act.func,
						function()
							openWezTermAt("~/dotfiles", "T")
						end,
					},
				},
			},
			{
				cons.cat.action,
				"",
				"f",
				"DeckFusion (B)",
				{
					{
						cons.act.func,
						function()
							arcBrowser.openToSpace("DF", "B")
						end,
					},
				},
			},
		},
	},

	------------------------------------------------------------------------------------------------
	-- Projects Menu
	------------------------------------------------------------------------------------------------
	[projectsMenu] = {
		parentMenu = mainMenu,
		menuHotkey = nil,
		menuItems = {
			{
				cons.cat.action,
				"",
				"f",
				"Fuse (DeckFusion)",
				{
					{
						cons.act.func,
						function()
							projectLauncher.open({
								name = "Fuse",
								wezterm = { dir = "~/dev/client/deckfusion", workspace = "T" },
								arc = { space = "DF", workspace = "B" },
								windsurf = { dir = "~/dev/client/deckfusion", workspace = "X" },
								orbstack = { workspace = "D" },
							})
						end,
					},
				},
			},
		},
	},
}
