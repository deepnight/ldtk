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

	var levels: Array<Dynamic>; // TODO
}

@display("Definitions")
typedef DefinitionsJson = {
	var layers : Array<LayerDefJson>;
	var entities : Array<EntityDefJson>;
	var tilesets : Array<TilesetDefJson>;
	var enums : Array<EnumDefJson>;
	/** Note: external enums are exactly the same as `enums`, except they have a `relPath` to point to an external source file. **/
	var externalEnums : Array<EnumDefJson>;
}

@display("Layer definition")
typedef LayerDefJson = Dynamic;

@display("Entity definition")
typedef EntityDefJson = Dynamic;

@display("Tileset definition")
typedef TilesetDefJson = Dynamic;

@display("Enum definition")
typedef EnumDefJson = Dynamic;
