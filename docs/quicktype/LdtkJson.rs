// Example code that deserializes and serializes the model.
// extern crate serde;
// #[macro_use]
// extern crate serde_derive;
// extern crate serde_json;
//
// use generated_module::[object Object];
//
// fn main() {
//     let json = r#"{"answer": 42}"#;
//     let model: [object Object] = serde_json::from_str(&json).unwrap();
// }

extern crate serde_derive;
use std::collections::HashMap;

/// This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).
///
/// This is the root of any Project JSON file. It contains:  - the project settings, - an
/// array of levels, - a group of definitions (that can probably be safely ignored for most
/// users).
#[derive(Serialize, Deserialize)]
pub struct LdtkJson {
    /// Number of backup files to keep, if the `backupOnSave` is TRUE
    #[serde(rename = "backupLimit")]
    backup_limit: i64,

    /// If TRUE, an extra copy of the project will be created in a sub folder, when saving.
    #[serde(rename = "backupOnSave")]
    backup_on_save: bool,

    /// Project background color
    #[serde(rename = "bgColor")]
    bg_color: String,

    /// Default grid size for new layers
    #[serde(rename = "defaultGridSize")]
    default_grid_size: i64,

    /// Default background color of levels
    #[serde(rename = "defaultLevelBgColor")]
    default_level_bg_color: String,

    /// Default new level height
    #[serde(rename = "defaultLevelHeight")]
    default_level_height: i64,

    /// Default new level width
    #[serde(rename = "defaultLevelWidth")]
    default_level_width: i64,

    /// Default X pivot (0 to 1) for new entities
    #[serde(rename = "defaultPivotX")]
    default_pivot_x: f64,

    /// Default Y pivot (0 to 1) for new entities
    #[serde(rename = "defaultPivotY")]
    default_pivot_y: f64,

    /// A structure containing all the definitions of this project
    #[serde(rename = "defs")]
    defs: Definitions,

    /// **WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced
    /// by: `imageExportMode`
    #[serde(rename = "exportPng")]
    export_png: Option<bool>,

    /// If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file
    /// (default is FALSE)
    #[serde(rename = "exportTiled")]
    export_tiled: bool,

    /// If TRUE, one file will be saved for the project (incl. all its definitions) and one file
    /// in a sub-folder for each level.
    #[serde(rename = "externalLevels")]
    external_levels: bool,

    /// An array containing various advanced flags (ie. options or other states). Possible
    /// values: `DiscardPreCsvIntGrid`, `IgnoreBackupSuggest`
    #[serde(rename = "flags")]
    flags: Vec<Flag>,

    /// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
    /// `OneImagePerLevel`
    #[serde(rename = "imageExportMode")]
    image_export_mode: ImageExportMode,

    /// File format version
    #[serde(rename = "jsonVersion")]
    json_version: String,

    /// The default naming convention for level identifiers.
    #[serde(rename = "levelNamePattern")]
    level_name_pattern: String,

    /// All levels. The order of this array is only relevant in `LinearHorizontal` and
    /// `linearVertical` world layouts (see `worldLayout` value). Otherwise, you should refer to
    /// the `worldX`,`worldY` coordinates of each Level.
    #[serde(rename = "levels")]
    levels: Vec<Level>,

    /// If TRUE, the Json is partially minified (no indentation, nor line breaks, default is
    /// FALSE)
    #[serde(rename = "minifyJson")]
    minify_json: bool,

    /// Next Unique integer ID available
    #[serde(rename = "nextUid")]
    next_uid: i64,

    /// File naming pattern for exported PNGs
    #[serde(rename = "pngFilePattern")]
    png_file_pattern: Option<String>,

    /// Height of the world grid in pixels.
    #[serde(rename = "worldGridHeight")]
    world_grid_height: i64,

    /// Width of the world grid in pixels.
    #[serde(rename = "worldGridWidth")]
    world_grid_width: i64,

    /// An enum that describes how levels are organized in this project (ie. linearly or in a 2D
    /// space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`
    #[serde(rename = "worldLayout")]
    world_layout: WorldLayout,
}

/// A structure containing all the definitions of this project
///
/// If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
/// the `defs` section, as it contains data that are mostly important to the editor. To keep
/// you away from the `defs` section and avoid some unnecessary JSON parsing, important data
/// from definitions is often duplicated in fields prefixed with a double underscore (eg.
/// `__identifier` or `__type`).  The 2 only definition types you might need here are
/// **Tilesets** and **Enums**.
#[derive(Serialize, Deserialize)]
pub struct Definitions {
    /// All entities definitions, including their custom fields
    #[serde(rename = "entities")]
    entities: Vec<EntityDefinition>,

    /// All internal enums
    #[serde(rename = "enums")]
    enums: Vec<EnumDefinition>,

    /// Note: external enums are exactly the same as `enums`, except they have a `relPath` to
    /// point to an external source file.
    #[serde(rename = "externalEnums")]
    external_enums: Vec<EnumDefinition>,

    /// All layer definitions
    #[serde(rename = "layers")]
    layers: Vec<LayerDefinition>,

    /// All custom fields available to all levels.
    #[serde(rename = "levelFields")]
    level_fields: Vec<FieldDefinition>,

    /// All tilesets
    #[serde(rename = "tilesets")]
    tilesets: Vec<TilesetDefinition>,
}

#[derive(Serialize, Deserialize)]
pub struct EntityDefinition {
    /// Base entity color
    #[serde(rename = "color")]
    color: String,

    /// Array of field definitions
    #[serde(rename = "fieldDefs")]
    field_defs: Vec<FieldDefinition>,

    #[serde(rename = "fillOpacity")]
    fill_opacity: f64,

    /// Pixel height
    #[serde(rename = "height")]
    height: i64,

    #[serde(rename = "hollow")]
    hollow: bool,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height
    /// will keep the same aspect ratio as the definition.
    #[serde(rename = "keepAspectRatio")]
    keep_aspect_ratio: bool,

    /// Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
    #[serde(rename = "limitBehavior")]
    limit_behavior: LimitBehavior,

    /// If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
    /// values: `PerLayer`, `PerLevel`, `PerWorld`
    #[serde(rename = "limitScope")]
    limit_scope: LimitScope,

    #[serde(rename = "lineOpacity")]
    line_opacity: f64,

    /// Max instances count
    #[serde(rename = "maxCount")]
    max_count: i64,

    /// Pivot X coordinate (from 0 to 1.0)
    #[serde(rename = "pivotX")]
    pivot_x: f64,

    /// Pivot Y coordinate (from 0 to 1.0)
    #[serde(rename = "pivotY")]
    pivot_y: f64,

    /// Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
    #[serde(rename = "renderMode")]
    render_mode: RenderMode,

    /// If TRUE, the entity instances will be resizable horizontally
    #[serde(rename = "resizableX")]
    resizable_x: bool,

    /// If TRUE, the entity instances will be resizable vertically
    #[serde(rename = "resizableY")]
    resizable_y: bool,

    /// Display entity name in editor
    #[serde(rename = "showName")]
    show_name: bool,

    /// An array of strings that classifies this entity
    #[serde(rename = "tags")]
    tags: Vec<String>,

    /// Tile ID used for optional tile display
    #[serde(rename = "tileId")]
    tile_id: Option<i64>,

    /// Possible values: `Cover`, `FitInside`, `Repeat`, `Stretch`
    #[serde(rename = "tileRenderMode")]
    tile_render_mode: TileRenderMode,

    /// Tileset ID used for optional tile display
    #[serde(rename = "tilesetId")]
    tileset_id: Option<i64>,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,

    /// Pixel width
    #[serde(rename = "width")]
    width: i64,
}

/// This section is mostly only intended for the LDtk editor app itself. You can safely
/// ignore it.
#[derive(Serialize, Deserialize)]
pub struct FieldDefinition {
    /// Human readable value type (eg. `Int`, `Float`, `Point`, etc.). If the field is an array,
    /// this field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)
    #[serde(rename = "__type")]
    field_definition_type: String,

    /// Optional list of accepted file extensions for FilePath value type. Includes the dot:
    /// `.ext`
    #[serde(rename = "acceptFileTypes")]
    accept_file_types: Option<Vec<String>>,

    /// Array max length
    #[serde(rename = "arrayMaxLength")]
    array_max_length: Option<i64>,

    /// Array min length
    #[serde(rename = "arrayMinLength")]
    array_min_length: Option<i64>,

    /// TRUE if the value can be null. For arrays, TRUE means it can contain null values
    /// (exception: array of Points can't have null values).
    #[serde(rename = "canBeNull")]
    can_be_null: bool,

    /// Default value if selected value is null or invalid.
    #[serde(rename = "defaultOverride")]
    default_override: Option<serde_json::Value>,

    #[serde(rename = "editorAlwaysShow")]
    editor_always_show: bool,

    #[serde(rename = "editorCutLongValues")]
    editor_cut_long_values: bool,

    /// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,
    /// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`
    #[serde(rename = "editorDisplayMode")]
    editor_display_mode: EditorDisplayMode,

    /// Possible values: `Above`, `Center`, `Beneath`
    #[serde(rename = "editorDisplayPos")]
    editor_display_pos: EditorDisplayPos,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// TRUE if the value is an array of multiple values
    #[serde(rename = "isArray")]
    is_array: bool,

    /// Max limit for value, if applicable
    #[serde(rename = "max")]
    max: Option<f64>,

    /// Min limit for value, if applicable
    #[serde(rename = "min")]
    min: Option<f64>,

    /// Optional regular expression that needs to be matched to accept values. Expected format:
    /// `/some_reg_ex/g`, with optional "i" flag.
    #[serde(rename = "regex")]
    regex: Option<String>,

    /// Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,
    /// `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`
    #[serde(rename = "textLanguageMode")]
    text_language_mode: Option<TextLanguageMode>,

    /// Internal type enum
    #[serde(rename = "type")]
    purple_type: Option<serde_json::Value>,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,
}

#[derive(Serialize, Deserialize)]
pub struct EnumDefinition {
    #[serde(rename = "externalFileChecksum")]
    external_file_checksum: Option<String>,

    /// Relative path to the external file providing this Enum
    #[serde(rename = "externalRelPath")]
    external_rel_path: Option<String>,

    /// Tileset UID if provided
    #[serde(rename = "iconTilesetUid")]
    icon_tileset_uid: Option<i64>,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,

    /// All possible enum values, with their optional Tile infos.
    #[serde(rename = "values")]
    values: Vec<EnumValueDefinition>,
}

#[derive(Serialize, Deserialize)]
pub struct EnumValueDefinition {
    /// An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width,
    /// height ]`
    #[serde(rename = "__tileSrcRect")]
    tile_src_rect: Option<Vec<i64>>,

    /// Optional color
    #[serde(rename = "color")]
    color: i64,

    /// Enum value
    #[serde(rename = "id")]
    id: String,

    /// The optional ID of the tile
    #[serde(rename = "tileId")]
    tile_id: Option<i64>,
}

#[derive(Serialize, Deserialize)]
pub struct LayerDefinition {
    /// Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)
    #[serde(rename = "__type")]
    layer_definition_type: String,

    /// Contains all the auto-layer rule definitions.
    #[serde(rename = "autoRuleGroups")]
    auto_rule_groups: Vec<AutoLayerRuleGroup>,

    #[serde(rename = "autoSourceLayerDefUid")]
    auto_source_layer_def_uid: Option<i64>,

    /// Reference to the Tileset UID being used by this auto-layer rules. WARNING: some layer
    /// *instances* might use a different tileset. So most of the time, you should probably use
    /// the `__tilesetDefUid` value from layer instances.
    #[serde(rename = "autoTilesetDefUid")]
    auto_tileset_def_uid: Option<i64>,

    /// Opacity of the layer (0 to 1.0)
    #[serde(rename = "displayOpacity")]
    display_opacity: f64,

    /// An array of tags to forbid some Entities in this layer
    #[serde(rename = "excludedTags")]
    excluded_tags: Vec<String>,

    /// Width and height of the grid in pixels
    #[serde(rename = "gridSize")]
    grid_size: i64,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// An array that defines extra optional info for each IntGrid value. The array is sorted
    /// using value (ascending).
    #[serde(rename = "intGridValues")]
    int_grid_values: Vec<IntGridValueDefinition>,

    /// X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    /// optional offset)
    #[serde(rename = "pxOffsetX")]
    px_offset_x: i64,

    /// Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    /// optional offset)
    #[serde(rename = "pxOffsetY")]
    px_offset_y: i64,

    /// An array of tags to filter Entities that can be added to this layer
    #[serde(rename = "requiredTags")]
    required_tags: Vec<String>,

    /// If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    /// position the tile relatively its grid cell.
    #[serde(rename = "tilePivotX")]
    tile_pivot_x: f64,

    /// If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    /// position the tile relatively its grid cell.
    #[serde(rename = "tilePivotY")]
    tile_pivot_y: f64,

    /// Reference to the Tileset UID being used by this Tile layer. WARNING: some layer
    /// *instances* might use a different tileset. So most of the time, you should probably use
    /// the `__tilesetDefUid` value from layer instances.
    #[serde(rename = "tilesetDefUid")]
    tileset_def_uid: Option<i64>,

    /// Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
    /// `AutoLayer`
    #[serde(rename = "type")]
    purple_type: Type,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,
}

#[derive(Serialize, Deserialize)]
pub struct AutoLayerRuleGroup {
    #[serde(rename = "active")]
    active: bool,

    #[serde(rename = "collapsed")]
    collapsed: bool,

    #[serde(rename = "isOptional")]
    is_optional: bool,

    #[serde(rename = "name")]
    name: String,

    #[serde(rename = "rules")]
    rules: Vec<AutoLayerRuleDefinition>,

    #[serde(rename = "uid")]
    uid: i64,
}

/// This complex section isn't meant to be used by game devs at all, as these rules are
/// completely resolved internally by the editor before any saving. You should just ignore
/// this part.
#[derive(Serialize, Deserialize)]
pub struct AutoLayerRuleDefinition {
    /// If FALSE, the rule effect isn't applied, and no tiles are generated.
    #[serde(rename = "active")]
    active: bool,

    /// When TRUE, the rule will prevent other rules to be applied in the same cell if it matches
    /// (TRUE by default).
    #[serde(rename = "breakOnMatch")]
    break_on_match: bool,

    /// Chances for this rule to be applied (0 to 1)
    #[serde(rename = "chance")]
    chance: f64,

    /// Checker mode Possible values: `None`, `Horizontal`, `Vertical`
    #[serde(rename = "checker")]
    checker: Checker,

    /// If TRUE, allow rule to be matched by flipping its pattern horizontally
    #[serde(rename = "flipX")]
    flip_x: bool,

    /// If TRUE, allow rule to be matched by flipping its pattern vertically
    #[serde(rename = "flipY")]
    flip_y: bool,

    /// Default IntGrid value when checking cells outside of level bounds
    #[serde(rename = "outOfBoundsValue")]
    out_of_bounds_value: Option<i64>,

    /// Rule pattern (size x size)
    #[serde(rename = "pattern")]
    pattern: Vec<i64>,

    /// If TRUE, enable Perlin filtering to only apply rule on specific random area
    #[serde(rename = "perlinActive")]
    perlin_active: bool,

    #[serde(rename = "perlinOctaves")]
    perlin_octaves: f64,

    #[serde(rename = "perlinScale")]
    perlin_scale: f64,

    #[serde(rename = "perlinSeed")]
    perlin_seed: f64,

    /// X pivot of a tile stamp (0-1)
    #[serde(rename = "pivotX")]
    pivot_x: f64,

    /// Y pivot of a tile stamp (0-1)
    #[serde(rename = "pivotY")]
    pivot_y: f64,

    /// Pattern width & height. Should only be 1,3,5 or 7.
    #[serde(rename = "size")]
    size: i64,

    /// Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value.
    #[serde(rename = "tileIds")]
    tile_ids: Vec<i64>,

    /// Defines how tileIds array is used Possible values: `Single`, `Stamp`
    #[serde(rename = "tileMode")]
    tile_mode: TileMode,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,

    /// X cell coord modulo
    #[serde(rename = "xModulo")]
    x_modulo: i64,

    /// Y cell coord modulo
    #[serde(rename = "yModulo")]
    y_modulo: i64,
}

/// IntGrid value definition
#[derive(Serialize, Deserialize)]
pub struct IntGridValueDefinition {
    #[serde(rename = "color")]
    color: String,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: Option<String>,

    /// The IntGrid value itself
    #[serde(rename = "value")]
    value: i64,
}

/// The `Tileset` definition is the most important part among project definitions. It
/// contains some extra informations about each integrated tileset. If you only had to parse
/// one definition section, that would be the one.
#[derive(Serialize, Deserialize)]
pub struct TilesetDefinition {
    /// Grid-based height
    #[serde(rename = "__cHei")]
    c_hei: i64,

    /// Grid-based width
    #[serde(rename = "__cWid")]
    c_wid: i64,

    /// The following data is used internally for various optimizations. It's always synced with
    /// source image changes.
    #[serde(rename = "cachedPixelData")]
    cached_pixel_data: Option<HashMap<String, Option<serde_json::Value>>>,

    /// An array of custom tile metadata
    #[serde(rename = "customData")]
    custom_data: Vec<HashMap<String, Option<serde_json::Value>>>,

    /// Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1
    /// element per Enum value, which contains an array of all Tile IDs that are tagged with it.
    #[serde(rename = "enumTags")]
    enum_tags: Vec<HashMap<String, Option<serde_json::Value>>>,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Distance in pixels from image borders
    #[serde(rename = "padding")]
    padding: i64,

    /// Image height in pixels
    #[serde(rename = "pxHei")]
    px_hei: i64,

    /// Image width in pixels
    #[serde(rename = "pxWid")]
    px_wid: i64,

    /// Path to the source file, relative to the current project JSON file
    #[serde(rename = "relPath")]
    rel_path: String,

    /// Array of group of tiles selections, only meant to be used in the editor
    #[serde(rename = "savedSelections")]
    saved_selections: Vec<HashMap<String, Option<serde_json::Value>>>,

    /// Space in pixels between all tiles
    #[serde(rename = "spacing")]
    spacing: i64,

    /// Optional Enum definition UID used for this tileset meta-data
    #[serde(rename = "tagsSourceEnumUid")]
    tags_source_enum_uid: Option<i64>,

    #[serde(rename = "tileGridSize")]
    tile_grid_size: i64,

    /// Unique Intidentifier
    #[serde(rename = "uid")]
    uid: i64,
}

/// This section contains all the level data. It can be found in 2 distinct forms, depending
/// on Project current settings:  - If "*Separate level files*" is **disabled** (default):
/// full level data is *embedded* inside the main Project JSON file, - If "*Separate level
/// files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one
/// per level). In this case, the main Project JSON file will still contain most level data,
/// except heavy sections, like the `layerInstances` array (which will be null). The
/// `externalRelPath` string points to the `ldtkl` file.  A `ldtkl` file is just a JSON file
/// containing exactly what is described below.
#[derive(Serialize, Deserialize)]
pub struct Level {
    /// Background color of the level (same as `bgColor`, except the default value is
    /// automatically used here if its value is `null`)
    #[serde(rename = "__bgColor")]
    bg_color: String,

    /// Position informations of the background image, if there is one.
    #[serde(rename = "__bgPos")]
    bg_pos: Option<LevelBackgroundPosition>,

    /// An array listing all other levels touching this one on the world map. In "linear" world
    /// layouts, this array is populated with previous/next levels in array, and `dir` depends on
    /// the linear horizontal/vertical layout.
    #[serde(rename = "__neighbours")]
    neighbours: Vec<NeighbourLevel>,

    /// Background color of the level. If `null`, the project `defaultLevelBgColor` should be
    /// used.
    #[serde(rename = "bgColor")]
    level_bg_color: Option<String>,

    /// Background image X pivot (0-1)
    #[serde(rename = "bgPivotX")]
    bg_pivot_x: f64,

    /// Background image Y pivot (0-1)
    #[serde(rename = "bgPivotY")]
    bg_pivot_y: f64,

    /// An enum defining the way the background image (if any) is positioned on the level. See
    /// `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,
    /// `Contain`, `Cover`, `CoverDirty`
    #[serde(rename = "bgPos")]
    level_bg_pos: Option<BgPos>,

    /// The *optional* relative path to the level background image.
    #[serde(rename = "bgRelPath")]
    bg_rel_path: Option<String>,

    /// This value is not null if the project option "*Save levels separately*" is enabled. In
    /// this case, this **relative** path points to the level Json file.
    #[serde(rename = "externalRelPath")]
    external_rel_path: Option<String>,

    /// An array containing this level custom field values.
    #[serde(rename = "fieldInstances")]
    field_instances: Vec<FieldInstance>,

    /// Unique String identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// An array containing all Layer instances. **IMPORTANT**: if the project option "*Save
    /// levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted
    /// in display order**: the 1st layer is the top-most and the last is behind.
    #[serde(rename = "layerInstances")]
    layer_instances: Option<Vec<LayerInstance>>,

    /// Height of the level in pixels
    #[serde(rename = "pxHei")]
    px_hei: i64,

    /// Width of the level in pixels
    #[serde(rename = "pxWid")]
    px_wid: i64,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,

    /// If TRUE, the level identifier will always automatically use the naming pattern as defined
    /// in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by
    /// user.
    #[serde(rename = "useAutoIdentifier")]
    use_auto_identifier: bool,

    /// World X coordinate in pixels
    #[serde(rename = "worldX")]
    world_x: i64,

    /// World Y coordinate in pixels
    #[serde(rename = "worldY")]
    world_y: i64,
}

/// Level background image position info
#[derive(Serialize, Deserialize)]
pub struct LevelBackgroundPosition {
    /// An array of 4 float values describing the cropped sub-rectangle of the displayed
    /// background image. This cropping happens when original is larger than the level bounds.
    /// Array format: `[ cropX, cropY, cropWidth, cropHeight ]`
    #[serde(rename = "cropRect")]
    crop_rect: Vec<f64>,

    /// An array containing the `[scaleX,scaleY]` values of the **cropped** background image,
    /// depending on `bgPos` option.
    #[serde(rename = "scale")]
    scale: Vec<f64>,

    /// An array containing the `[x,y]` pixel coordinates of the top-left corner of the
    /// **cropped** background image, depending on `bgPos` option.
    #[serde(rename = "topLeftPx")]
    top_left_px: Vec<i64>,
}

#[derive(Serialize, Deserialize)]
pub struct FieldInstance {
    /// Field definition identifier
    #[serde(rename = "__identifier")]
    identifier: String,

    /// Type of the field, such as `Int`, `Float`, `Enum(my_enum_name)`, `Bool`, etc.
    #[serde(rename = "__type")]
    field_instance_type: String,

    /// Actual value of the field instance. The value type may vary, depending on `__type`
    /// (Integer, Boolean, String etc.)<br/>  It can also be an `Array` of those same types.
    #[serde(rename = "__value")]
    value: Option<serde_json::Value>,

    /// Reference of the **Field definition** UID
    #[serde(rename = "defUid")]
    def_uid: i64,

    /// Editor internal raw values
    #[serde(rename = "realEditorValues")]
    real_editor_values: Vec<Option<serde_json::Value>>,
}

#[derive(Serialize, Deserialize)]
pub struct LayerInstance {
    /// Grid-based height
    #[serde(rename = "__cHei")]
    c_hei: i64,

    /// Grid-based width
    #[serde(rename = "__cWid")]
    c_wid: i64,

    /// Grid size
    #[serde(rename = "__gridSize")]
    grid_size: i64,

    /// Layer definition identifier
    #[serde(rename = "__identifier")]
    identifier: String,

    /// Layer opacity as Float [0-1]
    #[serde(rename = "__opacity")]
    opacity: f64,

    /// Total layer X pixel offset, including both instance and definition offsets.
    #[serde(rename = "__pxTotalOffsetX")]
    px_total_offset_x: i64,

    /// Total layer Y pixel offset, including both instance and definition offsets.
    #[serde(rename = "__pxTotalOffsetY")]
    px_total_offset_y: i64,

    /// The definition UID of corresponding Tileset, if any.
    #[serde(rename = "__tilesetDefUid")]
    tileset_def_uid: Option<i64>,

    /// The relative path to corresponding Tileset, if any.
    #[serde(rename = "__tilesetRelPath")]
    tileset_rel_path: Option<String>,

    /// Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)
    #[serde(rename = "__type")]
    layer_instance_type: String,

    /// An array containing all tiles generated by Auto-layer rules. The array is already sorted
    /// in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>
    /// Note: if multiple tiles are stacked in the same cell as the result of different rules,
    /// all tiles behind opaque ones will be discarded.
    #[serde(rename = "autoLayerTiles")]
    auto_layer_tiles: Vec<TileInstance>,

    #[serde(rename = "entityInstances")]
    entity_instances: Vec<EntityInstance>,

    #[serde(rename = "gridTiles")]
    grid_tiles: Vec<TileInstance>,

    /// **WARNING**: this deprecated value will be *removed* completely on version 0.10.0+
    /// Replaced by: `intGridCsv`
    #[serde(rename = "intGrid")]
    int_grid: Option<Vec<IntGridValueInstance>>,

    /// A list of all values in the IntGrid layer, stored from left to right, and top to bottom
    /// (ie. first row from left to right, followed by second row, etc). `0` means "empty cell"
    /// and IntGrid values start at 1. This array size is `__cWid` x `__cHei` cells.
    #[serde(rename = "intGridCsv")]
    int_grid_csv: Vec<i64>,

    /// Reference the Layer definition UID
    #[serde(rename = "layerDefUid")]
    layer_def_uid: i64,

    /// Reference to the UID of the level containing this layer instance
    #[serde(rename = "levelId")]
    level_id: i64,

    /// An Array containing the UIDs of optional rules that were enabled in this specific layer
    /// instance.
    #[serde(rename = "optionalRules")]
    optional_rules: Vec<i64>,

    /// This layer can use another tileset by overriding the tileset UID here.
    #[serde(rename = "overrideTilesetUid")]
    override_tileset_uid: Option<i64>,

    /// X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    /// the `LayerDef` optional offset, see `__pxTotalOffsetX`)
    #[serde(rename = "pxOffsetX")]
    px_offset_x: i64,

    /// Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    /// the `LayerDef` optional offset, see `__pxTotalOffsetY`)
    #[serde(rename = "pxOffsetY")]
    px_offset_y: i64,

    /// Random seed used for Auto-Layers rendering
    #[serde(rename = "seed")]
    seed: i64,

    /// Layer instance visibility
    #[serde(rename = "visible")]
    visible: bool,
}

/// This structure represents a single tile from a given Tileset.
#[derive(Serialize, Deserialize)]
pub struct TileInstance {
    /// Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>
    /// For tile-layer tiles: `[coordId]`.
    #[serde(rename = "d")]
    d: Vec<i64>,

    /// "Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>
    /// - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip
    /// only), f=2 (Y flip only), f=3 (both flips)
    #[serde(rename = "f")]
    f: i64,

    /// Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional
    /// layer offsets, if they exist!
    #[serde(rename = "px")]
    px: Vec<i64>,

    /// Pixel coordinates of the tile in the **tileset** (`[x,y]` format)
    #[serde(rename = "src")]
    src: Vec<i64>,

    /// The *Tile ID* in the corresponding tileset.
    #[serde(rename = "t")]
    t: i64,
}

#[derive(Serialize, Deserialize)]
pub struct EntityInstance {
    /// Grid-based coordinates (`[x,y]` format)
    #[serde(rename = "__grid")]
    grid: Vec<i64>,

    /// Entity definition identifier
    #[serde(rename = "__identifier")]
    identifier: String,

    /// Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity
    #[serde(rename = "__pivot")]
    pivot: Vec<f64>,

    /// Optional Tile used to display this entity (it could either be the default Entity tile, or
    /// some tile provided by a field value, like an Enum).
    #[serde(rename = "__tile")]
    tile: Option<EntityInstanceTile>,

    /// Reference of the **Entity definition** UID
    #[serde(rename = "defUid")]
    def_uid: i64,

    /// An array of all custom fields and their values.
    #[serde(rename = "fieldInstances")]
    field_instances: Vec<FieldInstance>,

    /// Entity height in pixels. For non-resizable entities, it will be the same as Entity
    /// definition.
    #[serde(rename = "height")]
    height: i64,

    /// Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget
    /// optional layer offsets, if they exist!
    #[serde(rename = "px")]
    px: Vec<i64>,

    /// Entity width in pixels. For non-resizable entities, it will be the same as Entity
    /// definition.
    #[serde(rename = "width")]
    width: i64,
}

/// Tile data in an Entity instance
#[derive(Serialize, Deserialize)]
pub struct EntityInstanceTile {
    /// An array of 4 Int values that refers to the tile in the tileset image: `[ x, y, width,
    /// height ]`
    #[serde(rename = "srcRect")]
    src_rect: Vec<i64>,

    /// Tileset ID
    #[serde(rename = "tilesetUid")]
    tileset_uid: i64,
}

/// IntGrid value instance
#[derive(Serialize, Deserialize)]
pub struct IntGridValueInstance {
    /// Coordinate ID in the layer grid
    #[serde(rename = "coordId")]
    coord_id: i64,

    /// IntGrid value
    #[serde(rename = "v")]
    v: i64,
}

/// Nearby level info
#[derive(Serialize, Deserialize)]
pub struct NeighbourLevel {
    /// A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,
    /// `e`ast).
    #[serde(rename = "dir")]
    dir: String,

    #[serde(rename = "levelUid")]
    level_uid: i64,
}

/// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,
/// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`
#[derive(Serialize, Deserialize)]
pub enum EditorDisplayMode {
    #[serde(rename = "EntityTile")]
    EntityTile,

    #[serde(rename = "Hidden")]
    Hidden,

    #[serde(rename = "NameAndValue")]
    NameAndValue,

    #[serde(rename = "PointPath")]
    PointPath,

    #[serde(rename = "PointPathLoop")]
    PointPathLoop,

    #[serde(rename = "PointStar")]
    PointStar,

    #[serde(rename = "Points")]
    Points,

    #[serde(rename = "RadiusGrid")]
    RadiusGrid,

    #[serde(rename = "RadiusPx")]
    RadiusPx,

    #[serde(rename = "ValueOnly")]
    ValueOnly,
}

/// Possible values: `Above`, `Center`, `Beneath`
#[derive(Serialize, Deserialize)]
pub enum EditorDisplayPos {
    #[serde(rename = "Above")]
    Above,

    #[serde(rename = "Beneath")]
    Beneath,

    #[serde(rename = "Center")]
    Center,
}

#[derive(Serialize, Deserialize)]
pub enum TextLanguageMode {
    #[serde(rename = "LangC")]
    LangC,

    #[serde(rename = "LangHaxe")]
    LangHaxe,

    #[serde(rename = "LangJS")]
    LangJs,

    #[serde(rename = "LangJson")]
    LangJson,

    #[serde(rename = "LangLua")]
    LangLua,

    #[serde(rename = "LangMarkdown")]
    LangMarkdown,

    #[serde(rename = "LangPython")]
    LangPython,

    #[serde(rename = "LangRuby")]
    LangRuby,

    #[serde(rename = "LangXml")]
    LangXml,
}

/// Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`
#[derive(Serialize, Deserialize)]
pub enum LimitBehavior {
    #[serde(rename = "DiscardOldOnes")]
    DiscardOldOnes,

    #[serde(rename = "MoveLastOne")]
    MoveLastOne,

    #[serde(rename = "PreventAdding")]
    PreventAdding,
}

/// If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
/// values: `PerLayer`, `PerLevel`, `PerWorld`
#[derive(Serialize, Deserialize)]
pub enum LimitScope {
    #[serde(rename = "PerLayer")]
    PerLayer,

    #[serde(rename = "PerLevel")]
    PerLevel,

    #[serde(rename = "PerWorld")]
    PerWorld,
}

/// Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`
#[derive(Serialize, Deserialize)]
pub enum RenderMode {
    #[serde(rename = "Cross")]
    Cross,

    #[serde(rename = "Ellipse")]
    Ellipse,

    #[serde(rename = "Rectangle")]
    Rectangle,

    #[serde(rename = "Tile")]
    Tile,
}

/// Possible values: `Cover`, `FitInside`, `Repeat`, `Stretch`
#[derive(Serialize, Deserialize)]
pub enum TileRenderMode {
    #[serde(rename = "Cover")]
    Cover,

    #[serde(rename = "FitInside")]
    FitInside,

    #[serde(rename = "Repeat")]
    Repeat,

    #[serde(rename = "Stretch")]
    Stretch,
}

/// Checker mode Possible values: `None`, `Horizontal`, `Vertical`
#[derive(Serialize, Deserialize)]
pub enum Checker {
    #[serde(rename = "Horizontal")]
    Horizontal,

    #[serde(rename = "None")]
    None,

    #[serde(rename = "Vertical")]
    Vertical,
}

/// Defines how tileIds array is used Possible values: `Single`, `Stamp`
#[derive(Serialize, Deserialize)]
pub enum TileMode {
    #[serde(rename = "Single")]
    Single,

    #[serde(rename = "Stamp")]
    Stamp,
}

/// Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
/// `AutoLayer`
#[derive(Serialize, Deserialize)]
pub enum Type {
    #[serde(rename = "AutoLayer")]
    AutoLayer,

    #[serde(rename = "Entities")]
    Entities,

    #[serde(rename = "IntGrid")]
    IntGrid,

    #[serde(rename = "Tiles")]
    Tiles,
}

#[derive(Serialize, Deserialize)]
pub enum Flag {
    #[serde(rename = "DiscardPreCsvIntGrid")]
    DiscardPreCsvIntGrid,

    #[serde(rename = "IgnoreBackupSuggest")]
    IgnoreBackupSuggest,
}

/// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
/// `OneImagePerLevel`
#[derive(Serialize, Deserialize)]
pub enum ImageExportMode {
    #[serde(rename = "None")]
    None,

    #[serde(rename = "OneImagePerLayer")]
    OneImagePerLayer,

    #[serde(rename = "OneImagePerLevel")]
    OneImagePerLevel,
}

#[derive(Serialize, Deserialize)]
pub enum BgPos {
    #[serde(rename = "Contain")]
    Contain,

    #[serde(rename = "Cover")]
    Cover,

    #[serde(rename = "CoverDirty")]
    CoverDirty,

    #[serde(rename = "Unscaled")]
    Unscaled,
}

/// An enum that describes how levels are organized in this project (ie. linearly or in a 2D
/// space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`
#[derive(Serialize, Deserialize)]
pub enum WorldLayout {
    #[serde(rename = "Free")]
    Free,

    #[serde(rename = "GridVania")]
    GridVania,

    #[serde(rename = "LinearHorizontal")]
    LinearHorizontal,

    #[serde(rename = "LinearVertical")]
    LinearVertical,
}
