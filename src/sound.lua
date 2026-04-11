local Sound = {}

local SFX_PATH = "assets/sounds/"

local sfxNames = {
    "colorPickup",
    "leverPull",
    "puzzleWrong",
    "puzzleSolved",
    "portal",
    "leverCorrect",
    "menuBlip",
    "menuSelect",
    "whiteShimmer",
}

local ambientDefs = {
    darkgreen  = { vol = 0.35 },
    yellow     = { vol = 0.30 },
    blue       = { vol = 0.28 },
    lightgreen = { vol = 0.25 },
    pink       = { vol = 0.25 },
    brown      = { vol = 0.30 },
    red        = { vol = 0.22 },
    darkblue   = { vol = 0.20 },
}

------------------------------------------------------
-- Volume helpers
------------------------------------------------------

local function getVolume(category)
    if not Game or not Game.settings or not Game.settings.sound then
        return 1.0
    end
    local s = Game.settings.sound
    return (s.master / 100) * (s[category] / 100)
end

function Sound.applyVolumes()
    if Sound.sfx then
        local sfxVol = getVolume("sfx")
        for _, src in pairs(Sound.sfx) do
            src:setVolume(sfxVol)
        end
    end
    if Sound.ambient then
        local ambVol = getVolume("ambient")
        for _, drone in pairs(Sound.ambient) do
            drone.source:setVolume(drone.targetVol * ambVol)
        end
    end
end

------------------------------------------------------
-- Public interface
------------------------------------------------------

function Sound.init()
    Sound.sfx = {}
    for _, name in ipairs(sfxNames) do
        Sound.sfx[name] = love.audio.newSource(SFX_PATH .. name .. ".wav", "static")
    end

    Sound.ambient = {}
    for color, def in pairs(ambientDefs) do
        local source = love.audio.newSource(SFX_PATH .. "drone_" .. color .. ".wav", "static")
        source:setLooping(true)
        source:setVolume(def.vol)
        Sound.ambient[color] = {
            source = source,
            targetVol = def.vol,
            active = false,
        }
    end
end

function Sound.play(name)
    if not Sound.sfx then return end
    local src = Sound.sfx[name]
    if src then
        src:stop()
        src:setVolume(getVolume("sfx"))
        src:play()
    end
end

function Sound.startAmbient(color)
    if not Sound.ambient then return end
    local drone = Sound.ambient[color]
    if not drone or drone.active then return end
    drone.active = true
    drone.source:setVolume(drone.targetVol * getVolume("ambient"))
    drone.source:play()
end

function Sound.updateAmbient()
    for color, _ in pairs(ambientDefs) do
        if UnlockedColor.values[color] then
            Sound.startAmbient(color)
        end
    end
end

function Sound.update(dt)
end

function Sound.stopAllAmbient()
    if not Sound.ambient then return end
    for color, drone in pairs(Sound.ambient) do
        if drone.active then
            drone.source:stop()
            drone.active = false
        end
    end
end

return Sound
