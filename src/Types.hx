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
	LayerInstanceChanged;

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
}

enum GenericLevelElement {
	IntGrid(li:LayerInstance, cx:Int, cy:Int);
	Entity(instance:EntityInstance);
}

enum ToolEditMode {
	PanView;
	Add;
	Remove;
	Move;
}