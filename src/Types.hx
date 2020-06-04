enum LayerType {
	IntGrid;
	Entities; // TODO temp
}


typedef IntGridValue = {
	var name : Null<String>;
	var color : UInt;
}

enum GlobalEvent {
	LayerDefChanged;
	LayerDefSorted;
	LayerContentChanged;

	EntityDefChanged;
	EntityDefSorted;
	EntityFieldChanged;
}

enum FieldType {
	F_Int;
	F_Float;
	F_String;
	F_Bool;
}

enum CursorType {
	None;
	GridCell(cx:Int, cy:Int, ?col:UInt);
	GridRect(cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
}