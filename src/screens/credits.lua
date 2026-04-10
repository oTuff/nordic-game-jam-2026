local credits = {}

function credits.keypressed(key)
	if key == "escape" then
		Game.currentState = GameState.menu
	end
end

function credits.gamepadpressed(button)
	if button == "b" then
		Game.currentState = GameState.menu
	end
end

function credits.draw()
	local w, h = GAME_WIDTH, GAME_HEIGHT
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, w, h)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Credits", 0, 120, w, "center")
	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.printf("A game made for Nordic Game Jam 2026", 0, 250, w, "center")
	love.graphics.printf("Made by:", 0, 320, w, "center")
	love.graphics.printf("Oscar, William & Alexander Tuff", 0, 360, w, "center")
	love.graphics.setColor(0.6, 0.6, 0.6)
	love.graphics.printf("Escape to go back", 0, h - 80, w, "center")
end

return credits
