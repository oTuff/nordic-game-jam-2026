local physics = require("src.models.physics")

---@class Player: Object
---@field body Body
---@field notOnGround boolean
---@field jumpDelay number
local Player = {}
Player.__index = Player

---@param x integer
---@param y integer
---@param spriteOverwrite? love.Image
---@return Player
function Player.new(x, y, spriteOverwrite)
	local self = setmetatable({}, Player)
	self.body = physics.Body.new(x, y)
	self.notOnGround = false
	self.jumpDelay = 1
	self.sprite = spriteOverwrite or Game.assets.images.playerImg
	return self
end

function Player:update(dt)
	self.body:clearForce()

	--gravity
	if (self.body.y <= WORLD_HEIGHT - TILE_SIZE) then
		self.body:addForce(0, 9.8)
	end

	if (self.body.y >= WORLD_HEIGHT - TILE_SIZE or self.body.y <= 0) then
		self.body.vely = 0
		self.notOnGround = false
	else
		self.notOnGround = true
	end

	if (self.notOnGround) then
		self.jumpDelay = self.jumpDelay - dt
	else
		self.jumpDelay = 0.15
	end

	-- input handling --
	local kb = Game.settings.controls
	local gp = Game.settings.gamepad
	local joystick = love.joystick.getJoysticks()[1]

	local function isDown(kb_bind, gp_bind)
		if love.keyboard.isScancodeDown(kb_bind) then return true end
		if joystick and gp_bind ~= "" and joystick:isGamepadDown(gp_bind) then return true end
		return false
	end

	if isDown(kb.jump, gp.jump) then
		if self.jumpDelay >= 0 then
			self.body:addForce(0, -50)
		end
	end
	if isDown(kb.move_down, gp.move_down) then
		self.body:addForce(0, 3)
	end
	if isDown(kb.move_right, gp.move_right) then
		self.body:addForce(3, 0)
	end
	if isDown(kb.move_left, gp.move_left) then
		self.body:addForce(-3, 0)
	end

	self.body:integrate(dt)

	-- TODO: should use the sprite w and h instead of the TILE_SIZE
	-- clamp
	self.body.x = math.max(0, math.min(WORLD_WIDTH - TILE_SIZE, self.body.x))
	self.body.y = math.max(0, math.min(WORLD_HEIGHT - TILE_SIZE, self.body.y))
end

return Player
