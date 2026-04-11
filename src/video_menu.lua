local lip = require("vendor.lip")
local push = require("vendor.push")

local video_menu = {
	open = false,
	selected = 1,
}

local resolutions = {
	{ w = 1024, h = 768 },
	{ w = 1280, h = 960 },
	{ w = 1366, h = 768 },
	{ w = 1600, h = 900 },
	{ w = 1920, h = 1080 },
}

local msaa_options = { 0, 2, 4, 8, 16 }

local items = {
	{ key = "resolution", label = "Resolution" },
	{ key = "fullscreen", label = "Fullscreen" },
	{ key = "vsync",      label = "VSync" },
	{ key = "msaa",       label = "Anti-Aliasing" },
}

local function current_res_index()
	local s = Game.settings.video
	for i, r in ipairs(resolutions) do
		if r.w == s.width and r.h == s.height then
			return i
		end
	end
	return 1
end

local function current_msaa_index()
	local msaa = Game.settings.video.msaa
	for i, v in ipairs(msaa_options) do
		if v == msaa then return i end
	end
	return 1
end

local function apply_video()
	local s = Game.settings.video
	local flags = {
		resizable = true,
		minwidth = 1024,
		minheight = 768,
		fullscreen = s.fullscreen,
		vsync = s.vsync and 1 or 0,
		highdpi = true,
		usedpiscale = false,
		msaa = s.msaa,
	}
	love.window.setMode(s.width, s.height, flags)
	push.resize()
	lip.save(SETTINGS_FILENAME, Game.settings)
end

function video_menu.keypressed(key)
	if not video_menu.open then return false end

	if key == "up" then
		video_menu.selected = video_menu.selected - 1
		if video_menu.selected < 1 then video_menu.selected = #items end
		return true
	end

	if key == "down" then
		video_menu.selected = video_menu.selected + 1
		if video_menu.selected > #items then video_menu.selected = 1 end
		return true
	end

	local item = items[video_menu.selected]

	if key == "left" or key == "right" then
		local s = Game.settings.video
		if item.key == "resolution" then
			local idx = current_res_index()
			if key == "right" then
				idx = idx + 1
				if idx > #resolutions then idx = 1 end
			else
				idx = idx - 1
				if idx < 1 then idx = #resolutions end
			end
			s.width = resolutions[idx].w
			s.height = resolutions[idx].h
		elseif item.key == "fullscreen" then
			s.fullscreen = not s.fullscreen
		elseif item.key == "vsync" then
			s.vsync = not s.vsync
		elseif item.key == "msaa" then
			local idx = current_msaa_index()
			if key == "right" then
				idx = idx + 1
				if idx > #msaa_options then idx = 1 end
			else
				idx = idx - 1
				if idx < 1 then idx = #msaa_options end
			end
			s.msaa = msaa_options[idx]
		end
		apply_video()
		return true
	end

	if key == "return" then
		local s = Game.settings.video
		if item.key == "fullscreen" then
			s.fullscreen = not s.fullscreen
		elseif item.key == "vsync" then
			s.vsync = not s.vsync
		end
		apply_video()
		return true
	end

	return false
end

function video_menu.gamepadpressed(button)
	if not video_menu.open then return false end

	if button == "dpup" then
		return video_menu.keypressed("up")
	end
	if button == "dpdown" then
		return video_menu.keypressed("down")
	end
	if button == "dpleft" then
		return video_menu.keypressed("left")
	end
	if button == "dpright" then
		return video_menu.keypressed("right")
	end
	if button == "a" then
		return video_menu.keypressed("return")
	end
	return false
end

function video_menu.mousepressed(x, y, btn)
	if not video_menu.open or btn ~= 1 then return false end

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
			video_menu.selected = i
			local midX = valX + valW / 2
			if x >= valX then
				if x < midX then
					video_menu.keypressed("left")
				else
					video_menu.keypressed("right")
				end
			end
			return true
		end
	end
	return false
end

function video_menu.mousemoved(x, y)
	if not video_menu.open then return end

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
			video_menu.selected = i
			return
		end
	end
end

function video_menu.draw()
	if not video_menu.open then return end

	local w, h = GAME_WIDTH, GAME_HEIGHT
	local s = Game.settings.video

	-- Dim background
	love.graphics.setColor(0, 0, 0, 0.7)
	love.graphics.rectangle("fill", 0, 0, w, h)

	-- Title
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Video", 0, 80, w, "center")

	-- Items
	local startY = 200
	local rowH = 55
	local labelX = w / 2 - 250
	local valX = w / 2 + 20
	local valW = 350

	for i, item in ipairs(items) do
		local y = startY + (i - 1) * rowH

		-- Highlight selected row
		if i == video_menu.selected then
			love.graphics.setColor(0.3, 0.3, 0.5, 0.8)
			love.graphics.rectangle("fill", labelX - 10, y - 5, valX + valW - labelX + 10, rowH - 5)
		end

		-- Label
		if i == video_menu.selected then
			love.graphics.setColor(1, 1, 0.5)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(item.label, labelX, y)

		-- Value with arrows
		love.graphics.setColor(0.8, 0.8, 0.8)
		local val
		if item.key == "resolution" then
			val = string.format("< %dx%d >", s.width, s.height)
		elseif item.key == "fullscreen" then
			val = s.fullscreen and "< On >" or "< Off >"
		elseif item.key == "vsync" then
			val = s.vsync and "< On >" or "< Off >"
		elseif item.key == "msaa" then
			val = s.msaa == 0 and "< Off >" or string.format("< %dx >", s.msaa)
		end
		love.graphics.printf(val, valX, y, valW, "center")
	end

	-- Back button
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

	-- Help text
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf("Left/Right to change, Escape to go back", 0, h - 40, w, "center")
end

function video_menu.backHitTest(x, y)
	local h = GAME_HEIGHT
	return x >= 40 and x < 160 and y >= h - 90 and y < h - 50
end

return video_menu
