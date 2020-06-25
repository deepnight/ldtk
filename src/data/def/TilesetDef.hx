package data.def;

class TilesetDef implements ISerializable {
	public var uid : Int;
	public var base64(default,set) : Null<String>;
	public var path : Null<String>;
	public var customName : Null<String>;
	public var pxWid = 0;
	public var pxHei = 0;
	public var tileGridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;
	public var savedSelections : Array< Array<Int> > = [];

	var texture(get,never) : Null<h3d.mat.Texture>;
	var _textureCache : Null<h3d.mat.Texture>;

	var pixels(get,never) : Null<hxd.Pixels>;
	var _pixelsCache : Null<hxd.Pixels>;

	var cWid(get,never) : Int; inline function get_cWid() return isEmpty() ? 0 : M.ceil( pxWid / tileGridSize );
	var cHei(get,never) : Int; inline function get_cHei() return isEmpty() ? 0 : M.ceil( pxHei / tileGridSize );


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
		if( path==null || isEmpty() )
			return null;

		return dn.FilePath.fromFile(path).fileWithExt;
	}

	function set_base64(str:String) {
		disposeCache();
		return base64 = str;
	}

	public function disposeCache() {
		if( _textureCache!=null )
			_textureCache.dispose();
		_textureCache = null;

		if( _pixelsCache!=null )
			_pixelsCache.dispose();
		_pixelsCache = null;
	}

	function get_texture() {
		if( _textureCache==null && pixels!=null )
			_textureCache = h3d.mat.Texture.fromPixels(pixels);
		return _textureCache;
	}

	function get_pixels() {
		if( _pixelsCache==null && base64!=null ) {
			var bytes = haxe.crypto.Base64.decode( base64 );
			_pixelsCache = dn.heaps.ImageDecoder.getPixels(bytes);
		}
		return _pixelsCache;
	}

	public inline function isEmpty() return pixels==null;


	public function clone() {
		return fromJson( Const.DATA_VERSION, toJson() );
	}

	public function toJson() {
		return {
			uid: uid,
			base64: base64,
			path: path,
			customName: customName,
			pxWid: pxWid,
			pxHei: pxHei,
			tileGridSize: tileGridSize,
			tileGridSpacing: tileGridSpacing,
		}
	}


	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var td = new TilesetDef( JsonTools.readInt(json.uid) );
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Const.DEFAULT_GRID_SIZE);
		td.tileGridSpacing = JsonTools.readInt(json.tileGridSpacing, 0);
		td.pxWid = JsonTools.readInt( json.pxWid );
		td.pxHei = JsonTools.readInt( json.pxHei );
		td.base64 = json.base64;
		td.path = json.path;
		td.customName = json.customName;
		return td;
	}

	public function importImage(filePath:String, bytes:haxe.io.Bytes) : Bool {
		path = dn.FilePath.fromFile(filePath).useSlashes().full;
		base64 = haxe.crypto.Base64.encode(bytes);

		if( pixels==null ) {
			switch dn.Identify.getType(bytes) {
				case Unknown:
				case Png, Gif:
					N.error("Couldn't read this image: maybe the data is corrupted or the format special?");

				case Jpeg:
					N.error("Sorry, JPEG is not yet supported, please use PNG instead.");

				case Bmp:
					N.error("Sorry, BMP is not supported, please use PNG instead.");
			}
			return false;
		}

		pxWid = pixels.width;
		pxHei = pixels.height;

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

	public inline function getAtlasTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

public inline function getTile(tileId:Int) {
		return getAtlasTile().sub( getTileSourceX(tileId), getTileSourceY(tileId), tileGridSize, tileGridSize );
	}

	public function createAtlasHtmlImage() : js.html.Image {
		var img = new js.html.Image();
		if( !isEmpty() )
			img.src = 'data:image/png;base64,$base64';
		return img;
	}

	public function drawAtlasToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( isEmpty() )
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


	public function dispose() {
		disposeCache();
		base64 = null;
	}


	public function saveSelection(tileIds:Array<Int>) {
		// Remove existing overlapping saved selections
		for(tid in tileIds) {
			var saved = getSavedSelectionFor(tid);
			if( saved!=null )
				savedSelections.remove(saved);
		}

		savedSelections.push( tileIds );
	}

	public inline function hasSavedSelectionFor(tid:Int) : Bool {
		return getSavedSelectionFor(tid)!=null;
	}

	public function getSavedSelectionFor(tid:Int) : Null< Array<Int> > {
		for(sel in savedSelections)
			for(stid in sel)
				if( stid==tid )
					return sel;
		return null;
	}
}