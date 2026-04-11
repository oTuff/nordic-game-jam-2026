local menu = require("src.menu")
local sound = require("src.sound")

local main_menu = {}

function main_menu.init()
	main_menu.menu = menu.new({
		{
			label = "Play",
			action = function()
				Game.currentState = GameState.playing
				sound.updateAmbient()
			end,
		},
		{
			label = "Settings",
			action = function()
				Game.currentState = GameState.settings
				Game._settings_return = GameState.menu
			end,
		},
		{
			label = "Credits",
			action = function()
				Game.currentState = GameState.credits
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

function main_menu.keypressed(key)
	menu.keypressed(main_menu.menu, key)
end

function main_menu.gamepadpressed(button)
	menu.gamepadpressed(main_menu.menu, button)
end

function main_menu.draw()
	menu.draw(main_menu.menu, "TBD Game")
end

return main_menu
