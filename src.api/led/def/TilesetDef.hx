package led.def;

import led.LedTypes;

class TilesetDef {
	var _project : Project;

	public var uid : Int;
	public var identifier(default,set) : String;
	public var relPath(default,null) : Null<String>;
	public var tileGridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;
	public var savedSelections : Array<TilesetSelection> = [];

	public var pxWid = 0;
	public var pxHei = 0;
	var bytes : Null<haxe.io.Bytes>;
	var texture : Null<h3d.mat.Texture>;
	var pixels : Null<hxd.Pixels>;
	var base64 : Null<String>;


	public var cWid(get,never) : Int;
	inline function get_cWid() return !hasAtlasPath() ? 0 : dn.M.ceil( pxWid / tileGridSize );

	public var cHei(get,never) : Int;
	inline function get_cHei() return !hasAtlasPath() ? 0 : dn.M.ceil( pxHei / tileGridSize );


	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier = "Tileset"+uid;
	}

	public function toString() {
		return identifier+"("+relPath+")";
	}

	public inline function hasAtlasPath() return relPath!=null;
	public inline function isAtlasLoaded() return relPath!=null && bytes!=null;

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


	public function toJson() {
		return {
			identifier: identifier,
			uid: uid,
			relPath: JsonTools.writePath(relPath),
			pxWid: pxWid,
			pxHei: pxHei,
			tileGridSize: tileGridSize,
			tileGridSpacing: tileGridSpacing,
			savedSelections: savedSelections.map( function(sel) {
				return { ids:sel.ids, mode:JsonTools.writeEnum(sel.mode, false) }
			}),
		}
	}


	public static function fromJson(p:Project, json:Dynamic) {
		var td = new TilesetDef( p, JsonTools.readInt(json.uid) );
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Project.DEFAULT_GRID_SIZE);
		td.tileGridSpacing = JsonTools.readInt(json.tileGridSpacing, 0);
		td.pxWid = JsonTools.readInt( json.pxWid );
		td.pxHei = JsonTools.readInt( json.pxHei );
		td.relPath = json.relPath;
		td.identifier = JsonTools.readString(json.identifier, "Tileset"+td.uid);

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

		relPath = dn.FilePath.fromFile( relFilePath ).useSlashes().full;

		try {
			var fullPath = Editor.ME.makeFullFilePath(relPath);
			bytes = misc.JsTools.readFileBytes(fullPath);

			if( bytes==null )
				return false;

			base64 = haxe.crypto.Base64.encode(bytes);
			pixels = dn.ImageDecoder.decodePixels(bytes);
			texture = h3d.mat.Texture.fromPixels(pixels);
		}
		catch(err:Dynamic) {
			trace(err);
			removeAtlasImage();
			return false;
		}

		pxWid = pixels.width;
		pxHei = pixels.height;
		tileGridSize = dn.M.imin( tileGridSize, getMaxTileGridSize() );
		tileGridSpacing = dn.M.imin( tileGridSpacing, getMaxTileGridSize() );

		return true;
	}

	public inline function reloadImage(projectDir:String) : EditorTypes.ImageSyncResult {
		var oldWid = pxWid;
		var oldHei = pxHei;

		if( !importAtlasImage(projectDir, relPath) )
			return FileNotFound;

		if( oldWid==pxWid && oldHei==pxHei )
			return Ok;

		var oldCwid = dn.M.ceil( oldWid / tileGridSize );

		// Layers remapping
		for(l in _project.levels)
		for(li in l.layerInstances)
		for( coordId in li.gridTiles.keys() ) {
			var remap = remapTileId( oldCwid, li.gridTiles.get(coordId) );
			if( remap==null )
				li.gridTiles.remove(coordId);
			else
				li.gridTiles.set( coordId, remap );
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
		for(ed in _project.defs.enums) {
			if( ed.iconTilesetUid!=uid )
				continue;

			for(v in ed.values) {
				if( v.tileId==null )
					continue;

				v.tileId = remapTileId(oldCwid, v.tileId);
			}
		}

		if( pxWid<oldWid || pxHei<oldHei )
			return RemapLoss;
		else
			return RemapSuccessful;
	}

	inline function remapTileId(oldCwid:Int, oldTileCoordId:Int) : Null<Int> {
		var oldCy = Std.int( oldTileCoordId / oldCwid );
		var oldCx = oldTileCoordId - oldCwid*oldCy;
		if( oldCx>=cWid || oldCy>=cHei )
			return null;
		else
			return getTileId(oldCx, oldCy);
	}

	public function getTileId(tcx,tcy) {
		return tcx + tcy * cWid;
	}

	public inline function getTileCx(tileId:Int) {
		return tileId - cWid * Std.int( tileId / cWid );
	}

	public inline function getTileCy(tileId:Int) {
		return Std.int( tileId / cWid );
	}

	public inline function getTileSourceX(tileId:Int) {
		return getTileCx(tileId) * ( tileGridSize + tileGridSpacing );
	}

	public inline function getTileSourceY(tileId:Int) {
		return getTileCy(tileId) * ( tileGridSize + tileGridSpacing );
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



	/*** JS API *********************************/
	#if js

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( isAtlasLoaded() )
			img.src = 'data:image/png;base64,$base64';
		return img;
	}

	#if editor
	public function drawAtlasToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( !isAtlasLoaded() )
			return;

		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var img = new js.html.Image(pixels.width, pixels.height);
		img.src = 'data:image/png;base64,$base64';
		img.onload = function() {
			ctx.drawImage(img, 0, 0);
		}
	}

	public function drawTileToCanvas(canvas:js.jquery.JQuery, tileId:Int, toX:Int, toY:Int) {
		if( pixels==null )
			return;

		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( getTileSourceX(tileId)+tileGridSize>pxWid || getTileSourceY(tileId)+tileGridSize>pxHei )
			return; // out of bounds

		var subPixels = pixels.sub(getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize);
		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		var img = new js.html.Image(subPixels.width, subPixels.height);
		var b64 = haxe.crypto.Base64.encode( subPixels.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		img.onload = function() {
			ctx.drawImage(img, toX, toY);
		}
	}
	#end

	#end

	public function tidy(p:led.Project) {
		_project = p;
	}
}