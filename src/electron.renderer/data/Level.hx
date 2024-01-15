package data;

class Level {
	var _project : Project;
	public var _world : World;

	var _cachedJson : Null<{ str:String, json:ldtk.Json.LevelJson }>;

	@:allow(data.Project, data.World)
	public var uid(default,null) : Int;
	public var iid : String;
	public var identifier(default,set): String;
	public var worldX : Int;
	public var worldY : Int;
	public var worldDepth : Int;
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Array<data.inst.LayerInstance> = [];
	public var fieldInstances : Map<Int, data.inst.FieldInstance> = new Map();

	public var externalRelPath: Null<String>;

	public var bgRelPath: Null<String>;
	public var bgPos: Null<ldtk.Json.BgImagePos>;
	public var bgPivotX: Float;
	public var bgPivotY: Float;
	public var useAutoIdentifier: Bool;

	@:allow(ui.LevelInstanceForm)
	@:allow(ui.modal.panel.LevelInstancePanel)
	var bgColor : Null<UInt>;

	public var worldCenterX(get,never) : Int;
		inline function get_worldCenterX() return dn.M.round( worldX + pxWid*0.5 );

	public var worldCenterY(get,never) : Int;
		inline function get_worldCenterY() return dn.M.round( worldY + pxHei*0.5 );


	@:allow(data.Project, data.World)
	private function new(project:Project, world:World, wid:Int, hei:Int, uid:Int, iid:String) {
		this.uid = uid;
		this.iid = iid;
		worldX = worldY = 0;
		worldDepth = 0;
		pxWid = wid;
		pxHei = hei;
		bgPivotX = 0.5;
		bgPivotY = 0.5;
		this._project = project;
		this._world = world;
		this.identifier = "Level"+uid;
		this.bgColor = null;
		useAutoIdentifier = true;

		for(ld in _project.defs.layers)
			createLayerInstance(ld);
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id, _project.identifierStyle) : identifier;
	}

	@:keep public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '#$iid "$identifier"';
	}


	/**
		List nearby level (only IIDs)
	**/
	public function getNeighboursIids() : Array<String> {
		return getNeighboursJson().map( njson->njson.levelIid );
	}

	/**
		List nearby level
	**/
	public function getNeighbours() : Array<Level> {
		return getNeighboursJson().map( njson->_project.getLevelAnywhere(njson.levelIid) );
	}


	/**
		List nearby levels as JSON
	**/
	public function getNeighboursJson() : Array<ldtk.Json.NeighbourLevel> {
		var neighbours : Array<ldtk.Json.NeighbourLevel> = [];

		// Overlaps in world layers
		neighbours = neighbours.concat( switch _world.worldLayout {
			case Free, GridVania:
				var nears = _world.levels.filter( (ol)->
					ol!=this
					&& M.iabs(worldDepth-ol.worldDepth)<=1
					&& dn.Lib.rectangleOverlaps(worldX,worldY,pxWid,pxHei, ol.worldX,ol.worldY,ol.pxWid,ol.pxHei)
				);
				nears.map( (l)->{
					var dir = l.worldDepth==worldDepth ? "o" : l.worldDepth>worldDepth? ">" : "<";
					var nl : ldtk.Json.NeighbourLevel = {
						levelIid: l.iid,
						dir: dir,
					}
					return nl;
				});

			case LinearHorizontal, LinearVertical:
				[];
		} );

		// Touching neighbours
		neighbours = neighbours.concat( switch _world.worldLayout {
			case Free, GridVania:
				var nears = _world.levels.filter( (ol)->
					ol!=this && getBoundsDist(ol)==0
					&& ol.worldDepth==worldDepth
					// && !( ( ol.worldX>=worldX+pxWid || ol.worldX+ol.pxWid<=worldX )
						// && ( ol.worldY>=worldY+pxHei || ol.worldY+ol.pxHei<=worldY ) )
					&& !dn.Lib.rectangleOverlaps(worldX,worldY,pxWid,pxHei, ol.worldX,ol.worldY,ol.pxWid,ol.pxHei)
				);
				nears.map( (l)->{
					var dir =
						l.worldX == worldX+pxWid  &&  l.worldY == worldY+pxHei ? "se"
						: l.worldX+l.pxWid == worldX  &&  l.worldY == worldY+pxHei ? "sw"
						: l.worldX == worldX+pxWid  &&  l.worldY+l.pxHei == worldY ? "ne"
						: l.worldX+l.pxWid == worldX  &&  l.worldY+l.pxHei == worldY ? "nw"
						: l.worldX>=worldX+pxWid ? "e"
						: l.worldX+l.pxWid<=worldX ? "w"
						: l.worldY+l.pxHei<=worldY ? "n"
						: "s";
					var nl : ldtk.Json.NeighbourLevel = {
						levelIid: l.iid,
						dir: dir,
					}
					return nl;
				});

			case LinearHorizontal, LinearVertical:
				[];
		});

		return neighbours;
	}



	public function toJson(ignoreCache=false) : ldtk.Json.LevelJson {
		if( !ignoreCache && hasJsonCache() ) {
			var o = getCacheJsonObject();
			if( !_project.externalLevels )
				Reflect.deleteField(o, dn.data.JsonPretty.HEADER_VALUE_NAME);
			return o;
		}

		// World coords are not stored in JSON for automatically organized layouts
		var jsonWorldX = worldX;
		var jsonWorldY = worldY;
		switch _world.worldLayout {
			case Free:
			case GridVania:
			case LinearHorizontal, LinearVertical:
				jsonWorldX = jsonWorldY = -1;
		}

		// Json
		var json : ldtk.Json.LevelJson = {
			identifier: identifier,
			iid: iid,
			uid: uid,
			worldX: jsonWorldX,
			worldY: jsonWorldY,
			worldDepth: worldDepth,
			pxWid: pxWid,
			pxHei: pxHei,
			__bgColor: JsonTools.writeColor( getBgColor() ),
			bgColor: JsonTools.writeColor(bgColor, true),
			useAutoIdentifier: useAutoIdentifier,

			bgRelPath: bgRelPath,
			bgPos: JsonTools.writeEnum(bgPos, true),
			bgPivotX: JsonTools.writeFloat(bgPivotX),
			bgPivotY: JsonTools.writeFloat(bgPivotY),

			__smartColor: JsonTools.writeColor( getSmartColor(true) ),

			__bgPos: {
				var bg = getBgTileInfos();
				if( bg==null )
					null;
				else {
					topLeftPx: [ bg.dispX, bg.dispY ],
					scale: [ bg.sx, bg.sy ],
					cropRect: [
						bg.tx, bg.ty,
						bg.tw, bg.th,
					],
				}
			},

			externalRelPath: null, // is only set upon actual saving, if project uses externalLevels option
			fieldInstances: {
				var all = [];
				for(fd in _project.defs.levelFields)
					all.push( getFieldInstance(fd,true).toJson() );
				all;
			},
			layerInstances: layerInstances.map( li->li.toJson() ),
			__neighbours: ignoreCache ? [] : getNeighboursJson(),
		}

		// Cache this json
		if( !ignoreCache )
			setJsonCache(json, false);

		return json;
	}


	public function toSimplifiedJson() {
		var json = toJson(false);

		var simpleJson = {
			identifier : json.identifier,
			uniqueIdentifer: json.iid,

			x : json.worldX,
			y : json.worldY,
			width : json.pxWid,
			height : json.pxHei,
			bgColor: json.__bgColor,
			neighbourLevels: json.__neighbours,

			customFields: {},

			layers : {
				var out = [];
				iterateLayerInstancesBottomToTop( (li)->{
					var show = switch li.def.type {
						case IntGrid: li.def.isAutoLayer();
						case Entities: false;
						case Tiles: true;
						case AutoLayer: true;
					}
					if( show )
						out.push( li.def.identifier+".png" );
				});
				out;
			},

			entities : {},
		}

		// Level custom fields
		for( fi in fieldInstances )
			Reflect.setField(simpleJson.customFields, fi.def.identifier, fi.toJson().__value);

		// Group entities by identifier
		var ents = new Map();
		for(li in layerInstances) {
			if( li.def.type!=Entities )
				continue;

			for( ei in li.entityInstances ) {
				if( !ents.exists(ei.def.identifier) )
					ents.set(ei.def.identifier, []);
				ents.get(ei.def.identifier).push( ei.toSimplifiedJson() );
			}
		}

		// Add entities to JSON
		for(g in ents.keyValueIterator())
			Reflect.setField(simpleJson.entities, g.key, g.value);

		return simpleJson;
	}

	public function makeExternalRelPath(idx:Int) {
		return
			_project.getRelExternalFilesDir() + "/"
			+ ( _project.hasFlag(PrependIndexToLevelFileNames) ? dn.Lib.leadingZeros(idx,Const.LEVEL_FILE_LEADER_ZEROS)+"-" : "")
			+ identifier
			+ "." + Const.LEVEL_EXTENSION;
	}

	public static function fromJson(p:Project, w:World, json:ldtk.Json.LevelJson, registerToQuickAccess:Bool) {
		if( json.iid==null )
			json.iid = p.generateUniqueId_UUID();

		var wid = JsonTools.readInt( json.pxWid, w.defaultLevelWidth );
		var hei = JsonTools.readInt( json.pxHei, w.defaultLevelHeight );
		var l = new Level( p, w, wid, hei, JsonTools.readInt(json.uid), json.iid );
		if( registerToQuickAccess )
			p.registerLevelQuickAccess(l);
		l.worldX = JsonTools.readInt( json.worldX, 0 );
		l.worldY = JsonTools.readInt( json.worldY, 0 );
		l.worldDepth = JsonTools.readInt( json.worldDepth, 0 );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);
		l.bgColor = JsonTools.readColor(json.bgColor, true);
		l.externalRelPath = json.externalRelPath;
		l.useAutoIdentifier = JsonTools.readBool(json.useAutoIdentifier, false); // older projects should keep their original IDs untouched

		l.bgRelPath = json.bgRelPath;
		l.bgPos = JsonTools.readEnum(ldtk.Json.BgImagePos, json.bgPos, true);
		l.bgPivotX = JsonTools.readFloat(json.bgPivotX, 0.5);
		l.bgPivotY = JsonTools.readFloat(json.bgPivotY, 0.5);

		l.layerInstances = [];
		if( json.layerInstances!=null ) // external levels
			for( layerJson in JsonTools.readArray(json.layerInstances) ) {
				var li = data.inst.LayerInstance.fromJson(p, layerJson);
				l.layerInstances.push(li);
			}

		if( json.fieldInstances!=null )
			for( fieldJson in JsonTools.readArray(json.fieldInstances)) {
				var fi = data.inst.FieldInstance.fromJson(p,fieldJson);
				l.fieldInstances.set(fi.defUid, fi);
			}

		// Init cache
		crawlObjectRec(json); // Because haxe.Json.parse unescapes "\n" chars, we need to re-escape them before caching the JSON object
		l.setJsonCache(json, true);

		return l;
	}

	/** Crawl an Object recursively and fixes unescaped \n chars **/
	static function crawlObjectRec(obj:{}) {
		for( k in Reflect.fields(obj) ) {
			var v : Dynamic = Reflect.field(obj, k);
			switch Type.typeof(v) {
				case TObject:
					crawlObjectRec(v);

				case TClass(Array):
					crawlArray(v);

				case TClass(String):
					if( v.indexOf("\n")>=0 )
						Reflect.setField(obj, k, StringTools.replace(v, "\n", "\\n"));

				case _:
			}
		}
	}

	/** Crawl an Array recursively and fixes unescaped \n chars **/
	static function crawlArray(arr:Array<Dynamic>) {
		for( i in 0...arr.length ) {
			var v : Dynamic = arr[i];
			switch Type.typeof(v) {
				case TObject:
					crawlObjectRec(v);

				case TClass(Array):
					crawlArray(v);

				case TClass(String):
					if( v.indexOf("\n")>=0 )
						arr[i] = StringTools.replace(v, "\n", "\\n");

				case _:
			}
		}
	}



	public inline function hasBgImage() {
		return bgRelPath!=null;
	}


	public inline function hasJsonCache() return _cachedJson!=null;
	public inline function invalidateJsonCache() _cachedJson = null;
	public function rebuildCache() {
		_cachedJson = null;
		toJson();
	}

	function setJsonCache(json:ldtk.Json.LevelJson, skipHeader:Bool) {
		_cachedJson = {
			str: ui.ProjectSaver.jsonStringify(_project, json, skipHeader ),
			json: json,
		}
	}

	public inline function getCacheJsonObject() : Null<ldtk.Json.LevelJson> {
		return hasJsonCache() ? _cachedJson.json : null;
	}

	public inline function getDisplayIdentifier() {
		return identifier + ( hasJsonCache() ? "" : "*" );
	}

	public function getCacheJsonString() : Null<String> {
		return hasJsonCache() ? _cachedJson.str : null;
	}

	public function getBgTileInfos() : Null<{ imgData:data.DataTypes.CachedImage, tx:Float, ty:Float, tw:Float, th:Float, dispX:Int, dispY:Int, sx:Float, sy:Float }> {
		if( !hasBgImage() )
			return null;

		var data = _project.getOrLoadImage(bgRelPath);
		if( data==null )
			return null;

		var baseTileWid = data.pixels.width;
		var baseTileHei = data.pixels.height;
		var sx = 1.0;
		var sy = 1.0;
		switch bgPos {
			case null:
				throw "bgPos should not be null";

			case Unscaled:

			case Contain:
				sx = sy = M.fmin( pxWid/baseTileWid, pxHei/baseTileHei );

			case Cover:
				sx = sy = M.fmax( pxWid/baseTileWid, pxHei/baseTileHei );

			case CoverDirty:
				sx = pxWid / baseTileWid;
				sy = pxHei/ baseTileHei;

			case Repeat:
				// Do nothing, tiling shenanigans are handled in createBgTiledTexture.
		}

		// Crop tile
		var subTileWid = M.fmin(baseTileWid, pxWid/sx);
		var subTileHei = M.fmin(baseTileHei, pxHei/sy);

		return {
			imgData: data,
			tx: bgPivotX * (baseTileWid-subTileWid),
			ty: bgPivotY * (baseTileHei-subTileHei),
			tw: subTileWid,
			th: subTileHei,
			dispX: Std.int( bgPivotX * (pxWid - subTileWid*sx) ),
			dispY: Std.int( bgPivotY * (pxHei - subTileHei*sy) ),
			sx: sx,
			sy: sy,
		}
	}

	public function createBgTiledTexture(?p:h2d.Object) : Null<dn.heaps.TiledTexture> {
		var bgInf = getBgTileInfos();
		if( bgInf==null )
			return null;

		var t = h2d.Tile.fromTexture( bgInf.imgData.tex );
		t = t.sub(bgInf.tx, bgInf.ty, bgInf.tw, bgInf.th);

		var tile = (bgPos == ldtk.Json.BgImagePos.Repeat);

		var w = tile ? pxWid : Std.int(bgInf.tw);
		var h = tile ? pxHei : Std.int(bgInf.th);

		var tt = new dn.heaps.TiledTexture(w, h, t, p);
		tt.scaleX = bgInf.sx;
		tt.scaleY = bgInf.sy;
		if( tile ) {
			tt.alignPivotX = bgPivotX;
			tt.alignPivotY = bgPivotY;
		}
		else {
			tt.x = bgInf.dispX;
			tt.y = bgInf.dispY;
		}

		return tt;
	}


	public inline function isUsingDefaultBgColor() {
		return bgColor==null;
	}

	public inline function getBgColor() : UInt {
		return bgColor!=null ? bgColor : _project.defaultLevelBgColor;
	}

	public inline function inBounds(levelX:Int, levelY:Int) {
		return levelX>=0 && levelX<pxWid && levelY>=0 && levelY<pxHei;
	}

	public inline function inBoundsWorld(worldX:Float, worldY:Float, padPx=0) {
		return worldX >= this.worldX-padPx
			&& worldX < this.worldX+pxWid+padPx
			&& worldY >= this.worldY-padPx
			&& worldY < this.worldY+pxHei+padPx;
	}

	public inline function otherLevelCoordInBounds(otherLevel:Level, levelX:Int, levelY:Int, padPx=0) {
		return inBoundsWorld(otherLevel.worldX+levelX, otherLevel.worldY+levelY, padPx);
	}

	public function isWorldOver(wx:Int, wy:Int, padding=0) {
		return
			wx>=worldX-padding && wx<worldX+pxWid+padding
			&& wy>=worldY-padding && wy<worldY+pxHei+padding;
	}

	public function getDist(wx:Int, wy:Int) : Float {
		if( isWorldOver(wx,wy) )
			return 0;
		else {
			if( wy>=worldY && wy<worldY+pxHei ) // Distance to left or right sides
				return M.imin( M.iabs(worldX-wx), M.iabs(wx-(worldX+pxWid)) );
			else if( wx>=worldX && wx<worldX+pxWid ) // Distance to top or bottom sides
				return M.imin( M.iabs(worldY-wy), M.iabs(wy-(worldY+pxHei)) );
			else // Distances to corners
				return M.fmin(
					M.fmin( M.dist(wx,wy,worldX,worldY), M.dist(wx,wy,worldX+pxWid-1,worldY) ),
					M.fmin( M.dist(wx,wy,worldX,worldY+pxHei-1), M.dist(wx,wy,worldX+pxWid-1,worldY+pxHei-1) )
				);
		}
	}

	public function getBoundsDist(l:Level) : Int {
		return dn.M.imax(
			dn.M.imax(0, worldX - (l.worldX+l.pxWid)) + dn.M.imax( 0, l.worldX - (worldX+pxWid) ),
			dn.M.imax(0, worldY - (l.worldY+l.pxHei)) + dn.M.imax( 0, l.worldY - (worldY+pxHei) )
		);
	}

	public inline function touches(l:Level) {
		return l!=null
			&& l!=this
			&& dn.Lib.rectangleTouches(worldX, worldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei);
	}

	public inline function overlaps(l:Level) {
		return l!=null
			&& l!=this
			&& dn.Lib.rectangleOverlaps(worldX, worldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei);
	}

	public function overlapsAnyLevel() {
		for(l in _world.levels)
			if( overlaps(l) )
				return true;

		return false;
	}

	public function willOverlapAnyLevel(newWorldX:Int, newWorldY:Int) {
		for(l in _world.levels)
			if( l!=this && dn.Lib.rectangleOverlaps(newWorldX, newWorldY, pxWid, pxHei, l.worldX, l.worldY, l.pxWid, l.pxHei) )
				return true;

		return false;
	}

	public function getLayerInstance(?layerDefUid:Int, ?layerDef:data.def.LayerDef) : data.inst.LayerInstance {
		if( layerDefUid==null && layerDef==null )
			throw "Need 1 parameter";

		if( layerDefUid==null )
			layerDefUid = layerDef.uid;

		for(li in layerInstances)
			if( li.layerDefUid==layerDefUid )
				return li;

		throw "Missing layer instance for "+layerDefUid;
	}

	public function getLayerInstanceFromRule(r:data.def.AutoLayerRuleDef) {
		var ld = _project.defs.getLayerDefFromRule(r);
		return ld!=null ? getLayerInstance(ld) : null;
	}


	function createLayerInstance(ld:data.def.LayerDef) : data.inst.LayerInstance {
		var li = new data.inst.LayerInstance(_project, this.uid, ld.uid, _project.generateUniqueId_UUID());
		layerInstances.push(li);
		return li;
	}



	/**
		Return TRUE if this level is part of given World
	**/
	public inline function isInWorld(w:World) {
		return w!=null && _world.iid==w.iid;
	}

	/**
		Move this level to target World
	**/
	public function moveToWorld(target:World) {
		if( _world.iid==target.iid )
			return false;

		var from = _world;
		if( !from.levels.remove(this) )
			return false;

		target.levels.push(this);
		_world = target;
		from.reorganizeWorld();
		target.reorganizeWorld();
		return true;
	}


	public function tidy(p:Project, w:World) {
		_project = p;
		_project.markIidAsUsed(iid);
		_world = w;

		// Remove layerInstances without layerDefs
		var i = 0;
		while( i<layerInstances.length )
			if( layerInstances[i].def==null ) {
				App.LOG.add("tidy", 'Removed lost layer instance in $this');
				layerInstances.splice(i,1);
				invalidateJsonCache();
			}
			else
				i++;

		// Create missing layerInstances & check if they're sorted in the same order as defs
		for(i in 0..._project.defs.layers.length)
			if( i>=layerInstances.length || layerInstances[i].layerDefUid!=_project.defs.layers[i].uid ) {
				App.LOG.add("tidy", 'Fixed layer instance array in $this (order mismatch or missing layer instance)');
				var existing = new Map();
				for(li in layerInstances)
					existing.set(li.layerDefUid, li);
				layerInstances = [];
				for(ld in _project.defs.layers)
					if( existing.exists(ld.uid) )
						layerInstances.push( existing.get(ld.uid) );
					else {
						App.LOG.add("tidy", 'Added missing layer instance ${ld.identifier} in $this');
						createLayerInstance(ld);
					}
				invalidateJsonCache();
				break;
			}

		// Tidy layer instances
		for(li in layerInstances)
			if( li.tidy(_project) )
				invalidateJsonCache();


		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null ) {
				App.LOG.add("tidy", 'Removed lost fieldInstance in $this');
				fieldInstances.remove(e.key);
				invalidateJsonCache();
			}

		// Create missing field instances
		for(fd in p.defs.levelFields)
			getFieldInstance(fd,true);

		for(fi in fieldInstances)
			if( fi.tidy(_project) )
				invalidateJsonCache();
	}


	public function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		for(li in layerInstances)
			li.applyNewBounds(newPxLeft, newPxTop, newPxWid, newPxHei);
		pxWid = newPxWid;
		pxHei = newPxHei;
		for(li in layerInstances)
			li.recountAllIntGridValues();

		// Remove entities out of bounds
		var n = 0;
		for(li in layerInstances) {
			var i = 0;
			var ei = null;
			while( i<li.entityInstances.length ) {
				ei = li.entityInstances[i];
				if( !ei.def.allowOutOfBounds && !inBounds(ei.x, ei.y) ) {
					App.LOG.general('Removed out-of-bounds entity ${ei.def.identifier} in $li');
					li.entityInstances.splice(i,1);
					n++;
				}
				else
					i++;
			}
		}
		if( n>0 )
			N.warning( L.t._("::n:: entity(ies) deleted during resizing!", { n:n }) );

		_project.tidy();
	}


	public inline function invalidateCachedError() {
		_cachedFirstError = null;
	}

	var _cachedFirstError : Null<LevelError> = null;
	public inline function getFirstError() : LevelError {
		if( _cachedFirstError!=null )
			return _cachedFirstError;
		else {
			_cachedFirstError = NoError;

			// Layers content
			for(li in layerInstances)
				for(ei in li.entityInstances) {
					if( !li.def.isEntityAllowedFromTags(ei) ) {
						_cachedFirstError = InvalidEntityTag(ei);
						break;
					}

					if( ei.hasAnyFieldError() ) {
						_cachedFirstError = InvalidEntityField(ei);
						break;
					}
				}

			// Level background images
			if( _cachedFirstError==NoError && bgRelPath!=null && !_project.isImageLoaded(bgRelPath) )
				_cachedFirstError = InvalidBgImage;

			return _cachedFirstError;
		}
	}



	/* CUSTOM FIELDS *******************/

	/**
		Get a field instance (or optionnaly, creates it)
	**/
	public function getFieldInstance(fd:data.def.FieldDef, createIfMissing:Bool) : Null<data.inst.FieldInstance> {
		if( createIfMissing && !fieldInstances.exists(fd.uid) ) {
			fieldInstances.set( fd.uid, new data.inst.FieldInstance(_project, fd.uid) );
			invalidateJsonCache();
		}
		return fieldInstances.get(fd.uid);
	}

	public function getFieldInstanceByUid(fdUid:Int, createIfMissing:Bool) : Null<data.inst.FieldInstance> {
		if( createIfMissing && !fieldInstances.exists(fdUid) ) {
			fieldInstances.set( fdUid, new data.inst.FieldInstance(_project, fdUid) );
			invalidateJsonCache();
		}
		return fieldInstances.get(fdUid);
	}


	public function getSmartColor(bright:Bool) : dn.Col {
		inline function _adjust(c:Int) {
			return bright ? dn.legacy.Color.toWhite(c, 0.45) : c;
		}

		var c : Null<Int> = null;
		for(fd in _project.defs.levelFields) {
			var fi = getFieldInstance(fd,false);
			if( fi==null )
				continue;
			c = fi.getSmartColor();
			if( c!=null )
				return _adjust(c);
		}

		return _adjust( getBgColor() );
	}


	public function getWorldTileFromFields() : Null<h2d.Tile> {
		for(fd in _project.defs.levelFields) {
			if( fd.editorDisplayMode!=LevelTile )
				continue;

			var fi = getFieldInstance(fd,false);
			if( fi==null )
				continue;

			var r = fi.getSmartTile(true);
			if( r!=null )
				return _project.defs.getTilesetDef(r.tilesetUid).getTileRect(r);
		}

		return null;
	}

	public function hasAnyFieldDisplayedAt(pos:ldtk.Json.FieldDisplayPosition) {
		for(fi in fieldInstances)
			if( fi.def.editorAlwaysShow || !fi.isUsingDefault(0) ) {
				switch fi.def.editorDisplayMode {
					case ValueOnly, NameAndValue, ArrayCountNoLabel, ArrayCountWithLabel:
						if( fi.def.editorDisplayPos==pos )
							return true;

					case Hidden:
					case EntityTile:
					case LevelTile:
					case Points:
					case PointStar:
					case PointPath, PointPathLoop:
					case RadiusPx:
					case RadiusGrid:
					case RefLinkBetweenCenters:
					case RefLinkBetweenPivots:
				}
			}
		return false;
	}


	/* RENDERING *******************/

	public function iterateLayerInstancesBottomToTop( eachLayer:data.inst.LayerInstance->Void ) {
		var i = _project.defs.layers.length-1;
		while( i>=0 ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i--;
		}
	}

	public function iterateLayerInstancesTopToBottom( eachLayer:data.inst.LayerInstance->Void ) {
		var i = 0;
		while( i<_project.defs.layers.length ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i++;
		}
	}
}
