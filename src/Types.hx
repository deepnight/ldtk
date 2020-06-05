enum LayerType {
	IntGrid;
	Entities; // TODO temp
}


typedef IntGridValue = {
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
	GridCell(cx:Int, cy:Int, ?col:UInt);
	GridRect(cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:EntityDef, x:Int, y:Int);
}

enum GenericLevelElement {
	IntGrid(lc:LayerContent, cx:Int, cy:Int);
	Entity(instance:EntityInstance);
}