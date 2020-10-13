typedef SessionData = {
	var recentProjects : Array<String>;
}

enum GlobalEvent {
	ViewportChanged;

	ProjectSelected;
	ProjectSettingsChanged;
	BeforeProjectSaving;
	ProjectSaved;

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

	LayerRuleChanged(rule:led.def.AutoLayerRuleDef);
	LayerRuleAdded(rule:led.def.AutoLayerRuleDef);
	LayerRuleRemoved(rule:led.def.AutoLayerRuleDef);
	LayerRuleSeedChanged;
	LayerRuleSorted;

	LayerRuleGroupAdded;
	LayerRuleGroupRemoved(rg:led.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupChanged(rg:led.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupChangedActiveState(rg:led.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupSorted;
	LayerRuleGroupCollapseChanged;

	LayerInstanceSelected;
	LayerInstanceChanged;
	LayerInstanceVisiblityChanged(li:led.inst.LayerInstance);
	LayerInstanceRestoredFromHistory(li:led.inst.LayerInstance);
	LayerInstanceAutoRenderingChanged(li:led.inst.LayerInstance);

	TilesetDefChanged(td:led.def.TilesetDef);
	TilesetDefAdded(td:led.def.TilesetDef);
	TilesetDefRemoved(td:led.def.TilesetDef);
	TilesetSelectionSaved(td:led.def.TilesetDef);

	EntityInstanceAdded(ei:led.inst.EntityInstance);
	EntityInstanceRemoved(ei:led.inst.EntityInstance);
	EntityInstanceChanged(ei:led.inst.EntityInstance);
	EntityInstanceFieldChanged(ei:led.inst.EntityInstance);

	EntityDefAdded;
	EntityDefRemoved;
	EntityDefChanged;
	EntityDefSorted;

	EntityFieldAdded(ed:led.def.EntityDef);
	EntityFieldRemoved(ed:led.def.EntityDef);
	EntityFieldDefChanged(ed:led.def.EntityDef);
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
	Forbidden;
	Pan;
	Move;
	Moving;
	PickNothing;
	Eraser(x:Int,y:Int);
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:led.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(li:led.inst.LayerInstance, def:led.def.EntityDef, ?ei:led.inst.EntityInstance, x:Int, y:Int);
	Tiles(li:led.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int);
	Resize(p:RulerPos);
	Link(fx:Float, fy:Float, tx:Float, ty:Float, color:UInt);
}

enum GenericLevelElement {
	GridCell(li:led.inst.LayerInstance, cx:Int, cy:Int);
	Entity(li:led.inst.LayerInstance, ei:led.inst.EntityInstance);
	PointField(li:led.inst.LayerInstance, ei:led.inst.EntityInstance, fi:led.inst.FieldInstance, arrayIdx:Int);
}

enum ToolEditMode {
	PanView;
	Add;
	Remove;
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
	TrimmedPadding;
	RemapLoss;
	RemapSuccessful;
}

enum TilePickerMode {
	ToolPicker;
	MultiTiles;
	SingleTile;
	ViewOnly;
	RectOnly;
}
