from enum import Enum
from typing import Any, List, Optional, Dict, TypeVar, Type, Callable, cast


T = TypeVar("T")
EnumT = TypeVar("EnumT", bound=Enum)


def from_str(x: Any) -> str:
    assert isinstance(x, str)
    return x


def to_enum(c: Type[EnumT], x: Any) -> EnumT:
    assert isinstance(x, c)
    return x.value


def from_none(x: Any) -> Any:
    assert x is None
    return x


def from_list(f: Callable[[Any], T], x: Any) -> List[T]:
    assert isinstance(x, list)
    return [f(y) for y in x]


def from_union(fs, x):
    for f in fs:
        try:
            return f(x)
        except:
            pass
    assert False


def from_int(x: Any) -> int:
    assert isinstance(x, int) and not isinstance(x, bool)
    return x


def from_bool(x: Any) -> bool:
    assert isinstance(x, bool)
    return x


def from_float(x: Any) -> float:
    assert isinstance(x, (float, int)) and not isinstance(x, bool)
    return float(x)


def to_float(x: Any) -> float:
    assert isinstance(x, float)
    return x


def to_class(c: Type[T], x: Any) -> dict:
    assert isinstance(x, c)
    return cast(Any, x).to_dict()


def from_dict(f: Callable[[Any], T], x: Any) -> Dict[str, T]:
    assert isinstance(x, dict)
    return { k: f(v) for (k, v) in x.items() }


class When(Enum):
    """Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`"""
    AFTER_LOAD = "AfterLoad"
    AFTER_SAVE = "AfterSave"
    BEFORE_SAVE = "BeforeSave"
    MANUAL = "Manual"


class LdtkCustomCommand:
    command: str
    """Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`"""
    when: When

    def __init__(self, command: str, when: When) -> None:
        self.command = command
        self.when = when

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkCustomCommand':
        assert isinstance(obj, dict)
        command = from_str(obj.get("command"))
        when = When(obj.get("when"))
        return LdtkCustomCommand(command, when)

    def to_dict(self) -> dict:
        result: dict = {}
        result["command"] = from_str(self.command)
        result["when"] = to_enum(When, self.when)
        return result


class AllowedRefs(Enum):
    """Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`"""
    ANY = "Any"
    ONLY_SAME = "OnlySame"
    ONLY_SPECIFIC_ENTITY = "OnlySpecificEntity"
    ONLY_TAGS = "OnlyTags"


class EditorDisplayMode(Enum):
    """Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`,
    `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
    `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
    `RefLinkBetweenCenters`
    """
    ARRAY_COUNT_NO_LABEL = "ArrayCountNoLabel"
    ARRAY_COUNT_WITH_LABEL = "ArrayCountWithLabel"
    ENTITY_TILE = "EntityTile"
    HIDDEN = "Hidden"
    LEVEL_TILE = "LevelTile"
    NAME_AND_VALUE = "NameAndValue"
    POINTS = "Points"
    POINT_PATH = "PointPath"
    POINT_PATH_LOOP = "PointPathLoop"
    POINT_STAR = "PointStar"
    RADIUS_GRID = "RadiusGrid"
    RADIUS_PX = "RadiusPx"
    REF_LINK_BETWEEN_CENTERS = "RefLinkBetweenCenters"
    REF_LINK_BETWEEN_PIVOTS = "RefLinkBetweenPivots"
    VALUE_ONLY = "ValueOnly"


class EditorDisplayPos(Enum):
    """Possible values: `Above`, `Center`, `Beneath`"""
    ABOVE = "Above"
    BENEATH = "Beneath"
    CENTER = "Center"


class EditorLinkStyle(Enum):
    """Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`"""
    ARROWS_LINE = "ArrowsLine"
    CURVED_ARROW = "CurvedArrow"
    DASHED_LINE = "DashedLine"
    STRAIGHT_ARROW = "StraightArrow"
    ZIG_ZAG = "ZigZag"


class TextLanguageMode(Enum):
    LANG_C = "LangC"
    LANG_HAXE = "LangHaxe"
    LANG_JS = "LangJS"
    LANG_JSON = "LangJson"
    LANG_LOG = "LangLog"
    LANG_LUA = "LangLua"
    LANG_MARKDOWN = "LangMarkdown"
    LANG_PYTHON = "LangPython"
    LANG_RUBY = "LangRuby"
    LANG_XML = "LangXml"


class FieldDefinition:
    """This section is mostly only intended for the LDtk editor app itself. You can safely
    ignore it.
    """
    """Human readable value type. Possible values: `Int, Float, String, Bool, Color,
    ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this
    field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if
    you enable the advanced option **Use Multilines type**, you will have "*Multilines*"
    instead of "*String*" when relevant.
    """
    type: str
    """Optional list of accepted file extensions for FilePath value type. Includes the dot:
    `.ext`
    """
    accept_file_types: Optional[List[str]]
    """Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`"""
    allowed_refs: AllowedRefs
    allowed_refs_entity_uid: Optional[int]
    allowed_ref_tags: List[str]
    allow_out_of_level_ref: bool
    """Array max length"""
    array_max_length: Optional[int]
    """Array min length"""
    array_min_length: Optional[int]
    auto_chain_ref: bool
    """TRUE if the value can be null. For arrays, TRUE means it can contain null values
    (exception: array of Points can't have null values).
    """
    can_be_null: bool
    """Default value if selected value is null or invalid."""
    default_override: Any
    """User defined documentation for this field to provide help/tips to level designers about
    accepted values.
    """
    doc: Optional[str]
    editor_always_show: bool
    editor_cut_long_values: bool
    """Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`,
    `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
    `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
    `RefLinkBetweenCenters`
    """
    editor_display_mode: EditorDisplayMode
    """Possible values: `Above`, `Center`, `Beneath`"""
    editor_display_pos: EditorDisplayPos
    editor_display_scale: float
    """Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`"""
    editor_link_style: EditorLinkStyle
    editor_show_in_world: bool
    editor_text_prefix: Optional[str]
    editor_text_suffix: Optional[str]
    """User defined unique identifier"""
    identifier: str
    """TRUE if the value is an array of multiple values"""
    is_array: bool
    """Max limit for value, if applicable"""
    max: Optional[float]
    """Min limit for value, if applicable"""
    min: Optional[float]
    """Optional regular expression that needs to be matched to accept values. Expected format:
    `/some_reg_ex/g`, with optional "i" flag.
    """
    regex: Optional[str]
    symmetrical_ref: bool
    """Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,
    `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
    """
    text_language_mode: Optional[TextLanguageMode]
    """UID of the tileset used for a Tile"""
    tileset_uid: Optional[int]
    """Internal enum representing the possible field types. Possible values: F_Int, F_Float,
    F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
    """
    field_definition_type: str
    """Unique Int identifier"""
    uid: int
    """If TRUE, the color associated with this field will override the Entity or Level default
    color in the editor UI. For Enum fields, this would be the color associated to their
    values.
    """
    use_for_smart_color: bool

    def __init__(self, type: str, accept_file_types: Optional[List[str]], allowed_refs: AllowedRefs, allowed_refs_entity_uid: Optional[int], allowed_ref_tags: List[str], allow_out_of_level_ref: bool, array_max_length: Optional[int], array_min_length: Optional[int], auto_chain_ref: bool, can_be_null: bool, default_override: Any, doc: Optional[str], editor_always_show: bool, editor_cut_long_values: bool, editor_display_mode: EditorDisplayMode, editor_display_pos: EditorDisplayPos, editor_display_scale: float, editor_link_style: EditorLinkStyle, editor_show_in_world: bool, editor_text_prefix: Optional[str], editor_text_suffix: Optional[str], identifier: str, is_array: bool, max: Optional[float], min: Optional[float], regex: Optional[str], symmetrical_ref: bool, text_language_mode: Optional[TextLanguageMode], tileset_uid: Optional[int], field_definition_type: str, uid: int, use_for_smart_color: bool) -> None:
        self.type = type
        self.accept_file_types = accept_file_types
        self.allowed_refs = allowed_refs
        self.allowed_refs_entity_uid = allowed_refs_entity_uid
        self.allowed_ref_tags = allowed_ref_tags
        self.allow_out_of_level_ref = allow_out_of_level_ref
        self.array_max_length = array_max_length
        self.array_min_length = array_min_length
        self.auto_chain_ref = auto_chain_ref
        self.can_be_null = can_be_null
        self.default_override = default_override
        self.doc = doc
        self.editor_always_show = editor_always_show
        self.editor_cut_long_values = editor_cut_long_values
        self.editor_display_mode = editor_display_mode
        self.editor_display_pos = editor_display_pos
        self.editor_display_scale = editor_display_scale
        self.editor_link_style = editor_link_style
        self.editor_show_in_world = editor_show_in_world
        self.editor_text_prefix = editor_text_prefix
        self.editor_text_suffix = editor_text_suffix
        self.identifier = identifier
        self.is_array = is_array
        self.max = max
        self.min = min
        self.regex = regex
        self.symmetrical_ref = symmetrical_ref
        self.text_language_mode = text_language_mode
        self.tileset_uid = tileset_uid
        self.field_definition_type = field_definition_type
        self.uid = uid
        self.use_for_smart_color = use_for_smart_color

    @staticmethod
    def from_dict(obj: Any) -> 'FieldDefinition':
        assert isinstance(obj, dict)
        type = from_str(obj.get("__type"))
        accept_file_types = from_union([from_none, lambda x: from_list(from_str, x)], obj.get("acceptFileTypes"))
        allowed_refs = AllowedRefs(obj.get("allowedRefs"))
        allowed_refs_entity_uid = from_union([from_none, from_int], obj.get("allowedRefsEntityUid"))
        allowed_ref_tags = from_list(from_str, obj.get("allowedRefTags"))
        allow_out_of_level_ref = from_bool(obj.get("allowOutOfLevelRef"))
        array_max_length = from_union([from_none, from_int], obj.get("arrayMaxLength"))
        array_min_length = from_union([from_none, from_int], obj.get("arrayMinLength"))
        auto_chain_ref = from_bool(obj.get("autoChainRef"))
        can_be_null = from_bool(obj.get("canBeNull"))
        default_override = obj.get("defaultOverride")
        doc = from_union([from_none, from_str], obj.get("doc"))
        editor_always_show = from_bool(obj.get("editorAlwaysShow"))
        editor_cut_long_values = from_bool(obj.get("editorCutLongValues"))
        editor_display_mode = EditorDisplayMode(obj.get("editorDisplayMode"))
        editor_display_pos = EditorDisplayPos(obj.get("editorDisplayPos"))
        editor_display_scale = from_float(obj.get("editorDisplayScale"))
        editor_link_style = EditorLinkStyle(obj.get("editorLinkStyle"))
        editor_show_in_world = from_bool(obj.get("editorShowInWorld"))
        editor_text_prefix = from_union([from_none, from_str], obj.get("editorTextPrefix"))
        editor_text_suffix = from_union([from_none, from_str], obj.get("editorTextSuffix"))
        identifier = from_str(obj.get("identifier"))
        is_array = from_bool(obj.get("isArray"))
        max = from_union([from_none, from_float], obj.get("max"))
        min = from_union([from_none, from_float], obj.get("min"))
        regex = from_union([from_none, from_str], obj.get("regex"))
        symmetrical_ref = from_bool(obj.get("symmetricalRef"))
        text_language_mode = from_union([from_none, TextLanguageMode], obj.get("textLanguageMode"))
        tileset_uid = from_union([from_none, from_int], obj.get("tilesetUid"))
        field_definition_type = from_str(obj.get("type"))
        uid = from_int(obj.get("uid"))
        use_for_smart_color = from_bool(obj.get("useForSmartColor"))
        return FieldDefinition(type, accept_file_types, allowed_refs, allowed_refs_entity_uid, allowed_ref_tags, allow_out_of_level_ref, array_max_length, array_min_length, auto_chain_ref, can_be_null, default_override, doc, editor_always_show, editor_cut_long_values, editor_display_mode, editor_display_pos, editor_display_scale, editor_link_style, editor_show_in_world, editor_text_prefix, editor_text_suffix, identifier, is_array, max, min, regex, symmetrical_ref, text_language_mode, tileset_uid, field_definition_type, uid, use_for_smart_color)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__type"] = from_str(self.type)
        if self.accept_file_types is not None:
            result["acceptFileTypes"] = from_union([from_none, lambda x: from_list(from_str, x)], self.accept_file_types)
        result["allowedRefs"] = to_enum(AllowedRefs, self.allowed_refs)
        if self.allowed_refs_entity_uid is not None:
            result["allowedRefsEntityUid"] = from_union([from_none, from_int], self.allowed_refs_entity_uid)
        result["allowedRefTags"] = from_list(from_str, self.allowed_ref_tags)
        result["allowOutOfLevelRef"] = from_bool(self.allow_out_of_level_ref)
        if self.array_max_length is not None:
            result["arrayMaxLength"] = from_union([from_none, from_int], self.array_max_length)
        if self.array_min_length is not None:
            result["arrayMinLength"] = from_union([from_none, from_int], self.array_min_length)
        result["autoChainRef"] = from_bool(self.auto_chain_ref)
        result["canBeNull"] = from_bool(self.can_be_null)
        if self.default_override is not None:
            result["defaultOverride"] = self.default_override
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        result["editorAlwaysShow"] = from_bool(self.editor_always_show)
        result["editorCutLongValues"] = from_bool(self.editor_cut_long_values)
        result["editorDisplayMode"] = to_enum(EditorDisplayMode, self.editor_display_mode)
        result["editorDisplayPos"] = to_enum(EditorDisplayPos, self.editor_display_pos)
        result["editorDisplayScale"] = to_float(self.editor_display_scale)
        result["editorLinkStyle"] = to_enum(EditorLinkStyle, self.editor_link_style)
        result["editorShowInWorld"] = from_bool(self.editor_show_in_world)
        if self.editor_text_prefix is not None:
            result["editorTextPrefix"] = from_union([from_none, from_str], self.editor_text_prefix)
        if self.editor_text_suffix is not None:
            result["editorTextSuffix"] = from_union([from_none, from_str], self.editor_text_suffix)
        result["identifier"] = from_str(self.identifier)
        result["isArray"] = from_bool(self.is_array)
        if self.max is not None:
            result["max"] = from_union([from_none, to_float], self.max)
        if self.min is not None:
            result["min"] = from_union([from_none, to_float], self.min)
        if self.regex is not None:
            result["regex"] = from_union([from_none, from_str], self.regex)
        result["symmetricalRef"] = from_bool(self.symmetrical_ref)
        if self.text_language_mode is not None:
            result["textLanguageMode"] = from_union([from_none, lambda x: to_enum(TextLanguageMode, x)], self.text_language_mode)
        if self.tileset_uid is not None:
            result["tilesetUid"] = from_union([from_none, from_int], self.tileset_uid)
        result["type"] = from_str(self.field_definition_type)
        result["uid"] = from_int(self.uid)
        result["useForSmartColor"] = from_bool(self.use_for_smart_color)
        return result


class LimitBehavior(Enum):
    """Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`"""
    DISCARD_OLD_ONES = "DiscardOldOnes"
    MOVE_LAST_ONE = "MoveLastOne"
    PREVENT_ADDING = "PreventAdding"


class LimitScope(Enum):
    """If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
    values: `PerLayer`, `PerLevel`, `PerWorld`
    """
    PER_LAYER = "PerLayer"
    PER_LEVEL = "PerLevel"
    PER_WORLD = "PerWorld"


class RenderMode(Enum):
    """Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`"""
    CROSS = "Cross"
    ELLIPSE = "Ellipse"
    RECTANGLE = "Rectangle"
    TILE = "Tile"


class TilesetRectangle:
    """This object represents a custom sub rectangle in a Tileset image."""
    """Height in pixels"""
    h: int
    """UID of the tileset"""
    tileset_uid: int
    """Width in pixels"""
    w: int
    """X pixels coordinate of the top-left corner in the Tileset image"""
    x: int
    """Y pixels coordinate of the top-left corner in the Tileset image"""
    y: int

    def __init__(self, h: int, tileset_uid: int, w: int, x: int, y: int) -> None:
        self.h = h
        self.tileset_uid = tileset_uid
        self.w = w
        self.x = x
        self.y = y

    @staticmethod
    def from_dict(obj: Any) -> 'TilesetRectangle':
        assert isinstance(obj, dict)
        h = from_int(obj.get("h"))
        tileset_uid = from_int(obj.get("tilesetUid"))
        w = from_int(obj.get("w"))
        x = from_int(obj.get("x"))
        y = from_int(obj.get("y"))
        return TilesetRectangle(h, tileset_uid, w, x, y)

    def to_dict(self) -> dict:
        result: dict = {}
        result["h"] = from_int(self.h)
        result["tilesetUid"] = from_int(self.tileset_uid)
        result["w"] = from_int(self.w)
        result["x"] = from_int(self.x)
        result["y"] = from_int(self.y)
        return result


class TileRenderMode(Enum):
    """An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
    values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
    `FullSizeUncropped`, `NineSlice`
    """
    COVER = "Cover"
    FIT_INSIDE = "FitInside"
    FULL_SIZE_CROPPED = "FullSizeCropped"
    FULL_SIZE_UNCROPPED = "FullSizeUncropped"
    NINE_SLICE = "NineSlice"
    REPEAT = "Repeat"
    STRETCH = "Stretch"


class EntityDefinition:
    """Base entity color"""
    color: str
    """User defined documentation for this element to provide help/tips to level designers."""
    doc: Optional[str]
    """If enabled, all instances of this entity will be listed in the project "Table of content"
    object.
    """
    export_to_toc: bool
    """Array of field definitions"""
    field_defs: List[FieldDefinition]
    fill_opacity: float
    """Pixel height"""
    height: int
    hollow: bool
    """User defined unique identifier"""
    identifier: str
    """Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height
    will keep the same aspect ratio as the definition.
    """
    keep_aspect_ratio: bool
    """Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`"""
    limit_behavior: LimitBehavior
    """If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
    values: `PerLayer`, `PerLevel`, `PerWorld`
    """
    limit_scope: LimitScope
    line_opacity: float
    """Max instances count"""
    max_count: int
    """An array of 4 dimensions for the up/right/down/left borders (in this order) when using
    9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then
    this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling
    """
    nine_slice_borders: List[int]
    """Pivot X coordinate (from 0 to 1.0)"""
    pivot_x: float
    """Pivot Y coordinate (from 0 to 1.0)"""
    pivot_y: float
    """Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`"""
    render_mode: RenderMode
    """If TRUE, the entity instances will be resizable horizontally"""
    resizable_x: bool
    """If TRUE, the entity instances will be resizable vertically"""
    resizable_y: bool
    """Display entity name in editor"""
    show_name: bool
    """An array of strings that classifies this entity"""
    tags: List[str]
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `tileRect`
    """
    tile_id: Optional[int]
    tile_opacity: float
    """An object representing a rectangle from an existing Tileset"""
    tile_rect: Optional[TilesetRectangle]
    """An enum describing how the the Entity tile is rendered inside the Entity bounds. Possible
    values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
    `FullSizeUncropped`, `NineSlice`
    """
    tile_render_mode: TileRenderMode
    """Tileset ID used for optional tile display"""
    tileset_id: Optional[int]
    """Unique Int identifier"""
    uid: int
    """Pixel width"""
    width: int

    def __init__(self, color: str, doc: Optional[str], export_to_toc: bool, field_defs: List[FieldDefinition], fill_opacity: float, height: int, hollow: bool, identifier: str, keep_aspect_ratio: bool, limit_behavior: LimitBehavior, limit_scope: LimitScope, line_opacity: float, max_count: int, nine_slice_borders: List[int], pivot_x: float, pivot_y: float, render_mode: RenderMode, resizable_x: bool, resizable_y: bool, show_name: bool, tags: List[str], tile_id: Optional[int], tile_opacity: float, tile_rect: Optional[TilesetRectangle], tile_render_mode: TileRenderMode, tileset_id: Optional[int], uid: int, width: int) -> None:
        self.color = color
        self.doc = doc
        self.export_to_toc = export_to_toc
        self.field_defs = field_defs
        self.fill_opacity = fill_opacity
        self.height = height
        self.hollow = hollow
        self.identifier = identifier
        self.keep_aspect_ratio = keep_aspect_ratio
        self.limit_behavior = limit_behavior
        self.limit_scope = limit_scope
        self.line_opacity = line_opacity
        self.max_count = max_count
        self.nine_slice_borders = nine_slice_borders
        self.pivot_x = pivot_x
        self.pivot_y = pivot_y
        self.render_mode = render_mode
        self.resizable_x = resizable_x
        self.resizable_y = resizable_y
        self.show_name = show_name
        self.tags = tags
        self.tile_id = tile_id
        self.tile_opacity = tile_opacity
        self.tile_rect = tile_rect
        self.tile_render_mode = tile_render_mode
        self.tileset_id = tileset_id
        self.uid = uid
        self.width = width

    @staticmethod
    def from_dict(obj: Any) -> 'EntityDefinition':
        assert isinstance(obj, dict)
        color = from_str(obj.get("color"))
        doc = from_union([from_none, from_str], obj.get("doc"))
        export_to_toc = from_bool(obj.get("exportToToc"))
        field_defs = from_list(FieldDefinition.from_dict, obj.get("fieldDefs"))
        fill_opacity = from_float(obj.get("fillOpacity"))
        height = from_int(obj.get("height"))
        hollow = from_bool(obj.get("hollow"))
        identifier = from_str(obj.get("identifier"))
        keep_aspect_ratio = from_bool(obj.get("keepAspectRatio"))
        limit_behavior = LimitBehavior(obj.get("limitBehavior"))
        limit_scope = LimitScope(obj.get("limitScope"))
        line_opacity = from_float(obj.get("lineOpacity"))
        max_count = from_int(obj.get("maxCount"))
        nine_slice_borders = from_list(from_int, obj.get("nineSliceBorders"))
        pivot_x = from_float(obj.get("pivotX"))
        pivot_y = from_float(obj.get("pivotY"))
        render_mode = RenderMode(obj.get("renderMode"))
        resizable_x = from_bool(obj.get("resizableX"))
        resizable_y = from_bool(obj.get("resizableY"))
        show_name = from_bool(obj.get("showName"))
        tags = from_list(from_str, obj.get("tags"))
        tile_id = from_union([from_none, from_int], obj.get("tileId"))
        tile_opacity = from_float(obj.get("tileOpacity"))
        tile_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("tileRect"))
        tile_render_mode = TileRenderMode(obj.get("tileRenderMode"))
        tileset_id = from_union([from_none, from_int], obj.get("tilesetId"))
        uid = from_int(obj.get("uid"))
        width = from_int(obj.get("width"))
        return EntityDefinition(color, doc, export_to_toc, field_defs, fill_opacity, height, hollow, identifier, keep_aspect_ratio, limit_behavior, limit_scope, line_opacity, max_count, nine_slice_borders, pivot_x, pivot_y, render_mode, resizable_x, resizable_y, show_name, tags, tile_id, tile_opacity, tile_rect, tile_render_mode, tileset_id, uid, width)

    def to_dict(self) -> dict:
        result: dict = {}
        result["color"] = from_str(self.color)
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        result["exportToToc"] = from_bool(self.export_to_toc)
        result["fieldDefs"] = from_list(lambda x: to_class(FieldDefinition, x), self.field_defs)
        result["fillOpacity"] = to_float(self.fill_opacity)
        result["height"] = from_int(self.height)
        result["hollow"] = from_bool(self.hollow)
        result["identifier"] = from_str(self.identifier)
        result["keepAspectRatio"] = from_bool(self.keep_aspect_ratio)
        result["limitBehavior"] = to_enum(LimitBehavior, self.limit_behavior)
        result["limitScope"] = to_enum(LimitScope, self.limit_scope)
        result["lineOpacity"] = to_float(self.line_opacity)
        result["maxCount"] = from_int(self.max_count)
        result["nineSliceBorders"] = from_list(from_int, self.nine_slice_borders)
        result["pivotX"] = to_float(self.pivot_x)
        result["pivotY"] = to_float(self.pivot_y)
        result["renderMode"] = to_enum(RenderMode, self.render_mode)
        result["resizableX"] = from_bool(self.resizable_x)
        result["resizableY"] = from_bool(self.resizable_y)
        result["showName"] = from_bool(self.show_name)
        result["tags"] = from_list(from_str, self.tags)
        if self.tile_id is not None:
            result["tileId"] = from_union([from_none, from_int], self.tile_id)
        result["tileOpacity"] = to_float(self.tile_opacity)
        if self.tile_rect is not None:
            result["tileRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile_rect)
        result["tileRenderMode"] = to_enum(TileRenderMode, self.tile_render_mode)
        if self.tileset_id is not None:
            result["tilesetId"] = from_union([from_none, from_int], self.tileset_id)
        result["uid"] = from_int(self.uid)
        result["width"] = from_int(self.width)
        return result


class EnumValueDefinition:
    """**WARNING**: this deprecated value will be *removed* completely on version 1.4.0+
    Replaced by: `tileRect`
    """
    tile_src_rect: Optional[List[int]]
    """Optional color"""
    color: int
    """Enum value"""
    id: str
    """**WARNING**: this deprecated value will be *removed* completely on version 1.4.0+
    Replaced by: `tileRect`
    """
    tile_id: Optional[int]
    """Optional tileset rectangle to represents this value"""
    tile_rect: Optional[TilesetRectangle]

    def __init__(self, tile_src_rect: Optional[List[int]], color: int, id: str, tile_id: Optional[int], tile_rect: Optional[TilesetRectangle]) -> None:
        self.tile_src_rect = tile_src_rect
        self.color = color
        self.id = id
        self.tile_id = tile_id
        self.tile_rect = tile_rect

    @staticmethod
    def from_dict(obj: Any) -> 'EnumValueDefinition':
        assert isinstance(obj, dict)
        tile_src_rect = from_union([from_none, lambda x: from_list(from_int, x)], obj.get("__tileSrcRect"))
        color = from_int(obj.get("color"))
        id = from_str(obj.get("id"))
        tile_id = from_union([from_none, from_int], obj.get("tileId"))
        tile_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("tileRect"))
        return EnumValueDefinition(tile_src_rect, color, id, tile_id, tile_rect)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.tile_src_rect is not None:
            result["__tileSrcRect"] = from_union([from_none, lambda x: from_list(from_int, x)], self.tile_src_rect)
        result["color"] = from_int(self.color)
        result["id"] = from_str(self.id)
        if self.tile_id is not None:
            result["tileId"] = from_union([from_none, from_int], self.tile_id)
        if self.tile_rect is not None:
            result["tileRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile_rect)
        return result


class EnumDefinition:
    external_file_checksum: Optional[str]
    """Relative path to the external file providing this Enum"""
    external_rel_path: Optional[str]
    """Tileset UID if provided"""
    icon_tileset_uid: Optional[int]
    """User defined unique identifier"""
    identifier: str
    """An array of user-defined tags to organize the Enums"""
    tags: List[str]
    """Unique Int identifier"""
    uid: int
    """All possible enum values, with their optional Tile infos."""
    values: List[EnumValueDefinition]

    def __init__(self, external_file_checksum: Optional[str], external_rel_path: Optional[str], icon_tileset_uid: Optional[int], identifier: str, tags: List[str], uid: int, values: List[EnumValueDefinition]) -> None:
        self.external_file_checksum = external_file_checksum
        self.external_rel_path = external_rel_path
        self.icon_tileset_uid = icon_tileset_uid
        self.identifier = identifier
        self.tags = tags
        self.uid = uid
        self.values = values

    @staticmethod
    def from_dict(obj: Any) -> 'EnumDefinition':
        assert isinstance(obj, dict)
        external_file_checksum = from_union([from_none, from_str], obj.get("externalFileChecksum"))
        external_rel_path = from_union([from_none, from_str], obj.get("externalRelPath"))
        icon_tileset_uid = from_union([from_none, from_int], obj.get("iconTilesetUid"))
        identifier = from_str(obj.get("identifier"))
        tags = from_list(from_str, obj.get("tags"))
        uid = from_int(obj.get("uid"))
        values = from_list(EnumValueDefinition.from_dict, obj.get("values"))
        return EnumDefinition(external_file_checksum, external_rel_path, icon_tileset_uid, identifier, tags, uid, values)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.external_file_checksum is not None:
            result["externalFileChecksum"] = from_union([from_none, from_str], self.external_file_checksum)
        if self.external_rel_path is not None:
            result["externalRelPath"] = from_union([from_none, from_str], self.external_rel_path)
        if self.icon_tileset_uid is not None:
            result["iconTilesetUid"] = from_union([from_none, from_int], self.icon_tileset_uid)
        result["identifier"] = from_str(self.identifier)
        result["tags"] = from_list(from_str, self.tags)
        result["uid"] = from_int(self.uid)
        result["values"] = from_list(lambda x: to_class(EnumValueDefinition, x), self.values)
        return result


class Checker(Enum):
    """Checker mode Possible values: `None`, `Horizontal`, `Vertical`"""
    HORIZONTAL = "Horizontal"
    NONE = "None"
    VERTICAL = "Vertical"


class TileMode(Enum):
    """Defines how tileIds array is used Possible values: `Single`, `Stamp`"""
    SINGLE = "Single"
    STAMP = "Stamp"


class AutoLayerRuleDefinition:
    """This complex section isn't meant to be used by game devs at all, as these rules are
    completely resolved internally by the editor before any saving. You should just ignore
    this part.
    """
    """If FALSE, the rule effect isn't applied, and no tiles are generated."""
    active: bool
    """When TRUE, the rule will prevent other rules to be applied in the same cell if it matches
    (TRUE by default).
    """
    break_on_match: bool
    """Chances for this rule to be applied (0 to 1)"""
    chance: float
    """Checker mode Possible values: `None`, `Horizontal`, `Vertical`"""
    checker: Checker
    """If TRUE, allow rule to be matched by flipping its pattern horizontally"""
    flip_x: bool
    """If TRUE, allow rule to be matched by flipping its pattern vertically"""
    flip_y: bool
    """Default IntGrid value when checking cells outside of level bounds"""
    out_of_bounds_value: Optional[int]
    """Rule pattern (size x size)"""
    pattern: List[int]
    """If TRUE, enable Perlin filtering to only apply rule on specific random area"""
    perlin_active: bool
    perlin_octaves: float
    perlin_scale: float
    perlin_seed: float
    """X pivot of a tile stamp (0-1)"""
    pivot_x: float
    """Y pivot of a tile stamp (0-1)"""
    pivot_y: float
    """Pattern width & height. Should only be 1,3,5 or 7."""
    size: int
    """Array of all the tile IDs. They are used randomly or as stamps, based on `tileMode` value."""
    tile_ids: List[int]
    """Defines how tileIds array is used Possible values: `Single`, `Stamp`"""
    tile_mode: TileMode
    """Max random offset for X tile pos"""
    tile_random_x_max: int
    """Min random offset for X tile pos"""
    tile_random_x_min: int
    """Max random offset for Y tile pos"""
    tile_random_y_max: int
    """Min random offset for Y tile pos"""
    tile_random_y_min: int
    """Tile X offset"""
    tile_x_offset: int
    """Tile Y offset"""
    tile_y_offset: int
    """Unique Int identifier"""
    uid: int
    """X cell coord modulo"""
    x_modulo: int
    """X cell start offset"""
    x_offset: int
    """Y cell coord modulo"""
    y_modulo: int
    """Y cell start offset"""
    y_offset: int

    def __init__(self, active: bool, break_on_match: bool, chance: float, checker: Checker, flip_x: bool, flip_y: bool, out_of_bounds_value: Optional[int], pattern: List[int], perlin_active: bool, perlin_octaves: float, perlin_scale: float, perlin_seed: float, pivot_x: float, pivot_y: float, size: int, tile_ids: List[int], tile_mode: TileMode, tile_random_x_max: int, tile_random_x_min: int, tile_random_y_max: int, tile_random_y_min: int, tile_x_offset: int, tile_y_offset: int, uid: int, x_modulo: int, x_offset: int, y_modulo: int, y_offset: int) -> None:
        self.active = active
        self.break_on_match = break_on_match
        self.chance = chance
        self.checker = checker
        self.flip_x = flip_x
        self.flip_y = flip_y
        self.out_of_bounds_value = out_of_bounds_value
        self.pattern = pattern
        self.perlin_active = perlin_active
        self.perlin_octaves = perlin_octaves
        self.perlin_scale = perlin_scale
        self.perlin_seed = perlin_seed
        self.pivot_x = pivot_x
        self.pivot_y = pivot_y
        self.size = size
        self.tile_ids = tile_ids
        self.tile_mode = tile_mode
        self.tile_random_x_max = tile_random_x_max
        self.tile_random_x_min = tile_random_x_min
        self.tile_random_y_max = tile_random_y_max
        self.tile_random_y_min = tile_random_y_min
        self.tile_x_offset = tile_x_offset
        self.tile_y_offset = tile_y_offset
        self.uid = uid
        self.x_modulo = x_modulo
        self.x_offset = x_offset
        self.y_modulo = y_modulo
        self.y_offset = y_offset

    @staticmethod
    def from_dict(obj: Any) -> 'AutoLayerRuleDefinition':
        assert isinstance(obj, dict)
        active = from_bool(obj.get("active"))
        break_on_match = from_bool(obj.get("breakOnMatch"))
        chance = from_float(obj.get("chance"))
        checker = Checker(obj.get("checker"))
        flip_x = from_bool(obj.get("flipX"))
        flip_y = from_bool(obj.get("flipY"))
        out_of_bounds_value = from_union([from_none, from_int], obj.get("outOfBoundsValue"))
        pattern = from_list(from_int, obj.get("pattern"))
        perlin_active = from_bool(obj.get("perlinActive"))
        perlin_octaves = from_float(obj.get("perlinOctaves"))
        perlin_scale = from_float(obj.get("perlinScale"))
        perlin_seed = from_float(obj.get("perlinSeed"))
        pivot_x = from_float(obj.get("pivotX"))
        pivot_y = from_float(obj.get("pivotY"))
        size = from_int(obj.get("size"))
        tile_ids = from_list(from_int, obj.get("tileIds"))
        tile_mode = TileMode(obj.get("tileMode"))
        tile_random_x_max = from_int(obj.get("tileRandomXMax"))
        tile_random_x_min = from_int(obj.get("tileRandomXMin"))
        tile_random_y_max = from_int(obj.get("tileRandomYMax"))
        tile_random_y_min = from_int(obj.get("tileRandomYMin"))
        tile_x_offset = from_int(obj.get("tileXOffset"))
        tile_y_offset = from_int(obj.get("tileYOffset"))
        uid = from_int(obj.get("uid"))
        x_modulo = from_int(obj.get("xModulo"))
        x_offset = from_int(obj.get("xOffset"))
        y_modulo = from_int(obj.get("yModulo"))
        y_offset = from_int(obj.get("yOffset"))
        return AutoLayerRuleDefinition(active, break_on_match, chance, checker, flip_x, flip_y, out_of_bounds_value, pattern, perlin_active, perlin_octaves, perlin_scale, perlin_seed, pivot_x, pivot_y, size, tile_ids, tile_mode, tile_random_x_max, tile_random_x_min, tile_random_y_max, tile_random_y_min, tile_x_offset, tile_y_offset, uid, x_modulo, x_offset, y_modulo, y_offset)

    def to_dict(self) -> dict:
        result: dict = {}
        result["active"] = from_bool(self.active)
        result["breakOnMatch"] = from_bool(self.break_on_match)
        result["chance"] = to_float(self.chance)
        result["checker"] = to_enum(Checker, self.checker)
        result["flipX"] = from_bool(self.flip_x)
        result["flipY"] = from_bool(self.flip_y)
        if self.out_of_bounds_value is not None:
            result["outOfBoundsValue"] = from_union([from_none, from_int], self.out_of_bounds_value)
        result["pattern"] = from_list(from_int, self.pattern)
        result["perlinActive"] = from_bool(self.perlin_active)
        result["perlinOctaves"] = to_float(self.perlin_octaves)
        result["perlinScale"] = to_float(self.perlin_scale)
        result["perlinSeed"] = to_float(self.perlin_seed)
        result["pivotX"] = to_float(self.pivot_x)
        result["pivotY"] = to_float(self.pivot_y)
        result["size"] = from_int(self.size)
        result["tileIds"] = from_list(from_int, self.tile_ids)
        result["tileMode"] = to_enum(TileMode, self.tile_mode)
        result["tileRandomXMax"] = from_int(self.tile_random_x_max)
        result["tileRandomXMin"] = from_int(self.tile_random_x_min)
        result["tileRandomYMax"] = from_int(self.tile_random_y_max)
        result["tileRandomYMin"] = from_int(self.tile_random_y_min)
        result["tileXOffset"] = from_int(self.tile_x_offset)
        result["tileYOffset"] = from_int(self.tile_y_offset)
        result["uid"] = from_int(self.uid)
        result["xModulo"] = from_int(self.x_modulo)
        result["xOffset"] = from_int(self.x_offset)
        result["yModulo"] = from_int(self.y_modulo)
        result["yOffset"] = from_int(self.y_offset)
        return result


class AutoLayerRuleGroup:
    active: bool
    """*This field was removed in 1.0.0 and should no longer be used.*"""
    collapsed: Optional[bool]
    is_optional: bool
    name: str
    rules: List[AutoLayerRuleDefinition]
    uid: int
    uses_wizard: bool

    def __init__(self, active: bool, collapsed: Optional[bool], is_optional: bool, name: str, rules: List[AutoLayerRuleDefinition], uid: int, uses_wizard: bool) -> None:
        self.active = active
        self.collapsed = collapsed
        self.is_optional = is_optional
        self.name = name
        self.rules = rules
        self.uid = uid
        self.uses_wizard = uses_wizard

    @staticmethod
    def from_dict(obj: Any) -> 'AutoLayerRuleGroup':
        assert isinstance(obj, dict)
        active = from_bool(obj.get("active"))
        collapsed = from_union([from_none, from_bool], obj.get("collapsed"))
        is_optional = from_bool(obj.get("isOptional"))
        name = from_str(obj.get("name"))
        rules = from_list(AutoLayerRuleDefinition.from_dict, obj.get("rules"))
        uid = from_int(obj.get("uid"))
        uses_wizard = from_bool(obj.get("usesWizard"))
        return AutoLayerRuleGroup(active, collapsed, is_optional, name, rules, uid, uses_wizard)

    def to_dict(self) -> dict:
        result: dict = {}
        result["active"] = from_bool(self.active)
        if self.collapsed is not None:
            result["collapsed"] = from_union([from_none, from_bool], self.collapsed)
        result["isOptional"] = from_bool(self.is_optional)
        result["name"] = from_str(self.name)
        result["rules"] = from_list(lambda x: to_class(AutoLayerRuleDefinition, x), self.rules)
        result["uid"] = from_int(self.uid)
        result["usesWizard"] = from_bool(self.uses_wizard)
        return result


class IntGridValueDefinition:
    """IntGrid value definition"""
    color: str
    """User defined unique identifier"""
    identifier: Optional[str]
    """The IntGrid value itself"""
    value: int

    def __init__(self, color: str, identifier: Optional[str], value: int) -> None:
        self.color = color
        self.identifier = identifier
        self.value = value

    @staticmethod
    def from_dict(obj: Any) -> 'IntGridValueDefinition':
        assert isinstance(obj, dict)
        color = from_str(obj.get("color"))
        identifier = from_union([from_none, from_str], obj.get("identifier"))
        value = from_int(obj.get("value"))
        return IntGridValueDefinition(color, identifier, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["color"] = from_str(self.color)
        if self.identifier is not None:
            result["identifier"] = from_union([from_none, from_str], self.identifier)
        result["value"] = from_int(self.value)
        return result


class TypeEnum(Enum):
    """Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
    `AutoLayer`
    """
    AUTO_LAYER = "AutoLayer"
    ENTITIES = "Entities"
    INT_GRID = "IntGrid"
    TILES = "Tiles"


class LayerDefinition:
    """Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)"""
    type: str
    """Contains all the auto-layer rule definitions."""
    auto_rule_groups: List[AutoLayerRuleGroup]
    auto_source_layer_def_uid: Optional[int]
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `tilesetDefUid`
    """
    auto_tileset_def_uid: Optional[int]
    """Allow editor selections when the layer is not currently active."""
    can_select_when_inactive: bool
    """Opacity of the layer (0 to 1.0)"""
    display_opacity: float
    """User defined documentation for this element to provide help/tips to level designers."""
    doc: Optional[str]
    """An array of tags to forbid some Entities in this layer"""
    excluded_tags: List[str]
    """Width and height of the grid in pixels"""
    grid_size: int
    """Height of the optional "guide" grid in pixels"""
    guide_grid_hei: int
    """Width of the optional "guide" grid in pixels"""
    guide_grid_wid: int
    hide_fields_when_inactive: bool
    """Hide the layer from the list on the side of the editor view."""
    hide_in_list: bool
    """User defined unique identifier"""
    identifier: str
    """Alpha of this layer when it is not the active one."""
    inactive_opacity: float
    """An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the
    array order is not related to actual IntGrid values! As user can re-order IntGrid values
    freely, you may value "2" before value "1" in this array.
    """
    int_grid_values: List[IntGridValueDefinition]
    """Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling
    speed of this layer, creating a fake 3D (parallax) effect.
    """
    parallax_factor_x: float
    """Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed
    of this layer, creating a fake 3D (parallax) effect.
    """
    parallax_factor_y: float
    """If true (default), a layer with a parallax factor will also be scaled up/down accordingly."""
    parallax_scaling: bool
    """X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    optional offset)
    """
    px_offset_x: int
    """Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    optional offset)
    """
    px_offset_y: int
    """An array of tags to filter Entities that can be added to this layer"""
    required_tags: List[str]
    """If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    position the tile relatively its grid cell.
    """
    tile_pivot_x: float
    """If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    position the tile relatively its grid cell.
    """
    tile_pivot_y: float
    """Reference to the default Tileset UID being used by this layer definition.<br/>
    **WARNING**: some layer *instances* might use a different tileset. So most of the time,
    you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:
    since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
    """
    tileset_def_uid: Optional[int]
    """Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
    `AutoLayer`
    """
    layer_definition_type: TypeEnum
    """Unique Int identifier"""
    uid: int

    def __init__(self, type: str, auto_rule_groups: List[AutoLayerRuleGroup], auto_source_layer_def_uid: Optional[int], auto_tileset_def_uid: Optional[int], can_select_when_inactive: bool, display_opacity: float, doc: Optional[str], excluded_tags: List[str], grid_size: int, guide_grid_hei: int, guide_grid_wid: int, hide_fields_when_inactive: bool, hide_in_list: bool, identifier: str, inactive_opacity: float, int_grid_values: List[IntGridValueDefinition], parallax_factor_x: float, parallax_factor_y: float, parallax_scaling: bool, px_offset_x: int, px_offset_y: int, required_tags: List[str], tile_pivot_x: float, tile_pivot_y: float, tileset_def_uid: Optional[int], layer_definition_type: TypeEnum, uid: int) -> None:
        self.type = type
        self.auto_rule_groups = auto_rule_groups
        self.auto_source_layer_def_uid = auto_source_layer_def_uid
        self.auto_tileset_def_uid = auto_tileset_def_uid
        self.can_select_when_inactive = can_select_when_inactive
        self.display_opacity = display_opacity
        self.doc = doc
        self.excluded_tags = excluded_tags
        self.grid_size = grid_size
        self.guide_grid_hei = guide_grid_hei
        self.guide_grid_wid = guide_grid_wid
        self.hide_fields_when_inactive = hide_fields_when_inactive
        self.hide_in_list = hide_in_list
        self.identifier = identifier
        self.inactive_opacity = inactive_opacity
        self.int_grid_values = int_grid_values
        self.parallax_factor_x = parallax_factor_x
        self.parallax_factor_y = parallax_factor_y
        self.parallax_scaling = parallax_scaling
        self.px_offset_x = px_offset_x
        self.px_offset_y = px_offset_y
        self.required_tags = required_tags
        self.tile_pivot_x = tile_pivot_x
        self.tile_pivot_y = tile_pivot_y
        self.tileset_def_uid = tileset_def_uid
        self.layer_definition_type = layer_definition_type
        self.uid = uid

    @staticmethod
    def from_dict(obj: Any) -> 'LayerDefinition':
        assert isinstance(obj, dict)
        type = from_str(obj.get("__type"))
        auto_rule_groups = from_list(AutoLayerRuleGroup.from_dict, obj.get("autoRuleGroups"))
        auto_source_layer_def_uid = from_union([from_none, from_int], obj.get("autoSourceLayerDefUid"))
        auto_tileset_def_uid = from_union([from_none, from_int], obj.get("autoTilesetDefUid"))
        can_select_when_inactive = from_bool(obj.get("canSelectWhenInactive"))
        display_opacity = from_float(obj.get("displayOpacity"))
        doc = from_union([from_none, from_str], obj.get("doc"))
        excluded_tags = from_list(from_str, obj.get("excludedTags"))
        grid_size = from_int(obj.get("gridSize"))
        guide_grid_hei = from_int(obj.get("guideGridHei"))
        guide_grid_wid = from_int(obj.get("guideGridWid"))
        hide_fields_when_inactive = from_bool(obj.get("hideFieldsWhenInactive"))
        hide_in_list = from_bool(obj.get("hideInList"))
        identifier = from_str(obj.get("identifier"))
        inactive_opacity = from_float(obj.get("inactiveOpacity"))
        int_grid_values = from_list(IntGridValueDefinition.from_dict, obj.get("intGridValues"))
        parallax_factor_x = from_float(obj.get("parallaxFactorX"))
        parallax_factor_y = from_float(obj.get("parallaxFactorY"))
        parallax_scaling = from_bool(obj.get("parallaxScaling"))
        px_offset_x = from_int(obj.get("pxOffsetX"))
        px_offset_y = from_int(obj.get("pxOffsetY"))
        required_tags = from_list(from_str, obj.get("requiredTags"))
        tile_pivot_x = from_float(obj.get("tilePivotX"))
        tile_pivot_y = from_float(obj.get("tilePivotY"))
        tileset_def_uid = from_union([from_none, from_int], obj.get("tilesetDefUid"))
        layer_definition_type = TypeEnum(obj.get("type"))
        uid = from_int(obj.get("uid"))
        return LayerDefinition(type, auto_rule_groups, auto_source_layer_def_uid, auto_tileset_def_uid, can_select_when_inactive, display_opacity, doc, excluded_tags, grid_size, guide_grid_hei, guide_grid_wid, hide_fields_when_inactive, hide_in_list, identifier, inactive_opacity, int_grid_values, parallax_factor_x, parallax_factor_y, parallax_scaling, px_offset_x, px_offset_y, required_tags, tile_pivot_x, tile_pivot_y, tileset_def_uid, layer_definition_type, uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__type"] = from_str(self.type)
        result["autoRuleGroups"] = from_list(lambda x: to_class(AutoLayerRuleGroup, x), self.auto_rule_groups)
        if self.auto_source_layer_def_uid is not None:
            result["autoSourceLayerDefUid"] = from_union([from_none, from_int], self.auto_source_layer_def_uid)
        if self.auto_tileset_def_uid is not None:
            result["autoTilesetDefUid"] = from_union([from_none, from_int], self.auto_tileset_def_uid)
        result["canSelectWhenInactive"] = from_bool(self.can_select_when_inactive)
        result["displayOpacity"] = to_float(self.display_opacity)
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        result["excludedTags"] = from_list(from_str, self.excluded_tags)
        result["gridSize"] = from_int(self.grid_size)
        result["guideGridHei"] = from_int(self.guide_grid_hei)
        result["guideGridWid"] = from_int(self.guide_grid_wid)
        result["hideFieldsWhenInactive"] = from_bool(self.hide_fields_when_inactive)
        result["hideInList"] = from_bool(self.hide_in_list)
        result["identifier"] = from_str(self.identifier)
        result["inactiveOpacity"] = to_float(self.inactive_opacity)
        result["intGridValues"] = from_list(lambda x: to_class(IntGridValueDefinition, x), self.int_grid_values)
        result["parallaxFactorX"] = to_float(self.parallax_factor_x)
        result["parallaxFactorY"] = to_float(self.parallax_factor_y)
        result["parallaxScaling"] = from_bool(self.parallax_scaling)
        result["pxOffsetX"] = from_int(self.px_offset_x)
        result["pxOffsetY"] = from_int(self.px_offset_y)
        result["requiredTags"] = from_list(from_str, self.required_tags)
        result["tilePivotX"] = to_float(self.tile_pivot_x)
        result["tilePivotY"] = to_float(self.tile_pivot_y)
        if self.tileset_def_uid is not None:
            result["tilesetDefUid"] = from_union([from_none, from_int], self.tileset_def_uid)
        result["type"] = to_enum(TypeEnum, self.layer_definition_type)
        result["uid"] = from_int(self.uid)
        return result


class TileCustomMetadata:
    """In a tileset definition, user defined meta-data of a tile."""
    data: str
    tile_id: int

    def __init__(self, data: str, tile_id: int) -> None:
        self.data = data
        self.tile_id = tile_id

    @staticmethod
    def from_dict(obj: Any) -> 'TileCustomMetadata':
        assert isinstance(obj, dict)
        data = from_str(obj.get("data"))
        tile_id = from_int(obj.get("tileId"))
        return TileCustomMetadata(data, tile_id)

    def to_dict(self) -> dict:
        result: dict = {}
        result["data"] = from_str(self.data)
        result["tileId"] = from_int(self.tile_id)
        return result


class EmbedAtlas(Enum):
    LDTK_ICONS = "LdtkIcons"


class EnumTagValue:
    """In a tileset definition, enum based tag infos"""
    enum_value_id: str
    tile_ids: List[int]

    def __init__(self, enum_value_id: str, tile_ids: List[int]) -> None:
        self.enum_value_id = enum_value_id
        self.tile_ids = tile_ids

    @staticmethod
    def from_dict(obj: Any) -> 'EnumTagValue':
        assert isinstance(obj, dict)
        enum_value_id = from_str(obj.get("enumValueId"))
        tile_ids = from_list(from_int, obj.get("tileIds"))
        return EnumTagValue(enum_value_id, tile_ids)

    def to_dict(self) -> dict:
        result: dict = {}
        result["enumValueId"] = from_str(self.enum_value_id)
        result["tileIds"] = from_list(from_int, self.tile_ids)
        return result


class TilesetDefinition:
    """The `Tileset` definition is the most important part among project definitions. It
    contains some extra informations about each integrated tileset. If you only had to parse
    one definition section, that would be the one.
    """
    """Grid-based height"""
    c_hei: int
    """Grid-based width"""
    c_wid: int
    """The following data is used internally for various optimizations. It's always synced with
    source image changes.
    """
    cached_pixel_data: Optional[Dict[str, Any]]
    """An array of custom tile metadata"""
    custom_data: List[TileCustomMetadata]
    """If this value is set, then it means that this atlas uses an internal LDtk atlas image
    instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`
    """
    embed_atlas: Optional[EmbedAtlas]
    """Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1
    element per Enum value, which contains an array of all Tile IDs that are tagged with it.
    """
    enum_tags: List[EnumTagValue]
    """User defined unique identifier"""
    identifier: str
    """Distance in pixels from image borders"""
    padding: int
    """Image height in pixels"""
    px_hei: int
    """Image width in pixels"""
    px_wid: int
    """Path to the source file, relative to the current project JSON file<br/>  It can be null
    if no image was provided, or when using an embed atlas.
    """
    rel_path: Optional[str]
    """Array of group of tiles selections, only meant to be used in the editor"""
    saved_selections: List[Dict[str, Any]]
    """Space in pixels between all tiles"""
    spacing: int
    """An array of user-defined tags to organize the Tilesets"""
    tags: List[str]
    """Optional Enum definition UID used for this tileset meta-data"""
    tags_source_enum_uid: Optional[int]
    tile_grid_size: int
    """Unique Intidentifier"""
    uid: int

    def __init__(self, c_hei: int, c_wid: int, cached_pixel_data: Optional[Dict[str, Any]], custom_data: List[TileCustomMetadata], embed_atlas: Optional[EmbedAtlas], enum_tags: List[EnumTagValue], identifier: str, padding: int, px_hei: int, px_wid: int, rel_path: Optional[str], saved_selections: List[Dict[str, Any]], spacing: int, tags: List[str], tags_source_enum_uid: Optional[int], tile_grid_size: int, uid: int) -> None:
        self.c_hei = c_hei
        self.c_wid = c_wid
        self.cached_pixel_data = cached_pixel_data
        self.custom_data = custom_data
        self.embed_atlas = embed_atlas
        self.enum_tags = enum_tags
        self.identifier = identifier
        self.padding = padding
        self.px_hei = px_hei
        self.px_wid = px_wid
        self.rel_path = rel_path
        self.saved_selections = saved_selections
        self.spacing = spacing
        self.tags = tags
        self.tags_source_enum_uid = tags_source_enum_uid
        self.tile_grid_size = tile_grid_size
        self.uid = uid

    @staticmethod
    def from_dict(obj: Any) -> 'TilesetDefinition':
        assert isinstance(obj, dict)
        c_hei = from_int(obj.get("__cHei"))
        c_wid = from_int(obj.get("__cWid"))
        cached_pixel_data = from_union([from_none, lambda x: from_dict(lambda x: x, x)], obj.get("cachedPixelData"))
        custom_data = from_list(TileCustomMetadata.from_dict, obj.get("customData"))
        embed_atlas = from_union([from_none, EmbedAtlas], obj.get("embedAtlas"))
        enum_tags = from_list(EnumTagValue.from_dict, obj.get("enumTags"))
        identifier = from_str(obj.get("identifier"))
        padding = from_int(obj.get("padding"))
        px_hei = from_int(obj.get("pxHei"))
        px_wid = from_int(obj.get("pxWid"))
        rel_path = from_union([from_none, from_str], obj.get("relPath"))
        saved_selections = from_list(lambda x: from_dict(lambda x: x, x), obj.get("savedSelections"))
        spacing = from_int(obj.get("spacing"))
        tags = from_list(from_str, obj.get("tags"))
        tags_source_enum_uid = from_union([from_none, from_int], obj.get("tagsSourceEnumUid"))
        tile_grid_size = from_int(obj.get("tileGridSize"))
        uid = from_int(obj.get("uid"))
        return TilesetDefinition(c_hei, c_wid, cached_pixel_data, custom_data, embed_atlas, enum_tags, identifier, padding, px_hei, px_wid, rel_path, saved_selections, spacing, tags, tags_source_enum_uid, tile_grid_size, uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__cHei"] = from_int(self.c_hei)
        result["__cWid"] = from_int(self.c_wid)
        if self.cached_pixel_data is not None:
            result["cachedPixelData"] = from_union([from_none, lambda x: from_dict(lambda x: x, x)], self.cached_pixel_data)
        result["customData"] = from_list(lambda x: to_class(TileCustomMetadata, x), self.custom_data)
        if self.embed_atlas is not None:
            result["embedAtlas"] = from_union([from_none, lambda x: to_enum(EmbedAtlas, x)], self.embed_atlas)
        result["enumTags"] = from_list(lambda x: to_class(EnumTagValue, x), self.enum_tags)
        result["identifier"] = from_str(self.identifier)
        result["padding"] = from_int(self.padding)
        result["pxHei"] = from_int(self.px_hei)
        result["pxWid"] = from_int(self.px_wid)
        if self.rel_path is not None:
            result["relPath"] = from_union([from_none, from_str], self.rel_path)
        result["savedSelections"] = from_list(lambda x: from_dict(lambda x: x, x), self.saved_selections)
        result["spacing"] = from_int(self.spacing)
        result["tags"] = from_list(from_str, self.tags)
        if self.tags_source_enum_uid is not None:
            result["tagsSourceEnumUid"] = from_union([from_none, from_int], self.tags_source_enum_uid)
        result["tileGridSize"] = from_int(self.tile_grid_size)
        result["uid"] = from_int(self.uid)
        return result


class Definitions:
    """If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
    the `defs` section, as it contains data that are mostly important to the editor. To keep
    you away from the `defs` section and avoid some unnecessary JSON parsing, important data
    from definitions is often duplicated in fields prefixed with a double underscore (eg.
    `__identifier` or `__type`).  The 2 only definition types you might need here are
    **Tilesets** and **Enums**.
    
    A structure containing all the definitions of this project
    """
    """All entities definitions, including their custom fields"""
    entities: List[EntityDefinition]
    """All internal enums"""
    enums: List[EnumDefinition]
    """Note: external enums are exactly the same as `enums`, except they have a `relPath` to
    point to an external source file.
    """
    external_enums: List[EnumDefinition]
    """All layer definitions"""
    layers: List[LayerDefinition]
    """All custom fields available to all levels."""
    level_fields: List[FieldDefinition]
    """All tilesets"""
    tilesets: List[TilesetDefinition]

    def __init__(self, entities: List[EntityDefinition], enums: List[EnumDefinition], external_enums: List[EnumDefinition], layers: List[LayerDefinition], level_fields: List[FieldDefinition], tilesets: List[TilesetDefinition]) -> None:
        self.entities = entities
        self.enums = enums
        self.external_enums = external_enums
        self.layers = layers
        self.level_fields = level_fields
        self.tilesets = tilesets

    @staticmethod
    def from_dict(obj: Any) -> 'Definitions':
        assert isinstance(obj, dict)
        entities = from_list(EntityDefinition.from_dict, obj.get("entities"))
        enums = from_list(EnumDefinition.from_dict, obj.get("enums"))
        external_enums = from_list(EnumDefinition.from_dict, obj.get("externalEnums"))
        layers = from_list(LayerDefinition.from_dict, obj.get("layers"))
        level_fields = from_list(FieldDefinition.from_dict, obj.get("levelFields"))
        tilesets = from_list(TilesetDefinition.from_dict, obj.get("tilesets"))
        return Definitions(entities, enums, external_enums, layers, level_fields, tilesets)

    def to_dict(self) -> dict:
        result: dict = {}
        result["entities"] = from_list(lambda x: to_class(EntityDefinition, x), self.entities)
        result["enums"] = from_list(lambda x: to_class(EnumDefinition, x), self.enums)
        result["externalEnums"] = from_list(lambda x: to_class(EnumDefinition, x), self.external_enums)
        result["layers"] = from_list(lambda x: to_class(LayerDefinition, x), self.layers)
        result["levelFields"] = from_list(lambda x: to_class(FieldDefinition, x), self.level_fields)
        result["tilesets"] = from_list(lambda x: to_class(TilesetDefinition, x), self.tilesets)
        return result


class Flag(Enum):
    DISCARD_PRE_CSV_INT_GRID = "DiscardPreCsvIntGrid"
    EXPORT_PRE_CSV_INT_GRID_FORMAT = "ExportPreCsvIntGridFormat"
    IGNORE_BACKUP_SUGGEST = "IgnoreBackupSuggest"
    MULTI_WORLDS = "MultiWorlds"
    PREPEND_INDEX_TO_LEVEL_FILE_NAMES = "PrependIndexToLevelFileNames"
    USE_MULTILINES_TYPE = "UseMultilinesType"


class FieldInstance:
    """Field definition identifier"""
    identifier: str
    """Optional TilesetRect used to display this field (this can be the field own Tile, or some
    other Tile guessed from the value, like an Enum).
    """
    tile: Optional[TilesetRectangle]
    """Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,
    etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have
    "*Multilines*" instead of "*String*" when relevant.
    """
    type: str
    """Actual value of the field instance. The value type varies, depending on `__type`:<br/>
    - For **classic types** (ie. Integer, Float, Boolean, String, Text and FilePath), you
    just get the actual value with the expected type.<br/>   - For **Color**, the value is an
    hexadecimal string using "#rrggbb" format.<br/>   - For **Enum**, the value is a String
    representing the selected enum value.<br/>   - For **Point**, the value is a
    [GridPoint](#ldtk-GridPoint) object.<br/>   - For **Tile**, the value is a
    [TilesetRect](#ldtk-TilesetRect) object.<br/>   - For **EntityRef**, the value is an
    [EntityReferenceInfos](#ldtk-EntityReferenceInfos) object.<br/><br/>  If the field is an
    array, then this `__value` will also be a JSON array.
    """
    value: Any
    """Reference of the **Field definition** UID"""
    def_uid: int
    """Editor internal raw values"""
    real_editor_values: List[Any]

    def __init__(self, identifier: str, tile: Optional[TilesetRectangle], type: str, value: Any, def_uid: int, real_editor_values: List[Any]) -> None:
        self.identifier = identifier
        self.tile = tile
        self.type = type
        self.value = value
        self.def_uid = def_uid
        self.real_editor_values = real_editor_values

    @staticmethod
    def from_dict(obj: Any) -> 'FieldInstance':
        assert isinstance(obj, dict)
        identifier = from_str(obj.get("__identifier"))
        tile = from_union([from_none, TilesetRectangle.from_dict], obj.get("__tile"))
        type = from_str(obj.get("__type"))
        value = obj.get("__value")
        def_uid = from_int(obj.get("defUid"))
        real_editor_values = from_list(lambda x: x, obj.get("realEditorValues"))
        return FieldInstance(identifier, tile, type, value, def_uid, real_editor_values)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__identifier"] = from_str(self.identifier)
        if self.tile is not None:
            result["__tile"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile)
        result["__type"] = from_str(self.type)
        result["__value"] = self.value
        result["defUid"] = from_int(self.def_uid)
        result["realEditorValues"] = from_list(lambda x: x, self.real_editor_values)
        return result


class EntityInstance:
    """Grid-based coordinates (`[x,y]` format)"""
    grid: List[int]
    """Entity definition identifier"""
    identifier: str
    """Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity"""
    pivot: List[float]
    """The entity "smart" color, guessed from either Entity definition, or one its field
    instances.
    """
    smart_color: str
    """Array of tags defined in this Entity definition"""
    tags: List[str]
    """Optional TilesetRect used to display this entity (it could either be the default Entity
    tile, or some tile provided by a field value, like an Enum).
    """
    tile: Optional[TilesetRectangle]
    """Reference of the **Entity definition** UID"""
    def_uid: int
    """An array of all custom fields and their values."""
    field_instances: List[FieldInstance]
    """Entity height in pixels. For non-resizable entities, it will be the same as Entity
    definition.
    """
    height: int
    """Unique instance identifier"""
    iid: str
    """Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget
    optional layer offsets, if they exist!
    """
    px: List[int]
    """Entity width in pixels. For non-resizable entities, it will be the same as Entity
    definition.
    """
    width: int

    def __init__(self, grid: List[int], identifier: str, pivot: List[float], smart_color: str, tags: List[str], tile: Optional[TilesetRectangle], def_uid: int, field_instances: List[FieldInstance], height: int, iid: str, px: List[int], width: int) -> None:
        self.grid = grid
        self.identifier = identifier
        self.pivot = pivot
        self.smart_color = smart_color
        self.tags = tags
        self.tile = tile
        self.def_uid = def_uid
        self.field_instances = field_instances
        self.height = height
        self.iid = iid
        self.px = px
        self.width = width

    @staticmethod
    def from_dict(obj: Any) -> 'EntityInstance':
        assert isinstance(obj, dict)
        grid = from_list(from_int, obj.get("__grid"))
        identifier = from_str(obj.get("__identifier"))
        pivot = from_list(from_float, obj.get("__pivot"))
        smart_color = from_str(obj.get("__smartColor"))
        tags = from_list(from_str, obj.get("__tags"))
        tile = from_union([from_none, TilesetRectangle.from_dict], obj.get("__tile"))
        def_uid = from_int(obj.get("defUid"))
        field_instances = from_list(FieldInstance.from_dict, obj.get("fieldInstances"))
        height = from_int(obj.get("height"))
        iid = from_str(obj.get("iid"))
        px = from_list(from_int, obj.get("px"))
        width = from_int(obj.get("width"))
        return EntityInstance(grid, identifier, pivot, smart_color, tags, tile, def_uid, field_instances, height, iid, px, width)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__grid"] = from_list(from_int, self.grid)
        result["__identifier"] = from_str(self.identifier)
        result["__pivot"] = from_list(to_float, self.pivot)
        result["__smartColor"] = from_str(self.smart_color)
        result["__tags"] = from_list(from_str, self.tags)
        if self.tile is not None:
            result["__tile"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile)
        result["defUid"] = from_int(self.def_uid)
        result["fieldInstances"] = from_list(lambda x: to_class(FieldInstance, x), self.field_instances)
        result["height"] = from_int(self.height)
        result["iid"] = from_str(self.iid)
        result["px"] = from_list(from_int, self.px)
        result["width"] = from_int(self.width)
        return result


class ReferenceToAnEntityInstance:
    """This object describes the "location" of an Entity instance in the project worlds."""
    """IID of the refered EntityInstance"""
    entity_iid: str
    """IID of the LayerInstance containing the refered EntityInstance"""
    layer_iid: str
    """IID of the Level containing the refered EntityInstance"""
    level_iid: str
    """IID of the World containing the refered EntityInstance"""
    world_iid: str

    def __init__(self, entity_iid: str, layer_iid: str, level_iid: str, world_iid: str) -> None:
        self.entity_iid = entity_iid
        self.layer_iid = layer_iid
        self.level_iid = level_iid
        self.world_iid = world_iid

    @staticmethod
    def from_dict(obj: Any) -> 'ReferenceToAnEntityInstance':
        assert isinstance(obj, dict)
        entity_iid = from_str(obj.get("entityIid"))
        layer_iid = from_str(obj.get("layerIid"))
        level_iid = from_str(obj.get("levelIid"))
        world_iid = from_str(obj.get("worldIid"))
        return ReferenceToAnEntityInstance(entity_iid, layer_iid, level_iid, world_iid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["entityIid"] = from_str(self.entity_iid)
        result["layerIid"] = from_str(self.layer_iid)
        result["levelIid"] = from_str(self.level_iid)
        result["worldIid"] = from_str(self.world_iid)
        return result


class GridPoint:
    """This object is just a grid-based coordinate used in Field values."""
    """X grid-based coordinate"""
    cx: int
    """Y grid-based coordinate"""
    cy: int

    def __init__(self, cx: int, cy: int) -> None:
        self.cx = cx
        self.cy = cy

    @staticmethod
    def from_dict(obj: Any) -> 'GridPoint':
        assert isinstance(obj, dict)
        cx = from_int(obj.get("cx"))
        cy = from_int(obj.get("cy"))
        return GridPoint(cx, cy)

    def to_dict(self) -> dict:
        result: dict = {}
        result["cx"] = from_int(self.cx)
        result["cy"] = from_int(self.cy)
        return result


class IntGridValueInstance:
    """IntGrid value instance"""
    """Coordinate ID in the layer grid"""
    coord_id: int
    """IntGrid value"""
    v: int

    def __init__(self, coord_id: int, v: int) -> None:
        self.coord_id = coord_id
        self.v = v

    @staticmethod
    def from_dict(obj: Any) -> 'IntGridValueInstance':
        assert isinstance(obj, dict)
        coord_id = from_int(obj.get("coordId"))
        v = from_int(obj.get("v"))
        return IntGridValueInstance(coord_id, v)

    def to_dict(self) -> dict:
        result: dict = {}
        result["coordId"] = from_int(self.coord_id)
        result["v"] = from_int(self.v)
        return result


class TileInstance:
    """This structure represents a single tile from a given Tileset."""
    """Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>
    For tile-layer tiles: `[coordId]`.
    """
    d: List[int]
    """"Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>
    - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip
    only), f=2 (Y flip only), f=3 (both flips)
    """
    f: int
    """Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional
    layer offsets, if they exist!
    """
    px: List[int]
    """Pixel coordinates of the tile in the **tileset** (`[x,y]` format)"""
    src: List[int]
    """The *Tile ID* in the corresponding tileset."""
    t: int

    def __init__(self, d: List[int], f: int, px: List[int], src: List[int], t: int) -> None:
        self.d = d
        self.f = f
        self.px = px
        self.src = src
        self.t = t

    @staticmethod
    def from_dict(obj: Any) -> 'TileInstance':
        assert isinstance(obj, dict)
        d = from_list(from_int, obj.get("d"))
        f = from_int(obj.get("f"))
        px = from_list(from_int, obj.get("px"))
        src = from_list(from_int, obj.get("src"))
        t = from_int(obj.get("t"))
        return TileInstance(d, f, px, src, t)

    def to_dict(self) -> dict:
        result: dict = {}
        result["d"] = from_list(from_int, self.d)
        result["f"] = from_int(self.f)
        result["px"] = from_list(from_int, self.px)
        result["src"] = from_list(from_int, self.src)
        result["t"] = from_int(self.t)
        return result


class LayerInstance:
    """Grid-based height"""
    c_hei: int
    """Grid-based width"""
    c_wid: int
    """Grid size"""
    grid_size: int
    """Layer definition identifier"""
    identifier: str
    """Layer opacity as Float [0-1]"""
    opacity: float
    """Total layer X pixel offset, including both instance and definition offsets."""
    px_total_offset_x: int
    """Total layer Y pixel offset, including both instance and definition offsets."""
    px_total_offset_y: int
    """The definition UID of corresponding Tileset, if any."""
    tileset_def_uid: Optional[int]
    """The relative path to corresponding Tileset, if any."""
    tileset_rel_path: Optional[str]
    """Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)"""
    type: str
    """An array containing all tiles generated by Auto-layer rules. The array is already sorted
    in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>
    Note: if multiple tiles are stacked in the same cell as the result of different rules,
    all tiles behind opaque ones will be discarded.
    """
    auto_layer_tiles: List[TileInstance]
    entity_instances: List[EntityInstance]
    grid_tiles: List[TileInstance]
    """Unique layer instance identifier"""
    iid: str
    """**WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced
    by: `intGridCsv`
    """
    int_grid: Optional[List[IntGridValueInstance]]
    """A list of all values in the IntGrid layer, stored in CSV format (Comma Separated
    Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to
    right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values
    start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.
    """
    int_grid_csv: List[int]
    """Reference the Layer definition UID"""
    layer_def_uid: int
    """Reference to the UID of the level containing this layer instance"""
    level_id: int
    """An Array containing the UIDs of optional rules that were enabled in this specific layer
    instance.
    """
    optional_rules: List[int]
    """This layer can use another tileset by overriding the tileset UID here."""
    override_tileset_uid: Optional[int]
    """X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
    which contains the total offset value)
    """
    px_offset_x: int
    """Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
    which contains the total offset value)
    """
    px_offset_y: int
    """Random seed used for Auto-Layers rendering"""
    seed: int
    """Layer instance visibility"""
    visible: bool

    def __init__(self, c_hei: int, c_wid: int, grid_size: int, identifier: str, opacity: float, px_total_offset_x: int, px_total_offset_y: int, tileset_def_uid: Optional[int], tileset_rel_path: Optional[str], type: str, auto_layer_tiles: List[TileInstance], entity_instances: List[EntityInstance], grid_tiles: List[TileInstance], iid: str, int_grid: Optional[List[IntGridValueInstance]], int_grid_csv: List[int], layer_def_uid: int, level_id: int, optional_rules: List[int], override_tileset_uid: Optional[int], px_offset_x: int, px_offset_y: int, seed: int, visible: bool) -> None:
        self.c_hei = c_hei
        self.c_wid = c_wid
        self.grid_size = grid_size
        self.identifier = identifier
        self.opacity = opacity
        self.px_total_offset_x = px_total_offset_x
        self.px_total_offset_y = px_total_offset_y
        self.tileset_def_uid = tileset_def_uid
        self.tileset_rel_path = tileset_rel_path
        self.type = type
        self.auto_layer_tiles = auto_layer_tiles
        self.entity_instances = entity_instances
        self.grid_tiles = grid_tiles
        self.iid = iid
        self.int_grid = int_grid
        self.int_grid_csv = int_grid_csv
        self.layer_def_uid = layer_def_uid
        self.level_id = level_id
        self.optional_rules = optional_rules
        self.override_tileset_uid = override_tileset_uid
        self.px_offset_x = px_offset_x
        self.px_offset_y = px_offset_y
        self.seed = seed
        self.visible = visible

    @staticmethod
    def from_dict(obj: Any) -> 'LayerInstance':
        assert isinstance(obj, dict)
        c_hei = from_int(obj.get("__cHei"))
        c_wid = from_int(obj.get("__cWid"))
        grid_size = from_int(obj.get("__gridSize"))
        identifier = from_str(obj.get("__identifier"))
        opacity = from_float(obj.get("__opacity"))
        px_total_offset_x = from_int(obj.get("__pxTotalOffsetX"))
        px_total_offset_y = from_int(obj.get("__pxTotalOffsetY"))
        tileset_def_uid = from_union([from_none, from_int], obj.get("__tilesetDefUid"))
        tileset_rel_path = from_union([from_none, from_str], obj.get("__tilesetRelPath"))
        type = from_str(obj.get("__type"))
        auto_layer_tiles = from_list(TileInstance.from_dict, obj.get("autoLayerTiles"))
        entity_instances = from_list(EntityInstance.from_dict, obj.get("entityInstances"))
        grid_tiles = from_list(TileInstance.from_dict, obj.get("gridTiles"))
        iid = from_str(obj.get("iid"))
        int_grid = from_union([from_none, lambda x: from_list(IntGridValueInstance.from_dict, x)], obj.get("intGrid"))
        int_grid_csv = from_list(from_int, obj.get("intGridCsv"))
        layer_def_uid = from_int(obj.get("layerDefUid"))
        level_id = from_int(obj.get("levelId"))
        optional_rules = from_list(from_int, obj.get("optionalRules"))
        override_tileset_uid = from_union([from_none, from_int], obj.get("overrideTilesetUid"))
        px_offset_x = from_int(obj.get("pxOffsetX"))
        px_offset_y = from_int(obj.get("pxOffsetY"))
        seed = from_int(obj.get("seed"))
        visible = from_bool(obj.get("visible"))
        return LayerInstance(c_hei, c_wid, grid_size, identifier, opacity, px_total_offset_x, px_total_offset_y, tileset_def_uid, tileset_rel_path, type, auto_layer_tiles, entity_instances, grid_tiles, iid, int_grid, int_grid_csv, layer_def_uid, level_id, optional_rules, override_tileset_uid, px_offset_x, px_offset_y, seed, visible)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__cHei"] = from_int(self.c_hei)
        result["__cWid"] = from_int(self.c_wid)
        result["__gridSize"] = from_int(self.grid_size)
        result["__identifier"] = from_str(self.identifier)
        result["__opacity"] = to_float(self.opacity)
        result["__pxTotalOffsetX"] = from_int(self.px_total_offset_x)
        result["__pxTotalOffsetY"] = from_int(self.px_total_offset_y)
        if self.tileset_def_uid is not None:
            result["__tilesetDefUid"] = from_union([from_none, from_int], self.tileset_def_uid)
        if self.tileset_rel_path is not None:
            result["__tilesetRelPath"] = from_union([from_none, from_str], self.tileset_rel_path)
        result["__type"] = from_str(self.type)
        result["autoLayerTiles"] = from_list(lambda x: to_class(TileInstance, x), self.auto_layer_tiles)
        result["entityInstances"] = from_list(lambda x: to_class(EntityInstance, x), self.entity_instances)
        result["gridTiles"] = from_list(lambda x: to_class(TileInstance, x), self.grid_tiles)
        result["iid"] = from_str(self.iid)
        if self.int_grid is not None:
            result["intGrid"] = from_union([from_none, lambda x: from_list(lambda x: to_class(IntGridValueInstance, x), x)], self.int_grid)
        result["intGridCsv"] = from_list(from_int, self.int_grid_csv)
        result["layerDefUid"] = from_int(self.layer_def_uid)
        result["levelId"] = from_int(self.level_id)
        result["optionalRules"] = from_list(from_int, self.optional_rules)
        if self.override_tileset_uid is not None:
            result["overrideTilesetUid"] = from_union([from_none, from_int], self.override_tileset_uid)
        result["pxOffsetX"] = from_int(self.px_offset_x)
        result["pxOffsetY"] = from_int(self.px_offset_y)
        result["seed"] = from_int(self.seed)
        result["visible"] = from_bool(self.visible)
        return result


class LevelBackgroundPosition:
    """Level background image position info"""
    """An array of 4 float values describing the cropped sub-rectangle of the displayed
    background image. This cropping happens when original is larger than the level bounds.
    Array format: `[ cropX, cropY, cropWidth, cropHeight ]`
    """
    crop_rect: List[float]
    """An array containing the `[scaleX,scaleY]` values of the **cropped** background image,
    depending on `bgPos` option.
    """
    scale: List[float]
    """An array containing the `[x,y]` pixel coordinates of the top-left corner of the
    **cropped** background image, depending on `bgPos` option.
    """
    top_left_px: List[int]

    def __init__(self, crop_rect: List[float], scale: List[float], top_left_px: List[int]) -> None:
        self.crop_rect = crop_rect
        self.scale = scale
        self.top_left_px = top_left_px

    @staticmethod
    def from_dict(obj: Any) -> 'LevelBackgroundPosition':
        assert isinstance(obj, dict)
        crop_rect = from_list(from_float, obj.get("cropRect"))
        scale = from_list(from_float, obj.get("scale"))
        top_left_px = from_list(from_int, obj.get("topLeftPx"))
        return LevelBackgroundPosition(crop_rect, scale, top_left_px)

    def to_dict(self) -> dict:
        result: dict = {}
        result["cropRect"] = from_list(to_float, self.crop_rect)
        result["scale"] = from_list(to_float, self.scale)
        result["topLeftPx"] = from_list(from_int, self.top_left_px)
        return result


class BgPos(Enum):
    CONTAIN = "Contain"
    COVER = "Cover"
    COVER_DIRTY = "CoverDirty"
    REPEAT = "Repeat"
    UNSCALED = "Unscaled"


class NeighbourLevel:
    """Nearby level info"""
    """A single lowercase character tipping on the level location (`n`orth, `s`outh, `w`est,
    `e`ast).
    """
    dir: str
    """Neighbour Instance Identifier"""
    level_iid: str
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `levelIid`
    """
    level_uid: Optional[int]

    def __init__(self, dir: str, level_iid: str, level_uid: Optional[int]) -> None:
        self.dir = dir
        self.level_iid = level_iid
        self.level_uid = level_uid

    @staticmethod
    def from_dict(obj: Any) -> 'NeighbourLevel':
        assert isinstance(obj, dict)
        dir = from_str(obj.get("dir"))
        level_iid = from_str(obj.get("levelIid"))
        level_uid = from_union([from_none, from_int], obj.get("levelUid"))
        return NeighbourLevel(dir, level_iid, level_uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["dir"] = from_str(self.dir)
        result["levelIid"] = from_str(self.level_iid)
        if self.level_uid is not None:
            result["levelUid"] = from_union([from_none, from_int], self.level_uid)
        return result


class Level:
    """This section contains all the level data. It can be found in 2 distinct forms, depending
    on Project current settings:  - If "*Separate level files*" is **disabled** (default):
    full level data is *embedded* inside the main Project JSON file, - If "*Separate level
    files*" is **enabled**: level data is stored in *separate* standalone `.ldtkl` files (one
    per level). In this case, the main Project JSON file will still contain most level data,
    except heavy sections, like the `layerInstances` array (which will be null). The
    `externalRelPath` string points to the `ldtkl` file.  A `ldtkl` file is just a JSON file
    containing exactly what is described below.
    """
    """Background color of the level (same as `bgColor`, except the default value is
    automatically used here if its value is `null`)
    """
    bg_color: str
    """Position informations of the background image, if there is one."""
    bg_pos: Optional[LevelBackgroundPosition]
    """An array listing all other levels touching this one on the world map.<br/>  Only relevant
    for world layouts where level spatial positioning is manual (ie. GridVania, Free). For
    Horizontal and Vertical layouts, this array is always empty.
    """
    neighbours: List[NeighbourLevel]
    """The "guessed" color for this level in the editor, decided using either the background
    color or an existing custom field.
    """
    smart_color: str
    """Background color of the level. If `null`, the project `defaultLevelBgColor` should be
    used.
    """
    level_bg_color: Optional[str]
    """Background image X pivot (0-1)"""
    bg_pivot_x: float
    """Background image Y pivot (0-1)"""
    bg_pivot_y: float
    """An enum defining the way the background image (if any) is positioned on the level. See
    `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,
    `Contain`, `Cover`, `CoverDirty`, `Repeat`
    """
    level_bg_pos: Optional[BgPos]
    """The *optional* relative path to the level background image."""
    bg_rel_path: Optional[str]
    """This value is not null if the project option "*Save levels separately*" is enabled. In
    this case, this **relative** path points to the level Json file.
    """
    external_rel_path: Optional[str]
    """An array containing this level custom field values."""
    field_instances: List[FieldInstance]
    """User defined unique identifier"""
    identifier: str
    """Unique instance identifier"""
    iid: str
    """An array containing all Layer instances. **IMPORTANT**: if the project option "*Save
    levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted
    in display order**: the 1st layer is the top-most and the last is behind.
    """
    layer_instances: Optional[List[LayerInstance]]
    """Height of the level in pixels"""
    px_hei: int
    """Width of the level in pixels"""
    px_wid: int
    """Unique Int identifier"""
    uid: int
    """If TRUE, the level identifier will always automatically use the naming pattern as defined
    in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by
    user.
    """
    use_auto_identifier: bool
    """Index that represents the "depth" of the level in the world. Default is 0, greater means
    "above", lower means "below".<br/>  This value is mostly used for display only and is
    intended to make stacking of levels easier to manage.
    """
    world_depth: int
    """World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    value is always -1 here.
    """
    world_x: int
    """World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    value is always -1 here.
    """
    world_y: int

    def __init__(self, bg_color: str, bg_pos: Optional[LevelBackgroundPosition], neighbours: List[NeighbourLevel], smart_color: str, level_bg_color: Optional[str], bg_pivot_x: float, bg_pivot_y: float, level_bg_pos: Optional[BgPos], bg_rel_path: Optional[str], external_rel_path: Optional[str], field_instances: List[FieldInstance], identifier: str, iid: str, layer_instances: Optional[List[LayerInstance]], px_hei: int, px_wid: int, uid: int, use_auto_identifier: bool, world_depth: int, world_x: int, world_y: int) -> None:
        self.bg_color = bg_color
        self.bg_pos = bg_pos
        self.neighbours = neighbours
        self.smart_color = smart_color
        self.level_bg_color = level_bg_color
        self.bg_pivot_x = bg_pivot_x
        self.bg_pivot_y = bg_pivot_y
        self.level_bg_pos = level_bg_pos
        self.bg_rel_path = bg_rel_path
        self.external_rel_path = external_rel_path
        self.field_instances = field_instances
        self.identifier = identifier
        self.iid = iid
        self.layer_instances = layer_instances
        self.px_hei = px_hei
        self.px_wid = px_wid
        self.uid = uid
        self.use_auto_identifier = use_auto_identifier
        self.world_depth = world_depth
        self.world_x = world_x
        self.world_y = world_y

    @staticmethod
    def from_dict(obj: Any) -> 'Level':
        assert isinstance(obj, dict)
        bg_color = from_str(obj.get("__bgColor"))
        bg_pos = from_union([from_none, LevelBackgroundPosition.from_dict], obj.get("__bgPos"))
        neighbours = from_list(NeighbourLevel.from_dict, obj.get("__neighbours"))
        smart_color = from_str(obj.get("__smartColor"))
        level_bg_color = from_union([from_none, from_str], obj.get("bgColor"))
        bg_pivot_x = from_float(obj.get("bgPivotX"))
        bg_pivot_y = from_float(obj.get("bgPivotY"))
        level_bg_pos = from_union([from_none, BgPos], obj.get("bgPos"))
        bg_rel_path = from_union([from_none, from_str], obj.get("bgRelPath"))
        external_rel_path = from_union([from_none, from_str], obj.get("externalRelPath"))
        field_instances = from_list(FieldInstance.from_dict, obj.get("fieldInstances"))
        identifier = from_str(obj.get("identifier"))
        iid = from_str(obj.get("iid"))
        layer_instances = from_union([from_none, lambda x: from_list(LayerInstance.from_dict, x)], obj.get("layerInstances"))
        px_hei = from_int(obj.get("pxHei"))
        px_wid = from_int(obj.get("pxWid"))
        uid = from_int(obj.get("uid"))
        use_auto_identifier = from_bool(obj.get("useAutoIdentifier"))
        world_depth = from_int(obj.get("worldDepth"))
        world_x = from_int(obj.get("worldX"))
        world_y = from_int(obj.get("worldY"))
        return Level(bg_color, bg_pos, neighbours, smart_color, level_bg_color, bg_pivot_x, bg_pivot_y, level_bg_pos, bg_rel_path, external_rel_path, field_instances, identifier, iid, layer_instances, px_hei, px_wid, uid, use_auto_identifier, world_depth, world_x, world_y)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__bgColor"] = from_str(self.bg_color)
        if self.bg_pos is not None:
            result["__bgPos"] = from_union([from_none, lambda x: to_class(LevelBackgroundPosition, x)], self.bg_pos)
        result["__neighbours"] = from_list(lambda x: to_class(NeighbourLevel, x), self.neighbours)
        result["__smartColor"] = from_str(self.smart_color)
        if self.level_bg_color is not None:
            result["bgColor"] = from_union([from_none, from_str], self.level_bg_color)
        result["bgPivotX"] = to_float(self.bg_pivot_x)
        result["bgPivotY"] = to_float(self.bg_pivot_y)
        if self.level_bg_pos is not None:
            result["bgPos"] = from_union([from_none, lambda x: to_enum(BgPos, x)], self.level_bg_pos)
        if self.bg_rel_path is not None:
            result["bgRelPath"] = from_union([from_none, from_str], self.bg_rel_path)
        if self.external_rel_path is not None:
            result["externalRelPath"] = from_union([from_none, from_str], self.external_rel_path)
        result["fieldInstances"] = from_list(lambda x: to_class(FieldInstance, x), self.field_instances)
        result["identifier"] = from_str(self.identifier)
        result["iid"] = from_str(self.iid)
        if self.layer_instances is not None:
            result["layerInstances"] = from_union([from_none, lambda x: from_list(lambda x: to_class(LayerInstance, x), x)], self.layer_instances)
        result["pxHei"] = from_int(self.px_hei)
        result["pxWid"] = from_int(self.px_wid)
        result["uid"] = from_int(self.uid)
        result["useAutoIdentifier"] = from_bool(self.use_auto_identifier)
        result["worldDepth"] = from_int(self.world_depth)
        result["worldX"] = from_int(self.world_x)
        result["worldY"] = from_int(self.world_y)
        return result


class LdtkTableOfContentEntry:
    identifier: str
    instances: List[ReferenceToAnEntityInstance]

    def __init__(self, identifier: str, instances: List[ReferenceToAnEntityInstance]) -> None:
        self.identifier = identifier
        self.instances = instances

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkTableOfContentEntry':
        assert isinstance(obj, dict)
        identifier = from_str(obj.get("identifier"))
        instances = from_list(ReferenceToAnEntityInstance.from_dict, obj.get("instances"))
        return LdtkTableOfContentEntry(identifier, instances)

    def to_dict(self) -> dict:
        result: dict = {}
        result["identifier"] = from_str(self.identifier)
        result["instances"] = from_list(lambda x: to_class(ReferenceToAnEntityInstance, x), self.instances)
        return result


class WorldLayout(Enum):
    FREE = "Free"
    GRID_VANIA = "GridVania"
    LINEAR_HORIZONTAL = "LinearHorizontal"
    LINEAR_VERTICAL = "LinearVertical"


class World:
    """**IMPORTANT**: this type is available as a preview. You can rely on it to update your
    importers, for when it will be officially available.  A World contains multiple levels,
    and it has its own layout settings.
    """
    """Default new level height"""
    default_level_height: int
    """Default new level width"""
    default_level_width: int
    """User defined unique identifier"""
    identifier: str
    """Unique instance identifer"""
    iid: str
    """All levels from this world. The order of this array is only relevant in
    `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).
    Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
    """
    levels: List[Level]
    """Height of the world grid in pixels."""
    world_grid_height: int
    """Width of the world grid in pixels."""
    world_grid_width: int
    """An enum that describes how levels are organized in this project (ie. linearly or in a 2D
    space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`
    """
    world_layout: Optional[WorldLayout]

    def __init__(self, default_level_height: int, default_level_width: int, identifier: str, iid: str, levels: List[Level], world_grid_height: int, world_grid_width: int, world_layout: Optional[WorldLayout]) -> None:
        self.default_level_height = default_level_height
        self.default_level_width = default_level_width
        self.identifier = identifier
        self.iid = iid
        self.levels = levels
        self.world_grid_height = world_grid_height
        self.world_grid_width = world_grid_width
        self.world_layout = world_layout

    @staticmethod
    def from_dict(obj: Any) -> 'World':
        assert isinstance(obj, dict)
        default_level_height = from_int(obj.get("defaultLevelHeight"))
        default_level_width = from_int(obj.get("defaultLevelWidth"))
        identifier = from_str(obj.get("identifier"))
        iid = from_str(obj.get("iid"))
        levels = from_list(Level.from_dict, obj.get("levels"))
        world_grid_height = from_int(obj.get("worldGridHeight"))
        world_grid_width = from_int(obj.get("worldGridWidth"))
        world_layout = from_union([from_none, WorldLayout], obj.get("worldLayout"))
        return World(default_level_height, default_level_width, identifier, iid, levels, world_grid_height, world_grid_width, world_layout)

    def to_dict(self) -> dict:
        result: dict = {}
        result["defaultLevelHeight"] = from_int(self.default_level_height)
        result["defaultLevelWidth"] = from_int(self.default_level_width)
        result["identifier"] = from_str(self.identifier)
        result["iid"] = from_str(self.iid)
        result["levels"] = from_list(lambda x: to_class(Level, x), self.levels)
        result["worldGridHeight"] = from_int(self.world_grid_height)
        result["worldGridWidth"] = from_int(self.world_grid_width)
        result["worldLayout"] = from_union([from_none, lambda x: to_enum(WorldLayout, x)], self.world_layout)
        return result


class ForcedRefs:
    """This object is not actually used by LDtk. It ONLY exists to force explicit references to
    all types, to make sure QuickType finds them and integrate all of them. Otherwise,
    Quicktype will drop types that are not explicitely used.
    """
    auto_layer_rule_group: Optional[AutoLayerRuleGroup]
    auto_rule_def: Optional[AutoLayerRuleDefinition]
    custom_command: Optional[LdtkCustomCommand]
    definitions: Optional[Definitions]
    entity_def: Optional[EntityDefinition]
    entity_instance: Optional[EntityInstance]
    entity_reference_infos: Optional[ReferenceToAnEntityInstance]
    enum_def: Optional[EnumDefinition]
    enum_def_values: Optional[EnumValueDefinition]
    enum_tag_value: Optional[EnumTagValue]
    field_def: Optional[FieldDefinition]
    field_instance: Optional[FieldInstance]
    grid_point: Optional[GridPoint]
    int_grid_value_def: Optional[IntGridValueDefinition]
    int_grid_value_instance: Optional[IntGridValueInstance]
    layer_def: Optional[LayerDefinition]
    layer_instance: Optional[LayerInstance]
    level: Optional[Level]
    level_bg_pos_infos: Optional[LevelBackgroundPosition]
    neighbour_level: Optional[NeighbourLevel]
    table_of_content_entry: Optional[LdtkTableOfContentEntry]
    tile: Optional[TileInstance]
    tile_custom_metadata: Optional[TileCustomMetadata]
    tileset_def: Optional[TilesetDefinition]
    tileset_rect: Optional[TilesetRectangle]
    world: Optional[World]

    def __init__(self, auto_layer_rule_group: Optional[AutoLayerRuleGroup], auto_rule_def: Optional[AutoLayerRuleDefinition], custom_command: Optional[LdtkCustomCommand], definitions: Optional[Definitions], entity_def: Optional[EntityDefinition], entity_instance: Optional[EntityInstance], entity_reference_infos: Optional[ReferenceToAnEntityInstance], enum_def: Optional[EnumDefinition], enum_def_values: Optional[EnumValueDefinition], enum_tag_value: Optional[EnumTagValue], field_def: Optional[FieldDefinition], field_instance: Optional[FieldInstance], grid_point: Optional[GridPoint], int_grid_value_def: Optional[IntGridValueDefinition], int_grid_value_instance: Optional[IntGridValueInstance], layer_def: Optional[LayerDefinition], layer_instance: Optional[LayerInstance], level: Optional[Level], level_bg_pos_infos: Optional[LevelBackgroundPosition], neighbour_level: Optional[NeighbourLevel], table_of_content_entry: Optional[LdtkTableOfContentEntry], tile: Optional[TileInstance], tile_custom_metadata: Optional[TileCustomMetadata], tileset_def: Optional[TilesetDefinition], tileset_rect: Optional[TilesetRectangle], world: Optional[World]) -> None:
        self.auto_layer_rule_group = auto_layer_rule_group
        self.auto_rule_def = auto_rule_def
        self.custom_command = custom_command
        self.definitions = definitions
        self.entity_def = entity_def
        self.entity_instance = entity_instance
        self.entity_reference_infos = entity_reference_infos
        self.enum_def = enum_def
        self.enum_def_values = enum_def_values
        self.enum_tag_value = enum_tag_value
        self.field_def = field_def
        self.field_instance = field_instance
        self.grid_point = grid_point
        self.int_grid_value_def = int_grid_value_def
        self.int_grid_value_instance = int_grid_value_instance
        self.layer_def = layer_def
        self.layer_instance = layer_instance
        self.level = level
        self.level_bg_pos_infos = level_bg_pos_infos
        self.neighbour_level = neighbour_level
        self.table_of_content_entry = table_of_content_entry
        self.tile = tile
        self.tile_custom_metadata = tile_custom_metadata
        self.tileset_def = tileset_def
        self.tileset_rect = tileset_rect
        self.world = world

    @staticmethod
    def from_dict(obj: Any) -> 'ForcedRefs':
        assert isinstance(obj, dict)
        auto_layer_rule_group = from_union([AutoLayerRuleGroup.from_dict, from_none], obj.get("AutoLayerRuleGroup"))
        auto_rule_def = from_union([AutoLayerRuleDefinition.from_dict, from_none], obj.get("AutoRuleDef"))
        custom_command = from_union([LdtkCustomCommand.from_dict, from_none], obj.get("CustomCommand"))
        definitions = from_union([Definitions.from_dict, from_none], obj.get("Definitions"))
        entity_def = from_union([EntityDefinition.from_dict, from_none], obj.get("EntityDef"))
        entity_instance = from_union([EntityInstance.from_dict, from_none], obj.get("EntityInstance"))
        entity_reference_infos = from_union([ReferenceToAnEntityInstance.from_dict, from_none], obj.get("EntityReferenceInfos"))
        enum_def = from_union([EnumDefinition.from_dict, from_none], obj.get("EnumDef"))
        enum_def_values = from_union([EnumValueDefinition.from_dict, from_none], obj.get("EnumDefValues"))
        enum_tag_value = from_union([EnumTagValue.from_dict, from_none], obj.get("EnumTagValue"))
        field_def = from_union([FieldDefinition.from_dict, from_none], obj.get("FieldDef"))
        field_instance = from_union([FieldInstance.from_dict, from_none], obj.get("FieldInstance"))
        grid_point = from_union([GridPoint.from_dict, from_none], obj.get("GridPoint"))
        int_grid_value_def = from_union([IntGridValueDefinition.from_dict, from_none], obj.get("IntGridValueDef"))
        int_grid_value_instance = from_union([IntGridValueInstance.from_dict, from_none], obj.get("IntGridValueInstance"))
        layer_def = from_union([LayerDefinition.from_dict, from_none], obj.get("LayerDef"))
        layer_instance = from_union([LayerInstance.from_dict, from_none], obj.get("LayerInstance"))
        level = from_union([Level.from_dict, from_none], obj.get("Level"))
        level_bg_pos_infos = from_union([from_none, LevelBackgroundPosition.from_dict], obj.get("LevelBgPosInfos"))
        neighbour_level = from_union([NeighbourLevel.from_dict, from_none], obj.get("NeighbourLevel"))
        table_of_content_entry = from_union([LdtkTableOfContentEntry.from_dict, from_none], obj.get("TableOfContentEntry"))
        tile = from_union([TileInstance.from_dict, from_none], obj.get("Tile"))
        tile_custom_metadata = from_union([TileCustomMetadata.from_dict, from_none], obj.get("TileCustomMetadata"))
        tileset_def = from_union([TilesetDefinition.from_dict, from_none], obj.get("TilesetDef"))
        tileset_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("TilesetRect"))
        world = from_union([World.from_dict, from_none], obj.get("World"))
        return ForcedRefs(auto_layer_rule_group, auto_rule_def, custom_command, definitions, entity_def, entity_instance, entity_reference_infos, enum_def, enum_def_values, enum_tag_value, field_def, field_instance, grid_point, int_grid_value_def, int_grid_value_instance, layer_def, layer_instance, level, level_bg_pos_infos, neighbour_level, table_of_content_entry, tile, tile_custom_metadata, tileset_def, tileset_rect, world)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.auto_layer_rule_group is not None:
            result["AutoLayerRuleGroup"] = from_union([lambda x: to_class(AutoLayerRuleGroup, x), from_none], self.auto_layer_rule_group)
        if self.auto_rule_def is not None:
            result["AutoRuleDef"] = from_union([lambda x: to_class(AutoLayerRuleDefinition, x), from_none], self.auto_rule_def)
        if self.custom_command is not None:
            result["CustomCommand"] = from_union([lambda x: to_class(LdtkCustomCommand, x), from_none], self.custom_command)
        if self.definitions is not None:
            result["Definitions"] = from_union([lambda x: to_class(Definitions, x), from_none], self.definitions)
        if self.entity_def is not None:
            result["EntityDef"] = from_union([lambda x: to_class(EntityDefinition, x), from_none], self.entity_def)
        if self.entity_instance is not None:
            result["EntityInstance"] = from_union([lambda x: to_class(EntityInstance, x), from_none], self.entity_instance)
        if self.entity_reference_infos is not None:
            result["EntityReferenceInfos"] = from_union([lambda x: to_class(ReferenceToAnEntityInstance, x), from_none], self.entity_reference_infos)
        if self.enum_def is not None:
            result["EnumDef"] = from_union([lambda x: to_class(EnumDefinition, x), from_none], self.enum_def)
        if self.enum_def_values is not None:
            result["EnumDefValues"] = from_union([lambda x: to_class(EnumValueDefinition, x), from_none], self.enum_def_values)
        if self.enum_tag_value is not None:
            result["EnumTagValue"] = from_union([lambda x: to_class(EnumTagValue, x), from_none], self.enum_tag_value)
        if self.field_def is not None:
            result["FieldDef"] = from_union([lambda x: to_class(FieldDefinition, x), from_none], self.field_def)
        if self.field_instance is not None:
            result["FieldInstance"] = from_union([lambda x: to_class(FieldInstance, x), from_none], self.field_instance)
        if self.grid_point is not None:
            result["GridPoint"] = from_union([lambda x: to_class(GridPoint, x), from_none], self.grid_point)
        if self.int_grid_value_def is not None:
            result["IntGridValueDef"] = from_union([lambda x: to_class(IntGridValueDefinition, x), from_none], self.int_grid_value_def)
        if self.int_grid_value_instance is not None:
            result["IntGridValueInstance"] = from_union([lambda x: to_class(IntGridValueInstance, x), from_none], self.int_grid_value_instance)
        if self.layer_def is not None:
            result["LayerDef"] = from_union([lambda x: to_class(LayerDefinition, x), from_none], self.layer_def)
        if self.layer_instance is not None:
            result["LayerInstance"] = from_union([lambda x: to_class(LayerInstance, x), from_none], self.layer_instance)
        if self.level is not None:
            result["Level"] = from_union([lambda x: to_class(Level, x), from_none], self.level)
        if self.level_bg_pos_infos is not None:
            result["LevelBgPosInfos"] = from_union([from_none, lambda x: to_class(LevelBackgroundPosition, x)], self.level_bg_pos_infos)
        if self.neighbour_level is not None:
            result["NeighbourLevel"] = from_union([lambda x: to_class(NeighbourLevel, x), from_none], self.neighbour_level)
        if self.table_of_content_entry is not None:
            result["TableOfContentEntry"] = from_union([lambda x: to_class(LdtkTableOfContentEntry, x), from_none], self.table_of_content_entry)
        if self.tile is not None:
            result["Tile"] = from_union([lambda x: to_class(TileInstance, x), from_none], self.tile)
        if self.tile_custom_metadata is not None:
            result["TileCustomMetadata"] = from_union([lambda x: to_class(TileCustomMetadata, x), from_none], self.tile_custom_metadata)
        if self.tileset_def is not None:
            result["TilesetDef"] = from_union([lambda x: to_class(TilesetDefinition, x), from_none], self.tileset_def)
        if self.tileset_rect is not None:
            result["TilesetRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tileset_rect)
        if self.world is not None:
            result["World"] = from_union([lambda x: to_class(World, x), from_none], self.world)
        return result


class IdentifierStyle(Enum):
    """Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
    values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
    """
    CAPITALIZE = "Capitalize"
    FREE = "Free"
    LOWERCASE = "Lowercase"
    UPPERCASE = "Uppercase"


class ImageExportMode(Enum):
    """"Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
    `OneImagePerLevel`, `LayersAndLevels`
    """
    LAYERS_AND_LEVELS = "LayersAndLevels"
    NONE = "None"
    ONE_IMAGE_PER_LAYER = "OneImagePerLayer"
    ONE_IMAGE_PER_LEVEL = "OneImagePerLevel"


class LdtkJSON:
    """This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).
    
    This is the root of any Project JSON file. It contains:  - the project settings, - an
    array of levels, - a group of definitions (that can probably be safely ignored for most
    users).
    """
    """This object is not actually used by LDtk. It ONLY exists to force explicit references to
    all types, to make sure QuickType finds them and integrate all of them. Otherwise,
    Quicktype will drop types that are not explicitely used.
    """
    forced_refs: Optional[ForcedRefs]
    """LDtk application build identifier.<br/>  This is only used to identify the LDtk version
    that generated this particular project file, which can be useful for specific bug fixing.
    Note that the build identifier is just the date of the release, so it's not unique to
    each user (one single global ID per LDtk public release), and as a result, completely
    anonymous.
    """
    app_build_id: float
    """Number of backup files to keep, if the `backupOnSave` is TRUE"""
    backup_limit: int
    """If TRUE, an extra copy of the project will be created in a sub folder, when saving."""
    backup_on_save: bool
    """Target relative path to store backup files"""
    backup_rel_path: Optional[str]
    """Project background color"""
    bg_color: str
    """An array of command lines that can be ran manually by the user"""
    custom_commands: List[LdtkCustomCommand]
    """Default grid size for new layers"""
    default_grid_size: int
    """Default background color of levels"""
    default_level_bg_color: str
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Default new level height
    """
    default_level_height: Optional[int]
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Default new level width
    """
    default_level_width: Optional[int]
    """Default X pivot (0 to 1) for new entities"""
    default_pivot_x: float
    """Default Y pivot (0 to 1) for new entities"""
    default_pivot_y: float
    """A structure containing all the definitions of this project"""
    defs: Definitions
    """If the project isn't in MultiWorlds mode, this is the IID of the internal "dummy" World."""
    dummy_world_iid: str
    """If TRUE, the exported PNGs will include the level background (color or image)."""
    export_level_bg: bool
    """**WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced
    by: `imageExportMode`
    """
    export_png: Optional[bool]
    """If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file
    (default is FALSE)
    """
    export_tiled: bool
    """If TRUE, one file will be saved for the project (incl. all its definitions) and one file
    in a sub-folder for each level.
    """
    external_levels: bool
    """An array containing various advanced flags (ie. options or other states). Possible
    values: `DiscardPreCsvIntGrid`, `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`,
    `PrependIndexToLevelFileNames`, `MultiWorlds`, `UseMultilinesType`
    """
    flags: List[Flag]
    """Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
    values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
    """
    identifier_style: IdentifierStyle
    """Unique project identifier"""
    iid: str
    """"Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
    `OneImagePerLevel`, `LayersAndLevels`
    """
    image_export_mode: ImageExportMode
    """File format version"""
    json_version: str
    """The default naming convention for level identifiers."""
    level_name_pattern: str
    """All levels. The order of this array is only relevant in `LinearHorizontal` and
    `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should
    refer to the `worldX`,`worldY` coordinates of each Level.
    """
    levels: List[Level]
    """If TRUE, the Json is partially minified (no indentation, nor line breaks, default is
    FALSE)
    """
    minify_json: bool
    """Next Unique integer ID available"""
    next_uid: int
    """File naming pattern for exported PNGs"""
    png_file_pattern: Optional[str]
    """If TRUE, a very simplified will be generated on saving, for quicker & easier engine
    integration.
    """
    simplified_export: bool
    """All instances of entities that have their `exportToToc` flag enabled are listed in this
    array.
    """
    toc: List[LdtkTableOfContentEntry]
    """This optional description is used by LDtk Samples to show up some informations and
    instructions.
    """
    tutorial_desc: Optional[str]
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Height of the world grid in pixels.
    """
    world_grid_height: Optional[int]
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Width of the world grid in pixels.
    """
    world_grid_width: Optional[int]
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  An enum that describes how levels are organized in
    this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,
    `GridVania`, `LinearHorizontal`, `LinearVertical`
    """
    world_layout: Optional[WorldLayout]
    """This array will be empty, unless you enable the Multi-Worlds in the project advanced
    settings.<br/><br/> - in current version, a LDtk project file can only contain a single
    world with multiple levels in it. In this case, levels and world layout related settings
    are stored in the root of the JSON.<br/> - with "Multi-worlds" enabled, there will be a
    `worlds` array in root, each world containing levels and layout settings. Basically, it's
    pretty much only about moving the `levels` array to the `worlds` array, along with world
    layout related values (eg. `worldGridWidth` etc).<br/><br/>If you want to start
    supporting this future update easily, please refer to this documentation:
    https://github.com/deepnight/ldtk/issues/231
    """
    worlds: List[World]

    def __init__(self, forced_refs: Optional[ForcedRefs], app_build_id: float, backup_limit: int, backup_on_save: bool, backup_rel_path: Optional[str], bg_color: str, custom_commands: List[LdtkCustomCommand], default_grid_size: int, default_level_bg_color: str, default_level_height: Optional[int], default_level_width: Optional[int], default_pivot_x: float, default_pivot_y: float, defs: Definitions, dummy_world_iid: str, export_level_bg: bool, export_png: Optional[bool], export_tiled: bool, external_levels: bool, flags: List[Flag], identifier_style: IdentifierStyle, iid: str, image_export_mode: ImageExportMode, json_version: str, level_name_pattern: str, levels: List[Level], minify_json: bool, next_uid: int, png_file_pattern: Optional[str], simplified_export: bool, toc: List[LdtkTableOfContentEntry], tutorial_desc: Optional[str], world_grid_height: Optional[int], world_grid_width: Optional[int], world_layout: Optional[WorldLayout], worlds: List[World]) -> None:
        self.forced_refs = forced_refs
        self.app_build_id = app_build_id
        self.backup_limit = backup_limit
        self.backup_on_save = backup_on_save
        self.backup_rel_path = backup_rel_path
        self.bg_color = bg_color
        self.custom_commands = custom_commands
        self.default_grid_size = default_grid_size
        self.default_level_bg_color = default_level_bg_color
        self.default_level_height = default_level_height
        self.default_level_width = default_level_width
        self.default_pivot_x = default_pivot_x
        self.default_pivot_y = default_pivot_y
        self.defs = defs
        self.dummy_world_iid = dummy_world_iid
        self.export_level_bg = export_level_bg
        self.export_png = export_png
        self.export_tiled = export_tiled
        self.external_levels = external_levels
        self.flags = flags
        self.identifier_style = identifier_style
        self.iid = iid
        self.image_export_mode = image_export_mode
        self.json_version = json_version
        self.level_name_pattern = level_name_pattern
        self.levels = levels
        self.minify_json = minify_json
        self.next_uid = next_uid
        self.png_file_pattern = png_file_pattern
        self.simplified_export = simplified_export
        self.toc = toc
        self.tutorial_desc = tutorial_desc
        self.world_grid_height = world_grid_height
        self.world_grid_width = world_grid_width
        self.world_layout = world_layout
        self.worlds = worlds

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkJSON':
        assert isinstance(obj, dict)
        forced_refs = from_union([ForcedRefs.from_dict, from_none], obj.get("__FORCED_REFS"))
        app_build_id = from_float(obj.get("appBuildId"))
        backup_limit = from_int(obj.get("backupLimit"))
        backup_on_save = from_bool(obj.get("backupOnSave"))
        backup_rel_path = from_union([from_none, from_str], obj.get("backupRelPath"))
        bg_color = from_str(obj.get("bgColor"))
        custom_commands = from_list(LdtkCustomCommand.from_dict, obj.get("customCommands"))
        default_grid_size = from_int(obj.get("defaultGridSize"))
        default_level_bg_color = from_str(obj.get("defaultLevelBgColor"))
        default_level_height = from_union([from_none, from_int], obj.get("defaultLevelHeight"))
        default_level_width = from_union([from_none, from_int], obj.get("defaultLevelWidth"))
        default_pivot_x = from_float(obj.get("defaultPivotX"))
        default_pivot_y = from_float(obj.get("defaultPivotY"))
        defs = Definitions.from_dict(obj.get("defs"))
        dummy_world_iid = from_str(obj.get("dummyWorldIid"))
        export_level_bg = from_bool(obj.get("exportLevelBg"))
        export_png = from_union([from_none, from_bool], obj.get("exportPng"))
        export_tiled = from_bool(obj.get("exportTiled"))
        external_levels = from_bool(obj.get("externalLevels"))
        flags = from_list(Flag, obj.get("flags"))
        identifier_style = IdentifierStyle(obj.get("identifierStyle"))
        iid = from_str(obj.get("iid"))
        image_export_mode = ImageExportMode(obj.get("imageExportMode"))
        json_version = from_str(obj.get("jsonVersion"))
        level_name_pattern = from_str(obj.get("levelNamePattern"))
        levels = from_list(Level.from_dict, obj.get("levels"))
        minify_json = from_bool(obj.get("minifyJson"))
        next_uid = from_int(obj.get("nextUid"))
        png_file_pattern = from_union([from_none, from_str], obj.get("pngFilePattern"))
        simplified_export = from_bool(obj.get("simplifiedExport"))
        toc = from_list(LdtkTableOfContentEntry.from_dict, obj.get("toc"))
        tutorial_desc = from_union([from_none, from_str], obj.get("tutorialDesc"))
        world_grid_height = from_union([from_none, from_int], obj.get("worldGridHeight"))
        world_grid_width = from_union([from_none, from_int], obj.get("worldGridWidth"))
        world_layout = from_union([from_none, WorldLayout], obj.get("worldLayout"))
        worlds = from_list(World.from_dict, obj.get("worlds"))
        return LdtkJSON(forced_refs, app_build_id, backup_limit, backup_on_save, backup_rel_path, bg_color, custom_commands, default_grid_size, default_level_bg_color, default_level_height, default_level_width, default_pivot_x, default_pivot_y, defs, dummy_world_iid, export_level_bg, export_png, export_tiled, external_levels, flags, identifier_style, iid, image_export_mode, json_version, level_name_pattern, levels, minify_json, next_uid, png_file_pattern, simplified_export, toc, tutorial_desc, world_grid_height, world_grid_width, world_layout, worlds)

    def to_dict(self) -> dict:
        result: dict = {}
        if self.forced_refs is not None:
            result["__FORCED_REFS"] = from_union([lambda x: to_class(ForcedRefs, x), from_none], self.forced_refs)
        result["appBuildId"] = to_float(self.app_build_id)
        result["backupLimit"] = from_int(self.backup_limit)
        result["backupOnSave"] = from_bool(self.backup_on_save)
        if self.backup_rel_path is not None:
            result["backupRelPath"] = from_union([from_none, from_str], self.backup_rel_path)
        result["bgColor"] = from_str(self.bg_color)
        result["customCommands"] = from_list(lambda x: to_class(LdtkCustomCommand, x), self.custom_commands)
        result["defaultGridSize"] = from_int(self.default_grid_size)
        result["defaultLevelBgColor"] = from_str(self.default_level_bg_color)
        if self.default_level_height is not None:
            result["defaultLevelHeight"] = from_union([from_none, from_int], self.default_level_height)
        if self.default_level_width is not None:
            result["defaultLevelWidth"] = from_union([from_none, from_int], self.default_level_width)
        result["defaultPivotX"] = to_float(self.default_pivot_x)
        result["defaultPivotY"] = to_float(self.default_pivot_y)
        result["defs"] = to_class(Definitions, self.defs)
        result["dummyWorldIid"] = from_str(self.dummy_world_iid)
        result["exportLevelBg"] = from_bool(self.export_level_bg)
        if self.export_png is not None:
            result["exportPng"] = from_union([from_none, from_bool], self.export_png)
        result["exportTiled"] = from_bool(self.export_tiled)
        result["externalLevels"] = from_bool(self.external_levels)
        result["flags"] = from_list(lambda x: to_enum(Flag, x), self.flags)
        result["identifierStyle"] = to_enum(IdentifierStyle, self.identifier_style)
        result["iid"] = from_str(self.iid)
        result["imageExportMode"] = to_enum(ImageExportMode, self.image_export_mode)
        result["jsonVersion"] = from_str(self.json_version)
        result["levelNamePattern"] = from_str(self.level_name_pattern)
        result["levels"] = from_list(lambda x: to_class(Level, x), self.levels)
        result["minifyJson"] = from_bool(self.minify_json)
        result["nextUid"] = from_int(self.next_uid)
        if self.png_file_pattern is not None:
            result["pngFilePattern"] = from_union([from_none, from_str], self.png_file_pattern)
        result["simplifiedExport"] = from_bool(self.simplified_export)
        result["toc"] = from_list(lambda x: to_class(LdtkTableOfContentEntry, x), self.toc)
        if self.tutorial_desc is not None:
            result["tutorialDesc"] = from_union([from_none, from_str], self.tutorial_desc)
        if self.world_grid_height is not None:
            result["worldGridHeight"] = from_union([from_none, from_int], self.world_grid_height)
        if self.world_grid_width is not None:
            result["worldGridWidth"] = from_union([from_none, from_int], self.world_grid_width)
        if self.world_layout is not None:
            result["worldLayout"] = from_union([from_none, lambda x: to_enum(WorldLayout, x)], self.world_layout)
        result["worlds"] = from_list(lambda x: to_class(World, x), self.worlds)
        return result


def ldtk_json_from_dict(s: Any) -> LdtkJSON:
    return LdtkJSON.from_dict(s)


def ldtk_json_to_dict(x: LdtkJSON) -> Any:
    return to_class(LdtkJSON, x)
