package data.def;

class TableDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var name: String;
	public var columns: Array<String>;
	public var data: Array<Array<Dynamic>>;
	// public var uid(default,null) : Int;
	// public var identifier(default,set) : String;
	// public var values : Array<data.DataTypes.EnumDefValue> = [];
	// public var iconTilesetUid : Null<Int>;
	// public var externalRelPath : Null<String>;
	// public var externalFileChecksum : Null<String>;
	// public var tags : Tags;

	@:allow(data.Definitions)
	private function new(p:Project, name:String, columns:Array<String>, data:Array<Array<Dynamic>>) {
		_project = p;
		this.name = name;
		this.columns = columns;
		this.data = data;
	}

	@:keep public function toString() {
		return 'TableDef#$name';
	}

	public static function fromJson(p:Project, json:ldtk.Json.TableDefJson) {
		var td = new TableDef(p, json.name, json.columns, json.data);
		return td;
	}

	public function toJson() : ldtk.Json.TableDefJson {
		return {
			name: name,
			columns: columns,
			data: data
		}
	}
}
