local physics = {}

---@class Body
---@field velx number
---@field vely number
---@field ax number
---@field ay number
---@field maxSpeed number
local Body = {}
Body.__index = Body

function Body.new(x, y)
    local self = setmetatable({}, Body)
    self.x = x
    self.y = y
    self.ax = 0
    self.ay = 0
    self.velx = 0
    self.vely = 0
    self.maxSpeed = 2.716
    return self
end

function Body:addForce(dirx, diry)
    self.ax = self.ax + dirx
    self.ay = self.ay + diry
end

function Body:clearForce()
    self.ax = 0
    self.ay = 0
end

function Body:integrate(dt)
    local pixelPerSecScale = 100
    local frictionCoeff = 2.298
    local frictionCoeffY = 0.914

    self.velx = self.velx + self.ax * dt
    self.vely = self.vely + self.ay * dt

    self.x = self.x + self.velx * dt * pixelPerSecScale
    self.y = self.y + self.vely * dt * pixelPerSecScale

    if self.velx >= self.maxSpeed then
        self.velx = self.maxSpeed
    end
    if self.velx <= -self.maxSpeed then
        self.velx = -self.maxSpeed
    end

    if math.abs(self.ax) == 0 then -- add friction when not accelerating
        self.velx = self.velx - self.velx * frictionCoeff * dt
        if math.abs(self.velx) <= math.abs(0.3) then
            self.velx = 0
        end
    end
    if math.abs(self.ay) == 0 then -- same for y-axis
        self.vely = self.vely - self.vely * frictionCoeffY * dt
    end
end

---@param a Player
---@param b Object
physics.CheckCollosion = function(a, b)
    local ax = a.body.x
    local ay = a.body.y
    local ax2 = a.body.x + 32
    local ay2 = a.body.y + 32

    local bx = b.x
    local by = b.y
    local bx2 = b.x + 32
    local by2 = b.y + 32

    return not (ax2 <= bx or ax >= bx2 or ay2 <= by or ay >= by2)
end

physics.Body = Body
return physics
