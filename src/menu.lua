-- Generic menu: a vertical list of items with keyboard + gamepad navigation.
-- Each item is { label = "...", action = function, enabled = true/false }

local menu = {}

function menu.new(items)
	return {
		items = items,
		selected = 1,
	}
end

function menu.keypressed(m, key)
	if key == "up" then
		repeat
			m.selected = m.selected - 1
			if m.selected < 1 then m.selected = #m.items end
		until m.items[m.selected].enabled ~= false
		return true
	end

	if key == "down" then
		repeat
			m.selected = m.selected + 1
			if m.selected > #m.items then m.selected = 1 end
		until m.items[m.selected].enabled ~= false
		return true
	end

	if key == "return" then
		local item = m.items[m.selected]
		if item.enabled ~= false and item.action then
			item.action()
		end
		return true
	end

	return false
end

function menu.gamepadpressed(m, button)
	if button == "dpup" then
		return menu.keypressed(m, "up")
	end
	if button == "dpdown" then
		return menu.keypressed(m, "down")
	end
	if button == "a" then
		return menu.keypressed(m, "return")
	end
	return false
end

function menu.draw(m, title, y_offset)
	local w, h = GAME_WIDTH, GAME_HEIGHT
	y_offset = y_offset or 0

	-- Dim background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, w, h)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(title, 0, 120 + y_offset, w, "center")

	-- Items
	local startY = 250 + y_offset
	local rowH = 55
	for i, item in ipairs(m.items) do
		local y = startY + (i - 1) * rowH

		-- Highlight selected row
		if i == m.selected then
			love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
			love.graphics.rectangle("fill", w / 2 - 150, y - 5, 300, rowH - 5)
		end

		-- Label
		if item.enabled == false then
			love.graphics.setColor(0.4, 0.4, 0.4)
		elseif i == m.selected then
			love.graphics.setColor(1, 1, 0.5)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.printf(item.label, 0, y, w, "center")
	end
end

return menu
