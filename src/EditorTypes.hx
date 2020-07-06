enum GlobalEvent {
	ProjectSettingsChanged;
	ProjectReplaced;

	LayerDefAdded;
	LayerDefRemoved;
	LayerDefChanged;
	LayerDefSorted;
	LayerInstanceChanged;

	TilesetDefChanged;

	EntityDefAdded;
	EntityDefRemoved;
	EntityDefChanged;
	EntityDefSorted;

	EntityFieldChanged;
	EntityFieldSorted;

	ToolOptionChanged;

	RestoredFromHistory;
}

enum CursorType {
	None;
	Move;
	Eraser(x:Int,y:Int);
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:led.def.EntityDef, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
}

enum GenericLevelElement {
	IntGrid(li:led.inst.LayerInstance, cx:Int, cy:Int);
	Entity(instance:led.inst.EntityInstance);
	Tile(li:led.inst.LayerInstance, cx:Int, cy:Int);
}

enum ToolEditMode {
	PanView;
	Add;
	Remove;
	Move;
}

typedef LayerState = {
	var layerId : Int;
	var json : Dynamic;
}