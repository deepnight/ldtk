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
				return M.round( ( canvasX/Const.SCALE - Editor.ME.levelRender.root.x ) / Editor.ME.levelRender.adjustedZoom );
		}

	public var levelY(get,never) : Int;
		inline function get_levelY() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return M.round( ( canvasY/Const.SCALE - Editor.ME.levelRender.root.y ) / Editor.ME.levelRender.adjustedZoom );
		}

	// World
	public var worldX(get,never) : Int;
	inline function get_worldX() {
		if( Editor.ME==null || Editor.ME.destroyed )
			return -1;
		else
			return levelX + ( Editor.ME.curLevel==null ? 0 : Editor.ME.curLevel.worldX );
	}

	public var worldY(get,never) : Int;
	inline function get_worldY() {
		if( Editor.ME==null || Editor.ME.destroyed )
			return -1;
		else
			return levelY + ( Editor.ME.curLevel==null ? 0 : Editor.ME.curLevel.worldY );
	}

	// Layer
	public var layerX(get,never) : Int;
		inline function get_layerX() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return levelX - ( getRelativeLayerInst()!=null ? getRelativeLayerInst().pxTotalOffsetX : 0 );
		}

	public var layerY(get,never) : Int;
		inline function get_layerY() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return levelY - ( getRelativeLayerInst()!=null ? getRelativeLayerInst().pxTotalOffsetY : 0 );
		}

	// Level cell
	public var cx(get,never) : Int;
		inline function get_cx() {
			return M.floor( layerX / ( getRelativeLayerInst()!=null ? getRelativeLayerInst().def.gridSize : 16 ) );
		}

	public var cy(get,never) : Int;
		inline function get_cy() {
			return M.floor( layerY / ( getRelativeLayerInst()!=null ? getRelativeLayerInst().def.gridSize : 16 ) );
		}

	var _relativeLayerInst : Null<data.inst.LayerInstance>;

	public function new(?pageX:Float, ?pageY:Float) {
		if( pageX==null ) {
			this.pageX = App.ME.lastKnownMouse.pageX;
			this.pageY = App.ME.lastKnownMouse.pageY;
		}
		else {
			this.pageX = Std.int(pageX);
			this.pageY = Std.int(pageY);
		}
	}


	inline function getRelativeLayerInst() {
		return _relativeLayerInst==null ? Editor.ME.curLayerInstance : _relativeLayerInst;
	}

	public function cloneRelativeToLayer(li:data.inst.LayerInstance) {
		var m = clone();
		m._relativeLayerInst = li;
		return m;
	}

	public function clone() {
		return new MouseCoords(pageX, pageY);
	}


	@:keep public function toString() {
		return 'MouseCoords: Page=$pageX,$pageY, Canvas=$canvasX,$canvasY, Level=$levelX,$levelY, Scale=${Const.SCALE}';
	}

	public inline function getRect(to:MouseCoords) : Rect {
		return Rect.fromMouseCoords(this, to);
	}

	public function getLayerCx(li:data.inst.LayerInstance) {
		return Std.int( ( layerX + getRelativeLayerInst().pxTotalOffsetX - li.pxTotalOffsetX ) / li.def.gridSize );
	}

	public function getLayerCy(li:data.inst.LayerInstance) {
		return Std.int( ( layerY + getRelativeLayerInst().pxTotalOffsetY - li.pxTotalOffsetY ) / li.def.gridSize );
	}
}

