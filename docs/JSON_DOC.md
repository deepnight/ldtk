# LDtk Json structure (version 1.3.0)


<a id="ldtk-ProjectJson" name="ldtk-ProjectJson"></a>
## 1. LDtk Json root   
This is the root of any Project JSON file. It contains:

- the project settings,
- an array of levels,
- a group of definitions (that can probably be safely ignored for most users).

Value | Type | Description
-- | -- | --
`bgColor` | String<br/><small class="color"> *Hex color "#rrggbb"* </small> | Project background color
`defs` | [Definitions](#ldtk-DefinitionsJson) | A structure containing all the definitions of this project
`externalLevels`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Bool | If TRUE, one file will be saved for the project (incl. all its definitions) and one file in a sub-folder for each level.
`iid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.0-gray.svg)  | String | Unique project identifier
`jsonVersion` | String | File format version
`levels` | Array&nbsp;of&nbsp;[Level](#ldtk-LevelJson) | All levels. The order of this array is only relevant in `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).<br/>		Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
`toc`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.4-gray.svg)  | Array&nbsp;of&nbsp;Object | All instances of entities that have their `exportToToc` flag enabled are listed in this array.<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`identifier`** **(String**)</li><li>**`instances`** **(Array of [Reference to an Entity instance](#ldtk-EntityReferenceInfos)**)</li></ul>
`worldGridHeight`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update. It will then be `null`. You can enable the Multi-worlds advanced project option to enable the change immediately.<br/><br/>		Height of the world grid in pixels.
`worldGridWidth`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update. It will then be `null`. You can enable the Multi-worlds advanced project option to enable the change immediately.<br/><br/>		Width of the world grid in pixels.
`worldLayout`<br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update. It will then be `null`. You can enable the Multi-worlds advanced project option to enable the change immediately.<br/><br/>		An enum that describes how levels are organized in this project (ie. linearly or in a 2D space).<br/> Possible values: &lt;`null`&gt;, `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`
`worlds`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;[World](#ldtk-WorldJson) | This array will be empty, unless you enable the Multi-Worlds in the project advanced settings.<br/><br/> - in current version, a LDtk project file can only contain a single world with multiple levels in it. In this case, levels and world layout related settings are stored in the root of the JSON.<br/> - with "Multi-worlds" enabled, there will be a `worlds` array in root, each world containing levels and layout settings. Basically, it's pretty much only about moving the `levels` array to the `worlds` array, along with world layout related values (eg. `worldGridWidth` etc).<br/><br/>If you want to start supporting this future update easily, please refer to this documentation: https://github.com/deepnight/ldtk/issues/231
`appBuildId`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Float | LDtk application build identifier.<br/>		This is only used to identify the LDtk version that generated this particular project file, which can be useful for specific bug fixing. Note that the build identifier is just the date of the release, so it's not unique to each user (one single global ID per LDtk public release), and as a result, completely anonymous.
`backupLimit`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Int | Number of backup files to keep, if the `backupOnSave` is TRUE
`backupOnSave`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Bool | If TRUE, an extra copy of the project will be created in a sub folder, when saving.
`backupRelPath`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Target relative path to store backup files
`customCommands`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.0-gray.svg)  | Array&nbsp;of&nbsp;Object | An array of command lines that can be ran manually by the user<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`command`** **(String**)</li><li>**`when`** **(Enum**) : *Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`*</li></ul>
`defaultGridSize`<br/><sup class="internal">*Only used by editor*</sup> | Int | Default grid size for new layers
`defaultLevelBgColor`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | String<br/><small class="color"> *Hex color "#rrggbb"* </small> | Default background color of levels
`defaultLevelHeight`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update. It will then be `null`. You can enable the Multi-worlds advanced project option to enable the change immediately.<br/><br/>		Default new level height
`defaultLevelWidth`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update. It will then be `null`. You can enable the Multi-worlds advanced project option to enable the change immediately.<br/><br/>		Default new level width
`defaultPivotX`<br/><sup class="internal">*Only used by editor*</sup> | Float | Default X pivot (0 to 1) for new entities
`defaultPivotY`<br/><sup class="internal">*Only used by editor*</sup> | Float | Default Y pivot (0 to 1) for new entities
`dummyWorldIid`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | String | If the project isn't in MultiWorlds mode, this is the IID of the internal "dummy" World.
`exportLevelBg`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.0-gray.svg)  | Bool | If TRUE, the exported PNGs will include the level background (color or image).
`exportTiled`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file (default is FALSE)
`flags`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;Enum | An array containing various advanced flags (ie. options or other states).<br/> Possible values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`, `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`
`identifierStyle`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Enum | Naming convention for Identifiers (first-letter uppercase, full uppercase etc.)<br/> Possible values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
`imageExportMode`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.3-gray.svg)  | Enum | "Image export" option when saving project.<br/> Possible values: `None`, `OneImagePerLayer`, `OneImagePerLevel`, `LayersAndLevels`
`levelNamePattern`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | String | The default naming convention for level identifiers.
`minifyJson`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If TRUE, the Json is partially minified (no indentation, nor line breaks, default is FALSE)
`nextUid`<br/><sup class="internal">*Only used by editor*</sup> | Int | Next Unique integer ID available
`pngFilePattern`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.2-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | File naming pattern for exported PNGs
`simplifiedExport`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.1.0-gray.svg)  | Bool | If TRUE, a very simplified will be generated on saving, for quicker & easier engine integration.
`tutorialDesc`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | This optional description is used by LDtk Samples to show up some informations and instructions.
~~`exportPng`~~<br/><sup class="internal">*Only used by editor*</sup><br/><sup class="deprecated">*DEPRECATED!*</sup><br/> ![Generic badge](https://img.shields.io/badge/Removed_0.9.3-gray.svg)  | Bool&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value is no longer exported since version 0.9.3<br/> <br/> Replaced by: `imageExportMode`

<a id="ldtk-WorldJson" name="ldtk-WorldJson"></a>
## 1.1. World  ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg) 
**IMPORTANT**: this type is available as a preview. You can rely on it to update your importers, for when it will be officially available.

A World contains multiple levels, and it has its own layout settings.

Value | Type | Description
-- | -- | --
`identifier`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | User defined unique identifier
`iid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | Unique instance identifer
`levels`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;[Level](#ldtk-LevelJson) | All levels from this world. The order of this array is only relevant in `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value). Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
`worldGridHeight`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Height of the world grid in pixels.
`worldGridWidth`<br/><sup class="only">Only *'GridVania' layouts*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Width of the world grid in pixels.
`worldLayout`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Enum | An enum that describes how levels are organized in this project (ie. linearly or in a 2D space).<br/> Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`
`defaultLevelHeight`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Default new level height
`defaultLevelWidth`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Default new level width

<a id="ldtk-LevelJson" name="ldtk-LevelJson"></a>
## 2. Level   
This section contains all the level data. It can be found in 2 distinct forms, depending on Project current settings:

- If "*Separate level files*" is **disabled** (default): full level data is *embedded* inside the main Project JSON file,
- If "*Separate level files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one per level). In this case, the main Project JSON file will still contain most level data, except heavy sections, like the `layerInstances` array (which will be null). The `externalRelPath` string points to the `ldtkl` file.

A `ldtkl` file is just a JSON file containing exactly what is described below.

Value | Type | Description
-- | -- | --
`__bgColor`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | String<br/><small class="color"> *Hex color "#rrggbb"* </small> | Background color of the level (same as `bgColor`, except the default value is automatically used here if its value is `null`)
`__bgPos`<br/><sup class="only">Only *If background image exists*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Object&nbsp;*(can&nbsp;be&nbsp;`null`)* | Position informations of the background image, if there is one.<br/> This object contains the following fields:<br/> <ul class='subFields'><li>**`cropRect`** **(Array of Float**) : *An array of 4 float values describing the cropped sub-rectangle of the displayed background image. This cropping happens when original is larger than the level bounds. Array format: `[ cropX, cropY, cropWidth, cropHeight ]`*</li><li>**`scale`** **(Array of Float**) : *An array containing the `[scaleX,scaleY]` values of the **cropped** background image, depending on `bgPos` option.*</li><li>**`topLeftPx`** **(Array of Int**) : *An array containing the `[x,y]` pixel coordinates of the top-left corner of the **cropped** background image, depending on `bgPos` option.*</li></ul>
`__neighbours`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg) ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;Object | An array listing all other levels touching this one on the world map.<br/>		Only relevant for world layouts where level spatial positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, this array is always empty.<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`dir`** **(String**) : *A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est, `e`ast).*</li><li>**`levelIid`** **(String**)  ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  : *Neighbour Instance Identifier*</li><li>**`levelUid`** **(Int *(can be `null`)***)  ![Generic badge](https://img.shields.io/badge/Removed_1.2.0-gray.svg)  : ***WARNING**: this deprecated value is no longer exported since version 1.2.0* ** *Replaced by: `levelIid`*</li></ul>
`bgRelPath`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | The *optional* relative path to the level background image.
`externalRelPath`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | This value is not null if the project option "*Save levels separately*" is enabled. In this case, this **relative** path points to the level Json file.
`fieldInstances`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;[Field&nbsp;instance](#ldtk-FieldInstanceJson) | An array containing this level custom field values.
`identifier` | String | User defined unique identifier
`iid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | Unique instance identifier
`layerInstances`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.7.0-gray.svg)  | Array&nbsp;of&nbsp;[Layer&nbsp;instance](#ldtk-LayerInstanceJson)&nbsp;*(can&nbsp;be&nbsp;`null`)* | An array containing all Layer instances. **IMPORTANT**: if the project option "*Save levels separately*" is enabled, this field will be `null`.<br/>		This array is **sorted in display order**: the 1st layer is the top-most and the last is behind.
`pxHei` | Int | Height of the level in pixels
`pxWid` | Int | Width of the level in pixels
`uid` | Int | Unique Int identifier
`worldDepth`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Index that represents the "depth" of the level in the world. Default is 0, greater means "above", lower means "below".<br/>		This value is mostly used for display only and is intended to make stacking of levels easier to manage.
`worldX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg) ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int | World X coordinate in pixels.<br/>		Only relevant for world layouts where level spatial positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the value is always -1 here.
`worldY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg) ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int | World Y coordinate in pixels.<br/>		Only relevant for world layouts where level spatial positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the value is always -1 here.
`__smartColor`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String<br/><small class="color"> *Hex color "#rrggbb"* </small> | The "guessed" color for this level in the editor, decided using either the background color or an existing custom field.
`bgColor`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)*<br/><small class="color"> *Hex color "#rrggbb"* </small> | Background color of the level. If `null`, the project `defaultLevelBgColor` should be used.
`bgPivotX`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Float | Background image X pivot (0-1)
`bgPivotY`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Float | Background image Y pivot (0-1)
`bgPos`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | An enum defining the way the background image (if any) is positioned on the level. See `__bgPos` for resulting position info.<br/> Possible values: &lt;`null`&gt;, `Unscaled`, `Contain`, `Cover`, `CoverDirty`, `Repeat`
`useAutoIdentifier`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Bool | If TRUE, the level identifier will always automatically use the naming pattern as defined in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by user.

<a id="ldtk-LayerInstanceJson" name="ldtk-LayerInstanceJson"></a>
## 2.1. Layer instance   
Value | Type | Description
-- | -- | --
`__cHei` | Int | Grid-based height
`__cWid` | Int | Grid-based width
`__gridSize` | Int | Grid size
`__identifier` | String | Layer definition identifier
`__opacity`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Float | Layer opacity as Float [0-1]
`__pxTotalOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Total layer X pixel offset, including both instance and definition offsets.
`__pxTotalOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Total layer Y pixel offset, including both instance and definition offsets.
`__tilesetDefUid`<br/><sup class="only">Only *Tile layers, Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | The definition UID of corresponding Tileset, if any.
`__tilesetRelPath`<br/><sup class="only">Only *Tile layers, Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | The relative path to corresponding Tileset, if any.
`__type` | String | Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
`autoLayerTiles`<br/><sup class="only">Only *Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;[Tile&nbsp;instance](#ldtk-Tile) | An array containing all tiles generated by Auto-layer rules. The array is already sorted in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>		Note: if multiple tiles are stacked in the same cell as the result of different rules, all tiles behind opaque ones will be discarded.
`entityInstances`<br/><sup class="only">Only *Entity layers*</sup> | Array&nbsp;of&nbsp;[Entity&nbsp;instance](#ldtk-EntityInstanceJson) | 
`gridTiles`<br/><sup class="only">Only *Tile layers*</sup> | Array&nbsp;of&nbsp;[Tile&nbsp;instance](#ldtk-Tile) | 
`iid` | String | Unique layer instance identifier
`intGridCsv`<br/><sup class="only">Only *IntGrid layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;Int | A list of all values in the IntGrid layer, stored in CSV format (Comma Separated Values).<br/>		Order is from left to right, and top to bottom (ie. first row from left to right, followed by second row, etc).<br/>		`0` means "empty cell" and IntGrid values start at 1.<br/>		The array size is `__cWid` x `__cHei` cells.
`layerDefUid` | Int | Reference the Layer definition UID
`levelId` | Int | Reference to the UID of the level containing this layer instance
`overrideTilesetUid`<br/><sup class="only">Only *Tile layers*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | This layer can use another tileset by overriding the tileset UID here.
`pxOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Int | X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX` which contains the total offset value)
`pxOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Int | Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX` which contains the total offset value)
`visible`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | Layer instance visibility
`optionalRules`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Array&nbsp;of&nbsp;Int | An Array containing the UIDs of optional rules that were enabled in this specific layer instance.
`seed`<br/><sup class="only">Only *Auto-layers*</sup><br/><sup class="internal">*Only used by editor*</sup> | Int | Random seed used for Auto-Layers rendering
~~`intGrid`~~<br/><sup class="only">Only *IntGrid layers*</sup><br/><sup class="deprecated">*DEPRECATED!*</sup><br/> ![Generic badge](https://img.shields.io/badge/Removed_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;Object&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value is no longer exported since version 1.0.0<br/> <br/> Replaced by: `intGridCsv`

<a id="ldtk-Tile" name="ldtk-Tile"></a>
## 2.2. Tile instance  ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg) 
This structure represents a single tile from a given Tileset.

Value | Type | Description
-- | -- | --
`f` | Int | "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>		 - Bit 0 = X flip<br/>		 - Bit 1 = Y flip<br/>		 Examples: f=0 (no flip), f=1 (X flip only), f=2 (Y flip only), f=3 (both flips)
`px`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.5.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional layer offsets, if they exist!
`src` | Array&nbsp;of&nbsp;Int | Pixel coordinates of the tile in the **tileset** (`[x,y]` format)
`t`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | Int | The *Tile ID* in the corresponding tileset.
`d`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_0.6.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Internal data used by the editor.<br/>		For auto-layer tiles: `[ruleId, coordId]`.<br/>		For tile-layer tiles: `[coordId]`.

<a id="ldtk-EntityInstanceJson" name="ldtk-EntityInstanceJson"></a>
## 2.3. Entity instance   
Value | Type | Description
-- | -- | --
`__grid`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Grid-based coordinates (`[x,y]` format)
`__identifier` | String | Entity definition identifier
`__pivot`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.7.0-gray.svg)  | Array&nbsp;of&nbsp;Float | Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity
`__smartColor`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | The entity "smart" color, guessed from either Entity definition, or one its field instances.
`__tags`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;String | Array of tags defined in this Entity definition
`__tile`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg) ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | [Tileset&nbsp;rectangle](#ldtk-TilesetRect)&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional TilesetRect used to display this entity (it could either be the default Entity tile, or some tile provided by a field value, like an Enum).
`defUid` | Int | Reference of the **Entity definition** UID
`fieldInstances` | Array&nbsp;of&nbsp;[Field&nbsp;instance](#ldtk-FieldInstanceJson) | An array of all custom fields and their values.
`height`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Int | Entity height in pixels. For non-resizable entities, it will be the same as Entity definition.
`iid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | Unique instance identifier
`px`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;Int | Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget optional layer offsets, if they exist!
`width`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Int | Entity width in pixels. For non-resizable entities, it will be the same as Entity definition.

<a id="ldtk-FieldInstanceJson" name="ldtk-FieldInstanceJson"></a>
## 2.4. Field instance   
Value | Type | Description
-- | -- | --
`__identifier` | String | Field definition identifier
`__tile`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | [Tileset&nbsp;rectangle](#ldtk-TilesetRect)&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional TilesetRect used to display this field (this can be the field own Tile, or some other Tile guessed from the value, like an Enum).
`__type` | String | Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`, etc.<br/>		NOTE: if you enable the advanced option **Use Multilines type**, you will have "*Multilines*" instead of "*String*" when relevant.
`__value` | Various&nbsp;possible&nbsp;types | Actual value of the field instance. The value type varies, depending on `__type`:<br/>		 - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you just get the actual value with the expected type.<br/>		 - For **Color**, the value is an hexadecimal string using "#rrggbb" format.<br/>		 - For **Enum**, the value is a String representing the selected enum value.<br/>		 - For **Point**, the value is a [GridPoint](#ldtk-GridPoint) object.<br/>		 - For **Tile**, the value is a [TilesetRect](#ldtk-TilesetRect) object.<br/>		 - For **EntityRef**, the value is an [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>		If the field is an array, then this `__value` will also be a JSON array.
`defUid` | Int | Reference of the **Field definition** UID
`realEditorValues`<br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | Editor internal raw values

<a id="ldtk-EntityReferenceInfos" name="ldtk-EntityReferenceInfos"></a>
## 2.4.2. Reference to an Entity instance  ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg) 
This object describes the "location" of an Entity instance in the project worlds.

Value | Type | Description
-- | -- | --
`entityIid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | IID of the refered EntityInstance
`layerIid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | IID of the LayerInstance containing the refered EntityInstance
`levelIid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | IID of the Level containing the refered EntityInstance
`worldIid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String | IID of the World containing the refered EntityInstance

<a id="ldtk-GridPoint" name="ldtk-GridPoint"></a>
## 2.4.3. Grid point  ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg) 
This object is just a grid-based coordinate used in Field values.

Value | Type | Description
-- | -- | --
`cx`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | X grid-based coordinate
`cy`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Y grid-based coordinate

<a id="ldtk-DefinitionsJson" name="ldtk-DefinitionsJson"></a>
## 3. Definitions   
If you're writing your own LDtk importer, you should probably just ignore *most* stuff in the `defs` section, as it contains data that are mostly important to the editor. To keep you away from the `defs` section and avoid some unnecessary JSON parsing, important data from definitions is often duplicated in fields prefixed with a double underscore (eg. `__identifier` or `__type`).

The 2 only definition types you might need here are **Tilesets** and **Enums**.

Value | Type | Description
-- | -- | --
`entities` | Array&nbsp;of&nbsp;[Entity&nbsp;definition](#ldtk-EntityDefJson) | All entities definitions, including their custom fields
`enums` | Array&nbsp;of&nbsp;[Enum&nbsp;definition](#ldtk-EnumDefJson) | All internal enums
`externalEnums` | Array&nbsp;of&nbsp;[Enum&nbsp;definition](#ldtk-EnumDefJson) | Note: external enums are exactly the same as `enums`, except they have a `relPath` to point to an external source file.
`layers` | Array&nbsp;of&nbsp;[Layer&nbsp;definition](#ldtk-LayerDefJson) | All layer definitions
`levelFields`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;[Field&nbsp;definition](#ldtk-FieldDefJson) | All custom fields available to all levels.
`tilesets` | Array&nbsp;of&nbsp;[Tileset&nbsp;definition](#ldtk-TilesetDefJson) | All tilesets

<a id="ldtk-LayerDefJson" name="ldtk-LayerDefJson"></a>
## 3.1. Layer definition   
Value | Type | Description
-- | -- | --
`__type` | String | Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)
`autoSourceLayerDefUid`<br/><sup class="only">Only *Auto-layers*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`displayOpacity` | Float | Opacity of the layer (0 to 1.0)
`gridSize` | Int | Width and height of the grid in pixels
`identifier` | String | User defined unique identifier
`intGridValues`<br/><sup class="only">Only *IntGrid layer*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;Object | An array that defines extra optional info for each IntGrid value.<br/>		WARNING: the array order is not related to actual IntGrid values! As user can re-order IntGrid values freely, you may value "2" before value "1" in this array.<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`color`** **(String**) <small class="color"> *Hex color "#rrggbb"* </small></li><li>**`identifier`** **(String *(can be `null`)***) : *User defined unique identifier*</li><li>**`value`** **(Int**)  ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  : *The IntGrid value itself*</li></ul>
`parallaxFactorX`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Float | Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling speed of this layer, creating a fake 3D (parallax) effect.
`parallaxFactorY`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Float | Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed of this layer, creating a fake 3D (parallax) effect.
`parallaxScaling`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | If true (default), a layer with a parallax factor will also be scaled up/down accordingly.
`pxOffsetX`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance` optional offset)
`pxOffsetY`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.5.0-gray.svg)  | Int | Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance` optional offset)
`tilesetDefUid`<br/><sup class="only">Only *Tile layers, Auto-layers*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Reference to the default Tileset UID being used by this layer definition.<br/>		**WARNING**: some layer *instances* might use a different tileset. So most of the time, you should probably use the `__tilesetDefUid` value found in layer instances.<br/>		Note: since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
`uid` | Int | Unique Int identifier
`autoRuleGroups`<br/><sup class="only">Only *Auto-layers*</sup><br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;Object | Contains all the auto-layer rule definitions.<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`active`** **(Bool**)</li><li>~~collapsed~~ **(Bool**)    *This field was removed in 1.0.0 and should no longer be used.*</li><li>**`isOptional`** **(Bool**)  ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg) </li><li>**`name`** **(String**)</li><li>**`rules`** **(Array of [Auto-layer rule definition](#ldtk-AutoRuleDef)**)</li><li>**`uid`** **(Int**)</li><li>**`usesWizard`** **(Bool**)  ![Generic badge](https://img.shields.io/badge/Added_1.1.4-gray.svg) </li></ul>
`canSelectWhenInactive`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.1.4-gray.svg)  | Bool | Allow editor selections when the layer is not currently active.
`doc`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.5-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | User defined documentation for this element to provide help/tips to level designers.
`excludedTags`<br/><sup class="only">Only *Entity layer*</sup><br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;String | An array of tags to forbid some Entities in this layer
`guideGridHei`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Height of the optional "guide" grid in pixels
`guideGridWid`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Width of the optional "guide" grid in pixels
`hideFieldsWhenInactive`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | 
`hideInList`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | Hide the layer from the list on the side of the editor view.
`inactiveOpacity`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Float | Alpha of this layer when it is not the active one.
`requiredTags`<br/><sup class="only">Only *Entity layer*</sup><br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;String | An array of tags to filter Entities that can be added to this layer
`tilePivotX`<br/><sup class="only">Only *Tile layers*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float | If the tiles are smaller or larger than the layer grid, the pivot value will be used to position the tile relatively its grid cell.
`tilePivotY`<br/><sup class="only">Only *Tile layers*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float | If the tiles are smaller or larger than the layer grid, the pivot value will be used to position the tile relatively its grid cell.
`type`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Type of the layer as Haxe Enum<br/> Possible values: `IntGrid`, `Entities`, `Tiles`, `AutoLayer`
~~`autoTilesetDefUid`~~<br/><sup class="only">Only *Auto-layers*</sup><br/><sup class="deprecated">*DEPRECATED!*</sup><br/> ![Generic badge](https://img.shields.io/badge/Removed_1.2.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value is no longer exported since version 1.2.0<br/> <br/> Replaced by: `tilesetDefUid`

<a id="ldtk-AutoRuleDef" name="ldtk-AutoRuleDef"></a>
## 3.1.1. Auto-layer rule definition   
This complex section isn't meant to be used by game devs at all, as these rules are completely resolved internally by the editor before any saving. You should just ignore this part.

Value | Type | Description
-- | -- | --
`active`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If FALSE, the rule effect isn't applied, and no tiles are generated.
`breakOnMatch`<br/><sup class="internal">*Only used by editor*</sup> | Bool | When TRUE, the rule will prevent other rules to be applied in the same cell if it matches (TRUE by default).
`chance`<br/><sup class="internal">*Only used by editor*</sup> | Float | Chances for this rule to be applied (0 to 1)
`checker`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Checker mode<br/> Possible values: `None`, `Horizontal`, `Vertical`
`flipX`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If TRUE, allow rule to be matched by flipping its pattern horizontally
`flipY`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If TRUE, allow rule to be matched by flipping its pattern vertically
`outOfBoundsValue`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Default IntGrid value when checking cells outside of level bounds
`pattern`<br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;Int | Rule pattern (size x size)
`perlinActive`<br/><sup class="internal">*Only used by editor*</sup> | Bool | If TRUE, enable Perlin filtering to only apply rule on specific random area
`perlinOctaves`<br/><sup class="internal">*Only used by editor*</sup> | Float | 
`perlinScale`<br/><sup class="internal">*Only used by editor*</sup> | Float | 
`perlinSeed`<br/><sup class="internal">*Only used by editor*</sup> | Float | 
`pivotX`<br/><sup class="only">Only *'Stamp' tile mode*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float | X pivot of a tile stamp (0-1)
`pivotY`<br/><sup class="only">Only *'Stamp' tile mode*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float | Y pivot of a tile stamp (0-1)
`size`<br/><sup class="internal">*Only used by editor*</sup> | Int | Pattern width & height. Should only be 1,3,5 or 7.
`tileIds`<br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;Int | Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.
`tileMode`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Defines how tileIds array is used<br/> Possible values: `Single`, `Stamp`
`tileRandomXMax`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Max random offset for X tile pos
`tileRandomXMin`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Min random offset for X tile pos
`tileRandomYMax`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Max random offset for Y tile pos
`tileRandomYMin`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Min random offset for Y tile pos
`tileXOffset`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Tile X offset
`tileYOffset`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int | Tile Y offset
`uid`<br/><sup class="internal">*Only used by editor*</sup> | Int | Unique Int identifier
`xModulo`<br/><sup class="internal">*Only used by editor*</sup> | Int | X cell coord modulo
`xOffset`<br/><sup class="internal">*Only used by editor*</sup> | Int | X cell start offset
`yModulo`<br/><sup class="internal">*Only used by editor*</sup> | Int | Y cell coord modulo
`yOffset`<br/><sup class="internal">*Only used by editor*</sup> | Int | Y cell start offset

<a id="ldtk-EntityDefJson" name="ldtk-EntityDefJson"></a>
## 3.2. Entity definition   
Value | Type | Description
-- | -- | --
`color` | String<br/><small class="color"> *Hex color "#rrggbb"* </small> | Base entity color
`height` | Int | Pixel height
`identifier` | String | User defined unique identifier
`nineSliceBorders`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;Int | An array of 4 dimensions for the up/right/down/left borders (in this order) when using 9-slice mode for `tileRenderMode`.<br/>		If the tileRenderMode is not NineSlice, then this array is empty.<br/>		See: https://en.wikipedia.org/wiki/9-slice_scaling
`pivotX` | Float | Pivot X coordinate (from 0 to 1.0)
`pivotY` | Float | Pivot Y coordinate (from 0 to 1.0)
`tileRect`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | [Tileset&nbsp;rectangle](#ldtk-TilesetRect)&nbsp;*(can&nbsp;be&nbsp;`null`)* | An object representing a rectangle from an existing Tileset
`tileRenderMode`<br/> ![Generic badge](https://img.shields.io/badge/Changed_0.8.1-gray.svg)  | Enum | An enum describing how the the Entity tile is rendered inside the Entity bounds.<br/> Possible values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`, `FullSizeUncropped`, `NineSlice`
`tilesetId` | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Tileset ID used for optional tile display
`uid` | Int | Unique Int identifier
`width` | Int | Pixel width
`doc`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.5-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | User defined documentation for this element to provide help/tips to level designers.
`exportToToc`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.4-gray.svg)  | Bool | If enabled, all instances of this entity will be listed in the project "Table of content" object.
`fieldDefs`<br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;[Field&nbsp;definition](#ldtk-FieldDefJson) | Array of field definitions
`fillOpacity`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Float | 
`hollow`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | 
`keepAspectRatio`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height will keep the same aspect ratio as the definition.
`limitBehavior`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
`limitScope`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Enum | If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level".<br/> Possible values: `PerLayer`, `PerLevel`, `PerWorld`
`lineOpacity`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Float | 
`maxCount`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_0.8.0-gray.svg)  | Int | Max instances count
`renderMode`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
`resizableX`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | If TRUE, the entity instances will be resizable horizontally
`resizableY`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | If TRUE, the entity instances will be resizable vertically
`showName`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Bool | Display entity name in editor
`tags`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Array&nbsp;of&nbsp;String | An array of strings that classifies this entity
`tileOpacity`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Float | 
~~`tileId`~~<br/><sup class="deprecated">*DEPRECATED!*</sup><br/> ![Generic badge](https://img.shields.io/badge/Removed_1.2.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value is no longer exported since version 1.2.0<br/> <br/> Replaced by: `tileRect`

<a id="ldtk-FieldDefJson" name="ldtk-FieldDefJson"></a>
## 3.2.1. Field definition  ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg) 
This section is mostly only intended for the LDtk editor app itself. You can safely ignore it.

Value | Type | Description
-- | -- | --
`__type`<br/><sup class="internal">*Only used by editor*</sup> | String | Human readable value type. Possible values: `Int, Float, String, Bool, Color, ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>		If the field is an array, this field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>		NOTE: if you enable the advanced option **Use Multilines type**, you will have "*Multilines*" instead of "*String*" when relevant.
`acceptFileTypes`<br/><sup class="only">Only *FilePath*</sup><br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional list of accepted file extensions for FilePath value type. Includes the dot: `.ext`
`arrayMaxLength`<br/><sup class="only">Only *Array*</sup><br/><sup class="internal">*Only used by editor*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Array max length
`arrayMinLength`<br/><sup class="only">Only *Array*</sup><br/><sup class="internal">*Only used by editor*</sup> | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Array min length
`canBeNull`<br/><sup class="internal">*Only used by editor*</sup> | Bool | TRUE if the value can be null. For arrays, TRUE means it can contain null values (exception: array of Points can't have null values).
`defaultOverride`<br/><sup class="internal">*Only used by editor*</sup> | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | Default value if selected value is null or invalid.
`doc`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.2.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | User defined documentation for this field to provide help/tips to level designers about accepted values.
`identifier`<br/><sup class="internal">*Only used by editor*</sup> | String | User defined unique identifier
`isArray`<br/><sup class="internal">*Only used by editor*</sup> | Bool | TRUE if the value is an array of multiple values
`max`<br/><sup class="only">Only *Int, Float*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float&nbsp;*(can&nbsp;be&nbsp;`null`)* | Max limit for value, if applicable
`min`<br/><sup class="only">Only *Int, Float*</sup><br/><sup class="internal">*Only used by editor*</sup> | Float&nbsp;*(can&nbsp;be&nbsp;`null`)* | Min limit for value, if applicable
`regex`<br/><sup class="only">Only *String*</sup><br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.2-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional regular expression that needs to be matched to accept values. Expected format: `/some_reg_ex/g`, with optional "i" flag.
`type`<br/><sup class="internal">*Only used by editor*</sup> | String | Internal enum representing the possible field types. Possible values: F_Int, F_Float, F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
`uid`<br/><sup class="internal">*Only used by editor*</sup> | Int | Unique Int identifier
`allowOutOfLevelRef`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | 
`allowedRefTags`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;String | 
`allowedRefs`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Enum | Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`
`allowedRefsEntityUid`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`autoChainRef`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | 
`editorAlwaysShow`<br/><sup class="internal">*Only used by editor*</sup> | Bool | 
`editorCutLongValues`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.8.0-gray.svg)  | Bool | 
`editorDisplayMode`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.0.0-gray.svg)  | Enum | Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`, `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`, `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`, `RefLinkBetweenCenters`
`editorDisplayPos`<br/><sup class="internal">*Only used by editor*</sup> | Enum | Possible values: `Above`, `Center`, `Beneath`
`editorDisplayScale`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_1.3.0-green.svg)  | Float | 
`editorLinkStyle`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.1.4-gray.svg)  | Enum | Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
`editorShowInWorld`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.1.4-gray.svg)  | Bool | 
`editorTextPrefix`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`editorTextSuffix`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | 
`symmetricalRef`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | 
`textLanguageMode`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Changed_0.9.3-gray.svg)  | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`, `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
`tilesetUid`<br/><sup class="only">Only *Tile*</sup><br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | UID of the tileset used for a Tile
`useForSmartColor`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Bool | If TRUE, the color associated with this field will override the Entity or Level default color in the editor UI. For Enum fields, this would be the color associated to their values.

<a id="ldtk-TilesetDefJson" name="ldtk-TilesetDefJson"></a>
## 3.3. Tileset definition   
The `Tileset` definition is the most important part among project definitions. It contains some extra informations about each integrated tileset. If you only had to parse one definition section, that would be the one.

Value | Type | Description
-- | -- | --
`__cHei`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Int | Grid-based height
`__cWid`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Int | Grid-based width
`customData`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Array&nbsp;of&nbsp;Object | An array of custom tile metadata<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`data`** **(String**)</li><li>**`tileId`** **(Int**)</li></ul>
`embedAtlas`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Enum&nbsp;*(can&nbsp;be&nbsp;`null`)* | If this value is set, then it means that this atlas uses an internal LDtk atlas image instead of a loaded one.<br/> Possible values: &lt;`null`&gt;, `LdtkIcons`
`enumTags`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Array&nbsp;of&nbsp;Object | Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1 element per Enum value, which contains an array of all Tile IDs that are tagged with it.<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`enumValueId`** **(String**)</li><li>**`tileIds`** **(Array of Int**)</li></ul>
`identifier` | String | User defined unique identifier
`padding` | Int | Distance in pixels from image borders
`pxHei` | Int | Image height in pixels
`pxWid` | Int | Image width in pixels
`relPath` | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Path to the source file, relative to the current project JSON file<br/>		It can be null if no image was provided, or when using an embed atlas.
`spacing` | Int | Space in pixels between all tiles
`tags`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;String | An array of user-defined tags to organize the Tilesets
`tagsSourceEnumUid`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional Enum definition UID used for this tileset meta-data
`tileGridSize` | Int | 
`uid` | Int | Unique Intidentifier
`cachedPixelData`<br/><sup class="internal">*Only used by editor*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  | Object&nbsp;*(can&nbsp;be&nbsp;`null`)* | The following data is used internally for various optimizations. It's always synced with source image changes.<br/> This object contains the following fields:<br/> <ul class='subFields'><li>**`averageColors`** **(String *(can be `null`)***)  ![Generic badge](https://img.shields.io/badge/Added_0.6.0-gray.svg)  : *Average color codes for each tileset tile (ARGB format)*</li><li>**`opaqueTiles`** **(String**)  ![Generic badge](https://img.shields.io/badge/Changed_0.6.0-gray.svg)  : *An array of 0/1 bytes, encoded in Base64, that tells if a specific TileID is fully opaque (1) or not (0)*</li></ul>
`savedSelections`<br/><sup class="internal">*Only used by editor*</sup> | Array&nbsp;of&nbsp;Object | Array of group of tiles selections, only meant to be used in the editor<br/> This array contains objects with the following fields:<br/> <ul class='subFields'><li>**`ids`** **(Array of Int**)</li><li>**`mode`** **(Enum**)</li></ul>

<a id="ldtk-TilesetRect" name="ldtk-TilesetRect"></a>
## 3.3.1. Tileset rectangle  ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg) 
This object represents a custom sub rectangle in a Tileset image.

Value | Type | Description
-- | -- | --
`h`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Height in pixels
`tilesetUid`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | UID of the tileset
`w`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Width in pixels
`x`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | X pixels coordinate of the top-left corner in the Tileset image
`y`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Int | Y pixels coordinate of the top-left corner in the Tileset image

<a id="ldtk-EnumDefJson" name="ldtk-EnumDefJson"></a>
## 3.4. Enum definition   
Value | Type | Description
-- | -- | --
`externalRelPath` | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | Relative path to the external file providing this Enum
`iconTilesetUid` | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | Tileset UID if provided
`identifier` | String | User defined unique identifier
`tags`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.0.0-gray.svg)  | Array&nbsp;of&nbsp;String | An array of user-defined tags to organize the Enums
`uid` | Int | Unique Int identifier
`values` | Array&nbsp;of&nbsp;[Enum&nbsp;value&nbsp;definition](#ldtk-EnumDefValues) | All possible enum values, with their optional Tile infos.
`externalFileChecksum`<br/><sup class="internal">*Only used by editor*</sup> | String&nbsp;*(can&nbsp;be&nbsp;`null`)* | 

<a id="ldtk-EnumDefValues" name="ldtk-EnumDefValues"></a>
## 3.4.1. Enum value definition   
Value | Type | Description
-- | -- | --
`color`<br/> ![Generic badge](https://img.shields.io/badge/Added_0.9.0-gray.svg)  | Int | Optional color
`id` | String | Enum value
`tileRect`<br/> ![Generic badge](https://img.shields.io/badge/Added_1.3.0-green.svg)  | [Tileset&nbsp;rectangle](#ldtk-TilesetRect)&nbsp;*(can&nbsp;be&nbsp;`null`)* | Optional tileset rectangle to represents this value
~~`tileId`~~<br/><sup class="deprecated">*DEPRECATED!*</sup><br/>   | Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value will be *removed* completely on version 1.4.0+<br/> <br/> Replaced by: `tileRect`
~~`__tileSrcRect`~~<br/><sup class="deprecated">*DEPRECATED!*</sup><br/> ![Generic badge](https://img.shields.io/badge/Added_0.4.0-gray.svg)  | Array&nbsp;of&nbsp;Int&nbsp;*(can&nbsp;be&nbsp;`null`)* | **WARNING**: this deprecated value will be *removed* completely on version 1.4.0+<br/> <br/> Replaced by: `tileRect`