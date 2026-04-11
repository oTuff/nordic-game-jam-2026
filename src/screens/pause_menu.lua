local menu = require("src.menu")
local sound = require("src.sound")

local pause_menu = {}

function pause_menu.init()
	pause_menu.menu = menu.new({
		{
			label = "Resume",
			action = function()
				Game.currentState = GameState.playing
			end,
		},
		{
			label = "Settings",
			action = function()
				Game.currentState = GameState.settings
				Game._settings_return = GameState.paused
			end,
		},
		{
			label = "Main Menu",
			action = function()
				Game.currentState = GameState.menu
				sound.stopAllAmbient()
			end,
		},
		{
			label = "Quit",
			action = function()
				love.event.quit()
			end,
		},
	})
end

function pause_menu.keypressed(key)
	if key == "escape" then
		Game.currentState = GameState.playing
	else
		menu.keypressed(pause_menu.menu, key)
	end
end

function pause_menu.gamepadpressed(button)
	if button == "b" or button == "start" then
		Game.currentState = GameState.playing
	else
		menu.gamepadpressed(pause_menu.menu, button)
	end
end

function pause_menu.draw()
	menu.draw(pause_menu.menu, "Paused")
end

return pause_menu
