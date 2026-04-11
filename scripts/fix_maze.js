// Open the map
var map = tiled.open("assets/tield/map1.tmx");

// Find the "tree" layer
var treeLayer = null;
for (var i = 0; i < map.layerCount; i++) {
    if (map.layerAt(i).name == "tree") {
        treeLayer = map.layerAt(i);
        break;
    }
}

if (treeLayer) {
    // Remove tree objects inside the maze area (tiles 64-75, rows 0-11)
    var toRemove = [];
    for (var i = 0; i < treeLayer.objectCount; i++) {
        var obj = treeLayer.objectAt(i);
        var tx = obj.x / 32;
        var ty = obj.y / 32;
        if (tx >= 63 && tx <= 76 && ty >= 0 && ty <= 12) {
            toRemove.push(obj);
            tiled.log("Removing tree at tile " + tx + "," + ty + " (id=" + obj.id + ")");
        }
    }
    for (var i = 0; i < toRemove.length; i++) {
        treeLayer.removeObject(toRemove[i]);
    }
    tiled.log("Removed " + toRemove.length + " trees from maze area");
} else {
    tiled.log("ERROR: tree layer not found");
}

// Save back to tmx
var tmxFormat = tiled.mapFormat("tmx");
tmxFormat.write(map, "assets/tield/map1.tmx");

tiled.log("Done!");
