local push = require("vendor.push")
local lip = require("vendor.lip")
local loader = require("src.loader")
local player = require("src.models.player")
local enemy = require("src.models.enemy")
local physics = require("src.models.physics")
local sti = require("vendor.sti")

local main_menu = require("src.screens.main_menu")
local pause_menu = require("src.screens.pause_menu")
local settings_menu = require("src.screens.settings_menu")
local credits = require("src.screens.credits")

---@class Object
---@field x integer
---@field y integer
---@field col string

---@class Entity:Object
---@field sprite love.Image
---@field update function?

---@class Unlocks:Object
---@field color number[]
function love.load()
	--[[ Constants(not supposed to change): denoted with CAPITALIZED snake_case ]]
	TILE_SIZE = 32
	GAME_WIDTH, GAME_HEIGHT = 1024, 768
	SETTINGS_FILENAME = "settings.ini"

	push.setupScreen(GAME_WIDTH, GAME_HEIGHT)
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setNewFont(36)

	Gamemap = sti("assets/tield/rgb.lua")
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

	UnlockedColor = {
		red = false,
		green = false,
		blue = false
	}

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
	}

	-- Initialize screens
	main_menu.init()
	pause_menu.init()
	settings_menu.init()

	Game.camera = { x = 0, y = 0 }
	Game.player = player.new(100, 100)
	--- @type Unlocks[]
	Game.unlocks = {
		{ col = "red",   x = 150, y = 100, color = { 1, 0, 0, 1 } }, -- red 1
		{ col = "green", x = 200, y = 200, color = { 0, 1, 0, 1 } }, -- green 2
		{ col = "blue",  x = 300, y = 300, color = { 0, 0, 1, 1 } } -- blue 3
	}
	--- @type Entity[]
	Game.objects = {
		{ col = "red", x = 300, y = 300, sprite = Game.assets.images.test }
	}
end

-- Screen dispatch tables
local screen_draw = {
	menu = function() main_menu.draw() end,
	credits = function() credits.draw() end,
	settings = function() settings_menu.draw() end,
	settings_keybinds = function() settings_menu.keybinds.draw() end,
	settings_video = function() settings_menu.video.draw() end,
}

local screen_keypressed = {
	menu = function(key) main_menu.keypressed(key) end,
	credits = function(key) credits.keypressed(key) end,
	settings = function(key) settings_menu.keypressed(key) end,
	settings_keybinds = function(key, scancode) settings_menu.keybinds.keypressed(key, scancode) end,
	settings_video = function(key) settings_menu.video.keypressed(key) end,
	playing = function(key)
		if key == "escape" then Game.currentState = GameState.paused end
	end,
	paused = function(key) pause_menu.keypressed(key) end,
}

local screen_gamepadpressed = {
	menu = function(button) main_menu.gamepadpressed(button) end,
	credits = function(button) credits.gamepadpressed(button) end,
	settings = function(button) settings_menu.gamepadpressed(button) end,
	settings_keybinds = function(button) settings_menu.keybinds.gamepadpressed(button) end,
	settings_video = function(button) settings_menu.video.gamepadpressed(button) end,
	playing = function(button)
		if button == "start" then Game.currentState = GameState.paused end
	end,
	paused = function(button) pause_menu.gamepadpressed(button) end,
}

---@param dt number
function love.update(dt)
	if Game.currentState ~= GameState.playing then return end

	local p = Game.player

	p:update(dt)

	for _, obj in ipairs(Game.objects) do
		if obj.update then
			obj:update(dt) -- only for objects to update
		end
	end

	for index, obj in ipairs(Game.unlocks) do
		if physics.CheckCollosion(p, obj) then
			table.remove(Game.unlocks, index)
			UnlockedColor[obj.col] = true
			print("col " .. p.body.x .. " " .. p.body.y)
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
		print(dbg.pp(Game.unlocks[1]))
	end

	push.start()

	local state = Game.currentState
	local draw_fn = screen_draw[state]

	if draw_fn then
		draw_fn()
	else -- playing or paused: draw the game world
		local cx = -math.floor(Game.camera.x)
		local cy = -math.floor(Game.camera.y)

		-- Fix push working with sti
		local sx, sy, sw, sh = love.graphics.getScissor()
		love.graphics.setScissor()
		love.graphics.setColor(1, 1, 1, 1)
		for key, value in pairs(UnlockedColor) do
			if value then
				Gamemap:drawLayer(Gamemap.layers[key], cx, cy)
			end
		end
		love.graphics.setScissor(sx, sy, sw, sh)

		love.graphics.push()
		love.graphics.translate(cx, cy)

		local p = Game.player
		--love.graphics.draw(p.sprite, p.body.x, p.body.y)
		love.graphics.setColor(0.1, 0.1, 0.1)
		love.graphics.rectangle("fill", p.body.x, p.body.y, TILE_SIZE, TILE_SIZE)

		for _, obj in ipairs(Game.unlocks) do
			love.graphics.setColor(obj.color[1], obj.color[2], obj.color[3], obj.color[4])
			love.graphics.rectangle("fill", obj.x, obj.y, TILE_SIZE, TILE_SIZE)
			--love.graphics.draw(obj.sprite, obj.x, obj.y)
		end

		for _, obj in ipairs(Game.objects) do
			if (UnlockedColor[obj.col]) then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(obj.sprite, obj.x, obj.y)
			end
		end

		love.graphics.pop()

		-- Draw pause overlay on top of game
		if state == GameState.paused then
			pause_menu.draw()
		end
	end

	push.finish()
end

function love.keypressed(key, scancode)
	local handler = screen_keypressed[Game.currentState]
	if handler then handler(key, scancode) end
end

function love.gamepadpressed(joystick, button)
	local handler = screen_gamepadpressed[Game.currentState]
	if handler then handler(button) end
end

function love.resize()
	Gamemap:resize(GAME_WIDTH, GAME_HEIGHT)
	return push.resize()
end
