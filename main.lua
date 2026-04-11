local push = require("vendor.push")
local lip = require("vendor.lip")
local loader = require("src.loader")
local player = require("src.models.player")
local enemy = require("src.models.enemy")
local physics = require("src.models.physics")
local sti = require("vendor.sti")
local particles = require("src.models.particles")
local sound = require("src.sound")
local walls = require("assets.tield.map")

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
	love.graphics.setBackgroundColor(0.05, 0.05, 0.05)
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.graphics.setNewFont(36)

	Gamemap = sti("assets/tield/map.lua")
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
			interact = "e",
			move_left = "a",
			move_right = "d",
			jump = "w",
			move_down = "s",
		},
		gamepad = {
			interact = "a",
			move_left = "dpleft",
			move_right = "dpright",
			jump = "dpup",
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
		order = { "darkgreen", "yellow", "blue", "lightgreen", "pink", "brown", "red", "darkblue" },
		values = {
			yellow = false,
			blue = false,
			lightgreen = false,
			pink = false,
			brown = false,
			red = false,
			darkgreen = false,
			darkblue = false,
			white = false
		}
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

	-- Initialize sound system
	sound.init()

	Game.camera = { x = 0, y = 0 }

	-- White ending transition state
	WhiteTransition = {
		active = false,
		timer = 0,
		zoomDuration = 6, -- seconds to zoom out
		fadeDuration = 8, -- seconds total before fully white
		fadeDelay = 4, -- seconds before fade starts
		startCamX = 0,
		startCamY = 0,
	}
	Game.player = player.new(100, 100)
	--- @type Unlocks[]
	Game.unlocks = {
		{ col = "red",        x = TILE_SIZE * 10, y = TILE_SIZE * 44, color = { 1, 0, 0, 1 } }, -- red
		{ col = "blue",       x = TILE_SIZE * 43, y = TILE_SIZE * 20, color = { 0, 0, 1, 1 } }, -- blue
		{ col = "lightgreen", x = TILE_SIZE * 69, y = TILE_SIZE * 5,  color = { 0, 1, 0, 1 } }, -- green
		{ col = "yellow",     x = TILE_SIZE * 11, y = TILE_SIZE * 20, color = { 1, 1, 0, 1 } },
		{ col = "pink",       x = TILE_SIZE * 67, y = TILE_SIZE * 32, color = { 1, 0.75, 0.80, 1 } },
		{ col = "brown",      x = TILE_SIZE * 42, y = TILE_SIZE * 42, color = { 0.60, 0.30, 0.10, 1 } },
		{ col = "darkgreen",  x = TILE_SIZE * 8,  y = TILE_SIZE * 72, color = { 0, 0.39, 0, 1 } },
		{ col = "darkblue",   x = TILE_SIZE * 62, y = TILE_SIZE * 63, color = { 0, 0, 0.55, 1 } },
		{ col = "white",      x = TILE_SIZE * 35, y = TILE_SIZE * 65, color = { 1, 1, 1, 1 } },
	}
	--- @type Entity[]
	Game.objects = {
		--stuff
	}
	for _, value in pairs(walls.layers[3].objects) do
		table.insert(Game.objects, {
			col = "yellow",
			x = value.x - TILE_SIZE * 2 - 8,
			y = value.y - TILE_SIZE * 6,
			sprite = Game.assets.images.tree
		})
		table.insert(Game.objects, {
			col = "lightgreen",
			x = value.x - TILE_SIZE * 2 - 8,
			y = value.y - TILE_SIZE * 6,
			sprite = Game.assets.images.leaves1
		})
	end

	YellowPuzzle = {
		-- yellow puzzle
		---@type Object[]
		yellowBlocked = {
			{ x = TILE_SIZE * 40, y = TILE_SIZE * 16, col = "" },
			{ x = TILE_SIZE * 41, y = TILE_SIZE * 16, col = "" }
		},
		---@type boolean
		solved = false,
		lever = {
			x = TILE_SIZE * 42,
			y = TILE_SIZE * 14,
			col = "yellow",
			frames = Game.assets.images.lever,
			frameIndex = 1,
			pulled = false,
		}
	}
	function YellowPuzzle.lever:update(p)
		if self.pulled then return end
		if p.interact and physics.CheckCollosion(p, self) then
			self.pulled = true
			self.frameIndex = #self.frames
			YellowPuzzle.solved = true
			sound.play("leverPull")
			sound.play("puzzleSolved")
			-- Particle effect at the opened path
			for _, block in ipairs(YellowPuzzle.yellowBlocked) do
				particles:spawnParticleEffect(block.x + 16, block.y + 16, 0, 0, {
					count = { 12, 18 },
					lifetime = { 0.5, 1.0 },
					speed = { 0.1, 0.3 },
					size = { 4, 10 },
					spread = 180,
					color = { 1, 1, 0, 0.9 },
				})
			end
		end
	end

	function YellowPuzzle.lever:draw()
		love.graphics.setColor(1, 1, 0, 1)
		local f = self.frames[self.pulled and #self.frames or 1]
		love.graphics.draw(f.image, f.quad, self.x, self.y)
		love.graphics.setColor(1, 1, 1, 1)
	end

	-- Darkblue portals
	Portals = {
		top    = { x = TILE_SIZE * 15, y = TILE_SIZE * 2, w = TILE_SIZE * 5, h = TILE_SIZE * 6 },
		bottom = { x = TILE_SIZE * 44, y = TILE_SIZE * 74, w = TILE_SIZE * 5, h = TILE_SIZE * 6 },
	}

	------------------------------------------------------
	-- Color-gated collision walls (shared infrastructure)
	------------------------------------------------------
	Game.colorWalls = {}

	local T = TILE_SIZE

	------------------------------------------------------
	-- Puzzle 3: Color Memory Sequence (gates red)
	------------------------------------------------------
	local la = { x = 6, y = 40 }
	LeverPuzzle = {
		solved = false,
		correctOrder = { "blue", "pink", "yellow", "brown", "lightgreen" },
		progress = 0,
		levers = {},
		blockedWall = { x = T * 10, y = T * 43, width = T, height = T * 2 },
	}
	local leverColors = { "yellow", "blue", "lightgreen", "pink", "brown" }
	local leverRGB = {
		yellow = { 1, 1, 0 },
		blue = { 0.3, 0.5, 1 },
		lightgreen = { 0, 1, 0 },
		pink = { 1, 0.75, 0.80 },
		brown = { 0.60, 0.30, 0.10 },
	}
	for i, col in ipairs(leverColors) do
		table.insert(LeverPuzzle.levers, {
			x = T * (la.x + (i - 1) * 2),
			y = T * la.y,
			col = col,
			pulled = false,
			color = leverRGB[col],
		})
	end

	function LeverPuzzle:update(p)
		if self.solved or not UnlockedColor.values.brown then return end
		for _, lever in ipairs(self.levers) do
			if p.interact and not lever.pulled and physics.CheckCollosion(p, lever) then
				if lever.col == self.correctOrder[self.progress + 1] then
					lever.pulled = true
					self.progress = self.progress + 1
					sound.play("leverPull")
					if self.progress >= #self.correctOrder then
						self.solved = true
						sound.play("puzzleSolved")
					else
						sound.play("leverCorrect")
					end
				else
					self.progress = 0
					for _, l in ipairs(self.levers) do l.pulled = false end
					sound.play("leverPull")
					sound.play("puzzleWrong")
					particles:spawnParticleEffect(p.body.x + 16, p.body.y + 16, 0, 0, {
						count = { 10, 15 },
						lifetime = { 0.3, 0.6 },
						speed = { 0.1, 0.3 },
						size = { 3, 8 },
						spread = 180,
						color = { 1, 0.2, 0.2, 0.8 },
					})
				end
			end
		end
		if not self.solved then
			if physics.CheckCollosionWall(p, self.blockedWall) then
				physics.HandleCollisionWall(p, self.blockedWall)
			end
		end
	end

	function LeverPuzzle:draw()
		if not UnlockedColor.values.brown then return end
		local frames = Game.assets.images.lever
		for _, lever in ipairs(self.levers) do
			love.graphics.setColor(lever.color[1], lever.color[2], lever.color[3], 1)
			local f = frames[lever.pulled and #frames or 1]
			love.graphics.draw(f.image, f.quad, lever.x, lever.y)
		end
		if not self.solved then
			love.graphics.setColor(0.5, 0.1, 0.1, 0.6)
			love.graphics.rectangle("fill", self.blockedWall.x, self.blockedWall.y, self.blockedWall.width,
				self.blockedWall.height)
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
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
	-- Ambient fades must run regardless of game state
	sound.update(dt)

	if Game.currentState ~= GameState.playing then return end

	local p = Game.player
	p:update(dt)

	for _, obj in ipairs(Game.objects) do
		if obj.update then
			obj:update(p) -- only for objects to update
		end
	end

	-- tree collision
	for _, tree in pairs(walls.layers[3].objects) do
		if physics.CheckCollosionWall(p, tree) then
			physics.HandleCollision(p, tree)
		end
	end

	for _, wall in pairs(walls.layers[2].objects) do
		if physics.CheckCollosionWall(p, wall) then
			physics.HandleCollisionWall(p, wall)
		end
	end

	-- yellow "puzzle"
	if not YellowPuzzle.solved then
		YellowPuzzle.lever:update(p)
		for _, obj in pairs(YellowPuzzle.yellowBlocked) do
			if physics.CheckCollosion(p, obj) then
				physics.HandleCollision(p, obj)
			end
		end
	end

	-- Color-gated collision walls
	for _, wall in ipairs(Game.colorWalls) do
		if not wall.col or wall.col == "" or UnlockedColor.values[wall.col] then
			if physics.CheckCollosionWall(p, wall) then
				physics.HandleCollisionWall(p, wall)
			end
		end
	end

	-- Puzzle updates
	LeverPuzzle:update(p)
	-- Darkblue portal (one-way: top -> bottom)
	if UnlockedColor.values.darkblue then
		local top = Portals.top
		local bot = Portals.bottom
		if physics.CheckCollosionWall(p, { x = top.x, y = top.y, width = top.w, height = top.h }) then
			p.body.x = bot.x + bot.w / 2 - TILE_SIZE / 2
			p.body.y = bot.y + bot.h / 2 - TILE_SIZE / 2
			sound.play("portal")
		end
	end

	for index, obj in ipairs(Game.unlocks) do
		if physics.CheckCollosion(p, obj) then
			local type = particles.Effects.explosion
			type.color = obj.color -- TODO maybe randomize color a bit
			particles:spawnParticleEffect(obj.x + 16, obj.y + 16, 0, 0, type)
			table.remove(Game.unlocks, index)
			UnlockedColor.values[obj.col] = true
			if obj.col == "white" and not WhiteTransition.active then
				WhiteTransition.active = true
				WhiteTransition.timer = 0
				WhiteTransition.startCamX = Game.camera.x
				WhiteTransition.startCamY = Game.camera.y
				sound.play("whiteShimmer")
			else
				sound.play("colorPickup")
			end
			sound.updateAmbient()
		end
	end

	particles:update(dt)

	-- White transition update
	if WhiteTransition.active then
		WhiteTransition.timer = WhiteTransition.timer + dt
	end

	-- Camera
	local cam = Game.camera
	if not WhiteTransition.active then
		local targetX = p.body.x - GAME_WIDTH / 2
		local targetY = p.body.y - GAME_HEIGHT / 2
		local smoothing = 1 - math.exp(-5 * dt)
		cam.x = cam.x + (targetX - cam.x) * smoothing
		cam.y = cam.y + (targetY - cam.y) * smoothing
		cam.x = math.max(0, math.min(WORLD_WIDTH - GAME_WIDTH, cam.x))
		cam.y = math.max(0, math.min(WORLD_HEIGHT - GAME_HEIGHT, cam.y))
	end
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

		love.graphics.push()

		if WhiteTransition.active then
			local t = math.min(WhiteTransition.timer / WhiteTransition.zoomDuration, 1)
			t = 1 - (1 - t) * (1 - t) -- ease out

			local targetScale = math.min(GAME_WIDTH / WORLD_WIDTH, GAME_HEIGHT / WORLD_HEIGHT)
			local scale = 1 + (targetScale - 1) * t

			-- Start: player-centered camera offset
			local startTX = -WhiteTransition.startCamX
			local startTY = -WhiteTransition.startCamY
			-- End: map centered on screen (translate then scale)
			local endTX = (GAME_WIDTH / targetScale - WORLD_WIDTH) / 2
			local endTY = (GAME_HEIGHT / targetScale - WORLD_HEIGHT) / 2
			-- Lerp the pre-scale translation
			local tx = startTX + (endTX - startTX) * t
			local ty = startTY + (endTY - startTY) * t

			love.graphics.scale(scale, scale)
			love.graphics.translate(tx, ty)
		else
			love.graphics.translate(cx, cy)
		end

		love.graphics.setColor(1, 1, 1, 1)

		--Gamemap:drawLayer(Gamemap.layers["main"])

		if UnlockedColor.values["yellow"] then
			YellowPuzzle.lever:draw()
		end

		for _, color in pairs(UnlockedColor.order) do
			if UnlockedColor.values[color] then
				Gamemap:drawLayer(Gamemap.layers[color])
			end
		end

		-- Draw color-gated walls
		local wallColors = {
			lightgreen = { 0, 0.8, 0 },
			pink = { 1, 0.75, 0.80 },
		}
		for _, wall in ipairs(Game.colorWalls) do
			if wall.col and UnlockedColor.values[wall.col] then
				local c = wallColors[wall.col] or { 0.5, 0.5, 0.5 }
				love.graphics.setColor(c[1], c[2], c[3], 0.8)
				love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
			end
		end
		love.graphics.setColor(1, 1, 1, 1)

		-- Draw puzzles
		LeverPuzzle:draw()

		local p = Game.player
		p:draw()

		for _, obj in ipairs(Game.unlocks) do
			love.graphics.setColor(obj.color[1], obj.color[2], obj.color[3], obj.color[4])
			love.graphics.rectangle("fill", obj.x, obj.y, TILE_SIZE, TILE_SIZE)
		end

		for _, obj in ipairs(Game.objects) do
			if (UnlockedColor.values[obj.col]) then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(obj.sprite, obj.x, obj.y)
			end
		end

		particles:draw()

		love.graphics.pop()

		-- Draw pause overlay on top of game
		if state == GameState.paused then
			pause_menu.draw()
		end
	end

	if WhiteTransition.active then
		local fadeT = (WhiteTransition.timer - WhiteTransition.fadeDelay) /
		    (WhiteTransition.fadeDuration - WhiteTransition.fadeDelay)
		fadeT = math.max(0, math.min(fadeT, 1))
		if fadeT > 0 then
			love.graphics.setColor(1, 1, 1, fadeT)
			love.graphics.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
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
