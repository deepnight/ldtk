package data.def;

class TilesetDef implements ISerializable {

	var texture : Null<h3d.mat.Texture>;
	var pixels : Null<hxd.Pixels>;
	public var tileGridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;

	public function new() {
	}


	public inline function hasTexture() return texture!=null;


	public function clone() {
		return fromJson( toJson() );
	}

	public function toJson() {
		var b64 = pixels==null ? null : haxe.crypto.Base64.encode( pixels.bytes );
		return {
			b64: b64,
			width: pixels==null ? 0 : pixels.width,
			height: pixels==null ? 0 : pixels.height,
			tileGridSize: tileGridSize,
			tileGridSpacing: tileGridSpacing,
		}
	}


	public static function fromJson(json:Dynamic) {
		var td = new TilesetDef();
		td.tileGridSize = JsonTools.readInt(json.tileGridSize, Const.DEFAULT_GRID_SIZE);
		td.tileGridSpacing = JsonTools.readInt(json.tileGridSpacing, 0);
		if( json.b64!=null ) {
			var bytes = haxe.crypto.Base64.decode(json.b64);
			var w = JsonTools.readInt(json.width);
			var h = JsonTools.readInt(json.height);
			td.pixels = new hxd.Pixels(w, h, bytes, BGRA);
			td.texture = h3d.mat.Texture.fromPixels(td.pixels);
		}
		return td;
	}

	public function importImage(bytes:haxe.io.Bytes) : Bool {
		disposeTexture();

		pixels = dn.heaps.ImageDecoder.getPixels(bytes);
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

		texture = h3d.mat.Texture.fromPixels(pixels);
		return true;
	}


	public inline function getSubTileX(cx:Int) {
		return cx*(tileGridSize+tileGridSpacing);
	}

	public inline function getSubTileY(cy:Int) {
		return cy*(tileGridSize+tileGridSpacing);
	}

	public inline function getFullTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

	public inline function getSubTile(cx:Int, cy:Int) {
		return getFullTile().sub(getSubTileX(cx), getSubTileY(cy), tileGridSize, tileGridSize);
	}

	function pixelsToImageElement(source:hxd.Pixels) : Null<js.html.Image> {
		if( texture==null )
			return null;

		var img = new js.html.Image(source.width, source.height);
		var b64 = haxe.crypto.Base64.encode( source.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		return img;
	}

	public function drawFullTileToCanvas(canvas:js.jquery.JQuery) {
		if( !canvas.is("canvas") )
			throw "Not a canvas";

		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		var img = pixelsToImageElement(pixels);
		img.onload = function() {
			ctx.drawImage(img, 0, 0);
		}
	}

	public function drawSubTileToCanvas(canvas:js.jquery.JQuery, cx:Int, cy:Int, toX:Int, toY:Int) {
		if( pixels==null )
			return;

		if( !canvas.is("canvas") )
			throw "Not a canvas";

		if( cx>=M.ceil(pixels.width/tileGridSize) || cy>=M.ceil(pixels.height/tileGridSize) )
			return;

		var subPixels = pixels.sub(getSubTileX(cx), getSubTileY(cy), tileGridSize, tileGridSize);
		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		var img = pixelsToImageElement(subPixels);
		img.onload = function() {
			ctx.drawImage(img, toX, toY);
		}
	}


	public function disposeTexture() {
		if( texture!=null )
			texture.dispose();

		if( pixels!=null )
			pixels.dispose();

		texture = null;
		pixels = null;
	}

}