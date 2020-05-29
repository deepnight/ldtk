package data;

class Project implements data.IData {
	var nextUniqId = 0;
	public var levels : Array<Level> = [];
	public var layerDefs : Array<data.def.LayerDef> = [];

	public function new() {
		layerDefs.push( new LayerDef(IntGrid) );
	}

	public function getNextUniqId() return nextUniqId++;

	public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function clone() {
		var e = new Project();
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

	public function createLevel() {
		var l = new Level(this);
		levels.push(l);
		return l;
	}

	public function removeLevel(l:Level) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";
	}

}
