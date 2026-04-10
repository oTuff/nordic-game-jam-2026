---@class Enemy: Object
---@field speed number
---@field direction number
local Enemy = {}
Enemy.__index = Enemy

---@param x integer
---@param y integer
---@param spriteOverwrite? love.Image
---@return Enemy
function Enemy.new(x, y, spriteOverwrite)
	local self = setmetatable({}, Enemy)
	self.x = x or 400
	self.y = y or 100
	self.speed = 100
	self.direction = 1
	self.sprite = spriteOverwrite or Game.assets.images.test
	return self
end

function Enemy:update(dt)
	self.x = self.x + self.speed * self.direction * dt
	if self.x < 50 then
		self.direction = 1
	elseif self.x > 750 then
		self.direction = -1
	end
end

return Enemy
