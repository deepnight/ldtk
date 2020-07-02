package led;

class ApiTypes {
	public static var DEFAULT_LEVEL_WIDTH = 128; // px
	public static var DEFAULT_LEVEL_HEIGHT = 128; // px
	public static var DEFAULT_GRID_SIZE = 16; // px

	public static var DATA_VERSION = 1;
	/**
		VERSION CHANGELOG
		1. initial release
	**/
}


enum LayerType {
	IntGrid;
	Entities;
	Tiles;
	// WARNING: field is serialized (do not remove values, add new ones at the end!)
}


typedef IntGridValueDef = {
	var name : Null<String>;
	var color : UInt;
}

enum FieldType {
	F_Int;
	F_Float;
	F_String;
	F_Bool;
	F_Color;
}

enum ValueWrapper {
	V_Int(v:Int);
	V_Float(v:Float);
	V_Bool(v:Bool);
	V_String(v:String);
}

enum FieldDisplayMode {
	Hidden;
	ValueOnly;
	NameAndValue;
}

enum FieldDisplayPosition {
	Above;
	Beneath;
}

typedef TilesetSelection = {
	var ids : Array<Int>;
	var mode : TileEditMode;
}

enum TileEditMode {
	Stamp;
	Random;
}