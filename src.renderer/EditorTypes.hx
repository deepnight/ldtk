typedef SessionData = {
	var recentProjects : Array<String>;
}

enum GlobalEvent {
	ViewportChanged;

	ProjectSelected;
	ProjectSettingsChanged;

	LevelSelected;
	LevelSettingsChanged;
	LevelAdded;
	LevelRemoved;
	LevelResized;
	LevelRestoredFromHistory;
	LevelSorted;

	LayerDefAdded;
	LayerDefRemoved(defUid:Int);
	LayerDefChanged;
	LayerDefSorted;

	LayerRuleChanged(rule:led.def.AutoLayerRule);
	// LayerRuleAdded(ruleUid:Int);
	LayerRuleRemoved(rule:led.def.AutoLayerRule);
	LayerRuleSorted;

	LayerInstanceSelected;
	LayerInstanceChanged;
	LayerInstanceVisiblityChanged;
	LayerInstanceRestoredFromHistory;

	TilesetDefChanged;
	TilesetDefAdded;
	TilesetDefRemoved;
	TilesetSelectionSaved;

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
	EnumDefValueRemoved;

	ToolOptionChanged;
}

enum CursorType {
	None;
	Move;
	PickNothing;
	Eraser(x:Int,y:Int);
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(li:led.inst.LayerInstance, def:led.def.EntityDef, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
	Resize(p:RulerPos);
}

enum GenericLevelElement {
	IntGrid(li:led.inst.LayerInstance, cx:Int, cy:Int);
	Entity(li:led.inst.LayerInstance, instance:led.inst.EntityInstance);
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

typedef ParsedExternalEnum = {
	var enumId : String;
	var values : Array<String>;
}

typedef SyncLog = Array<{
	var op : SyncOp;
	var str : String;
}>;

enum SyncOp {
	Add;
	Remove(used:Bool);
	ChecksumUpdated;
	DateUpdated;
}

enum ImageSyncResult {
	Ok;
	FileNotFound;
	RemapLoss;
	RemapSuccessful;
}