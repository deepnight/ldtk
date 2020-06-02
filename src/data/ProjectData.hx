package data;

class ProjectData implements data.IData {
	var nextUniqId = 0;
	public var levels : Array<LevelData> = [];
	public var layerDefs : Array<data.def.LayerDef> = [];

	public function new() {
	}

	public function makeUniqId() return nextUniqId++;

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

	public function getLevel(uid:Int) : Null<LevelData> {
		for(l in levels)
			if( l.uid==uid )
				return l;
		return null;
	}

	public function getLayerDef(uid:Int) : Null<LayerDef> {
		for(ld in layerDefs)
			if( ld.uid==uid )
				return ld;
		return null;
	}

	public function createLayerDef(type:LayerType, ?name:String) : LayerDef {
		var l = new LayerDef(makeUniqId(), type);
		if( name!=null )
			l.name = name;
		layerDefs.push(l);
		return l;
	}

	public function removeLayerDef(ld:LayerDef) {
		if( !layerDefs.remove(ld) )
			throw "Unknown layerDef";

		checkDataIntegrity();
	}

	public function createLevel() {
		var l = new LevelData(this);
		levels.push(l);
		return l;
	}

	public function removeLevel(l:LevelData) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		checkDataIntegrity();
	}


	public function checkDataIntegrity() {
		for(level in levels) {
			// Remove layerContents without layerDefs
			var i = 0;
			while( i<level.layerContents.length ) {
				if( level.layerContents[i].def==null )
					level.layerContents.splice(i,1);
				else
					i++;
			}

			// Add missing layerContents
			for(ld in layerDefs)
				if( level.getLayerContent(ld.uid)==null )
					level.layerContents.push( new LayerContent(level, ld) );

			// Cleanup layer values
			for(lc in level.layerContents)
				switch lc.def.type {
					case IntGrid:
						// Remove lost intGrid values
						for(cy in 0...lc.cHei)
						for(cx in 0...lc.cWid) {
							if( lc.getIntGrid(cx,cy) >= lc.def.intGridValues.length )
								lc.removeIntGrid(cx,cy);
						}
					case Entities:
				}
		}
	}
}
