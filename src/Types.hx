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

enum ValueWrapper {
	V_Int(v:Null<Int>);
}

enum CursorType {
	None;
	Move;
	Eraser(x:Int,y:Int);
	GridCell(lc:LayerContent, cx:Int, cy:Int, ?col:UInt);
	GridRect(lc:LayerContent, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:EntityDef, x:Int, y:Int);
}

enum GenericLevelElement {
	IntGrid(lc:LayerContent, cx:Int, cy:Int);
	Entity(instance:EntityInstance);
}

enum ToolEditMode {
	PanView;
	Add;
	Remove;
	Move;
}