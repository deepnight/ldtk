package data;

class ProjectData implements data.ISerializable {
	var nextUniqId = 0;
	public var levels : Array<LevelData> = [];
	public var defs : Definitions;

	public var name : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var bgColor : UInt;
	public var defaultGridSize : Int;

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
		var e = new ProjectData();
		for(l in levels)
			e.levels.push( l.clone() );
		e.nextUniqId = nextUniqId;
		return e;
	}

	public function toJson() {
		return {
			nextUniqId: nextUniqId,
			levels: levels.map( function(l) return l.toJson() ),
		}
	}

	public function tidy() {
		// TODO ensure .project references

		for(level in levels)
			level.tidy(this);
	}


	/**  LEVELS  *****************************************/

	public function createLevel() {
		var l = new LevelData(makeUniqId());
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
