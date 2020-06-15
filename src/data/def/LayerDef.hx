package data.def;

class LayerDef implements ISerializable {
	public var uid(default,null) : Int;
	public var type : LayerType;
	public var name : String;
	public var gridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var displayOpacity : Float = 1.0;

	// IntGrid
	var intGridValues : Array<IntGridValueDef> = [];

	// Tileset
	var texture : Null<h3d.mat.Texture>;
	var pixels : Null<hxd.Pixels>;
	var tilePath : Null<String>;
	public var tileGridSize : Int = Const.DEFAULT_GRID_SIZE;
	public var tileGridSpacing : Int = 0;

	public function new(uid:Int, t:LayerType) {
		this.uid = uid;
		name = "New layer "+uid;
		type = t;
		addIntGridValue(0x0);
	}

	@:keep public function toString() {
		return '$name($type, ${gridSize}px)';
	}

	public function clone() {
		return fromJson( Const.DATA_VERSION, toJson() );
	}


	public function hasTilesetTexture() return texture!=null;

	public function readTileset(bytes:haxe.io.Bytes) {
		disposeTileset();

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


	public inline function getTileX(cx:Int) {
		return cx*(tileGridSize+tileGridSpacing);
	}

	public inline function getTileY(cy:Int) {
		return cy*(tileGridSize+tileGridSpacing);
	}

	public function getTile() : Null<h2d.Tile> {
		return texture==null ? null : h2d.Tile.fromTexture(texture);
	}

	public function getSubTile(cx:Int, cy:Int) {
		if( texture==null )
			return null;

		var t = getTile();
		return t.sub(getTileX(cx), getTileY(cy), tileGridSize, tileGridSize);
	}

	function pixelsToImageElement(source:hxd.Pixels) : Null<js.html.Image> {
		if( texture==null )
			return null;

		var img = new js.html.Image(source.width, source.height);
		var b64 = haxe.crypto.Base64.encode( source.toPNG() );
		img.src = 'data:image/png;base64,$b64';
		return img;
	}

	public function drawTileToCanvas(canvas:js.jquery.JQuery) {
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

		var subPixels = pixels.sub(getTileX(cx), getTileY(cy), tileGridSize, tileGridSize);
		var canvas = Std.downcast(canvas.get(0), js.html.CanvasElement);
		var ctx = canvas.getContext2d();
		var img = pixelsToImageElement(subPixels);
		img.onload = function() {
			ctx.drawImage(img, toX, toY);
		}
	}


	public function disposeTileset() {
		if( texture!=null )
			texture.dispose();

		if( pixels!=null )
			pixels.dispose();

		texture = null;
		pixels = null;
	}

	public static function fromJson(dataVersion:Int, json:Dynamic) {
		var o = new LayerDef( JsonTools.readInt(json.uid), JsonTools.readEnum(LayerType, json.type, false));
		o.name = JsonTools.readString(json.name);
		o.gridSize = JsonTools.readInt(json.gridSize, Const.DEFAULT_GRID_SIZE);
		o.displayOpacity = JsonTools.readFloat(json.displayOpacity, 1);

		o.intGridValues = [];
		for( v in JsonTools.readArray(json.intGridValues) )
			o.intGridValues.push(v);

		return o;
	}

	public function toJson() {
		return {
			uid: uid,
			type: JsonTools.writeEnum(type, false),
			name: name,
			gridSize: gridSize,
			displaydisplayOpacity: JsonTools.clampFloatPrecision(displayOpacity),
			intGridValues: intGridValues,
		}
	}

	public function addIntGridValue(col:UInt, ?name:String) {
		if( !isIntGridValueNameValid(name) )
			throw "Invalid intGrid value name "+name;
		intGridValues.push({
			color: col,
			name: name,
		});
	}

	public function getIntGridValueDef(idx:Int) : Null<IntGridValueDef> {
		return intGridValues[idx];
	}

	public inline function getAllIntGridValues() return intGridValues;
	public inline function countIntGridValues() return intGridValues.length;


	public function isIntGridValueUsedInProject(p:ProjectData, idx:Int) {
		for(level in p.levels) {
			var li = level.getLayerInstance(this);
			if( li!=null ) {
				for(cx in 0...li.cWid)
				for(cy in 0...li.cHei)
					if( li.getIntGrid(cx,cy)==idx )
						return true;
			}
		}
		return false;
	}

	public function isIntGridValueNameValid(name:Null<String>) {
		if( name==null )
			return true;

		for(v in intGridValues)
			if( v.name==name )
				return false;

		return true;
	}


	public function loadTileset(filePath:String) {
		tilePath = filePath;
	}

}