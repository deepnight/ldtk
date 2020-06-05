package tools;

class MouseCoords {
	public var gx : Float;
	public var gy : Float;

	public var clientX(get,never) : Int;
	inline function get_clientX() return Std.int( ( gx/Const.SCALE - levelRender.root.x ) / levelRender.zoom );

	public var clientY(get,never) : Int;
	inline function get_clientY() return Std.int( ( gy/Const.SCALE - levelRender.root.y ) / levelRender.zoom );

	public var cx(get,never) : Int;
	inline function get_cx() return Std.int( clientX / client.curLayerContent.def.gridSize );

	public var cy(get,never) : Int;
	inline function get_cy() return Std.int( clientY / client.curLayerContent.def.gridSize );


	var client(get,never) : Client; inline function get_client() return Client.ME;
	var levelRender(get,never) : render.LevelRender; inline function get_levelRender() return Client.ME.levelRender;

	public function new(gx:Float,gy:Float) {
		this.gx = gx;
		this.gy = gy;
	}

	public inline function getRect(to:MouseCoords) : Rect {
		return Rect.fromMouseCoords(this, to);
	}
}

