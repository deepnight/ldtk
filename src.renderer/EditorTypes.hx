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

	LayerRuleChanged(rule:data.def.AutoLayerRuleDef);
	LayerRuleAdded(rule:data.def.AutoLayerRuleDef);
	LayerRuleRemoved(rule:data.def.AutoLayerRuleDef);
	LayerRuleSeedChanged;
	LayerRuleSorted;

	LayerRuleGroupAdded;
	LayerRuleGroupRemoved(rg:data.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupChanged(rg:data.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupChangedActiveState(rg:data.LedTypes.AutoLayerRuleGroup);
	LayerRuleGroupSorted;
	LayerRuleGroupCollapseChanged;

	LayerInstanceSelected;
	LayerInstanceChanged;
	LayerInstanceVisiblityChanged(li:data.inst.LayerInstance);
	LayerInstanceRestoredFromHistory(li:data.inst.LayerInstance);
	LayerInstanceAutoRenderingChanged(li:data.inst.LayerInstance);

	TilesetDefChanged(td:data.def.TilesetDef);
	TilesetDefAdded(td:data.def.TilesetDef);
	TilesetDefRemoved(td:data.def.TilesetDef);
	TilesetSelectionSaved(td:data.def.TilesetDef);

	EntityInstanceAdded(ei:data.inst.EntityInstance);
	EntityInstanceRemoved(ei:data.inst.EntityInstance);
	EntityInstanceChanged(ei:data.inst.EntityInstance);
	EntityInstanceFieldChanged(ei:data.inst.EntityInstance);

	EntityDefAdded;
	EntityDefRemoved;
	EntityDefChanged;
	EntityDefSorted;

	EntityFieldAdded(ed:data.def.EntityDef);
	EntityFieldRemoved(ed:data.def.EntityDef);
	EntityFieldDefChanged(ed:data.def.EntityDef);
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
	GridCell(li:data.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:data.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(li:data.inst.LayerInstance, def:data.def.EntityDef, ?ei:data.inst.EntityInstance, x:Int, y:Int);
	Tiles(li:data.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int, flips:Int);
	Resize(p:RulerPos);
	Link(fx:Float, fy:Float, tx:Float, ty:Float, color:UInt);
}

enum GenericLevelElement {
	GridCell(li:data.inst.LayerInstance, cx:Int, cy:Int);
	Entity(li:data.inst.LayerInstance, ei:data.inst.EntityInstance);
	PointField(li:data.inst.LayerInstance, ei:data.inst.EntityInstance, fi:data.inst.FieldInstance, arrayIdx:Int);
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
