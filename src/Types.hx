enum LayerType {
	IntGrid;
	Entities; // TODO temp
}


typedef IntGridValue = {
	var name : String;
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
	F_String;
}