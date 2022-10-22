package data.def;

class TableDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var table: Map<String, Array<String>>;
	// public var uid(default,null) : Int;
	// public var identifier(default,set) : String;
	// public var values : Array<data.DataTypes.EnumDefValue> = [];
	// public var iconTilesetUid : Null<Int>;
	// public var externalRelPath : Null<String>;
	// public var externalFileChecksum : Null<String>;
	// public var tags : Tags;

	@:allow(data.Definitions)
	private function new(p:Project, table:Map<String, Array<String>>) {
		_project = p;
		this.table = table;
	}

	@:keep public function toString() {
		return 'TableDef#$table';
	}

	public static function fromJson(p:Project, json:ldtk.Json.TableDefJson) {
		var td = new TableDef(p, json.table);
		return td;
	}

	public function toJson() : ldtk.Json.TableDefJson {
		return {
			table: table
		}
	}
}
