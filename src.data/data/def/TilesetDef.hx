package data.def;

import data.DataTypes;

class TilesetDef {
	var _project : Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;
	public var relPath(default,null) : Null<String>;
	public var tileGridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var padding : Int = 0; // px dist to atlas borders
	public var spacing : Int = 0; // px space between consecutive tiles
	public var savedSelections : Array<TilesetSelection> = [];

	// @:allow(page.Editor)
	// var opaqueTilesCache : Null< Map<Int,Bool> >;

	var opaqueTiles : Null< haxe.ds.Vector<Bool> >;
	var averageColorsCache : Null< Map<Int,Int> >; // ARGB Int

	public var pxWid = 0;
	public var pxHei = 0;
	var bytes : Null<haxe.io.Bytes>;
	var texture : Null<h3d.mat.Texture>;
	var pixels : Null<hxd.Pixels>;
	var base64 : Null<String>;


	public var cWid(get,never) : Int;
	inline function get_cWid() return !hasAtlasPath() ? 0 : dn.M.ceil( (pxWid-padding*2) / (tileGridSize+spacing) );

	public var cHei(get,never) : Int;
	inline function get_cHei() return !hasAtlasPath() ? 0 : dn.M.ceil( (pxHei-padding*2) / (tileGridSize+spacing) );


	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier = "Tileset"+uid;
	}

	public function toString() {
		return 'TilesetDef.$identifier($relPath)';
	}

	public inline function hasAtlasPath() return relPath!=null;
	public inline function isAtlasLoaded() return relPath!=null && bytes!=null;

	@:allow(data.Project)
	function unsafeRelPathChange(newRelPath:String) { // should ONLY be used in specific circonstances
		relPath = newRelPath;
	}

	public function getMaxTileGridSize() {
		return hasAtlasPath() ? dn.M.imin(pxWid, pxHei) : 100;
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	public function getFileName(withExt:Bool) : Null<String> {
		if( !hasAtlasPath() )
			return null;

		return withExt ? dn.FilePath.extractFileWithExt(relPath) : dn.FilePath.extractFileName(relPath);
	}

	public function removeAtlasImage() {
		relPath = null;
		pxWid = pxHei = 0;
		savedSelections = [];

		#if heaps
		if( texture!=null )
			texture.dispose();
		texture = null;

		if( pixels!=null )
			pixels.dispose();
		pixels = null;

		bytes = null;
		base64 = null;
		#end
	}


	public function toJson() : ldtk.Json.TilesetDefJson {
		return {
			identifier: identifier,
			uid: uid,
			relPath: JsonTools.writePath(relPath),
			pxWid: pxWid,
			pxHei: pxHei,
			tileGridSize: tileGridSize,
			spacing: spacing,
			padding: padding,

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
						buf.add( dn.Color.intToHex3_ARGB( averageColorsCache.get(tid) ) );
					buf.toString();
				},
			},
		}
	}


	public static function fromJson(p:Project, json:ldtk.Json.TilesetDefJson) {
		var td = new TilesetDef( p, JsonTools.readInt(json.uid) );
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Project.DEFAULT_GRID_SIZE);
		td.spacing = JsonTools.readInt(json.spacing, 0);
		td.padding = JsonTools.readInt(json.padding, 0);
		td.pxWid = JsonTools.readInt( json.pxWid );
		td.pxHei = JsonTools.readInt( json.pxHei );
		td.relPath = json.relPath;
		td.identifier = JsonTools.readString(json.identifier, "Tileset"+td.uid);

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
					td.averageColorsCache.set( tid, dn.Color.hex3ToInt_ARGB( data.averageColors.substr(pos,4) ) );
					tid++;
					pos+=4;
				}
			}
		}


		// if( json.opaqueTiles!=null ) {
		// 	td.opaqueTilesCache = new Map();
		// 	for(tid in json.opaqueTiles)
		// 		td.opaqueTilesCache.set(tid, true);
		// }
		// else
		// 	td.opaqueTilesCache = null;

		var arr = JsonTools.readArray( json.savedSelections );
		td.savedSelections = json.savedSelections==null ? [] : arr.map( function(jsonSel:Dynamic) {
			return {
				mode: JsonTools.readEnum(TileEditMode, jsonSel.mode, false, Stamp),
				ids: jsonSel.ids,
			}
		});
		return td;
	}


	public function importAtlasImage(projectDir:String, relFilePath:String) : Bool {
		if( relFilePath==null ) {
			removeAtlasImage();
			return false;
		}

		var newPath = dn.FilePath.fromFile( relFilePath ).useSlashes();
		relPath = newPath.full;

		try {
			var fullFp = newPath.hasDriveLetter() ? newPath : dn.FilePath.fromFile( projectDir +"/"+ relFilePath );
			var fullPath = fullFp.full;
			App.LOG.fileOp("Loading atlas image: "+fullPath);
			bytes = misc.JsTools.readFileBytes(fullPath);

			if( bytes==null ) {
				App.LOG.error("No bytes");
				return false;
			}

			App.LOG.fileOp(' -> Loaded ${bytes.length} bytes.');
			base64 = haxe.crypto.Base64.encode(bytes);
			pixels = dn.ImageDecoder.decodePixels(bytes);
			App.LOG.fileOp(' -> Decoded ${pixels.width}x${pixels.height} pixels.');
			texture = h3d.mat.Texture.fromPixels(pixels);
		}
		catch(err:Dynamic) {
			App.LOG.error(err);
			removeAtlasImage();
			return false;
		}

		pxWid = pixels.width;
		pxHei = pixels.height;
		tileGridSize = dn.M.imin( tileGridSize, getMaxTileGridSize() );
		spacing = dn.M.imin( spacing, getMaxTileGridSize() );
		padding = dn.M.imin( padding, getMaxTileGridSize() );

		return true;
	}

	public inline function reloadImage(projectDir:String) : EditorTypes.ImageSyncResult {
		var oldWid = pxWid;
		var oldHei = pxHei;
		App.LOG.fileOp("Reloading tileset image "+relPath);

		if( !importAtlasImage(projectDir, relPath) )
			return FileNotFound;

		if( oldWid==pxWid && oldHei==pxHei )
			return Ok;

		if( padding>0 && oldWid>pxWid && oldHei>pxHei && dn.M.iabs(oldWid-pxWid)<=padding*2 && dn.M.iabs(oldHei-pxHei)<=padding*2 && pxWid%2==0 && pxHei%2==0 ) {
			padding -= Std.int( dn.M.imin( oldWid-pxWid, oldHei-pxHei ) / 2 );
			return TrimmedPadding;
		}

		var oldCwid = dn.M.ceil( oldWid / tileGridSize );

		// Layers remapping
		for(l in _project.levels)
		for(li in l.layerInstances)
		for( coordId in li.gridTiles.keys() ) {
			if( !li.gridTiles.exists(coordId) )
				continue;

			var i = 0;
			while( i < li.gridTiles.get(coordId).length ) {
				var tileInf = li.gridTiles.get(coordId)[i];
				var remappedTileId = remapTileId( oldCwid, tileInf.tileId );
				if( remappedTileId==null )
					li.gridTiles.get(coordId).splice(i,1);
				else {
					tileInf.tileId = remappedTileId;
					i++;
				}
			}
			// for( tileInf in li.gridTiles.get(coordId) ) {
			// 	var remap = remapTileId( oldCwid, tileInf.tileId );
			// 	if( remap==null )
			// 		li.gridTiles.remove(coordId);
			// 	else
			// 		tileInf.tileId = remap;
			// }
		}

		// Save selections remapping
		for(sel in savedSelections) {
			var i = 0;
			while( i<sel.ids.length ) {
				var remap = remapTileId(oldCwid, sel.ids[i]);
				if( remap==null )
					sel.ids.splice(i,1);
				else {
					sel.ids[i] = remap;
					i++;
				}
			}
		}

		// Enum tiles remapping
		for(ed in _project.defs.enums)
			if( ed.iconTilesetUid==uid )
				for(v in ed.values)
					v.tileId = remapTileId(oldCwid, v.tileId);

		// Entity tiles remapping
		for( ed in _project.defs.entities )
			if( ed.tilesetId==uid && ed.tileId!=null )
				ed.tileId = remapTileId(oldCwid, ed.tileId);

		// Auto-layer tiles remapping
		for(ld in _project.defs.layers)
			if( ld.isAutoLayer() && ld.autoTilesetDefUid==uid ) {
				for(rg in ld.autoRuleGroups)
				for(r in rg.rules)
				for(i in 0...r.tileIds.length)
					r.tileIds[i] = remapTileId(oldCwid, r.tileIds[i]);
			}


		if( pxWid<oldWid || pxHei<oldHei )
			return RemapLoss;
		else
			return RemapSuccessful;
	}

	inline function remapTileId(oldCwid:Int, oldTileCoordId:Null<Int>) : Null<Int> {
		if( oldTileCoordId==null )
			return null;

		var oldCy = Std.int( oldTileCoordId / oldCwid );
		var oldCx = oldTileCoordId - oldCwid*oldCy;
		if( oldCx>=cWid || oldCy>=cHei )
			return null;
		else
			return getTileId(oldCx, oldCy);
	}

	public inline function getAverageTileColor(tid:Int) {
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
		return isAtlasLoaded() ? h2d.Tile.fromTexture(texture) : null;
	}

	public inline function getTile(tileId:Int) : h2d.Tile {
		if( isAtlasLoaded() )
			return getAtlasTile().sub( getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize );
		else
			return makeErrorTile(tileGridSize);
	}

	public inline function extractTile(tileX:Int, tileY:Int) : h2d.Tile {
		if( isAtlasLoaded() )
			return getAtlasTile().sub( tileX, tileY, tileGridSize, tileGridSize );
		else
			return makeErrorTile(tileGridSize);
	}


	public inline function isTileOpaque(tid:Int) {
		return opaqueTiles!=null ? opaqueTiles[tid]==true : false;
		// return opaqueTilesCache!=null ? opaqueTilesCache.get(tid)==true : false;
	}


	function _parseTilePixels(tid:Int) {
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
				pixel = pixels.getPixel(px,py);

				// Detect opacity
				if( opaqueTiles[tid]!=false && dn.Color.getA(pixel) < 1 )
					opaqueTiles[tid] = false;

				// Average color
				curA = dn.Color.getA(pixel);
				a += curA;
				r += dn.Color.getR(pixel) * dn.Color.getR(pixel) * curA;
				g += dn.Color.getG(pixel) * dn.Color.getG(pixel) * curA;
				b += dn.Color.getB(pixel) * dn.Color.getB(pixel) * curA;
				nRGB += curA;
				nA++;
			}

			// WARNING: actual color precision will later be reduced upon saving to 4-chars "argb"" String
			averageColorsCache.set(tid, dn.Color.makeColor( Math.sqrt(r/nRGB), Math.sqrt(g/nRGB), Math.sqrt(b/nRGB), a/nA ));
		}
	}

	public inline function hasValidPixelData() {
		return isAtlasLoaded()
			&& opaqueTiles!=null && opaqueTiles.length==cWid*cHei
			&& averageColorsCache!=null;
	}

	public function buildPixelData(onComplete:Void->Void, sync=false) {
		if( !isAtlasLoaded() )
			return false;

		App.LOG.general("Init pixel data cache for "+relPath);
		opaqueTiles = new haxe.ds.Vector( cWid*cHei );
		averageColorsCache = new Map();
		var ops = [];
		for(tcy in 0...cHei)
			ops.push({
				label: "Row "+tcy,
				cb : ()->{
					for(tcx in 0...cWid)
						_parseTilePixels( getTileId(tcx,tcy) );
				}
			});

		if( !sync )
			new ui.modal.Progress('Initializing pixel data cache for "${getFileName(true)}"', 3, ops, onComplete);
		else
			for(op in ops)
				op.cb();

		return true;
	}



	/*** JS API *********************************/
	#if js

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( isAtlasLoaded() )
			img.src = 'data:image/png;base64,$base64';
		return img;
	}

	#if editor
	public function drawAtlasToCanvas(jCanvas:js.jquery.JQuery, scale=1.0) {
		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		if( !isAtlasLoaded() )
			return;

		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.imageSmoothingEnabled = false;
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var clampedArray = new js.lib.Uint8ClampedArray( pixels.width * pixels.height * 4 );
		var c = 0;
		var idx = 0;
		for(y in 0...pixels.height)
		for(x in 0...pixels.width) {
			c = pixels.getPixel(x,y);
			idx = y*(pixels.width*4) + x*4;
			clampedArray[idx] = dn.Color.getRi(c);
			clampedArray[idx+1] = dn.Color.getGi(c);
			clampedArray[idx+2] = dn.Color.getBi(c);
			clampedArray[idx+3] = dn.Color.getAi(c);
		}
		var imgData = new js.html.ImageData(clampedArray, pixels.width);
		ctx.putImageData(imgData,0,0);

		// var img = new js.html.Image(pixels.width, pixels.height);
		// img.src = 'data:image/png;base64,$base64';
		// img.onload = function() {
		// 	ctx.drawImage(img, 0, 0, pixels.width*scale, pixels.height*scale);
		// }
	}

	public function drawTileToCanvas(jCanvas:js.jquery.JQuery, tileId:Int, toX=0, toY=0, scaleX=1.0, scaleY=1.0) {
		if( pixels==null )
			return;

		if( !jCanvas.is("canvas") )
			throw "Not a canvas";

		if( getTileSourceX(tileId)+tileGridSize>pxWid || getTileSourceY(tileId)+tileGridSize>pxHei )
			return; // out of bounds

		var subPixels = pixels.sub(getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize);
		var canvas = Std.downcast(jCanvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.imageSmoothingEnabled = false;
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		img.onload = function() {
			ctx.drawImage(img, toX, toY, subPixels.width*scaleX, subPixels.height*scaleY);
		}
	}
	#end

	#end

	public function tidy(p:data.Project) {
		_project = p;
	}
}