local sfxr = require("vendor.sfxr")

local Sound = {}

------------------------------------------------------
-- Helper: create a LÖVE Source from an sfxr Sound
------------------------------------------------------
local function makeSource(snd, volume)
    local data = snd:generateSoundData()
    local source = love.audio.newSource(data, "static")
    if volume then source:setVolume(volume) end
    return source
end

------------------------------------------------------
-- Interaction SFX (one-shot sounds)
------------------------------------------------------

-- Color pickup: bright, sparkly powerup
local function makeColorPickup()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SINE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.15
    s.envelope.decay = 0.35
    s.envelope.punch = 0.4
    s.frequency.start = 0.35
    s.frequency.slide = 0.15
    s.vibrato.depth = 0.05
    s.vibrato.speed = 0.4
    s.volume.master = 0.4
    s.volume.sound = 0.5
    s:sanitizeParameters()
    return makeSource(s, 0.5)
end

-- Lever pull: mechanical click
local function makeLeverPull()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SQUARE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.05
    s.envelope.decay = 0.15
    s.envelope.punch = 0.6
    s.frequency.start = 0.25
    s.frequency.slide = -0.25
    s.duty.ratio = 0.5
    s.volume.master = 0.35
    s.volume.sound = 0.5
    s:sanitizeParameters()
    return makeSource(s, 0.4)
end

-- Puzzle wrong: low buzzer
local function makePuzzleWrong()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SAWTOOTH
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.1
    s.envelope.decay = 0.3
    s.frequency.start = 0.15
    s.frequency.slide = -0.1
    s.volume.master = 0.3
    s.volume.sound = 0.4
    s:sanitizeParameters()
    return makeSource(s, 0.35)
end

-- Puzzle solved: ascending chime
local function makePuzzleSolved()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SINE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.2
    s.envelope.decay = 0.5
    s.envelope.punch = 0.3
    s.frequency.start = 0.3
    s.frequency.slide = 0.2
    s.vibrato.depth = 0.03
    s.vibrato.speed = 0.3
    s.volume.master = 0.4
    s.volume.sound = 0.5
    s:sanitizeParameters()
    return makeSource(s, 0.45)
end

-- Portal whoosh
local function makePortal()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.NOISE
    s.envelope.attack = 0.05
    s.envelope.sustain = 0.15
    s.envelope.decay = 0.4
    s.frequency.start = 0.5
    s.frequency.slide = -0.3
    s.lowpass.cutoff = 0.6
    s.lowpass.sweep = -0.2
    s.phaser.offset = 0.3
    s.phaser.sweep = -0.1
    s.volume.master = 0.3
    s.volume.sound = 0.4
    s:sanitizeParameters()
    return makeSource(s, 0.35)
end

-- Lever correct step in sequence
local function makeLeverCorrect()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SINE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.08
    s.envelope.decay = 0.2
    s.envelope.punch = 0.2
    s.frequency.start = 0.28
    s.frequency.slide = 0.08
    s.volume.master = 0.35
    s.volume.sound = 0.45
    s:sanitizeParameters()
    return makeSource(s, 0.4)
end

-- Menu navigate blip
local function makeMenuBlip()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SQUARE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.03
    s.envelope.decay = 0.08
    s.frequency.start = 0.4
    s.duty.ratio = 0.3
    s.volume.master = 0.2
    s.volume.sound = 0.3
    s:sanitizeParameters()
    return makeSource(s, 0.25)
end

-- Menu select
local function makeMenuSelect()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SQUARE
    s.envelope.attack = 0.0
    s.envelope.sustain = 0.05
    s.envelope.decay = 0.12
    s.envelope.punch = 0.3
    s.frequency.start = 0.35
    s.frequency.slide = 0.1
    s.duty.ratio = 0.4
    s.volume.master = 0.25
    s.volume.sound = 0.35
    s:sanitizeParameters()
    return makeSource(s, 0.3)
end

-- White ending shimmer
local function makeWhiteShimmer()
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = sfxr.WAVEFORM.SINE
    s.envelope.attack = 0.3
    s.envelope.sustain = 0.5
    s.envelope.decay = 1.0
    s.frequency.start = 0.45
    s.frequency.slide = 0.05
    s.vibrato.depth = 0.08
    s.vibrato.speed = 0.2
    s.phaser.offset = 0.15
    s.phaser.sweep = 0.05
    s.volume.master = 0.35
    s.volume.sound = 0.4
    s:sanitizeParameters()
    return makeSource(s, 0.4)
end

------------------------------------------------------
-- Ambient drones: procedurally generated looping
-- buffers using raw SoundData and sine waves.
------------------------------------------------------

local SAMPLE_RATE = 44100
local DRONE_SECONDS = 4

local function makeDrone(def)
    local numSamples = SAMPLE_RATE * DRONE_SECONDS
    -- Use LÖVE's default format (same way sfxr does it internally)
    local data = love.sound.newSoundData(numSamples, SAMPLE_RATE, 16, 1)
    local pi2 = math.pi * 2

    for i = 0, numSamples - 1 do
        local t = i / SAMPLE_RATE
        local sample = 0

        -- Base tone
        sample = sample + math.sin(pi2 * def.hz * t) * 0.4
        -- Detuned second voice for warmth
        sample = sample + math.sin(pi2 * def.hz * 1.002 * t) * 0.25
        -- Soft octave below
        sample = sample + math.sin(pi2 * def.hz * 0.5 * t) * 0.15
        -- Fifth above
        if def.fifth then
            sample = sample + math.sin(pi2 * def.hz * 1.498 * t) * 0.08
        end

        -- Slow breathing amplitude modulation
        local breathRate = def.breathRate or 0.15
        local breathDepth = def.breathDepth or 0.3
        local breath = 1.0 - breathDepth * (0.5 + 0.5 * math.sin(pi2 * breathRate * t))
        sample = sample * breath

        -- Crossfade loop edges
        local fadeLen = 0.05 * SAMPLE_RATE
        if i < fadeLen then
            sample = sample * (i / fadeLen)
        elseif i > numSamples - fadeLen then
            sample = sample * ((numSamples - i) / fadeLen)
        end

        data:setSample(i, math.max(-1, math.min(1, sample)))
    end

    local source = love.audio.newSource(data, "static")
    source:setLooping(true)
    source:setVolume(def.vol)
    return source
end

local ambientDefs = {
    darkgreen  = { hz = 174.6, vol = 0.35, breathRate = 0.12, breathDepth = 0.35, fifth = false },  -- F3
    yellow     = { hz = 196.0, vol = 0.30, breathRate = 0.15, breathDepth = 0.30, fifth = false },  -- G3
    blue       = { hz = 220.0, vol = 0.28, breathRate = 0.10, breathDepth = 0.25, fifth = true },   -- A3
    lightgreen = { hz = 261.6, vol = 0.25, breathRate = 0.18, breathDepth = 0.30, fifth = false },  -- C4
    pink       = { hz = 293.7, vol = 0.25, breathRate = 0.14, breathDepth = 0.25, fifth = true },   -- D4
    brown      = { hz = 164.8, vol = 0.30, breathRate = 0.08, breathDepth = 0.40, fifth = false },  -- E3
    red        = { hz = 329.6, vol = 0.22, breathRate = 0.20, breathDepth = 0.20, fifth = true },   -- E4
    darkblue   = { hz = 392.0, vol = 0.20, breathRate = 0.16, breathDepth = 0.25, fifth = true },   -- G4
}

------------------------------------------------------
-- Public interface
------------------------------------------------------

function Sound.init()
    Sound.sfx = {
        colorPickup   = makeColorPickup(),
        leverPull     = makeLeverPull(),
        puzzleWrong   = makePuzzleWrong(),
        puzzleSolved  = makePuzzleSolved(),
        portal        = makePortal(),
        leverCorrect  = makeLeverCorrect(),
        menuBlip      = makeMenuBlip(),
        menuSelect    = makeMenuSelect(),
        whiteShimmer  = makeWhiteShimmer(),
    }

    Sound.ambient = {}
    for color, def in pairs(ambientDefs) do
        Sound.ambient[color] = {
            source = makeDrone(def),
            targetVol = def.vol,
            active = false,
        }
    end

end

--- Play a one-shot sound effect
function Sound.play(name)
    if not Sound.sfx then return end
    local src = Sound.sfx[name]
    if src then
        src:stop()
        src:play()
    end
end

--- Start a drone for the given color
function Sound.startAmbient(color)
    if not Sound.ambient then return end
    local drone = Sound.ambient[color]
    if not drone or drone.active then return end
    drone.active = true
    drone.source:setVolume(drone.targetVol)
    drone.source:play()
end

--- Activate drones for all unlocked colors
function Sound.updateAmbient()
    for color, _ in pairs(ambientDefs) do
        if UnlockedColor.values[color] then
            Sound.startAmbient(color)
        end
    end
end

--- No-op for now (fade logic removed to debug)
function Sound.update(dt)
end

--- Stop all ambient drones
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
