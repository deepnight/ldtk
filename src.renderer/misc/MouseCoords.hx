package misc;

class MouseCoords {
	var pixelRatio(get,never): Float; inline function get_pixelRatio() return js.Browser.window.devicePixelRatio;

	// HTML Page
	public var pageX : Int;
	public var pageY : Int;

	// Canvas
	public var canvasX(get,never) : Int;
		inline function get_canvasX() return M.round( ( pageX - App.ME.jCanvas.offset().left ) * pixelRatio );

	public var canvasY(get,never) : Int;
		inline function get_canvasY() return M.round( ( pageY - App.ME.jCanvas.offset().top ) * pixelRatio );

	// Level
	public var levelX(get,never) : Int;
		inline function get_levelX() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return M.round( ( canvasX/Const.SCALE - Editor.ME.levelRender.root.x ) / Editor.ME.levelRender.zoom ) - Editor.ME.curLayerInstance.pxOffsetX;
		}

	public var levelY(get,never) : Int;
		inline function get_levelY() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return M.round( ( canvasY/Const.SCALE - Editor.ME.levelRender.root.y ) / Editor.ME.levelRender.zoom ) - Editor.ME.curLayerInstance.pxOffsetY;
		}

	// Level cell
	public var cx(get,never) : Int;
		inline function get_cx() {
			return M.floor( levelX / Editor.ME.curLayerInstance.def.gridSize );
		}

	public var cy(get,never) : Int;
		inline function get_cy() {
			return M.floor( levelY / Editor.ME.curLayerInstance.def.gridSize );
		}



	public function new(?pageX, ?pageY) {
		if( pageX==null ) {
			this.pageX = App.ME.lastKnownMouse.pageX;
			this.pageY = App.ME.lastKnownMouse.pageY;
		}
		else {
			this.pageX = pageX;
			this.pageY = pageY;
		}
	}


	@:keep public function toString() {
		return 'Page:$pageX,$pageY, Canvas:$canvasX,$canvasY, Level:$levelX,$levelY, Scale:${Const.SCALE}';
	}

	public inline function getRect(to:MouseCoords) : Rect {
		return Rect.fromMouseCoords(this, to);
	}

	public function getLayerCx(ld:led.def.LayerDef) return Std.int( levelX / ld.gridSize );
	public function getLayerCy(ld:led.def.LayerDef) return Std.int( levelY / ld.gridSize );
}

