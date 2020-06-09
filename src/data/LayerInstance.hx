package data;

class LayerInstance implements IData { // TODO rename: LayerInstance
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project; // TODO
	public var def(get,never) : data.def.LayerDef; inline function get_def() return project.getLayerDef(layerDefId); // TODO
	public var level(get,never) : LevelData; function get_level() return project.getLevel(levelId);
	public var cWid(get,never) : Int; inline function get_cWid() return M.ceil( level.pxWid / def.gridSize );
	public var cHei(get,never) : Int; function get_cHei() return M.ceil( level.pxHei / def.gridSize );

	public var levelId : Int;
	public var layerDefId : Int;

	var intGrid : Map<Int,Int> = new Map();
	public var entityInstances : Array<EntityInstance> = [];

	public function new(l:LevelData, def:LayerDef) {
		levelId = l.uid;
		layerDefId = def.uid;
	}


	@:keep public function toString() {
		return 'LayerInstance#<${def.name}:${def.type}>';
	}


	public function clone() {
		var e = new LayerInstance(level, def);
		// TODO
		return e;
	}

	public function toJson() {
		return {}
	}

	inline function requireType(t:LayerType) {
		if( def.type!=t )
			throw 'Only works on $t layer!';
	}

	public inline function isValid(cx:Int,cy:Int) {
		return cx>=0 && cx<cWid && cy>=0 && cy<cHei;
	}

	public inline function coordId(cx:Int, cy:Int) {
		return cx + cy*cWid;
	}

	public function tidy(project:ProjectData) {
		switch def.type {
			case IntGrid:
				// Remove lost intGrid values
				for(cy in 0...cHei)
				for(cx in 0...cWid) {
					if( getIntGrid(cx,cy) >= def.countIntGridValues() )
						removeIntGrid(cx,cy);
				}

			case Entities:
				// Remove lost entities (def removed)
				var i = 0;
				while( i<entityInstances.length ) {
					if( entityInstances[i].def==null )
						entityInstances.splice(i,1);
					else
						i++;
				}

				// Cleanup field instances
				for(ei in entityInstances)
					ei.tidy(project);
		}
}

	/** INT GRID *******************/

	public function getIntGrid(cx:Int, cy:Int) : Int {
		requireType(IntGrid);
		return !isValid(cx,cy) || !intGrid.exists( coordId(cx,cy) ) ? -1 : intGrid.get( coordId(cx,cy) );
	}

	public function getIntGridColorAt(cx:Int, cy:Int) : Null<UInt> {
		var v = def.getIntGridValueDef( getIntGrid(cx,cy) );
		return v==null ? null : v.color;
	}

	public function setIntGrid(cx:Int, cy:Int, v:Int) {
		requireType(IntGrid);
		if( isValid(cx,cy) )
			intGrid.set( coordId(cx,cy), v );
	}
	public function removeIntGrid(cx:Int, cy:Int) {
		requireType(IntGrid);
		if( isValid(cx,cy) )
			intGrid.remove( coordId(cx,cy) );
	}


	/** ENTITY INSTANCE *******************/

	public function createEntityInstance(ed:EntityDef) : EntityInstance {
		if( ed.maxPerLevel>0 ) {
			var all = entityInstances.filter( function(ei) return ei.defId==ed.uid );
			while( all.length>=ed.maxPerLevel )
				removeEntityInstance( all.shift() );
		}

		var ei = new EntityInstance(ed);
		entityInstances.push(ei);
		return ei;
	}

	public function removeEntityInstance(e:EntityInstance) {
		if( !entityInstances.remove(e) )
			throw "Unknown instance "+e;
	}
}