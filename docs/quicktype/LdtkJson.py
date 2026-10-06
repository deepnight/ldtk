from enum import Enum
from dataclasses import dataclass
from typing import Any, TypeVar, Type, Callable, cast


T = TypeVar("T")
EnumT = TypeVar("EnumT", bound=Enum)


def from_str(x: Any) -> str:
    assert isinstance(x, str)
    return x


def to_enum(c: Type[EnumT], x: Any) -> EnumT:
    assert isinstance(x, c)
    return x.value


def from_list(f: Callable[[Any], T], x: Any) -> list[T]:
    assert isinstance(x, list)
    return [f(y) for y in x]


def from_bool(x: Any) -> bool:
    assert isinstance(x, bool)
    return x


def from_float(x: Any) -> float:
    assert isinstance(x, (float, int)) and not isinstance(x, bool)
    return float(x)


def from_int(x: Any) -> int:
    assert isinstance(x, int) and not isinstance(x, bool)
    return x


def from_none(x: Any) -> Any:
    assert x is None
    return x


def from_union(fs, x):
    for f in fs:
        try:
            return f(x)
        except:
            pass
    assert False


def to_float(x: Any) -> float:
    assert isinstance(x, (int, float))
    return x


def to_class(c: Type[T], x: Any) -> dict:
    assert isinstance(x, c)
    return cast(Any, x).to_dict()


def from_dict(f: Callable[[Any], T], x: Any) -> dict[str, T]:
    assert isinstance(x, dict)
    return { k: f(v) for (k, v) in x.items() }


class When(Enum):
    """Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`"""

    AFTER_LOAD = "AfterLoad"
    AFTER_SAVE = "AfterSave"
    BEFORE_SAVE = "BeforeSave"
    MANUAL = "Manual"


@dataclass
class LdtkCustomCommand:
    command: str
    when: When
    """Possible values: `Manual`, `AfterLoad`, `BeforeSave`, `AfterSave`"""

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


@dataclass
class FieldDefinition:
    """This section is mostly only intended for the LDtk editor app itself. You can safely
    ignore it.
    """
    type: str
    """Human readable value type. Possible values: `Int, Float, String, Bool, Color,
    ExternEnum.XXX, LocalEnum.XXX, Point, FilePath`.<br/>  If the field is an array, this
    field will look like `Array<...>` (eg. `Array<Int>`, `Array<Point>` etc.)<br/>  NOTE: if
    you enable the advanced option **Use Multilines type**, you will have "*Multilines*"
    instead of "*String*" when relevant.
    """
    allowed_refs: AllowedRefs
    """Possible values: `Any`, `OnlySame`, `OnlyTags`, `OnlySpecificEntity`"""

    allowed_ref_tags: list[str]
    allow_out_of_level_ref: bool
    auto_chain_ref: bool
    can_be_null: bool
    """TRUE if the value can be null. For arrays, TRUE means it can contain null values
    (exception: array of Points can't have null values).
    """
    editor_always_show: bool
    editor_cut_long_values: bool
    editor_display_mode: EditorDisplayMode
    """Possible values: `Hidden`, `ValueOnly`, `NameAndValue`, `EntityTile`, `LevelTile`,
    `Points`, `PointStar`, `PointPath`, `PointPathLoop`, `RadiusPx`, `RadiusGrid`,
    `ArrayCountWithLabel`, `ArrayCountNoLabel`, `RefLinkBetweenPivots`,
    `RefLinkBetweenCenters`
    """
    editor_display_pos: EditorDisplayPos
    """Possible values: `Above`, `Center`, `Beneath`"""

    editor_display_scale: float
    editor_link_style: EditorLinkStyle
    """Possible values: `ZigZag`, `StraightArrow`, `CurvedArrow`, `ArrowsLine`, `DashedLine`"""

    editor_show_in_world: bool
    export_to_toc: bool
    """If TRUE, the field value will be exported to the `toc` project JSON field. Only applies
    to Entity fields.
    """
    identifier: str
    """User defined unique identifier"""

    is_array: bool
    """TRUE if the value is an array of multiple values"""

    searchable: bool
    """If enabled, this field will be searchable through LDtk command palette"""

    symmetrical_ref: bool
    field_definition_type: str
    """Internal enum representing the possible field types. Possible values: F_Int, F_Float,
    F_String, F_Text, F_Bool, F_Color, F_Enum(...), F_Point, F_Path, F_EntityRef, F_Tile
    """
    uid: int
    """Unique Int identifier"""

    use_for_smart_color: bool
    """If TRUE, the color associated with this field will override the Entity or Level default
    color in the editor UI. For Enum fields, this would be the color associated to their
    values.
    """
    accept_file_types: list[str] | None = None
    """Optional list of accepted file extensions for FilePath value type. Includes the dot:
    `.ext`
    """
    allowed_refs_entity_uid: int | None = None
    array_max_length: int | None = None
    """Array max length"""

    array_min_length: int | None = None
    """Array min length"""

    default_override: Any = None
    """Default value if selected value is null or invalid."""

    doc: str | None = None
    """User defined documentation for this field to provide help/tips to level designers about
    accepted values.
    """
    editor_display_color: str | None = None
    editor_text_prefix: str | None = None
    editor_text_suffix: str | None = None
    max: float | None = None
    """Max limit for value, if applicable"""

    min: float | None = None
    """Min limit for value, if applicable"""

    regex: str | None = None
    """Optional regular expression that needs to be matched to accept values. Expected format:
    `/some_reg_ex/g`, with optional "i" flag.
    """
    text_language_mode: TextLanguageMode | None = None
    """Possible values: &lt;`null`&gt;, `LangPython`, `LangRuby`, `LangJS`, `LangLua`, `LangC`,
    `LangHaxe`, `LangMarkdown`, `LangJson`, `LangXml`, `LangLog`
    """
    tileset_uid: int | None = None
    """UID of the tileset used for a Tile"""

    @staticmethod
    def from_dict(obj: Any) -> 'FieldDefinition':
        assert isinstance(obj, dict)
        type = from_str(obj.get("__type"))
        allowed_refs = AllowedRefs(obj.get("allowedRefs"))
        allowed_ref_tags = from_list(from_str, obj.get("allowedRefTags"))
        allow_out_of_level_ref = from_bool(obj.get("allowOutOfLevelRef"))
        auto_chain_ref = from_bool(obj.get("autoChainRef"))
        can_be_null = from_bool(obj.get("canBeNull"))
        editor_always_show = from_bool(obj.get("editorAlwaysShow"))
        editor_cut_long_values = from_bool(obj.get("editorCutLongValues"))
        editor_display_mode = EditorDisplayMode(obj.get("editorDisplayMode"))
        editor_display_pos = EditorDisplayPos(obj.get("editorDisplayPos"))
        editor_display_scale = from_float(obj.get("editorDisplayScale"))
        editor_link_style = EditorLinkStyle(obj.get("editorLinkStyle"))
        editor_show_in_world = from_bool(obj.get("editorShowInWorld"))
        export_to_toc = from_bool(obj.get("exportToToc"))
        identifier = from_str(obj.get("identifier"))
        is_array = from_bool(obj.get("isArray"))
        searchable = from_bool(obj.get("searchable"))
        symmetrical_ref = from_bool(obj.get("symmetricalRef"))
        field_definition_type = from_str(obj.get("type"))
        uid = from_int(obj.get("uid"))
        use_for_smart_color = from_bool(obj.get("useForSmartColor"))
        accept_file_types = from_union([from_none, lambda x: from_list(from_str, x)], obj.get("acceptFileTypes"))
        allowed_refs_entity_uid = from_union([from_none, from_int], obj.get("allowedRefsEntityUid"))
        array_max_length = from_union([from_none, from_int], obj.get("arrayMaxLength"))
        array_min_length = from_union([from_none, from_int], obj.get("arrayMinLength"))
        default_override = obj.get("defaultOverride")
        doc = from_union([from_none, from_str], obj.get("doc"))
        editor_display_color = from_union([from_none, from_str], obj.get("editorDisplayColor"))
        editor_text_prefix = from_union([from_none, from_str], obj.get("editorTextPrefix"))
        editor_text_suffix = from_union([from_none, from_str], obj.get("editorTextSuffix"))
        max = from_union([from_none, from_float], obj.get("max"))
        min = from_union([from_none, from_float], obj.get("min"))
        regex = from_union([from_none, from_str], obj.get("regex"))
        text_language_mode = from_union([from_none, TextLanguageMode], obj.get("textLanguageMode"))
        tileset_uid = from_union([from_none, from_int], obj.get("tilesetUid"))
        return FieldDefinition(type, allowed_refs, allowed_ref_tags, allow_out_of_level_ref, auto_chain_ref, can_be_null, editor_always_show, editor_cut_long_values, editor_display_mode, editor_display_pos, editor_display_scale, editor_link_style, editor_show_in_world, export_to_toc, identifier, is_array, searchable, symmetrical_ref, field_definition_type, uid, use_for_smart_color, accept_file_types, allowed_refs_entity_uid, array_max_length, array_min_length, default_override, doc, editor_display_color, editor_text_prefix, editor_text_suffix, max, min, regex, text_language_mode, tileset_uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__type"] = from_str(self.type)
        result["allowedRefs"] = to_enum(AllowedRefs, self.allowed_refs)
        result["allowedRefTags"] = from_list(from_str, self.allowed_ref_tags)
        result["allowOutOfLevelRef"] = from_bool(self.allow_out_of_level_ref)
        result["autoChainRef"] = from_bool(self.auto_chain_ref)
        result["canBeNull"] = from_bool(self.can_be_null)
        result["editorAlwaysShow"] = from_bool(self.editor_always_show)
        result["editorCutLongValues"] = from_bool(self.editor_cut_long_values)
        result["editorDisplayMode"] = to_enum(EditorDisplayMode, self.editor_display_mode)
        result["editorDisplayPos"] = to_enum(EditorDisplayPos, self.editor_display_pos)
        result["editorDisplayScale"] = to_float(self.editor_display_scale)
        result["editorLinkStyle"] = to_enum(EditorLinkStyle, self.editor_link_style)
        result["editorShowInWorld"] = from_bool(self.editor_show_in_world)
        result["exportToToc"] = from_bool(self.export_to_toc)
        result["identifier"] = from_str(self.identifier)
        result["isArray"] = from_bool(self.is_array)
        result["searchable"] = from_bool(self.searchable)
        result["symmetricalRef"] = from_bool(self.symmetrical_ref)
        result["type"] = from_str(self.field_definition_type)
        result["uid"] = from_int(self.uid)
        result["useForSmartColor"] = from_bool(self.use_for_smart_color)
        if self.accept_file_types is not None:
            result["acceptFileTypes"] = from_union([from_none, lambda x: from_list(from_str, x)], self.accept_file_types)
        if self.allowed_refs_entity_uid is not None:
            result["allowedRefsEntityUid"] = from_union([from_none, from_int], self.allowed_refs_entity_uid)
        if self.array_max_length is not None:
            result["arrayMaxLength"] = from_union([from_none, from_int], self.array_max_length)
        if self.array_min_length is not None:
            result["arrayMinLength"] = from_union([from_none, from_int], self.array_min_length)
        if self.default_override is not None:
            result["defaultOverride"] = self.default_override
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        if self.editor_display_color is not None:
            result["editorDisplayColor"] = from_union([from_none, from_str], self.editor_display_color)
        if self.editor_text_prefix is not None:
            result["editorTextPrefix"] = from_union([from_none, from_str], self.editor_text_prefix)
        if self.editor_text_suffix is not None:
            result["editorTextSuffix"] = from_union([from_none, from_str], self.editor_text_suffix)
        if self.max is not None:
            result["max"] = from_union([from_none, to_float], self.max)
        if self.min is not None:
            result["min"] = from_union([from_none, to_float], self.min)
        if self.regex is not None:
            result["regex"] = from_union([from_none, from_str], self.regex)
        if self.text_language_mode is not None:
            result["textLanguageMode"] = from_union([from_none, lambda x: to_enum(TextLanguageMode, x)], self.text_language_mode)
        if self.tileset_uid is not None:
            result["tilesetUid"] = from_union([from_none, from_int], self.tileset_uid)
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


@dataclass
class TilesetRectangle:
    """This object represents a custom sub rectangle in a Tileset image."""

    h: int
    """Height in pixels"""

    tileset_uid: int
    """UID of the tileset"""

    w: int
    """Width in pixels"""

    x: int
    """X pixels coordinate of the top-left corner in the Tileset image"""

    y: int
    """Y pixels coordinate of the top-left corner in the Tileset image"""

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
    """An enum describing how the Entity tile is rendered inside the Entity bounds. Possible
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


@dataclass
class EntityDefinition:
    allow_out_of_bounds: bool
    """If enabled, this entity is allowed to stay outside of the current level bounds"""

    color: str
    """Base entity color"""

    export_to_toc: bool
    """If enabled, all instances of this entity will be listed in the project "Table of content"
    object.
    """
    field_defs: list[FieldDefinition]
    """Array of field definitions"""

    fill_opacity: float
    height: int
    """Pixel height"""

    hollow: bool
    identifier: str
    """User defined unique identifier"""

    keep_aspect_ratio: bool
    """Only applies to entities resizable on both X/Y. If TRUE, the entity instance width/height
    will keep the same aspect ratio as the definition.
    """
    limit_behavior: LimitBehavior
    """Possible values: `DiscardOldOnes`, `PreventAdding`, `MoveLastOne`"""

    limit_scope: LimitScope
    """If TRUE, the maxCount is a "per world" limit, if FALSE, it's a "per level". Possible
    values: `PerLayer`, `PerLevel`, `PerWorld`
    """
    line_opacity: float
    max_count: int
    """Max instances count"""

    nine_slice_borders: list[int]
    """An array of 4 dimensions for the up/right/down/left borders (in this order) when using
    9-slice mode for `tileRenderMode`.<br/>  If the tileRenderMode is not NineSlice, then
    this array is empty.<br/>  See: https://en.wikipedia.org/wiki/9-slice_scaling
    """
    pivot_x: float
    """Pivot X coordinate (from 0 to 1.0)"""

    pivot_y: float
    """Pivot Y coordinate (from 0 to 1.0)"""

    render_mode: RenderMode
    """Possible values: `Rectangle`, `Ellipse`, `Tile`, `Cross`"""

    resizable_x: bool
    """If TRUE, the entity instances will be resizable horizontally"""

    resizable_y: bool
    """If TRUE, the entity instances will be resizable vertically"""

    show_name: bool
    """Display entity name in editor"""

    tags: list[str]
    """An array of strings that classifies this entity"""

    tile_opacity: float
    tile_render_mode: TileRenderMode
    """An enum describing how the Entity tile is rendered inside the Entity bounds. Possible
    values: `Cover`, `FitInside`, `Repeat`, `Stretch`, `FullSizeCropped`,
    `FullSizeUncropped`, `NineSlice`
    """
    uid: int
    """Unique Int identifier"""

    width: int
    """Pixel width"""

    doc: str | None = None
    """User defined documentation for this element to provide help/tips to level designers."""

    max_height: int | None = None
    """Max pixel height (only applies if the entity is resizable on Y)"""

    max_width: int | None = None
    """Max pixel width (only applies if the entity is resizable on X)"""

    min_height: int | None = None
    """Min pixel height (only applies if the entity is resizable on Y)"""

    min_width: int | None = None
    """Min pixel width (only applies if the entity is resizable on X)"""

    tile_id: int | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `tileRect`
    """
    tile_rect: TilesetRectangle | None = None
    """An object representing a rectangle from an existing Tileset"""

    tileset_id: int | None = None
    """Tileset ID used for optional tile display"""

    ui_tile_rect: TilesetRectangle | None = None
    """This tile overrides the one defined in `tileRect` in the UI"""

    @staticmethod
    def from_dict(obj: Any) -> 'EntityDefinition':
        assert isinstance(obj, dict)
        allow_out_of_bounds = from_bool(obj.get("allowOutOfBounds"))
        color = from_str(obj.get("color"))
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
        tile_opacity = from_float(obj.get("tileOpacity"))
        tile_render_mode = TileRenderMode(obj.get("tileRenderMode"))
        uid = from_int(obj.get("uid"))
        width = from_int(obj.get("width"))
        doc = from_union([from_none, from_str], obj.get("doc"))
        max_height = from_union([from_none, from_int], obj.get("maxHeight"))
        max_width = from_union([from_none, from_int], obj.get("maxWidth"))
        min_height = from_union([from_none, from_int], obj.get("minHeight"))
        min_width = from_union([from_none, from_int], obj.get("minWidth"))
        tile_id = from_union([from_none, from_int], obj.get("tileId"))
        tile_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("tileRect"))
        tileset_id = from_union([from_none, from_int], obj.get("tilesetId"))
        ui_tile_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("uiTileRect"))
        return EntityDefinition(allow_out_of_bounds, color, export_to_toc, field_defs, fill_opacity, height, hollow, identifier, keep_aspect_ratio, limit_behavior, limit_scope, line_opacity, max_count, nine_slice_borders, pivot_x, pivot_y, render_mode, resizable_x, resizable_y, show_name, tags, tile_opacity, tile_render_mode, uid, width, doc, max_height, max_width, min_height, min_width, tile_id, tile_rect, tileset_id, ui_tile_rect)

    def to_dict(self) -> dict:
        result: dict = {}
        result["allowOutOfBounds"] = from_bool(self.allow_out_of_bounds)
        result["color"] = from_str(self.color)
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
        result["tileOpacity"] = to_float(self.tile_opacity)
        result["tileRenderMode"] = to_enum(TileRenderMode, self.tile_render_mode)
        result["uid"] = from_int(self.uid)
        result["width"] = from_int(self.width)
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        if self.max_height is not None:
            result["maxHeight"] = from_union([from_none, from_int], self.max_height)
        if self.max_width is not None:
            result["maxWidth"] = from_union([from_none, from_int], self.max_width)
        if self.min_height is not None:
            result["minHeight"] = from_union([from_none, from_int], self.min_height)
        if self.min_width is not None:
            result["minWidth"] = from_union([from_none, from_int], self.min_width)
        if self.tile_id is not None:
            result["tileId"] = from_union([from_none, from_int], self.tile_id)
        if self.tile_rect is not None:
            result["tileRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile_rect)
        if self.tileset_id is not None:
            result["tilesetId"] = from_union([from_none, from_int], self.tileset_id)
        if self.ui_tile_rect is not None:
            result["uiTileRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.ui_tile_rect)
        return result


@dataclass
class EnumValueDefinition:
    color: int
    """Optional color"""

    id: str
    """Enum value"""

    tile_src_rect: list[int] | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.4.0  Replaced
    by: `tileRect`
    """
    tile_id: int | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.4.0  Replaced
    by: `tileRect`
    """
    tile_rect: TilesetRectangle | None = None
    """Optional tileset rectangle to represents this value"""

    @staticmethod
    def from_dict(obj: Any) -> 'EnumValueDefinition':
        assert isinstance(obj, dict)
        color = from_int(obj.get("color"))
        id = from_str(obj.get("id"))
        tile_src_rect = from_union([from_none, lambda x: from_list(from_int, x)], obj.get("__tileSrcRect"))
        tile_id = from_union([from_none, from_int], obj.get("tileId"))
        tile_rect = from_union([from_none, TilesetRectangle.from_dict], obj.get("tileRect"))
        return EnumValueDefinition(color, id, tile_src_rect, tile_id, tile_rect)

    def to_dict(self) -> dict:
        result: dict = {}
        result["color"] = from_int(self.color)
        result["id"] = from_str(self.id)
        if self.tile_src_rect is not None:
            result["__tileSrcRect"] = from_union([from_none, lambda x: from_list(from_int, x)], self.tile_src_rect)
        if self.tile_id is not None:
            result["tileId"] = from_union([from_none, from_int], self.tile_id)
        if self.tile_rect is not None:
            result["tileRect"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile_rect)
        return result


@dataclass
class EnumDefinition:
    identifier: str
    """User defined unique identifier"""

    tags: list[str]
    """An array of user-defined tags to organize the Enums"""

    uid: int
    """Unique Int identifier"""

    values: list[EnumValueDefinition]
    """All possible enum values, with their optional Tile infos."""

    external_file_checksum: str | None = None
    external_rel_path: str | None = None
    """Relative path to the external file providing this Enum"""

    icon_tileset_uid: int | None = None
    """Tileset UID if provided"""

    @staticmethod
    def from_dict(obj: Any) -> 'EnumDefinition':
        assert isinstance(obj, dict)
        identifier = from_str(obj.get("identifier"))
        tags = from_list(from_str, obj.get("tags"))
        uid = from_int(obj.get("uid"))
        values = from_list(EnumValueDefinition.from_dict, obj.get("values"))
        external_file_checksum = from_union([from_none, from_str], obj.get("externalFileChecksum"))
        external_rel_path = from_union([from_none, from_str], obj.get("externalRelPath"))
        icon_tileset_uid = from_union([from_none, from_int], obj.get("iconTilesetUid"))
        return EnumDefinition(identifier, tags, uid, values, external_file_checksum, external_rel_path, icon_tileset_uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["identifier"] = from_str(self.identifier)
        result["tags"] = from_list(from_str, self.tags)
        result["uid"] = from_int(self.uid)
        result["values"] = from_list(lambda x: to_class(EnumValueDefinition, x), self.values)
        if self.external_file_checksum is not None:
            result["externalFileChecksum"] = from_union([from_none, from_str], self.external_file_checksum)
        if self.external_rel_path is not None:
            result["externalRelPath"] = from_union([from_none, from_str], self.external_rel_path)
        if self.icon_tileset_uid is not None:
            result["iconTilesetUid"] = from_union([from_none, from_int], self.icon_tileset_uid)
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


@dataclass
class AutoLayerRuleDefinition:
    """This complex section isn't meant to be used by game devs at all, as these rules are
    completely resolved internally by the editor before any saving. You should just ignore
    this part.
    """
    active: bool
    """If FALSE, the rule effect isn't applied, and no tiles are generated."""

    alpha: float
    break_on_match: bool
    """When TRUE, the rule will prevent other rules to be applied in the same cell if it matches
    (TRUE by default).
    """
    chance: float
    """Chances for this rule to be applied (0 to 1)"""

    checker: Checker
    """Checker mode Possible values: `None`, `Horizontal`, `Vertical`"""

    flip_x: bool
    """If TRUE, allow rule to be matched by flipping its pattern horizontally"""

    flip_y: bool
    """If TRUE, allow rule to be matched by flipping its pattern vertically"""

    invalidated: bool
    """If TRUE, then the rule should be re-evaluated by the editor at one point"""

    pattern: list[int]
    """Rule pattern (size x size)"""

    perlin_active: bool
    """If TRUE, enable Perlin filtering to only apply rule on specific random area"""

    perlin_octaves: float
    perlin_scale: float
    perlin_seed: float
    pivot_x: float
    """X pivot of a tile stamp (0-1)"""

    pivot_y: float
    """Y pivot of a tile stamp (0-1)"""

    size: int
    """Pattern width & height. Should only be 1,3,5 or 7."""

    tile_mode: TileMode
    """Defines how tileIds array is used Possible values: `Single`, `Stamp`"""

    tile_random_x_max: int
    """Max random offset for X tile pos"""

    tile_random_x_min: int
    """Min random offset for X tile pos"""

    tile_random_y_max: int
    """Max random offset for Y tile pos"""

    tile_random_y_min: int
    """Min random offset for Y tile pos"""

    tile_rects_ids: list[list[int]]
    """Array containing all the possible tile IDs rectangles (picked randomly)."""

    tile_x_offset: int
    """Tile X offset"""

    tile_y_offset: int
    """Tile Y offset"""

    uid: int
    """Unique Int identifier"""

    x_modulo: int
    """X cell coord modulo"""

    x_offset: int
    """X cell start offset"""

    y_modulo: int
    """Y cell coord modulo"""

    y_offset: int
    """Y cell start offset"""

    out_of_bounds_value: int | None = None
    """Default IntGrid value when checking cells outside of level bounds"""

    tile_ids: list[int] | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.5.0  Replaced
    by: `tileRectsIds`
    """

    @staticmethod
    def from_dict(obj: Any) -> 'AutoLayerRuleDefinition':
        assert isinstance(obj, dict)
        active = from_bool(obj.get("active"))
        alpha = from_float(obj.get("alpha"))
        break_on_match = from_bool(obj.get("breakOnMatch"))
        chance = from_float(obj.get("chance"))
        checker = Checker(obj.get("checker"))
        flip_x = from_bool(obj.get("flipX"))
        flip_y = from_bool(obj.get("flipY"))
        invalidated = from_bool(obj.get("invalidated"))
        pattern = from_list(from_int, obj.get("pattern"))
        perlin_active = from_bool(obj.get("perlinActive"))
        perlin_octaves = from_float(obj.get("perlinOctaves"))
        perlin_scale = from_float(obj.get("perlinScale"))
        perlin_seed = from_float(obj.get("perlinSeed"))
        pivot_x = from_float(obj.get("pivotX"))
        pivot_y = from_float(obj.get("pivotY"))
        size = from_int(obj.get("size"))
        tile_mode = TileMode(obj.get("tileMode"))
        tile_random_x_max = from_int(obj.get("tileRandomXMax"))
        tile_random_x_min = from_int(obj.get("tileRandomXMin"))
        tile_random_y_max = from_int(obj.get("tileRandomYMax"))
        tile_random_y_min = from_int(obj.get("tileRandomYMin"))
        tile_rects_ids = from_list(lambda x: from_list(from_int, x), obj.get("tileRectsIds"))
        tile_x_offset = from_int(obj.get("tileXOffset"))
        tile_y_offset = from_int(obj.get("tileYOffset"))
        uid = from_int(obj.get("uid"))
        x_modulo = from_int(obj.get("xModulo"))
        x_offset = from_int(obj.get("xOffset"))
        y_modulo = from_int(obj.get("yModulo"))
        y_offset = from_int(obj.get("yOffset"))
        out_of_bounds_value = from_union([from_none, from_int], obj.get("outOfBoundsValue"))
        tile_ids = from_union([from_none, lambda x: from_list(from_int, x)], obj.get("tileIds"))
        return AutoLayerRuleDefinition(active, alpha, break_on_match, chance, checker, flip_x, flip_y, invalidated, pattern, perlin_active, perlin_octaves, perlin_scale, perlin_seed, pivot_x, pivot_y, size, tile_mode, tile_random_x_max, tile_random_x_min, tile_random_y_max, tile_random_y_min, tile_rects_ids, tile_x_offset, tile_y_offset, uid, x_modulo, x_offset, y_modulo, y_offset, out_of_bounds_value, tile_ids)

    def to_dict(self) -> dict:
        result: dict = {}
        result["active"] = from_bool(self.active)
        result["alpha"] = to_float(self.alpha)
        result["breakOnMatch"] = from_bool(self.break_on_match)
        result["chance"] = to_float(self.chance)
        result["checker"] = to_enum(Checker, self.checker)
        result["flipX"] = from_bool(self.flip_x)
        result["flipY"] = from_bool(self.flip_y)
        result["invalidated"] = from_bool(self.invalidated)
        result["pattern"] = from_list(from_int, self.pattern)
        result["perlinActive"] = from_bool(self.perlin_active)
        result["perlinOctaves"] = to_float(self.perlin_octaves)
        result["perlinScale"] = to_float(self.perlin_scale)
        result["perlinSeed"] = to_float(self.perlin_seed)
        result["pivotX"] = to_float(self.pivot_x)
        result["pivotY"] = to_float(self.pivot_y)
        result["size"] = from_int(self.size)
        result["tileMode"] = to_enum(TileMode, self.tile_mode)
        result["tileRandomXMax"] = from_int(self.tile_random_x_max)
        result["tileRandomXMin"] = from_int(self.tile_random_x_min)
        result["tileRandomYMax"] = from_int(self.tile_random_y_max)
        result["tileRandomYMin"] = from_int(self.tile_random_y_min)
        result["tileRectsIds"] = from_list(lambda x: from_list(from_int, x), self.tile_rects_ids)
        result["tileXOffset"] = from_int(self.tile_x_offset)
        result["tileYOffset"] = from_int(self.tile_y_offset)
        result["uid"] = from_int(self.uid)
        result["xModulo"] = from_int(self.x_modulo)
        result["xOffset"] = from_int(self.x_offset)
        result["yModulo"] = from_int(self.y_modulo)
        result["yOffset"] = from_int(self.y_offset)
        if self.out_of_bounds_value is not None:
            result["outOfBoundsValue"] = from_union([from_none, from_int], self.out_of_bounds_value)
        if self.tile_ids is not None:
            result["tileIds"] = from_union([from_none, lambda x: from_list(from_int, x)], self.tile_ids)
        return result


@dataclass
class AutoLayerRuleGroup:
    active: bool
    biome_requirement_mode: int
    is_optional: bool
    name: str
    required_biome_values: list[str]
    rules: list[AutoLayerRuleDefinition]
    uid: int
    uses_wizard: bool
    collapsed: bool | None = None
    """*This field was removed in 1.0.0 and should no longer be used.*"""

    color: str | None = None
    icon: TilesetRectangle | None = None

    @staticmethod
    def from_dict(obj: Any) -> 'AutoLayerRuleGroup':
        assert isinstance(obj, dict)
        active = from_bool(obj.get("active"))
        biome_requirement_mode = from_int(obj.get("biomeRequirementMode"))
        is_optional = from_bool(obj.get("isOptional"))
        name = from_str(obj.get("name"))
        required_biome_values = from_list(from_str, obj.get("requiredBiomeValues"))
        rules = from_list(AutoLayerRuleDefinition.from_dict, obj.get("rules"))
        uid = from_int(obj.get("uid"))
        uses_wizard = from_bool(obj.get("usesWizard"))
        collapsed = from_union([from_none, from_bool], obj.get("collapsed"))
        color = from_union([from_none, from_str], obj.get("color"))
        icon = from_union([from_none, TilesetRectangle.from_dict], obj.get("icon"))
        return AutoLayerRuleGroup(active, biome_requirement_mode, is_optional, name, required_biome_values, rules, uid, uses_wizard, collapsed, color, icon)

    def to_dict(self) -> dict:
        result: dict = {}
        result["active"] = from_bool(self.active)
        result["biomeRequirementMode"] = from_int(self.biome_requirement_mode)
        result["isOptional"] = from_bool(self.is_optional)
        result["name"] = from_str(self.name)
        result["requiredBiomeValues"] = from_list(from_str, self.required_biome_values)
        result["rules"] = from_list(lambda x: to_class(AutoLayerRuleDefinition, x), self.rules)
        result["uid"] = from_int(self.uid)
        result["usesWizard"] = from_bool(self.uses_wizard)
        if self.collapsed is not None:
            result["collapsed"] = from_union([from_none, from_bool], self.collapsed)
        if self.color is not None:
            result["color"] = from_union([from_none, from_str], self.color)
        if self.icon is not None:
            result["icon"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.icon)
        return result


class EntityDepthSorting(Enum):
    """Entity depth sorting mode. Possible values: `Manual`, `YAscending`, `YDescending`"""

    MANUAL = "Manual"
    Y_ASCENDING = "YAscending"
    Y_DESCENDING = "YDescending"


@dataclass
class IntGridValueDefinition:
    """IntGrid value definition"""

    color: str
    group_uid: int
    """Parent group identifier (0 if none)"""

    value: int
    """The IntGrid value itself"""

    identifier: str | None = None
    """User defined unique identifier"""

    tile: TilesetRectangle | None = None

    @staticmethod
    def from_dict(obj: Any) -> 'IntGridValueDefinition':
        assert isinstance(obj, dict)
        color = from_str(obj.get("color"))
        group_uid = from_int(obj.get("groupUid"))
        value = from_int(obj.get("value"))
        identifier = from_union([from_none, from_str], obj.get("identifier"))
        tile = from_union([from_none, TilesetRectangle.from_dict], obj.get("tile"))
        return IntGridValueDefinition(color, group_uid, value, identifier, tile)

    def to_dict(self) -> dict:
        result: dict = {}
        result["color"] = from_str(self.color)
        result["groupUid"] = from_int(self.group_uid)
        result["value"] = from_int(self.value)
        if self.identifier is not None:
            result["identifier"] = from_union([from_none, from_str], self.identifier)
        if self.tile is not None:
            result["tile"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile)
        return result


@dataclass
class IntGridValueGroupDefinition:
    """IntGrid value group definition"""

    uid: int
    """Group unique ID"""

    color: str | None = None
    """User defined color"""

    identifier: str | None = None
    """User defined string identifier"""

    @staticmethod
    def from_dict(obj: Any) -> 'IntGridValueGroupDefinition':
        assert isinstance(obj, dict)
        uid = from_int(obj.get("uid"))
        color = from_union([from_none, from_str], obj.get("color"))
        identifier = from_union([from_none, from_str], obj.get("identifier"))
        return IntGridValueGroupDefinition(uid, color, identifier)

    def to_dict(self) -> dict:
        result: dict = {}
        result["uid"] = from_int(self.uid)
        if self.color is not None:
            result["color"] = from_union([from_none, from_str], self.color)
        if self.identifier is not None:
            result["identifier"] = from_union([from_none, from_str], self.identifier)
        return result


class TypeEnum(Enum):
    """Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
    `AutoLayer`
    """
    AUTO_LAYER = "AutoLayer"
    ENTITIES = "Entities"
    INT_GRID = "IntGrid"
    TILES = "Tiles"


@dataclass
class LayerDefinition:
    type: str
    """Type of the layer (*IntGrid, Entities, Tiles or AutoLayer*)"""

    auto_rule_groups: list[AutoLayerRuleGroup]
    """Contains all the auto-layer rule definitions."""

    can_select_when_inactive: bool
    """Allow editor selections when the layer is not currently active."""

    display_opacity: float
    """Opacity of the layer (0 to 1.0)"""

    entity_depth_sorting: EntityDepthSorting
    """Entity depth sorting mode. Possible values: `Manual`, `YAscending`, `YDescending`"""

    excluded_tags: list[str]
    """An array of tags to forbid some Entities in this layer"""

    grid_size: int
    """Width and height of the grid in pixels"""

    guide_grid_hei: int
    """Height of the optional "guide" grid in pixels"""

    guide_grid_wid: int
    """Width of the optional "guide" grid in pixels"""

    guide_opacity: float
    """Opacity of the optional "guide" grid"""

    hide_fields_when_inactive: bool
    hide_in_list: bool
    """Hide the layer from the list on the side of the editor view."""

    identifier: str
    """User defined unique identifier"""

    inactive_opacity: float
    """Alpha of this layer when it is not the active one."""

    int_grid_values: list[IntGridValueDefinition]
    """An array that defines extra optional info for each IntGrid value.<br/>  WARNING: the
    array order is not related to actual IntGrid values! As user can re-order IntGrid values
    freely, you may value "2" before value "1" in this array.
    """
    int_grid_values_groups: list[IntGridValueGroupDefinition]
    """Group informations for IntGrid values"""

    layer_uids_preventing_auto_tiling_here: list[int]
    parallax_factor_x: float
    """Parallax horizontal factor (from -1 to 1, defaults to 0) which affects the scrolling
    speed of this layer, creating a fake 3D (parallax) effect.
    """
    parallax_factor_y: float
    """Parallax vertical factor (from -1 to 1, defaults to 0) which affects the scrolling speed
    of this layer, creating a fake 3D (parallax) effect.
    """
    parallax_scaling: bool
    """If true (default), a layer with a parallax factor will also be scaled up/down accordingly."""

    px_offset_x: int
    """X offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    optional offset)
    """
    px_offset_y: int
    """Y offset of the layer, in pixels (IMPORTANT: this should be added to the `LayerInstance`
    optional offset)
    """
    render_in_world_view: bool
    """If TRUE, the content of this layer will be used when rendering levels in a simplified way
    for the world view
    """
    required_tags: list[str]
    """An array of tags to filter Entities that can be added to this layer"""

    tile_pivot_x: float
    """If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    position the tile relatively its grid cell.
    """
    tile_pivot_y: float
    """If the tiles are smaller or larger than the layer grid, the pivot value will be used to
    position the tile relatively its grid cell.
    """
    layer_definition_type: TypeEnum
    """Type of the layer as Haxe Enum Possible values: `IntGrid`, `Entities`, `Tiles`,
    `AutoLayer`
    """
    uid: int
    """Unique Int identifier"""

    ui_filter_tags: list[str]
    """Display tags"""

    use_async_render: bool
    """Asynchronous rendering option for large/complex layers"""

    auto_source_layer_def_uid: int | None = None
    auto_tileset_def_uid: int | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `tilesetDefUid`
    """
    auto_tiles_killed_by_other_layer_uid: int | None = None
    """*This field was removed in 1.5.4 and should no longer be used.*"""

    biome_field_uid: int | None = None
    doc: str | None = None
    """User defined documentation for this element to provide help/tips to level designers."""

    guide_color: str | None = None
    """Color of the optional "guide" grid"""

    tileset_def_uid: int | None = None
    """Reference to the default Tileset UID being used by this layer definition.<br/>
    **WARNING**: some layer *instances* might use a different tileset. So most of the time,
    you should probably use the `__tilesetDefUid` value found in layer instances.<br/>  Note:
    since version 1.0.0, the old `autoTilesetDefUid` was removed and merged into this value.
    """
    ui_color: str | None = None
    """User defined color for the UI"""

    @staticmethod
    def from_dict(obj: Any) -> 'LayerDefinition':
        assert isinstance(obj, dict)
        type = from_str(obj.get("__type"))
        auto_rule_groups = from_list(AutoLayerRuleGroup.from_dict, obj.get("autoRuleGroups"))
        can_select_when_inactive = from_bool(obj.get("canSelectWhenInactive"))
        display_opacity = from_float(obj.get("displayOpacity"))
        entity_depth_sorting = EntityDepthSorting(obj.get("entityDepthSorting"))
        excluded_tags = from_list(from_str, obj.get("excludedTags"))
        grid_size = from_int(obj.get("gridSize"))
        guide_grid_hei = from_int(obj.get("guideGridHei"))
        guide_grid_wid = from_int(obj.get("guideGridWid"))
        guide_opacity = from_float(obj.get("guideOpacity"))
        hide_fields_when_inactive = from_bool(obj.get("hideFieldsWhenInactive"))
        hide_in_list = from_bool(obj.get("hideInList"))
        identifier = from_str(obj.get("identifier"))
        inactive_opacity = from_float(obj.get("inactiveOpacity"))
        int_grid_values = from_list(IntGridValueDefinition.from_dict, obj.get("intGridValues"))
        int_grid_values_groups = from_list(IntGridValueGroupDefinition.from_dict, obj.get("intGridValuesGroups"))
        layer_uids_preventing_auto_tiling_here = from_list(from_int, obj.get("layerUidsPreventingAutoTilingHere"))
        parallax_factor_x = from_float(obj.get("parallaxFactorX"))
        parallax_factor_y = from_float(obj.get("parallaxFactorY"))
        parallax_scaling = from_bool(obj.get("parallaxScaling"))
        px_offset_x = from_int(obj.get("pxOffsetX"))
        px_offset_y = from_int(obj.get("pxOffsetY"))
        render_in_world_view = from_bool(obj.get("renderInWorldView"))
        required_tags = from_list(from_str, obj.get("requiredTags"))
        tile_pivot_x = from_float(obj.get("tilePivotX"))
        tile_pivot_y = from_float(obj.get("tilePivotY"))
        layer_definition_type = TypeEnum(obj.get("type"))
        uid = from_int(obj.get("uid"))
        ui_filter_tags = from_list(from_str, obj.get("uiFilterTags"))
        use_async_render = from_bool(obj.get("useAsyncRender"))
        auto_source_layer_def_uid = from_union([from_none, from_int], obj.get("autoSourceLayerDefUid"))
        auto_tileset_def_uid = from_union([from_none, from_int], obj.get("autoTilesetDefUid"))
        auto_tiles_killed_by_other_layer_uid = from_union([from_none, from_int], obj.get("autoTilesKilledByOtherLayerUid"))
        biome_field_uid = from_union([from_none, from_int], obj.get("biomeFieldUid"))
        doc = from_union([from_none, from_str], obj.get("doc"))
        guide_color = from_union([from_none, from_str], obj.get("guideColor"))
        tileset_def_uid = from_union([from_none, from_int], obj.get("tilesetDefUid"))
        ui_color = from_union([from_none, from_str], obj.get("uiColor"))
        return LayerDefinition(type, auto_rule_groups, can_select_when_inactive, display_opacity, entity_depth_sorting, excluded_tags, grid_size, guide_grid_hei, guide_grid_wid, guide_opacity, hide_fields_when_inactive, hide_in_list, identifier, inactive_opacity, int_grid_values, int_grid_values_groups, layer_uids_preventing_auto_tiling_here, parallax_factor_x, parallax_factor_y, parallax_scaling, px_offset_x, px_offset_y, render_in_world_view, required_tags, tile_pivot_x, tile_pivot_y, layer_definition_type, uid, ui_filter_tags, use_async_render, auto_source_layer_def_uid, auto_tileset_def_uid, auto_tiles_killed_by_other_layer_uid, biome_field_uid, doc, guide_color, tileset_def_uid, ui_color)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__type"] = from_str(self.type)
        result["autoRuleGroups"] = from_list(lambda x: to_class(AutoLayerRuleGroup, x), self.auto_rule_groups)
        result["canSelectWhenInactive"] = from_bool(self.can_select_when_inactive)
        result["displayOpacity"] = to_float(self.display_opacity)
        result["entityDepthSorting"] = to_enum(EntityDepthSorting, self.entity_depth_sorting)
        result["excludedTags"] = from_list(from_str, self.excluded_tags)
        result["gridSize"] = from_int(self.grid_size)
        result["guideGridHei"] = from_int(self.guide_grid_hei)
        result["guideGridWid"] = from_int(self.guide_grid_wid)
        result["guideOpacity"] = to_float(self.guide_opacity)
        result["hideFieldsWhenInactive"] = from_bool(self.hide_fields_when_inactive)
        result["hideInList"] = from_bool(self.hide_in_list)
        result["identifier"] = from_str(self.identifier)
        result["inactiveOpacity"] = to_float(self.inactive_opacity)
        result["intGridValues"] = from_list(lambda x: to_class(IntGridValueDefinition, x), self.int_grid_values)
        result["intGridValuesGroups"] = from_list(lambda x: to_class(IntGridValueGroupDefinition, x), self.int_grid_values_groups)
        result["layerUidsPreventingAutoTilingHere"] = from_list(from_int, self.layer_uids_preventing_auto_tiling_here)
        result["parallaxFactorX"] = to_float(self.parallax_factor_x)
        result["parallaxFactorY"] = to_float(self.parallax_factor_y)
        result["parallaxScaling"] = from_bool(self.parallax_scaling)
        result["pxOffsetX"] = from_int(self.px_offset_x)
        result["pxOffsetY"] = from_int(self.px_offset_y)
        result["renderInWorldView"] = from_bool(self.render_in_world_view)
        result["requiredTags"] = from_list(from_str, self.required_tags)
        result["tilePivotX"] = to_float(self.tile_pivot_x)
        result["tilePivotY"] = to_float(self.tile_pivot_y)
        result["type"] = to_enum(TypeEnum, self.layer_definition_type)
        result["uid"] = from_int(self.uid)
        result["uiFilterTags"] = from_list(from_str, self.ui_filter_tags)
        result["useAsyncRender"] = from_bool(self.use_async_render)
        if self.auto_source_layer_def_uid is not None:
            result["autoSourceLayerDefUid"] = from_union([from_none, from_int], self.auto_source_layer_def_uid)
        if self.auto_tileset_def_uid is not None:
            result["autoTilesetDefUid"] = from_union([from_none, from_int], self.auto_tileset_def_uid)
        if self.auto_tiles_killed_by_other_layer_uid is not None:
            result["autoTilesKilledByOtherLayerUid"] = from_union([from_none, from_int], self.auto_tiles_killed_by_other_layer_uid)
        if self.biome_field_uid is not None:
            result["biomeFieldUid"] = from_union([from_none, from_int], self.biome_field_uid)
        if self.doc is not None:
            result["doc"] = from_union([from_none, from_str], self.doc)
        if self.guide_color is not None:
            result["guideColor"] = from_union([from_none, from_str], self.guide_color)
        if self.tileset_def_uid is not None:
            result["tilesetDefUid"] = from_union([from_none, from_int], self.tileset_def_uid)
        if self.ui_color is not None:
            result["uiColor"] = from_union([from_none, from_str], self.ui_color)
        return result


@dataclass
class TileCustomMetadata:
    """In a tileset definition, user defined meta-data of a tile."""

    data: str
    tile_id: int

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


@dataclass
class EnumTagValue:
    """In a tileset definition, enum based tag infos"""

    enum_value_id: str
    tile_ids: list[int]

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


@dataclass
class TilesetDefinition:
    """The `Tileset` definition is the most important part among project definitions. It
    contains some extra informations about each integrated tileset. If you only had to parse
    one definition section, that would be the one.
    """
    c_hei: int
    """Grid-based height"""

    c_wid: int
    """Grid-based width"""

    custom_data: list[TileCustomMetadata]
    """An array of custom tile metadata"""

    enum_tags: list[EnumTagValue]
    """Tileset tags using Enum values specified by `tagsSourceEnumId`. This array contains 1
    element per Enum value, which contains an array of all Tile IDs that are tagged with it.
    """
    identifier: str
    """User defined unique identifier"""

    padding: int
    """Distance in pixels from image borders"""

    px_hei: int
    """Image height in pixels"""

    px_wid: int
    """Image width in pixels"""

    saved_selections: list[dict[str, Any]]
    """Array of group of tiles selections, only meant to be used in the editor"""

    spacing: int
    """Space in pixels between all tiles"""

    tags: list[str]
    """An array of user-defined tags to organize the Tilesets"""

    tile_grid_size: int
    uid: int
    """Unique Intidentifier"""

    cached_pixel_data: dict[str, Any] | None = None
    """The following data is used internally for various optimizations. It's always synced with
    source image changes.
    """
    embed_atlas: EmbedAtlas | None = None
    """If this value is set, then it means that this atlas uses an internal LDtk atlas image
    instead of a loaded one. Possible values: &lt;`null`&gt;, `LdtkIcons`
    """
    rel_path: str | None = None
    """Path to the source file, relative to the current project JSON file<br/>  It can be null
    if no image was provided, or when using an embed atlas.
    """
    tags_source_enum_uid: int | None = None
    """Optional Enum definition UID used for this tileset meta-data"""

    @staticmethod
    def from_dict(obj: Any) -> 'TilesetDefinition':
        assert isinstance(obj, dict)
        c_hei = from_int(obj.get("__cHei"))
        c_wid = from_int(obj.get("__cWid"))
        custom_data = from_list(TileCustomMetadata.from_dict, obj.get("customData"))
        enum_tags = from_list(EnumTagValue.from_dict, obj.get("enumTags"))
        identifier = from_str(obj.get("identifier"))
        padding = from_int(obj.get("padding"))
        px_hei = from_int(obj.get("pxHei"))
        px_wid = from_int(obj.get("pxWid"))
        saved_selections = from_list(lambda x: from_dict(lambda x: x, x), obj.get("savedSelections"))
        spacing = from_int(obj.get("spacing"))
        tags = from_list(from_str, obj.get("tags"))
        tile_grid_size = from_int(obj.get("tileGridSize"))
        uid = from_int(obj.get("uid"))
        cached_pixel_data = from_union([from_none, lambda x: from_dict(lambda x: x, x)], obj.get("cachedPixelData"))
        embed_atlas = from_union([from_none, EmbedAtlas], obj.get("embedAtlas"))
        rel_path = from_union([from_none, from_str], obj.get("relPath"))
        tags_source_enum_uid = from_union([from_none, from_int], obj.get("tagsSourceEnumUid"))
        return TilesetDefinition(c_hei, c_wid, custom_data, enum_tags, identifier, padding, px_hei, px_wid, saved_selections, spacing, tags, tile_grid_size, uid, cached_pixel_data, embed_atlas, rel_path, tags_source_enum_uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__cHei"] = from_int(self.c_hei)
        result["__cWid"] = from_int(self.c_wid)
        result["customData"] = from_list(lambda x: to_class(TileCustomMetadata, x), self.custom_data)
        result["enumTags"] = from_list(lambda x: to_class(EnumTagValue, x), self.enum_tags)
        result["identifier"] = from_str(self.identifier)
        result["padding"] = from_int(self.padding)
        result["pxHei"] = from_int(self.px_hei)
        result["pxWid"] = from_int(self.px_wid)
        result["savedSelections"] = from_list(lambda x: from_dict(lambda x: x, x), self.saved_selections)
        result["spacing"] = from_int(self.spacing)
        result["tags"] = from_list(from_str, self.tags)
        result["tileGridSize"] = from_int(self.tile_grid_size)
        result["uid"] = from_int(self.uid)
        if self.cached_pixel_data is not None:
            result["cachedPixelData"] = from_union([from_none, lambda x: from_dict(lambda x: x, x)], self.cached_pixel_data)
        if self.embed_atlas is not None:
            result["embedAtlas"] = from_union([from_none, lambda x: to_enum(EmbedAtlas, x)], self.embed_atlas)
        if self.rel_path is not None:
            result["relPath"] = from_union([from_none, from_str], self.rel_path)
        if self.tags_source_enum_uid is not None:
            result["tagsSourceEnumUid"] = from_union([from_none, from_int], self.tags_source_enum_uid)
        return result


@dataclass
class Definitions:
    """If you're writing your own LDtk importer, you should probably just ignore *most* stuff in
    the `defs` section, as it contains data that are mostly important to the editor. To keep
    you away from the `defs` section and avoid some unnecessary JSON parsing, important data
    from definitions is often duplicated in fields prefixed with a double underscore (eg.
    `__identifier` or `__type`).  The 2 only definition types you might need here are
    **Tilesets** and **Enums**.
    
    A structure containing all the definitions of this project
    """
    entities: list[EntityDefinition]
    """All entities definitions, including their custom fields"""

    enums: list[EnumDefinition]
    """All internal enums"""

    external_enums: list[EnumDefinition]
    """Note: external enums are exactly the same as `enums`, except they have a `relPath` to
    point to an external source file.
    """
    layers: list[LayerDefinition]
    """All layer definitions"""

    level_fields: list[FieldDefinition]
    """All custom fields available to all levels."""

    tilesets: list[TilesetDefinition]
    """All tilesets"""

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
    EXPORT_OLD_TABLE_OF_CONTENT_DATA = "ExportOldTableOfContentData"
    EXPORT_PRE_CSV_INT_GRID_FORMAT = "ExportPreCsvIntGridFormat"
    IGNORE_BACKUP_SUGGEST = "IgnoreBackupSuggest"
    MULTI_WORLDS = "MultiWorlds"
    PREPEND_INDEX_TO_LEVEL_FILE_NAMES = "PrependIndexToLevelFileNames"
    USE_MULTILINES_TYPE = "UseMultilinesType"


@dataclass
class FieldInstance:
    identifier: str
    """Field definition identifier"""

    type: str
    """Type of the field, such as `Int`, `Float`, `String`, `Enum(my_enum_name)`, `Bool`,
    etc.<br/>  NOTE: if you enable the advanced option **Use Multilines type**, you will have
    "*Multilines*" instead of "*String*" when relevant.
    """
    def_uid: int
    """Reference of the **Field definition** UID"""

    real_editor_values: list[Any]
    """Editor internal raw values"""

    tile: TilesetRectangle | None = None
    """Optional TilesetRect used to display this field (this can be the field own Tile, or some
    other Tile guessed from the value, like an Enum).
    """
    value: Any = None
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

    @staticmethod
    def from_dict(obj: Any) -> 'FieldInstance':
        assert isinstance(obj, dict)
        identifier = from_str(obj.get("__identifier"))
        type = from_str(obj.get("__type"))
        def_uid = from_int(obj.get("defUid"))
        real_editor_values = from_list(lambda x: x, obj.get("realEditorValues"))
        tile = from_union([from_none, TilesetRectangle.from_dict], obj.get("__tile"))
        value = obj.get("__value")
        return FieldInstance(identifier, type, def_uid, real_editor_values, tile, value)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__identifier"] = from_str(self.identifier)
        result["__type"] = from_str(self.type)
        result["defUid"] = from_int(self.def_uid)
        result["realEditorValues"] = from_list(lambda x: x, self.real_editor_values)
        if self.tile is not None:
            result["__tile"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile)
        result["__value"] = self.value
        return result


@dataclass
class EntityInstance:
    grid: list[int]
    """Grid-based coordinates (`[x,y]` format)"""

    identifier: str
    """Entity definition identifier"""

    pivot: list[float]
    """Pivot coordinates  (`[x,y]` format, values are from 0 to 1) of the Entity"""

    smart_color: str
    """The entity "smart" color, guessed from either Entity definition, or one its field
    instances.
    """
    tags: list[str]
    """Array of tags defined in this Entity definition"""

    def_uid: int
    """Reference of the **Entity definition** UID"""

    field_instances: list[FieldInstance]
    """An array of all custom fields and their values."""

    height: int
    """Entity height in pixels. For non-resizable entities, it will be the same as Entity
    definition.
    """
    iid: str
    """Unique instance identifier"""

    px: list[int]
    """Pixel coordinates (`[x,y]` format) in current level coordinate space. Don't forget
    optional layer offsets, if they exist!
    """
    width: int
    """Entity width in pixels. For non-resizable entities, it will be the same as Entity
    definition.
    """
    tile: TilesetRectangle | None = None
    """Optional TilesetRect used to display this entity (it could either be the default Entity
    tile, or some tile provided by a field value, like an Enum).
    """
    world_x: int | None = None
    """X world coordinate in pixels. Only available in GridVania or Free world layouts."""

    world_y: int | None = None
    """Y world coordinate in pixels Only available in GridVania or Free world layouts."""

    @staticmethod
    def from_dict(obj: Any) -> 'EntityInstance':
        assert isinstance(obj, dict)
        grid = from_list(from_int, obj.get("__grid"))
        identifier = from_str(obj.get("__identifier"))
        pivot = from_list(from_float, obj.get("__pivot"))
        smart_color = from_str(obj.get("__smartColor"))
        tags = from_list(from_str, obj.get("__tags"))
        def_uid = from_int(obj.get("defUid"))
        field_instances = from_list(FieldInstance.from_dict, obj.get("fieldInstances"))
        height = from_int(obj.get("height"))
        iid = from_str(obj.get("iid"))
        px = from_list(from_int, obj.get("px"))
        width = from_int(obj.get("width"))
        tile = from_union([from_none, TilesetRectangle.from_dict], obj.get("__tile"))
        world_x = from_union([from_none, from_int], obj.get("__worldX"))
        world_y = from_union([from_none, from_int], obj.get("__worldY"))
        return EntityInstance(grid, identifier, pivot, smart_color, tags, def_uid, field_instances, height, iid, px, width, tile, world_x, world_y)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__grid"] = from_list(from_int, self.grid)
        result["__identifier"] = from_str(self.identifier)
        result["__pivot"] = from_list(to_float, self.pivot)
        result["__smartColor"] = from_str(self.smart_color)
        result["__tags"] = from_list(from_str, self.tags)
        result["defUid"] = from_int(self.def_uid)
        result["fieldInstances"] = from_list(lambda x: to_class(FieldInstance, x), self.field_instances)
        result["height"] = from_int(self.height)
        result["iid"] = from_str(self.iid)
        result["px"] = from_list(from_int, self.px)
        result["width"] = from_int(self.width)
        if self.tile is not None:
            result["__tile"] = from_union([from_none, lambda x: to_class(TilesetRectangle, x)], self.tile)
        if self.world_x is not None:
            result["__worldX"] = from_union([from_none, from_int], self.world_x)
        if self.world_y is not None:
            result["__worldY"] = from_union([from_none, from_int], self.world_y)
        return result


@dataclass
class ReferenceToAnEntityInstance:
    """This object describes the "location" of an Entity instance in the project worlds.
    
    IID information of this instance
    """
    entity_iid: str
    """IID of the refered EntityInstance"""

    layer_iid: str
    """IID of the LayerInstance containing the refered EntityInstance"""

    level_iid: str
    """IID of the Level containing the refered EntityInstance"""

    world_iid: str
    """IID of the World containing the refered EntityInstance"""

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


@dataclass
class GridPoint:
    """This object is just a grid-based coordinate used in Field values."""

    cx: int
    """X grid-based coordinate"""

    cy: int
    """Y grid-based coordinate"""

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


@dataclass
class IntGridValueInstance:
    """IntGrid value instance"""

    coord_id: int
    """Coordinate ID in the layer grid"""

    v: int
    """IntGrid value"""

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


@dataclass
class TileInstance:
    """This structure represents a single tile from a given Tileset."""

    a: float
    """Alpha/opacity of the tile (0-1, defaults to 1)"""

    d: list[int]
    """Internal data used by the editor.<br/>  For auto-layer tiles: `[ruleId, coordId]`.<br/>
    For tile-layer tiles: `[coordId]`.
    """
    f: int
    """"Flip bits", a 2-bits integer to represent the mirror transformations of the tile.<br/>
    - Bit 0 = X flip<br/>   - Bit 1 = Y flip<br/>   Examples: f=0 (no flip), f=1 (X flip
    only), f=2 (Y flip only), f=3 (both flips)
    """
    px: list[int]
    """Pixel coordinates of the tile in the **layer** (`[x,y]` format). Don't forget optional
    layer offsets, if they exist!
    """
    src: list[int]
    """Pixel coordinates of the tile in the **tileset** (`[x,y]` format)"""

    t: int
    """The *Tile ID* in the corresponding tileset."""

    @staticmethod
    def from_dict(obj: Any) -> 'TileInstance':
        assert isinstance(obj, dict)
        a = from_float(obj.get("a"))
        d = from_list(from_int, obj.get("d"))
        f = from_int(obj.get("f"))
        px = from_list(from_int, obj.get("px"))
        src = from_list(from_int, obj.get("src"))
        t = from_int(obj.get("t"))
        return TileInstance(a, d, f, px, src, t)

    def to_dict(self) -> dict:
        result: dict = {}
        result["a"] = to_float(self.a)
        result["d"] = from_list(from_int, self.d)
        result["f"] = from_int(self.f)
        result["px"] = from_list(from_int, self.px)
        result["src"] = from_list(from_int, self.src)
        result["t"] = from_int(self.t)
        return result


@dataclass
class LayerInstance:
    c_hei: int
    """Grid-based height"""

    c_wid: int
    """Grid-based width"""

    grid_size: int
    """Grid size"""

    identifier: str
    """Layer definition identifier"""

    opacity: float
    """Layer opacity as Float [0-1]"""

    px_total_offset_x: int
    """Total layer X pixel offset, including both instance and definition offsets."""

    px_total_offset_y: int
    """Total layer Y pixel offset, including both instance and definition offsets."""

    type: str
    """Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer)"""

    auto_layer_tiles: list[TileInstance]
    """An array containing all tiles generated by Auto-layer rules. The array is already sorted
    in display order (ie. 1st tile is beneath 2nd, which is beneath 3rd etc.).<br/><br/>
    Note: if multiple tiles are stacked in the same cell as the result of different rules,
    all tiles behind opaque ones will be discarded.
    """
    entity_instances: list[EntityInstance]
    grid_tiles: list[TileInstance]
    iid: str
    """Unique layer instance identifier"""

    int_grid_csv: list[int]
    """A list of all values in the IntGrid layer, stored in CSV format (Comma Separated
    Values).<br/>  Order is from left to right, and top to bottom (ie. first row from left to
    right, followed by second row, etc).<br/>  `0` means "empty cell" and IntGrid values
    start at 1.<br/>  The array size is `__cWid` x `__cHei` cells.
    """
    layer_def_uid: int
    """Reference the Layer definition UID"""

    level_id: int
    """Reference to the UID of the level containing this layer instance"""

    optional_rules: list[int]
    """An Array containing the UIDs of optional rules that were enabled in this specific layer
    instance.
    """
    px_offset_x: int
    """X offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
    which contains the total offset value)
    """
    px_offset_y: int
    """Y offset in pixels to render this layer, usually 0 (IMPORTANT: this should be added to
    the `LayerDef` optional offset, so you should probably prefer using `__pxTotalOffsetX`
    which contains the total offset value)
    """
    seed: int
    """Random seed used for Auto-Layers rendering"""

    visible: bool
    """Layer instance visibility"""

    tileset_def_uid: int | None = None
    """The definition UID of corresponding Tileset, if any."""

    tileset_rel_path: str | None = None
    """The relative path to corresponding Tileset, if any."""

    int_grid: list[IntGridValueInstance] | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.0.0  Replaced
    by: `intGridCsv`
    """
    override_tileset_uid: int | None = None
    """This layer can use another tileset by overriding the tileset UID here."""

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
        type = from_str(obj.get("__type"))
        auto_layer_tiles = from_list(TileInstance.from_dict, obj.get("autoLayerTiles"))
        entity_instances = from_list(EntityInstance.from_dict, obj.get("entityInstances"))
        grid_tiles = from_list(TileInstance.from_dict, obj.get("gridTiles"))
        iid = from_str(obj.get("iid"))
        int_grid_csv = from_list(from_int, obj.get("intGridCsv"))
        layer_def_uid = from_int(obj.get("layerDefUid"))
        level_id = from_int(obj.get("levelId"))
        optional_rules = from_list(from_int, obj.get("optionalRules"))
        px_offset_x = from_int(obj.get("pxOffsetX"))
        px_offset_y = from_int(obj.get("pxOffsetY"))
        seed = from_int(obj.get("seed"))
        visible = from_bool(obj.get("visible"))
        tileset_def_uid = from_union([from_none, from_int], obj.get("__tilesetDefUid"))
        tileset_rel_path = from_union([from_none, from_str], obj.get("__tilesetRelPath"))
        int_grid = from_union([from_none, lambda x: from_list(IntGridValueInstance.from_dict, x)], obj.get("intGrid"))
        override_tileset_uid = from_union([from_none, from_int], obj.get("overrideTilesetUid"))
        return LayerInstance(c_hei, c_wid, grid_size, identifier, opacity, px_total_offset_x, px_total_offset_y, type, auto_layer_tiles, entity_instances, grid_tiles, iid, int_grid_csv, layer_def_uid, level_id, optional_rules, px_offset_x, px_offset_y, seed, visible, tileset_def_uid, tileset_rel_path, int_grid, override_tileset_uid)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__cHei"] = from_int(self.c_hei)
        result["__cWid"] = from_int(self.c_wid)
        result["__gridSize"] = from_int(self.grid_size)
        result["__identifier"] = from_str(self.identifier)
        result["__opacity"] = to_float(self.opacity)
        result["__pxTotalOffsetX"] = from_int(self.px_total_offset_x)
        result["__pxTotalOffsetY"] = from_int(self.px_total_offset_y)
        result["__type"] = from_str(self.type)
        result["autoLayerTiles"] = from_list(lambda x: to_class(TileInstance, x), self.auto_layer_tiles)
        result["entityInstances"] = from_list(lambda x: to_class(EntityInstance, x), self.entity_instances)
        result["gridTiles"] = from_list(lambda x: to_class(TileInstance, x), self.grid_tiles)
        result["iid"] = from_str(self.iid)
        result["intGridCsv"] = from_list(from_int, self.int_grid_csv)
        result["layerDefUid"] = from_int(self.layer_def_uid)
        result["levelId"] = from_int(self.level_id)
        result["optionalRules"] = from_list(from_int, self.optional_rules)
        result["pxOffsetX"] = from_int(self.px_offset_x)
        result["pxOffsetY"] = from_int(self.px_offset_y)
        result["seed"] = from_int(self.seed)
        result["visible"] = from_bool(self.visible)
        if self.tileset_def_uid is not None:
            result["__tilesetDefUid"] = from_union([from_none, from_int], self.tileset_def_uid)
        if self.tileset_rel_path is not None:
            result["__tilesetRelPath"] = from_union([from_none, from_str], self.tileset_rel_path)
        if self.int_grid is not None:
            result["intGrid"] = from_union([from_none, lambda x: from_list(lambda x: to_class(IntGridValueInstance, x), x)], self.int_grid)
        if self.override_tileset_uid is not None:
            result["overrideTilesetUid"] = from_union([from_none, from_int], self.override_tileset_uid)
        return result


@dataclass
class LevelBackgroundPosition:
    """Level background image position info"""

    crop_rect: list[float]
    """An array of 4 float values describing the cropped sub-rectangle of the displayed
    background image. This cropping happens when original is larger than the level bounds.
    Array format: `[ cropX, cropY, cropWidth, cropHeight ]`
    """
    scale: list[float]
    """An array containing the `[scaleX,scaleY]` values of the **cropped** background image,
    depending on `bgPos` option.
    """
    top_left_px: list[int]
    """An array containing the `[x,y]` pixel coordinates of the top-left corner of the
    **cropped** background image, depending on `bgPos` option.
    """

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


@dataclass
class NeighbourLevel:
    """Nearby level info"""

    dir: str
    """A lowercase string tipping on the level location (`n`orth, `s`outh, `w`est,
    `e`ast).<br/>  Since 1.4.0, this value can also be `<` (neighbour depth is lower), `>`
    (neighbour depth is greater) or `o` (levels overlap and share the same world
    depth).<br/>  Since 1.5.3, this value can also be `nw`,`ne`,`sw` or `se` for levels only
    touching corners.
    """
    level_iid: str
    """Neighbour Instance Identifier"""

    level_uid: int | None = None
    """**WARNING**: this deprecated value is no longer exported since version 1.2.0  Replaced
    by: `levelIid`
    """

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


@dataclass
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
    bg_color: str
    """Background color of the level (same as `bgColor`, except the default value is
    automatically used here if its value is `null`)
    """
    neighbours: list[NeighbourLevel]
    """An array listing all other levels touching this one on the world map. Since 1.4.0, this
    includes levels that overlap in the same world layer, or in nearby world layers.<br/>
    Only relevant for world layouts where level spatial positioning is manual (ie. GridVania,
    Free). For Horizontal and Vertical layouts, this array is always empty.
    """
    smart_color: str
    """The "guessed" color for this level in the editor, decided using either the background
    color or an existing custom field.
    """
    bg_pivot_x: float
    """Background image X pivot (0-1)"""

    bg_pivot_y: float
    """Background image Y pivot (0-1)"""

    field_instances: list[FieldInstance]
    """An array containing this level custom field values."""

    identifier: str
    """User defined unique identifier"""

    iid: str
    """Unique instance identifier"""

    px_hei: int
    """Height of the level in pixels"""

    px_wid: int
    """Width of the level in pixels"""

    uid: int
    """Unique Int identifier"""

    use_auto_identifier: bool
    """If TRUE, the level identifier will always automatically use the naming pattern as defined
    in `Project.levelNamePattern`. Becomes FALSE if the identifier is manually modified by
    user.
    """
    world_depth: int
    """Index that represents the "depth" of the level in the world. Default is 0, greater means
    "above", lower means "below".<br/>  This value is mostly used for display only and is
    intended to make stacking of levels easier to manage.
    """
    world_x: int
    """World X coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    value is always -1 here.
    """
    world_y: int
    """World Y coordinate in pixels.<br/>  Only relevant for world layouts where level spatial
    positioning is manual (ie. GridVania, Free). For Horizontal and Vertical layouts, the
    value is always -1 here.
    """
    bg_pos: LevelBackgroundPosition | None = None
    """Position informations of the background image, if there is one."""

    level_bg_color: str | None = None
    """Background color of the level. If `null`, the project `defaultLevelBgColor` should be
    used.
    """
    level_bg_pos: BgPos | None = None
    """An enum defining the way the background image (if any) is positioned on the level. See
    `__bgPos` for resulting position info. Possible values: &lt;`null`&gt;, `Unscaled`,
    `Contain`, `Cover`, `CoverDirty`, `Repeat`
    """
    bg_rel_path: str | None = None
    """The *optional* relative path to the level background image."""

    external_rel_path: str | None = None
    """This value is not null if the project option "*Save levels separately*" is enabled. In
    this case, this **relative** path points to the level Json file.
    """
    layer_instances: list[LayerInstance] | None = None
    """An array containing all Layer instances. **IMPORTANT**: if the project option "*Save
    levels separately*" is enabled, this field will be `null`.<br/>  This array is **sorted
    in display order**: the 1st layer is the top-most and the last is behind.
    """

    @staticmethod
    def from_dict(obj: Any) -> 'Level':
        assert isinstance(obj, dict)
        bg_color = from_str(obj.get("__bgColor"))
        neighbours = from_list(NeighbourLevel.from_dict, obj.get("__neighbours"))
        smart_color = from_str(obj.get("__smartColor"))
        bg_pivot_x = from_float(obj.get("bgPivotX"))
        bg_pivot_y = from_float(obj.get("bgPivotY"))
        field_instances = from_list(FieldInstance.from_dict, obj.get("fieldInstances"))
        identifier = from_str(obj.get("identifier"))
        iid = from_str(obj.get("iid"))
        px_hei = from_int(obj.get("pxHei"))
        px_wid = from_int(obj.get("pxWid"))
        uid = from_int(obj.get("uid"))
        use_auto_identifier = from_bool(obj.get("useAutoIdentifier"))
        world_depth = from_int(obj.get("worldDepth"))
        world_x = from_int(obj.get("worldX"))
        world_y = from_int(obj.get("worldY"))
        bg_pos = from_union([from_none, LevelBackgroundPosition.from_dict], obj.get("__bgPos"))
        level_bg_color = from_union([from_none, from_str], obj.get("bgColor"))
        level_bg_pos = from_union([from_none, BgPos], obj.get("bgPos"))
        bg_rel_path = from_union([from_none, from_str], obj.get("bgRelPath"))
        external_rel_path = from_union([from_none, from_str], obj.get("externalRelPath"))
        layer_instances = from_union([from_none, lambda x: from_list(LayerInstance.from_dict, x)], obj.get("layerInstances"))
        return Level(bg_color, neighbours, smart_color, bg_pivot_x, bg_pivot_y, field_instances, identifier, iid, px_hei, px_wid, uid, use_auto_identifier, world_depth, world_x, world_y, bg_pos, level_bg_color, level_bg_pos, bg_rel_path, external_rel_path, layer_instances)

    def to_dict(self) -> dict:
        result: dict = {}
        result["__bgColor"] = from_str(self.bg_color)
        result["__neighbours"] = from_list(lambda x: to_class(NeighbourLevel, x), self.neighbours)
        result["__smartColor"] = from_str(self.smart_color)
        result["bgPivotX"] = to_float(self.bg_pivot_x)
        result["bgPivotY"] = to_float(self.bg_pivot_y)
        result["fieldInstances"] = from_list(lambda x: to_class(FieldInstance, x), self.field_instances)
        result["identifier"] = from_str(self.identifier)
        result["iid"] = from_str(self.iid)
        result["pxHei"] = from_int(self.px_hei)
        result["pxWid"] = from_int(self.px_wid)
        result["uid"] = from_int(self.uid)
        result["useAutoIdentifier"] = from_bool(self.use_auto_identifier)
        result["worldDepth"] = from_int(self.world_depth)
        result["worldX"] = from_int(self.world_x)
        result["worldY"] = from_int(self.world_y)
        if self.bg_pos is not None:
            result["__bgPos"] = from_union([from_none, lambda x: to_class(LevelBackgroundPosition, x)], self.bg_pos)
        if self.level_bg_color is not None:
            result["bgColor"] = from_union([from_none, from_str], self.level_bg_color)
        if self.level_bg_pos is not None:
            result["bgPos"] = from_union([from_none, lambda x: to_enum(BgPos, x)], self.level_bg_pos)
        if self.bg_rel_path is not None:
            result["bgRelPath"] = from_union([from_none, from_str], self.bg_rel_path)
        if self.external_rel_path is not None:
            result["externalRelPath"] = from_union([from_none, from_str], self.external_rel_path)
        if self.layer_instances is not None:
            result["layerInstances"] = from_union([from_none, lambda x: from_list(lambda x: to_class(LayerInstance, x), x)], self.layer_instances)
        return result


@dataclass
class LdtkTocInstanceData:
    hei_px: int
    iids: ReferenceToAnEntityInstance
    """IID information of this instance"""

    wid_px: int
    world_x: int
    world_y: int
    fields: Any = None
    """An object containing the values of all entity fields with the `exportToToc` option
    enabled. This object typing depends on actual field value types.
    """

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkTocInstanceData':
        assert isinstance(obj, dict)
        hei_px = from_int(obj.get("heiPx"))
        iids = ReferenceToAnEntityInstance.from_dict(obj.get("iids"))
        wid_px = from_int(obj.get("widPx"))
        world_x = from_int(obj.get("worldX"))
        world_y = from_int(obj.get("worldY"))
        fields = obj.get("fields")
        return LdtkTocInstanceData(hei_px, iids, wid_px, world_x, world_y, fields)

    def to_dict(self) -> dict:
        result: dict = {}
        result["heiPx"] = from_int(self.hei_px)
        result["iids"] = to_class(ReferenceToAnEntityInstance, self.iids)
        result["widPx"] = from_int(self.wid_px)
        result["worldX"] = from_int(self.world_x)
        result["worldY"] = from_int(self.world_y)
        result["fields"] = self.fields
        return result


@dataclass
class LdtkTableOfContentEntry:
    identifier: str
    instances_data: list[LdtkTocInstanceData]
    instances: list[ReferenceToAnEntityInstance] | None = None
    """**WARNING**: this deprecated value will be *removed* completely on version 1.7.0+
    Replaced by: `instancesData`
    """

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkTableOfContentEntry':
        assert isinstance(obj, dict)
        identifier = from_str(obj.get("identifier"))
        instances_data = from_list(LdtkTocInstanceData.from_dict, obj.get("instancesData"))
        instances = from_union([lambda x: from_list(ReferenceToAnEntityInstance.from_dict, x), from_none], obj.get("instances"))
        return LdtkTableOfContentEntry(identifier, instances_data, instances)

    def to_dict(self) -> dict:
        result: dict = {}
        result["identifier"] = from_str(self.identifier)
        result["instancesData"] = from_list(lambda x: to_class(LdtkTocInstanceData, x), self.instances_data)
        if self.instances is not None:
            result["instances"] = from_union([lambda x: from_list(lambda x: to_class(ReferenceToAnEntityInstance, x), x), from_none], self.instances)
        return result


class WorldLayout(Enum):
    FREE = "Free"
    GRID_VANIA = "GridVania"
    LINEAR_HORIZONTAL = "LinearHorizontal"
    LINEAR_VERTICAL = "LinearVertical"


@dataclass
class World:
    """**IMPORTANT**: this type is available as a preview. You can rely on it to update your
    importers, for when it will be officially available.  A World contains multiple levels,
    and it has its own layout settings.
    """
    default_level_height: int
    """Default new level height"""

    default_level_width: int
    """Default new level width"""

    identifier: str
    """User defined unique identifier"""

    iid: str
    """Unique instance identifer"""

    levels: list[Level]
    """All levels from this world. The order of this array is only relevant in
    `LinearHorizontal` and `linearVertical` world layouts (see `worldLayout` value).
    Otherwise, you should refer to the `worldX`,`worldY` coordinates of each Level.
    """
    world_grid_height: int
    """Height of the world grid in pixels."""

    world_grid_width: int
    """Width of the world grid in pixels."""

    world_layout: WorldLayout | None = None
    """An enum that describes how levels are organized in this project (ie. linearly or in a 2D
    space). Possible values: `Free`, `GridVania`, `LinearHorizontal`, `LinearVertical`, `null`
    """

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


@dataclass
class ForcedRefs:
    """This object is not actually used by LDtk. It ONLY exists to force explicit references to
    all types, to make sure QuickType finds them and integrate all of them. Otherwise,
    Quicktype will drop types that are not explicitely used.
    """
    auto_layer_rule_group: AutoLayerRuleGroup | None = None
    auto_rule_def: AutoLayerRuleDefinition | None = None
    custom_command: LdtkCustomCommand | None = None
    definitions: Definitions | None = None
    entity_def: EntityDefinition | None = None
    entity_instance: EntityInstance | None = None
    entity_reference_infos: ReferenceToAnEntityInstance | None = None
    enum_def: EnumDefinition | None = None
    enum_def_values: EnumValueDefinition | None = None
    enum_tag_value: EnumTagValue | None = None
    field_def: FieldDefinition | None = None
    field_instance: FieldInstance | None = None
    grid_point: GridPoint | None = None
    int_grid_value_def: IntGridValueDefinition | None = None
    int_grid_value_group_def: IntGridValueGroupDefinition | None = None
    int_grid_value_instance: IntGridValueInstance | None = None
    layer_def: LayerDefinition | None = None
    layer_instance: LayerInstance | None = None
    level: Level | None = None
    level_bg_pos_infos: LevelBackgroundPosition | None = None
    neighbour_level: NeighbourLevel | None = None
    table_of_content_entry: LdtkTableOfContentEntry | None = None
    tile: TileInstance | None = None
    tile_custom_metadata: TileCustomMetadata | None = None
    tileset_def: TilesetDefinition | None = None
    tileset_rect: TilesetRectangle | None = None
    toc_instance_data: LdtkTocInstanceData | None = None
    world: World | None = None

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
        int_grid_value_group_def = from_union([IntGridValueGroupDefinition.from_dict, from_none], obj.get("IntGridValueGroupDef"))
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
        toc_instance_data = from_union([LdtkTocInstanceData.from_dict, from_none], obj.get("TocInstanceData"))
        world = from_union([World.from_dict, from_none], obj.get("World"))
        return ForcedRefs(auto_layer_rule_group, auto_rule_def, custom_command, definitions, entity_def, entity_instance, entity_reference_infos, enum_def, enum_def_values, enum_tag_value, field_def, field_instance, grid_point, int_grid_value_def, int_grid_value_group_def, int_grid_value_instance, layer_def, layer_instance, level, level_bg_pos_infos, neighbour_level, table_of_content_entry, tile, tile_custom_metadata, tileset_def, tileset_rect, toc_instance_data, world)

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
        if self.int_grid_value_group_def is not None:
            result["IntGridValueGroupDef"] = from_union([lambda x: to_class(IntGridValueGroupDefinition, x), from_none], self.int_grid_value_group_def)
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
        if self.toc_instance_data is not None:
            result["TocInstanceData"] = from_union([lambda x: to_class(LdtkTocInstanceData, x), from_none], self.toc_instance_data)
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


class JSONStyle(Enum):
    """JSON style Possible values: `Minified`, `Compact`, `Full`"""

    COMPACT = "Compact"
    FULL = "Full"
    MINIFIED = "Minified"


@dataclass
class LdtkJSON:
    """This file is a JSON schema of files created by LDtk level editor (https://ldtk.io).
    
    This is the root of any Project JSON file. It contains:  - the project settings, - an
    array of levels, - a group of definitions (that can probably be safely ignored for most
    users).
    """
    app_build_id: float
    """LDtk application build identifier.<br/>  This is only used to identify the LDtk version
    that generated this particular project file, which can be useful for specific bug fixing.
    Note that the build identifier is just the date of the release, so it's not unique to
    each user (one single global ID per LDtk public release), and as a result, completely
    anonymous.
    """
    backup_limit: int
    """Number of backup files to keep, if the `backupOnSave` is TRUE"""

    backup_on_save: bool
    """If TRUE, an extra copy of the project will be created in a sub folder, when saving."""

    bg_color: str
    """Project background color"""

    custom_commands: list[LdtkCustomCommand]
    """An array of command lines that can be ran manually by the user"""

    default_entity_height: int
    """Default height for new entities"""

    default_entity_width: int
    """Default width for new entities"""

    default_grid_size: int
    """Default grid size for new layers"""

    default_level_bg_color: str
    """Default background color of levels"""

    default_pivot_x: float
    """Default X pivot (0 to 1) for new entities"""

    default_pivot_y: float
    """Default Y pivot (0 to 1) for new entities"""

    defs: Definitions
    """A structure containing all the definitions of this project"""

    dummy_world_iid: str
    """If the project isn't in MultiWorlds mode, this is the IID of the internal "dummy" World."""

    export_level_bg: bool
    """If TRUE, the exported PNGs will include the level background (color or image)."""

    export_tiled: bool
    """If TRUE, a Tiled compatible file will also be generated along with the LDtk JSON file
    (default is FALSE)
    """
    external_levels: bool
    """If TRUE, one file will be saved for the project (incl. all its definitions) and one file
    in a sub-folder for each level.
    """
    flags: list[Flag]
    """An array containing various advanced flags (ie. options or other states). Possible
    values: `DiscardPreCsvIntGrid`, `ExportOldTableOfContentData`,
    `ExportPreCsvIntGridFormat`, `IgnoreBackupSuggest`, `PrependIndexToLevelFileNames`,
    `MultiWorlds`, `UseMultilinesType`
    """
    identifier_style: IdentifierStyle
    """Naming convention for Identifiers (first-letter uppercase, full uppercase etc.) Possible
    values: `Capitalize`, `Uppercase`, `Lowercase`, `Free`
    """
    iid: str
    """Unique project identifier"""

    image_export_mode: ImageExportMode
    """"Image export" option when saving project. Possible values: `None`, `OneImagePerLayer`,
    `OneImagePerLevel`, `LayersAndLevels`
    """
    json_style: JSONStyle
    """JSON style Possible values: `Minified`, `Compact`, `Full`"""

    json_version: str
    """File format version"""

    level_name_pattern: str
    """The default naming convention for level identifiers."""

    levels: list[Level]
    """All levels. The order of this array is only relevant in `LinearHorizontal` and
    `linearVertical` world layouts (see `worldLayout` value).<br/>  Otherwise, you should
    refer to the `worldX`,`worldY` coordinates of each Level.
    """
    next_uid: int
    """Next Unique integer ID available"""

    simplified_export: bool
    """If TRUE, a very simplified will be generated on saving, for quicker & easier engine
    integration.
    """
    toc: list[LdtkTableOfContentEntry]
    """All instances of entities that have their `exportToToc` flag enabled are listed in this
    array.
    """
    worlds: list[World]
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
    forced_refs: ForcedRefs | None = None
    """This object is not actually used by LDtk. It ONLY exists to force explicit references to
    all types, to make sure QuickType finds them and integrate all of them. Otherwise,
    Quicktype will drop types that are not explicitely used.
    """
    backup_rel_path: str | None = None
    """Target relative path to store backup files"""

    default_level_height: int | None = None
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Default new level height
    """
    default_level_width: int | None = None
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Default new level width
    """
    export_png: bool | None = None
    """**WARNING**: this deprecated value is no longer exported since version 0.9.3  Replaced
    by: `imageExportMode`
    """
    minify_json: bool | None = None
    """**WARNING**: this deprecated value will be *removed* completely on version 1.7.0+
    Replaced by: `jsonStyle`
    """
    png_file_pattern: str | None = None
    """File naming pattern for exported PNGs"""

    tutorial_desc: str | None = None
    """This optional description is used by LDtk Samples to show up some informations and
    instructions.
    """
    world_grid_height: int | None = None
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Height of the world grid in pixels.
    """
    world_grid_width: int | None = None
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  Width of the world grid in pixels.
    """
    world_layout: WorldLayout | None = None
    """**WARNING**: this field will move to the `worlds` array after the "multi-worlds" update.
    It will then be `null`. You can enable the Multi-worlds advanced project option to enable
    the change immediately.<br/><br/>  An enum that describes how levels are organized in
    this project (ie. linearly or in a 2D space). Possible values: &lt;`null`&gt;, `Free`,
    `GridVania`, `LinearHorizontal`, `LinearVertical`
    """

    @staticmethod
    def from_dict(obj: Any) -> 'LdtkJSON':
        assert isinstance(obj, dict)
        app_build_id = from_float(obj.get("appBuildId"))
        backup_limit = from_int(obj.get("backupLimit"))
        backup_on_save = from_bool(obj.get("backupOnSave"))
        bg_color = from_str(obj.get("bgColor"))
        custom_commands = from_list(LdtkCustomCommand.from_dict, obj.get("customCommands"))
        default_entity_height = from_int(obj.get("defaultEntityHeight"))
        default_entity_width = from_int(obj.get("defaultEntityWidth"))
        default_grid_size = from_int(obj.get("defaultGridSize"))
        default_level_bg_color = from_str(obj.get("defaultLevelBgColor"))
        default_pivot_x = from_float(obj.get("defaultPivotX"))
        default_pivot_y = from_float(obj.get("defaultPivotY"))
        defs = Definitions.from_dict(obj.get("defs"))
        dummy_world_iid = from_str(obj.get("dummyWorldIid"))
        export_level_bg = from_bool(obj.get("exportLevelBg"))
        export_tiled = from_bool(obj.get("exportTiled"))
        external_levels = from_bool(obj.get("externalLevels"))
        flags = from_list(Flag, obj.get("flags"))
        identifier_style = IdentifierStyle(obj.get("identifierStyle"))
        iid = from_str(obj.get("iid"))
        image_export_mode = ImageExportMode(obj.get("imageExportMode"))
        json_style = JSONStyle(obj.get("jsonStyle"))
        json_version = from_str(obj.get("jsonVersion"))
        level_name_pattern = from_str(obj.get("levelNamePattern"))
        levels = from_list(Level.from_dict, obj.get("levels"))
        next_uid = from_int(obj.get("nextUid"))
        simplified_export = from_bool(obj.get("simplifiedExport"))
        toc = from_list(LdtkTableOfContentEntry.from_dict, obj.get("toc"))
        worlds = from_list(World.from_dict, obj.get("worlds"))
        forced_refs = from_union([ForcedRefs.from_dict, from_none], obj.get("__FORCED_REFS"))
        backup_rel_path = from_union([from_none, from_str], obj.get("backupRelPath"))
        default_level_height = from_union([from_none, from_int], obj.get("defaultLevelHeight"))
        default_level_width = from_union([from_none, from_int], obj.get("defaultLevelWidth"))
        export_png = from_union([from_none, from_bool], obj.get("exportPng"))
        minify_json = from_union([from_none, from_bool], obj.get("minifyJson"))
        png_file_pattern = from_union([from_none, from_str], obj.get("pngFilePattern"))
        tutorial_desc = from_union([from_none, from_str], obj.get("tutorialDesc"))
        world_grid_height = from_union([from_none, from_int], obj.get("worldGridHeight"))
        world_grid_width = from_union([from_none, from_int], obj.get("worldGridWidth"))
        world_layout = from_union([from_none, WorldLayout], obj.get("worldLayout"))
        return LdtkJSON(app_build_id, backup_limit, backup_on_save, bg_color, custom_commands, default_entity_height, default_entity_width, default_grid_size, default_level_bg_color, default_pivot_x, default_pivot_y, defs, dummy_world_iid, export_level_bg, export_tiled, external_levels, flags, identifier_style, iid, image_export_mode, json_style, json_version, level_name_pattern, levels, next_uid, simplified_export, toc, worlds, forced_refs, backup_rel_path, default_level_height, default_level_width, export_png, minify_json, png_file_pattern, tutorial_desc, world_grid_height, world_grid_width, world_layout)

    def to_dict(self) -> dict:
        result: dict = {}
        result["appBuildId"] = to_float(self.app_build_id)
        result["backupLimit"] = from_int(self.backup_limit)
        result["backupOnSave"] = from_bool(self.backup_on_save)
        result["bgColor"] = from_str(self.bg_color)
        result["customCommands"] = from_list(lambda x: to_class(LdtkCustomCommand, x), self.custom_commands)
        result["defaultEntityHeight"] = from_int(self.default_entity_height)
        result["defaultEntityWidth"] = from_int(self.default_entity_width)
        result["defaultGridSize"] = from_int(self.default_grid_size)
        result["defaultLevelBgColor"] = from_str(self.default_level_bg_color)
        result["defaultPivotX"] = to_float(self.default_pivot_x)
        result["defaultPivotY"] = to_float(self.default_pivot_y)
        result["defs"] = to_class(Definitions, self.defs)
        result["dummyWorldIid"] = from_str(self.dummy_world_iid)
        result["exportLevelBg"] = from_bool(self.export_level_bg)
        result["exportTiled"] = from_bool(self.export_tiled)
        result["externalLevels"] = from_bool(self.external_levels)
        result["flags"] = from_list(lambda x: to_enum(Flag, x), self.flags)
        result["identifierStyle"] = to_enum(IdentifierStyle, self.identifier_style)
        result["iid"] = from_str(self.iid)
        result["imageExportMode"] = to_enum(ImageExportMode, self.image_export_mode)
        result["jsonStyle"] = to_enum(JSONStyle, self.json_style)
        result["jsonVersion"] = from_str(self.json_version)
        result["levelNamePattern"] = from_str(self.level_name_pattern)
        result["levels"] = from_list(lambda x: to_class(Level, x), self.levels)
        result["nextUid"] = from_int(self.next_uid)
        result["simplifiedExport"] = from_bool(self.simplified_export)
        result["toc"] = from_list(lambda x: to_class(LdtkTableOfContentEntry, x), self.toc)
        result["worlds"] = from_list(lambda x: to_class(World, x), self.worlds)
        if self.forced_refs is not None:
            result["__FORCED_REFS"] = from_union([lambda x: to_class(ForcedRefs, x), from_none], self.forced_refs)
        if self.backup_rel_path is not None:
            result["backupRelPath"] = from_union([from_none, from_str], self.backup_rel_path)
        if self.default_level_height is not None:
            result["defaultLevelHeight"] = from_union([from_none, from_int], self.default_level_height)
        if self.default_level_width is not None:
            result["defaultLevelWidth"] = from_union([from_none, from_int], self.default_level_width)
        if self.export_png is not None:
            result["exportPng"] = from_union([from_none, from_bool], self.export_png)
        if self.minify_json is not None:
            result["minifyJson"] = from_union([from_none, from_bool], self.minify_json)
        if self.png_file_pattern is not None:
            result["pngFilePattern"] = from_union([from_none, from_str], self.png_file_pattern)
        if self.tutorial_desc is not None:
            result["tutorialDesc"] = from_union([from_none, from_str], self.tutorial_desc)
        if self.world_grid_height is not None:
            result["worldGridHeight"] = from_union([from_none, from_int], self.world_grid_height)
        if self.world_grid_width is not None:
            result["worldGridWidth"] = from_union([from_none, from_int], self.world_grid_width)
        if self.world_layout is not None:
            result["worldLayout"] = from_union([from_none, lambda x: to_enum(WorldLayout, x)], self.world_layout)
        return result


def ldtk_json_from_dict(s: Any) -> LdtkJSON:
    return LdtkJSON.from_dict(s)


def ldtk_json_to_dict(x: LdtkJSON) -> Any:
    return to_class(LdtkJSON, x)
