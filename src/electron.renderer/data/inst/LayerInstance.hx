package data.inst;

import data.DataTypes;

class LayerInstance {
	var _project : Project;

	public var def(get,never) : data.def.LayerDef;
		inline function get_def() return _project.defs.getLayerDef(layerDefUid);

	public var level(get,never) : Level;
		inline function get_level() return _project.getLevelAnywhere(levelId);

	var camera(get,never) : display.Camera;
		inline function get_camera() return Editor.ME.camera;

	public var iid : String;
	public var levelId : Int;
	public var layerDefUid : Int;
	public var visible = true;

	@:allow(importer)
	var pxOffsetX : Int = 0;

	@:allow(importer)
	var pxOffsetY : Int = 0;

	public var pxTotalOffsetX(get,never) : Int;
		inline function get_pxTotalOffsetX() return pxOffsetX + def.pxOffsetX;

	public var pxTotalOffsetY(get,never) : Int;
		inline function get_pxTotalOffsetY() return pxOffsetY + def.pxOffsetY;

	public var pxParallaxX(get,never) : Int;
		inline function get_pxParallaxX() return M.round( pxTotalOffsetX + camera.getParallaxOffsetX(this) );

	public var pxParallaxY(get,never) : Int;
		inline function get_pxParallaxY() return M.round( pxTotalOffsetY + camera.getParallaxOffsetY(this) );

	public var seed : Int;
	public var optionalRules : Map<Int,Bool> = new Map();

	// Layer content
	var intGrid : Map<Int,Int> = new Map(); // <coordId, value>
	public var entityInstances : Array<EntityInstance> = [];
	public var gridTiles : Map<Int, Array<GridTileInfos>> = []; // <coordId, tileinfos>
	var overrideTilesetUid : Null<Int>;

	/** < RuleUid, < coordId, { tiles } > > **/
	public var autoTilesCache :
		Null< Map<Int, // RuleUID
			Map<Int, // CoordID
				// WARNING: x/y don't contain layerDef.pxOffsetX/Y (to avoid the need of a global update when changing these values). They are added in the JSON though.
				Array<{ x:Int, y:Int, flips:Int, srcX:Int, srcY:Int, tid:Int, a:Float }>
			>
		> > = null;

	var areaIntGridUseCount : Map<Int, Map<Int,Int>> = new Map();
	var layerIntGridUseCount : Map<Int,Int> = new Map();
	var intGridAreaSize = 10;

	public var pxWid(get,never) : Int; inline function get_pxWid() return level.pxWid - pxOffsetX;
	public var pxHei(get,never) : Int; inline function get_pxHei() return level.pxHei - pxOffsetY;
	public var cWid(get,never) : Int; inline function get_cWid() return dn.M.ceil( pxWid / def.gridSize );
	public var cHei(get,never) : Int; inline function get_cHei() return dn.M.ceil( pxHei / def.gridSize );


	@:allow(data.Level)
	private function new(p:Project, levelUid:Int, layerDefUid:Int, layerInstIid:String) {
		_project = p;
		iid = layerInstIid;
		this.levelId = levelUid;
		this.layerDefUid = layerDefUid;
		seed = Std.random(9999999);
	}

	inline function areaCoordId(cx:Int,cy:Int) {
		return Std.int(cx/intGridAreaSize) + Std.int(cy/intGridAreaSize) * 10000;
	}

	public inline function hasIntGridValueInArea(iv:Int, cx:Int, cy:Int) {
		return areaIntGridUseCount.exists(iv) && areaIntGridUseCount.get(iv).get(areaCoordId(cx,cy)) > 0;
	}

	public function recountAllIntGridValues() {
		if( def.type!=IntGrid )
			return;

		areaIntGridUseCount = new Map();
		layerIntGridUseCount = new Map();

		for(cy in 0...cHei)
		for(cx in 0...cWid) {
			if( hasIntGrid(cx,cy) )
				increaseAreaIntGridValueCount(getIntGrid(cx,cy), cx, cy);
		}
	}

	inline function increaseAreaIntGridValueCount(iv:Int, cx:Int, cy:Int) {
		if( iv==0 || iv==null )
			return;

		if( !areaIntGridUseCount.exists(iv) )
			areaIntGridUseCount.set(iv, new Map());

		var areaCountMap = areaIntGridUseCount.get(iv);
		final cid = areaCoordId(cx,cy);
		if( !areaCountMap.exists(cid) )
			areaCountMap.set(cid,1);
		else
			areaCountMap.set(cid, areaCountMap.get(cid)+1);

		// Layer counts
		if( !layerIntGridUseCount.exists(iv) )
			layerIntGridUseCount.set(iv, 1);
		else
			layerIntGridUseCount.set(iv, layerIntGridUseCount.get(iv)+1);

		// Also update group
		if( iv<1000 ) {
			var groupUid = def.getIntGridGroupUidFromValue(iv);
			if( groupUid>=0 )
				increaseAreaIntGridValueCount(def.getRuleValueFromGroupUid(groupUid), cx,cy);
		}
	}


	inline function decreaseAreaIntGridValueCount(iv:Int, cx:Int, cy:Int) {
		if( iv!=0 && iv!=null && areaIntGridUseCount.exists(iv) ) {
			var areaCountMap = areaIntGridUseCount.get(iv);
			final cid = areaCoordId(cx,cy);
			if( areaCountMap.exists(cid) ) {
				areaCountMap.set(cid, areaCountMap.get(cid)-1);

				// Last one in area
				if( areaCountMap.get(cid)<=0 )
					areaCountMap.remove(cid);

				// Layer counts
				if( layerIntGridUseCount.exists(iv) ) {
					layerIntGridUseCount.set(iv, layerIntGridUseCount.get(iv)-1);
					// Last one in layer
					if( layerIntGridUseCount.get(iv)<=0 )
						layerIntGridUseCount.remove(iv);
				}
			}
		}

		// Also update group
		if( iv<1000 ) {
			var groupUid = def.getIntGridGroupUidFromValue(iv);
			if( groupUid>=0 )
				decreaseAreaIntGridValueCount(def.getRuleValueFromGroupUid(groupUid), cx,cy);
		}
	}


	public inline function containsIntGridValueOrGroup(iv:Int) {
		return layerIntGridUseCount.exists(iv);
	}


	@:keep public function toString() {
		return 'LayerInst#$layerDefUid "${def.identifier}" [${def.type}]';
	}


	public function setOverrideTileset(?tilesetUid:Int) {
		overrideTilesetUid = tilesetUid==null ? null : tilesetUid;
	}

	public function getDefaultTilesetUid() : Null<Int> {
		return
			def.tilesetDefUid!=null ? def.tilesetDefUid
			: null;
	}

	public function getTilesetUid() : Null<Int> {
		return
			overrideTilesetUid!=null ? overrideTilesetUid
			: def.tilesetDefUid!=null ? def.tilesetDefUid
			: null;
	}


	public function isUsingTileset(td:data.def.TilesetDef) {
		if( getTilesetUid()==td.uid )
			return true;

		if( def.type==Entities )
			for( li in entityInstances )
				if( li.isUsingTileset(td) )
					return true;

		return false;
	}


	public function getTilesetDef() : Null<data.def.TilesetDef> {
		var tdUid = getTilesetUid();
		return tdUid==null ? null : _project.defs.getTilesetDef(tdUid);
	}

	public function toJson() : ldtk.Json.LayerInstanceJson {
		var td = getTilesetDef();

		var json : ldtk.Json.LayerInstanceJson = {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__type: Std.string(def.type),
			__cWid: cWid,
			__cHei: cHei,
			__gridSize: def.gridSize,
			__opacity: def.displayOpacity,
			__pxTotalOffsetX: pxOffsetX + def.pxOffsetX,
			__pxTotalOffsetY: pxOffsetY + def.pxOffsetY,
			__tilesetDefUid: td!=null ? td.uid : null,
			__tilesetRelPath: td!=null ? td.relPath : null,

			iid: iid,
			levelId: levelId,
			layerDefUid: layerDefUid,
			pxOffsetX: pxOffsetX,
			pxOffsetY: pxOffsetY,
			visible: visible,
			optionalRules: {
				var arr = [];
				for(k in optionalRules.keys())
					arr.push(k);
				arr;
			},

			intGridCsv: {
				var csv : Array<Int> = [];
				if( def.type==IntGrid )
					for(cy in 0...cHei)
					for(cx in 0...cWid)
						csv.push( getIntGrid(cx,cy) );
				csv;
			},

			autoLayerTiles: {
				var arr = [];

				if( autoTilesCache!=null ) {
					var td = getTilesetDef();
					def.iterateActiveRulesInDisplayOrder( this, (r)->{
						if( autoTilesCache.exists( r.uid ) ) {
							for( allTiles in autoTilesCache.get( r.uid ).keyValueIterator() )
							for( tileInfos in allTiles.value )
								arr.push({
									px: [ tileInfos.x, tileInfos.y ],
									src: [ tileInfos.srcX, tileInfos.srcY ],
									f: tileInfos.flips,
									t: tileInfos.tid,
									d: [r.uid,allTiles.key],
									a: r.alpha,
								});
							}
					});
				}
				arr;
			},

			seed: seed,

			overrideTilesetUid: overrideTilesetUid,
			gridTiles: {
				var arr : Array<ldtk.Json.Tile> = [];
				for( e in gridTiles.keyValueIterator() )
					for( tileInf in e.value ) {
						arr.push({
							px: [
								getCx(e.key) * def.gridSize,
								getCy(e.key) * def.gridSize,
							],
							src: [
								td==null ? -1 : td.getTileSourceX(tileInf.tileId),
								td==null ? -1 : td.getTileSourceY(tileInf.tileId),
							],
							f: tileInf.flips,
							t: tileInf.tileId,
							d: [ e.key ],
							a: 1,
						});
					}
				arr;
			},

			entityInstances: entityInstances.map( function(ei) return ei.toJson(this) ),
		}

		if( _project.hasFlag(ExportPreCsvIntGridFormat) )
			json.intGrid = {
				var arr = [];
				for(e in intGrid.keyValueIterator())
					arr.push({
						coordId: e.key,
						v: e.value-1,
					});
				arr;
			}

		return json;
	}

	public inline function getRuleStampRenderInfos(rule:data.def.AutoLayerRuleDef, td:data.def.TilesetDef, tileIds:Array<Int>, flipBits:Int)
	: Map<Int, { xOff:Int, yOff:Int }> {
		if( td==null )
			return null;

		// Get stamp bounds in tileset
		var top = 99999;
		var left = 99999;
		var right = 0;
		var bottom = 0;
		for(tid in tileIds) {
			top = dn.M.imin( top, td.getTileCy(tid) );
			bottom = dn.M.imax( bottom, td.getTileCy(tid) );
			left = dn.M.imin( left, td.getTileCx(tid) );
			right = dn.M.imax( right, td.getTileCx(tid) );
		}

		var out = new Map();
		for( tid in tileIds )
			out.set( tid, {
				xOff: Std.int( ( td.getTileCx(tid)-left - rule.pivotX*(right-left) + def.tilePivotX ) * def.gridSize ) * (dn.M.hasBit(flipBits,0)?-1:1),
				yOff: Std.int( ( td.getTileCy(tid)-top - rule.pivotY*(bottom-top) + def.tilePivotY ) * def.gridSize ) * (dn.M.hasBit(flipBits,1)?-1:1)
			});
		return out;
	}


	public function isEmpty() {
		switch def.type {
			case IntGrid:
				for(e in intGrid)
					return false;
				return true;

			case AutoLayer:
				for(rg in def.autoRuleGroups)
				for(r in rg.rules)
					return false;
				return false;

			case Entities:
				return entityInstances.length==0;

			case Tiles:
				for(e in gridTiles)
					return false;
				return true;
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.LayerInstanceJson) {
		if( (cast json).layerDefId!=null ) json.layerDefUid = (cast json).layerDefId;
		if( (cast json).iid==null )
			json.iid = p.generateUniqueId_UUID();

		var li = new data.inst.LayerInstance( p, JsonTools.readInt(json.levelId), JsonTools.readInt(json.layerDefUid), json.iid );
		li.seed = JsonTools.readInt(json.seed, Std.random(9999999));
		li.pxOffsetX = JsonTools.readInt(json.pxOffsetX, 0);
		li.pxOffsetY = JsonTools.readInt(json.pxOffsetY, 0);
		li.visible = JsonTools.readBool(json.visible, true);

		if( json.intGridCsv==null ) {
			// Read old pre-CSV format
			for( intGridJson in json.intGrid )
				li.intGrid.set( intGridJson.coordId, intGridJson.v+1 );
		}
		else {
			// Read CSV format
			for(coordId in 0...json.intGridCsv.length)
				if( json.intGridCsv[coordId]>=0 )
					li.intGrid.set(coordId, json.intGridCsv[coordId]);
		}
		li.recountAllIntGridValues();

		for( gridTilesJson in json.gridTiles ) {
			if( dn.Version.lower(p.jsonVersion, "0.4", true) || gridTilesJson.d==null )
				gridTilesJson.d = [ (cast gridTilesJson).coordId, (cast gridTilesJson).tileId ];

			if( dn.Version.lower(p.jsonVersion, "0.6", true) )
				gridTilesJson.t = gridTilesJson.d[1];

			var coordId = gridTilesJson.d[0];
			if( !li.gridTiles.exists(coordId) )
				li.gridTiles.set(coordId, []);

			li.gridTiles.get(coordId).push({
				tileId: gridTilesJson.t,
				flips: gridTilesJson.f,
			});
		}
		li.overrideTilesetUid = JsonTools.readNullableInt(json.overrideTilesetUid);

		// Optional rules
		if( json.optionalRules!=null )
			for(uid in json.optionalRules)
				li.optionalRules.set(uid, true);

		// Entities
		for( entityJson in json.entityInstances )
			li.entityInstances.push( EntityInstance.fromJson(p, li, entityJson) );

		// Auto-layer tiles
		if( json.autoLayerTiles!=null ) {
			try {
				var jsonAutoLayerTiles : Array<ldtk.Json.Tile> = JsonTools.readArray(json.autoLayerTiles);
				li.clearAllAutoTilesCache();

				for(at in jsonAutoLayerTiles) {
					var ruleId = at.d[0];
					var coordId = at.d[1];

					if( dn.Version.lower(p.jsonVersion, "0.6", true) )
						at.t = at.d[2];

					if( !li.autoTilesCache.exists(ruleId) )
						li.autoTilesCache.set(ruleId, new Map());

					if( !li.autoTilesCache.get(ruleId).exists(coordId) )
						li.autoTilesCache.get(ruleId).set(coordId, []);

					if( dn.Version.lower(p.jsonVersion, "0.5", true) && ( li.pxOffsetX!=0 || li.pxOffsetY!=0 ) ) {
						// Fix old coords that included offsets
						at.px[0]-=li.pxOffsetX;
						at.px[1]-=li.pxOffsetY;
					}

					li.autoTilesCache.get(ruleId).get(coordId).push({
						x: at.px[0],
						y: at.px[1],
						srcX: at.src[0],
						srcY: at.src[1],
						flips: at.f,
						tid: at.t,
						a: at.a==null ? 1 : at.a,
					});
				}
			}
			catch(e:Dynamic) {
				App.LOG.error('Failed to parse autoTilesCache in $li (err=$e)');
				li.autoTilesCache = null;
			}
		}

		return li;
	}

	inline function requireType(t:ldtk.Json.LayerType) {
		if( def.type!=t )
			throw 'Only works on $t layer!';
	}

	public inline function isValid(cx:Int,cy:Int) {
		return cx>=0 && cx<cWid && cy>=0 && cy<cHei;
	}

	public inline function coordId(cx:Int, cy:Int) {
		return cx + cy*cWid;
	}

	public inline function getCx(coordId:Int) {
		return coordId - Std.int(coordId/cWid)*cWid;
	}

	public inline function getCy(coordId:Int) {
		return Std.int(coordId/cWid);
	}

	public inline function levelToLayerCx(levelX:Float) {
		return Std.int( ( levelX - pxTotalOffsetX ) / def.gridSize ); // TODO not tested: check if this works with the new layerDef offsets
	}

	public inline function levelToLayerCy(levelY:Float) {
		return Std.int( ( levelY - pxTotalOffsetY ) / def.gridSize );
	}

	public function tidy(p:Project) : Bool {
		_project = p;
		_project.markIidAsUsed(iid);
		var anyChange = false;

		// Remove lost optional rule group UIDs
		var keep = false;
		for(optGroupUid in optionalRules.keys()) {
			var rg = def.getRuleGroup(optGroupUid);
			if( rg==null || !rg.isOptional ) {
				App.LOG.add("tidy", 'Removed lost optional rule group #$optGroupUid in $this');
				optionalRules.remove(optGroupUid);
				anyChange = true;
			}
		}


		switch def.type {
			case IntGrid, AutoLayer:
				// Remove lost intGrid values
				if( def.type==IntGrid )
					for(cy in 0...cHei)
					for(cx in 0...cWid)
						if( hasIntGrid(cx,cy) && !def.hasIntGridValue( getIntGrid(cx,cy) ) ) {
							removeIntGrid(cx,cy,false);
							if( def.isAutoLayer() )
								autoTilesCache = null;
							anyChange = true;
							// no logging as this could be a LOT of entries
						}

				if( def.isAutoLayer() && autoTilesCache!=null ) {
					// Discard lost rules autoTiles
					for( rUid in autoTilesCache.keys() )
						if( !def.hasRule(rUid) ) {
							App.LOG.add("tidy", 'Removed lost rule cache in $this');
							autoTilesCache.remove(rUid);
							anyChange = true;
						}

					if( !def.autoLayerRulesCanBeUsed() ) {
						App.LOG.add("tidy", 'Removed all autoTilesCache in $this (rules can no longer be applied)');
						clearAllAutoTilesCache();
						anyChange = true;
					}
				}


			case Entities:
				var i = 0;
				var ei = null;
				var level = this.level;
				while( i<entityInstances.length ) {
					ei = entityInstances[i];
					if( ei.def==null ) {
						// Remove lost entities (def removed)
						App.LOG.add("tidy", 'Removed lost entity in $this');
						entityInstances.splice(i,1);
						anyChange = true;
					}
					else
						i++;
				}

				// Cleanup field instances
				for(ei in entityInstances)
					if( ei.tidy(_project, this) )
						anyChange = true;

			case Tiles:
		}

		return anyChange;
	}


	@:allow(data.Level)
	private function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		var totalOffsetX = pxOffsetX - newPxLeft;
		var totalOffsetY = pxOffsetY - newPxTop;
		var newPxOffsetX = totalOffsetX % def.gridSize;
		var newPxOffsetY = totalOffsetY % def.gridSize;
		var newCWid = dn.M.ceil( (newPxWid-newPxOffsetX) / def.gridSize );
		var newCHei = dn.M.ceil( (newPxHei-newPxOffsetY) / def.gridSize );

		// Move data
		var cDeltaX = Std.int( totalOffsetX / def.gridSize);
		var cDeltaY = Std.int( totalOffsetY / def.gridSize);
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

			case AutoLayer:

			case Entities:
				var i = 0;
				while( i<entityInstances.length ) {
					var ei = entityInstances[i];
					ei.x += cDeltaX*def.gridSize;
					ei.y += cDeltaY*def.gridSize;

					// Move points
					for(fi in ei.fieldInstances)
						if( fi.def.type==F_Point )
							for(i in 0...fi.getArrayLength())  {
								var pt = fi.getPointGrid(i);
								if( pt==null )
									continue;

								pt.cx+=cDeltaX;
								pt.cy+=cDeltaY;
								fi.parseValue( i, pt.cx + Const.POINT_SEPARATOR + pt.cy );
							}

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
		pxOffsetX = newPxOffsetX;
		pxOffsetY = newPxOffsetY;
	}

	public inline function hasAnyGridValue(cx:Int, cy:Int) {
		return switch def.type {
			case IntGrid: hasIntGrid(cx,cy);
			case Tiles: hasAnyGridTile(cx,cy);
			case Entities: false;
			case AutoLayer: false;
		}
	}


	/** INT GRID *******************/

	public inline function getIntGrid(cx:Int, cy:Int) : Int {
		requireType(IntGrid);
		return !isValid(cx,cy) || !intGrid.exists( coordId(cx,cy) ) ? 0 : intGrid.get( coordId(cx,cy) );
	}

	public inline function getIntGridColorAt(cx:Int, cy:Int) : Null<UInt> {
		var v = def.getIntGridValueDef( getIntGrid(cx,cy) );
		return v==null ? null : v.color;
	}

	public inline function getIntGridIdentifierAt(cx:Int, cy:Int) : Null<String> {
		var v = def.getIntGridValueDef( getIntGrid(cx,cy) );
		return v==null ? null : v.identifier;
	}

	public function setIntGrid(cx:Int, cy:Int, v:Int, useAsyncRender:Bool) {
		requireType(IntGrid);
		if( isValid(cx,cy) ) {
			if( v>=0 ) {
				var old = intGrid.get(coordId(cx,cy));
				if( old!=v ) {
					decreaseAreaIntGridValueCount(old, cx,cy);
					increaseAreaIntGridValueCount(v, cx, cy);
					intGrid.set( coordId(cx,cy), v );
				}
				if( useAsyncRender )
					asyncPaint(cx,cy, def.getIntGridValueColor(v));
			}
			else
				removeIntGrid(cx,cy, useAsyncRender);
		}
	}

	public inline function hasIntGrid(cx:Int, cy:Int) {
		requireType(IntGrid);
		return getIntGrid(cx,cy)!=0;
	}

	public function removeIntGrid(cx:Int, cy:Int, useAsyncRender:Bool) {
		requireType(IntGrid);
		if( isValid(cx,cy) && hasIntGrid(cx,cy) ) {
			decreaseAreaIntGridValueCount( intGrid.get(coordId(cx,cy)), cx, cy );
			intGrid.remove( coordId(cx,cy) );
		}
		if( useAsyncRender )
			asyncErase(cx,cy);
	}


	/** ENTITY INSTANCE *******************/

	public function createEntityInstance(ed:data.def.EntityDef) : Null<EntityInstance> {
		requireType(Entities);

		var ei = new EntityInstance(_project, this, ed.uid, _project.generateUniqueId_UUID());
		entityInstances.push(ei);
		_project.registerEntityInstance(ei);
		return ei;
	}

	public function containsEntity(ei:EntityInstance) {
		for(e in entityInstances)
			if( e==ei )
				return true;
		return false;
	}

	public function duplicateEntityInstance(ei:EntityInstance) : EntityInstance {
		var copy = EntityInstance.fromJson( _project, this, ei.toJson(this) );
		copy.iid = _project.generateUniqueId_UUID();
		entityInstances.push(copy);
		_project.registerEntityInstance(copy);

		return copy;
	}

	public function removeEntityInstance(ei:EntityInstance) {
		requireType(Entities);
		if( !entityInstances.remove(ei) )
			throw "Unknown instance "+ei;

		_project.removeAnyFieldRefsTo(ei);
		_project.unregisterEntityIid(ei.iid);
		_project.unregisterAllReverseIidRefsFor(ei);
	}


	inline function asyncPaint(cx:Int, cy:Int, col:Col) {
		if( isValid(cx,cy) && Editor.exists() )
			Editor.ME.levelRender.asyncPaint(this, cx,cy, col);
	}

	inline function asyncErase(cx:Int, cy:Int) {
		if( isValid(cx,cy) && Editor.exists() )
			Editor.ME.levelRender.asyncErase(this, cx,cy);
	}


	/** TILES *******************/
	inline function getGridTileColor(tileId:Int) : dn.Col {
		var td = _project.defs.getTilesetDef( getTilesetUid() );
		return td!=null ? td.getAverageTileColor(tileId) : White;
	}

	public function addGridTile(cx:Int, cy:Int, tileId:Null<Int>, flips=0, stack:Bool, useAsyncRender=true) {
		if( !isValid(cx,cy) )
			return;

		if( tileId==null ) {
			removeAllGridTiles(cx,cy, useAsyncRender);
			return;
		}

		if( !gridTiles.exists(coordId(cx,cy)) || !stack )
			gridTiles.set( coordId(cx,cy), [{ tileId:tileId, flips:flips }]);
		else {
			removeSpecificGridTile(cx, cy, tileId, flips);
			gridTiles.get( coordId(cx,cy) ).push({ tileId:tileId, flips:flips });
		}

		if( useAsyncRender )
			asyncPaint(cx,cy, getGridTileColor(tileId));
	}


	public function removeAllGridTiles(cx:Int, cy:Int, useAsyncRender:Bool) {
		if( useAsyncRender )
			asyncErase(cx,cy);

		if( isValid(cx,cy) && hasAnyGridTile(cx,cy) ) {
			gridTiles.remove( coordId(cx,cy) );
			return true;
		}
		else
			return false;
	}


	public inline function removeSpecificGridTile(cx:Int, cy:Int, tileId:Int, flips:Int) {
		if( hasAnyGridTile(cx,cy) ) {
			var stack = gridTiles.get(coordId(cx,cy));
			for( i in 0...stack.length )
				if( stack[i].tileId==tileId && stack[i].flips==flips ) {
					stack.splice(i,1);
					break;
				}
		}
	}

	public inline function removeTopMostGridTile(cx:Int, cy:Int, useAsyncRender:Bool) {
		if( useAsyncRender )
			asyncErase(cx,cy);

		if( hasAnyGridTile(cx,cy) ) {
			gridTiles.get( coordId(cx,cy) ).pop();

			if( gridTiles.get( coordId(cx,cy) ).length==0 )
				gridTiles.remove( coordId(cx,cy) );

			return true;
		}
		else
			return false;
	}

	public inline function removeGridTileAtStackIndex(cx:Int, cy:Int, stackIdx:Int) {
		if( hasAnyGridTile(cx,cy) && getGridTileStack(cx,cy).length>stackIdx )
			gridTiles.get( coordId(cx,cy) ).splice( stackIdx, 1 );
	}

	public function getHighestGridTileStack(left:Int, top:Int, right:Int, bottom:Int) {
		var highest = 0;
		for(cx in left...right+1)
		for(cy in top...bottom+1)
			if( hasAnyGridTile(cx,cy) )
				highest = dn.M.imax( highest, getGridTileStack(cx,cy).length );
		return highest;
	}

	public inline function getGridTileStack(cx:Int, cy:Int) : Array<GridTileInfos> {
		return isValid(cx,cy) && gridTiles.exists( coordId(cx,cy) ) ? gridTiles.get( coordId(cx,cy) ) : [];
	}

	public inline function getTopMostGridTile(cx:Int, cy:Int) : Null<GridTileInfos> {
		return hasAnyGridTile(cx,cy) ? gridTiles.get(coordId(cx,cy))[ gridTiles.get(coordId(cx,cy)).length-1 ] : null;
	}


	public function remapToGridSize(oldGrid:Int, newGrid:Int) {
		var newCWid = M.ceil( pxWid/newGrid );
		var newCHei = M.ceil( pxHei/newGrid );
		inline function _newCoordId(cx,cy) {
			return cx+cy*newCWid;
		}

		switch def.type {
			case IntGrid:
				var newIntGrid = new Map();
				for(cy in 0...cHei)
				for(cx in 0...cWid)
					if( hasIntGrid(cx,cy) && cx<newCWid && cy<newCHei )
						newIntGrid.set( _newCoordId(cx,cy), getIntGrid(cx,cy));
				intGrid = newIntGrid;
				if( def.isAutoLayer() )
					autoTilesCache = null;

			case Entities:
				var ratio = newGrid/oldGrid;
				for(ei in entityInstances) {
					ei.x = M.floor( ratio * ei.x );
					ei.y = M.floor( ratio * ei.y );
					if( ei.customWidth!=null )
						ei.customWidth = M.floor( ratio * ei.customWidth );
					if( ei.customHeight!=null )
						ei.customHeight = M.floor( ratio * ei.customHeight );
				}

			case Tiles:
				var newGridTiles = new Map();
				for(cy in 0...cHei)
				for(cx in 0...cWid)
					if( hasAnyGridTile(cx,cy) && cx<newCWid && cy<newCHei ) {
						var stack = getGridTileStack(cx,cy).copy();
						newGridTiles.set( _newCoordId(cx,cy), stack );
					}
				gridTiles = newGridTiles;

			case AutoLayer:
				autoTilesCache = null;
		}
	}


	public function hasSpecificGridTile(cx:Int, cy:Int, tileId:Int, ?flips:Null<Int>) {
		if( !hasAnyGridTile(cx,cy) )
			return false;

		for( t in getGridTileStack(cx,cy) )
			if( t.tileId==tileId && ( flips==null || t.flips==flips ) )
				return true;

		return false;
	}

	public inline function hasAnyGridTile(cx:Int, cy:Int) : Bool {
		return isValid(cx,cy) && gridTiles.exists( coordId(cx,cy) ) && gridTiles.get(coordId(cx,cy)).length>0;
	}

	inline function isAutoTileCellAllowed(cx:Int, cy:Int) {
		if( def.autoTilesKilledByOtherLayerUid==null )
			return true;
		else
			return !level.getLayerInstance(def.autoTilesKilledByOtherLayerUid).hasAnyGridTile(cx,cy);
	}

	inline function addRuleTilesAt(r:data.def.AutoLayerRuleDef, cx:Int, cy:Int, flips:Int) {
		if( isAutoTileCellAllowed(cx,cy) ) {
			var tileRectIds = r.getRandomTileRectIdsForCoord(seed, cx,cy, flips);
			var td = getTilesetDef();
			var stampInfos = r.tileMode==Single ? null : getRuleStampRenderInfos(r, td, tileRectIds, flips);

			if( !autoTilesCache.get(r.uid).exists( coordId(cx,cy) ) )
				autoTilesCache.get(r.uid).set( coordId(cx,cy), [] );

			autoTilesCache.get(r.uid).set( coordId(cx,cy), autoTilesCache.get(r.uid).get( coordId(cx,cy) ).concat(
				tileRectIds.map( (tid)->{
					return {
						x: cx*def.gridSize + (stampInfos==null ? 0 : stampInfos.get(tid).xOff ) + r.getXOffsetForCoord(seed,cx,cy, flips),
						y: cy*def.gridSize + (stampInfos==null ? 0 : stampInfos.get(tid).yOff ) + r.getYOffsetForCoord(seed,cx,cy, flips),
						srcX: td.getTileSourceX(tid),
						srcY: td.getTileSourceY(tid),
						tid: tid,
						flips: flips,
						a: r.alpha,
					}
				} )
			));
		}
	}

	function clearAutoTilesCacheRect(r:data.def.AutoLayerRuleDef, cx,cy,wid,hei) {
		if( !autoTilesCache.exists(r.uid) )
			autoTilesCache.set( r.uid, [] );

		var m = autoTilesCache.get(r.uid);
		for(y in cy...cy+hei)
		for(x in cx...cx+wid)
			m.remove( coordId(x,y) );
	}

	function clearAutoTilesCacheByRule(r:data.def.AutoLayerRuleDef) {
		autoTilesCache.set( r.uid, [] );
	}

	function clearAllAutoTilesCache() {
		autoTilesCache = new Map();
	}

	/**
		Check & apply given rule at coord.
		WARNING: autoTiles clear method should always be called before that one!
	**/
	inline function applyRuleAt(sourceLi:LayerInstance, r:data.def.AutoLayerRuleDef, cx:Int, cy:Int) : Bool {
		// Skip rule that requires specific IntGrid values absent from layer
		if( !r.isRelevantInLayerAt(sourceLi,cx,cy) )
			return false;

		// Modulos
		if( r.checker!=Vertical && (cy-r.yOffset) % r.yModulo!=0 )
			return false;

		if( r.checker==Vertical && ( cy + ( Std.int(cx/r.xModulo)%2 ) )%r.yModulo!=0 )
			return false;

		if( r.checker!=Horizontal && (cx-r.xOffset) % r.xModulo!=0 )
			return false;

		if( r.checker==Horizontal && ( cx + ( Std.int(cy/r.yModulo)%2 ) )%r.xModulo!=0 )
			return false;

		// Apply rule
		var matched = false;
		if( r.matches(this, sourceLi, cx,cy) ) {
			addRuleTilesAt(r, cx,cy, 0);
			matched = true;
		}

		if( ( !matched || !r.breakOnMatch ) && r.flipX && r.matches(this, sourceLi, cx,cy, -1) ) {
			addRuleTilesAt(r, cx,cy, 1);
			matched = true;
		}

		if( ( !matched || !r.breakOnMatch ) && r.flipY && r.matches(this, sourceLi, cx,cy, 1, -1) ) {
			addRuleTilesAt(r, cx,cy, 2);
			matched = true;
		}

		if( ( !matched || !r.breakOnMatch ) && r.flipX && r.flipY && r.matches(this, sourceLi, cx,cy, -1, -1) ) {
			addRuleTilesAt(r, cx,cy, 3);
			matched = true;
		}

		return matched;
	}



	public function isRuleGroupAppliedHere(rg:data.def.AutoLayerRuleGroupDef) {
		if( rg.active && rg.requiredBiomeValues.length>0 ) {
			var fi = level.getFieldInstanceByUid(def.biomeFieldUid, false);
			if( fi!=null ) {
				switch rg.biomeRequirementMode {
					case 0: // OR
						for(idx in 0...fi.getArrayLength())
							for( bid in rg.requiredBiomeValues )
								if( fi.getEnumValue(idx)==bid )
									return true;
						return false;

					case 1: // AND
						var matches = 0;
						for( bid in rg.requiredBiomeValues ) {
							for( arrayIdx in 0...fi.getArrayLength() )
								if( fi.getEnumValue(arrayIdx)==bid ) {
									matches++;
									break;
								}
						}
						return matches>=rg.requiredBiomeValues.length;

					case _:
						return false;
				}
			}
		}

		return isRuleGroupEnabled(rg);
	}

	public inline function isRuleGroupEnabled(rg:data.def.AutoLayerRuleGroupDef) {
		return rg.active && !rg.isOptional || optionalRules.exists(rg.uid);
	}

	public function enableRuleGroupHere(rg:data.def.AutoLayerRuleGroupDef) {
		optionalRules.set(rg.uid, true);
	}
	public function disableRuleGroupHere(rg:data.def.AutoLayerRuleGroupDef) {
		optionalRules.remove(rg.uid);
	}
	public function toggleRuleGroupHere(rg:data.def.AutoLayerRuleGroupDef) {
		if( optionalRules.exists(rg.uid) )
			disableRuleGroupHere(rg);
		else
			enableRuleGroupHere(rg);
	}


	public inline function applyBreakOnMatchesEverywhere() {
		applyBreakOnMatchesArea(0,0,cWid,cHei);
	}

	public function applyBreakOnMatchesArea(cx:Int, cy:Int, wid:Int, hei:Int) {
		var left = M.imax(0,cx);
		var top = M.imax(0,cy);
		var right = M.imin(cWid-1, left + wid-1);
		var bottom = M.imin(cHei-1, top + hei-1);

		var coordLocks = new Map();

		var td = getTilesetDef();
		for( y in top...bottom+1 )
		for( x in left...right+1 ) {
			def.iterateActiveRulesInEvalOrder( this, (r)->{
				if( autoTilesCache.exists(r.uid) && autoTilesCache.get(r.uid).exists(coordId(x,y)) ) {
					if( coordLocks.exists( coordId(x,y) ) ) {
						// Tiles below locks are discarded
						autoTilesCache.get(r.uid).remove( coordId(x,y) );
					}
					else if( r.breakOnMatch ) {
						// Break on match is ON
						coordLocks.set( coordId(x,y), true ); // mark cell as locked
					}
					else if( !r.hasAnyPositionOffset() && r.alpha>=1 ) {
						// Check for opaque tiles
						for( t in autoTilesCache.get(r.uid).get( coordId(x,y) ) )
							if( td.isTileOpaque(t.tid) ) {
								coordLocks.set( coordId(x,y), true ); // mark cell as locked
								break;
							}
					}
				}

			});
		}
	}


	/** Apply all rules to specific cell **/
	public function applyAllRulesAt(cx:Int, cy:Int, wid:Int, hei:Int) {
		if( !def.autoLayerRulesCanBeUsed() ) {
			clearAllAutoTilesCache();
			return;
		}

		var source = def.type==IntGrid ? this : def.autoSourceLayerDefUid!=null ? level.getLayerInstance(def.autoSourceLayerDefUid) : null;
		if( source==null ) {
			clearAllAutoTilesCache();
			return;
		}

		if( autoTilesCache==null ) {
			applyAllRules();
			return;
		}

		// Adjust bounds to also redraw nearby cells
		var maxRadius = Std.int( Const.MAX_AUTO_PATTERN_SIZE*0.5 );
		var left = dn.M.imax( 0, cx - maxRadius );
		var right = dn.M.imin( cWid-1, cx + wid-1 + maxRadius );
		var top = dn.M.imax( 0, cy - maxRadius );
		var bottom = dn.M.imin( cHei-1, cy + hei-1 + maxRadius );

		// Apply rules
		def.iterateActiveRulesInEvalOrder( this, (r)->{
			clearAutoTilesCacheRect(r, left,top, right-left+1, bottom-top+1);
			for(x in left...right+1)
			for(y in top...bottom+1)
				applyRuleAt(source, r, x,y);
		});

		// Discard using break-on-match flag
		applyBreakOnMatchesArea(left,top, right-left+1, bottom-top+1);
	}

	/** Apply all rules to all cells **/
	public inline function applyAllRules() {
		if( def.isAutoLayer() ) {
			clearAllAutoTilesCache();
			applyAllRulesAt(0, 0, cWid, cHei);
			App.LOG.warning("All rules applied in "+toString());
		}
	}

	/** Apply the rule to all layer cells **/
	public function applyRuleToFullLayer(r:data.def.AutoLayerRuleDef, applyBreakOnMatch:Bool) {
		if( !def.isAutoLayer() )
			return;

		// Clear tiles if rule is disabled
		if( !r.active || !def.getParentRuleGroup(r).active ) {
			autoTilesCache.remove(r.uid);
			return;
		}

		var source = def.type==IntGrid ? this : def.autoSourceLayerDefUid!=null ? level.getLayerInstance(def.autoSourceLayerDefUid) : null;
		if( source==null || !r.isRelevantInLayer(source) )
			return;

		clearAutoTilesCacheByRule(r);

		if( def.autoLayerRulesCanBeUsed() ) {
			for( ay in 0...Std.int(cHei/intGridAreaSize)+1 )
			for( ax in 0...Std.int(cWid/intGridAreaSize)+1 ) {
				if( !r.isRelevantInLayerAt(source, ax*intGridAreaSize, ay*intGridAreaSize) )
					continue;

				for(cx in ax*intGridAreaSize...(ax+1)*intGridAreaSize)
				for(cy in ay*intGridAreaSize...(ay+1)*intGridAreaSize)
					if( isValid(cx,cy) )
						applyRuleAt(source, r, cx,cy);
			}

			if( applyBreakOnMatch )
				applyBreakOnMatchesEverywhere();
		}
	}

}