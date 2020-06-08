package data;

class EntityInstance {
	static var _renderCache : Map<Int, h3d.mat.Texture> = new Map();

	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return Client.ME.project.getEntityDef(defId); // TODO

	public var x : Int;
	public var y : Int;

	public var left(get,never) : Int; inline function get_left() return Std.int( x - def.width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + def.width-1;

	public var top(get,never) : Int; inline function get_top() return Std.int( y - def.height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + def.height-1;

	public var fieldValues : Array<data.FieldValue> = [];


	public function new(def:EntityDef) {
		defId = def.uid;
		for(fd in def.fieldDefs)
			fieldValues.push( new data.FieldValue(fd) );
	}

	@:keep public function toString() {
		return 'Instance<${def.name}>@$x,$y';
	}

	public function getCx(ld:LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public static function createRender(def:EntityDef, ?parent:h2d.Object) {
		if( !_renderCache.exists(def.uid) ) {
			var g = new h2d.Graphics();
			g.beginFill(def.color);
			g.lineStyle(1, 0x0, 0.25);
			g.drawRect(0, 0, def.width, def.height);

			g.lineStyle(1, 0x0, 0.5);
			var pivotSize = 3;
			g.drawRect(
				Std.int((def.width-pivotSize)*def.pivotX),
				Std.int((def.height-pivotSize)*def.pivotY),
				pivotSize, pivotSize
			);

			var tex = new h3d.mat.Texture(def.width, def.height, [Target]);
			g.drawTo(tex);
			_renderCache.set(def.uid, tex);
		}

		var bmp = new h2d.Bitmap(parent);
		bmp.tile = h2d.Tile.fromTexture( _renderCache.get(def.uid) );
		bmp.tile.setCenterRatio(def.pivotX, def.pivotY);

		return bmp;
	}

	public function isOver(levelX:Int, levelY:Int) {
		return levelX >= left && levelX <= right && levelY >= top && levelY <= bottom;
	}

	public static function invalidateRenderCache() {
		for(tex in _renderCache)
			tex.dispose();
		_renderCache = new Map();
	}
}