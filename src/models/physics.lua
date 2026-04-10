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
    if self.vely >= self.maxSpeed then
        self.vely = self.maxSpeed
    end
    if self.vely <= -self.maxSpeed then
        self.vely = -self.maxSpeed
    end

    if math.abs(self.ax) == 0 then -- add friction when not accelerating
        self.velx = self.velx - self.velx * frictionCoeff * dt
        if math.abs(self.velx) <= math.abs(0.3) then
            self.velx = 0
        end
    end
    if math.abs(self.ay) == 0 then -- same for y-axis
        self.vely = self.vely - self.vely * frictionCoeff * dt
        if math.abs(self.vely) <= math.abs(0.3) then
            self.vely = 0
        end
    end
end

--- check collison on player vs objects (box)
---@return boolean
---@param a Player
---@param b Object
physics.CheckCollosion = function(a, b)
    local ax = a.body.x
    local ay = a.body.y
    local ax2 = a.body.x + TILE_SIZE
    local ay2 = a.body.y + TILE_SIZE

    local bx = b.x
    local by = b.y
    local bx2 = b.x + TILE_SIZE
    local by2 = b.y + TILE_SIZE

    return not (ax2 <= bx or ax >= bx2 or ay2 <= by or ay >= by2)
end

--- stops player movemennt on object (as if objects are solid)
---@param a Player
---@param b table
physics.HandleCollision = function(a, b)
    local overlapX = math.min(a.body.x + TILE_SIZE - b.x, b.x + TILE_SIZE - a.body.x)
    local overlapY = math.min(a.body.y + TILE_SIZE - b.y, b.y + TILE_SIZE - a.body.y)

    if overlapX < overlapY then
        if a.body.x < b.x then
            a.body.x = a.body.x - overlapX
        else
            a.body.x = a.body.x + overlapX
        end
        a.body.velx = 0
    else
        if a.body.y < b.y then
            a.body.y = a.body.y - overlapY
        else
            a.body.y = a.body.y + overlapY
        end
        a.body.vely = 0
    end
end

physics.Body = Body
return physics
