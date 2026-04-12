local physics = require("src.models.physics")

---@class Player: Object
---@field body Body
---@field interact boolean
---@field intDelay number
local Player = {}
Player.__index = Player

local WALK_FPS = 1 / 0.150 -- 150ms per frame
local IDLE_FPS = 1 / 0.300 -- 300ms per frame

-- Determines which sprite variant to use based on collected colors.
-- Matches the progression: 0=none, 1=yellow, 2=+blue, 3=+lightgreen,
-- 4=+pink, 5=+brown, 6a/6b=red or darkgreen, 7=both, 8=+darkblue
local eyedelay = 0
local function getSpriteVariant()
	local u = UnlockedColor.values
	local count = 0
	if eyedelay > 10 and not u.yellow then
		count = 1
	end
	-- Count in progression order
	local sequence = { "yellow", "blue", "lightgreen", "pink", "brown" }
	for _, col in ipairs(sequence) do
		if u[col] then count = count + 1 else break end
	end

	if count < 5 then return tostring(count) end

	local hasRed = u.red
	local hasGreen = u.darkgreen

	if hasRed and hasGreen then
		if u.darkblue then return "8" end
		return "7"
	elseif hasRed then
		return "6a"
	elseif hasGreen then
		return "6b"
	end

	return "5"
end

---@param x integer
---@param y integer
---@return Player
function Player.new(x, y)
	local self = setmetatable({}, Player)
	self.body = physics.Body.new(x, y)
	self.interact = false
	self.intDelay = 0.66

	self.frameIndex = 1
	self.frameTimer = 0
	self.facingLeft = false
	self.moving = false

	return self
end

function Player:update(dt)
	eyedelay = eyedelay + dt
	-- input handling --
	local kb = Game.settings.controls
	local gp = Game.settings.gamepad
	local joystick = love.joystick.getJoysticks()[1]

	local function isDown(kb_bind, gp_bind)
		if love.keyboard.isScancodeDown(kb_bind) then return true end
		if joystick and gp_bind ~= "" and joystick:isGamepadDown(gp_bind) then return true end
		return false
	end

	if isDown(kb.interact, gp.interact) and self.intDelay <= 0 then
		self.interact = true
		self.intDelay = 0.66
	else
		self.intDelay = self.intDelay - dt
		self.interact = false
	end

	local moving = false
	local dirx = 0
	local diry = 0

	if isDown(kb.move_down, gp.move_down) then
		diry = diry + 11
		moving = true
	end
	if isDown(kb.move_up, gp.move_up) then
		diry = diry - 11
		moving = true
	end
	if isDown(kb.move_right, gp.move_right) then
		dirx = dirx + 11
		moving = true
		self.facingLeft = false
	end
	if isDown(kb.move_left, gp.move_left) then
		dirx = dirx - 11
		moving = true
		self.facingLeft = true
	end

	self.body:addForce(dirx, diry)

	-- reset frame on state change
	if moving ~= self.moving then
		self.moving = moving
		self.frameIndex = 1
		self.frameTimer = 0
	end

	-- advance frame
	local fps = moving and WALK_FPS or IDLE_FPS
	self.frameTimer = self.frameTimer + dt
	if self.frameTimer >= 1 / fps then
		self.frameTimer = self.frameTimer - 1 / fps
		local frames = self:getFrames()
		self.frameIndex = self.frameIndex % #frames + 1
	end

	self.body:integrate(dt)

	-- TODO: should use the sprite w and h instead of the TILE_SIZE
	-- clamp
	self.body.x = math.max(0, math.min(WORLD_WIDTH - TILE_SIZE, self.body.x))
	self.body.y = math.max(0, math.min(WORLD_HEIGHT - TILE_SIZE, self.body.y))
	self.body:clearForce()
end

function Player:getFrames()
	local variant = getSpriteVariant()
	local anims = self.moving and Game.assets.images.blackcat_walk or Game.assets.images.blackcat_idle
	return anims[variant]
end

function Player:draw()
	local frames = self:getFrames()
	local idx = math.min(self.frameIndex, #frames)
	local f = frames[idx]
	if self.facingLeft then
		love.graphics.draw(f.image, f.quad, self.body.x, self.body.y)
	else
		love.graphics.draw(f.image, f.quad, self.body.x + TILE_SIZE, self.body.y, 0, -1, 1)
	end
end

return Player
