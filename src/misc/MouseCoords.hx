package misc;

class MouseCoords {
	public var gx : Float;
	public var gy : Float;

	public var levelX(get,never) : Int;
	inline function get_levelX() return globalToLevelX(gx);

	public var levelY(get,never) : Int;
	inline function get_levelY() return globalToLevelY(gy);

	public var cx(get,never) : Int;
	inline function get_cx() return M.floor( levelX / editor.curLayerInstance.def.gridSize );

	public var cy(get,never) : Int;
	inline function get_cy() return M.floor( levelY / editor.curLayerInstance.def.gridSize );

	public var htmlX(get,never) : Int;
	inline function get_htmlX() return M.round( gx / js.Browser.window.devicePixelRatio + new J("#webgl").offset().left );

	public var htmlY(get,never) : Int;
	inline function get_htmlY() return M.round( gy / js.Browser.window.devicePixelRatio + new J("#webgl").offset().top );


	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var levelRender(get,never) : display.LevelRender; inline function get_levelRender() return Editor.ME.levelRender;

	public function new(gx:Float,gy:Float) {
		this.gx = gx;
		this.gy = gy;
	}

	public inline function getRect(to:MouseCoords) : Rect {
		return Rect.fromMouseCoords(this, to);
	}

	public static function globalToLevelX(gx:Float) {
		return M.round( ( gx/Const.SCALE - Editor.ME.levelRender.root.x ) / Editor.ME.levelRender.zoom );
	}

	public static function globalToLevelY(gy:Float) {
		return M.round( ( gy/Const.SCALE - Editor.ME.levelRender.root.y ) / Editor.ME.levelRender.zoom );
	}

	public function getLayerCx(ld:led.def.LayerDef) return Std.int( levelX / ld.gridSize );
	public function getLayerCy(ld:led.def.LayerDef) return Std.int( levelY / ld.gridSize );


	public function clampToLayer(li:led.inst.LayerInstance) {
		gx = M.fmax(gx, levelRender.root.x);
		gx = M.fmin(gx, levelRender.root.x + editor.curLevel.pxWid * levelRender.zoom - 1);

		gy = M.fmax(gy, levelRender.root.y);
		gy = M.fmin(gy, levelRender.root.y + editor.curLevel.pxHei * levelRender.zoom - 1);

	}
}

