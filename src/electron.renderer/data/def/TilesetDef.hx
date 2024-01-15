package data.def;

import data.DataTypes;

class TilesetDef {
	var _project : Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var relPath(default,null) : Null<String>;
	public var embedAtlas : Null<ldtk.Json.EmbedAtlas>;
	public var tileGridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var padding : Int = 0; // px dist to atlas borders
	public var spacing : Int = 0; // px space between consecutive tiles
	public var savedSelections : Array<TilesetSelection> = [];
	var customData : Map<Int, String> = new Map();

	public var tagsSourceEnumUid : Null<Int>;
	/** Map< EnumValueId, Map< TileId, Bool > > **/
	public var enumTags: Map< String, Map<Int,Bool> > = new Map();

	var opaqueTiles : Null< haxe.ds.Vector<Bool> >;
	var averageColorsCache : Null< Map<Int,Int> >; // ARGB Int

	public var pxWid = 0;
	public var pxHei = 0;

	public var cWid(get,never) : Int;
	inline function get_cWid() return !hasAtlasPointer() ? 0 : dn.M.ceil( (pxWid-padding*2) / (tileGridSize+spacing) );

	public var cHei(get,never) : Int;
	inline function get_cHei() return !hasAtlasPointer() ? 0 : dn.M.ceil( (pxHei-padding*2) / (tileGridSize+spacing) );

	public var tags : Tags;

	var cachedTiles : Map<Int,h2d.Tile> = new Map();


	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier = "Tileset"+uid;
		tags = new Tags();
	}

	public function toString() {
		return 'TilesetDef.$identifier($relPath)';
	}

	/** TRUE if this tileset has a pointer to an atlas image **/
	public inline function hasAtlasPointer() return relPath!=null || embedAtlas!=null;

	public inline function isAtlasLoaded() {
		if( !hasAtlasPointer() )
			return false;
		else
			return embedAtlas!=null ? _project.isEmbedImageLoaded(embedAtlas) : _project.isImageLoaded(relPath);
	}

	public inline function isUsingEmbedAtlas() return embedAtlas!=null;

	function getOrLoadTilesetImage() {
		if( !hasAtlasPointer() )
			return null;
		else
			return embedAtlas!=null ? _project.getOrLoadEmbedImage(embedAtlas) : _project.getOrLoadImage(relPath);
	}

	function getOrLoadTilesetImageSub(x:Int, y:Int, w:Int, h:Int) {
		if( !hasAtlasPointer() )
			return null;
		else if( embedAtlas!=null )
			return _project.getOrLoadEmbedImageSub(embedAtlas, x,y,w,h);
		else
			return _project.getOrLoadImageSub(relPath, x,y,w,h);
	}

	@:allow(data.Project)
	function unsafeRelPathChange(newRelPath:Null<String>) { // should ONLY be used in specific circonstances
		relPath = newRelPath;
	}

	public function getMaxTileGridSize() {
		return hasAtlasPointer() ? dn.M.imin(pxWid, pxHei) : 100;
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id, _project.identifierStyle) : identifier;
	}

	public function getFileName(withExt:Bool) : Null<String> {
		if( !hasAtlasPointer() )
			return null;

		return withExt ? dn.FilePath.extractFileWithExt(relPath) : dn.FilePath.extractFileName(relPath);
	}

	public function removeAtlasImage(keepPath=false) {
		if( embedAtlas!=null ) // not allowed
			return;

		if( !keepPath )
			relPath = null;
		pxWid = pxHei = 0;
		clearTileCache();
		savedSelections = [];
	}

	public function toJson() : ldtk.Json.TilesetDefJson {
		return {
			__cWid: cWid,
			__cHei: cHei,
			identifier: identifier,
			uid: uid,
			relPath: JsonTools.writePath(relPath),
			embedAtlas: JsonTools.writeEnum(embedAtlas, true),
			pxWid: pxWid,
			pxHei: pxHei,
			tileGridSize: tileGridSize,
			spacing: spacing,
			padding: padding,
			tags: tags.toJson(),

			tagsSourceEnumUid: tagsSourceEnumUid,
			enumTags: {
				if( tagsSourceEnumUid==null )
					[];
				else {
					var tags = [];
					for(ev in getTagsEnumDef().values) {
						var tileIds = [];
						if( enumTags.exists(ev.id) )
							for(tid in enumTags.get(ev.id).keys())
								tileIds.push(tid);

						tags.push({
							enumValueId: ev.id,
							tileIds: tileIds,
						});
					}
					tags;
				}
			},

			customData: {
				var all = [];
				for(d in customData.keyValueIterator())
					all.push({ tileId:d.key, data:JsonTools.escapeString(d.value) });
				all;
			},

			savedSelections: savedSelections.map( function(sel) {
				return { ids:sel.ids, mode:JsonTools.writeEnum(sel.mode, false) }
			}),

			cachedPixelData: !hasValidPixelData() ? null : {
				opaqueTiles: {
					var buf = new StringBuf();
					var zero = "0".charCodeAt(0);
					for(v in opaqueTiles)
						buf.addChar( v==true ? zero+1 : zero );
					buf.toString();
				},

				averageColors: {
					var buf = new StringBuf();
					for(tid in 0...cWid*cHei)
						buf.add( dn.legacy.Color.intToHex3_ARGB( averageColorsCache.get(tid) ) );
					buf.toString();
				},
			},
		}
	}


	public static function fromJson(p:Project, json:ldtk.Json.TilesetDefJson) {
		if( (cast json).path!=null ) json.relPath = (cast json).path;

		var td = new TilesetDef( p, JsonTools.readInt(json.uid) );
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Project.DEFAULT_GRID_SIZE);
		td.spacing = JsonTools.readInt(json.spacing, 0);
		td.padding = JsonTools.readInt(json.padding, 0);
		td.pxWid = JsonTools.readInt( json.pxWid );
		td.pxHei = JsonTools.readInt( json.pxHei );
		td.relPath = json.relPath;
		td.embedAtlas = JsonTools.readEnum(ldtk.Json.EmbedAtlas, json.embedAtlas, true);
		td.identifier = JsonTools.readString(json.identifier, "Tileset"+td.uid);
		td.tags = Tags.fromJson(json.tags);

		// Enum tags
		if( (cast json).metaDataEnumUid!=null ) json.tagsSourceEnumUid = (cast json).metaDataEnumUid;
		td.tagsSourceEnumUid = JsonTools.readNullableInt(json.tagsSourceEnumUid);
		if( (cast json).metaDataEnumValues!=null ) json.enumTags = (cast json).metaDataEnumValues;
		if( json.enumTags!=null ) {
			for(mv in json.enumTags)
			for(tid in mv.tileIds)
				td.setTag(tid, mv.enumValueId, true);
		}

		// Custom data
		if( json.customData!=null ) {
			for( d in json.customData )
				td.customData.set(d.tileId, JsonTools.unescapeString(d.data));
		}

		if( json.cachedPixelData!=null ) {
			var size = td.cWid*td.cHei;
			var data = json.cachedPixelData;
			if( data.opaqueTiles!=null && data.opaqueTiles.length==size && data.averageColors!=null && data.averageColors.length%4==0 ) {
				td.opaqueTiles = new haxe.ds.Vector(size);
				var one = "1".code;
				for(i in 0...size)
					td.opaqueTiles[i] = data.opaqueTiles.charCodeAt(i)==one;

				td.averageColorsCache = new Map();
				var pos = 0;
				var tid = 0;
				while( pos<data.averageColors.length ) {
					td.averageColorsCache.set( tid, dn.legacy.Color.hex3ToInt_ARGB( data.averageColors.substr(pos,4) ) );
					tid++;
					pos+=4;
				}
			}
		}

		var arr = JsonTools.readArray( json.savedSelections );
		td.savedSelections = json.savedSelections==null ? [] : arr.map( function(jsonSel:Dynamic) {
			return {
				mode: JsonTools.readEnum(TileEditMode, jsonSel.mode, false, Stamp),
				ids: jsonSel.ids,
			}
		});
		return td;
	}


	public function importAtlasImage(?relFilePath:String, ?embedId:ldtk.Json.EmbedAtlas) : EditorTypes.ImageLoadingResult {
		// Check common errors
		if( relFilePath!=null ) {
			var chk = _project.checkImageBeforeLoading(relFilePath);
			if( chk!=Ok ) {
				if( relFilePath==null && embedId==null )
					removeAtlasImage();
				return chk;
			}
		}

		// Optional previous image infos
		var oldRelPath = relPath;
		var oldPxWid = pxWid;
		var oldPxHei = pxHei;

		// Init
		if( relFilePath!=null ) {
			var newPath = dn.FilePath.fromFile( relFilePath ).useSlashes();
			relPath = newPath.full;
			embedAtlas = null;
		}
		else if( embedId!=null ) {
			relPath = null;
			embedAtlas = embedId;
		}
		clearTileCache();

		// Load image
		App.LOG.fileOp('Loading atlas image: ${embedAtlas!=null ? embedAtlas.getName() : relPath}...');
		var img = getOrLoadTilesetImage();
		if( img==null ) {
			App.LOG.error("Image loading failed");
			return LoadingFailed("Could not read image file");
		}
		else {
			App.LOG.fileOp(' -> Loaded ${img.bytes.length} bytes.');
			App.LOG.fileOp(' -> Decoded ${img.pixels.width}x${img.pixels.height} pixels.');

			// Update dimensions
			pxWid = img.pixels.width;
			pxHei = img.pixels.height;
			App.LOG.fileOp(' -> Old size: ${oldPxWid}x$oldPxHei -> ${pxWid}x$pxHei');
			tileGridSize = dn.M.imin( tileGridSize, getMaxTileGridSize() );
			spacing = dn.M.imin( spacing, getMaxTileGridSize() );
			padding = dn.M.imin( padding, getMaxTileGridSize() );

			if( oldRelPath!=null || isUsingEmbedAtlas() && oldPxWid>0 ) {
				// Try to update previous image
				return remapAllTileIdsAfterResize(oldPxWid, oldPxHei);
			}
			else
				return Ok;
		}
	}


	function remapAllTileIdsAfterResize(oldPxWid:Int, oldPxHei:Int) : EditorTypes.ImageLoadingResult {
		App.LOG.warning('Tileset $identifier remapping (image size changed)...');
		if( oldPxWid==pxWid && oldPxHei==pxHei )
			return Ok;

		// Use padding to trim
		if( padding>0 && oldPxWid>pxWid && oldPxHei>pxHei && dn.M.iabs(oldPxWid-pxWid)<=padding*2 && dn.M.iabs(oldPxHei-pxHei)<=padding*2 && pxWid%2==0 && pxHei%2==0 ) {
			App.LOG.general(' > padding trim');
			padding -= Std.int( dn.M.imin( oldPxWid-pxWid, oldPxHei-pxHei ) / 2 );
			return TrimmedPadding;
		}

		return remapAllTileIds( dn.M.ceil( oldPxWid/tileGridSize ) );
	}


	public function remapAllTileIdsAfterGridChange(oldGrid:Int) : EditorTypes.ImageLoadingResult {
		return remapAllTileIds( dn.M.ceil( (pxWid-padding*2)/(oldGrid+spacing) ) );
	}


	function remapAllTileIds(oldCwid:Int) : EditorTypes.ImageLoadingResult {
		App.LOG.warning('Tileset remapping (oldCwid=$oldCwid)...');

		inline function _remapTileId(oldTileCoordId:Null<Int>) : Null<Int> {
			var tileCy = Std.int(oldTileCoordId/oldCwid);
			var tileCx = oldTileCoordId - tileCy*oldCwid;
			if( tileCx>=cWid || tileCy>=cHei )
				return null;
			else
				return tileCx + tileCy*cWid;
		}


		// Tiles layers remapping
		for(w in _project.worlds)
		for(l in w.levels)
		for(li in l.layerInstances) {
			if( li.def.type!=Tiles || li.def.tilesetDefUid!=uid )
				continue;

			App.LOG.general(' > level ${l.identifier} layer ${li.def.identifier}');

			for(tileStack in li.gridTiles) {
				var i = 0;
				while( i<tileStack.length ) {
					var r = _remapTileId(tileStack[i].tileId);
					if( r==null )
						tileStack.splice(i,1);
					else {
						tileStack[i].tileId = r;
						i++;
					}
				}
			}
		}

		// Saved selections remapping
		for(sel in savedSelections) {
			var i = 0;
			while( i<sel.ids.length ) {
				var r = _remapTileId(sel.ids[i]);
				if( r==null )
					sel.ids.splice(i,1);
				else {
					sel.ids[i] = r;
					i++;
				}
			}
		}

		// Auto-layer tiles remapping
		for(ld in _project.defs.layers)
			if( ld.isAutoLayer() && ld.tilesetDefUid==uid ) {
				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
				for(rectIds in r.tileRectsIds)
				for(i in 0...rectIds.length)
					rectIds[i] = _remapTileId( rectIds[i] );
			}

		// Enum tags remapping
		for(enumTag in enumTags.keys()) {
			var newMap = new Map();
			for( t in enumTags.get(enumTag).keyValueIterator() ) {
				var newTileId = _remapTileId(t.key);
				if( newTileId!=null )
					newMap.set(newTileId, t.value);
			}
			enumTags.set(enumTag, newMap);
		}

		// Custom tile-data remapping
		var newCustomData = new Map();
		for(cd in customData.keyValueIterator()) {
			var newTileId = _remapTileId(cd.key);
			if( newTileId!=null )
				newCustomData.set(newTileId, cd.value);
		}
		customData = newCustomData;

		// Results
		if( cWid < oldCwid ) {
			App.LOG.general(' > loss');
			return RemapLoss;
		}
		else {
			App.LOG.general(' > success');
			return RemapSuccessful;
		}
	}


	public inline function getAverageTileColor(tid:Int) : dn.Col {
		return averageColorsCache!=null && averageColorsCache.exists(tid) ? averageColorsCache.get(tid) : 0x888888;
	}

	public inline function getTileId(tcx,tcy) {
		return tcx + tcy * cWid;
	}

	public inline function getTileCx(tileId:Int) {
		return tileId - cWid * Std.int( tileId / cWid );
	}

	public inline function getTileCy(tileId:Int) {
		return Std.int( tileId / cWid );
	}

	public inline function getTileSourceX(tileId:Int) {
		return padding + getTileCx(tileId) * ( tileGridSize + spacing );
	}

	public inline function getTileSourceY(tileId:Int) {
		return padding + getTileCy(tileId) * ( tileGridSize + spacing );
	}

	public inline function xToCx(v:Float) : Int {
		return Std.int( ( v - padding ) / (tileGridSize + spacing ) );
	}

	public inline function yToCy(v:Float) : Int {
		return Std.int( ( v - padding ) / (tileGridSize + spacing ) );
	}


	public function saveSelection(tsSel:TilesetSelection) {
		// Remove existing overlapping saved selections
		for(tid in tsSel.ids) {
			var saved = getSavedSelectionFor(tid);
			if( saved!=null )
				savedSelections.remove(saved);
		}

		if( tsSel.ids.length>1 )
			savedSelections.push({
				mode: tsSel.mode,
				ids: tsSel.ids.copy(),
			});
	}

	public inline function hasSavedSelectionFor(tid:Int) : Bool {
		return getSavedSelectionFor(tid)!=null;
	}

	public function getSavedSelectionFor(tid:Int) : Null< TilesetSelection > {
		for(sel in savedSelections)
			for(stid in sel.ids)
				if( stid==tid )
					return sel;
		return null;
	}


	public function getTileGroupBounds(tileIds:Array<Int>) { // Warning: not good for real-time!
		if( tileIds==null || tileIds.length==0 )
			return {
				top: -1,
				bottom: -1,
				left: -1,
				right: -1,
				wid: 0,
				hei: 0,
			}

		var top = 99999;
		var left = 99999;
		var right = 0;
		var bottom = 0;
		for(tid in tileIds) {
			top = dn.M.imin( top, getTileCy(tid) );
			bottom = dn.M.imax( bottom, getTileCy(tid) );
			left = dn.M.imin( left, getTileCx(tid) );
			right = dn.M.imax( right, getTileCx(tid) );
		}
		return {
			top: top,
			bottom: bottom,
			left: left,
			right: right,
			wid: right-left+1,
			hei: bottom-top+1,
		}
	}


	public function getTileRectFromTileIds(tileIds:Array<Int>) : Null<ldtk.Json.TilesetRect> { // Warning: not good for real-time!
		if( tileIds==null || tileIds.length==0 )
			return null;

		var top = 99999;
		var left = 99999;
		var right = 0;
		var bottom = 0;
		for(tid in tileIds) {
			top = dn.M.imin( top, getTileSourceY(tid) );
			bottom = dn.M.imax( bottom, getTileSourceY(tid)+tileGridSize );
			left = dn.M.imin( left, getTileSourceX(tid) );
			right = dn.M.imax( right, getTileSourceX(tid)+tileGridSize );
		}
		return {
			tilesetUid: this.uid,
			x: left,
			y: top,
			w: right-left,
			h: bottom-top,
		}
	}


	public inline function getTileRectFromTileId(tid:Int) : Null<ldtk.Json.TilesetRect> { // Warning: not good for real-time!
		return {
			x: getTileSourceX(tid),
			y: getTileSourceY(tid),
			w: tileGridSize,
			h: tileGridSize,
			tilesetUid: uid,
		}
	}


	public function getTileIdsFromRect(r:ldtk.Json.TilesetRect) : Array<Int> {
		if( r==null )
			return [];

		var left = xToCx(r.x);
		var right = xToCx(r.x+r.w-1);
		var top = yToCy(r.y);
		var bottom = yToCy(r.y+r.h-1);

		var tids = [];
		for(cx in left...right+1)
		for(cy in top...bottom+1)
			tids.push( getTileId(cx,cy) );

		return tids;
	}


	public inline function getFirstTileIdFromRect(r:ldtk.Json.TilesetRect) : Null<Int> {
		if( r==null )
			return null;
		else
			return getTileId(xToCx(r.x), yToCy(r.y));
	}


	public function getTileGroupWidth(tileIds:Array<Int>) : Int {
		var min = 99999;
		var max = 0;
		for(tid in tileIds) {
			min = dn.M.imin( min, getTileCx(tid) );
			max = dn.M.imax( max, getTileCx(tid) );
		}
		return max-min+1;
	}

	public function getTileGroupHeight(tileIds:Array<Int>) : Int {
		var min = 99999;
		var max = 0;
		for(tid in tileIds) {
			min = dn.M.imin( min, getTileCy(tid) );
			max = dn.M.imax( max, getTileCy(tid) );
		}
		return max-min+1;
	}



	/*** HEAPS API *********************************/

	static var CACHED_ERROR_TILES: Map<Int,h3d.mat.Texture> = new Map();
	public static function makeErrorTile(size) {
		if( !CACHED_ERROR_TILES.exists(size) ) {
			var g = new h2d.Graphics();
			g.beginFill(0x880000);
			g.drawRect(0,0,size,size);
			g.endFill();

			g.lineStyle(2,0xff0000);

			g.moveTo(size*0.2,size*0.2);
			g.lineTo(size*0.8,size*0.8);

			g.moveTo(size*0.2,size*0.8);
			g.lineTo(size*0.8,size*0.2);

			g.endFill();

			var tex = new h3d.mat.Texture(size,size, [Target]);
			g.drawTo(tex);
			CACHED_ERROR_TILES.set(size, tex);
		}

		return h2d.Tile.fromTexture( CACHED_ERROR_TILES.get(size) );
	}

	public inline function getAtlasTile() : Null<h2d.Tile> {
		return isAtlasLoaded() ? h2d.Tile.fromTexture( getOrLoadTilesetImage().tex ) : null;
	}

	function clearTileCache() {
		cachedTiles = new Map();
	}

	inline function getCachedTile(x:Int, y:Int) {
		if( !isAtlasLoaded() )
			return makeErrorTile(tileGridSize);
		else {
			var cachedTileId = Std.int(x/tileGridSize) + Std.int(y/tileGridSize) * 100000;
			if( !cachedTiles.exists(cachedTileId) ) {
				var t = getAtlasTile().sub( x, y, tileGridSize, tileGridSize );
				cachedTiles.set(cachedTileId, t);
			}
			return cachedTiles.get(cachedTileId);
		}

	}


	public inline function getTileById(tileId:Int) : h2d.Tile {
		return getCachedTile( getTileSourceX(tileId), getTileSourceY(tileId) );
	}

	@:allow(display.LayerRender)
	inline function getOptimizedTileAt(gridTilePxX:Int, gridTilePxY:Int) : h2d.Tile {
		return getCachedTile(gridTilePxX, gridTilePxY);
	}


	public inline function getTileRect(r:ldtk.Json.TilesetRect) : h2d.Tile {
		if( isAtlasLoaded() )
			return getAtlasTile().sub( r.x, r.y, r.w, r.h );
		else
			return makeErrorTile(tileGridSize);
	}

	public inline function isTileOpaque(tid:Int) {
		return opaqueTiles!=null ? opaqueTiles[tid]==true : false;
	}


	function _parseTilePixels(img:CachedImage, tid:Int) {
		opaqueTiles[tid] = true;
		averageColorsCache.set(tid, 0x0);

		var tx = getTileSourceX(tid);
		var ty = getTileSourceY(tid);

		if( tx+tileGridSize<=pxWid && ty+tileGridSize<=pxHei ) {
			var a = 0.;
			var r = 0.;
			var g = 0.;
			var b = 0.;

			var pixel = 0x0;
			var nRGB = 0.;
			var nA = 0.;
			var curA = 0.;
			for(py in ty...ty+tileGridSize)
			for(px in tx...tx+tileGridSize) {
				pixel = img.pixels.getPixel(px,py);

				// Detect opacity
				if( opaqueTiles[tid]!=false && dn.legacy.Color.getA(pixel) < 1 )
					opaqueTiles[tid] = false;

				// Average color
				curA = dn.legacy.Color.getA(pixel);
				a += curA;
				r += dn.legacy.Color.getR(pixel) * dn.legacy.Color.getR(pixel) * curA;
				g += dn.legacy.Color.getG(pixel) * dn.legacy.Color.getG(pixel) * curA;
				b += dn.legacy.Color.getB(pixel) * dn.legacy.Color.getB(pixel) * curA;
				nRGB += curA;
				nA++;
			}

			// WARNING: actual color precision will later be reduced upon saving to 4-chars "argb"" String
			averageColorsCache.set(tid, dn.legacy.Color.makeColorArgb( Math.sqrt(r/nRGB), Math.sqrt(g/nRGB), Math.sqrt(b/nRGB), a/nA ));
		}
	}

	public inline function hasValidPixelData() {
		return isAtlasLoaded()
			&& opaqueTiles!=null && opaqueTiles.length==cWid*cHei
			&& averageColorsCache!=null;
	}


	public function buildPixelDataAndNotify(runImmediately=false) {
		buildPixelData( Editor.ME.ge.emit.bind(TilesetDefPixelDataCacheRebuilt(this)), runImmediately );
	}

	public function buildPixelData(?onComplete:Void->Void, runImmediately=false) {
		if( !isAtlasLoaded() )
			return false;

		App.LOG.general("Init pixel data cache for "+relPath);
		opaqueTiles = new haxe.ds.Vector( cWid*cHei );
		averageColorsCache = new Map();
		var img = getOrLoadTilesetImage();
		var ops = [];
		for(tcy in 0...cHei)
			ops.push({
				label: "Row "+tcy,
				cb : ()->{
					for(tcx in 0...cWid)
						_parseTilePixels( img, getTileId(tcx,tcy) );
				}
			});

		if( runImmediately ) {
			for(op in ops)
				op.cb();
			if( onComplete!=null )
				onComplete();
		}
		else
			new ui.modal.Progress('Initializing pixel data cache for "${getFileName(true)}"', ops, onComplete);

		return true;
	}

	/* META DATA ******************************************/

	public function getTagsEnumDef() : Null<EnumDef> {
		return tagsSourceEnumUid==null ? null : _project.defs.getEnumDef(tagsSourceEnumUid);
	}

	public function setTag(tileId:Int, enumValueId:String, active:Bool) {
		if( tileId<0 || tileId>=cWid*cHei )
			return;

		if( !enumTags.exists(enumValueId) )
			enumTags.set(enumValueId, new Map());

		if( active )
			enumTags.get(enumValueId).set(tileId, true);
		else
			enumTags.get(enumValueId).remove(tileId);
	}

	public inline function hasTag(enumId:String, tileId:Int) {
		return enumTags.exists(enumId) && enumTags.get(enumId).get(tileId)==true;
	}

	public function hasAnyTag(?tileId:Int) {
		for(m in enumTags)
			if( tileId==null )
				return true;
			else if( m.exists(tileId) )
				return true;
		return false;
	}

	public function getAllTagsAt(tileId:Int) : Array<String> {
		var all = [];
		for(ek in enumTags.keys())
			if( enumTags.get(ek).exists(tileId) )
				all.push(ek);

		return all;
	}

	public function removeAllTagsAt(tileId:Int) {
		for( mv in enumTags )
			mv.remove(tileId);
	}

	public function hasAnyTileCustomData() : Bool {
		for(c in customData)
			return true;
		return false;
	}
	public inline function hasTileCustomData(tileId:Int) : Bool {
		return getTileCustomData(tileId)!=null;
	}

	public function getTileCustomData(tileId:Int) : Null<String> {
		return customData.exists(tileId) ? customData.get(tileId) : null;
	}

	public function setTileCustomData(tileId:Int, ?str:String) {
		if( str==null )
			customData.remove(tileId);
		else
			customData.set(tileId, str);
	}



	/*** JS API *********************************/
	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( isAtlasLoaded() ) {
			var imgData = getOrLoadTilesetImage();
			img.src = 'data:image/png;base64,${imgData.base64}';
		}
		return img;
	}

	public function drawAtlasToCanvas(jCanvas:js.jquery.JQuery, scale=1.0) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		if( !isAtlasLoaded() )
			return;

		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.imageSmoothingEnabled = false;
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var imgData = getOrLoadTilesetImage();

		var clampedArray = new js.lib.Uint8ClampedArray( imgData.pixels.width * imgData.pixels.height * 4 );
		var c = 0;
		var idx = 0;
		for(y in 0...imgData.pixels.height)
		for(x in 0...imgData.pixels.width) {
			c = imgData.pixels.getPixel(x,y);
			idx = y*(imgData.pixels.width*4) + x*4;
			clampedArray[idx] = dn.legacy.Color.getRi(c);
			clampedArray[idx+1] = dn.legacy.Color.getGi(c);
			clampedArray[idx+2] = dn.legacy.Color.getBi(c);
			clampedArray[idx+3] = dn.legacy.Color.getAi(c);
		}
		var imgData = new js.html.ImageData(clampedArray, imgData.pixels.width);
		ctx.putImageData(imgData,0,0);
	}

	inline function isTileInBounds(tid:Int) {
		return isAtlasLoaded()
			&& getTileSourceX(tid)>=0 && getTileSourceX(tid)+tileGridSize-1 < pxWid
			&& getTileSourceY(tid)>=0 && getTileSourceY(tid)+tileGridSize-1 < pxHei;
	}


	public function createCanvasFromTileId(tileId:Int, canvasSize:Int) : js.jquery.JQuery {
		var jCanvas = new J('<canvas></canvas>');
		jCanvas.attr("width",tileGridSize);
		jCanvas.attr("height",tileGridSize);
		jCanvas.css("width", canvasSize+"px");
		jCanvas.css("height", canvasSize+"px");
		drawTileToCanvas(jCanvas, tileId);
		return jCanvas;
	}

	public function createCanvasFromTileRect(tileRect:ldtk.Json.TilesetRect, canvasSize:Int) : js.jquery.JQuery {
		var jCanvas = new J('<canvas></canvas>');
		jCanvas.attr("width",tileGridSize);
		jCanvas.attr("height",tileGridSize);
		jCanvas.css("width", canvasSize+"px");
		jCanvas.css("height", canvasSize+"px");
		drawTileRectToCanvas(jCanvas, tileRect);
		return jCanvas;
	}


	public function createTileHtmlImageFromTileId(tid:Int, ?imgWid:Int, ?imgHei:Int) : js.jquery.JQuery {
		var jImg =
			if( isAtlasLoaded() && isTileInBounds(tid) ) {
				var imgData = getOrLoadTilesetImage();
				var subPixels = imgData.pixels.sub(getTileSourceX(tid), getTileSourceY(tid), tileGridSize, tileGridSize);
				var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
				var img = new js.html.Image(subPixels.width, subPixels.height);
				img.src = 'data:image/png;base64,$b64';
				new J(img);
			}
			else
				new J( new js.html.Image() );

		if( imgWid!=null ) {
			jImg.css({
				width:imgWid+"px",
				height:(imgHei!=null?imgHei:imgWid)+"px",
				imageRendering: "pixelated",
			});
		}
		return jImg;
	}


	public function createTileHtmlImageFromRect(r:ldtk.Json.TilesetRect, ?imgWid:Int, ?imgHei:Int) : js.jquery.JQuery {
		var jImg =
			if( isAtlasLoaded() && isTileRectInBounds(r) ) {
				var imgData = getOrLoadTilesetImageSub(r.x, r.y, r.w, r.h);
				var subPixels = imgData.pixels;
				var b64 = imgData.base64;
				var img = new js.html.Image(subPixels.width, subPixels.height);
				img.src = 'data:image/png;base64,$b64';
				new J(img);
			}
			else
				new J( new js.html.Image() );

		if( imgWid!=null )
			jImg.css({
				width:imgWid+"px",
				height:(imgHei!=null?imgHei:imgWid)+"px",
				imageRendering: "pixelated",
			});

		return jImg;
	}

	public function createTileHtmlUri(tid:Int, ?imgWid:Int, ?imgHei:Int) : Null<String> {
		if( !isAtlasLoaded() || !isTileInBounds(tid) )
			return null;

		var imgData = getOrLoadTilesetImage();
		var subPixels = imgData.pixels.sub(getTileSourceX(tid), getTileSourceY(tid), tileGridSize, tileGridSize);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		return 'data:image/png;base64,$b64';
	}

	public function drawTileToCanvas(jCanvas:js.jquery.JQuery, tileId:Int, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		drawTileTo2dContext( canvas.getContext2d(), tileId, toX, toY, scaleX, scaleY );
	}


	public function drawTileTo2dContext(ctx:js.html.CanvasRenderingContext2D, tileId:Int, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
		if( !isAtlasLoaded() )
			return;

		if( !isTileInBounds(tileId) )
			return; // out of bounds

		var imgData = getOrLoadTilesetImage();
		var subPixels = imgData.pixels.sub(getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize);
		ctx.imageSmoothingEnabled = false;
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		img.onload = function() {
			ctx.drawImage(img, toX, toY, subPixels.width*scaleX, subPixels.height*scaleY);
		}
	}


	inline function isTileRectInBounds(r:ldtk.Json.TilesetRect) {
		return isAtlasLoaded()
			&& r.x>=0 && r.x+r.w-1<pxWid
			&& r.y>=0 && r.y+r.h-1<pxHei;
	}

	public function drawTileRectToCanvas(jCanvas:js.jquery.JQuery, rect:ldtk.Json.TilesetRect, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		drawTileRectTo2dContext( canvas.getContext2d(), rect, toX, toY, scaleX, scaleY );
	}

	public function drawTileRectTo2dContext(ctx:js.html.CanvasRenderingContext2D, rect:ldtk.Json.TilesetRect, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
		if( !isAtlasLoaded() )
			return;

		if( !isTileRectInBounds(rect) )
			return; // out of bounds

		var imgData = getOrLoadTilesetImage();
		var subPixels = imgData.pixels.sub(rect.x, rect.y, rect.w, rect.h);
		ctx.imageSmoothingEnabled = false;
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		img.onload = function() {
			ctx.drawImage(img, toX, toY, subPixels.width*scaleX, subPixels.height*scaleY);
		}
	}


	public function getTileHtmlImg(tileRect:ldtk.Json.TilesetRect) : Null<js.html.Image> {
		if( !isAtlasLoaded() )
			return null;

		if( !isTileRectInBounds(tileRect) )
			return null; // out of bounds

		var imgData = getOrLoadTilesetImage();
		var subPixels = imgData.pixels.sub(tileRect.x, tileRect.y, tileRect.w, tileRect.h);
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		return img;
	}


	// public function drawTileRectTo2dContext(ctx:js.html.CanvasRenderingContext2D, rect:CustomTileRect, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
	// 	if( !isAtlasLoaded() )
	// 		return;

	// 	if( !isTileInBounds(tileId) )
	// 		return; // out of bounds

	// 	var imgData = _project.getOrLoadImage(relPath);
	// 	var subPixels = imgData.pixels.sub(getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize);
	// 	ctx.imageSmoothingEnabled = false;
	// 	var img = new js.html.Image(subPixels.width, subPixels.height);
	// 	var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
	// 	img.src = 'data:image/png;base64,$b64';
	// 	img.onload = function() {
	// 		ctx.drawImage(img, toX, toY, subPixels.width*scaleX, subPixels.height*scaleY);
	// 	}
	// }



	public function tidy(p:data.Project) {
		_project = p;

		// Enforce embed atlas ID
		if( embedAtlas!=null ) {
			var inf = Lang.getEmbedAtlasInfos(embedAtlas);
			identifier = Project.cleanupIdentifier(inf.identifier, _project.identifierStyle);
		}

		// Lost source enum
		if( tagsSourceEnumUid!=null && getTagsEnumDef()==null ) {
			App.LOG.add("tidy", "Cleared lost tag enum in "+this);
			tagsSourceEnumUid = null;
		}

		// Clear tags if source is null
		if( tagsSourceEnumUid==null && hasAnyTag() ) {
			App.LOG.add("tidy", "Cleared lost tags in "+this);
			enumTags = new Map();
		}

		// Lost tag values
		if( tagsSourceEnumUid!=null ) {
			var ed = getTagsEnumDef();
			for(k in enumTags.keys())
				if( !ed.hasValue(k) ) {
					App.LOG.add("tidy", "Cleared lost tag value in "+this);
					enumTags.remove(k);
				}
		}

		clearTileCache();
	}
}