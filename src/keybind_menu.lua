local push = require("vendor.push")

local COLUMN_KEYBOARD = 1
local COLUMN_GAMEPAD = 2
local column_labels = { "Keyboard", "Gamepad" }

local keybind_menu = {
	open = false,
	listening = nil,
	selected = 1,
	column = COLUMN_KEYBOARD,
	conflict = nil,
	unbound = { controls = {}, gamepad = {} },
}

-- The action names and display labels (order matters for drawing)
local actions = {
	{ key = "interact",   label = "interact" },
	{ key = "move_up",    label = "Move Up" },
	{ key = "move_left",  label = "Move Left" },
	{ key = "move_right", label = "Move Right" },
	{ key = "move_down",  label = "Move Down" },
}

local function find_conflict(section, value, exclude_index)
	for i, action in ipairs(actions) do
		if i ~= exclude_index and Game.settings[section][action.key] == value then
			return i, action.label
		end
	end
	return nil, nil
end

local function apply_bind(section, index, value)
	local unbound = keybind_menu.unbound[section]
	for i, action in ipairs(actions) do
		if i ~= index and Game.settings[section][action.key] == value then
			Game.settings[section][action.key] = ""
			unbound[action.key] = true
		end
	end
	Game.settings[section][actions[index].key] = value
	unbound[actions[index].key] = nil
end

function keybind_menu.has_any_unbound()
	return next(keybind_menu.unbound.controls) or next(keybind_menu.unbound.gamepad)
end

local function handle_bind_input(section, value)
	local _, conflict_label = find_conflict(section, value, keybind_menu.listening)
	if conflict_label then
		keybind_menu.conflict = {
			index = keybind_menu.listening,
			value = value,
			label = conflict_label,
			section = section,
		}
	else
		Game.settings[section][actions[keybind_menu.listening].key] = value
		keybind_menu.unbound[section][actions[keybind_menu.listening].key] = nil
		keybind_menu.listening = nil
	end
end

function keybind_menu.keypressed(key, scancode)
	if not keybind_menu.open then return false end

	-- Awaiting conflict confirmation
	if keybind_menu.conflict then
		if key == "return" then
			apply_bind(keybind_menu.conflict.section, keybind_menu.conflict.index,
				keybind_menu.conflict.value)
		end
		keybind_menu.conflict = nil
		keybind_menu.listening = nil
		return true
	end

	-- Listening for a new bind
	if keybind_menu.listening then
		if key == "escape" then
			keybind_menu.listening = nil
			return true
		end
		if keybind_menu.column == COLUMN_KEYBOARD then
			handle_bind_input("controls", scancode)
		end
		return true
	end

	if key == "up" then
		keybind_menu.selected = keybind_menu.selected - 1
		if keybind_menu.selected < 1 then keybind_menu.selected = #actions end
		return true
	end

	if key == "down" then
		keybind_menu.selected = keybind_menu.selected + 1
		if keybind_menu.selected > #actions then keybind_menu.selected = 1 end
		return true
	end

	if key == "left" or key == "right" then
		keybind_menu.column = keybind_menu.column == COLUMN_KEYBOARD and COLUMN_GAMEPAD or COLUMN_KEYBOARD
		return true
	end

	if key == "return" then
		keybind_menu.listening = keybind_menu.selected
		return true
	end

	return false
end

function keybind_menu.gamepadpressed(button)
	if not keybind_menu.open then return false end

	-- Awaiting conflict confirmation
	if keybind_menu.conflict then
		if button == "a" then
			apply_bind(keybind_menu.conflict.section, keybind_menu.conflict.index,
				keybind_menu.conflict.value)
		end
		keybind_menu.conflict = nil
		keybind_menu.listening = nil
		return true
	end

	-- Listening for a new bind on gamepad column
	if keybind_menu.listening then
		if button == "b" then
			keybind_menu.listening = nil
			return true
		end
		if keybind_menu.column == COLUMN_GAMEPAD then
			handle_bind_input("gamepad", button)
		end
		return true
	end

	if button == "dpup" then
		keybind_menu.selected = keybind_menu.selected - 1
		if keybind_menu.selected < 1 then keybind_menu.selected = #actions end
		return true
	end

	if button == "dpdown" then
		keybind_menu.selected = keybind_menu.selected + 1
		if keybind_menu.selected > #actions then keybind_menu.selected = 1 end
		return true
	end

	if button == "dpleft" or button == "dpright" then
		keybind_menu.column = keybind_menu.column == COLUMN_KEYBOARD and COLUMN_GAMEPAD or COLUMN_KEYBOARD
		return true
	end

	if button == "a" then
		keybind_menu.listening = keybind_menu.selected
		return true
	end

	return false
end

function keybind_menu.mousepressed(x, y, btn)
	if not keybind_menu.open or btn ~= 1 then return false end
	if keybind_menu.conflict or keybind_menu.listening then return false end

	local w = GAME_WIDTH
	local labelX = w / 2 - 300
	local kbX = w / 2 - 70
	local gpX = w / 2 + 150
	local colW = 200
	local rowStartY = 190
	local rowH = 50

	for i, _ in ipairs(actions) do
		local iy = rowStartY + (i - 1) * rowH
		if y >= iy - 5 and y < iy + rowH - 5 and x >= labelX - 10 and x < gpX + colW + 10 then
			keybind_menu.selected = i
			if x >= gpX and x < gpX + colW then
				keybind_menu.column = COLUMN_GAMEPAD
			elseif x >= kbX and x < kbX + colW then
				keybind_menu.column = COLUMN_KEYBOARD
			end
			keybind_menu.listening = i
			return true
		end
	end
	return false
end

function keybind_menu.mousemoved(x, y)
	if not keybind_menu.open or keybind_menu.conflict or keybind_menu.listening then return end

	local w = GAME_WIDTH
	local labelX = w / 2 - 300
	local gpX = w / 2 + 150
	local colW = 200
	local rowStartY = 190
	local rowH = 50

	for i, _ in ipairs(actions) do
		local iy = rowStartY + (i - 1) * rowH
		if y >= iy - 5 and y < iy + rowH - 5 and x >= labelX - 10 and x < gpX + colW + 10 then
			keybind_menu.selected = i
			return
		end
	end
end

function keybind_menu.draw()
	if not keybind_menu.open then return end

	local w, h = GAME_WIDTH, GAME_HEIGHT

	-- Dim background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, w, h)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Keybinds", 0, 80, w, "center")

	-- Column layout
	local labelX = w / 2 - 300
	local kbX = w / 2 - 70
	local gpX = w / 2 + 150
	local colW = 200

	-- Column headers
	local startY = 130
	for col = 1, 2 do
		local x = col == 1 and kbX or gpX
		if keybind_menu.column == col then
			love.graphics.setColor(1, 1, 0.5)
		else
			love.graphics.setColor(0.6, 0.6, 0.6)
		end
		love.graphics.printf(column_labels[col], x, startY, colW, "center")
	end

	-- List actions
	local rowStartY = 190
	local rowH = 50
	for i, action in ipairs(actions) do
		local y = rowStartY + (i - 1) * rowH
		local kb_val = Game.settings.controls[action.key]
		local gp_val = Game.settings.gamepad[action.key]
		local kb_unbound = keybind_menu.unbound.controls[action.key]
		local gp_unbound = keybind_menu.unbound.gamepad[action.key]

		-- Highlight selected row
		if i == keybind_menu.selected then
			love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
			love.graphics.rectangle("fill", labelX - 10, y - 5, gpX + colW - labelX + 20, rowH - 5)
		end

		-- Action label (red if either is unbound)
		if kb_unbound or gp_unbound then
			love.graphics.setColor(1, 0.2, 0.2)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(action.label, labelX, y)

		-- Keyboard column
		local is_listening_kb = keybind_menu.listening == i and keybind_menu.column == COLUMN_KEYBOARD and
			not keybind_menu.conflict
		if is_listening_kb then
			love.graphics.setColor(1, 1, 0)
			love.graphics.printf("...", kbX, y, colW, "center")
		elseif kb_unbound then
			love.graphics.setColor(1, 0.2, 0.2)
			love.graphics.printf("UNBOUND", kbX, y, colW, "center")
		else
			love.graphics.setColor(0.8, 0.8, 0.8)
			love.graphics.printf(kb_val, kbX, y, colW, "center")
		end

		-- Gamepad column
		local is_listening_gp = keybind_menu.listening == i and keybind_menu.column == COLUMN_GAMEPAD and
			not keybind_menu.conflict
		if is_listening_gp then
			love.graphics.setColor(1, 1, 0)
			love.graphics.printf("...", gpX, y, colW, "center")
		elseif gp_unbound then
			love.graphics.setColor(1, 0.2, 0.2)
			love.graphics.printf("UNBOUND", gpX, y, colW, "center")
		else
			love.graphics.setColor(0.8, 0.8, 0.8)
			love.graphics.printf(gp_val, gpX, y, colW, "center")
		end
	end

	-- Conflict warning
	if keybind_menu.conflict then
		love.graphics.setColor(1, 0.2, 0.2)
		local msg = string.format(
			'"%s" is already bound to %s. Enter to confirm, any key to cancel.',
			keybind_menu.conflict.value,
			keybind_menu.conflict.label
		)
		love.graphics.printf(msg, 0, h - 160, w, "center")
	end

	-- Back button (only when not listening/conflicting and no unbound actions)
	if not keybind_menu.listening and not keybind_menu.conflict and not keybind_menu.has_any_unbound() then
		local backX, backY, backW, backH = 40, h - 90, 120, 40
		local mx, my
		if love.mouse.getPosition then
			local rx, ry = love.mouse.getPosition()
			mx, my = push.toGame(rx, ry)
		end
		local backHover = mx and my and mx >= backX and mx < backX + backW and my >= backY and my < backY + backH
		if backHover then
			love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
			love.graphics.rectangle("fill", backX, backY, backW, backH)
			love.graphics.setColor(1, 1, 0.5)
		else
			love.graphics.setColor(0.8, 0.8, 0.8)
		end
		love.graphics.printf("< Back", backX, backY + 4, backW, "center")
	end

	-- Help text
	love.graphics.setColor(1, 1, 1)
	if keybind_menu.has_any_unbound() then
		love.graphics.printf("Bind all actions before closing", 0, h - 40, w, "center")
	else
		love.graphics.printf("Arrows to navigate, Enter to rebind, Escape to close", 0, h - 40, w, "center")
	end
end

function keybind_menu.backHitTest(x, y)
	if keybind_menu.listening or keybind_menu.conflict or keybind_menu.has_any_unbound() then
		return false
	end
	local h = GAME_HEIGHT
	return x >= 40 and x < 160 and y >= h - 90 and y < h - 50
end

return keybind_menu
