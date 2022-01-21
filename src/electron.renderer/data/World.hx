package data;

class World {
	var _project : data.Project;

	public var iid : String;
	public var identifier : String;
	public var levels : Array<Level> = [];
	public var worldGridWidth : Int;
	public var worldGridHeight : Int;
	public var worldLayout : ldtk.Json.WorldLayout;


	public function new(p:Project, iid:String, identifier:String) {
		_project = p;
		this.iid = iid;
		this.identifier = identifier;
		worldGridWidth = p.defaultLevelWidth;
		worldGridHeight= p.defaultLevelHeight;
		worldLayout = Free;
	}

	@:keep
	public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '.$identifier (${levels.length} levels)';
	}


	public function toJson() : ldtk.Json.WorldJson {
		return {
			iid: iid,
			identifier: identifier,
			worldGridWidth: worldGridWidth,
			worldGridHeight: worldGridHeight,
			worldLayout: JsonTools.writeEnum(worldLayout, false),
			levels: levels.map( l->l.toJson() ),
		}
	}


	public static function fromJson(p:Project, json:ldtk.Json.WorldJson) : World {
		if( json.iid==null )
			json.iid = p.generateUniqueId_UUID();

		if( json.identifier==null )
			json.identifier = p.fixUniqueIdStr("World", (id)->p.isWorldIdentifierUnique(id));

		var w = new World(p, json.iid, json.identifier);
		w.iid = json.iid;
		w.identifier = json.identifier;

		w.worldGridWidth = JsonTools.readInt( json.worldGridWidth, p.defaultLevelWidth );
		w.worldGridHeight = JsonTools.readInt( json.worldGridHeight, p.defaultLevelHeight );
		w.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, Free );

		for( levelJson in json.levels )
			w.levels.push( Level.fromJson(p, levelJson) );

		return w;
	}


	public function tidy(p:Project) {
		_project = p;
		for( l in levels )
			l.tidy(p);
	}
}