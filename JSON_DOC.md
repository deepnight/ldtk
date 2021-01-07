# LDtk Json structure (version 0.6.3)

Json schema: https://ldtk.io/files/JSON_SCHEMA.json

## Table of contents
   - [LDtk Json root](#ldtk-ProjectJson)
   - [Level](#ldtk-LevelJson)
     - [Layer instance](#ldtk-LayerInstanceJson)
       - [Tile instance](#ldtk-Tile)
       - [Entity instance](#ldtk-EntityInstanceJson)
       - [Field instance](#ldtk-FieldInstanceJson)
   - [Definitions](#ldtk-DefinitionsJson)
     - [Layer definition](#ldtk-LayerDefJson)
       - [Auto-layer rule definition](#ldtk-AutoRuleDef)
     - [Entity definition](#ldtk-EntityDefJson)
       - [Field definition](#ldtk-FieldDefJson)
     - [Tileset definition](#ldtk-TilesetDefJson)
     - [Enum definition](#ldtk-EnumDefJson)

<a id="ldtk-ProjectJson" name="ldtk-ProjectJson"></a>
## LDtk Json root   
This is the root of any Project JSON file. It contains:

- the project settings,
- an array of levels
- and a definition object (that can probably be safely ignored for most users).

Value | Type | Description
-- | -- | --
`bgColor` | String<br/><small&nbsp;class="color">*Hex&nbsp;color&nbsp;"#rrggbb"*</small> | Project background color
`defaultGridSize` | Int | Default grid size for new layers
`defaultLevelBgColor`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | String<br/><small&nbsp;class="color">*Hex&nbsp;color&nbsp;"#rrggbb"*</small> | Default background color of levels
`defaultPivotX` | Float | Default X pivot (0 to 1) for new entities
`defaultPivotY` | Float | Default Y pivot (0 to 1) for new entities
`defs` | [Definitions](#ldtk-DefinitionsJson) | A structure containing all the definitions of this project
`exportTiled` | Bool | If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file (default is FALSE)
`externalLevels` | Bool | If TRUE, one file will be saved the project (incl. all its definitions) and one file per-level in a sub-folder.
`jsonVersion` | String | File format version
`levels` | Array&nbsp;of&nbsp;[Level](#ldtk-LevelJson) | All levels. The order of this array is only relevant in `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value). Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
`minifyJson` | Bool | If TRUE, the Json is partially minified (no indentation, nor line breaks, default is FALSE)
`nextUid`<br/><sup class="internal">*Internal editor data*</sup> | Int | 
`worldGridHeight`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int | Height of the world grid in pixels.
`worldGridWidth`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int | Width of the world grid in pixels.
`worldLayout`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Enum | An enum that describes how levels are organized in this project (ie. linearly or in a 2D space).<br/> Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`

<a id="ldtk-LevelJson" name="ldtk-LevelJson"></a>
## 1. Level   
This section contains all the level data. It can be found in 2 distinct forms, depending on Project current settings:

- If "*Separate level files*" is **disabled** (default): full level data is *embedded* inside the main Project JSON file,
- If "*Separate level files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one per level). In this case, the main Project JSON file will still contain most level data, except heavy sections, like the `layerInstances` array (which will be null). The `externalRelPath` string points to the `ldtkl` file.

A `ldtkl` file is just a JSON file containing exactly what is described below.

Value | Type | Description
-- | -- | --
`__bgColor`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | String<br/><small&nbsp;class="color">*Hex&nbsp;color&nbsp;"#rrggbb"*</small> | Background color of the level (same as `bgColor`, except the default value is automatically used here if its value is `null`)
`__neighbours`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Array&nbsp;of&nbsp;Object | An array listing all other levels touching this one on the world map. The `dir` is a single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est, `e`ast). In "linear" world layouts, this array is populated with previous/next levels in array, and `dir` depends on the linear horizontal/vertical layout.<br/> This object contains the following fields:<br/> <ul><li>**`dir`** **(String**)</li><li>**`levelUid`** **(Int**)</li></ul>
`bgColor`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)*<br/><small&nbsp;class="color">*Hex&nbsp;color&nbsp;"#rrggbb"*</small> | Background color of the level. If `null`, the project `defaultLevelBgColor` should be used.
`externalRelPath`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.3-green.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | This value is not null if the project option "*Save levels separately*" is enabled. In this case, this **relative** path points to the level Json file.
`identifier` | String | Unique String identifier
`layerInstances`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.6.3-green.svg)  | Array&nbsp;of&nbsp;[Layer&nbsp;instance](#ldtk-LayerInstanceJson)&nbsp;*(can&nbsp;be&nbsp;`null`)* | An array containing all Layer instances. **IMPORTANT**: if the project option "*Save levels separately*" is enabled, this field will be `null`.<br/>		This array is **sorted in display order**: the 1st layer is the top-most and the last is behind.
`pxHei` | Int | Height of the level in pixels
`pxWid` | Int | Width of the level in pixels
`uid` | Int | Unique Int identifier
`worldX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int | World X coordinate in pixels
`worldY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int | World Y coordinate in pixels

<a id="ldtk-LayerInstanceJson" name="ldtk-LayerInstanceJson"></a>
## 1.1. Layer instance   
Value | Type | Description
-- | -- | --
`__cHei` | Int | Grid-based height
`__cWid` | Int | Grid-based width
`__gridSize` | Int | Grid size
`__identifier` | String | Layer definition identifier
`__opacity`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Float | Layer opacity as Float [0-1]
`__pxTotalOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Total layer X pixel offset, including both instance and definition offsets.
`__pxTotalOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Total layer Y pixel offset, including both instance and definition offsets.
`__tilesetDefUid`<br/><sup class="only">Only *Tile layers, Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | The definition UID of corresponding Tileset, if any.
`__tilesetRelPath`<br/><sup class="only">Only *Tile layers, Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | The relative path to corresponding Tileset, if any.
`__type` | String | Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
`autoLayerTiles`<br/><sup class="only">Only *Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;[Tile&nbsp;instance](#ldtk-Tile) | An array containing all tiles generated by Auto-layer rules. The array is already sorted in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>		Note: if multiple tiles are stacked in the same cell as the result of different rules, all tiles behind opaque ones will be discarded.
`entityInstances`<br/><sup class="only">Only *Entity layers*</sup> | Array&nbsp;of&nbsp;[Entity&nbsp;instance](#ldtk-EntityInstanceJson) | 
`gridTiles`<br/><sup class="only">Only *Tile layers*</sup> | Array&nbsp;of&nbsp;[Tile&nbsp;instance](#ldtk-Tile) | 
`intGrid`<br/><sup class="only">Only *IntGrid layers*</sup> | Array&nbsp;of&nbsp;Object | This object contains the following fields:<br/> <ul><li>**`coordId`** **(Int**) : *Coordinate ID in the layer grid*</li><li>**`v`** **(Int**) : *IntGrid value*</li></ul>
`layerDefUid` | Int | Reference the Layer definition UID
`levelId` | Int | Reference to the UID of the level containing this layer instance
`pxOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Int | X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to the `LayerDef` optional offset, see `__pxTotalOffsetX`)
`pxOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Int | Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to the `LayerDef` optional offset, see `__pxTotalOffsetY`)
`seed`<br/><sup class="only">Only *Auto-layers*</sup> | Int | Random seed used for Auto-Layers rendering

<a id="ldtk-Tile" name="ldtk-Tile"></a>
## 1.1.1. Tile instance  ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg) 
Value | Type | Description
-- | -- | --
`d`<br/><sup class="internal">*Internal editor data*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_0.6.0-green.svg)  | Array&nbsp;of&nbsp;Int | Internal data used by the editor.<br/>		For auto-layer tiles: `[ruleId, coordId]`.<br/>		For tile-layer tiles: `[coordId]`.
`f` | Int | "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>		 - Bit 0 = X flip<br/>		 - Bit 1 = Y flip<br/>		 Examples: f=0 (no flip), f=1 (X flip only), f=2 (Y flip only), f=3 (both flips)
`px`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional layer offsets, if they exist!
`src` | Array&nbsp;of&nbsp;Int | Pixel coordinates of the tile in the **tileset** (`[x,y]` format)
`t`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Int | The *Tile ID* in the corresponding tileset.

<a id="ldtk-EntityInstanceJson" name="ldtk-EntityInstanceJson"></a>
## 1.1.2. Entity instance   
Value | Type | Description
-- | -- | --
`__grid`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Grid-based coordinates (`[x,y]` format)
`__identifier` | String | Entity definition identifier
`__tile`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Object&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional Tile used to display this entity (it could either be the default Entity tile, or some tile provided by a field value, like an Enum).<br/> This object contains the following fields:<br/> <ul><li>**`srcRect`** **(Array of Int**) : *An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width, height ]`*</li><li>**`tilesetUid`** **(Int**) : *Tileset ID*</li></ul>
`defUid` | Int | Reference of the **Entity definition** UID
`fieldInstances` | Array&nbsp;of&nbsp;[Field&nbsp;instance](#ldtk-FieldInstanceJson) | 
`px`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget optional layer offsets, if they exist!

<a id="ldtk-FieldInstanceJson" name="ldtk-FieldInstanceJson"></a>
## 1.1.3. Field instance   
Value | Type | Description
-- | -- | --
`__identifier` | String | Field definition identifier
`__type` | String | Type of the field, such as Int, Float, Enum(enum_name), Bool, etc.
`__value` | Dynamic&nbsp;(anything) | Actual value of the field instance. The value type may vary, depending on `__type` (Integer, Boolean, String etc.)<br/>		It can also be an `Array` of those same types.
`defUid` | Int | Reference of the **Field definition** UID
`realEditorValues`<br/><sup class="internal">*Internal editor data*</sup> | Array&nbsp;of&nbsp;Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | 

<a id="ldtk-DefinitionsJson" name="ldtk-DefinitionsJson"></a>
## 2. Definitions   
If you're writing your own LDtk importer, you should probably just ignore *most* stuff in the `defs` section, as it contains data that are mostly useful to the editor. To keep you away from the `defs` section and avoid some unnecessary JSON parsing, important data from definitions is often duplicated in fields prefixed with a double underscore (eg. `__identifier` or `__type`).

The 2 only definition types you might need here are **Tilesets** and **Enums**.

Value | Type | Description
-- | -- | --
`entities` | Array&nbsp;of&nbsp;[Entity&nbsp;definition](#ldtk-EntityDefJson) | 
`enums` | Array&nbsp;of&nbsp;[Enum&nbsp;definition](#ldtk-EnumDefJson) | 
`externalEnums` | Array&nbsp;of&nbsp;[Enum&nbsp;definition](#ldtk-EnumDefJson) | Note: external enums are exactly the same as `enums`, except they have a `relPath` to point to an external source file.
`layers` | Array&nbsp;of&nbsp;[Layer&nbsp;definition](#ldtk-LayerDefJson) | 
`tilesets` | Array&nbsp;of&nbsp;[Tileset&nbsp;definition](#ldtk-TilesetDefJson) | 

<a id="ldtk-LayerDefJson" name="ldtk-LayerDefJson"></a>
## 2.1. Layer definition   
Value | Type | Description
-- | -- | --
`__type` | String | Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)
`autoRuleGroups`<br/><sup class="only">Only *Auto-layers*</sup> | Array&nbsp;of&nbsp;Object | Contains all the auto-layer rule definitions.<br/> This object contains the following fields:<br/> <ul><li>**`active`** **(Bool**)</li><li>**`collapsed`** **(Bool**)</li><li>**`name`** **(String**)</li><li>**`rules`** **(Array of [Auto-layer rule definition](#ldtk-AutoRuleDef)**)</li><li>**`uid`** **(Int**)</li></ul>
`autoSourceLayerDefUid`<br/><sup class="only">Only *Auto-layers*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`autoTilesetDefUid`<br/><sup class="only">Only *Auto-layers*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Reference to the Tileset UID being used by this auto-layer rules
`displayOpacity` | Float | Opacity of the layer (0 to 1.0)
`gridSize` | Int | Width and height of the grid in pixels
`identifier` | String | Unique String identifier
`intGridValues`<br/><sup class="only">Only *IntGrid layer*</sup> | Array&nbsp;of&nbsp;Object | This object contains the following fields:<br/> <ul><li>**`color`** **(String**) <small class="color">*Hex color "#rrggbb"*</small></li><li>**`identifier`** **(String *(can be `null`)***)</li></ul>
`pxOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance` optional offset)
`pxOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance` optional offset)
`tilePivotX`<br/><sup class="only">Only *Tile layers*</sup> | Float | If the tiles are smaller or larger than the layer grid, the pivot value will be used to position the tile relatively its grid cell.
`tilePivotY`<br/><sup class="only">Only *Tile layers*</sup> | Float | If the tiles are smaller or larger than the layer grid, the pivot value will be used to position the tile relatively its grid cell.
`tilesetDefUid`<br/><sup class="only">Only *Tile layers*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Reference to the Tileset UID being used by this tile layer
`type`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Type of the layer as Haxe Enum<br/> Possible values: `IntGrid`, `Entities`, `Tiles`, `AutoLayer`
`uid` | Int | Unique Int identifier

<a id="ldtk-AutoRuleDef" name="ldtk-AutoRuleDef"></a>
## 2.1.1. Auto-layer rule definition   
This complex section isn't meant to be used by game devs at all, as these rules are completely resolved internally by the editor before any saving. You should just ignore this part.

Value | Type | Description
-- | -- | --
`active` | Bool | If FALSE, the rule effect isn't applied, and no tiles are generated.
`breakOnMatch` | Bool | When TRUE, the rule will prevent other rules to be applied in the same cell if it matches (TRUE by default).
`chance` | Float | Chances for this rule to be applied (0 to 1)
`checker` | Enum | Checker mode<br/> Possible values: `None`, `Horizontal`, `Vertical`
`flipX` | Bool | If TRUE, allow rule to be matched by flipping its pattern horizontally
`flipY` | Bool | If TRUE, allow rule to be matched by flipping its pattern vertically
`pattern` | Array&nbsp;of&nbsp;Int | Rule pattern (size x size)
`perlinActive` | Bool | If TRUE, enable Perlin filtering to only apply rule on specific random area
`perlinOctaves` | Float | 
`perlinScale` | Float | 
`perlinSeed` | Float | 
`pivotX`<br/><sup class="only">Only *'Stamp' tile mode*</sup> | Float | X pivot of a tile stamp (0-1)
`pivotY`<br/><sup class="only">Only *'Stamp' tile mode*</sup> | Float | Y pivot of a tile stamp (0-1)
`size` | Int | Pattern width & height. Should only be 1,3,5 or 7.
`tileIds` | Array&nbsp;of&nbsp;Int | Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.
`tileMode` | Enum | Defines how tileIds array is used<br/> Possible values: `Single`, `Stamp`
`uid` | Int | Unique Int identifier
`xModulo` | Int | X cell coord modulo
`yModulo` | Int | Y cell coord modulo

<a id="ldtk-EntityDefJson" name="ldtk-EntityDefJson"></a>
## 2.2. Entity definition   
Value | Type | Description
-- | -- | --
`color` | String<br/><small&nbsp;class="color">*Hex&nbsp;color&nbsp;"#rrggbb"*</small> | Base entity color
`fieldDefs` | Array&nbsp;of&nbsp;[Field&nbsp;definition](#ldtk-FieldDefJson) | Array of field definitions
`height` | Int | Pixel height
`identifier` | String | Unique String identifier
`limitBehavior`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
`maxPerLevel` | Int | Max instances per level
`pivotX` | Float | Pivot X coordinate (from 0 to 1.0)
`pivotY` | Float | Pivot Y coordinate (from 0 to 1.0)
`renderMode`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
`showName`<br/><sup class="internal">*Internal editor data*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Bool | Display entity name in editor
`tileId` | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Tile ID used for optional tile display
`tileRenderMode`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Possible values: `Stretch`, `Crop`
`tilesetId` | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Tileset ID used for optional tile display
`uid` | Int | Unique Int identifier
`width` | Int | Pixel width

<a id="ldtk-FieldDefJson" name="ldtk-FieldDefJson"></a>
## 2.2.1. Field definition  ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg) 
This section is mostly only intended for the LDtk editor app itself. You can safely ignore it.

Value | Type | Description
-- | -- | --
`__type` | String | Human readable value type (eg. `Int`, `Float`, `Point`, etc.). If the field is an array, this field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)
`acceptFileTypes`<br/><sup class="only">Only *FilePath*</sup> | Array&nbsp;of&nbsp;String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional list of accepted file extensions for FilePath value type. Includes the dot: `.ext`
`arrayMaxLength`<br/><sup class="only">Only *Array*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Array max length
`arrayMinLength`<br/><sup class="only">Only *Array*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Array min length
`canBeNull` | Bool | TRUE if the value can be null. For arrays, TRUE means it can contain null values (exception: array of Points can't have null values).
`defaultOverride` | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | Default value if selected value is null or invalid.
`editorAlwaysShow`<br/><sup class="internal">*Internal editor data*</sup> | Bool | 
`editorDisplayMode`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `PointStar`, `PointPath`, `RadiusPx`, `RadiusGrid`
`editorDisplayPos`<br/><sup class="internal">*Internal editor data*</sup> | Enum | Possible values: `Above`, `Center`, `Beneath`
`identifier` | String | Unique String identifier
`isArray` | Bool | TRUE if the value is an array of multiple values
`max`<br/><sup class="only">Only *Int, Float*</sup> | Float&nbsp;*(can&nbsp;be&nbsp;`null`)* | Max limit for value, if applicable
`min`<br/><sup class="only">Only *Int, Float*</sup> | Float&nbsp;*(can&nbsp;be&nbsp;`null`)* | Min limit for value, if applicable
`regex`<br/><sup class="only">Only *String*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.2-green.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional regular expression that needs to be matched to accept values. Expected format: `/some_reg_ex/g`, with optional "i" flag.
`type` | Dynamic&nbsp;(anything) | Internal type enum
`uid` | Int | Unique Intidentifier

<a id="ldtk-TilesetDefJson" name="ldtk-TilesetDefJson"></a>
## 2.3. Tileset definition   
The `Tileset` definition is the most useful part among project definitions. It contains some extra informations about each integrated tileset. If you only had to parse one definition section, that would be the one.

Value | Type | Description
-- | -- | --
`cachedPixelData`<br/><sup class="internal">*Internal editor data*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  | Object&nbsp;*(can&nbsp;be&nbsp;`null`)* | The following data is used internally for various optimizations. It's always synced with source image changes.<br/> This object contains the following fields:<br/> <ul><li>**`averageColors`** **(String *(can be `null`)***)  ![Generic badge](https://img.shields.io/badge/Added_0.6.0-green.svg)  : *Average color codes for each tileset tile (ARGB format)*</li><li>**`opaqueTiles`** **(String**)  ![Generic badge](https://img.shields.io/badge/Changed_0.6.0-green.svg)  : *An array of 0/1 bytes, encoded in Base64, that tells if a specific TileID is fully opaque (1) or not (0)*</li></ul>
`identifier` | String | Unique String identifier
`padding` | Int | Distance in pixels from image borders
`pxHei` | Int | Image height in pixels
`pxWid` | Int | Image width in pixels
`relPath` | String | Path to the source file, relative to the current project JSON file
`savedSelections`<br/><sup class="internal">*Internal editor data*</sup> | Array&nbsp;of&nbsp;Object | Array of group of tiles selections, only meant to be used in the editor<br/> This object contains the following fields:<br/> <ul><li>**`ids`** **(Array of Int**)</li><li>**`mode`** **(Enum**)</li></ul>
`spacing` | Int | Space in pixels between all tiles
`tileGridSize` | Int | 
`uid` | Int | Unique Intidentifier

<a id="ldtk-EnumDefJson" name="ldtk-EnumDefJson"></a>
## 2.4. Enum definition   
Value | Type | Description
-- | -- | --
`externalFileChecksum`<br/><sup class="internal">*Internal editor data*</sup> | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`externalRelPath` | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Relative path to the external file providing this Enum
`iconTilesetUid` | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Tileset UID if provided
`identifier` | String | Unique String identifier
`uid` | Int | Unique Int identifier
`values` | Array&nbsp;of&nbsp;Object | All possible enum values, with their optional Tile infos.<br/> This object contains the following fields:<br/> <ul><li>**`__tileSrcRect`** **(Array of Int**)  ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  : *An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width, height ]`*</li><li>**`id`** **(String**) : *Enum value*</li><li>**`tileId`** **(Int *(can be `null`)***) : *The optional ID of the tile*</li></ul>