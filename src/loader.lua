local function loadSheet(path, frameW, frameH)
	local img = love.graphics.newImage(path)
	local imgW, imgH = img:getDimensions()
	local frames = {}
	for c = 0, math.floor(imgW / frameW) - 1 do
		frames[#frames + 1] = { image = img, quad = love.graphics.newQuad(c * frameW, 0, frameW, frameH, imgW, imgH) }
	end
	return frames
end

local function loadVariants(prefix, frameW, frameH)
	local variants = {}
	for _, suffix in ipairs({ "0", "1", "2", "3", "4", "5", "6a", "6b", "7", "8" }) do
		variants[suffix] = loadSheet("assets/images/" .. prefix .. suffix .. ".png", frameW, frameH)
	end
	return variants
end

return {
	load = function()
		return {
			images = {
				test = love.graphics.newImage("assets/images/dogo.png"),
				playerImg = love.graphics.newImage("assets/images/frogo.png"),
				handle = loadSheet("assets/images/handle-Sheet.png", 32, 32),
				tree = love.graphics.newImage("assets/images/tree2.png"),
				leaves1 = love.graphics.newImage("assets/images/leaves.png"),
				blackcat_idle = loadVariants("blackcat_idle_", 32, 32),
				blackcat_walk = loadVariants("blackcat_walk_", 32, 32),
				lever = loadSheet("assets/images/lever.png", 32, 32),
				faucet = love.graphics.newImage("assets/images/faucet.png"),
				vines = love.graphics.newImage("assets/images/vines.png"),
				water = love.graphics.newImage("assets/images/water.png"),
			},
			fonts = {
			},
			audio = {
			},
		}
	end,
}
