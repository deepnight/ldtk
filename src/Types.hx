enum LayerType {
	IntGrid;
	Entities; // TODO temp
}


typedef IntGridValueDef = {
	var name : Null<String>;
	var color : UInt;
}

enum GlobalEvent {
	ProjectChanged;

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
	Eraser(x:Int,y:Int);
	GridCell(lc:LayerContent, cx:Int, cy:Int);
	GridRect(lc:LayerContent, cx:Int, cy:Int, wid:Int, hei:Int);
	Entity(def:EntityDef, x:Int, y:Int);
}

enum GenericLevelElement {
	IntGrid(lc:LayerContent, cx:Int, cy:Int);
	Entity(instance:EntityInstance);
}

enum ToolEditMode {
	Add;
	Remove;
	Move;
}