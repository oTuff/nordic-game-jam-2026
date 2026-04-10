local push = require("vendor.push")
local lip = require("vendor.lip")
local loader = require("src.loader")
local player = require("src.models.player")
local enemy = require("src.models.enemy")
local physics = require("src.models.physics")
local sti = require("vendor.sti")
local menu = require("src.menu")
local keybind_menu = require("src.keybind_menu")
local video_menu = require("src.video_menu")

---@class Object
---@field x integer
---@field y integer
---@field sprite love.Image
---@field update? fun(self, dt:number)

function love.load()
	--[[ Constants(not supposed to change): denoted with CAPITALIZED snake_case ]]
	TILE_SIZE = 32
	GAME_WIDTH, GAME_HEIGHT = 1024, 768
	SETTINGS_FILENAME = "settings.ini"

	push.setupScreen(GAME_WIDTH, GAME_HEIGHT)
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setNewFont(36)

	Gamemap = sti("assets/tield/frø.lua")
	Gamemap:resize(GAME_WIDTH, GAME_HEIGHT)
	WORLD_WIDTH  = Gamemap.width * Gamemap.tilewidth
	WORLD_HEIGHT = Gamemap.height * Gamemap.tileheight

	-- Reading environment variable DEBUG and load the dbg tool
	DEBUG        = os.getenv("DEBUG")
	if DEBUG then
		dbg = require("tools.debugger")
	end

	---@enum Gamestate
	GameState = {
		menu = "menu",
		playing = "playing",
		paused = "paused",
		settings = "settings",
		settings_keybinds = "settings_keybinds",
		settings_video = "settings_video",
		credits = "credits",
		gameOver = "gameOver",
	}

	-- Read settings
	local defaults = {
		controls = {
			move_left = "a",
			move_right = "d",
			jump = "w",
			move_down = "s",
		},
		gamepad = {
			move_left = "dpleft",
			move_right = "dpright",
			jump = "a",
			move_down = "dpdown",
		},
		video = {
			width = 1024,
			height = 768,
			fullscreen = false,
			vsync = true,
			msaa = 0,
		},
	}

	local data
	if love.filesystem.getInfo(SETTINGS_FILENAME) then
		data = lip.load(SETTINGS_FILENAME)
	end
	if not data then
		data = defaults
		lip.save(SETTINGS_FILENAME, data)
	else
		-- Fill in any missing keys from defaults
		for section, keys in pairs(defaults) do
			if not data[section] then
				data[section] = keys
			else
				for key, value in pairs(keys) do
					if data[section][key] == nil then
						data[section][key] = value
					end
				end
			end
		end
	end

	-- Apply saved video settings
	local vid = data.video
	love.window.setMode(vid.width, vid.height, {
		resizable = true,
		minwidth = 1024,
		minheight = 768,
		fullscreen = vid.fullscreen,
		vsync = vid.vsync and 1 or 0, ---@diagnostic disable-line: assign-type-mismatch
		highdpi = true,
		usedpiscale = false,
		msaa = vid.msaa,
	})
	push.resize()

	-- Global `game` object
	Game = {
		---@type Gamestate
		currentState = GameState.menu,
		assets = loader.load(),
		settings = data,
		keybind_menu = keybind_menu,
		video_menu = video_menu,
	}

	-- Menus
	Game.main_menu = menu.new({
		{
			label = "Play",
			action = function()
				Game.currentState = GameState.playing
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

	Game.pause_menu = menu.new({
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
			end,
		},
		{
			label = "Quit",
			action = function()
				love.event.quit()
			end,
		},
	})

	Game.settings_menu = menu.new({
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

	Game.camera = { x = 0, y = 0 }
	Game.player = player.new(100, 100)
	--- @type Object[]
	Game.objects = {
		-- Static game objects
		{ x = 300, y = 300, sprite = Game.assets.images.test },
		{ x = 350, y = 400, sprite = Game.assets.images.test },

		-- Enemies
		enemy.new(400, 100),
		enemy.new(500, 250),
		enemy.new(600, 600),
	}
end

---@param dt number
function love.update(dt)
	if Game.currentState ~= GameState.playing then return end

	local p = Game.player

	p:update(dt)

	for _, obj in ipairs(Game.objects) do
		if physics.CheckCollosion(p, obj) then
			print("col " .. p.body.x .. " " .. p.body.y)
		end

		if obj.update then
			obj:update(dt)
		end
	end

	-- Camera
	local cam = Game.camera
	local targetX = p.body.x - GAME_WIDTH / 2
	local targetY = p.body.y - GAME_HEIGHT / 2
	local smoothing = 1 - math.exp(-5 * dt)
	cam.x = cam.x + (targetX - cam.x) * smoothing
	cam.y = cam.y + (targetY - cam.y) * smoothing
	cam.x = math.max(0, math.min(WORLD_WIDTH - GAME_WIDTH, cam.x))
	cam.y = math.max(0, math.min(WORLD_HEIGHT - GAME_HEIGHT, cam.y))
end

function love.draw()
	if DEBUG then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(("FPS: %d"):format(love.timer.getFPS()), 8, 8)
		print(dbg.pp(Game))
		print(dbg.pp(Game.objects[1]))
	end

	push.start()

	local state = Game.currentState

	if state == GameState.menu then
		menu.draw(Game.main_menu, "My Game")
	elseif state == GameState.credits then
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
	elseif state == GameState.settings then
		menu.draw(Game.settings_menu, "Settings")
	elseif state == GameState.settings_keybinds then
		Game.keybind_menu.draw()
	elseif state == GameState.settings_video then
		Game.video_menu.draw()
	else -- playing or paused: draw the game world
		local cx = -math.floor(Game.camera.x)
		local cy = -math.floor(Game.camera.y)

		-- Fix push working with sti
		local sx, sy, sw, sh = love.graphics.getScissor()
		love.graphics.setScissor()
		Gamemap:draw(cx, cy)
		love.graphics.setScissor(sx, sy, sw, sh)

		love.graphics.push()
		love.graphics.translate(cx, cy)

		local p = Game.player
		love.graphics.draw(p.sprite, p.body.x, p.body.y)

		for _, obj in ipairs(Game.objects) do
			love.graphics.draw(obj.sprite, obj.x, obj.y)
		end

		love.graphics.pop()

		-- Draw pause overlay on top of game
		if state == GameState.paused then
			menu.draw(Game.pause_menu, "Paused")
		end
	end

	push.finish()
end

function love.keypressed(key, scancode)
	local state = Game.currentState

	if state == GameState.menu then
		menu.keypressed(Game.main_menu, key)
	elseif state == GameState.credits then
		if key == "escape" then
			Game.currentState = GameState.menu
		end
	elseif state == GameState.settings then
		if key == "escape" then
			Game.currentState = Game._settings_return or GameState.menu
			Game._settings_return = nil
			return
		end
		menu.keypressed(Game.settings_menu, key)
	elseif state == GameState.settings_keybinds then
		if key == "escape" and not Game.keybind_menu.listening
		    and not Game.keybind_menu.has_any_unbound() then
			Game.keybind_menu.open = false
			Game.currentState = GameState.settings
			lip.save(SETTINGS_FILENAME, Game.settings)
			return
		end
		Game.keybind_menu.keypressed(key, scancode)
	elseif state == GameState.settings_video then
		if key == "escape" then
			Game.video_menu.open = false
			Game.currentState = GameState.settings
			return
		end
		Game.video_menu.keypressed(key)
	elseif state == GameState.playing then
		if key == "escape" then
			Game.currentState = GameState.paused
		end
	elseif state == GameState.paused then
		if key == "escape" then
			Game.currentState = GameState.playing
		else
			menu.keypressed(Game.pause_menu, key)
		end
	end
end

function love.gamepadpressed(joystick, button)
	local state = Game.currentState

	if state == GameState.menu then
		menu.gamepadpressed(Game.main_menu, button)
	elseif state == GameState.credits then
		if button == "b" then
			Game.currentState = GameState.menu
		end
	elseif state == GameState.settings then
		if button == "b" then
			Game.currentState = Game._settings_return or GameState.menu
			Game._settings_return = nil
			return
		end
		menu.gamepadpressed(Game.settings_menu, button)
	elseif state == GameState.settings_keybinds then
		if button == "b" and not Game.keybind_menu.listening
		    and not Game.keybind_menu.has_any_unbound() then
			Game.keybind_menu.open = false
			Game.currentState = GameState.settings
			lip.save(SETTINGS_FILENAME, Game.settings)
			return
		end
		Game.keybind_menu.gamepadpressed(button)
	elseif state == GameState.settings_video then
		if button == "b" then
			Game.video_menu.open = false
			Game.currentState = GameState.settings
			return
		end
		Game.video_menu.gamepadpressed(button)
	elseif state == GameState.playing then
		if button == "start" then
			Game.currentState = GameState.paused
		end
	elseif state == GameState.paused then
		if button == "b" or button == "start" then
			Game.currentState = GameState.playing
		else
			menu.gamepadpressed(Game.pause_menu, button)
		end
	end
end

function love.resize()
	Gamemap:resize(GAME_WIDTH, GAME_HEIGHT)
	return push.resize()
end
