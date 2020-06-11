package data;

class ProjectData implements data.ISerializable {
	var nextUniqId = 0;
	public var defs : Definitions;
	public var levels : Array<LevelData> = [];

	public var dataVersion : Int;
	public var name : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var bgColor : UInt;

	private function new() {
		name = "New project";
		dataVersion = Const.DATA_VERSION;
		defaultGridSize = Const.DEFAULT_GRID_SIZE;
		bgColor = 0xffffff;
		defaultPivotX = defaultPivotY = 0;

		defs = new Definitions(this);
	}

	public static function createEmpty() {
		var p = new ProjectData();
		p.createLevel();
		return p;
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
		p.dataVersion = JsonTools.readInt(json.dataVersion, 0);
		p.nextUniqId = JsonTools.readInt( json.nextUniqId, 0 );
		p.name = JsonTools.readString( json.name );
		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Const.DEFAULT_GRID_SIZE );
		p.bgColor = JsonTools.readInt( json.bgColor, 0xffffff );

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( LevelData.fromJson(p, lvlJson) );

		p.dataVersion = Const.DATA_VERSION; // updated
		return p;
	}

	public function toJson() {
		return {
			dataVersion: dataVersion,
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


	public static function createTest() : ProjectData {
		var p = new ProjectData();

		// Hero
		var ed = p.defs.createEntityDef("Hero");
		ed.color = 0x00ff00;
		ed.width = 24;
		ed.height = 32;
		ed.maxPerLevel = 1;
		ed.setPivot(0.5,1);

		// // Hero.life
		var fd = ed.createField(p, F_Int);
		fd.name = "life";
		fd.setDefault(Std.string(3));
		fd.setMin("1");
		fd.setMax("10");

		// Collision layer
		var ld = p.defs.layers[0];
		ld.name = "Collisions";
		ld.getIntGridValueDef(0).name = "walls";
		ld.addIntGridValue(0x00ff00, "grass");
		ld.addIntGridValue(0x0000ff, "water");

		// Entity layer
		var ld = p.defs.createLayerDef(Entities,"Entities");

		// Decoration layer
		var ld = p.defs.createLayerDef(IntGrid,"Decorations");
		ld.gridSize = 8;
		ld.displayOpacity = 0.7;
		ld.getIntGridValueDef(0).color = 0x00ff00;

		p.tidy();

		return p;
	}
}
