package data;

class LayerInstance implements ISerializable {
	var _project : ProjectData;
	public var def(get,never) : data.def.LayerDef; inline function get_def() return _project.defs.getLayerDef(layerDefId);
	public var level(get,never) : LevelData; function get_level() return _project.getLevel(levelId);

	public var levelId : Int;
	public var layerDefId : Int;
	var intGrid : Map<Int,Int> = new Map(); // <coordId,value>
	public var entityInstances : Array<EntityInstance> = [];

	public var cWid(get,never) : Int; inline function get_cWid() return M.ceil( level.pxWid / def.gridSize );
	public var cHei(get,never) : Int; function get_cHei() return M.ceil( level.pxHei / def.gridSize );


	public function new(p:ProjectData, levelId:Int, layerDefId:Int) {
		_project = p;
		this.levelId = levelId;
		this.layerDefId = layerDefId;
	}


	@:keep public function toString() {
		return 'LayerInstance#<${def.name}:${def.type}>';
	}


	public function clone() {
		return fromJson( _project, toJson() );
	}

	public function toJson() {
		var intGridJson = [];
		for(e in intGrid.keyValueIterator())
			intGridJson.push({
				coordId: e.key,
				v: e.value,
			});

		return {
			levelId: levelId,
			layerDefId: layerDefId,
			intGrid: intGridJson,
			entityInstances: entityInstances.map( function(ei) return ei.toJson() ),
		}
	}

	public static function fromJson(p:ProjectData, json:Dynamic) {
		var li = new LayerInstance( p, JsonTools.readInt(json.levelId), JsonTools.readInt(json.layerDefId) );

		for( intGridJson in JsonTools.readArray(json.intGrid) )
			li.intGrid.set( intGridJson.coordId, intGridJson.v );

		for( entityJson in JsonTools.readArray(json.entityInstances) )
			li.entityInstances.push( EntityInstance.fromJson(p, entityJson) );

		return li;
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

	public function tidy(p:ProjectData) {
		_project = p;

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
					ei.tidy(_project);
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
		requireType(Entities);
		if( ed.maxPerLevel>0 ) {
			var all = entityInstances.filter( function(ei) return ei.defId==ed.uid );
			while( all.length>=ed.maxPerLevel )
				removeEntityInstance( all.shift() );
		}

		var ei = new EntityInstance(_project, ed.uid);
		entityInstances.push(ei);
		return ei;
	}

	public function duplicateEntityInstance(ei:EntityInstance) : EntityInstance {
		var copy = ei.clone();
		entityInstances.push(copy);
		return copy;
	}

	public function removeEntityInstance(e:EntityInstance) {
		requireType(Entities);
		if( !entityInstances.remove(e) )
			throw "Unknown instance "+e;
	}
}