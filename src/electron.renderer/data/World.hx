package data;

class World {
	public var iid : String;
	public var identifier : String;
	public var levels : Array<Level> = [];
	public var worldGridWidth : Int;
	public var worldGridHeight : Int;
	public var worldLayout : ldtk.Json.WorldLayout;

	function new(p:Project) {}

	public function toJson() : ldtk.Json.WorldJson {
		return {
			iid: iid,
			identifier: identifier,
			worldGridWidth: worldGridWidth,
			worldGridHeight: worldGridHeight,
			worldLayout: JsonTools.writeEnum(worldLayout, false),
			levels: [],
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.WorldJson) : World {
		if( json.iid==null )
			json.iid = p.generateUniqueId_UUID();

		if( json.identifier==null )
			json.identifier = p.fixUniqueIdStr("World", (id)->{ return true; }); // HACK

		var w = new World(p);
		w.iid = json.iid;
		w.identifier = json.identifier;

		w.worldGridWidth = JsonTools.readInt( json.worldGridWidth, p.defaultLevelWidth );
		w.worldGridHeight = JsonTools.readInt( json.worldGridHeight, p.defaultLevelHeight );
		w.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, Free );

		for( levelJson in json.levels )
			w.levels.push( Level.fromJson(p, levelJson) );

		trace(w);

		return w;
	}
}