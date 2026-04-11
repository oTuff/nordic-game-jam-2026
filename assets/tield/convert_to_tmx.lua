-- Convert map.lua to map.tmx for Tiled
local map = dofile("map.lua")

local out = {}
local function w(s) out[#out + 1] = s end

w('<?xml version="1.0" encoding="UTF-8"?>')
w(string.format(
    '<map version="%s" tiledversion="%s" orientation="%s" renderorder="%s" width="%d" height="%d" tilewidth="%d" tileheight="%d" infinite="0" nextlayerid="%d" nextobjectid="%d">',
    map.version, map.tiledversion, map.orientation, map.renderorder,
    map.width, map.height, map.tilewidth, map.tileheight,
    map.nextlayerid, map.nextobjectid))

-- Tilesets
for _, ts in ipairs(map.tilesets) do
    w(string.format(' <tileset firstgid="%d" name="%s" tilewidth="%d" tileheight="%d" tilecount="%d" columns="%d">',
        ts.firstgid, ts.name, ts.tilewidth, ts.tileheight, ts.tilecount, ts.columns))
    w(string.format('  <image source="%s" width="%d" height="%d"/>',
        ts.image, ts.imagewidth, ts.imageheight))
    w(' </tileset>')
end

-- Layers
for _, layer in ipairs(map.layers) do
    if layer.type == "tilelayer" then
        w(string.format(' <layer id="%d" name="%s" width="%d" height="%d"%s%s>',
            layer.id, layer.name, layer.width, layer.height,
            layer.visible and "" or ' visible="0"',
            layer.opacity ~= 1 and string.format(' opacity="%.2f"', layer.opacity) or ""))
        -- CSV data
        w('  <data encoding="csv">')
        local data = layer.data
        local rows = {}
        for row = 0, layer.height - 1 do
            local cols = {}
            for col = 1, layer.width do
                cols[col] = tostring(data[row * layer.width + col])
            end
            rows[#rows + 1] = table.concat(cols, ",")
        end
        w(table.concat(rows, ",\n"))
        w('  </data>')
        w(' </layer>')
    elseif layer.type == "objectgroup" then
        w(string.format(' <objectgroup id="%d" name="%s" draworder="%s">',
            layer.id, layer.name, layer.draworder or "topdown"))
        for _, obj in ipairs(layer.objects) do
            if obj.width == 0 and obj.height == 0 then
                w(string.format('  <object id="%d" x="%.1f" y="%.1f"/>',
                    obj.id, obj.x, obj.y))
            else
                w(string.format('  <object id="%d" x="%.1f" y="%.1f" width="%.1f" height="%.1f"/>',
                    obj.id, obj.x, obj.y, obj.width, obj.height))
            end
        end
        w(' </objectgroup>')
    end
end

w('</map>')

local file = io.open("map.tmx", "w")
if file then
    file:write(table.concat(out, "\n"))
    file:close()
    print("Wrote map.tmx")
end
