package led.inst;

import led.LedTypes;

class LayerInstance {
	var _project : Project;
	public var def(get,never) : led.def.LayerDef; inline function get_def() return _project.defs.getLayerDef(layerDefUid);
	public var level(get,never) : Level; function get_level() return _project.getLevel(levelId);

	public var levelId : Int;
	public var layerDefUid : Int;
	public var pxOffsetX : Int = 0;
	public var pxOffsetY : Int = 0;

	// Layer content
	var intGrid : Map<Int,Int> = new Map(); // <coordId, value>
	public var entityInstances : Array<EntityInstance> = [];
	public var gridTiles : Map<Int,Int> = []; // <coordId, tileId>

	/** < RuleUid, < coordId, {tileInfos} > > **/
	public var autoTiles : Map<Int, Map<Int, { tileId:Int, flips:Int }> > = [];

	public var cWid(get,never) : Int; inline function get_cWid() return dn.M.ceil( level.pxWid / def.gridSize );
	public var cHei(get,never) : Int; inline function get_cHei() return dn.M.ceil( level.pxHei / def.gridSize );


	public function new(p:Project, levelId:Int, layerDefUid:Int) {
		_project = p;
		this.levelId = levelId;
		this.layerDefUid = layerDefUid;
	}


	@:keep public function toString() {
		return 'LayerInstance#<${def.identifier}:${def.type}>';
	}


	public function toJson() {
		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__type: Std.string(def.type),
			__cWid: cWid,
			__cHei: cHei,
			__gridSize: def.gridSize,

			levelId: levelId,
			layerDefUid: layerDefUid,
			pxOffsetX: pxOffsetX,
			pxOffsetY: pxOffsetY,

			intGrid: {
				var arr = [];
				for(e in intGrid.keyValueIterator())
					arr.push({
						coordId: e.key,
						v: e.value,
					});
				arr;
			},

			// __autoTiles: {
			// 	applyAllAutoLayerRules(); // HACK autoTiles should actually be saved and reused for perf issues

			// 	var perCoords = new Map();
			// 	for( rTiles in autoTiles ) {
			// 		for( at in rTiles.keyValueIterator() ) {
			// 			if( !perCoords.exists(at.key) )
			// 				perCoords.set(at.key, []);
			// 			perCoords.get(at.key).push(at.value);
			// 		}
			// 	}

			// 	var arr = [];
			// 	for( e in perCoords.keyValueIterator() )
			// 		arr.push({
			// 			coordId: e.key,
			// 			tiles: e.value,
			// 		});
			// 	arr;
			// },

			gridTiles: {
				var arr = [];
				for(e in gridTiles.keyValueIterator())
					arr.push({
						coordId: e.key,
						v: e.value,
					});
				arr;
			},
			entityInstances: entityInstances.map( function(ei) return ei.toJson(this) ),
		}
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var li = new led.inst.LayerInstance( p, JsonTools.readInt(json.levelId), JsonTools.readInt(json.layerDefUid) );

		for( intGridJson in JsonTools.readArray(json.intGrid) )
			li.intGrid.set( intGridJson.coordId, intGridJson.v );

		for( gridTilesJson in JsonTools.readArray(json.gridTiles) )
			li.gridTiles.set( gridTilesJson.coordId, gridTilesJson.v );

		for( entityJson in JsonTools.readArray(json.entityInstances) )
			li.entityInstances.push( EntityInstance.fromJson(p, entityJson) );

		li.pxOffsetX = JsonTools.readInt(json.pxOffsetX, 0);
		li.pxOffsetY = JsonTools.readInt(json.pxOffsetY, 0);

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

	public function getCx(coordId:Int) {
		return coordId - Std.int(coordId/cWid)*cWid;
	}

	public inline function getCy(coordId:Int) {
		return Std.int(coordId/cWid);
	}

	public function tidy(p:Project) {
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

			case Tiles:
				// Lost tileset
				if( _project.defs.getTilesetDef(def.tilesetDefUid)==null )
					def.tilesetDefUid = null;
		}
	}


	@:allow(led.Level)
	function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		var pxDeltaX = pxOffsetX - newPxLeft;
		var pxDeltaY = pxOffsetY - newPxTop;
		var newCWid = dn.M.ceil( newPxWid / def.gridSize );
		var newCHei = dn.M.ceil( newPxHei/ def.gridSize );

		// Move data
		var cDeltaX = Std.int(pxDeltaX/def.gridSize);
		var cDeltaY = Std.int(pxDeltaY/def.gridSize);
		switch def.type {
			case IntGrid:
				// Remap coords
				var old = intGrid;
				intGrid = new Map();
				for(cx in 0...cWid)
				for(cy in 0...cHei) {
					var newCx = cx + cDeltaX;
					var newCy = cy + cDeltaY;
					var newCoordId = newCx + newCy * newCWid;
					if( old.exists(coordId(cx,cy)) && newCx>=0 && newCx<newCWid && newCy>=0 && newCy<newCHei )
						intGrid.set( newCoordId, old.get(coordId(cx,cy)) );
				}

			case Entities:
				var i = 0;
				while( i<entityInstances.length ) {
					var ei = entityInstances[i];
					ei.x += pxDeltaX;
					ei.y += pxDeltaY;
					if( ei.x<0 || ei.y<0 )
						entityInstances.splice(i,1);
					else
						i++;
				}

			case Tiles:
				// Remap coords
				var old = gridTiles;
				gridTiles = new Map();
				for(cx in 0...cWid)
				for(cy in 0...cHei) {
					var newCx = cx + cDeltaX;
					var newCy = cy + cDeltaY;
					var newCoordId = newCx + newCy * newCWid;
					if( old.exists(coordId(cx,cy)) && newCx>=0 && newCx<newCWid && newCy>=0 && newCy<newCHei )
						gridTiles.set( newCoordId, old.get(coordId(cx,cy)) );
				}

		}

		// The remaining pixels are stored in offsets
		pxOffsetX = pxDeltaX % def.gridSize;
		pxOffsetY = pxDeltaY % def.gridSize;
	}


	/** INT GRID *******************/

	public inline function getIntGrid(cx:Int, cy:Int) : Int {
		requireType(IntGrid);
		return !isValid(cx,cy) || !intGrid.exists( coordId(cx,cy) ) ? -1 : intGrid.get( coordId(cx,cy) );
	}

	public inline function getIntGridColorAt(cx:Int, cy:Int) : Null<UInt> {
		var v = def.getIntGridValueDef( getIntGrid(cx,cy) );
		return v==null ? null : v.color;
	}

	public inline function getIntGridIdentifierAt(cx:Int, cy:Int) : Null<String> {
		var v = def.getIntGridValueDef( getIntGrid(cx,cy) );
		return v==null ? null : v.identifier;
	}

	public function setIntGrid(cx:Int, cy:Int, v:Int) {
		requireType(IntGrid);
		if( isValid(cx,cy) )
			intGrid.set( coordId(cx,cy), v );
	}

	public inline function hasIntGrid(cx:Int, cy:Int) {
		requireType(IntGrid);
		return getIntGrid(cx,cy)!=-1;
	}

	public function removeIntGrid(cx:Int, cy:Int) {
		requireType(IntGrid);
		if( isValid(cx,cy) )
			intGrid.remove( coordId(cx,cy) );
	}


	/** ENTITY INSTANCE *******************/

	public function createEntityInstance(ed:led.def.EntityDef) : Null<EntityInstance> {
		requireType(Entities);
		if( ed.maxPerLevel>0 ) {
			var all = entityInstances.filter( function(ei) return ei.defUid==ed.uid );
			if( ed.discardExcess )
				while( all.length>=ed.maxPerLevel )
					removeEntityInstance( all.shift() );
			else if( all.length>=ed.maxPerLevel )
				return null;
		}

		var ei = new EntityInstance(_project, ed.uid);
		entityInstances.push(ei);
		return ei;
	}

	public function duplicateEntityInstance(ei:EntityInstance) : EntityInstance {
		var copy = EntityInstance.fromJson( _project, ei.toJson(this) );
		entityInstances.push(copy);
		return copy;
	}

	public function removeEntityInstance(e:EntityInstance) {
		requireType(Entities);
		if( !entityInstances.remove(e) )
			throw "Unknown instance "+e;
	}



	/** TILES *******************/

	public function setGridTile(cx:Int, cy:Int, tileId:Int) {
		if( isValid(cx,cy) )
			gridTiles.set( coordId(cx,cy), tileId );
	}

	public function removeGridTile(cx:Int, cy:Int) {
		if( isValid(cx,cy) )
			gridTiles.remove( coordId(cx,cy) );
	}

	public function getGridTile(cx:Int, cy:Int) : Null<Int> {
		return !isValid(cx,cy) || !gridTiles.exists( coordId(cx,cy) ) ? null : gridTiles.get( coordId(cx,cy) );
	}

	public inline function hasGridTile(cx:Int, cy:Int) : Bool {
		return getGridTile(cx,cy)!=null;
	}



	inline function applyAutoLayerRuleAt(r:led.def.AutoLayerRule, cx:Int, cy:Int) {
		if( def.isAutoLayer() ) {
			// Init
			if( !autoTiles.exists(r.uid) )
				autoTiles.set( r.uid, new Map() );
			autoTiles.get(r.uid).remove( coordId(cx,cy) );

			// Apply rule
			if( r.matches(this, cx,cy) ) {
				autoTiles.get(r.uid).set( coordId(cx,cy), { tileId:r.getRandomTileForCoord(cx,cy), flips:0 } );
				return true;
			}
			else if( r.flipX && r.matches(this, cx,cy, -1) ) {
				autoTiles.get(r.uid).set( coordId(cx,cy), { tileId:r.getRandomTileForCoord(cx,cy), flips:1 } );
				return true;
			}
			else if( r.flipY && r.matches(this, cx,cy, 1, -1) ) {
				autoTiles.get(r.uid).set( coordId(cx,cy), { tileId:r.getRandomTileForCoord(cx,cy), flips:2 } );
				return true;
			}
			else if( r.flipX && r.flipY && r.matches(this, cx,cy, -1, -1) ) {
				autoTiles.get(r.uid).set( coordId(cx,cy), { tileId:r.getRandomTileForCoord(cx,cy), flips:3 } );
				return true;
			}
			else
				return false;
		}
		else
			return false;
	}

	public function applyAllAutoLayerRulesAt(cx:Int, cy:Int, wid:Int, hei:Int) {
		if( !def.isAutoLayer() )
			return;

		// Adjust bounds to also redraw nearby cells
		var left = dn.M.imax( 0, cx - Std.int(Const.MAX_AUTO_PATTERN_SIZE*0.5) );
		var top = dn.M.imax( 0, cy - Std.int(Const.MAX_AUTO_PATTERN_SIZE*0.5) );
		var right = dn.M.imin( cWid-1, cx + wid-1 + Std.int(Const.MAX_AUTO_PATTERN_SIZE*0.5) );
		var bottom = dn.M.imin( cHei-1, cy + hei-1 + Std.int(Const.MAX_AUTO_PATTERN_SIZE*0.5) );

		// Apply rules
		for(cx in left...right+1)
		for(cy in top...bottom+1)
		for(r in def.rules)
			applyAutoLayerRuleAt(r,cx,cy);
	}

	public function applyAllAutoLayerRules() {
		if( !def.isAutoLayer() )
			return;

		autoTiles = new Map();
		applyAllAutoLayerRulesAt(0, 0, cWid, cHei);
	}

	public function applyAutoLayerRule(r:led.def.AutoLayerRule) {
		if( !def.isAutoLayer() )
			return;

		for(cx in 0...cWid)
		for(cy in 0...cHei)
			applyAutoLayerRuleAt(r, cx,cy);
	}

}