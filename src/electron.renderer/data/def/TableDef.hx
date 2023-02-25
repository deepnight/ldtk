package data.def;

class TableDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var name: String;
	public var primaryKey: Null<String>;
	public var columns: Array<String>;
	public var data: Array<Array<Dynamic>>;
	// public var identifier(default,set) : String;
	// public var values : Array<data.DataTypes.EnumDefValue> = [];
	// public var iconTilesetUid : Null<Int>;
	// public var externalRelPath : Null<String>;
	// public var externalFileChecksum : Null<String>;
	// public var tags : Tags;

	@:allow(data.Definitions)
	private function new(p:Project, uid:Int, name:String, primaryKey:Null<String>, columns:Array<String>, data:Array<Array<Dynamic>>) {
		_project = p;
		this.uid = uid;
		this.name = name;
		this.primaryKey = primaryKey;
		this.columns = columns;
		this.data = data;
	}

	@:keep public function toString() {
		return 'TableDef#$name';
	}

	public static function fromJson(p:Project, json:ldtk.Json.TableDefJson) {
		var td = new TableDef(p, json.uid, json.name, json.primaryKey, json.columns, json.data);
		return td;
	}

	public function toJson() : ldtk.Json.TableDefJson {
		return {
			uid: uid,
			name: name,
			primaryKey: primaryKey,
			columns: columns,
			data: data
		}
	}
	
	public function getPrimaryRow() {
		var pki = this.columns.indexOf(this.primaryKey);
		var data = [];
		for(i in 0...this.data.length) {
			var row = this.data[i];
			data.push(row[pki]);
		}
		return data;
	}
}
