package data;

class ProjectData implements data.IData {
	var nextUniqId = 0;
	public var levels : Array<LevelData> = [];
	public var layerDefs : Array<data.def.LayerDef> = [];

	public function new() {
	}

	public function getNextUniqId() return nextUniqId++;

	public function toString() {
		return Type.getClassName(Type.getClass(this));
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

	public function createLayerDef(type:LayerType, ?name:String) : LayerDef {
		var l = new LayerDef(type);
		if( name!=null )
			l.name = name;
		layerDefs.push(l);
		return l;
	}

	public function createLevel() {
		var l = new LevelData(this);
		levels.push(l);
		return l;
	}

	public function removeLevel(l:LevelData) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";
	}

}
