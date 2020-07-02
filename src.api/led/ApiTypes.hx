package led;

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