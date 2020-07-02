package led.def;

import led.LedTypes;

class TilesetDef {
	public var uid : Int;
	public var fileBase64(default,set) : Null<String>;
	public var path : Null<String>;
	public var customName : Null<String>;
	public var pxWid = 0;
	public var pxHei = 0;
	public var tileGridSize : Int = Project.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;
	public var savedSelections : Array<TilesetSelection> = [];

	#if heaps
	var texture(get,never) : Null<h3d.mat.Texture>;
	var _textureCache : Null<h3d.mat.Texture>;

	var pixels(get,never) : Null<hxd.Pixels>;
	var _pixelsCache : Null<hxd.Pixels>;
	#end

	public var cWid(get,never) : Int; inline function get_cWid() return !hasAtlas() ? 0 : dn.M.ceil( pxWid / tileGridSize );
	public var cHei(get,never) : Int; inline function get_cHei() return !hasAtlas() ? 0 : dn.M.ceil( pxHei / tileGridSize );


	public function new(uid:Int) {
		this.uid = uid;
	}

	public function getName() {
		return customName!=null ? customName : getDefaultName();
	}

	public function getDefaultName() {
		return path!=null ? dn.FilePath.extractFileWithExt(path) : "Empty tileset "+uid;
	}

	public function getFileName() : Null<String> {
		if( path==null || !hasAtlas() )
			return null;

		return dn.FilePath.extractFileWithExt(path);
	}

	function set_fileBase64(str:String) {
		disposeAtlasCache();
		return fileBase64 = str;
	}

	public function disposeAtlasCache() {
		#if heaps
		if( _textureCache!=null )
			_textureCache.dispose();
		_textureCache = null;

		if( _pixelsCache!=null )
			_pixelsCache.dispose();
		_pixelsCache = null;
		#end
	}

	public function clearAtlas() {
		fileBase64 = null;
		path = null;
		savedSelections = [];
	}

	public inline function hasAtlas() return fileBase64!=null;


	public function clone() {
		return fromJson( Project.DATA_VERSION, toJson() );
	}

	public function toJson() {
		return {
			uid: uid,
			fileBase64: fileBase64,
			path: path,
			customName: customName,
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
		td.fileBase64 = json.fileBase64;
		td.path = json.path;
		td.customName = json.customName;

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

		path = dn.FilePath.fromFile(filePath).useSlashes().full;
		fileBase64 = haxe.crypto.Base64.encode(fileContent);
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
		fileBase64 = null;
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

	public inline function getAtlasTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

	public inline function getTile(tileId:Int) {
		return getAtlasTile().sub( getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize );
	}

	function get_texture() {
		if( _textureCache==null && pixels!=null )
			_textureCache = h3d.mat.Texture.fromPixels(pixels);
		return _textureCache;
	}

	function get_pixels() {
		if( _pixelsCache==null && fileBase64!=null ) {
			var bytes = haxe.crypto.Base64.decode( fileBase64 );
			_pixelsCache = dn.ImageDecoder.decodePixels(bytes);
		}
		return _pixelsCache;
	}

	#end



	/*** JS API *********************************/
	#if js

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( hasAtlas() )
			img.src = 'data:image/png;base64,$fileBase64';
		return img;
	}

	public function drawAtlasToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( !hasAtlas() )
			return;

		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var img = new js.html.Image(pixels.width, pixels.height);
		img.src = 'data:image/png;base64,$fileBase64';
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
}