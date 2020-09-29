# 0.3.0-beta

**BREAKING CHANGE**: some cleanup & renaming happened on this update, please check changes below.

## Tiles layer

 - `__tileX` / `__tileY` were renamed to `__srcX` / `__srcY` in `layerInstances.gridTiles`. These values are **pixel coordinates of the tile in the tileset atlas image**.
 - added `__x` / `__y` values, which are **pixel display coordinates of each tile**.

## Auto-tile layers
 To support new rule-based group of tiles (eg. "*placing a big object using just rules*"), some changes were introduced to the `layerInstances.autoLayers` structure (see example below):
   - Renamed `tiles` to `results`.
   - Replaced `tileId` from `layerInstances.autoTiles` with an array called `tiles`.
   - Renamed `__tileX` and `__tileY` in these sections with hopefully clearer names `__srcX` and `__srcY`. These are still X/Y pixel coordinates of corresponding tiles in the tileset image.
   - Added `_x` and `_y` which are pre-computed pixel coordinates of tile on screen
   - Please refer to updated doc for more infos: https://deepnight.net/docs/led/json/

Before, in layerInstances:
```json
"autoTiles": [
	{
		"ruleId": 101,
		"tiles": [ {
			"coordId": 90,
			"tileId": 169,
			"__tileX": 32,
			"__tileY": 128,
			"flips": 0
		} ]
	}
]
```

Now:
```json
"autoTiles": [
	{
		"ruleId": 101,
		"results": [ {    // <--- Renamed!
			"coordId": 90,
			"tiles": [    // <---- Now an array!
				{ "tileId": 169, "__x": 64, "__y": 8, "__srcX": 8, "__srcY": 112 },
				{ "tileId": 181, "__x": 64, "__y": 16, "__srcX": 8, "__srcY": 120 }
			],
			"flips": 0
		} ]
	}
]
```

# 0.2.1-beta

 - Added `__tileX` / `__tileY` to `layerInstances.autoTiles`
 - Added `__tileX` / `__tileY` to `layerInstances.gridTiles`
 - Renamed `v` to `tileId` in `layerInstances.gridTiles`
 - Renamed `tileSpacing` -> `spacing` in `tilesets` definitions
 - Added `padding` to `tilesets` definitions

# 0.2.0-beta

 Initial beta release