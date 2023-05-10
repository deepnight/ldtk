package data;

/*
	WARNING: all the follow types are serialized when saving a Project:
		- do not remove Enum values,
		- Enum values CANNOT be renamed (they are stored as strings)
		- do not rename Typedef fields or change their type
*/

typedef IntGridValueDefEditor = {
	var value : Int;
	var identifier : Null<String>;
	var color : dn.Col;
	var tile : Null<ldtk.Json.TilesetRect>;
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
	var tileRect : Null<ldtk.Json.TilesetRect>;
	var color: Int;
}

typedef AutoLayerRuleGroup = {
	var uid : Int;
	var name : String;
	var active : Bool;
	var collapsed : Bool;
	var rules : Array<data.def.AutoLayerRuleDef>;
	var isOptional : Bool;
	var usesWizard : Bool;
}

typedef GridTileInfos = {
	var tileId : Int;
	var flips : Int;
}

typedef CachedImage = {
	var relPath: String;
	var fileName: String;
	var base64: String;
	var bytes: haxe.io.Bytes;
	var pixels: hxd.Pixels;
	var tex: h3d.mat.Texture;
}