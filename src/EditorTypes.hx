enum GlobalEvent {
	ProjectSettingsChanged;

	LayerDefChanged;
	LayerDefSorted;
	LayerInstanceChanged;

	TilesetDefChanged;

	EntityDefChanged;
	EntityDefSorted;

	EntityFieldChanged;
	EntityFieldSorted;

	ToolOptionChanged;
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
