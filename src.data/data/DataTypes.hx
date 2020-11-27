package data;

/*
	WARNING: all the follow types are serialized when saving a Project:
		- do not remove Enum values,
		- always add new Enum values at the end of the Enum,
		- Enum values can be renamed (they are stored as enum indexes)
		- do not rename Typedef fields or change their type
*/

enum LayerType {
	IntGrid;
	Entities;
	Tiles;
	AutoLayer;
}


enum WorldLayout {
	Free;
	GridVania;
	LinearHorizontal;
	LinearVertical;
}


typedef IntGridValueDef = {
	var identifier : Null<String>;
	var color : UInt;
}

enum FieldType {
	F_Int;
	F_Float;
	F_String;
	F_Text;
	F_Bool;
	F_Color;
	F_Enum(enumDefUid:Int);
	F_Point;
	F_Path;
}

enum ValueWrapper {
	V_Int(v:Int);
	V_Float(v:Float);
	V_Bool(v:Bool);
	V_String(v:String);
}

enum FieldDisplayMode {
	Hidden;
	ValueOnly;
	NameAndValue;
	EntityTile;
	PointStar;
	PointPath;
	RadiusPx;
	RadiusGrid;
}

enum FieldDisplayPosition {
	Above;
	Center;
	Beneath;
}

enum EntityRenderMode {
	Rectangle;
	Ellipse;
	Tile;
	Cross;
}
enum EntityTileRenderMode {
	Stretch;
	Crop;
}

typedef TilesetSelection = {
	var ids : Array<Int>;
	var mode : TileEditMode;
}

enum TileEditMode {
	Stamp;
	Random;
}

typedef EnumDefValue = {
	var id : String;
	var tileId : Null<Int>;
}

typedef AutoLayerRuleGroup = {
	var uid : Int;
	var name : String;
	var active : Bool;
	var collapsed : Bool;
	var rules : Array<data.def.AutoLayerRuleDef>;
}

enum EntityLimitBehavior {
	DiscardOldOnes;
	PreventAdding;
	MoveLastOne;
}

enum AutoLayerRuleTileMode {
	Single;
	Stamp;
}
enum AutoLayerRuleCheckerMode {
	None;
	Horizontal;
	Vertical;
}

typedef GridTileInfos = {
	var tileId : Int;
	var flips : Int;
}