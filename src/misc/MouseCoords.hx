package misc;

class MouseCoords {
	public var gx : Float;
	public var gy : Float;

	public var levelX(get,never) : Int;
	inline function get_levelX() return Std.int( ( gx/Const.SCALE - levelRender.root.x ) / levelRender.zoom );

	public var levelY(get,never) : Int;
	inline function get_levelY() return Std.int( ( gy/Const.SCALE - levelRender.root.y ) / levelRender.zoom );

	public var cx(get,never) : Int;
	inline function get_cx() return Std.int( levelX / client.curLayerInstance.def.gridSize );

	public var cy(get,never) : Int;
	inline function get_cy() return Std.int( levelY / client.curLayerInstance.def.gridSize );

	public var htmlX(get,never) : Int;
	inline function get_htmlX() return Std.int( gx / js.Browser.window.devicePixelRatio + new J("#webgl").offset().left );

	public var htmlY(get,never) : Int;
	inline function get_htmlY() return Std.int( gy / js.Browser.window.devicePixelRatio + new J("#webgl").offset().top );


	var client(get,never) : Client; inline function get_client() return Client.ME;
	var levelRender(get,never) : display.LevelRender; inline function get_levelRender() return Client.ME.levelRender;

	public function new(gx:Float,gy:Float) {
		this.gx = gx;
		this.gy = gy;
	}

	public inline function getRect(to:MouseCoords) : Rect {
		return Rect.fromMouseCoords(this, to);
	}

	public function getLayerCx(ld:led.def.LayerDef) return Std.int( levelX / ld.gridSize );
	public function getLayerCy(ld:led.def.LayerDef) return Std.int( levelY / ld.gridSize );


	public function clampToLayer(li:led.inst.LayerInstance) {
		gx = M.fmax(gx, levelRender.root.x);
		gx = M.fmin(gx, levelRender.root.x + client.curLevel.pxWid * levelRender.zoom - 1);

		gy = M.fmax(gy, levelRender.root.y);
		gy = M.fmin(gy, levelRender.root.y + client.curLevel.pxHei * levelRender.zoom - 1);

	}
}

