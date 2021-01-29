package data;

/*
	WARNING: all the follow types are serialized when saving a Project:
		- do not remove Enum values,
		- Enum values CANNOT be renamed (they are stored as strings)
		- do not rename Typedef fields or change their type
*/

typedef IntGridValueDef = {
	var identifier : Null<String>;
	var color : UInt;
}

enum ValueWrapper {
	V_Int(v:Int);
	V_Float(v:Float);
	V_Bool(v:Bool);
	V_String(v:String);
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

typedef GridTileInfos = {
	var tileId : Int;
	var flips : Int;
	var rotations : Int;
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

typedef CachedImage = {
	var relPath: String;
	var fileName: String;
	var base64: String;
	var bytes: haxe.io.Bytes;
	var pixels: hxd.Pixels;
	var tex: h3d.mat.Texture;
}