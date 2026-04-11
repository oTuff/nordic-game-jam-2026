local lip = require("vendor.lip")
local push = require("vendor.push")
local menu = require("src.menu")
local keybind_menu = require("src.keybind_menu")
local video_menu = require("src.video_menu")
local sound_menu = require("src.sound_menu")

local settings_menu = {}

function settings_menu.init()
	Game.keybind_menu = keybind_menu
	Game.video_menu = video_menu
	Game.sound_menu = sound_menu

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
		{
			label = "Sound",
			action = function()
				Game.currentState = GameState.settings_sound
				Game.sound_menu.open = true
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

function settings_menu.mousepressed(x, y, btn)
	if btn == 1 and settings_menu.backHitTest(x, y) then
		Game.currentState = Game._settings_return or GameState.menu
		Game._settings_return = nil
		return
	end
	menu.mousepressed(settings_menu.menu, x, y, btn)
end

function settings_menu.backHitTest(x, y)
	local h = GAME_HEIGHT
	return x >= 40 and x < 160 and y >= h - 90 and y < h - 50
end

function settings_menu.mousemoved(x, y)
	menu.mousemoved(settings_menu.menu, x, y)
end

function settings_menu.draw()
	menu.draw(settings_menu.menu, "Settings")

	-- Back button
	local w, h = GAME_WIDTH, GAME_HEIGHT
	local backX, backY, backW, backH = 40, h - 90, 120, 40
	local mx, my = 0, 0
	if love.mouse.getPosition then
		local rx, ry = love.mouse.getPosition()
		mx, my = push.toGame(rx, ry)
		mx = mx or 0
		my = my or 0
	end
	local backHover = mx >= backX and mx < backX + backW and my >= backY and my < backY + backH
	if backHover then
		love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
		love.graphics.rectangle("fill", backX, backY, backW, backH)
		love.graphics.setColor(1, 1, 0.5)
	else
		love.graphics.setColor(0.8, 0.8, 0.8)
	end
	love.graphics.printf("< Back", backX, backY + 4, backW, "center")
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

function settings_menu.keybinds.mousepressed(x, y, btn)
	if btn == 1 and keybind_menu.backHitTest(x, y) then
		keybind_menu.open = false
		Game.currentState = GameState.settings
		lip.save(SETTINGS_FILENAME, Game.settings)
		return
	end
	keybind_menu.mousepressed(x, y, btn)
end

function settings_menu.keybinds.mousemoved(x, y)
	keybind_menu.mousemoved(x, y)
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

function settings_menu.video.mousepressed(x, y, btn)
	if btn == 1 and video_menu.backHitTest(x, y) then
		video_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	video_menu.mousepressed(x, y, btn)
end

function settings_menu.video.mousemoved(x, y)
	video_menu.mousemoved(x, y)
end

function settings_menu.video.draw()
	video_menu.draw()
end

-- Sound sub-screen
settings_menu.sound = {}

function settings_menu.sound.keypressed(key)
	if key == "escape" then
		sound_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	sound_menu.keypressed(key)
end

function settings_menu.sound.gamepadpressed(button)
	if button == "b" then
		sound_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	sound_menu.gamepadpressed(button)
end

function settings_menu.sound.mousepressed(x, y, btn)
	if btn == 1 and sound_menu.backHitTest(x, y) then
		sound_menu.open = false
		Game.currentState = GameState.settings
		return
	end
	sound_menu.mousepressed(x, y, btn)
end

function settings_menu.sound.mousemoved(x, y)
	sound_menu.mousemoved(x, y)
end

function settings_menu.sound.draw()
	sound_menu.draw()
end

return settings_menu
