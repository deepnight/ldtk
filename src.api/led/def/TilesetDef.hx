package led.def;

import led.LedTypes;

class TilesetDef {
	public var uid : Int;
	public var identifier(default,set) : String;
	public var path : Null<String>; // TODO add a setter to auto clear cache
	public var pxWid = 0;
	public var pxHei = 0;
	public var tileGridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;
	public var savedSelections : Array<TilesetSelection> = [];

	#if heaps
	var bytes(get,never) : Null<haxe.io.Bytes>;
	var _bytesCache : Null<haxe.io.Bytes>;

	var texture(get,never) : Null<h3d.mat.Texture>;
	var _textureCache : Null<h3d.mat.Texture>;

	var pixels(get,never) : Null<hxd.Pixels>;
	var _pixelsCache : Null<hxd.Pixels>;
	#end

	#if editor
	var base64(get,null): Null<String>;
	var _base64cache : Null<String>;
	#end

	public var cWid(get,never) : Int; inline function get_cWid() return !isAtlasValid() ? 0 : dn.M.ceil( pxWid / tileGridSize );
	public var cHei(get,never) : Int; inline function get_cHei() return !isAtlasValid() ? 0 : dn.M.ceil( pxHei / tileGridSize );


	public function new(uid:Int) {
		this.uid = uid;
		identifier = "Tileset"+uid;
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	public function getFileName(withExt:Bool) : Null<String> {
		if( path==null )
			return null;

		return withExt ? dn.FilePath.extractFileWithExt(path) : dn.FilePath.extractFileName(path);
	}

	public function disposeAtlasCache() {
		#if heaps
		if( _textureCache!=null )
			_textureCache.dispose();
		_textureCache = null;

		if( _pixelsCache!=null )
			_pixelsCache.dispose();
		_pixelsCache = null;

		_bytesCache = null;
		#end
	}

	public function clearAtlas() {
		path = null;
		disposeAtlasCache();
		savedSelections = [];
	}

	public inline function isAtlasPathValid() return path!=null && misc.JsTools.fileExists(path);
	public inline function isAtlasValid() return isAtlasPathValid() && bytes!=null;


	public function toJson() {
		return {
			uid: uid,
			identifier: identifier,
			path: path,
			pxWid: pxWid,
			pxHei: pxHei,
			tileGridSize: tileGridSize,
			tileGridSpacing: tileGridSpacing,
			savedSelections: savedSelections.map( function(sel) {
				return { ids:sel.ids, mode:JsonTools.writeEnum(sel.mode, false) }
			}),
		}
	}


	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var td = new TilesetDef( JsonTools.readInt(json.uid) );
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Project.DEFAULT_GRID_SIZE);
		td.tileGridSpacing = JsonTools.readInt(json.tileGridSpacing, 0);
		td.pxWid = JsonTools.readInt( json.pxWid );
		td.pxHei = JsonTools.readInt( json.pxHei );
		td.path = json.path;
		td.identifier = JsonTools.readString(json.identifier, "Tileset"+td.uid);

		var arr = JsonTools.readArray( json.savedSelections );
		td.savedSelections = json.savedSelections==null ? [] : arr.map( function(jsonSel:Dynamic) {
			return {
				mode: JsonTools.readEnum(TileEditMode, jsonSel.mode, false, Stamp),
				ids: jsonSel.ids,
			}
		}) ;
		return td;
	}

	public function importImage(filePath:String, fileContent:haxe.io.Bytes) : Bool {
		clearAtlas();

		var img = dn.ImageDecoder.decode(fileContent);
		if( img==null )
			return false;

		_bytesCache = fileContent;
		path = dn.FilePath.fromFile(filePath).useSlashes().full;
		pxWid = img.width;
		pxHei = img.height;
		return true;
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

	public function dispose() {
		disposeAtlasCache();
		// TODO clear other fields?
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
	#if heaps

	function makeErrorTile() {
		return h2d.Tile.fromColor(0xff0000, tileGridSize, tileGridSize);
	}

	public inline function getAtlasTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

	public inline function getTile(tileId:Int) : h2d.Tile {
		if( isAtlasValid() )
			return getAtlasTile().sub( getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize );
		else
			return makeErrorTile();
	}

	function get_texture() {
		if( _textureCache==null && pixels!=null )
			_textureCache = h3d.mat.Texture.fromPixels(pixels);
		return _textureCache;
	}

	function get_pixels() {
		if( path==null )
			return null;

		if( _pixelsCache==null ) {
			if( bytes==null )
				return null;
			_pixelsCache = dn.ImageDecoder.decodePixels(bytes);
		}
		return _pixelsCache;
	}


	function get_bytes() {
		if( _bytesCache==null )
			_bytesCache = misc.JsTools.readFileBytes(path);
		return _bytesCache;
	}

	#end



	/*** JS API *********************************/
	#if js

	function get_base64() {
		if( path==null )
			return null;
		else if( _base64cache==null )
			_base64cache = haxe.crypto.Base64.encode( misc.JsTools.readFileBytes(path) );
		return _base64cache;
	}

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( isAtlasValid() )
			img.src = 'data:image/png;base64,$base64';
		return img;
	}

	#if editor
	public function drawAtlasToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( !isAtlasValid() )
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

		if( getTileSourceX(tileId)+tileGridSize>=pxWid || getTileSourceY(tileId)+tileGridSize>=pxHei )
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
	}
}