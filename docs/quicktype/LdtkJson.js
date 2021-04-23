// To parse this data:
//
//   const Convert = require("./file");
//
//   const ldtkJSON = Convert.toLdtkJSON(json);
//
// These functions will throw an error if the JSON doesn't
// match the expected interface, even if the JSON is valid.

// Converts JSON strings to/from your types
// and asserts the results of JSON.parse at runtime
function toLdtkJSON(json) {
    return cast(JSON.parse(json), r("LdtkJSON"));
}

function ldtkJSONToJson(value) {
    return JSON.stringify(uncast(value, r("LdtkJSON")), null, 2);
}

function invalidValue(typ, val, key = '') {
    if (key) {
        throw Error(`Invalid value for key "${key}". Expected type ${JSON.stringify(typ)} but got ${JSON.stringify(val)}`);
    }
    throw Error(`Invalid value ${JSON.stringify(val)} for type ${JSON.stringify(typ)}`, );
}

function jsonToJSProps(typ) {
    if (typ.jsonToJS === undefined) {
        const map = {};
        typ.props.forEach((p) => map[p.json] = { key: p.js, typ: p.typ });
        typ.jsonToJS = map;
    }
    return typ.jsonToJS;
}

function jsToJSONProps(typ) {
    if (typ.jsToJSON === undefined) {
        const map = {};
        typ.props.forEach((p) => map[p.js] = { key: p.json, typ: p.typ });
        typ.jsToJSON = map;
    }
    return typ.jsToJSON;
}

function transform(val, typ, getProps, key = '') {
    function transformPrimitive(typ, val) {
        if (typeof typ === typeof val) return val;
        return invalidValue(typ, val, key);
    }

    function transformUnion(typs, val) {
        // val must validate against one typ in typs
        const l = typs.length;
        for (let i = 0; i < l; i++) {
            const typ = typs[i];
            try {
                return transform(val, typ, getProps);
            } catch (_) {}
        }
        return invalidValue(typs, val);
    }

    function transformEnum(cases, val) {
        if (cases.indexOf(val) !== -1) return val;
        return invalidValue(cases, val);
    }

    function transformArray(typ, val) {
        // val must be an array with no invalid elements
        if (!Array.isArray(val)) return invalidValue("array", val);
        return val.map(el => transform(el, typ, getProps));
    }

    function transformDate(val) {
        if (val === null) {
            return null;
        }
        const d = new Date(val);
        if (isNaN(d.valueOf())) {
            return invalidValue("Date", val);
        }
        return d;
    }

    function transformObject(props, additional, val) {
        if (val === null || typeof val !== "object" || Array.isArray(val)) {
            return invalidValue("object", val);
        }
        const result = {};
        Object.getOwnPropertyNames(props).forEach(key => {
            const prop = props[key];
            const v = Object.prototype.hasOwnProperty.call(val, key) ? val[key] : undefined;
            result[prop.key] = transform(v, prop.typ, getProps, prop.key);
        });
        Object.getOwnPropertyNames(val).forEach(key => {
            if (!Object.prototype.hasOwnProperty.call(props, key)) {
                result[key] = transform(val[key], additional, getProps, key);
            }
        });
        return result;
    }

    if (typ === "any") return val;
    if (typ === null) {
        if (val === null) return val;
        return invalidValue(typ, val);
    }
    if (typ === false) return invalidValue(typ, val);
    while (typeof typ === "object" && typ.ref !== undefined) {
        typ = typeMap[typ.ref];
    }
    if (Array.isArray(typ)) return transformEnum(typ, val);
    if (typeof typ === "object") {
        return typ.hasOwnProperty("unionMembers") ? transformUnion(typ.unionMembers, val)
            : typ.hasOwnProperty("arrayItems")    ? transformArray(typ.arrayItems, val)
            : typ.hasOwnProperty("props")         ? transformObject(getProps(typ), typ.additional, val)
            : invalidValue(typ, val);
    }
    // Numbers can be parsed by Date but shouldn't be.
    if (typ === Date && typeof val !== "number") return transformDate(val);
    return transformPrimitive(typ, val);
}

function cast(val, typ) {
    return transform(val, typ, jsonToJSProps);
}

function uncast(val, typ) {
    return transform(val, typ, jsToJSONProps);
}

function a(typ) {
    return { arrayItems: typ };
}

function u(...typs) {
    return { unionMembers: typs };
}

function o(props, additional) {
    return { props, additional };
}

function m(additional) {
    return { props: [], additional };
}

function r(name) {
    return { ref: name };
}

const typeMap = {
    "LdtkJSON": o([
        { json: "backupLimit", js: "backupLimit", typ: 0 },
        { json: "backupOnSave", js: "backupOnSave", typ: true },
        { json: "bgColor", js: "bgColor", typ: "" },
        { json: "defaultGridSize", js: "defaultGridSize", typ: 0 },
        { json: "defaultLevelBgColor", js: "defaultLevelBgColor", typ: "" },
        { json: "defaultLevelHeight", js: "defaultLevelHeight", typ: 0 },
        { json: "defaultLevelWidth", js: "defaultLevelWidth", typ: 0 },
        { json: "defaultPivotX", js: "defaultPivotX", typ: 3.14 },
        { json: "defaultPivotY", js: "defaultPivotY", typ: 3.14 },
        { json: "defs", js: "defs", typ: r("Definitions") },
        { json: "exportPng", js: "exportPng", typ: u(undefined, u(true, null)) },
        { json: "exportTiled", js: "exportTiled", typ: true },
        { json: "externalLevels", js: "externalLevels", typ: true },
        { json: "flags", js: "flags", typ: a(r("Flag")) },
        { json: "imageExportMode", js: "imageExportMode", typ: r("ImageExportMode") },
        { json: "jsonVersion", js: "jsonVersion", typ: "" },
        { json: "levelNamePattern", js: "levelNamePattern", typ: "" },
        { json: "levels", js: "levels", typ: a(r("Level")) },
        { json: "minifyJson", js: "minifyJson", typ: true },
        { json: "nextUid", js: "nextUid", typ: 0 },
        { json: "pngFilePattern", js: "pngFilePattern", typ: u(undefined, u(null, "")) },
        { json: "worldGridHeight", js: "worldGridHeight", typ: 0 },
        { json: "worldGridWidth", js: "worldGridWidth", typ: 0 },
        { json: "worldLayout", js: "worldLayout", typ: r("WorldLayout") },
    ], "any"),
    "Definitions": o([
        { json: "entities", js: "entities", typ: a(r("EntityDefinition")) },
        { json: "enums", js: "enums", typ: a(r("EnumDefinition")) },
        { json: "externalEnums", js: "externalEnums", typ: a(r("EnumDefinition")) },
        { json: "layers", js: "layers", typ: a(r("LayerDefinition")) },
        { json: "levelFields", js: "levelFields", typ: a(r("FieldDefinition")) },
        { json: "tilesets", js: "tilesets", typ: a(r("TilesetDefinition")) },
    ], false),
    "EntityDefinition": o([
        { json: "color", js: "color", typ: "" },
        { json: "fieldDefs", js: "fieldDefs", typ: a(r("FieldDefinition")) },
        { json: "fillOpacity", js: "fillOpacity", typ: 3.14 },
        { json: "height", js: "height", typ: 0 },
        { json: "hollow", js: "hollow", typ: true },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "keepAspectRatio", js: "keepAspectRatio", typ: true },
        { json: "limitBehavior", js: "limitBehavior", typ: r("LimitBehavior") },
        { json: "limitScope", js: "limitScope", typ: r("LimitScope") },
        { json: "lineOpacity", js: "lineOpacity", typ: 3.14 },
        { json: "maxCount", js: "maxCount", typ: 0 },
        { json: "pivotX", js: "pivotX", typ: 3.14 },
        { json: "pivotY", js: "pivotY", typ: 3.14 },
        { json: "renderMode", js: "renderMode", typ: r("RenderMode") },
        { json: "resizableX", js: "resizableX", typ: true },
        { json: "resizableY", js: "resizableY", typ: true },
        { json: "showName", js: "showName", typ: true },
        { json: "tags", js: "tags", typ: a("") },
        { json: "tileId", js: "tileId", typ: u(undefined, u(0, null)) },
        { json: "tileRenderMode", js: "tileRenderMode", typ: r("TileRenderMode") },
        { json: "tilesetId", js: "tilesetId", typ: u(undefined, u(0, null)) },
        { json: "uid", js: "uid", typ: 0 },
        { json: "width", js: "width", typ: 0 },
    ], false),
    "FieldDefinition": o([
        { json: "__type", js: "__type", typ: "" },
        { json: "acceptFileTypes", js: "acceptFileTypes", typ: u(undefined, u(a(""), null)) },
        { json: "arrayMaxLength", js: "arrayMaxLength", typ: u(undefined, u(0, null)) },
        { json: "arrayMinLength", js: "arrayMinLength", typ: u(undefined, u(0, null)) },
        { json: "canBeNull", js: "canBeNull", typ: true },
        { json: "defaultOverride", js: "defaultOverride", typ: u(undefined, "any") },
        { json: "editorAlwaysShow", js: "editorAlwaysShow", typ: true },
        { json: "editorCutLongValues", js: "editorCutLongValues", typ: true },
        { json: "editorDisplayMode", js: "editorDisplayMode", typ: r("EditorDisplayMode") },
        { json: "editorDisplayPos", js: "editorDisplayPos", typ: r("EditorDisplayPos") },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "isArray", js: "isArray", typ: true },
        { json: "max", js: "max", typ: u(undefined, u(3.14, null)) },
        { json: "min", js: "min", typ: u(undefined, u(3.14, null)) },
        { json: "regex", js: "regex", typ: u(undefined, u(null, "")) },
        { json: "textLanguageMode", js: "textLanguageMode", typ: u(undefined, u(r("TextLanguageMode"), null)) },
        { json: "type", js: "type", typ: "any" },
        { json: "uid", js: "uid", typ: 0 },
    ], false),
    "EnumDefinition": o([
        { json: "externalFileChecksum", js: "externalFileChecksum", typ: u(undefined, u(null, "")) },
        { json: "externalRelPath", js: "externalRelPath", typ: u(undefined, u(null, "")) },
        { json: "iconTilesetUid", js: "iconTilesetUid", typ: u(undefined, u(0, null)) },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "uid", js: "uid", typ: 0 },
        { json: "values", js: "values", typ: a(r("EnumValueDefinition")) },
    ], false),
    "EnumValueDefinition": o([
        { json: "__tileSrcRect", js: "__tileSrcRect", typ: u(undefined, u(a(0), null)) },
        { json: "color", js: "color", typ: 0 },
        { json: "id", js: "id", typ: "" },
        { json: "tileId", js: "tileId", typ: u(undefined, u(0, null)) },
    ], false),
    "LayerDefinition": o([
        { json: "__type", js: "__type", typ: "" },
        { json: "autoRuleGroups", js: "autoRuleGroups", typ: a(r("AutoLayerRuleGroup")) },
        { json: "autoSourceLayerDefUid", js: "autoSourceLayerDefUid", typ: u(undefined, u(0, null)) },
        { json: "autoTilesetDefUid", js: "autoTilesetDefUid", typ: u(undefined, u(0, null)) },
        { json: "displayOpacity", js: "displayOpacity", typ: 3.14 },
        { json: "excludedTags", js: "excludedTags", typ: a("") },
        { json: "gridSize", js: "gridSize", typ: 0 },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "intGridValues", js: "intGridValues", typ: a(r("IntGridValueDefinition")) },
        { json: "pxOffsetX", js: "pxOffsetX", typ: 0 },
        { json: "pxOffsetY", js: "pxOffsetY", typ: 0 },
        { json: "requiredTags", js: "requiredTags", typ: a("") },
        { json: "tilePivotX", js: "tilePivotX", typ: 3.14 },
        { json: "tilePivotY", js: "tilePivotY", typ: 3.14 },
        { json: "tilesetDefUid", js: "tilesetDefUid", typ: u(undefined, u(0, null)) },
        { json: "type", js: "type", typ: r("Type") },
        { json: "uid", js: "uid", typ: 0 },
    ], false),
    "AutoLayerRuleGroup": o([
        { json: "active", js: "active", typ: true },
        { json: "collapsed", js: "collapsed", typ: true },
        { json: "isOptional", js: "isOptional", typ: true },
        { json: "name", js: "name", typ: "" },
        { json: "rules", js: "rules", typ: a(r("AutoLayerRuleDefinition")) },
        { json: "uid", js: "uid", typ: 0 },
    ], false),
    "AutoLayerRuleDefinition": o([
        { json: "active", js: "active", typ: true },
        { json: "breakOnMatch", js: "breakOnMatch", typ: true },
        { json: "chance", js: "chance", typ: 3.14 },
        { json: "checker", js: "checker", typ: r("Checker") },
        { json: "flipX", js: "flipX", typ: true },
        { json: "flipY", js: "flipY", typ: true },
        { json: "outOfBoundsValue", js: "outOfBoundsValue", typ: u(undefined, u(0, null)) },
        { json: "pattern", js: "pattern", typ: a(0) },
        { json: "perlinActive", js: "perlinActive", typ: true },
        { json: "perlinOctaves", js: "perlinOctaves", typ: 3.14 },
        { json: "perlinScale", js: "perlinScale", typ: 3.14 },
        { json: "perlinSeed", js: "perlinSeed", typ: 3.14 },
        { json: "pivotX", js: "pivotX", typ: 3.14 },
        { json: "pivotY", js: "pivotY", typ: 3.14 },
        { json: "size", js: "size", typ: 0 },
        { json: "tileIds", js: "tileIds", typ: a(0) },
        { json: "tileMode", js: "tileMode", typ: r("TileMode") },
        { json: "uid", js: "uid", typ: 0 },
        { json: "xModulo", js: "xModulo", typ: 0 },
        { json: "yModulo", js: "yModulo", typ: 0 },
    ], false),
    "IntGridValueDefinition": o([
        { json: "color", js: "color", typ: "" },
        { json: "identifier", js: "identifier", typ: u(undefined, u(null, "")) },
        { json: "value", js: "value", typ: 0 },
    ], false),
    "TilesetDefinition": o([
        { json: "__cHei", js: "__cHei", typ: 0 },
        { json: "__cWid", js: "__cWid", typ: 0 },
        { json: "cachedPixelData", js: "cachedPixelData", typ: u(undefined, u(m("any"), null)) },
        { json: "customData", js: "customData", typ: a(m("any")) },
        { json: "enumTags", js: "enumTags", typ: a(m("any")) },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "padding", js: "padding", typ: 0 },
        { json: "pxHei", js: "pxHei", typ: 0 },
        { json: "pxWid", js: "pxWid", typ: 0 },
        { json: "relPath", js: "relPath", typ: "" },
        { json: "savedSelections", js: "savedSelections", typ: a(m("any")) },
        { json: "spacing", js: "spacing", typ: 0 },
        { json: "tagsSourceEnumUid", js: "tagsSourceEnumUid", typ: u(undefined, u(0, null)) },
        { json: "tileGridSize", js: "tileGridSize", typ: 0 },
        { json: "uid", js: "uid", typ: 0 },
    ], false),
    "Level": o([
        { json: "__bgColor", js: "__bgColor", typ: "" },
        { json: "__bgPos", js: "__bgPos", typ: u(undefined, u(r("LevelBackgroundPosition"), null)) },
        { json: "__neighbours", js: "__neighbours", typ: a(r("NeighbourLevel")) },
        { json: "bgColor", js: "bgColor", typ: u(undefined, u(null, "")) },
        { json: "bgPivotX", js: "bgPivotX", typ: 3.14 },
        { json: "bgPivotY", js: "bgPivotY", typ: 3.14 },
        { json: "bgPos", js: "bgPos", typ: u(undefined, u(r("BgPos"), null)) },
        { json: "bgRelPath", js: "bgRelPath", typ: u(undefined, u(null, "")) },
        { json: "externalRelPath", js: "externalRelPath", typ: u(undefined, u(null, "")) },
        { json: "fieldInstances", js: "fieldInstances", typ: a(r("FieldInstance")) },
        { json: "identifier", js: "identifier", typ: "" },
        { json: "layerInstances", js: "layerInstances", typ: u(undefined, u(a(r("LayerInstance")), null)) },
        { json: "pxHei", js: "pxHei", typ: 0 },
        { json: "pxWid", js: "pxWid", typ: 0 },
        { json: "uid", js: "uid", typ: 0 },
        { json: "useAutoIdentifier", js: "useAutoIdentifier", typ: true },
        { json: "worldX", js: "worldX", typ: 0 },
        { json: "worldY", js: "worldY", typ: 0 },
    ], false),
    "LevelBackgroundPosition": o([
        { json: "cropRect", js: "cropRect", typ: a(3.14) },
        { json: "scale", js: "scale", typ: a(3.14) },
        { json: "topLeftPx", js: "topLeftPx", typ: a(0) },
    ], false),
    "NeighbourLevel": o([
        { json: "dir", js: "dir", typ: "" },
        { json: "levelUid", js: "levelUid", typ: 0 },
    ], false),
    "FieldInstance": o([
        { json: "__identifier", js: "__identifier", typ: "" },
        { json: "__type", js: "__type", typ: "" },
        { json: "__value", js: "__value", typ: "any" },
        { json: "defUid", js: "defUid", typ: 0 },
        { json: "realEditorValues", js: "realEditorValues", typ: a("any") },
    ], false),
    "LayerInstance": o([
        { json: "__cHei", js: "__cHei", typ: 0 },
        { json: "__cWid", js: "__cWid", typ: 0 },
        { json: "__gridSize", js: "__gridSize", typ: 0 },
        { json: "__identifier", js: "__identifier", typ: "" },
        { json: "__opacity", js: "__opacity", typ: 3.14 },
        { json: "__pxTotalOffsetX", js: "__pxTotalOffsetX", typ: 0 },
        { json: "__pxTotalOffsetY", js: "__pxTotalOffsetY", typ: 0 },
        { json: "__tilesetDefUid", js: "__tilesetDefUid", typ: u(undefined, u(0, null)) },
        { json: "__tilesetRelPath", js: "__tilesetRelPath", typ: u(undefined, u(null, "")) },
        { json: "__type", js: "__type", typ: "" },
        { json: "autoLayerTiles", js: "autoLayerTiles", typ: a(r("TileInstance")) },
        { json: "entityInstances", js: "entityInstances", typ: a(r("EntityInstance")) },
        { json: "gridTiles", js: "gridTiles", typ: a(r("TileInstance")) },
        { json: "intGrid", js: "intGrid", typ: u(undefined, a(r("IntGridValueInstance"))) },
        { json: "intGridCsv", js: "intGridCsv", typ: a(0) },
        { json: "layerDefUid", js: "layerDefUid", typ: 0 },
        { json: "levelId", js: "levelId", typ: 0 },
        { json: "optionalRules", js: "optionalRules", typ: a(0) },
        { json: "overrideTilesetUid", js: "overrideTilesetUid", typ: u(undefined, u(0, null)) },
        { json: "pxOffsetX", js: "pxOffsetX", typ: 0 },
        { json: "pxOffsetY", js: "pxOffsetY", typ: 0 },
        { json: "seed", js: "seed", typ: 0 },
        { json: "visible", js: "visible", typ: true },
    ], false),
    "TileInstance": o([
        { json: "d", js: "d", typ: a(0) },
        { json: "f", js: "f", typ: 0 },
        { json: "px", js: "px", typ: a(0) },
        { json: "src", js: "src", typ: a(0) },
        { json: "t", js: "t", typ: 0 },
    ], false),
    "EntityInstance": o([
        { json: "__grid", js: "__grid", typ: a(0) },
        { json: "__identifier", js: "__identifier", typ: "" },
        { json: "__pivot", js: "__pivot", typ: a(3.14) },
        { json: "__tile", js: "__tile", typ: u(undefined, u(r("EntityInstanceTile"), null)) },
        { json: "defUid", js: "defUid", typ: 0 },
        { json: "fieldInstances", js: "fieldInstances", typ: a(r("FieldInstance")) },
        { json: "height", js: "height", typ: 0 },
        { json: "px", js: "px", typ: a(0) },
        { json: "width", js: "width", typ: 0 },
    ], false),
    "EntityInstanceTile": o([
        { json: "srcRect", js: "srcRect", typ: a(0) },
        { json: "tilesetUid", js: "tilesetUid", typ: 0 },
    ], false),
    "IntGridValueInstance": o([
        { json: "coordId", js: "coordId", typ: 0 },
        { json: "v", js: "v", typ: 0 },
    ], false),
    "EditorDisplayMode": [
        "EntityTile",
        "Hidden",
        "NameAndValue",
        "PointPath",
        "PointPathLoop",
        "PointStar",
        "Points",
        "RadiusGrid",
        "RadiusPx",
        "ValueOnly",
    ],
    "EditorDisplayPos": [
        "Above",
        "Beneath",
        "Center",
    ],
    "TextLanguageMode": [
        "LangC",
        "LangHaxe",
        "LangJS",
        "LangJson",
        "LangLua",
        "LangMarkdown",
        "LangPython",
        "LangRuby",
        "LangXml",
    ],
    "LimitBehavior": [
        "DiscardOldOnes",
        "MoveLastOne",
        "PreventAdding",
    ],
    "LimitScope": [
        "PerLayer",
        "PerLevel",
        "PerWorld",
    ],
    "RenderMode": [
        "Cross",
        "Ellipse",
        "Rectangle",
        "Tile",
    ],
    "TileRenderMode": [
        "Cover",
        "FitInside",
        "Repeat",
        "Stretch",
    ],
    "Checker": [
        "Horizontal",
        "None",
        "Vertical",
    ],
    "TileMode": [
        "Single",
        "Stamp",
    ],
    "Type": [
        "AutoLayer",
        "Entities",
        "IntGrid",
        "Tiles",
    ],
    "Flag": [
        "DiscardPreCsvIntGrid",
        "IgnoreBackupSuggest",
    ],
    "ImageExportMode": [
        "None",
        "OneImagePerLayer",
        "OneImagePerLevel",
    ],
    "BgPos": [
        "Contain",
        "Cover",
        "CoverDirty",
        "Unscaled",
    ],
    "WorldLayout": [
        "Free",
        "GridVania",
        "LinearHorizontal",
        "LinearVertical",
    ],
};

module.exports = {
    "ldtkJSONToJson": ldtkJSONToJson,
    "toLdtkJSON": toLdtkJSON,
};
