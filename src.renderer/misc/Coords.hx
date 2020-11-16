package misc;

class Coords {
	static var pixelRatio(get,never): Float;
		static inline function get_pixelRatio() return Editor.ME.camera.pixelRatio;

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
				return M.round( ( canvasX/Const.SCALE - Editor.ME.levelRender.root.x ) / Editor.ME.camera.adjustedZoom );
		}

	public var levelY(get,never) : Int;
		inline function get_levelY() {
			if( Editor.ME==null || Editor.ME.destroyed )
				return -1;
			else
				return M.round( ( canvasY/Const.SCALE - Editor.ME.levelRender.root.y ) / Editor.ME.camera.adjustedZoom );
		}

	// World
	public var worldX(get,never) : Int;
	inline function get_worldX() {
		if( Editor.ME==null || Editor.ME.destroyed )
			return -1;
		else
			return levelX + Editor.ME.curLevel.worldX;
	}

	public var worldY(get,never) : Int;
	inline function get_worldY() {
		if( Editor.ME==null || Editor.ME.destroyed )
			return -1;
		else
			return levelY + Editor.ME.curLevel.worldY;
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


	/** Construct from Page coords **/
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

	/** Create from Level coords **/
	public static function fromLevelCoords(lx:Float, ly:Float) {
		var render = Editor.ME.levelRender;
		var camera = Editor.ME.camera;

		var canvasX = ( lx * camera.adjustedZoom + render.root.x ) * Const.SCALE;
		var pageX = canvasX / pixelRatio + App.ME.jCanvas.offset().left;
		var canvasY = ( ly * camera.adjustedZoom + render.root.y ) * Const.SCALE;
		var pageY = canvasY / pixelRatio + App.ME.jCanvas.offset().top;

		return new Coords(pageX, pageY);
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
		return new Coords(pageX, pageY);
	}


	@:keep public function toString() {
		return 'Coords: Page=$pageX,$pageY, Canvas=$canvasX,$canvasY, Level=$levelX,$levelY, Scale=${Const.SCALE}';
	}

	public inline function makeRect(to:Coords) : Rect {
		return Rect.fromCoords(this, to);
	}

	public function getLayerCx(li:data.inst.LayerInstance) {
		return Std.int( ( layerX + getRelativeLayerInst().pxTotalOffsetX - li.pxTotalOffsetX ) / li.def.gridSize );
	}

	public function getLayerCy(li:data.inst.LayerInstance) {
		return Std.int( ( layerY + getRelativeLayerInst().pxTotalOffsetY - li.pxTotalOffsetY ) / li.def.gridSize );
	}

	public inline function getPageDist(with:Coords) {
		return M.dist(pageX, pageY, with.pageX, with.pageY);
	}
}

