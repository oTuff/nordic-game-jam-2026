Particles = {
    ---@type Particle[]
    ParticleActive = {},
    ---@type Particle[]
    ParticlePool = {},

    ---@class Particle
    ---@field lifetime number
    ---@field speed number
    ---@field x number
    ---@field y number
    ---@field xv number
    ---@field yv number
    ---@field color number[]

    ---@class Effects
    ---@field count number[]
    ---@field lifetime number[]
    ---@field speed number[]
    ---@field size number[]
    ---@field color number[]
    ---@field spread number

    ---@type table Effects
    Effects = {
        explosion = {
            count = { 18, 24 },
            lifetime = { 0.4, 0.8 },
            speed = { 0.1, 0.33 },
            size = { 3, 10 },
            color = { 1, 0.4, 0.1, 0.8 },
            spread = 180 -- in degrees range from -180 to 180
        },
        muzzleFlash = {
            count = { 18, 42 },
            lifetime = { 0.012, 0.067 },
            speed = { 1.1, 2.3 },
            size = { 5, 10 },
            color = { 1, 1, 0.6 },
            spread = 20 -- in degrees
        }
    }
}
---@param _x number start x
---@param _y number start y
---@param _xv number x dir (0 for omnidir)
---@param _yv number y dir
---@param type Effects what effect to spawn
function Particles:spawnParticleEffect(_x, _y, _xv, _yv, type)
    for i = love.math.random(type.count[1], type.count[2]), 1, -1 do
        local theta = math.sin(math.rad(love.math.random(-type.spread, type.spread)))
        local phi = math.sin(math.rad(love.math.random(-type.spread, type.spread)))
        local xv = _xv + (love.math.random() * (type.speed[2] - type.speed[1]) + type.speed[1]) * theta
        local yv = _yv + (love.math.random() * (type.speed[2] - type.speed[1]) + type.speed[1]) * phi
        local offsetx = _x + (love.math.random() * (TILE_SIZE - (-TILE_SIZE)) + (-TILE_SIZE))
        local offsety = _y + (love.math.random() * (TILE_SIZE - (-TILE_SIZE)) + (-TILE_SIZE))
        self:spawnParticle(offsetx, offsety, xv, yv, type)
    end
end

--- dont use! its for internal usage. Instead use spawnParticleEffect
function Particles:spawnParticle(x, y, xv, yv, type)
    --@type Particle (it doesnt like line below: p = {})
    local p = table.remove(self.ParticlePool)
    if not p then
        p = {}
    end
    p.x, p.y, p.xv, p.yv = x, y, xv, yv
    p.lifetime = math.random() * (type.lifetime[2] - type.lifetime[1]) + type.lifetime[1]
    p.color = type.color
    p.speed = love.math.random() * (type.speed[2] - type.speed[1]) + type.speed[1]
    table.insert(self.ParticleActive, p)
end

function Particles:killParticle(i)
    local p = self.ParticleActive[i]
    self.ParticleActive[i] = self.ParticleActive[#self.ParticleActive]
    self.ParticleActive[#self.ParticleActive] = nil
    table.insert(self.ParticlePool, p)
end

function Particles:update(dt)
    for i = #self.ParticleActive, 1, -1 do
        local p = self.ParticleActive[i]
        p.lifetime = p.lifetime - dt
        p.x = p.x + p.xv * dt * 1000 * p.speed
        p.y = p.y + p.yv * dt * 1000 * p.speed
        if p.lifetime <= 0 then
            self:killParticle(i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.ParticleActive) do
        love.graphics.setColor(p.color);
        love.graphics.rectangle("fill", p.x, p.y, 5, 5);
    end
end

return Particles
