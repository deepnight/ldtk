typedef SessionData = {
	var projectPath: String;
}

enum GlobalEvent {
	ViewportChanged;

	ProjectSelected;
	ProjectSettingsChanged;

	LevelSelected;
	LevelSettingsChanged;
	LevelAdded;
	LevelResized;
	LevelRestoredFromHistory;
	LevelSorted;

	LayerDefAdded;
	LayerDefRemoved;
	LayerDefChanged;
	LayerDefSorted;

	LayerInstanceSelected;
	LayerInstanceChanged;
	LayerInstanceVisiblityChanged;
	LayerInstanceRestoredFromHistory;

	TilesetDefChanged;

	EntityDefAdded;
	EntityDefRemoved;
	EntityDefChanged;
	EntityDefSorted;

	EntityFieldAdded;
	EntityFieldRemoved;
	EntityFieldDefChanged;
	EntityFieldInstanceChanged;
	EntityFieldSorted;

	EnumDefAdded;
	EnumDefRemoved;
	EnumDefChanged;
	EnumDefSorted;

	ToolOptionChanged;
}

enum CursorType {
	None;
	Move;
	Eraser(x:Int,y:Int);
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(def:led.def.EntityDef, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
	Resize(p:RulerPos);
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

enum HistoryState {
	ResizedLevel(beforeJson:Dynamic, afterJson:Dynamic);
	// FullLevel(json:Dynamic);
	Layer(layerId:Int, bounds:Null<HistoryStateBounds>, json:Dynamic);
}

typedef HistoryStateBounds = {
	var x : Int;
	var y : Int;
	var wid : Int;
	var hei : Int;
}

enum RulerPos {
	Top;
	Bottom;
	Left;
	Right;

	TopLeft;
	TopRight;
	BottomLeft;
	BottomRight;
}