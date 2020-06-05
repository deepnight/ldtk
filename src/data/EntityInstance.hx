package data;

class EntityInstance {
	static var _renderCache : Map<Int, h3d.mat.Texture> = new Map();

	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return Client.ME.project.getEntityDef(defId);

	public var x : Int;
	public var y : Int;


	public function new(def:EntityDef) {
		defId = def.uid;
	}

	public static function createRender(def:EntityDef, ?parent:h2d.Object) {
		if( !_renderCache.exists(def.uid) ) {
			var g = new h2d.Graphics();
			g.beginFill(def.color);
			g.drawRect(0, 0, def.width, def.height);

			var tex = new h3d.mat.Texture(def.width, def.height, [Target]);
			g.drawTo(tex);
			_renderCache.set(def.uid, tex);
			N.debug(tex.width+"x"+tex.height);
		}

		var bmp = new h2d.Bitmap(parent);
		bmp.tile = h2d.Tile.fromTexture( _renderCache.get(def.uid) );
		return bmp;
	}

	public static function invalidateRenderCache() {
		for(tex in _renderCache)
			tex.dispose();
		_renderCache = new Map();
	}
}