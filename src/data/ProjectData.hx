package data;

class ProjectData implements data.IData {
	var nextUniqId = 0;
	public var levels : Array<LevelData> = [];
	public var layerDefs : Array<data.def.LayerDef> = [];
	public var entityDefs : Array<data.def.EntityDef> = [];

	public var name : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;

	public function new() {
		createLayerDef(IntGrid);
		name = "New project";
		defaultPivotX = defaultPivotY = 0;
	}

	public function makeUniqId() return nextUniqId++;

	@:keep public function toString() {
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
			while( i<level.layerInstances.length ) {
				if( level.layerInstances[i].def==null )
					level.layerInstances.splice(i,1);
				else
					i++;
			}

			// Add missing layerContents
			for(ld in layerDefs)
				if( level.getLayerInstance(ld.uid)==null )
					level.layerInstances.push( new LayerInstance(level, ld) );

			// TODO: remove useless layerContent data (ex: when layer type changed from Entity to IntGrid)

			// Cleanup layer values
			for(li in level.layerInstances)
				switch li.def.type {
					case IntGrid:
						// Remove lost intGrid values
						for(cy in 0...li.cHei)
						for(cx in 0...li.cWid) {
							if( li.getIntGrid(cx,cy) >= li.def.countIntGridValues() )
								li.removeIntGrid(cx,cy);
						}

					case Entities:
						// Remove lost entities (def removed)
						var i = 0;
						while( i<li.entityInstances.length ) {
							if( li.entityInstances[i].def==null )
								li.entityInstances.splice(i,1);
							else
								i++;
						}

						for(ei in li.entityInstances) {
							// Remove fields whose def was removed
							var i = 0;
							while( i<ei.fieldInstances.length )
								if( ei.fieldInstances[i].def==null )
									ei.fieldInstances.splice(i,1);
								else
									i++;
						}
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
			var moved = l.layerInstances.splice(from,1)[0];
			l.layerInstances.insert(to, moved);
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

		ed.setPivot( defaultPivotX, defaultPivotY );

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


	/**  FIELD DEFS  *****************************************/
	public function getFieldDef(id:Int) : Null<FieldDef> {
		for(ed in entityDefs)
		for(fd in ed.fieldDefs)
			if( fd.uid==id )
				return fd;
		return null;
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
