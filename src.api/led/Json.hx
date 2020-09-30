package led;

@display("Json root")
typedef ProjectJson = {
	/** File format version **/
	var jsonVersion: String;

	/** Default X pivot (0 to 1) for new entities **/
	var defaultPivotX: Float;

	/** Default Y pivot (0 to 1) for new entities **/
	var defaultPivotY: Float;

	/** Default grid size for new layers **/
	var defaultGridSize: Int;

	/** Project background color **/
	@color
	var bgColor: String;

	@hide
	var nextUid: Int;

	/** If TRUE, the Json is partially minified (no indentation, nor line breaks) **/
	var minifyJson: Bool;

	/** A structure containing all the definitions of this project **/
	var defs: DefinitionsJson;

	var levels: Array<LevelJson>;
}


@section("1")
@display("Level")
typedef LevelJson = {

	/** Unique Int identifier **/
	var uid: Int;

	/** Unique String identifier **/
	var identifier: String;

	/** Width of the level in pixels **/
	var pxWid: Int;

	/** Height of the level in pixels **/
	var pxHei: Int;

	var layerInstances: Array<LayerInstanceJson>;
}


@section("1.1")
@display("Layer instance")
typedef LayerInstanceJson = {
	/** Unique String identifier **/
	var __identifier: String;

	/** Layer type (possible values: IntGrid, Entities, Tiles or AutoLayer) **/
	var __type: String;

	/** Grid-based width **/
	var __cWid: Int;

	/** Grid-based height **/
	var __cHei: Int;

	/** Grid size **/
	var __gridSize: Int;

	/** Reference to the UID of the level containing this layer instance **/
	var levelId: Int;

	/** Reference the Layer definition UID **/
	var layerDefUid: Int;

	/** Horizontal offset in pixels to render this layer, usually 0 **/
	var pxOffsetX: Int;

	/** Vertical offset in pixels to render this layer, usually 0 **/
	var pxOffsetY: Int;

	/** Random seed used for Auto-Layers rendering **/
	@only("Auto-layers (pure or IntGrid based)")
	var seed: Int;

	@only("IntGrid layers")
	var intGrid: Array<{ coordId:Int, v:Int }>;

	var autoTiles: Dynamic;
	var gridTiles: Dynamic;
	var entityInstances: Dynamic;

}


@section("2")
@display("Definitions")
typedef DefinitionsJson = {
	var layers : Array<LayerDefJson>;
	var entities : Array<EntityDefJson>;
	var tilesets : Array<TilesetDefJson>;
	var enums : Array<EnumDefJson>;

	/**
		Note: external enums are exactly the same as `enums`, except they
		have a `relPath` to point to an external source file.
	**/
	var externalEnums : Array<EnumDefJson>;
}


@section("2.1")
@display("Layer definition")
typedef LayerDefJson = Dynamic;

@section("2.2")
@display("Entity definition")
typedef EntityDefJson = Dynamic;

@section("2.3")
@display("Tileset definition")
typedef TilesetDefJson = Dynamic;

@section("2.4")
@display("Enum definition")
typedef EnumDefJson = Dynamic;
