package data.def;

class PokemonDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var id : Int;
	public var name : String;
	// public var uid(default,null) : Int;
	// public var identifier(default,set) : String;
	// public var values : Array<data.DataTypes.EnumDefValue> = [];
	// public var iconTilesetUid : Null<Int>;
	// public var externalRelPath : Null<String>;
	// public var externalFileChecksum : Null<String>;
	// public var tags : Tags;

	@:allow(data.Definitions)
	private function new(p:Project, id:Int, name:String) {
		_project = p;
		this.id = id;
		this.name = name;
	}

	@:keep public function toString() {
		return 'Placeholder toString in PokemonDef';
		//return 'EnumDef#$uid.$identifier(${values.length} values)';
	}

	// public static function fromJson(p:Project, jsonVersion:String, json:ldtk.Json.PokemonDefJson) {
	// 	var ed = new PokemonDef(p, JsonTools.readInt(json.id), json.name);

	// 	return ed;
	// }

	// public function toJson() : ldtk.Json.PokemonDefJson {
	// 	return {
	// 		id: id,
	// 		name: name			
	// 	}
	// }
}
