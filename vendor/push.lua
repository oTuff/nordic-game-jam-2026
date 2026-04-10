-- Copyright (c) 2018 Ulysse Ramage
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local pushWidth, pushHeight
local windowWidth, windowHeight

local scale = { x = 0, y = 0 }
local offset = { x = 0, y = 0 }

local drawWidth, drawHeight

local function initValues()
	local scaleX     = windowWidth / pushWidth
	local scaleY     = windowHeight / pushHeight

	local scaleVal   = math.min(scaleX, scaleY)

	scale.x, scale.y = scaleVal, scaleVal

	drawWidth        = pushWidth * scaleVal
	drawHeight       = pushHeight * scaleVal

	offset.x         = math.floor((windowWidth - drawWidth) / 2)
	offset.y         = math.floor((windowHeight - drawHeight) / 2)
end

local function start()
	love.graphics.translate(offset.x, offset.y)
	love.graphics.setScissor(offset.x, offset.y, pushWidth * scale.x, pushHeight * scale.y)
	love.graphics.push()
	love.graphics.scale(scale.x, scale.y)
end

local function finish()
	love.graphics.pop()
	love.graphics.setScissor()
end

return {
	setupScreen = function(width, height)
		pushWidth, pushHeight = width, height
		windowWidth, windowHeight = love.graphics.getDimensions()

		initValues()
	end,

	start = start,
	finish = finish,

	resize = function()
		windowWidth, windowHeight = love.graphics.getDimensions()
		initValues()
	end,

	-- All below functions currently not used
	toGame = function(x, y)
		x = x - offset.x
		y = y - offset.y

		if x < 0 or y < 0 or x > drawWidth or y > drawHeight then
			return false, false
		end

		local gameX = math.floor(x / scale.x)
		local gameY = math.floor(y / scale.y)

		return gameX, gameY
	end,
	toReal = function(x, y)
		local realX = offset.x + (drawWidth * x) / pushWidth
		local realY = offset.y + (drawHeight * y) / pushHeight

		return realX, realY
	end,
	getWidth = function() return pushWidth end,
	getHeight = function() return pushHeight end,
	getDimensions = function() return pushWidth, pushHeight end,
}
