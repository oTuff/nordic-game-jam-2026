local lip = require("vendor.lip")
local push = require("vendor.push")
local sound = require("src.sound")

local sound_menu = {
	open = false,
	selected = 1,
}

local items = {
	{ key = "master",  label = "Master Volume" },
	{ key = "sfx",     label = "SFX Volume" },
	{ key = "ambient", label = "Ambient Volume" },
}

local STEP = 10

local function clamp(val)
	if val < 0 then return 0 end
	if val > 100 then return 100 end
	return val
end

local function apply_sound()
	sound.applyVolumes()
	lip.save(SETTINGS_FILENAME, Game.settings)
end

function sound_menu.keypressed(key)
	if not sound_menu.open then return false end

	if key == "up" then
		sound_menu.selected = sound_menu.selected - 1
		if sound_menu.selected < 1 then sound_menu.selected = #items end
		return true
	end

	if key == "down" then
		sound_menu.selected = sound_menu.selected + 1
		if sound_menu.selected > #items then sound_menu.selected = 1 end
		return true
	end

	local item = items[sound_menu.selected]

	if key == "left" or key == "right" then
		local s = Game.settings.sound
		local delta = key == "right" and STEP or -STEP
		s[item.key] = clamp(s[item.key] + delta)
		apply_sound()
		return true
	end

	return false
end

function sound_menu.gamepadpressed(button)
	if not sound_menu.open then return false end

	if button == "dpup" then
		return sound_menu.keypressed("up")
	end
	if button == "dpdown" then
		return sound_menu.keypressed("down")
	end
	if button == "dpleft" then
		return sound_menu.keypressed("left")
	end
	if button == "dpright" then
		return sound_menu.keypressed("right")
	end
	return false
end

function sound_menu.mousepressed(x, y, btn)
	if not sound_menu.open or btn ~= 1 then return false end

	local w = GAME_WIDTH
	local startY = 200
	local rowH = 55
	local labelX = w / 2 - 250
	local valX = w / 2 + 20
	local valW = 350
	local rowW = valX + valW - labelX + 10

	for i, _ in ipairs(items) do
		local iy = startY + (i - 1) * rowH
		if y >= iy - 5 and y < iy + rowH - 5 and x >= labelX - 10 and x < labelX - 10 + rowW then
			sound_menu.selected = i
			local midX = valX + valW / 2
			if x >= valX then
				if x < midX then
					sound_menu.keypressed("left")
				else
					sound_menu.keypressed("right")
				end
			end
			return true
		end
	end
	return false
end

function sound_menu.mousemoved(x, y)
	if not sound_menu.open then return end

	local w = GAME_WIDTH
	local startY = 200
	local rowH = 55
	local labelX = w / 2 - 250
	local valX = w / 2 + 20
	local valW = 350
	local rowW = valX + valW - labelX + 10

	for i, _ in ipairs(items) do
		local iy = startY + (i - 1) * rowH
		if y >= iy - 5 and y < iy + rowH - 5 and x >= labelX - 10 and x < labelX - 10 + rowW then
			sound_menu.selected = i
			return
		end
	end
end

function sound_menu.draw()
	if not sound_menu.open then return end

	local w, h = GAME_WIDTH, GAME_HEIGHT
	local s = Game.settings.sound

	-- Dim background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, w, h)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Sound", 0, 80, w, "center")

	-- Items
	local startY = 200
	local rowH = 55
	local labelX = w / 2 - 250
	local valX = w / 2 + 20
	local valW = 350

	for i, item in ipairs(items) do
		local y = startY + (i - 1) * rowH

		-- Highlight selected row
		if i == sound_menu.selected then
			love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
			love.graphics.rectangle("fill", labelX - 10, y - 5, valX + valW - labelX + 10, rowH - 5)
		end

		-- Label
		if i == sound_menu.selected then
			love.graphics.setColor(1, 1, 0.5)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(item.label, labelX, y)

		-- Value with arrows and bar
		local val = s[item.key]
		love.graphics.setColor(0.8, 0.8, 0.8)
		love.graphics.printf(string.format("< %d%% >", val), valX, y, valW, "center")

		-- Volume bar
		local barX = valX + 40
		local barY = y + 32
		local barW = valW - 80
		local barH = 6
		love.graphics.setColor(0.3, 0.3, 0.3)
		love.graphics.rectangle("fill", barX, barY, barW, barH)
		love.graphics.setColor(0.6, 0.8, 0.6)
		love.graphics.rectangle("fill", barX, barY, barW * val / 100, barH)
	end

	-- Back button
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

	-- Help text
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Left/Right to change, Escape to go back", 0, h - 40, w, "center")
end

function sound_menu.backHitTest(x, y)
	local h = GAME_HEIGHT
	return x >= 40 and x < 160 and y >= h - 90 and y < h - 50
end

return sound_menu
