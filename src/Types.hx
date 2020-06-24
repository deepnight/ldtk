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

enum GlobalEvent {
	ProjectChanged;

	LayerDefChanged;
	LayerDefSorted;
	LayerInstanceChanged;

	TilesetDefChanged;

	EntityDefChanged;
	EntityDefSorted;

	EntityFieldChanged;
	EntityFieldSorted;
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

enum CursorType {
	None;
	Move;
	Eraser(x:Int,y:Int);
	GridCell(li:LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:EntityDef, x:Int, y:Int);
	Tiles(li:LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
}

enum GenericLevelElement {
	IntGrid(li:LayerInstance, cx:Int, cy:Int);
	Entity(instance:EntityInstance);
	Tile(li:LayerInstance, cx:Int, cy:Int);
}

enum ToolEditMode {
	PanView;
	Add;
	Remove;
	Move;
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
