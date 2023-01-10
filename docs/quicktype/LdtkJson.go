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
	// This object is not actually used by LDtk. It ONLY exists to force explicit references to                           
	// all types, to make sure QuickType finds them and integrate all of them. Otherwise,                                 
	// Quicktype will drop types that are not explicitely used.                                                           
	ForcedRefs                                                                                  *ForcedRefs               `json:"__FORCED_REFS,omitempty"`
	// LDtk application build identifier.<br/>  This is only used to identify the LDtk version                            
	// that generated this particular project file, which can be useful for specific bug fixing.                          
	// Note that the build identifier is just the date of the release, so it's not unique to                              
	// each user (one single global ID per LDtk public release), and as a result, completely                              
	// anonymous.                                                                                                         
	AppBuildID                                                                                  float64                   `json:"appBuildId"`
	// Number of backup files to keep, if the `backupOnSave` is TRUE                                                      
	BackupLimit                                                                                 int64                     `json:"backupLimit"`
	// If TRUE, an extra copy of the project will be created in a sub folder, when saving.                                
	BackupOnSave                                                                                bool                      `json:"backupOnSave"`
	// Project background color                                                                                           
	BgColor                                                                                     string                    `json:"bgColor"`
	// An array of command lines that can be ran manually by the user                                                     
	CustomCommands                                                                              []LdtkCustomCommand       `json:"customCommands"`
	// Default grid size for new layers                                                                                   
	DefaultGridSize                                                                             int64                     `json:"defaultGridSize"`
	// Default background color of levels                                                                                 
	DefaultLevelBgColor                                                                         string                    `json:"defaultLevelBgColor"`
	// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.                           
	// It will then be `null`. You can enable the Multi-worlds advanced project option to enable                          
	// the change immediately.<br/><br/>  Default new level height                                                        
	DefaultLevelHeight                                                                          *int64                    `json:"defaultLevelHeight"`
	// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.                           
	// It will then be `null`. You can enable the Multi-worlds advanced project option to enable                          
	// the change immediately.<br/><br/>  Default new level width                                                         
	DefaultLevelWidth                                                                           *int64                    `json:"defaultLevelWidth"`
	// Default X pivot (0 to 1) for new entities                                                                          
	DefaultPivotX                                                                               float64                   `json:"defaultPivotX"`
	// Default Y pivot (0 to 1) for new entities                                                                          
	DefaultPivotY                                                                               float64                   `json:"defaultPivotY"`
	// A structure containing all the definitions of this project                                                         
	Defs                                                                                        Definitions               `json:"defs"`
	// If TRUE, the exported PNGs will include the level background (color or image).                                     
	ExportLevelBg                                                                               bool                      `json:"exportLevelBg"`
	// **WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced                             
	// by: `imageExportMode`                                                                                              
	ExportPNG                                                                                   *bool                     `json:"exportPng"`
	// If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file                              
	// (default is FALSE)                                                                                                 
	ExportTiled                                                                                 bool                      `json:"exportTiled"`
	// If TRUE, one file will be saved for the project (incl. all its definitions) and one file                           
	// in a sub-folder for each level.                                                                                    
	ExternalLevels                                                                              bool                      `json:"externalLevels"`
	// An array containing various advanced flags (ie. options or other states). Possible                                 
	// values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`,                                
	// `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`                                                 
	Flags                                                                                       []Flag                    `json:"flags"`
	// Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible                           
	// values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`                                                             
	IdentifierStyle                                                                             IdentifierStyle           `json:"identifierStyle"`
	// Unique project identifier                                                                                          
	Iid                                                                                         string                    `json:"iid"`
	// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,                            
	// `OneImagePerLevel`, `LayersAndLevels`                                                                              
	ImageExportMode                                                                             ImageExportMode           `json:"imageExportMode"`
	// File format version                                                                                                
	JSONVersion                                                                                 string                    `json:"jsonVersion"`
	// The default naming convention for level identifiers.                                                               
	LevelNamePattern                                                                            string                    `json:"levelNamePattern"`
	// All levels. The order of this array is only relevant in `LinearHorizontal` and                                     
	// `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should                              
	// refer to the `worldX`,`worldY` coordinates of each Level.                                                          
	Levels                                                                                      []Level                   `json:"levels"`
	// If TRUE, the Json is partially minified (no indentation, nor line breaks, default is                               
	// FALSE)                                                                                                             
	MinifyJSON                                                                                  bool                      `json:"minifyJson"`
	// Next Unique integer ID available                                                                                   
	NextUid                                                                                     int64                     `json:"nextUid"`
	// File naming pattern for exported PNGs                                                                              
	PNGFilePattern                                                                              *string                   `json:"pngFilePattern"`
	// If TRUE, a very simplified will be generated on saving, for quicker & easier engine                                
	// integration.                                                                                                       
	SimplifiedExport                                                                            bool                      `json:"simplifiedExport"`
	// All the instances of entities that have their `exportToToc` flag enabled are listed this                           
	// array.                                                                                                             
	Toc                                                                                         []LdtkTableOfContentEntry `json:"toc"`
	// This optional description is used by LDtk Samples to show up some informations and                                 
	// instructions.                                                                                                      
	TutorialDesc                                                                                *string                   `json:"tutorialDesc"`
	// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.                           
	// It will then be `null`. You can enable the Multi-worlds advanced project option to enable                          
	// the change immediately.<br/><br/>  Height of the world grid in pixels.                                             
	WorldGridHeight                                                                             *int64                    `json:"worldGridHeight"`
	// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.                           
	// It will then be `null`. You can enable the Multi-worlds advanced project option to enable                          
	// the change immediately.<br/><br/>  Width of the world grid in pixels.                                              
	WorldGridWidth                                                                              *int64                    `json:"worldGridWidth"`
	// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.                           
	// It will then be `null`. You can enable the Multi-worlds advanced project option to enable                          
	// the change immediately.<br/><br/>  An enum that describes how levels are organized in                              
	// this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,                             
	// `GridVania`, `LinearHorizontal`, `LinearVertical`                                                                  
	WorldLayout                                                                                 *WorldLayout              `json:"worldLayout"`
	// This array is not used yet in current LDtk version (so, for now, it's always                                       
	// empty).<br/><br/>In a later update, it will be possible to have multiple Worlds in a                               
	// single project, each containing multiple Levels.<br/><br/>What will change when "Multiple                          
	// worlds" support will be added to LDtk:<br/><br/> - in current version, a LDtk project                              
	// file can only contain a single world with multiple levels in it. In this case, levels and                          
	// world layout related settings are stored in the root of the JSON.<br/> - after the                                 
	// "Multiple worlds" update, there will be a `worlds` array in root, each world containing                            
	// levels and layout settings. Basically, it's pretty much only about moving the `levels`                             
	// array to the `worlds` array, along with world layout related values (eg. `worldGridWidth`                          
	// etc).<br/><br/>If you want to start supporting this future update easily, please refer to                          
	// this documentation: https://github.com/deepnight/ldtk/issues/231                                                   
	Worlds                                                                                      []World                   `json:"worlds"`
}

type LdtkCustomCommand struct {
	Command                                                             string `json:"command"`
	// Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`       
	When                                                                When   `json:"when"`
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
	// All entities definitions, including their custom fields                                                  
	Entities                                                                                []EntityDefinition  `json:"entities"`
	// All internal enums                                                                                       
	Enums                                                                                   []EnumDefinition    `json:"enums"`
	// Note: external enums are exactly the same as `enums`, except they have a `relPath` to                    
	// point to an external source file.                                                                        
	ExternalEnums                                                                           []EnumDefinition    `json:"externalEnums"`
	// All layer definitions                                                                                    
	Layers                                                                                  []LayerDefinition   `json:"layers"`
	// All custom fields available to all levels.                                                               
	LevelFields                                                                             []FieldDefinition   `json:"levelFields"`
	// All tilesets                                                                                             
	Tilesets                                                                                []TilesetDefinition `json:"tilesets"`
}

type EntityDefinition struct {
	// Base entity color                                                                                          
	Color                                                                                       string            `json:"color"`
	// If enabled, all instances of this entity will be listed in the project "Table of content"                  
	// object.                                                                                                    
	ExportToToc                                                                                 bool              `json:"exportToToc"`
	// Array of field definitions                                                                                 
	FieldDefs                                                                                   []FieldDefinition `json:"fieldDefs"`
	FillOpacity                                                                                 float64           `json:"fillOpacity"`
	// Pixel height                                                                                               
	Height                                                                                      int64             `json:"height"`
	Hollow                                                                                      bool              `json:"hollow"`
	// User defined unique identifier                                                                             
	Identifier                                                                                  string            `json:"identifier"`
	// Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height                  
	// will keep the same aspect ratio as the definition.                                                         
	KeepAspectRatio                                                                             bool              `json:"keepAspectRatio"`
	// Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`                                          
	LimitBehavior                                                                               LimitBehavior     `json:"limitBehavior"`
	// If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible                       
	// values: `PerLayer`, `PerLevel`, `PerWorld`                                                                 
	LimitScope                                                                                  LimitScope        `json:"limitScope"`
	LineOpacity                                                                                 float64           `json:"lineOpacity"`
	// Max instances count                                                                                        
	MaxCount                                                                                    int64             `json:"maxCount"`
	// An array of 4 dimensions for the up/right/down/left borders (in this order) when using                     
	// 9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then                      
	// this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling                              
	NineSliceBorders                                                                            []int64           `json:"nineSliceBorders"`
	// Pivot X coordinate (from 0 to 1.0)                                                                         
	PivotX                                                                                      float64           `json:"pivotX"`
	// Pivot Y coordinate (from 0 to 1.0)                                                                         
	PivotY                                                                                      float64           `json:"pivotY"`
	// Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`                                                   
	RenderMode                                                                                  RenderMode        `json:"renderMode"`
	// If TRUE, the entity instances will be resizable horizontally                                               
	ResizableX                                                                                  bool              `json:"resizableX"`
	// If TRUE, the entity instances will be resizable vertically                                                 
	ResizableY                                                                                  bool              `json:"resizableY"`
	// Display entity name in editor                                                                              
	ShowName                                                                                    bool              `json:"showName"`
	// An array of strings that classifies this entity                                                            
	Tags                                                                                        []string          `json:"tags"`
	// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced                     
	// by: `tileRect`                                                                                             
	TileID                                                                                      *int64            `json:"tileId"`
	TileOpacity                                                                                 float64           `json:"tileOpacity"`
	// An object representing a rectangle from an existing Tileset                                                
	TileRect                                                                                    *TilesetRectangle `json:"tileRect"`
	// An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible                  
	// values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,                                      
	// `FullSizeUncropped`, `NineSlice`                                                                           
	TileRenderMode                                                                              TileRenderMode    `json:"tileRenderMode"`
	// Tileset ID used for optional tile display                                                                  
	TilesetID                                                                                   *int64            `json:"tilesetId"`
	// Unique Int identifier                                                                                      
	Uid                                                                                         int64             `json:"uid"`
	// Pixel width                                                                                                
	Width                                                                                       int64             `json:"width"`
}

// This section is mostly only intended for the LDtk editor app itself. You can safely
// ignore it.
type FieldDefinition struct {
	// Human readable value type. Possible values: `Int, Float, String, Bool, Color,                             
	// ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this                     
	// field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if                  
	// you enable the advanced option **Use Multilines type**, you will have "*Multilines*"                      
	// instead of "*String*" when relevant.                                                                      
	Type                                                                                       string            `json:"__type"`
	// Optional list of accepted file extensions for FilePath value type. Includes the dot:                      
	// `.ext`                                                                                                    
	AcceptFileTypes                                                                            []string          `json:"acceptFileTypes"`
	// Possible values: `Any`, `OnlySame`, `OnlyTags`                                                            
	AllowedRefs                                                                                AllowedRefs       `json:"allowedRefs"`
	AllowedRefTags                                                                             []string          `json:"allowedRefTags"`
	AllowOutOfLevelRef                                                                         bool              `json:"allowOutOfLevelRef"`
	// Array max length                                                                                          
	ArrayMaxLength                                                                             *int64            `json:"arrayMaxLength"`
	// Array min length                                                                                          
	ArrayMinLength                                                                             *int64            `json:"arrayMinLength"`
	AutoChainRef                                                                               bool              `json:"autoChainRef"`
	// TRUE if the value can be null. For arrays, TRUE means it can contain null values                          
	// (exception: array of Points can't have null values).                                                      
	CanBeNull                                                                                  bool              `json:"canBeNull"`
	// Default value if selected value is null or invalid.                                                       
	DefaultOverride                                                                            interface{}       `json:"defaultOverride"`
	// User defined documentation for this field to provide help/tips to level designers about                   
	// accepted values.                                                                                          
	Doc                                                                                        *string           `json:"doc"`
	EditorAlwaysShow                                                                           bool              `json:"editorAlwaysShow"`
	EditorCutLongValues                                                                        bool              `json:"editorCutLongValues"`
	// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,                           
	// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,                                      
	// `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,                                       
	// `RefLinkBetweenCenters`                                                                                   
	EditorDisplayMode                                                                          EditorDisplayMode `json:"editorDisplayMode"`
	// Possible values: `Above`, `Center`, `Beneath`                                                             
	EditorDisplayPos                                                                           EditorDisplayPos  `json:"editorDisplayPos"`
	// Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`                     
	EditorLinkStyle                                                                            EditorLinkStyle   `json:"editorLinkStyle"`
	EditorShowInWorld                                                                          bool              `json:"editorShowInWorld"`
	EditorTextPrefix                                                                           *string           `json:"editorTextPrefix"`
	EditorTextSuffix                                                                           *string           `json:"editorTextSuffix"`
	// User defined unique identifier                                                                            
	Identifier                                                                                 string            `json:"identifier"`
	// TRUE if the value is an array of multiple values                                                          
	IsArray                                                                                    bool              `json:"isArray"`
	// Max limit for value, if applicable                                                                        
	Max                                                                                        *float64          `json:"max"`
	// Min limit for value, if applicable                                                                        
	Min                                                                                        *float64          `json:"min"`
	// Optional regular expression that needs to be matched to accept values. Expected format:                   
	// `/some_reg_ex/g`, with optional "i" flag.                                                                 
	Regex                                                                                      *string           `json:"regex"`
	SymmetricalRef                                                                             bool              `json:"symmetricalRef"`
	// Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,                  
	// `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`                                              
	TextLanguageMode                                                                           *TextLanguageMode `json:"textLanguageMode"`
	// UID of the tileset used for a Tile                                                                        
	TilesetUid                                                                                 *int64            `json:"tilesetUid"`
	// Internal enum representing the possible field types. Possible values: F_Int, F_Float,                     
	// F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile                      
	FieldDefinitionType                                                                        string            `json:"type"`
	// Unique Int identifier                                                                                     
	Uid                                                                                        int64             `json:"uid"`
	// If TRUE, the color associated with this field will override the Entity or Level default                   
	// color in the editor UI. For Enum fields, this would be the color associated to their                      
	// values.                                                                                                   
	UseForSmartColor                                                                           bool              `json:"useForSmartColor"`
}

// This object represents a custom sub rectangle in a Tileset image.
type TilesetRectangle struct {
	// Height in pixels                                                     
	H                                                                 int64 `json:"h"`
	// UID of the tileset                                                   
	TilesetUid                                                        int64 `json:"tilesetUid"`
	// Width in pixels                                                      
	W                                                                 int64 `json:"w"`
	// X pixels coordinate of the top-left corner in the Tileset image      
	X                                                                 int64 `json:"x"`
	// Y pixels coordinate of the top-left corner in the Tileset image      
	Y                                                                 int64 `json:"y"`
}

type EnumDefinition struct {
	ExternalFileChecksum                                        *string               `json:"externalFileChecksum"`
	// Relative path to the external file providing this Enum                         
	ExternalRelPath                                             *string               `json:"externalRelPath"`
	// Tileset UID if provided                                                        
	IconTilesetUid                                              *int64                `json:"iconTilesetUid"`
	// User defined unique identifier                                                 
	Identifier                                                  string                `json:"identifier"`
	// An array of user-defined tags to organize the Enums                            
	Tags                                                        []string              `json:"tags"`
	// Unique Int identifier                                                          
	Uid                                                         int64                 `json:"uid"`
	// All possible enum values, with their optional Tile infos.                      
	Values                                                      []EnumValueDefinition `json:"values"`
}

type EnumValueDefinition struct {
	// An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width,        
	// height ]`                                                                                     
	TileSrcRect                                                                              []int64 `json:"__tileSrcRect"`
	// Optional color                                                                                
	Color                                                                                    int64   `json:"color"`
	// Enum value                                                                                    
	ID                                                                                       string  `json:"id"`
	// The optional ID of the tile                                                                   
	TileID                                                                                   *int64  `json:"tileId"`
}

type LayerDefinition struct {
	// Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)                                                        
	Type                                                                                         string                   `json:"__type"`
	// Contains all the auto-layer rule definitions.                                                                      
	AutoRuleGroups                                                                               []AutoLayerRuleGroup     `json:"autoRuleGroups"`
	AutoSourceLayerDefUid                                                                        *int64                   `json:"autoSourceLayerDefUid"`
	// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced                             
	// by: `tilesetDefUid`                                                                                                
	AutoTilesetDefUid                                                                            *int64                   `json:"autoTilesetDefUid"`
	// Allow editor selections when the layer is not currently active.                                                    
	CanSelectWhenInactive                                                                        bool                     `json:"canSelectWhenInactive"`
	// Opacity of the layer (0 to 1.0)                                                                                    
	DisplayOpacity                                                                               float64                  `json:"displayOpacity"`
	// An array of tags to forbid some Entities in this layer                                                             
	ExcludedTags                                                                                 []string                 `json:"excludedTags"`
	// Width and height of the grid in pixels                                                                             
	GridSize                                                                                     int64                    `json:"gridSize"`
	// Height of the optional "guide" grid in pixels                                                                      
	GuideGridHei                                                                                 int64                    `json:"guideGridHei"`
	// Width of the optional "guide" grid in pixels                                                                       
	GuideGridWid                                                                                 int64                    `json:"guideGridWid"`
	HideFieldsWhenInactive                                                                       bool                     `json:"hideFieldsWhenInactive"`
	// Hide the layer from the list on the side of the editor view.                                                       
	HideInList                                                                                   bool                     `json:"hideInList"`
	// User defined unique identifier                                                                                     
	Identifier                                                                                   string                   `json:"identifier"`
	// Alpha of this layer when it is not the active one.                                                                 
	InactiveOpacity                                                                              float64                  `json:"inactiveOpacity"`
	// An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the                               
	// array order is not related to actual IntGrid values! As user can re-order IntGrid values                           
	// freely, you may value "2" before value "1" in this array.                                                          
	IntGridValues                                                                                []IntGridValueDefinition `json:"intGridValues"`
	// Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling                               
	// speed of this layer, creating a fake 3D (parallax) effect.                                                         
	ParallaxFactorX                                                                              float64                  `json:"parallaxFactorX"`
	// Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed                           
	// of this layer, creating a fake 3D (parallax) effect.                                                               
	ParallaxFactorY                                                                              float64                  `json:"parallaxFactorY"`
	// If true (default), a layer with a parallax factor will also be scaled up/down accordingly.                         
	ParallaxScaling                                                                              bool                     `json:"parallaxScaling"`
	// X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`                           
	// optional offset)                                                                                                   
	PxOffsetX                                                                                    int64                    `json:"pxOffsetX"`
	// Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`                           
	// optional offset)                                                                                                   
	PxOffsetY                                                                                    int64                    `json:"pxOffsetY"`
	// An array of tags to filter Entities that can be added to this layer                                                
	RequiredTags                                                                                 []string                 `json:"requiredTags"`
	// If the tiles are smaller or larger than the layer grid, the pivot value will be used to                            
	// position the tile relatively its grid cell.                                                                        
	TilePivotX                                                                                   float64                  `json:"tilePivotX"`
	// If the tiles are smaller or larger than the layer grid, the pivot value will be used to                            
	// position the tile relatively its grid cell.                                                                        
	TilePivotY                                                                                   float64                  `json:"tilePivotY"`
	// Reference to the default Tileset UID being used by this layer definition.<br/>                                     
	// **WARNING**: some layer *instances* might use a different tileset. So most of the time,                            
	// you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:                          
	// since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.                           
	TilesetDefUid                                                                                *int64                   `json:"tilesetDefUid"`
	// Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,                                    
	// `AutoLayer`                                                                                                        
	LayerDefinitionType                                                                          Type                     `json:"type"`
	// Unique Int identifier                                                                                              
	Uid                                                                                          int64                    `json:"uid"`
}

type AutoLayerRuleGroup struct {
	Active                                                            bool                      `json:"active"`
	// *This field was removed in 1.0.0 and should no longer be used.*                          
	Collapsed                                                         *bool                     `json:"collapsed"`
	IsOptional                                                        bool                      `json:"isOptional"`
	Name                                                              string                    `json:"name"`
	Rules                                                             []AutoLayerRuleDefinition `json:"rules"`
	Uid                                                               int64                     `json:"uid"`
	UsesWizard                                                        bool                      `json:"usesWizard"`
}

// This complex section isn't meant to be used by game devs at all, as these rules are
// completely resolved internally by the editor before any saving. You should just ignore
// this part.
type AutoLayerRuleDefinition struct {
	// If FALSE, the rule effect isn't applied, and no tiles are generated.                               
	Active                                                                                       bool     `json:"active"`
	// When TRUE, the rule will prevent other rules to be applied in the same cell if it matches          
	// (TRUE by default).                                                                                 
	BreakOnMatch                                                                                 bool     `json:"breakOnMatch"`
	// Chances for this rule to be applied (0 to 1)                                                       
	Chance                                                                                       float64  `json:"chance"`
	// Checker mode Possible values: `None`, `Horizontal`, `Vertical`                                     
	Checker                                                                                      Checker  `json:"checker"`
	// If TRUE, allow rule to be matched by flipping its pattern horizontally                             
	FlipX                                                                                        bool     `json:"flipX"`
	// If TRUE, allow rule to be matched by flipping its pattern vertically                               
	FlipY                                                                                        bool     `json:"flipY"`
	// Default IntGrid value when checking cells outside of level bounds                                  
	OutOfBoundsValue                                                                             *int64   `json:"outOfBoundsValue"`
	// Rule pattern (size x size)                                                                         
	Pattern                                                                                      []int64  `json:"pattern"`
	// If TRUE, enable Perlin filtering to only apply rule on specific random area                        
	PerlinActive                                                                                 bool     `json:"perlinActive"`
	PerlinOctaves                                                                                float64  `json:"perlinOctaves"`
	PerlinScale                                                                                  float64  `json:"perlinScale"`
	PerlinSeed                                                                                   float64  `json:"perlinSeed"`
	// X pivot of a tile stamp (0-1)                                                                      
	PivotX                                                                                       float64  `json:"pivotX"`
	// Y pivot of a tile stamp (0-1)                                                                      
	PivotY                                                                                       float64  `json:"pivotY"`
	// Pattern width & height. Should only be 1,3,5 or 7.                                                 
	Size                                                                                         int64    `json:"size"`
	// Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.         
	TileIDS                                                                                      []int64  `json:"tileIds"`
	// Defines how tileIds array is used Possible values: `Single`, `Stamp`                               
	TileMode                                                                                     TileMode `json:"tileMode"`
	// Unique Int identifier                                                                              
	Uid                                                                                          int64    `json:"uid"`
	// X cell coord modulo                                                                                
	XModulo                                                                                      int64    `json:"xModulo"`
	// X cell start offset                                                                                
	XOffset                                                                                      int64    `json:"xOffset"`
	// Y cell coord modulo                                                                                
	YModulo                                                                                      int64    `json:"yModulo"`
	// Y cell start offset                                                                                
	YOffset                                                                                      int64    `json:"yOffset"`
}

// IntGrid value definition
type IntGridValueDefinition struct {
	Color                            string  `json:"color"`
	// User defined unique identifier        
	Identifier                       *string `json:"identifier"`
	// The IntGrid value itself              
	Value                            int64   `json:"value"`
}

// The `Tileset` definition is the most important part among project definitions. It
// contains some extra informations about each integrated tileset. If you only had to parse
// one definition section, that would be the one.
type TilesetDefinition struct {
	// Grid-based height                                                                                                
	CHei                                                                                       int64                    `json:"__cHei"`
	// Grid-based width                                                                                                 
	CWid                                                                                       int64                    `json:"__cWid"`
	// The following data is used internally for various optimizations. It's always synced with                         
	// source image changes.                                                                                            
	CachedPixelData                                                                            map[string]interface{}   `json:"cachedPixelData"`
	// An array of custom tile metadata                                                                                 
	CustomData                                                                                 []TileCustomMetadata     `json:"customData"`
	// If this value is set, then it means that this atlas uses an internal LDtk atlas image                            
	// instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`                                            
	EmbedAtlas                                                                                 *EmbedAtlas              `json:"embedAtlas"`
	// Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1                            
	// element per Enum value, which contains an array of all Tile IDs that are tagged with it.                         
	EnumTags                                                                                   []EnumTagValue           `json:"enumTags"`
	// User defined unique identifier                                                                                   
	Identifier                                                                                 string                   `json:"identifier"`
	// Distance in pixels from image borders                                                                            
	Padding                                                                                    int64                    `json:"padding"`
	// Image height in pixels                                                                                           
	PxHei                                                                                      int64                    `json:"pxHei"`
	// Image width in pixels                                                                                            
	PxWid                                                                                      int64                    `json:"pxWid"`
	// Path to the source file, relative to the current project JSON file<br/>  It can be null                          
	// if no image was provided, or when using an embed atlas.                                                          
	RelPath                                                                                    *string                  `json:"relPath"`
	// Array of group of tiles selections, only meant to be used in the editor                                          
	SavedSelections                                                                            []map[string]interface{} `json:"savedSelections"`
	// Space in pixels between all tiles                                                                                
	Spacing                                                                                    int64                    `json:"spacing"`
	// An array of user-defined tags to organize the Tilesets                                                           
	Tags                                                                                       []string                 `json:"tags"`
	// Optional Enum definition UID used for this tileset meta-data                                                     
	TagsSourceEnumUid                                                                          *int64                   `json:"tagsSourceEnumUid"`
	TileGridSize                                                                               int64                    `json:"tileGridSize"`
	// Unique Intidentifier                                                                                             
	Uid                                                                                        int64                    `json:"uid"`
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
	CustomCommand        *LdtkCustomCommand            `json:"CustomCommand,omitempty"`
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
	TableOfContentEntry  *LdtkTableOfContentEntry      `json:"TableOfContentEntry,omitempty"`
	Tile                 *TileInstance                 `json:"Tile,omitempty"`
	TileCustomMetadata   *TileCustomMetadata           `json:"TileCustomMetadata,omitempty"`
	TilesetDef           *TilesetDefinition            `json:"TilesetDef,omitempty"`
	TilesetRect          *TilesetRectangle             `json:"TilesetRect,omitempty"`
	World                *World                        `json:"World,omitempty"`
}

type EntityInstance struct {
	// Grid-based coordinates (`[x,y]` format)                                                                  
	Grid                                                                                      []int64           `json:"__grid"`
	// Entity definition identifier                                                                             
	Identifier                                                                                string            `json:"__identifier"`
	// Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity                                
	Pivot                                                                                     []float64         `json:"__pivot"`
	// The entity "smart" color, guessed from either Entity definition, or one its field                        
	// instances.                                                                                               
	SmartColor                                                                                string            `json:"__smartColor"`
	// Array of tags defined in this Entity definition                                                          
	Tags                                                                                      []string          `json:"__tags"`
	// Optional TilesetRect used to display this entity (it could either be the default Entity                  
	// tile, or some tile provided by a field value, like an Enum).                                             
	Tile                                                                                      *TilesetRectangle `json:"__tile"`
	// Reference of the **Entity definition** UID                                                               
	DefUid                                                                                    int64             `json:"defUid"`
	// An array of all custom fields and their values.                                                          
	FieldInstances                                                                            []FieldInstance   `json:"fieldInstances"`
	// Entity height in pixels. For non-resizable entities, it will be the same as Entity                       
	// definition.                                                                                              
	Height                                                                                    int64             `json:"height"`
	// Unique instance identifier                                                                               
	Iid                                                                                       string            `json:"iid"`
	// Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget                       
	// optional layer offsets, if they exist!                                                                   
	Px                                                                                        []int64           `json:"px"`
	// Entity width in pixels. For non-resizable entities, it will be the same as Entity                        
	// definition.                                                                                              
	Width                                                                                     int64             `json:"width"`
}

type FieldInstance struct {
	// Field definition identifier                                                                                
	Identifier                                                                                  string            `json:"__identifier"`
	// Optional TilesetRect used to display this field (this can be the field own Tile, or some                   
	// other Tile guessed from the value, like an Enum).                                                          
	Tile                                                                                        *TilesetRectangle `json:"__tile"`
	// Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,                         
	// etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have                  
	// "*Multilines*" instead of "*String*" when relevant.                                                        
	Type                                                                                        string            `json:"__type"`
	// Actual value of the field instance. The value type varies, depending on `__type`:<br/>                     
	// - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you                      
	// just get the actual value with the expected type.<br/>   - For **Color**, the value is an                  
	// hexadecimal string using "#rrggbb" format.<br/>   - For **Enum**, the value is a String                    
	// representing the selected enum value.<br/>   - For **Point**, the value is a                               
	// [GridPoint](#ldtk-GridPoint) object.<br/>   - For **Tile**, the value is a                                 
	// [TilesetRect](#ldtk-TilesetRect) object.<br/>   - For **EntityRef**, the value is an                       
	// [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>  If the field is an                   
	// array, then this `__value` will also be a JSON array.                                                      
	Value                                                                                       interface{}       `json:"__value"`
	// Reference of the **Field definition** UID                                                                  
	DefUid                                                                                      int64             `json:"defUid"`
	// Editor internal raw values                                                                                 
	RealEditorValues                                                                            []interface{}     `json:"realEditorValues"`
}

// This object is used in Field Instances to describe an EntityRef value.
type FieldInstanceEntityReference struct {
	// IID of the refered EntityInstance                                    
	EntityIid                                                        string `json:"entityIid"`
	// IID of the LayerInstance containing the refered EntityInstance       
	LayerIid                                                         string `json:"layerIid"`
	// IID of the Level containing the refered EntityInstance               
	LevelIid                                                         string `json:"levelIid"`
	// IID of the World containing the refered EntityInstance               
	WorldIid                                                         string `json:"worldIid"`
}

// This object is just a grid-based coordinate used in Field values.
type FieldInstanceGridPoint struct {
	// X grid-based coordinate      
	Cx                        int64 `json:"cx"`
	// Y grid-based coordinate      
	Cy                        int64 `json:"cy"`
}

// IntGrid value instance
type IntGridValueInstance struct {
	// Coordinate ID in the layer grid      
	CoordID                           int64 `json:"coordId"`
	// IntGrid value                        
	V                                 int64 `json:"v"`
}

type LayerInstance struct {
	// Grid-based height                                                                                               
	CHei                                                                                        int64                  `json:"__cHei"`
	// Grid-based width                                                                                                
	CWid                                                                                        int64                  `json:"__cWid"`
	// Grid size                                                                                                       
	GridSize                                                                                    int64                  `json:"__gridSize"`
	// Layer definition identifier                                                                                     
	Identifier                                                                                  string                 `json:"__identifier"`
	// Layer opacity as Float [0-1]                                                                                    
	Opacity                                                                                     float64                `json:"__opacity"`
	// Total layer X pixel offset, including both instance and definition offsets.                                     
	PxTotalOffsetX                                                                              int64                  `json:"__pxTotalOffsetX"`
	// Total layer Y pixel offset, including both instance and definition offsets.                                     
	PxTotalOffsetY                                                                              int64                  `json:"__pxTotalOffsetY"`
	// The definition UID of corresponding Tileset, if any.                                                            
	TilesetDefUid                                                                               *int64                 `json:"__tilesetDefUid"`
	// The relative path to corresponding Tileset, if any.                                                             
	TilesetRelPath                                                                              *string                `json:"__tilesetRelPath"`
	// Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)                                             
	Type                                                                                        string                 `json:"__type"`
	// An array containing all tiles generated by Auto-layer rules. The array is already sorted                        
	// in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>                            
	// Note: if multiple tiles are stacked in the same cell as the result of different rules,                          
	// all tiles behind opaque ones will be discarded.                                                                 
	AutoLayerTiles                                                                              []TileInstance         `json:"autoLayerTiles"`
	EntityInstances                                                                             []EntityInstance       `json:"entityInstances"`
	GridTiles                                                                                   []TileInstance         `json:"gridTiles"`
	// Unique layer instance identifier                                                                                
	Iid                                                                                         string                 `json:"iid"`
	// **WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced                          
	// by: `intGridCsv`                                                                                                
	IntGrid                                                                                     []IntGridValueInstance `json:"intGrid"`
	// A list of all values in the IntGrid layer, stored in CSV format (Comma Separated                                
	// Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to                       
	// right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values                            
	// start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.                                                  
	IntGridCSV                                                                                  []int64                `json:"intGridCsv"`
	// Reference the Layer definition UID                                                                              
	LayerDefUid                                                                                 int64                  `json:"layerDefUid"`
	// Reference to the UID of the level containing this layer instance                                                
	LevelID                                                                                     int64                  `json:"levelId"`
	// An Array containing the UIDs of optional rules that were enabled in this specific layer                         
	// instance.                                                                                                       
	OptionalRules                                                                               []int64                `json:"optionalRules"`
	// This layer can use another tileset by overriding the tileset UID here.                                          
	OverrideTilesetUid                                                                          *int64                 `json:"overrideTilesetUid"`
	// X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to                          
	// the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`                          
	// which contains the total offset value)                                                                          
	PxOffsetX                                                                                   int64                  `json:"pxOffsetX"`
	// Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to                          
	// the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`                          
	// which contains the total offset value)                                                                          
	PxOffsetY                                                                                   int64                  `json:"pxOffsetY"`
	// Random seed used for Auto-Layers rendering                                                                      
	Seed                                                                                        int64                  `json:"seed"`
	// Layer instance visibility                                                                                       
	Visible                                                                                     bool                   `json:"visible"`
}

// This structure represents a single tile from a given Tileset.
type TileInstance struct {
	// Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>        
	// For tile-layer tiles: `[coordId]`.                                                             
	D                                                                                         []int64 `json:"d"`
	// "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>        
	// - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip           
	// only), f=2 (Y flip only), f=3 (both flips)                                                     
	F                                                                                         int64   `json:"f"`
	// Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional         
	// layer offsets, if they exist!                                                                  
	Px                                                                                        []int64 `json:"px"`
	// Pixel coordinates of the tile in the **tileset** (`[x,y]` format)                              
	Src                                                                                       []int64 `json:"src"`
	// The *Tile ID* in the corresponding tileset.                                                    
	T                                                                                         int64   `json:"t"`
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
	// Background color of the level (same as `bgColor`, except the default value is                                     
	// automatically used here if its value is `null`)                                                                   
	BgColor                                                                                     string                   `json:"__bgColor"`
	// Position informations of the background image, if there is one.                                                   
	BgPos                                                                                       *LevelBackgroundPosition `json:"__bgPos"`
	// An array listing all other levels touching this one on the world map.<br/>  Only relevant                         
	// for world layouts where level spatial positioning is manual (ie. GridVania, Free). For                            
	// Horizontal and Vertical layouts, this array is always empty.                                                      
	Neighbours                                                                                  []NeighbourLevel         `json:"__neighbours"`
	// The "guessed" color for this level in the editor, decided using either the background                             
	// color or an existing custom field.                                                                                
	SmartColor                                                                                  string                   `json:"__smartColor"`
	// Background color of the level. If `null`, the project `defaultLevelBgColor` should be                             
	// used.                                                                                                             
	LevelBgColor                                                                                *string                  `json:"bgColor"`
	// Background image X pivot (0-1)                                                                                    
	BgPivotX                                                                                    float64                  `json:"bgPivotX"`
	// Background image Y pivot (0-1)                                                                                    
	BgPivotY                                                                                    float64                  `json:"bgPivotY"`
	// An enum defining the way the background image (if any) is positioned on the level. See                            
	// `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,                               
	// `Contain`, `Cover`, `CoverDirty`                                                                                  
	LevelBgPos                                                                                  *BgPos                   `json:"bgPos"`
	// The *optional* relative path to the level background image.                                                       
	BgRelPath                                                                                   *string                  `json:"bgRelPath"`
	// This value is not null if the project option "*Save levels separately*" is enabled. In                            
	// this case, this **relative** path points to the level Json file.                                                  
	ExternalRelPath                                                                             *string                  `json:"externalRelPath"`
	// An array containing this level custom field values.                                                               
	FieldInstances                                                                              []FieldInstance          `json:"fieldInstances"`
	// User defined unique identifier                                                                                    
	Identifier                                                                                  string                   `json:"identifier"`
	// Unique instance identifier                                                                                        
	Iid                                                                                         string                   `json:"iid"`
	// An array containing all Layer instances. **IMPORTANT**: if the project option "*Save                              
	// levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted                           
	// in display order**: the 1st layer is the top-most and the last is behind.                                         
	LayerInstances                                                                              []LayerInstance          `json:"layerInstances"`
	// Height of the level in pixels                                                                                     
	PxHei                                                                                       int64                    `json:"pxHei"`
	// Width of the level in pixels                                                                                      
	PxWid                                                                                       int64                    `json:"pxWid"`
	// Unique Int identifier                                                                                             
	Uid                                                                                         int64                    `json:"uid"`
	// If TRUE, the level identifier will always automatically use the naming pattern as defined                         
	// in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by                            
	// user.                                                                                                             
	UseAutoIdentifier                                                                           bool                     `json:"useAutoIdentifier"`
	// Index that represents the "depth" of the level in the world. Default is 0, greater means                          
	// "above", lower means "below".<br/>  This value is mostly used for display only and is                             
	// intended to make stacking of levels easier to manage.                                                             
	WorldDepth                                                                                  int64                    `json:"worldDepth"`
	// World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial                           
	// positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the                             
	// value is always -1 here.                                                                                          
	WorldX                                                                                      int64                    `json:"worldX"`
	// World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial                           
	// positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the                             
	// value is always -1 here.                                                                                          
	WorldY                                                                                      int64                    `json:"worldY"`
}

// Level background image position info
type LevelBackgroundPosition struct {
	// An array of 4 float values describing the cropped sub-rectangle of the displayed                
	// background image. This cropping happens when original is larger than the level bounds.          
	// Array format: `[ cropX, cropY, cropWidth, cropHeight ]`                                         
	CropRect                                                                                 []float64 `json:"cropRect"`
	// An array containing the `[scaleX,scaleY]` values of the **cropped** background image,           
	// depending on `bgPos` option.                                                                    
	Scale                                                                                    []float64 `json:"scale"`
	// An array containing the `[x,y]` pixel coordinates of the top-left corner of the                 
	// **cropped** background image, depending on `bgPos` option.                                      
	TopLeftPx                                                                                []int64   `json:"topLeftPx"`
}

// Nearby level info
type NeighbourLevel struct {
	// A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,        
	// `e`ast).                                                                                     
	Dir                                                                                      string `json:"dir"`
	// Neighbour Instance Identifier                                                                
	LevelIid                                                                                 string `json:"levelIid"`
	// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced       
	// by: `levelIid`                                                                               
	LevelUid                                                                                 *int64 `json:"levelUid"`
}

type LdtkTableOfContentEntry struct {
	Identifier string                         `json:"identifier"`
	Instances  []FieldInstanceEntityReference `json:"instances"`
}

// **IMPORTANT**: this type is not used *yet* in current LDtk version. It's only presented
// here as a preview of a planned feature.  A World contains multiple levels, and it has its
// own layout settings.
type World struct {
	// Default new level height                                                                               
	DefaultLevelHeight                                                                           int64        `json:"defaultLevelHeight"`
	// Default new level width                                                                                
	DefaultLevelWidth                                                                            int64        `json:"defaultLevelWidth"`
	// User defined unique identifier                                                                         
	Identifier                                                                                   string       `json:"identifier"`
	// Unique instance identifer                                                                              
	Iid                                                                                          string       `json:"iid"`
	// All levels from this world. The order of this array is only relevant in                                
	// `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).                       
	// Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.                        
	Levels                                                                                       []Level      `json:"levels"`
	// Height of the world grid in pixels.                                                                    
	WorldGridHeight                                                                              int64        `json:"worldGridHeight"`
	// Width of the world grid in pixels.                                                                     
	WorldGridWidth                                                                               int64        `json:"worldGridWidth"`
	// An enum that describes how levels are organized in this project (ie. linearly or in a 2D               
	// space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`             
	WorldLayout                                                                                  *WorldLayout `json:"worldLayout"`
}

// Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`
type When string
const (
	AfterLoad When = "AfterLoad"
	AfterSave When = "AfterSave"
	BeforeSave When = "BeforeSave"
	Manual When = "Manual"
)

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

// Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
type EditorLinkStyle string
const (
	ArrowsLine EditorLinkStyle = "ArrowsLine"
	CurvedArrow EditorLinkStyle = "CurvedArrow"
	DashedLine EditorLinkStyle = "DashedLine"
	StraightArrow EditorLinkStyle = "StraightArrow"
	ZigZag EditorLinkStyle = "ZigZag"
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
