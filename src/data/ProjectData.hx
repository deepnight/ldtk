package data;

class ProjectData implements data.ISerializable {
	var nextUniqId = 0;
	public var defs : Definitions;
	public var levels : Array<LevelData> = [];

	public var name : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var bgColor : UInt;

	public function new() {
		name = "New project";
		defaultGridSize = Const.DEFAULT_GRID_SIZE;
		bgColor = 0xffffff;
		defaultPivotX = defaultPivotY = 0;

		defs = new Definitions(this);
		defs.createLayerDef(IntGrid);
	}

	public function makeUniqId() return nextUniqId++;

	@:keep public function toString() {
		return '$name(levels=${levels.length}, layerDefs=${defs.layers.length}, entDefs=${defs.entities.length})';
	}

	public function clone() {
		return fromJson( toJson() );
	}

	public static function fromJson(json:Dynamic) {
		var p = new ProjectData();
		p.nextUniqId = JsonTools.readInt( json.nextUniqId, 0 );
		p.name = JsonTools.readString( json.name );
		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Const.DEFAULT_GRID_SIZE );
		p.bgColor = JsonTools.readInt( json.bgColor, 0xffffff );

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( LevelData.fromJson(p, lvlJson) );

		return p;
	}

	public function toJson() {
		return {
			nextUniqId: nextUniqId,
			defs: defs.toJson(),
			levels: levels.map( function(l) return l.toJson() ),

			name: name,
			defaultPivotX: JsonTools.clampFloatPrecision( defaultPivotX ),
			defaultPivotY: JsonTools.clampFloatPrecision( defaultPivotY ),
			defaultGridSize: defaultGridSize,
			bgColor: bgColor,
		}
	}

	public function tidy() {
		for(level in levels)
			level.tidy(this);

		defs.tidy(this);
	}


	/**  LEVELS  *****************************************/

	public function createLevel() {
		var l = new LevelData(this, makeUniqId());
		levels.push(l);
		tidy(); // will create layer instances
		return l;
	}

	public function removeLevel(l:LevelData) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		tidy();
	}

	public function getLevel(uid:Int) : Null<LevelData> {
		for(l in levels)
			if( l.uid==uid )
				return l;
		return null;
	}
}
