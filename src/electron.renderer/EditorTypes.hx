
enum GlobalEvent {
	ViewportChanged(zoomChanged:Bool);
	AppSettingsChanged;
	LastChanceEnded;

	ProjectSelected;
	ProjectSettingsChanged;
	BeforeProjectSaving;
	ProjectSaved;

	LevelSelected(level:data.Level);
	LevelSettingsChanged(level:data.Level);
	LevelAdded(level:data.Level);
	LevelRemoved(level:data.Level);
	LevelResized(level:data.Level);
	LevelRestoredFromHistory(level:data.Level);
	LevelJsonCacheInvalidated(level:data.Level);

	WorldLevelMoved(level:data.Level, isFinal:Bool, prevNeighbourIids:Null<Array<String>>);
	WorldSettingsChanged;
	WorldCreated(w:data.World);
	WorldRemoved(w:data.World);

	LayerDefAdded;
	LayerDefRemoved(defUid:Int);
	LayerDefChanged(defUid:Int);
	LayerDefSorted;
	LayerDefConverted;
	LayerDefIntGridValuesSorted(defUid:Int);
	LayerDefIntGridValueRemoved(defUid:Int, valueId:Int, isUsed:Bool);

	LayerRuleChanged(rule:data.def.AutoLayerRuleDef);
	LayerRuleAdded(rule:data.def.AutoLayerRuleDef);
	LayerRuleRemoved(rule:data.def.AutoLayerRuleDef);
	LayerRuleSeedChanged;
	LayerRuleSorted;

	LayerRuleGroupAdded(rg:data.DataTypes.AutoLayerRuleGroup);
	LayerRuleGroupRemoved(rg:data.DataTypes.AutoLayerRuleGroup);
	LayerRuleGroupChanged(rg:data.DataTypes.AutoLayerRuleGroup);
	LayerRuleGroupChangedActiveState(rg:data.DataTypes.AutoLayerRuleGroup);
	LayerRuleGroupSorted;
	LayerRuleGroupCollapseChanged(rg:data.DataTypes.AutoLayerRuleGroup);

	LayerInstanceSelected;
	LayerInstanceEditedByTool(li:data.inst.LayerInstance);
	LayerInstanceChangedGlobally(li:data.inst.LayerInstance);
	LayerInstanceVisiblityChanged(li:data.inst.LayerInstance);
	LayerInstancesRestoredFromHistory(lis:Array<data.inst.LayerInstance>);
	AutoLayerRenderingChanged;
	LayerInstanceTilesetChanged(li:data.inst.LayerInstance);

	TilesetImageLoaded(td:data.def.TilesetDef, isInitial:Bool);
	TilesetDefChanged(td:data.def.TilesetDef);
	TilesetDefAdded(td:data.def.TilesetDef);
	TilesetDefRemoved(td:data.def.TilesetDef);
	TilesetMetaDataChanged(td:data.def.TilesetDef);
	TilesetSelectionSaved(td:data.def.TilesetDef);
	TilesetDefPixelDataCacheRebuilt(td:data.def.TilesetDef);
	TilesetDefSorted;
	TilesetEnumChanged;

	EntityInstanceAdded(ei:data.inst.EntityInstance);
	EntityInstanceRemoved(ei:data.inst.EntityInstance);
	EntityInstanceChanged(ei:data.inst.EntityInstance);

	EntityDefAdded;
	EntityDefRemoved;
	EntityDefChanged;
	EntityDefSorted;

	FieldDefAdded(fd:data.def.FieldDef);
	FieldDefRemoved(fd:data.def.FieldDef);
	FieldDefChanged(fd:data.def.FieldDef);
	FieldDefSorted;
	LevelFieldInstanceChanged(l:data.Level, fi:data.inst.FieldInstance);
	EntityFieldInstanceChanged(ei:data.inst.EntityInstance, fi:data.inst.FieldInstance);

	EnumDefAdded;
	EnumDefRemoved;
	EnumDefChanged;
	EnumDefSorted;
	EnumDefValueRemoved;
	ExternalEnumsLoaded(anyCriticalChange:Bool);

	ToolValueSelected;
	ToolOptionChanged;

	WorldSelected(w:data.World);

	WorldMode(active:Bool);
	WorldDepthSelected(worldDepth:Int);
	GridChanged(active:Bool);
	ShowDetailsChanged(active:Bool);
}

enum CursorType {
	None;
	Forbidden;
	Pan;
	Panning;
	Move;
	Moving;
	PickNothing;
	Pointer;
	Add;
	Resize(p:RectHandlePos);

	Eraser(x:Int,y:Int);
	GridCell(li:data.inst.LayerInstance, cx:Int, cy:Int, ?col:UInt);
	GridRect(li:data.inst.LayerInstance, cx:Int, cy:Int, wid:Int, hei:Int, ?col:UInt);
	Entity(li:data.inst.LayerInstance, def:data.def.EntityDef, ?ei:data.inst.EntityInstance, x:Int, y:Int, highlight:Bool);
	Tiles(li:data.inst.LayerInstance, tileIds:Array<Int>, cx:Int, cy:Int, flips:Int);
	Link(fx:Float, fy:Float, tx:Float, ty:Float, color:UInt);
}

enum GenericLevelElement {
	GridCell(li:data.inst.LayerInstance, cx:Int, cy:Int);
	Entity(li:data.inst.LayerInstance, ei:data.inst.EntityInstance);
	PointField(li:data.inst.LayerInstance, ei:data.inst.EntityInstance, fi:data.inst.FieldInstance, arrayIdx:Int);
}

enum ToolEditMode {
	Add;
	Remove;
}

enum RectHandlePos {
	Top;
	Bottom;
	Left;
	Right;

	TopLeft;
	TopRight;
	BottomLeft;
	BottomRight;
}

typedef ParsedExternalEnumData = {
	var color: Null<Int>;
	var tileRect: Null<ldtk.Json.TilesetRect>;
}
typedef ParsedExternalEnum = {
	var enumId : String;
	var tilesetUid : Null<Int>;
	var values : Array<{
		var valueId: String;
		var data : ParsedExternalEnumData;
	}>;
}

enum EnumSyncChange {
	Added;
	Removed;
	Renamed(to:String);
}

typedef EnumSyncDiff = {
	var enumId: String;
	var newTilesetUid: Null<Int>;
	var ?warning: Bool;
	var change: Null<EnumSyncChange>;
	var valueDiffs: Map<String, EnumValueSyncDiff>;
}

typedef EnumValueSyncDiff = {
	var valueId: String;
	var ?warning: Bool;
	var change: EnumSyncChange;
	var data: ParsedExternalEnumData;
}

enum ImageLoadingResult {
	Ok;
	FileNotFound;
	LoadingFailed(err:String);
	TrimmedPadding;
	RemapLoss;
	RemapSuccessful;
	UnsupportedFileOrigin(origin:String);
}

enum TilesetSelectionMode {
	None;
	PickAndClose;
	PickSingle;
	Free;
	RectOnly;
}

enum TilePickerDisplayMode {
	ShowOpaques;
	ShowPixelData;
}

typedef FileSavingData = {
	var projectJsonStr: String;
	var externLevels: Array<{ jsonStr:String, relPath:String, id:String }>;
}

enum LevelError {
	NoError;
	InvalidEntityTag(ei:data.inst.EntityInstance);
	InvalidEntityField(ei:data.inst.EntityInstance);
	InvalidBgImage;
}

enum ClipboardType {
	CLayerDef;
	CEntityDef;
	CEnumDef;
	CTilesetDef;

	CFieldDef;

	CRuleGroup;
	CRule;
}

typedef CachedIID = {
	var level: data.Level;
	var ?ei: data.inst.EntityInstance ;
}
