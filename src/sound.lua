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
-- Ambient layers: each unlocked color adds a tone
-- These are gentle, looping sine/noise pads
------------------------------------------------------

local function makeAmbientTone(freq, vol, waveform, attack, sustain, decay, vibratoDepth, vibratoSpeed)
    local s = sfxr.newSound()
    s:resetParameters()
    s.waveform = waveform or sfxr.WAVEFORM.SINE
    s.envelope.attack = attack or 0.5
    s.envelope.sustain = sustain or 1.0
    s.envelope.decay = decay or 0.8
    s.frequency.start = freq or 0.2
    s.vibrato.depth = vibratoDepth or 0.02
    s.vibrato.speed = vibratoSpeed or 0.15
    s.lowpass.cutoff = 0.8
    s.volume.master = vol or 0.15
    s.volume.sound = 0.3
    s:sanitizeParameters()

    local data = s:generateSoundData()
    local source = love.audio.newSource(data, "static")
    source:setLooping(true)
    source:setVolume(vol or 0.15)
    return source
end

-- Each ambient layer: soft, different pitch/character, increasingly lush
local ambientDefs = {
    darkgreen  = { freq = 0.08, vol = 0.06, wave = sfxr.WAVEFORM.SINE,     atk = 0.8, sus = 1.0, dec = 0.9, vdep = 0.01, vspd = 0.08 },
    yellow     = { freq = 0.12, vol = 0.06, wave = sfxr.WAVEFORM.SINE,     atk = 0.7, sus = 1.0, dec = 0.8, vdep = 0.02, vspd = 0.10 },
    blue       = { freq = 0.15, vol = 0.05, wave = sfxr.WAVEFORM.SINE,     atk = 0.6, sus = 1.0, dec = 0.9, vdep = 0.03, vspd = 0.12 },
    lightgreen = { freq = 0.18, vol = 0.05, wave = sfxr.WAVEFORM.SINE,     atk = 0.7, sus = 1.0, dec = 0.8, vdep = 0.02, vspd = 0.15 },
    pink       = { freq = 0.22, vol = 0.05, wave = sfxr.WAVEFORM.SINE,     atk = 0.6, sus = 1.0, dec = 0.9, vdep = 0.04, vspd = 0.10 },
    brown      = { freq = 0.10, vol = 0.04, wave = sfxr.WAVEFORM.SAWTOOTH, atk = 0.8, sus = 1.0, dec = 0.9, vdep = 0.01, vspd = 0.06 },
    red        = { freq = 0.25, vol = 0.05, wave = sfxr.WAVEFORM.SINE,     atk = 0.5, sus = 1.0, dec = 0.8, vdep = 0.03, vspd = 0.18 },
    darkblue   = { freq = 0.30, vol = 0.05, wave = sfxr.WAVEFORM.SINE,     atk = 0.6, sus = 1.0, dec = 0.9, vdep = 0.05, vspd = 0.12 },
}

------------------------------------------------------
-- Public interface
------------------------------------------------------

function Sound.init()
    -- One-shot SFX
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

    -- Ambient layers (keyed by color name)
    Sound.ambient = {}
    for color, def in pairs(ambientDefs) do
        Sound.ambient[color] = makeAmbientTone(def.freq, def.vol, def.wave, def.atk, def.sus, def.dec, def.vdep, def.vspd)
    end

    -- Track which ambient layers are active
    Sound.activeAmbient = {}
end

--- Play a one-shot sound effect (restarts if already playing)
function Sound.play(name)
    if not Sound.sfx then return end
    local src = Sound.sfx[name]
    if src then
        src:stop()
        src:play()
    end
end

--- Start an ambient layer for the given color (if not already playing)
function Sound.startAmbient(color)
    if not Sound.ambient then return end
    if Sound.activeAmbient[color] then return end
    local src = Sound.ambient[color]
    if src then
        src:play()
        Sound.activeAmbient[color] = true
    end
end

--- Update ambient layers based on currently unlocked colors
function Sound.updateAmbient()
    for color, _ in pairs(ambientDefs) do
        if UnlockedColor.values[color] then
            Sound.startAmbient(color)
        end
    end
end

--- Stop all ambient layers (e.g. when returning to menu)
function Sound.stopAllAmbient()
    if not Sound.ambient then return end
    for color, src in pairs(Sound.ambient) do
        src:stop()
        Sound.activeAmbient[color] = false
    end
end

return Sound
