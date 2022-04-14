// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse and unparse this JSON data, add this code to your project and do:
//
//    ldtkJSON, err := UnmarshalLdtkJSON(bytes)
//    bytes, err = ldtkJSON.Marshal()

package main

import "encoding/json"

func UnmarshalLdtkJSON(data []byte) (LdtkJSON, error) {
	var r LdtkJSON
	err := json.Unmarshal(data, &r)
	return r, err
}

func (r *LdtkJSON) Marshal() ([]byte, error) {
	return json.Marshal(r)
}

// This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).
//
// This is the root of any Project JSON file. It contains:  - the project settings, - an
// array of levels, - a group of definitions (that can probably be safely ignored for most
// users).
type LdtkJSON struct {
	ForcedRefs          *ForcedRefs     `json:"__FORCED_REFS,omitempty"`// This object is not actually used by LDtk. It ONLY exists to force explicit references to; all types, to make sure QuickType finds them and integrate all of them. Otherwise,; Quicktype will drop types that are not explicitely used.
	AppBuildID          float64         `json:"appBuildId"`             // LDtk application build identifier.<br/>  This is only used to identify the LDtk version; that generated this particular project file, which can be useful for specific bug fixing.; Note that the build identifier is just the date of the release, so it's not unique to; each user (one single global ID per LDtk public release), and as a result, completely; anonymous.
	BackupLimit         int64           `json:"backupLimit"`            // Number of backup files to keep, if the `backupOnSave` is TRUE
	BackupOnSave        bool            `json:"backupOnSave"`           // If TRUE, an extra copy of the project will be created in a sub folder, when saving.
	BgColor             string          `json:"bgColor"`                // Project background color
	DefaultGridSize     int64           `json:"defaultGridSize"`        // Default grid size for new layers
	DefaultLevelBgColor string          `json:"defaultLevelBgColor"`    // Default background color of levels
	DefaultLevelHeight  *int64          `json:"defaultLevelHeight"`     // **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.; It will then be `null`. You can enable the Multi-worlds advanced project option to enable; the change immediately.<br/><br/>  Default new level height
	DefaultLevelWidth   *int64          `json:"defaultLevelWidth"`      // **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.; It will then be `null`. You can enable the Multi-worlds advanced project option to enable; the change immediately.<br/><br/>  Default new level width
	DefaultPivotX       float64         `json:"defaultPivotX"`          // Default X pivot (0 to 1) for new entities
	DefaultPivotY       float64         `json:"defaultPivotY"`          // Default Y pivot (0 to 1) for new entities
	Defs                Definitions     `json:"defs"`                   // A structure containing all the definitions of this project
	ExportPNG           *bool           `json:"exportPng"`              // **WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced; by: `imageExportMode`
	ExportTiled         bool            `json:"exportTiled"`            // If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file; (default is FALSE)
	ExternalLevels      bool            `json:"externalLevels"`         // If TRUE, one file will be saved for the project (incl. all its definitions) and one file; in a sub-folder for each level.
	Flags               []Flag          `json:"flags"`                  // An array containing various advanced flags (ie. options or other states). Possible; values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`,; `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`
	IdentifierStyle     IdentifierStyle `json:"identifierStyle"`        // Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible; values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
	ImageExportMode     ImageExportMode `json:"imageExportMode"`        // "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,; `OneImagePerLevel`, `LayersAndLevels`
	JSONVersion         string          `json:"jsonVersion"`            // File format version
	LevelNamePattern    string          `json:"levelNamePattern"`       // The default naming convention for level identifiers.
	Levels              []Level         `json:"levels"`                 // All levels. The order of this array is only relevant in `LinearHorizontal` and; `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should; refer to the `worldX`,`worldY` coordinates of each Level.
	MinifyJSON          bool            `json:"minifyJson"`             // If TRUE, the Json is partially minified (no indentation, nor line breaks, default is; FALSE)
	NextUid             int64           `json:"nextUid"`                // Next Unique integer ID available
	PNGFilePattern      *string         `json:"pngFilePattern"`         // File naming pattern for exported PNGs
	SimplifiedExport    bool            `json:"simplifiedExport"`       // If TRUE, a very simplified will be generated on saving, for quicker & easier engine; integration.
	TutorialDesc        *string         `json:"tutorialDesc"`           // This optional description is used by LDtk Samples to show up some informations and; instructions.
	WorldGridHeight     *int64          `json:"worldGridHeight"`        // **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.; It will then be `null`. You can enable the Multi-worlds advanced project option to enable; the change immediately.<br/><br/>  Height of the world grid in pixels.
	WorldGridWidth      *int64          `json:"worldGridWidth"`         // **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.; It will then be `null`. You can enable the Multi-worlds advanced project option to enable; the change immediately.<br/><br/>  Width of the world grid in pixels.
	WorldLayout         *WorldLayout    `json:"worldLayout"`            // **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.; It will then be `null`. You can enable the Multi-worlds advanced project option to enable; the change immediately.<br/><br/>  An enum that describes how levels are organized in; this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,; `GridVania`, `LinearHorizontal`, `LinearVertical`
	Worlds              []World         `json:"worlds"`                 // This array is not used yet in current LDtk version (so, for now, it's always; empty).<br/><br/>In a later update, it will be possible to have multiple Worlds in a; single project, each containing multiple Levels.<br/><br/>What will change when "Multiple; worlds" support will be added to LDtk:<br/><br/> - in current version, a LDtk project; file can only contain a single world with multiple levels in it. In this case, levels and; world layout related settings are stored in the root of the JSON.<br/> - after the; "Multiple worlds" update, there will be a `worlds` array in root, each world containing; levels and layout settings. Basically, it's pretty much only about moving the `levels`; array to the `worlds` array, along with world layout related values (eg. `worldGridWidth`; etc).<br/><br/>If you want to start supporting this future update easily, please refer to; this documentation: https://github.com/deepnight/ldtk/issues/231
}

// If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
// the `defs` section, as it contains data that are mostly important to the editor. To keep
// you away from the `defs` section and avoid some unnecessary JSON parsing, important data
// from definitions is often duplicated in fields prefixed with a double underscore (eg.
// `__identifier` or `__type`).  The 2 only definition types you might need here are
// **Tilesets** and **Enums**.
//
// A structure containing all the definitions of this project
type Definitions struct {
	Entities      []EntityDefinition  `json:"entities"`     // All entities definitions, including their custom fields
	Enums         []EnumDefinition    `json:"enums"`        // All internal enums
	ExternalEnums []EnumDefinition    `json:"externalEnums"`// Note: external enums are exactly the same as `enums`, except they have a `relPath` to; point to an external source file.
	Layers        []LayerDefinition   `json:"layers"`       // All layer definitions
	LevelFields   []FieldDefinition   `json:"levelFields"`  // All custom fields available to all levels.
	Tilesets      []TilesetDefinition `json:"tilesets"`     // All tilesets
}

type EntityDefinition struct {
	Color            string            `json:"color"`           // Base entity color
	FieldDefs        []FieldDefinition `json:"fieldDefs"`       // Array of field definitions
	FillOpacity      float64           `json:"fillOpacity"`     
	Height           int64             `json:"height"`          // Pixel height
	Hollow           bool              `json:"hollow"`          
	Identifier       string            `json:"identifier"`      // User defined unique identifier
	KeepAspectRatio  bool              `json:"keepAspectRatio"` // Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height; will keep the same aspect ratio as the definition.
	LimitBehavior    LimitBehavior     `json:"limitBehavior"`   // Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
	LimitScope       LimitScope        `json:"limitScope"`      // If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible; values: `PerLayer`, `PerLevel`, `PerWorld`
	LineOpacity      float64           `json:"lineOpacity"`     
	MaxCount         int64             `json:"maxCount"`        // Max instances count
	NineSliceBorders []int64           `json:"nineSliceBorders"`// An array of 4 dimensions for the up/right/down/left borders (in this order) when using; 9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then; this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling
	PivotX           float64           `json:"pivotX"`          // Pivot X coordinate (from 0 to 1.0)
	PivotY           float64           `json:"pivotY"`          // Pivot Y coordinate (from 0 to 1.0)
	RenderMode       RenderMode        `json:"renderMode"`      // Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
	ResizableX       bool              `json:"resizableX"`      // If TRUE, the entity instances will be resizable horizontally
	ResizableY       bool              `json:"resizableY"`      // If TRUE, the entity instances will be resizable vertically
	ShowName         bool              `json:"showName"`        // Display entity name in editor
	Tags             []string          `json:"tags"`            // An array of strings that classifies this entity
	TileID           *int64            `json:"tileId"`          // **WARNING**: this deprecated value will be *removed* completely on version 1.2.0+; Replaced by: `tileRect`
	TileOpacity      float64           `json:"tileOpacity"`     
	TileRect         *TilesetRectangle `json:"tileRect"`        // An object representing a rectangle from an existing Tileset
	TileRenderMode   TileRenderMode    `json:"tileRenderMode"`  // An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible; values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,; `FullSizeUncropped`, `NineSlice`
	TilesetID        *int64            `json:"tilesetId"`       // Tileset ID used for optional tile display
	Uid              int64             `json:"uid"`             // Unique Int identifier
	Width            int64             `json:"width"`           // Pixel width
}

// This section is mostly only intended for the LDtk editor app itself. You can safely
// ignore it.
type FieldDefinition struct {
	Type                string            `json:"__type"`             // Human readable value type. Possible values: `Int, Float, String, Bool, Color,; ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this; field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if; you enable the advanced option **Use Multilines type**, you will have "*Multilines*"; instead of "*String*" when relevant.
	AcceptFileTypes     []string          `json:"acceptFileTypes"`    // Optional list of accepted file extensions for FilePath value type. Includes the dot:; `.ext`
	AllowedRefs         AllowedRefs       `json:"allowedRefs"`        // Possible values: `Any`, `OnlySame`, `OnlyTags`
	AllowedRefTags      []string          `json:"allowedRefTags"`     
	AllowOutOfLevelRef  bool              `json:"allowOutOfLevelRef"` 
	ArrayMaxLength      *int64            `json:"arrayMaxLength"`     // Array max length
	ArrayMinLength      *int64            `json:"arrayMinLength"`     // Array min length
	AutoChainRef        bool              `json:"autoChainRef"`       
	CanBeNull           bool              `json:"canBeNull"`          // TRUE if the value can be null. For arrays, TRUE means it can contain null values; (exception: array of Points can't have null values).
	DefaultOverride     interface{}       `json:"defaultOverride"`    // Default value if selected value is null or invalid.
	EditorAlwaysShow    bool              `json:"editorAlwaysShow"`   
	EditorCutLongValues bool              `json:"editorCutLongValues"`
	EditorDisplayMode   EditorDisplayMode `json:"editorDisplayMode"`  // Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,; `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,; `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,; `RefLinkBetweenCenters`
	EditorDisplayPos    EditorDisplayPos  `json:"editorDisplayPos"`   // Possible values: `Above`, `Center`, `Beneath`
	EditorTextPrefix    *string           `json:"editorTextPrefix"`   
	EditorTextSuffix    *string           `json:"editorTextSuffix"`   
	Identifier          string            `json:"identifier"`         // User defined unique identifier
	IsArray             bool              `json:"isArray"`            // TRUE if the value is an array of multiple values
	Max                 *float64          `json:"max"`                // Max limit for value, if applicable
	Min                 *float64          `json:"min"`                // Min limit for value, if applicable
	Regex               *string           `json:"regex"`              // Optional regular expression that needs to be matched to accept values. Expected format:; `/some_reg_ex/g`, with optional "i" flag.
	SymmetricalRef      bool              `json:"symmetricalRef"`     
	TextLanguageMode    *TextLanguageMode `json:"textLanguageMode"`   // Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,; `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
	TilesetUid          *int64            `json:"tilesetUid"`         // UID of the tileset used for a Tile
	FieldDefinitionType string            `json:"type"`               // Internal enum representing the possible field types. Possible values: F_Int, F_Float,; F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
	Uid                 int64             `json:"uid"`                // Unique Int identifier
	UseForSmartColor    bool              `json:"useForSmartColor"`   // If TRUE, the color associated with this field will override the Entity or Level default; color in the editor UI. For Enum fields, this would be the color associated to their; values.
}

// This object represents a custom sub rectangle in a Tileset image.
type TilesetRectangle struct {
	H          int64 `json:"h"`         // Height in pixels
	TilesetUid int64 `json:"tilesetUid"`// UID of the tileset
	W          int64 `json:"w"`         // Width in pixels
	X          int64 `json:"x"`         // X pixels coordinate of the top-left corner in the Tileset image
	Y          int64 `json:"y"`         // Y pixels coordinate of the top-left corner in the Tileset image
}

type EnumDefinition struct {
	ExternalFileChecksum *string               `json:"externalFileChecksum"`
	ExternalRelPath      *string               `json:"externalRelPath"`     // Relative path to the external file providing this Enum
	IconTilesetUid       *int64                `json:"iconTilesetUid"`      // Tileset UID if provided
	Identifier           string                `json:"identifier"`          // User defined unique identifier
	Tags                 []string              `json:"tags"`                // An array of user-defined tags to organize the Enums
	Uid                  int64                 `json:"uid"`                 // Unique Int identifier
	Values               []EnumValueDefinition `json:"values"`              // All possible enum values, with their optional Tile infos.
}

type EnumValueDefinition struct {
	TileSrcRect []int64 `json:"__tileSrcRect"`// An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width,; height ]`
	Color       int64   `json:"color"`        // Optional color
	ID          string  `json:"id"`           // Enum value
	TileID      *int64  `json:"tileId"`       // The optional ID of the tile
}

type LayerDefinition struct {
	Type                   string                   `json:"__type"`                // Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)
	AutoRuleGroups         []AutoLayerRuleGroup     `json:"autoRuleGroups"`        // Contains all the auto-layer rule definitions.
	AutoSourceLayerDefUid  *int64                   `json:"autoSourceLayerDefUid"` 
	AutoTilesetDefUid      *int64                   `json:"autoTilesetDefUid"`     // **WARNING**: this deprecated value will be *removed* completely on version 1.2.0+; Replaced by: `tilesetDefUid`
	DisplayOpacity         float64                  `json:"displayOpacity"`        // Opacity of the layer (0 to 1.0)
	ExcludedTags           []string                 `json:"excludedTags"`          // An array of tags to forbid some Entities in this layer
	GridSize               int64                    `json:"gridSize"`              // Width and height of the grid in pixels
	GuideGridHei           int64                    `json:"guideGridHei"`          // Height of the optional "guide" grid in pixels
	GuideGridWid           int64                    `json:"guideGridWid"`          // Width of the optional "guide" grid in pixels
	HideFieldsWhenInactive bool                     `json:"hideFieldsWhenInactive"`
	HideInList             bool                     `json:"hideInList"`            // Hide the layer from the list on the side of the editor view.
	Identifier             string                   `json:"identifier"`            // User defined unique identifier
	InactiveOpacity        float64                  `json:"inactiveOpacity"`       // Alpha of this layer when it is not the active one.
	IntGridValues          []IntGridValueDefinition `json:"intGridValues"`         // An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the; array order is not related to actual IntGrid values! As user can re-order IntGrid values; freely, you may value "2" before value "1" in this array.
	ParallaxFactorX        float64                  `json:"parallaxFactorX"`       // Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling; speed of this layer, creating a fake 3D (parallax) effect.
	ParallaxFactorY        float64                  `json:"parallaxFactorY"`       // Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed; of this layer, creating a fake 3D (parallax) effect.
	ParallaxScaling        bool                     `json:"parallaxScaling"`       // If true (default), a layer with a parallax factor will also be scaled up/down accordingly.
	PxOffsetX              int64                    `json:"pxOffsetX"`             // X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`; optional offset)
	PxOffsetY              int64                    `json:"pxOffsetY"`             // Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`; optional offset)
	RequiredTags           []string                 `json:"requiredTags"`          // An array of tags to filter Entities that can be added to this layer
	TilePivotX             float64                  `json:"tilePivotX"`            // If the tiles are smaller or larger than the layer grid, the pivot value will be used to; position the tile relatively its grid cell.
	TilePivotY             float64                  `json:"tilePivotY"`            // If the tiles are smaller or larger than the layer grid, the pivot value will be used to; position the tile relatively its grid cell.
	TilesetDefUid          *int64                   `json:"tilesetDefUid"`         // Reference to the default Tileset UID being used by this layer definition.<br/>; **WARNING**: some layer *instances* might use a different tileset. So most of the time,; you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:; since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
	LayerDefinitionType    Type                     `json:"type"`                  // Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,; `AutoLayer`
	Uid                    int64                    `json:"uid"`                   // Unique Int identifier
}

type AutoLayerRuleGroup struct {
	Active     bool                      `json:"active"`    
	Collapsed  *bool                     `json:"collapsed"` // *This field was removed in 1.0.0 and should no longer be used.*
	IsOptional bool                      `json:"isOptional"`
	Name       string                    `json:"name"`      
	Rules      []AutoLayerRuleDefinition `json:"rules"`     
	Uid        int64                     `json:"uid"`       
}

// This complex section isn't meant to be used by game devs at all, as these rules are
// completely resolved internally by the editor before any saving. You should just ignore
// this part.
type AutoLayerRuleDefinition struct {
	Active           bool     `json:"active"`          // If FALSE, the rule effect isn't applied, and no tiles are generated.
	BreakOnMatch     bool     `json:"breakOnMatch"`    // When TRUE, the rule will prevent other rules to be applied in the same cell if it matches; (TRUE by default).
	Chance           float64  `json:"chance"`          // Chances for this rule to be applied (0 to 1)
	Checker          Checker  `json:"checker"`         // Checker mode Possible values: `None`, `Horizontal`, `Vertical`
	FlipX            bool     `json:"flipX"`           // If TRUE, allow rule to be matched by flipping its pattern horizontally
	FlipY            bool     `json:"flipY"`           // If TRUE, allow rule to be matched by flipping its pattern vertically
	OutOfBoundsValue *int64   `json:"outOfBoundsValue"`// Default IntGrid value when checking cells outside of level bounds
	Pattern          []int64  `json:"pattern"`         // Rule pattern (size x size)
	PerlinActive     bool     `json:"perlinActive"`    // If TRUE, enable Perlin filtering to only apply rule on specific random area
	PerlinOctaves    float64  `json:"perlinOctaves"`   
	PerlinScale      float64  `json:"perlinScale"`     
	PerlinSeed       float64  `json:"perlinSeed"`      
	PivotX           float64  `json:"pivotX"`          // X pivot of a tile stamp (0-1)
	PivotY           float64  `json:"pivotY"`          // Y pivot of a tile stamp (0-1)
	Size             int64    `json:"size"`            // Pattern width & height. Should only be 1,3,5 or 7.
	TileIDS          []int64  `json:"tileIds"`         // Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.
	TileMode         TileMode `json:"tileMode"`        // Defines how tileIds array is used Possible values: `Single`, `Stamp`
	Uid              int64    `json:"uid"`             // Unique Int identifier
	XModulo          int64    `json:"xModulo"`         // X cell coord modulo
	XOffset          int64    `json:"xOffset"`         // X cell start offset
	YModulo          int64    `json:"yModulo"`         // Y cell coord modulo
	YOffset          int64    `json:"yOffset"`         // Y cell start offset
}

// IntGrid value definition
type IntGridValueDefinition struct {
	Color      string  `json:"color"`     
	Identifier *string `json:"identifier"`// User defined unique identifier
	Value      int64   `json:"value"`     // The IntGrid value itself
}

// The `Tileset` definition is the most important part among project definitions. It
// contains some extra informations about each integrated tileset. If you only had to parse
// one definition section, that would be the one.
type TilesetDefinition struct {
	CHei              int64                    `json:"__cHei"`           // Grid-based height
	CWid              int64                    `json:"__cWid"`           // Grid-based width
	CachedPixelData   map[string]interface{}   `json:"cachedPixelData"`  // The following data is used internally for various optimizations. It's always synced with; source image changes.
	CustomData        []TileCustomMetadata     `json:"customData"`       // An array of custom tile metadata
	EmbedAtlas        *EmbedAtlas              `json:"embedAtlas"`       // If this value is set, then it means that this atlas uses an internal LDtk atlas image; instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`
	EnumTags          []EnumTagValue           `json:"enumTags"`         // Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1; element per Enum value, which contains an array of all Tile IDs that are tagged with it.
	Identifier        string                   `json:"identifier"`       // User defined unique identifier
	Padding           int64                    `json:"padding"`          // Distance in pixels from image borders
	PxHei             int64                    `json:"pxHei"`            // Image height in pixels
	PxWid             int64                    `json:"pxWid"`            // Image width in pixels
	RelPath           *string                  `json:"relPath"`          // Path to the source file, relative to the current project JSON file<br/>  It can be null; if no image was provided, or when using an embed atlas.
	SavedSelections   []map[string]interface{} `json:"savedSelections"`  // Array of group of tiles selections, only meant to be used in the editor
	Spacing           int64                    `json:"spacing"`          // Space in pixels between all tiles
	Tags              []string                 `json:"tags"`             // An array of user-defined tags to organize the Tilesets
	TagsSourceEnumUid *int64                   `json:"tagsSourceEnumUid"`// Optional Enum definition UID used for this tileset meta-data
	TileGridSize      int64                    `json:"tileGridSize"`     
	Uid               int64                    `json:"uid"`              // Unique Intidentifier
}

// In a tileset definition, user defined meta-data of a tile.
type TileCustomMetadata struct {
	Data   string `json:"data"`  
	TileID int64  `json:"tileId"`
}

// In a tileset definition, enum based tag infos
type EnumTagValue struct {
	EnumValueID string  `json:"enumValueId"`
	TileIDS     []int64 `json:"tileIds"`    
}

// This object is not actually used by LDtk. It ONLY exists to force explicit references to
// all types, to make sure QuickType finds them and integrate all of them. Otherwise,
// Quicktype will drop types that are not explicitely used.
type ForcedRefs struct {
	AutoLayerRuleGroup   *AutoLayerRuleGroup           `json:"AutoLayerRuleGroup,omitempty"`  
	AutoRuleDef          *AutoLayerRuleDefinition      `json:"AutoRuleDef,omitempty"`         
	Definitions          *Definitions                  `json:"Definitions,omitempty"`         
	EntityDef            *EntityDefinition             `json:"EntityDef,omitempty"`           
	EntityInstance       *EntityInstance               `json:"EntityInstance,omitempty"`      
	EntityReferenceInfos *FieldInstanceEntityReference `json:"EntityReferenceInfos,omitempty"`
	EnumDef              *EnumDefinition               `json:"EnumDef,omitempty"`             
	EnumDefValues        *EnumValueDefinition          `json:"EnumDefValues,omitempty"`       
	EnumTagValue         *EnumTagValue                 `json:"EnumTagValue,omitempty"`        
	FieldDef             *FieldDefinition              `json:"FieldDef,omitempty"`            
	FieldInstance        *FieldInstance                `json:"FieldInstance,omitempty"`       
	GridPoint            *FieldInstanceGridPoint       `json:"GridPoint,omitempty"`           
	IntGridValueDef      *IntGridValueDefinition       `json:"IntGridValueDef,omitempty"`     
	IntGridValueInstance *IntGridValueInstance         `json:"IntGridValueInstance,omitempty"`
	LayerDef             *LayerDefinition              `json:"LayerDef,omitempty"`            
	LayerInstance        *LayerInstance                `json:"LayerInstance,omitempty"`       
	Level                *Level                        `json:"Level,omitempty"`               
	LevelBgPosInfos      *LevelBackgroundPosition      `json:"LevelBgPosInfos,omitempty"`     
	NeighbourLevel       *NeighbourLevel               `json:"NeighbourLevel,omitempty"`      
	Tile                 *TileInstance                 `json:"Tile,omitempty"`                
	TileCustomMetadata   *TileCustomMetadata           `json:"TileCustomMetadata,omitempty"`  
	TilesetDef           *TilesetDefinition            `json:"TilesetDef,omitempty"`          
	TilesetRect          *TilesetRectangle             `json:"TilesetRect,omitempty"`         
	World                *World                        `json:"World,omitempty"`               
}

type EntityInstance struct {
	Grid           []int64           `json:"__grid"`        // Grid-based coordinates (`[x,y]` format)
	Identifier     string            `json:"__identifier"`  // Entity definition identifier
	Pivot          []float64         `json:"__pivot"`       // Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity
	SmartColor     string            `json:"__smartColor"`  // The entity "smart" color, guessed from either Entity definition, or one its field; instances.
	Tags           []string          `json:"__tags"`        // Array of tags defined in this Entity definition
	Tile           *TilesetRectangle `json:"__tile"`        // Optional TilesetRect used to display this entity (it could either be the default Entity; tile, or some tile provided by a field value, like an Enum).
	DefUid         int64             `json:"defUid"`        // Reference of the **Entity definition** UID
	FieldInstances []FieldInstance   `json:"fieldInstances"`// An array of all custom fields and their values.
	Height         int64             `json:"height"`        // Entity height in pixels. For non-resizable entities, it will be the same as Entity; definition.
	Iid            string            `json:"iid"`           // Unique instance identifier
	Px             []int64           `json:"px"`            // Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget; optional layer offsets, if they exist!
	Width          int64             `json:"width"`         // Entity width in pixels. For non-resizable entities, it will be the same as Entity; definition.
}

type FieldInstance struct {
	Identifier       string            `json:"__identifier"`    // Field definition identifier
	Tile             *TilesetRectangle `json:"__tile"`          // Optional TilesetRect used to display this field (this can be the field own Tile, or some; other Tile guessed from the value, like an Enum).
	Type             string            `json:"__type"`          // Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,; etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have; "*Multilines*" instead of "*String*" when relevant.
	Value            interface{}       `json:"__value"`         // Actual value of the field instance. The value type varies, depending on `__type`:<br/>; - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you; just get the actual value with the expected type.<br/>   - For **Color**, the value is an; hexadecimal string using "#rrggbb" format.<br/>   - For **Enum**, the value is a String; representing the selected enum value.<br/>   - For **Point**, the value is a; [GridPoint](#ldtk-GridPoint) object.<br/>   - For **Tile**, the value is a; [TilesetRect](#ldtk-TilesetRect) object.<br/>   - For **EntityRef**, the value is an; [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>  If the field is an; array, then this `__value` will also be a JSON array.
	DefUid           int64             `json:"defUid"`          // Reference of the **Field definition** UID
	RealEditorValues []interface{}     `json:"realEditorValues"`// Editor internal raw values
}

// This object is used in Field Instances to describe an EntityRef value.
type FieldInstanceEntityReference struct {
	EntityIid string `json:"entityIid"`// IID of the refered EntityInstance
	LayerIid  string `json:"layerIid"` // IID of the LayerInstance containing the refered EntityInstance
	LevelIid  string `json:"levelIid"` // IID of the Level containing the refered EntityInstance
	WorldIid  string `json:"worldIid"` // IID of the World containing the refered EntityInstance
}

// This object is just a grid-based coordinate used in Field values.
type FieldInstanceGridPoint struct {
	Cx int64 `json:"cx"`// X grid-based coordinate
	Cy int64 `json:"cy"`// Y grid-based coordinate
}

// IntGrid value instance
type IntGridValueInstance struct {
	CoordID int64 `json:"coordId"`// Coordinate ID in the layer grid
	V       int64 `json:"v"`      // IntGrid value
}

type LayerInstance struct {
	CHei               int64                  `json:"__cHei"`            // Grid-based height
	CWid               int64                  `json:"__cWid"`            // Grid-based width
	GridSize           int64                  `json:"__gridSize"`        // Grid size
	Identifier         string                 `json:"__identifier"`      // Layer definition identifier
	Opacity            float64                `json:"__opacity"`         // Layer opacity as Float [0-1]
	PxTotalOffsetX     int64                  `json:"__pxTotalOffsetX"`  // Total layer X pixel offset, including both instance and definition offsets.
	PxTotalOffsetY     int64                  `json:"__pxTotalOffsetY"`  // Total layer Y pixel offset, including both instance and definition offsets.
	TilesetDefUid      *int64                 `json:"__tilesetDefUid"`   // The definition UID of corresponding Tileset, if any.
	TilesetRelPath     *string                `json:"__tilesetRelPath"`  // The relative path to corresponding Tileset, if any.
	Type               string                 `json:"__type"`            // Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
	AutoLayerTiles     []TileInstance         `json:"autoLayerTiles"`    // An array containing all tiles generated by Auto-layer rules. The array is already sorted; in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>; Note: if multiple tiles are stacked in the same cell as the result of different rules,; all tiles behind opaque ones will be discarded.
	EntityInstances    []EntityInstance       `json:"entityInstances"`   
	GridTiles          []TileInstance         `json:"gridTiles"`         
	Iid                string                 `json:"iid"`               // Unique layer instance identifier
	IntGrid            []IntGridValueInstance `json:"intGrid"`           // **WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced; by: `intGridCsv`
	IntGridCSV         []int64                `json:"intGridCsv"`        // A list of all values in the IntGrid layer, stored in CSV format (Comma Separated; Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to; right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values; start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.
	LayerDefUid        int64                  `json:"layerDefUid"`       // Reference the Layer definition UID
	LevelID            int64                  `json:"levelId"`           // Reference to the UID of the level containing this layer instance
	OptionalRules      []int64                `json:"optionalRules"`     // An Array containing the UIDs of optional rules that were enabled in this specific layer; instance.
	OverrideTilesetUid *int64                 `json:"overrideTilesetUid"`// This layer can use another tileset by overriding the tileset UID here.
	PxOffsetX          int64                  `json:"pxOffsetX"`         // X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to; the `LayerDef` optional offset, see `__pxTotalOffsetX`)
	PxOffsetY          int64                  `json:"pxOffsetY"`         // Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to; the `LayerDef` optional offset, see `__pxTotalOffsetY`)
	Seed               int64                  `json:"seed"`              // Random seed used for Auto-Layers rendering
	Visible            bool                   `json:"visible"`           // Layer instance visibility
}

// This structure represents a single tile from a given Tileset.
type TileInstance struct {
	D   []int64 `json:"d"`  // Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>; For tile-layer tiles: `[coordId]`.
	F   int64   `json:"f"`  // "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>; - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip; only), f=2 (Y flip only), f=3 (both flips)
	Px  []int64 `json:"px"` // Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional; layer offsets, if they exist!
	Src []int64 `json:"src"`// Pixel coordinates of the tile in the **tileset** (`[x,y]` format)
	T   int64   `json:"t"`  // The *Tile ID* in the corresponding tileset.
}

// This section contains all the level data. It can be found in 2 distinct forms, depending
// on Project current settings:  - If "*Separate level files*" is **disabled** (default):
// full level data is *embedded* inside the main Project JSON file, - If "*Separate level
// files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one
// per level). In this case, the main Project JSON file will still contain most level data,
// except heavy sections, like the `layerInstances` array (which will be null). The
// `externalRelPath` string points to the `ldtkl` file.  A `ldtkl` file is just a JSON file
// containing exactly what is described below.
type Level struct {
	BgColor           string                   `json:"__bgColor"`        // Background color of the level (same as `bgColor`, except the default value is; automatically used here if its value is `null`)
	BgPos             *LevelBackgroundPosition `json:"__bgPos"`          // Position informations of the background image, if there is one.
	Neighbours        []NeighbourLevel         `json:"__neighbours"`     // An array listing all other levels touching this one on the world map.<br/>  Only relevant; for world layouts where level spatial positioning is manual (ie. GridVania, Free). For; Horizontal and Vertical layouts, this array is always empty.
	SmartColor        string                   `json:"__smartColor"`     // The "guessed" color for this level in the editor, decided using either the background; color or an existing custom field.
	LevelBgColor      *string                  `json:"bgColor"`          // Background color of the level. If `null`, the project `defaultLevelBgColor` should be; used.
	BgPivotX          float64                  `json:"bgPivotX"`         // Background image X pivot (0-1)
	BgPivotY          float64                  `json:"bgPivotY"`         // Background image Y pivot (0-1)
	LevelBgPos        *BgPos                   `json:"bgPos"`            // An enum defining the way the background image (if any) is positioned on the level. See; `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,; `Contain`, `Cover`, `CoverDirty`
	BgRelPath         *string                  `json:"bgRelPath"`        // The *optional* relative path to the level background image.
	ExternalRelPath   *string                  `json:"externalRelPath"`  // This value is not null if the project option "*Save levels separately*" is enabled. In; this case, this **relative** path points to the level Json file.
	FieldInstances    []FieldInstance          `json:"fieldInstances"`   // An array containing this level custom field values.
	Identifier        string                   `json:"identifier"`       // User defined unique identifier
	Iid               string                   `json:"iid"`              // Unique instance identifier
	LayerInstances    []LayerInstance          `json:"layerInstances"`   // An array containing all Layer instances. **IMPORTANT**: if the project option "*Save; levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted; in display order**: the 1st layer is the top-most and the last is behind.
	PxHei             int64                    `json:"pxHei"`            // Height of the level in pixels
	PxWid             int64                    `json:"pxWid"`            // Width of the level in pixels
	Uid               int64                    `json:"uid"`              // Unique Int identifier
	UseAutoIdentifier bool                     `json:"useAutoIdentifier"`// If TRUE, the level identifier will always automatically use the naming pattern as defined; in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by; user.
	WorldDepth        int64                    `json:"worldDepth"`       // Index that represents the "depth" of the level in the world. Default is 0, greater means; "above", lower means "below".<br/>  This value is mostly used for display only and is; intended to make stacking of levels easier to manage.
	WorldX            int64                    `json:"worldX"`           // World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial; positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the; value is always -1 here.
	WorldY            int64                    `json:"worldY"`           // World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial; positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the; value is always -1 here.
}

// Level background image position info
type LevelBackgroundPosition struct {
	CropRect  []float64 `json:"cropRect"` // An array of 4 float values describing the cropped sub-rectangle of the displayed; background image. This cropping happens when original is larger than the level bounds.; Array format: `[ cropX, cropY, cropWidth, cropHeight ]`
	Scale     []float64 `json:"scale"`    // An array containing the `[scaleX,scaleY]` values of the **cropped** background image,; depending on `bgPos` option.
	TopLeftPx []int64   `json:"topLeftPx"`// An array containing the `[x,y]` pixel coordinates of the top-left corner of the; **cropped** background image, depending on `bgPos` option.
}

// Nearby level info
type NeighbourLevel struct {
	Dir      string `json:"dir"`               // A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,; `e`ast).
	LevelIid string `json:"levelIid"`          // Neighbour Instance Identifier
	LevelUid *int64 `json:"levelUid,omitempty"`// **WARNING**: this deprecated value will be *removed* completely on version 1.2.0+; Replaced by: `levelIid`
}

// **IMPORTANT**: this type is not used *yet* in current LDtk version. It's only presented
// here as a preview of a planned feature.  A World contains multiple levels, and it has its
// own layout settings.
type World struct {
	DefaultLevelHeight int64        `json:"defaultLevelHeight"`// Default new level height
	DefaultLevelWidth  int64        `json:"defaultLevelWidth"` // Default new level width
	Identifier         string       `json:"identifier"`        // User defined unique identifier
	Iid                string       `json:"iid"`               // Unique instance identifer
	Levels             []Level      `json:"levels"`            // All levels from this world. The order of this array is only relevant in; `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).; Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
	WorldGridHeight    int64        `json:"worldGridHeight"`   // Height of the world grid in pixels.
	WorldGridWidth     int64        `json:"worldGridWidth"`    // Width of the world grid in pixels.
	WorldLayout        *WorldLayout `json:"worldLayout"`       // An enum that describes how levels are organized in this project (ie. linearly or in a 2D; space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`
}

// Possible values: `Any`, `OnlySame`, `OnlyTags`
type AllowedRefs string
const (
	Any AllowedRefs = "Any"
	OnlySame AllowedRefs = "OnlySame"
	OnlyTags AllowedRefs = "OnlyTags"
)

// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,
// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
// `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
// `RefLinkBetweenCenters`
type EditorDisplayMode string
const (
	ArrayCountNoLabel EditorDisplayMode = "ArrayCountNoLabel"
	ArrayCountWithLabel EditorDisplayMode = "ArrayCountWithLabel"
	EntityTile EditorDisplayMode = "EntityTile"
	Hidden EditorDisplayMode = "Hidden"
	NameAndValue EditorDisplayMode = "NameAndValue"
	PointPath EditorDisplayMode = "PointPath"
	PointPathLoop EditorDisplayMode = "PointPathLoop"
	PointStar EditorDisplayMode = "PointStar"
	Points EditorDisplayMode = "Points"
	RadiusGrid EditorDisplayMode = "RadiusGrid"
	RadiusPx EditorDisplayMode = "RadiusPx"
	RefLinkBetweenCenters EditorDisplayMode = "RefLinkBetweenCenters"
	RefLinkBetweenPivots EditorDisplayMode = "RefLinkBetweenPivots"
	ValueOnly EditorDisplayMode = "ValueOnly"
)

// Possible values: `Above`, `Center`, `Beneath`
type EditorDisplayPos string
const (
	Above EditorDisplayPos = "Above"
	Beneath EditorDisplayPos = "Beneath"
	Center EditorDisplayPos = "Center"
)

type TextLanguageMode string
const (
	LangC TextLanguageMode = "LangC"
	LangHaxe TextLanguageMode = "LangHaxe"
	LangJS TextLanguageMode = "LangJS"
	LangJSON TextLanguageMode = "LangJson"
	LangLog TextLanguageMode = "LangLog"
	LangLua TextLanguageMode = "LangLua"
	LangMarkdown TextLanguageMode = "LangMarkdown"
	LangPython TextLanguageMode = "LangPython"
	LangRuby TextLanguageMode = "LangRuby"
	LangXML TextLanguageMode = "LangXml"
)

// Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
type LimitBehavior string
const (
	DiscardOldOnes LimitBehavior = "DiscardOldOnes"
	MoveLastOne LimitBehavior = "MoveLastOne"
	PreventAdding LimitBehavior = "PreventAdding"
)

// If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
// values: `PerLayer`, `PerLevel`, `PerWorld`
type LimitScope string
const (
	PerLayer LimitScope = "PerLayer"
	PerLevel LimitScope = "PerLevel"
	PerWorld LimitScope = "PerWorld"
)

// Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
type RenderMode string
const (
	Cross RenderMode = "Cross"
	Ellipse RenderMode = "Ellipse"
	Rectangle RenderMode = "Rectangle"
	Tile RenderMode = "Tile"
)

// An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
// values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
// `FullSizeUncropped`, `NineSlice`
type TileRenderMode string
const (
	FitInside TileRenderMode = "FitInside"
	FullSizeCropped TileRenderMode = "FullSizeCropped"
	FullSizeUncropped TileRenderMode = "FullSizeUncropped"
	NineSlice TileRenderMode = "NineSlice"
	Repeat TileRenderMode = "Repeat"
	Stretch TileRenderMode = "Stretch"
	TileRenderModeCover TileRenderMode = "Cover"
)

// Checker mode Possible values: `None`, `Horizontal`, `Vertical`
type Checker string
const (
	CheckerNone Checker = "None"
	Horizontal Checker = "Horizontal"
	Vertical Checker = "Vertical"
)

// Defines how tileIds array is used Possible values: `Single`, `Stamp`
type TileMode string
const (
	Single TileMode = "Single"
	Stamp TileMode = "Stamp"
)

// Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
// `AutoLayer`
type Type string
const (
	AutoLayer Type = "AutoLayer"
	Entities Type = "Entities"
	IntGrid Type = "IntGrid"
	Tiles Type = "Tiles"
)

type EmbedAtlas string
const (
	LdtkIcons EmbedAtlas = "LdtkIcons"
)

type Flag string
const (
	DiscardPreCSVIntGrid Flag = "DiscardPreCsvIntGrid"
	ExportPreCSVIntGridFormat Flag = "ExportPreCsvIntGridFormat"
	IgnoreBackupSuggest Flag = "IgnoreBackupSuggest"
	MultiWorlds Flag = "MultiWorlds"
	PrependIndexToLevelFileNames Flag = "PrependIndexToLevelFileNames"
	UseMultilinesType Flag = "UseMultilinesType"
)

type BgPos string
const (
	BgPosCover BgPos = "Cover"
	Contain BgPos = "Contain"
	CoverDirty BgPos = "CoverDirty"
	Unscaled BgPos = "Unscaled"
)

type WorldLayout string
const (
	GridVania WorldLayout = "GridVania"
	LinearHorizontal WorldLayout = "LinearHorizontal"
	LinearVertical WorldLayout = "LinearVertical"
	WorldLayoutFree WorldLayout = "Free"
)

// Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
// values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
type IdentifierStyle string
const (
	Capitalize IdentifierStyle = "Capitalize"
	IdentifierStyleFree IdentifierStyle = "Free"
	Lowercase IdentifierStyle = "Lowercase"
	Uppercase IdentifierStyle = "Uppercase"
)

// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
// `OneImagePerLevel`, `LayersAndLevels`
type ImageExportMode string
const (
	ImageExportModeNone ImageExportMode = "None"
	LayersAndLevels ImageExportMode = "LayersAndLevels"
	OneImagePerLayer ImageExportMode = "OneImagePerLayer"
	OneImagePerLevel ImageExportMode = "OneImagePerLevel"
)
