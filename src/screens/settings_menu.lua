local lip = require("vendor.lip")
local menu = require("src.menu")
local keybind_menu = require("src.keybind_menu")
local video_menu = require("src.video_menu")

local settings_menu = {}

function settings_menu.init()
	Game.keybind_menu = keybind_menu
	Game.video_menu = video_menu

	settings_menu.menu = menu.new({
		{
			label = "Keybinds",
			action = function()
				Game.currentState = GameState.settings_keybinds
				Game.keybind_menu.open = true
			end,
		},
		{
			label = "Video",
			action = function()
				Game.currentState = GameState.settings_video
				Game.video_menu.open = true
			end,
		},
	})
end

function settings_menu.keypressed(key)
	if key == "escape" then
		Game.currentState = Game._settings_return or GameState.menu
		Game._settings_return = nil
		return
	end
	menu.keypressed(settings_menu.menu, key)
end

function settings_menu.gamepadpressed(button)
	if button == "b" then
		Game.currentState = Game._settings_return or GameState.menu
		Game._settings_return = nil
		return
	end
	menu.gamepadpressed(settings_menu.menu, button)
end

function settings_menu.draw()
	menu.draw(settings_menu.menu, "Settings")
end

-- Keybinds sub-screen
settings_menu.keybinds = {}

function settings_menu.keybinds.keypressed(key, scancode)
	if key == "escape" and not keybind_menu.listening
		and not keybind_menu.has_any_unbound() then
		keybind_menu.open = false
		Game.currentState = GameState.settings
		lip.save(SETTINGS_FILENAME, Game.settings)
		return
	end
	keybind_menu.keypressed(key, scancode)
end

function settings_menu.keybinds.gamepadpressed(button)
	if button == "b" and not keybind_menu.listening
		and not keybind_menu.has_any_unbound() then
		keybind_menu.open = false
		Game.currentState = GameState.settings
		lip.save(SETTINGS_FILENAME, Game.settings)
		return
	end
	keybind_menu.gamepadpressed(button)
end

function settings_menu.keybinds.draw()
	keybind_menu.draw()
end

-- Video sub-screen
settings_menu.video = {}

function settings_menu.video.keypressed(key)
	if key == "escape" then
		video_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	video_menu.keypressed(key)
end

function settings_menu.video.gamepadpressed(button)
	if button == "b" then
		video_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	video_menu.gamepadpressed(button)
end

function settings_menu.video.draw()
	video_menu.draw()
end

return settings_menu
