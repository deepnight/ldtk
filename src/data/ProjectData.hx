package data;

class ProjectData implements data.IData {
	var nextUniqId = 0;
	public var name : String;
	public var levels : Array<LevelData> = [];
	public var layerDefs : Array<data.def.LayerDef> = [];
	public var entityDefs : Array<data.def.EntityDef> = [];

	public function new() {
		createLayerDef(IntGrid);
		name = "New project";
	}

	public function makeUniqId() return nextUniqId++;

	public function toString() {
		return '$name(levels=${levels.length}, layerDefs=${layerDefs.length}, entDefs=${entityDefs.length})';
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

			// TODO: remove useless layerContent data (ex: when layer type changed from Entity to IntGrid)

			// Cleanup layer values
			for(lc in level.layerContents)
				switch lc.def.type {
					case IntGrid:
						// Remove lost intGrid values
						for(cy in 0...lc.cHei)
						for(cx in 0...lc.cWid) {
							if( lc.getIntGrid(cx,cy) >= lc.def.countIntGridValues() )
								lc.removeIntGrid(cx,cy);
						}
					case Entities:
				}
		}
	}


	/**  LAYER DEFS  *****************************************/

	public function getLayerDef(uid:Int) : Null<LayerDef> {
		for(ld in layerDefs)
			if( ld.uid==uid )
				return ld;
		return null;
	}

	public function createLayerDef(type:LayerType, ?name:String) : LayerDef {
		var l = new LayerDef(makeUniqId(), type);
		if( name!=null && isLayerNameValid(name) )
			l.name = name;
		layerDefs.push(l);
		return l;
	}

	public function isLayerNameValid(name:String) {
		for(ld in layerDefs)
			if( ld.name==name )
				return false;
		return true;
	}

	public function removeLayerDef(ld:LayerDef) {
		if( !layerDefs.remove(ld) )
			throw "Unknown layerDef";

		checkDataIntegrity();
	}

	public function sortLayerDef(from:Int, to:Int) : Null<LayerDef> {
		if( from<0 || from>=layerDefs.length || from==to )
			return null;

		if( to<0 || to>=layerDefs.length )
			return null;

		checkDataIntegrity();

		var moved = layerDefs.splice(from,1)[0];
		layerDefs.insert(to, moved);

		// Also sort level layerContents
		for(l in levels) {
			var moved = l.layerContents.splice(from,1)[0];
			l.layerContents.insert(to, moved);
		}

		return moved;
	}


	/**  ENTITY DEFS  *****************************************/

	public function getEntityDef(uid:Int) : Null<EntityDef> {
		for(ed in entityDefs)
			if( ed.uid==uid )
				return ed;
		return null;
	}

	public function createEntityDef(?name:String) : EntityDef {
		var ed = new EntityDef(makeUniqId());
		entityDefs.push(ed);
		if( isEntityNameValid(name) )
			ed.name = name;
		return ed;
	}

	public function removeEntityDef(ed:EntityDef) {
		entityDefs.remove(ed);
		checkDataIntegrity();
	}

	public function isEntityNameValid(name:String) {
		if( name==null || name.length==0 )
			return false;

		for(ed in entityDefs)
			if( ed.name==name )
				return false;
		return true;
	}

	public function sortEntityDef(from:Int, to:Int) : Null<EntityDef> {
		if( from<0 || from>=entityDefs.length || from==to )
			return null;

		if( to<0 || to>=entityDefs.length )
			return null;

		checkDataIntegrity();

		var moved = entityDefs.splice(from,1)[0];
		entityDefs.insert(to, moved);

		return moved;
	}



	/**  LEVELS  *****************************************/

	public function createLevel() {
		var l = new LevelData(makeUniqId());
		l.initLayersUsingProject(this);
		levels.push(l);
		return l;
	}

	public function removeLevel(l:LevelData) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		checkDataIntegrity();
	}

	public function getLevel(uid:Int) : Null<LevelData> {
		for(l in levels)
			if( l.uid==uid )
				return l;
		return null;
	}
}
