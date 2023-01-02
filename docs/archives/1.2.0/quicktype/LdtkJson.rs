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
    /// This object is not actually used by LDtk. It ONLY exists to force explicit references to
    /// all types, to make sure QuickType finds them and integrate all of them. Otherwise,
    /// Quicktype will drop types that are not explicitely used.
    #[serde(rename = "__FORCED_REFS")]
    forced_refs: Option<ForcedRefs>,

    /// LDtk application build identifier.<br/>  This is only used to identify the LDtk version
    /// that generated this particular project file, which can be useful for specific bug fixing.
    /// Note that the build identifier is just the date of the release, so it's not unique to
    /// each user (one single global ID per LDtk public release), and as a result, completely
    /// anonymous.
    #[serde(rename = "appBuildId")]
    app_build_id: f64,

    /// Number of backup files to keep, if the `backupOnSave` is TRUE
    #[serde(rename = "backupLimit")]
    backup_limit: i64,

    /// If TRUE, an extra copy of the project will be created in a sub folder, when saving.
    #[serde(rename = "backupOnSave")]
    backup_on_save: bool,

    /// Project background color
    #[serde(rename = "bgColor")]
    bg_color: String,

    /// An array of command lines that can be ran manually by the user
    #[serde(rename = "customCommands")]
    custom_commands: Vec<LdtkCustomCommand>,

    /// Default grid size for new layers
    #[serde(rename = "defaultGridSize")]
    default_grid_size: i64,

    /// Default background color of levels
    #[serde(rename = "defaultLevelBgColor")]
    default_level_bg_color: String,

    /// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    /// It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    /// the change immediately.<br/><br/>  Default new level height
    #[serde(rename = "defaultLevelHeight")]
    default_level_height: Option<i64>,

    /// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    /// It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    /// the change immediately.<br/><br/>  Default new level width
    #[serde(rename = "defaultLevelWidth")]
    default_level_width: Option<i64>,

    /// Default X pivot (0 to 1) for new entities
    #[serde(rename = "defaultPivotX")]
    default_pivot_x: f64,

    /// Default Y pivot (0 to 1) for new entities
    #[serde(rename = "defaultPivotY")]
    default_pivot_y: f64,

    /// A structure containing all the definitions of this project
    #[serde(rename = "defs")]
    defs: Definitions,

    /// If TRUE, the exported PNGs will include the level background (color or image).
    #[serde(rename = "exportLevelBg")]
    export_level_bg: bool,

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
    /// values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`,
    /// `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`
    #[serde(rename = "flags")]
    flags: Vec<Flag>,

    /// Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
    /// values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
    #[serde(rename = "identifierStyle")]
    identifier_style: IdentifierStyle,

    /// Unique project identifier
    #[serde(rename = "iid")]
    iid: String,

    /// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
    /// `OneImagePerLevel`, `LayersAndLevels`
    #[serde(rename = "imageExportMode")]
    image_export_mode: ImageExportMode,

    /// File format version
    #[serde(rename = "jsonVersion")]
    json_version: String,

    /// The default naming convention for level identifiers.
    #[serde(rename = "levelNamePattern")]
    level_name_pattern: String,

    /// All levels. The order of this array is only relevant in `LinearHorizontal` and
    /// `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should
    /// refer to the `worldX`,`worldY` coordinates of each Level.
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

    /// If TRUE, a very simplified will be generated on saving, for quicker & easier engine
    /// integration.
    #[serde(rename = "simplifiedExport")]
    simplified_export: bool,

    /// This optional description is used by LDtk Samples to show up some informations and
    /// instructions.
    #[serde(rename = "tutorialDesc")]
    tutorial_desc: Option<String>,

    /// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    /// It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    /// the change immediately.<br/><br/>  Height of the world grid in pixels.
    #[serde(rename = "worldGridHeight")]
    world_grid_height: Option<i64>,

    /// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    /// It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    /// the change immediately.<br/><br/>  Width of the world grid in pixels.
    #[serde(rename = "worldGridWidth")]
    world_grid_width: Option<i64>,

    /// **WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    /// It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    /// the change immediately.<br/><br/>  An enum that describes how levels are organized in
    /// this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,
    /// `GridVania`, `LinearHorizontal`, `LinearVertical`
    #[serde(rename = "worldLayout")]
    world_layout: Option<WorldLayout>,

    /// This array is not used yet in current LDtk version (so, for now, it's always
    /// empty).<br/><br/>In a later update, it will be possible to have multiple Worlds in a
    /// single project, each containing multiple Levels.<br/><br/>What will change when "Multiple
    /// worlds" support will be added to LDtk:<br/><br/> - in current version, a LDtk project
    /// file can only contain a single world with multiple levels in it. In this case, levels and
    /// world layout related settings are stored in the root of the JSON.<br/> - after the
    /// "Multiple worlds" update, there will be a `worlds` array in root, each world containing
    /// levels and layout settings. Basically, it's pretty much only about moving the `levels`
    /// array to the `worlds` array, along with world layout related values (eg. `worldGridWidth`
    /// etc).<br/><br/>If you want to start supporting this future update easily, please refer to
    /// this documentation: https://github.com/deepnight/ldtk/issues/231
    #[serde(rename = "worlds")]
    worlds: Vec<World>,
}

#[derive(Serialize, Deserialize)]
pub struct LdtkCustomCommand {
    #[serde(rename = "command")]
    command: String,

    /// Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`
    #[serde(rename = "when")]
    when: When,
}

/// If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
/// the `defs` section, as it contains data that are mostly important to the editor. To keep
/// you away from the `defs` section and avoid some unnecessary JSON parsing, important data
/// from definitions is often duplicated in fields prefixed with a double underscore (eg.
/// `__identifier` or `__type`).  The 2 only definition types you might need here are
/// **Tilesets** and **Enums**.
///
/// A structure containing all the definitions of this project
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

    /// User defined unique identifier
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

    /// An array of 4 dimensions for the up/right/down/left borders (in this order) when using
    /// 9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then
    /// this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling
    #[serde(rename = "nineSliceBorders")]
    nine_slice_borders: Vec<i64>,

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

    /// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    /// by: `tileRect`
    #[serde(rename = "tileId")]
    tile_id: Option<i64>,

    #[serde(rename = "tileOpacity")]
    tile_opacity: f64,

    /// An object representing a rectangle from an existing Tileset
    #[serde(rename = "tileRect")]
    tile_rect: Option<TilesetRectangle>,

    /// An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
    /// values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
    /// `FullSizeUncropped`, `NineSlice`
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
    /// Human readable value type. Possible values: `Int, Float, String, Bool, Color,
    /// ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this
    /// field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if
    /// you enable the advanced option **Use Multilines type**, you will have "*Multilines*"
    /// instead of "*String*" when relevant.
    #[serde(rename = "__type")]
    field_definition_type: String,

    /// Optional list of accepted file extensions for FilePath value type. Includes the dot:
    /// `.ext`
    #[serde(rename = "acceptFileTypes")]
    accept_file_types: Option<Vec<String>>,

    /// Possible values: `Any`, `OnlySame`, `OnlyTags`
    #[serde(rename = "allowedRefs")]
    allowed_refs: AllowedRefs,

    #[serde(rename = "allowedRefTags")]
    allowed_ref_tags: Vec<String>,

    #[serde(rename = "allowOutOfLevelRef")]
    allow_out_of_level_ref: bool,

    /// Array max length
    #[serde(rename = "arrayMaxLength")]
    array_max_length: Option<i64>,

    /// Array min length
    #[serde(rename = "arrayMinLength")]
    array_min_length: Option<i64>,

    #[serde(rename = "autoChainRef")]
    auto_chain_ref: bool,

    /// TRUE if the value can be null. For arrays, TRUE means it can contain null values
    /// (exception: array of Points can't have null values).
    #[serde(rename = "canBeNull")]
    can_be_null: bool,

    /// Default value if selected value is null or invalid.
    #[serde(rename = "defaultOverride")]
    default_override: Option<serde_json::Value>,

    /// User defined documentation for this field to provide help/tips to level designers about
    /// accepted values.
    #[serde(rename = "doc")]
    doc: Option<String>,

    #[serde(rename = "editorAlwaysShow")]
    editor_always_show: bool,

    #[serde(rename = "editorCutLongValues")]
    editor_cut_long_values: bool,

    /// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,
    /// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
    /// `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
    /// `RefLinkBetweenCenters`
    #[serde(rename = "editorDisplayMode")]
    editor_display_mode: EditorDisplayMode,

    /// Possible values: `Above`, `Center`, `Beneath`
    #[serde(rename = "editorDisplayPos")]
    editor_display_pos: EditorDisplayPos,

    /// Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
    #[serde(rename = "editorLinkStyle")]
    editor_link_style: EditorLinkStyle,

    #[serde(rename = "editorShowInWorld")]
    editor_show_in_world: bool,

    #[serde(rename = "editorTextPrefix")]
    editor_text_prefix: Option<String>,

    #[serde(rename = "editorTextSuffix")]
    editor_text_suffix: Option<String>,

    /// User defined unique identifier
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

    #[serde(rename = "symmetricalRef")]
    symmetrical_ref: bool,

    /// Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,
    /// `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
    #[serde(rename = "textLanguageMode")]
    text_language_mode: Option<TextLanguageMode>,

    /// UID of the tileset used for a Tile
    #[serde(rename = "tilesetUid")]
    tileset_uid: Option<i64>,

    /// Internal enum representing the possible field types. Possible values: F_Int, F_Float,
    /// F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
    #[serde(rename = "type")]
    purple_type: String,

    /// Unique Int identifier
    #[serde(rename = "uid")]
    uid: i64,

    /// If TRUE, the color associated with this field will override the Entity or Level default
    /// color in the editor UI. For Enum fields, this would be the color associated to their
    /// values.
    #[serde(rename = "useForSmartColor")]
    use_for_smart_color: bool,
}

/// This object represents a custom sub rectangle in a Tileset image.
#[derive(Serialize, Deserialize)]
pub struct TilesetRectangle {
    /// Height in pixels
    #[serde(rename = "h")]
    h: i64,

    /// UID of the tileset
    #[serde(rename = "tilesetUid")]
    tileset_uid: i64,

    /// Width in pixels
    #[serde(rename = "w")]
    w: i64,

    /// X pixels coordinate of the top-left corner in the Tileset image
    #[serde(rename = "x")]
    x: i64,

    /// Y pixels coordinate of the top-left corner in the Tileset image
    #[serde(rename = "y")]
    y: i64,
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

    /// User defined unique identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// An array of user-defined tags to organize the Enums
    #[serde(rename = "tags")]
    tags: Vec<String>,

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

    /// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    /// by: `tilesetDefUid`
    #[serde(rename = "autoTilesetDefUid")]
    auto_tileset_def_uid: Option<i64>,

    /// Allow editor selections when the layer is not currently active.
    #[serde(rename = "canSelectWhenInactive")]
    can_select_when_inactive: bool,

    /// Opacity of the layer (0 to 1.0)
    #[serde(rename = "displayOpacity")]
    display_opacity: f64,

    /// An array of tags to forbid some Entities in this layer
    #[serde(rename = "excludedTags")]
    excluded_tags: Vec<String>,

    /// Width and height of the grid in pixels
    #[serde(rename = "gridSize")]
    grid_size: i64,

    /// Height of the optional "guide" grid in pixels
    #[serde(rename = "guideGridHei")]
    guide_grid_hei: i64,

    /// Width of the optional "guide" grid in pixels
    #[serde(rename = "guideGridWid")]
    guide_grid_wid: i64,

    #[serde(rename = "hideFieldsWhenInactive")]
    hide_fields_when_inactive: bool,

    /// Hide the layer from the list on the side of the editor view.
    #[serde(rename = "hideInList")]
    hide_in_list: bool,

    /// User defined unique identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Alpha of this layer when it is not the active one.
    #[serde(rename = "inactiveOpacity")]
    inactive_opacity: f64,

    /// An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the
    /// array order is not related to actual IntGrid values! As user can re-order IntGrid values
    /// freely, you may value "2" before value "1" in this array.
    #[serde(rename = "intGridValues")]
    int_grid_values: Vec<IntGridValueDefinition>,

    /// Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling
    /// speed of this layer, creating a fake 3D (parallax) effect.
    #[serde(rename = "parallaxFactorX")]
    parallax_factor_x: f64,

    /// Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed
    /// of this layer, creating a fake 3D (parallax) effect.
    #[serde(rename = "parallaxFactorY")]
    parallax_factor_y: f64,

    /// If true (default), a layer with a parallax factor will also be scaled up/down accordingly.
    #[serde(rename = "parallaxScaling")]
    parallax_scaling: bool,

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

    /// Reference to the default Tileset UID being used by this layer definition.<br/>
    /// **WARNING**: some layer *instances* might use a different tileset. So most of the time,
    /// you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:
    /// since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
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

    /// *This field was removed in 1.0.0 and should no longer be used.*
    #[serde(rename = "collapsed")]
    collapsed: Option<bool>,

    #[serde(rename = "isOptional")]
    is_optional: bool,

    #[serde(rename = "name")]
    name: String,

    #[serde(rename = "rules")]
    rules: Vec<AutoLayerRuleDefinition>,

    #[serde(rename = "uid")]
    uid: i64,

    #[serde(rename = "usesWizard")]
    uses_wizard: bool,
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

    /// X cell start offset
    #[serde(rename = "xOffset")]
    x_offset: i64,

    /// Y cell coord modulo
    #[serde(rename = "yModulo")]
    y_modulo: i64,

    /// Y cell start offset
    #[serde(rename = "yOffset")]
    y_offset: i64,
}

/// IntGrid value definition
#[derive(Serialize, Deserialize)]
pub struct IntGridValueDefinition {
    #[serde(rename = "color")]
    color: String,

    /// User defined unique identifier
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
    custom_data: Vec<TileCustomMetadata>,

    /// If this value is set, then it means that this atlas uses an internal LDtk atlas image
    /// instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`
    #[serde(rename = "embedAtlas")]
    embed_atlas: Option<EmbedAtlas>,

    /// Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1
    /// element per Enum value, which contains an array of all Tile IDs that are tagged with it.
    #[serde(rename = "enumTags")]
    enum_tags: Vec<EnumTagValue>,

    /// User defined unique identifier
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

    /// Path to the source file, relative to the current project JSON file<br/>  It can be null
    /// if no image was provided, or when using an embed atlas.
    #[serde(rename = "relPath")]
    rel_path: Option<String>,

    /// Array of group of tiles selections, only meant to be used in the editor
    #[serde(rename = "savedSelections")]
    saved_selections: Vec<HashMap<String, Option<serde_json::Value>>>,

    /// Space in pixels between all tiles
    #[serde(rename = "spacing")]
    spacing: i64,

    /// An array of user-defined tags to organize the Tilesets
    #[serde(rename = "tags")]
    tags: Vec<String>,

    /// Optional Enum definition UID used for this tileset meta-data
    #[serde(rename = "tagsSourceEnumUid")]
    tags_source_enum_uid: Option<i64>,

    #[serde(rename = "tileGridSize")]
    tile_grid_size: i64,

    /// Unique Intidentifier
    #[serde(rename = "uid")]
    uid: i64,
}

/// In a tileset definition, user defined meta-data of a tile.
#[derive(Serialize, Deserialize)]
pub struct TileCustomMetadata {
    #[serde(rename = "data")]
    data: String,

    #[serde(rename = "tileId")]
    tile_id: i64,
}

/// In a tileset definition, enum based tag infos
#[derive(Serialize, Deserialize)]
pub struct EnumTagValue {
    #[serde(rename = "enumValueId")]
    enum_value_id: String,

    #[serde(rename = "tileIds")]
    tile_ids: Vec<i64>,
}

/// This object is not actually used by LDtk. It ONLY exists to force explicit references to
/// all types, to make sure QuickType finds them and integrate all of them. Otherwise,
/// Quicktype will drop types that are not explicitely used.
#[derive(Serialize, Deserialize)]
pub struct ForcedRefs {
    #[serde(rename = "AutoLayerRuleGroup")]
    auto_layer_rule_group: Option<AutoLayerRuleGroup>,

    #[serde(rename = "AutoRuleDef")]
    auto_rule_def: Option<AutoLayerRuleDefinition>,

    #[serde(rename = "CustomCommand")]
    custom_command: Option<LdtkCustomCommand>,

    #[serde(rename = "Definitions")]
    definitions: Option<Definitions>,

    #[serde(rename = "EntityDef")]
    entity_def: Option<EntityDefinition>,

    #[serde(rename = "EntityInstance")]
    entity_instance: Option<EntityInstance>,

    #[serde(rename = "EntityReferenceInfos")]
    entity_reference_infos: Option<FieldInstanceEntityReference>,

    #[serde(rename = "EnumDef")]
    enum_def: Option<EnumDefinition>,

    #[serde(rename = "EnumDefValues")]
    enum_def_values: Option<EnumValueDefinition>,

    #[serde(rename = "EnumTagValue")]
    enum_tag_value: Option<EnumTagValue>,

    #[serde(rename = "FieldDef")]
    field_def: Option<FieldDefinition>,

    #[serde(rename = "FieldInstance")]
    field_instance: Option<FieldInstance>,

    #[serde(rename = "GridPoint")]
    grid_point: Option<FieldInstanceGridPoint>,

    #[serde(rename = "IntGridValueDef")]
    int_grid_value_def: Option<IntGridValueDefinition>,

    #[serde(rename = "IntGridValueInstance")]
    int_grid_value_instance: Option<IntGridValueInstance>,

    #[serde(rename = "LayerDef")]
    layer_def: Option<LayerDefinition>,

    #[serde(rename = "LayerInstance")]
    layer_instance: Option<LayerInstance>,

    #[serde(rename = "Level")]
    level: Option<Level>,

    #[serde(rename = "LevelBgPosInfos")]
    level_bg_pos_infos: Option<LevelBackgroundPosition>,

    #[serde(rename = "NeighbourLevel")]
    neighbour_level: Option<NeighbourLevel>,

    #[serde(rename = "Tile")]
    tile: Option<TileInstance>,

    #[serde(rename = "TileCustomMetadata")]
    tile_custom_metadata: Option<TileCustomMetadata>,

    #[serde(rename = "TilesetDef")]
    tileset_def: Option<TilesetDefinition>,

    #[serde(rename = "TilesetRect")]
    tileset_rect: Option<TilesetRectangle>,

    #[serde(rename = "World")]
    world: Option<World>,
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

    /// The entity "smart" color, guessed from either Entity definition, or one its field
    /// instances.
    #[serde(rename = "__smartColor")]
    smart_color: String,

    /// Array of tags defined in this Entity definition
    #[serde(rename = "__tags")]
    tags: Vec<String>,

    /// Optional TilesetRect used to display this entity (it could either be the default Entity
    /// tile, or some tile provided by a field value, like an Enum).
    #[serde(rename = "__tile")]
    tile: Option<TilesetRectangle>,

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

    /// Unique instance identifier
    #[serde(rename = "iid")]
    iid: String,

    /// Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget
    /// optional layer offsets, if they exist!
    #[serde(rename = "px")]
    px: Vec<i64>,

    /// Entity width in pixels. For non-resizable entities, it will be the same as Entity
    /// definition.
    #[serde(rename = "width")]
    width: i64,
}

#[derive(Serialize, Deserialize)]
pub struct FieldInstance {
    /// Field definition identifier
    #[serde(rename = "__identifier")]
    identifier: String,

    /// Optional TilesetRect used to display this field (this can be the field own Tile, or some
    /// other Tile guessed from the value, like an Enum).
    #[serde(rename = "__tile")]
    tile: Option<TilesetRectangle>,

    /// Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,
    /// etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have
    /// "*Multilines*" instead of "*String*" when relevant.
    #[serde(rename = "__type")]
    field_instance_type: String,

    /// Actual value of the field instance. The value type varies, depending on `__type`:<br/>
    /// - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you
    /// just get the actual value with the expected type.<br/>   - For **Color**, the value is an
    /// hexadecimal string using "#rrggbb" format.<br/>   - For **Enum**, the value is a String
    /// representing the selected enum value.<br/>   - For **Point**, the value is a
    /// [GridPoint](#ldtk-GridPoint) object.<br/>   - For **Tile**, the value is a
    /// [TilesetRect](#ldtk-TilesetRect) object.<br/>   - For **EntityRef**, the value is an
    /// [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>  If the field is an
    /// array, then this `__value` will also be a JSON array.
    #[serde(rename = "__value")]
    value: Option<serde_json::Value>,

    /// Reference of the **Field definition** UID
    #[serde(rename = "defUid")]
    def_uid: i64,

    /// Editor internal raw values
    #[serde(rename = "realEditorValues")]
    real_editor_values: Vec<Option<serde_json::Value>>,
}

/// This object is used in Field Instances to describe an EntityRef value.
#[derive(Serialize, Deserialize)]
pub struct FieldInstanceEntityReference {
    /// IID of the refered EntityInstance
    #[serde(rename = "entityIid")]
    entity_iid: String,

    /// IID of the LayerInstance containing the refered EntityInstance
    #[serde(rename = "layerIid")]
    layer_iid: String,

    /// IID of the Level containing the refered EntityInstance
    #[serde(rename = "levelIid")]
    level_iid: String,

    /// IID of the World containing the refered EntityInstance
    #[serde(rename = "worldIid")]
    world_iid: String,
}

/// This object is just a grid-based coordinate used in Field values.
#[derive(Serialize, Deserialize)]
pub struct FieldInstanceGridPoint {
    /// X grid-based coordinate
    #[serde(rename = "cx")]
    cx: i64,

    /// Y grid-based coordinate
    #[serde(rename = "cy")]
    cy: i64,
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

    /// Unique layer instance identifier
    #[serde(rename = "iid")]
    iid: String,

    /// **WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced
    /// by: `intGridCsv`
    #[serde(rename = "intGrid")]
    int_grid: Option<Vec<IntGridValueInstance>>,

    /// A list of all values in the IntGrid layer, stored in CSV format (Comma Separated
    /// Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to
    /// right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values
    /// start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.
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

    /// An array listing all other levels touching this one on the world map.<br/>  Only relevant
    /// for world layouts where level spatial positioning is manual (ie. GridVania, Free). For
    /// Horizontal and Vertical layouts, this array is always empty.
    #[serde(rename = "__neighbours")]
    neighbours: Vec<NeighbourLevel>,

    /// The "guessed" color for this level in the editor, decided using either the background
    /// color or an existing custom field.
    #[serde(rename = "__smartColor")]
    smart_color: String,

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

    /// User defined unique identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Unique instance identifier
    #[serde(rename = "iid")]
    iid: String,

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

    /// Index that represents the "depth" of the level in the world. Default is 0, greater means
    /// "above", lower means "below".<br/>  This value is mostly used for display only and is
    /// intended to make stacking of levels easier to manage.
    #[serde(rename = "worldDepth")]
    world_depth: i64,

    /// World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    /// positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    /// value is always -1 here.
    #[serde(rename = "worldX")]
    world_x: i64,

    /// World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    /// positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    /// value is always -1 here.
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

/// Nearby level info
#[derive(Serialize, Deserialize)]
pub struct NeighbourLevel {
    /// A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,
    /// `e`ast).
    #[serde(rename = "dir")]
    dir: String,

    /// Neighbour Instance Identifier
    #[serde(rename = "levelIid")]
    level_iid: String,

    /// **WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    /// by: `levelIid`
    #[serde(rename = "levelUid")]
    level_uid: Option<i64>,
}

/// **IMPORTANT**: this type is not used *yet* in current LDtk version. It's only presented
/// here as a preview of a planned feature.  A World contains multiple levels, and it has its
/// own layout settings.
#[derive(Serialize, Deserialize)]
pub struct World {
    /// Default new level height
    #[serde(rename = "defaultLevelHeight")]
    default_level_height: i64,

    /// Default new level width
    #[serde(rename = "defaultLevelWidth")]
    default_level_width: i64,

    /// User defined unique identifier
    #[serde(rename = "identifier")]
    identifier: String,

    /// Unique instance identifer
    #[serde(rename = "iid")]
    iid: String,

    /// All levels from this world. The order of this array is only relevant in
    /// `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).
    /// Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
    #[serde(rename = "levels")]
    levels: Vec<Level>,

    /// Height of the world grid in pixels.
    #[serde(rename = "worldGridHeight")]
    world_grid_height: i64,

    /// Width of the world grid in pixels.
    #[serde(rename = "worldGridWidth")]
    world_grid_width: i64,

    /// An enum that describes how levels are organized in this project (ie. linearly or in a 2D
    /// space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`
    #[serde(rename = "worldLayout")]
    world_layout: Option<WorldLayout>,
}

/// Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`
#[derive(Serialize, Deserialize)]
pub enum When {
    #[serde(rename = "AfterLoad")]
    AfterLoad,

    #[serde(rename = "AfterSave")]
    AfterSave,

    #[serde(rename = "BeforeSave")]
    BeforeSave,

    #[serde(rename = "Manual")]
    Manual,
}

/// Possible values: `Any`, `OnlySame`, `OnlyTags`
#[derive(Serialize, Deserialize)]
pub enum AllowedRefs {
    #[serde(rename = "Any")]
    Any,

    #[serde(rename = "OnlySame")]
    OnlySame,

    #[serde(rename = "OnlyTags")]
    OnlyTags,
}

/// Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `Points`,
/// `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
/// `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
/// `RefLinkBetweenCenters`
#[derive(Serialize, Deserialize)]
pub enum EditorDisplayMode {
    #[serde(rename = "ArrayCountNoLabel")]
    ArrayCountNoLabel,

    #[serde(rename = "ArrayCountWithLabel")]
    ArrayCountWithLabel,

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

    #[serde(rename = "RefLinkBetweenCenters")]
    RefLinkBetweenCenters,

    #[serde(rename = "RefLinkBetweenPivots")]
    RefLinkBetweenPivots,

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

/// Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`
#[derive(Serialize, Deserialize)]
pub enum EditorLinkStyle {
    #[serde(rename = "ArrowsLine")]
    ArrowsLine,

    #[serde(rename = "CurvedArrow")]
    CurvedArrow,

    #[serde(rename = "DashedLine")]
    DashedLine,

    #[serde(rename = "StraightArrow")]
    StraightArrow,

    #[serde(rename = "ZigZag")]
    ZigZag,
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

    #[serde(rename = "LangLog")]
    LangLog,

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

/// An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
/// values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
/// `FullSizeUncropped`, `NineSlice`
#[derive(Serialize, Deserialize)]
pub enum TileRenderMode {
    #[serde(rename = "Cover")]
    Cover,

    #[serde(rename = "FitInside")]
    FitInside,

    #[serde(rename = "FullSizeCropped")]
    FullSizeCropped,

    #[serde(rename = "FullSizeUncropped")]
    FullSizeUncropped,

    #[serde(rename = "NineSlice")]
    NineSlice,

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
pub enum EmbedAtlas {
    #[serde(rename = "LdtkIcons")]
    LdtkIcons,
}

#[derive(Serialize, Deserialize)]
pub enum Flag {
    #[serde(rename = "DiscardPreCsvIntGrid")]
    DiscardPreCsvIntGrid,

    #[serde(rename = "ExportPreCsvIntGridFormat")]
    ExportPreCsvIntGridFormat,

    #[serde(rename = "IgnoreBackupSuggest")]
    IgnoreBackupSuggest,

    #[serde(rename = "MultiWorlds")]
    MultiWorlds,

    #[serde(rename = "PrependIndexToLevelFileNames")]
    PrependIndexToLevelFileNames,

    #[serde(rename = "UseMultilinesType")]
    UseMultilinesType,
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

/// Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
/// values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
#[derive(Serialize, Deserialize)]
pub enum IdentifierStyle {
    #[serde(rename = "Capitalize")]
    Capitalize,

    #[serde(rename = "Free")]
    Free,

    #[serde(rename = "Lowercase")]
    Lowercase,

    #[serde(rename = "Uppercase")]
    Uppercase,
}

/// "Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
/// `OneImagePerLevel`, `LayersAndLevels`
#[derive(Serialize, Deserialize)]
pub enum ImageExportMode {
    #[serde(rename = "LayersAndLevels")]
    LayersAndLevels,

    #[serde(rename = "None")]
    None,

    #[serde(rename = "OneImagePerLayer")]
    OneImagePerLayer,

    #[serde(rename = "OneImagePerLevel")]
    OneImagePerLevel,
}
