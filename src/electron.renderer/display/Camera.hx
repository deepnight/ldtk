package display;

class Camera extends dn.Process {
	static var MIN_WORLD_ZOOM = 0.03;
	static var DEFAULT_MIN_LEVEL_ZOOM = MIN_WORLD_ZOOM;
	static var MAX_ZOOM = 32;
	static var MAX_FOCUS_PADDING_X = 450;
	static var MAX_FOCUS_PADDING_Y = 400;
	static var ANIM_KEEP_DURATION_S = 1.8;


	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var settings(get,never) : Settings; inline function get_settings() return App.ME.settings;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;

	/** Centered world X coord **/
	public var worldX(default,set) : Float;
	/** Centered world Y coord **/
	public var worldY(default,set) : Float;

	/** Centered level X coord **/
	public var levelX(get,set) : Float;
	/** Centered level Y coord **/
	public var levelY(get,set) : Float;

	public var adjustedZoom(get,never) : Float;

	@:allow(display.EntityRender)
	var rawZoom : Float;

	var _cachedPixelRatio = -1.;
	public var pixelRatio(get,never) : Float;
		inline function get_pixelRatio() {
			return _cachedPixelRatio<0 ? _cachedPixelRatio = js.Browser.window.devicePixelRatio : _cachedPixelRatio;
		}

	var _cachedCanvasWidth = -1.;
	var _cachedCanvasHeight = -1.;

	var canvasWidth(get,never) : Float;
		inline function get_canvasWidth() return _cachedCanvasWidth<=0 ? _cachedCanvasWidth = App.ME.jCanvas.outerWidth() : _cachedCanvasWidth;

	var canvasHeight(get,never) : Float;
		inline function get_canvasHeight() return _cachedCanvasHeight<=0 ? _cachedCanvasHeight = App.ME.jCanvas.outerHeight() : _cachedCanvasHeight;

	public var width(get,never) : Float;
		inline function get_width() return canvasWidth * pixelRatio;

	public var height(get,never) : Float;
		inline function get_height() return canvasHeight * pixelRatio;

	public var iWidth(get,never) : Int;
		inline function get_iWidth() return M.ceil(width);

	public var iHeight(get,never) : Int;
		inline function get_iHeight() return M.ceil(height);


	public var left(get,never) : Float;
		inline function get_left() return worldX - 0.5*width/adjustedZoom;

	public var right(get,never) : Float;
		inline function get_right() return worldX + 0.5*width/adjustedZoom;

	public var top(get,never) : Float;
		inline function get_top() return worldY - 0.5*height/adjustedZoom;

	public var bottom(get,never) : Float;
		inline function get_bottom() return worldY + 0.5*height/adjustedZoom;


	var targetWorldX: Null<Float>;
	var targetWorldY: Null<Float>;
	var targetZoom: Null<Float>;

	@:allow(tool.PanView)
	var kdx = 0.;

	@:allow(tool.PanView)
	var kdy = 0.;

	public function new() {
		super(Editor.ME);

		worldX = worldY = 0;
		setZoom(3);
		editor.ge.addGlobalListener(onGlobalEvent);
	}

	public inline function invalidateCache() {
		_cachedCanvasWidth = _cachedCanvasHeight = -1;
		_cachedPixelRatio = -1;
	}


	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}


	public function onWorldModeChange(worldMode:Bool, usedMouseWheel:Bool) {
		if( !usedMouseWheel )
			if( worldMode ) {
				targetZoom = snapZoomValue( M.fmax(0.3, getFitZoom()*0.8) );
				cd.setS("keepAutoZoom",ANIM_KEEP_DURATION_S);
				if( curWorld.levels.length<=1 )
					targetZoom*=0.5;
			}
			else
				fit();
	}

	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case WorldMode(active):

			case LevelSelected(level):

			case ViewportChanged(zoomChanged):

			case ProjectSelected:
				fit(true);

			case _:
		}
	}


	public function setLevelPos(x,y) {
		levelX = x;
		levelY = y;
	}

	public function setWorldPos(x,y) {
		worldX = x;
		worldY = y;
	}

	function getFitZoom() : Float {
		if( editor.worldMode) {
			var b = curWorld.getWorldBounds();
			var padX = (b.right-b.left) * 0.1 + 300*pixelRatio;
			var padY = (b.bottom-b.top) * 0.1;
			return M.fmin(
				width / ( b.right-b.left + padX ),
				height / ( b.bottom-b.top + padY )
			);
		}
		else {
			var pad = 80 * pixelRatio;
			return M.fmin(
				width / ( editor.curLevel.pxWid + pad ),
				height / ( editor.curLevel.pxHei + pad )
			);
		}
	}

	public function fit(immediate=false) {
		cancelAutoScrolling();
		cancelAutoZoom();
		cancelKeyboardPanning();

		// Scroll
		if( editor.worldMode ) {
			var b = curWorld.getWorldBounds();
			targetWorldX = 0.5 * (b.left + b.right);
			targetWorldY = 0.5 * (b.top + b.bottom);
		}
		else {
			targetWorldX = editor.curLevel.worldX + editor.curLevel.pxWid*0.5;
			targetWorldY = editor.curLevel.worldY + editor.curLevel.pxHei*0.5;
		}
		cd.setS("keepAutoScroll",ANIM_KEEP_DURATION_S);

		// Zoom
		targetZoom = snapZoomValue( getFitZoom() );
		cd.setS("keepAutoZoom",ANIM_KEEP_DURATION_S);

		if( immediate ) {
			worldX = targetWorldX;
			worldY = targetWorldY;
			setZoom(targetZoom);
			cancelAutoScrolling();
			cancelAutoZoom();
		}
	}

	inline function set_worldX(v) {
		if( worldX!=v )
			editor.ge.emitAtTheEndOfFrame( ViewportChanged(false) );
		worldX = v;
		return worldX;
	}

	inline function set_worldY(v) {
		if( worldY!=v )
			editor.ge.emitAtTheEndOfFrame( ViewportChanged(false) );
		worldY = v;
		return worldY;
	}


	inline function set_levelX(v:Float) {
		if( editor.curLevelId!=null && !editor.worldMode && !isAnimated() )
			v = M.fclamp( v, -MAX_FOCUS_PADDING_X/adjustedZoom, editor.curLevel.pxWid + MAX_FOCUS_PADDING_X/adjustedZoom );

		return worldX = v + editor.curLevel.worldX;
	}

	inline function get_levelX() {
		return worldX - editor.curLevel.worldX;
	}


	inline function set_levelY(v:Float) {
		if( editor.curLevelId!=null && !editor.worldMode && !isAnimated() )
			v = M.fclamp( v, -MAX_FOCUS_PADDING_Y/adjustedZoom, editor.curLevel.pxHei+MAX_FOCUS_PADDING_Y/adjustedZoom );

		return worldY = v + editor.curLevel.worldY;
	}

	inline function get_levelY() {
		return worldY - editor.curLevel.worldY;
	}

	public inline function cancelAutoScrolling() {
		targetWorldX = targetWorldX = null;
		cd.unset("keepAutoScroll");
	}

	public inline function cancelAutoZoom() {
		targetZoom = null;
		cd.unset("keepAutoZoom");
	}

	public function cancelKeyboardPanning() {
		kdx = kdy = 0;
	}

	public inline function isAnimated() return targetWorldX!=null || targetZoom!=null;

	public inline function cancelAllAutoMovements() {
		cancelAutoScrolling();
		cancelAutoZoom();
	}

	public function scrollToLevel(l:data.Level) {
		targetWorldX = l.worldCenterX;
		targetWorldY = l.worldCenterY;
		cd.setS("keepAutoScroll",ANIM_KEEP_DURATION_S);
	}

	public function scrollTo(wx,wy) {
		targetWorldX = wx;
		targetWorldY = wy;
		cd.setS("keepAutoScroll",ANIM_KEEP_DURATION_S);
	}

	public function getMinZoom(?l:data.Level) {
		final mul = 2.3;
		if( l!=null )
			return M.fmin( width/(l.pxWid*mul), height/(l.pxHei*mul) );
		else if( editor.worldMode )
			return MIN_WORLD_ZOOM;
		else if( editor!=null && editor.curLevel!=null && !isAnimated() )
			return M.fmin( width/(editor.curLevel.pxWid*mul), height/(editor.curLevel.pxHei*mul) );
		else
			return DEFAULT_MIN_LEVEL_ZOOM;
	}

	public function setZoom(v) {
		cancelAutoZoom();
		rawZoom = M.fclamp(v, getMinZoom(), MAX_ZOOM);
		editor.ge.emitAtTheEndOfFrame( ViewportChanged(true) );
	}

	inline function snapZoomValue(z:Float) {
		return z;
		// return z<=pixelRatio ? z : M.round(z*2)/2;
	}

	inline function get_adjustedZoom() {
		return targetZoom==null ? snapZoomValue(rawZoom) : rawZoom;
	}

	public function deltaZoomTo(zoomFocusX:Float, zoomFocusY:Float, delta:Float) {
		var old = Coords.fromLevelCoords(zoomFocusX, zoomFocusY);

		rawZoom += delta;
		rawZoom = M.fclamp(rawZoom, getMinZoom(), MAX_ZOOM);

		editor.ge.emit( ViewportChanged(true) );

		var newCoord = Coords.fromLevelCoords(zoomFocusX, zoomFocusY);
		worldX += newCoord.worldXf - old.worldXf;
		worldY += newCoord.worldYf - old.worldYf;
	}


	public inline function isOnScreen(wx:Float, wy:Float) {
		return wx>=left && wx<=right && wy>=top && wy<=bottom;
	}

	public inline function isOnScreenLevel(l:data.Level, padding=0.) {
		return isOnScreenRect(l.worldX, l.worldY, l.pxWid, l.pxHei, padding);
	}

	public inline function isOnScreenWorldRect(r:WorldRect, padding=0.) {
		return !( r.right<left || r.left>right || r.bottom<top || r.top>bottom );
	}

	public inline function isOnScreenRect(wx:Float, wy:Float, wid:Float, hei:Float, padding=0.) {
		return dn.Lib.rectangleTouches(
			wx,wy, wid,hei,
			left-padding, top-padding, width/adjustedZoom+padding*2, height/adjustedZoom+padding*2
		);
	}


	public inline function getParallaxOffsetX(li:data.inst.LayerInstance) : Float {
		if( li==null )
			return 0;
		else
			return levelX*li.def.parallaxFactorX
				+ ( li.def.parallaxScaling ? 0 : -li.pxWid*0.5*li.def.parallaxFactorX );
	}

	public inline function getParallaxOffsetY(li:data.inst.LayerInstance) : Float {
		if( li==null )
			return 0;
		else
			return levelY*li.def.parallaxFactorY
				+ ( li.def.parallaxScaling ? 0 : -li.pxHei*0.5*li.def.parallaxFactorY );
	}


	override function postUpdate() {
		super.postUpdate();

		// Keyboard panning
		levelX += kdx*tmod;
		levelY += kdy*tmod;
		kdx *= Math.pow(0.83,tmod);
		kdy *= Math.pow(0.83,tmod);
		if( M.fabs(kdx)<=0.1 ) kdx = 0;
		if( M.fabs(kdy)<=0.1 ) kdy = 0;

		// Animated zoom
		if( targetZoom!=null ) {
			deltaZoomTo( levelX, levelY, ( targetZoom - rawZoom ) * M.fmin(1, M.fmax(0.1, 0.22*adjustedZoom)*tmod) );
			if( M.fabs(targetZoom-rawZoom) <= 0.04*rawZoom || !cd.has("keepAutoZoom") )
				cancelAutoZoom();
		}

		// Animated scrolling
		if( targetWorldX!=null ) {
			worldX += ( targetWorldX - worldX ) * M.fmin(1, 0.15*tmod);
			worldY += ( targetWorldY - worldY ) * M.fmin(1, 0.15*tmod);
			if( M.dist(targetWorldX, targetWorldY, worldX, worldY)<=6 || !cd.has("keepAutoScroll") )
				cancelAutoScrolling();
		}

		if( isAnimated() )
			App.ME.requestCpu();
	}

	public inline function getLevelWidthRatio(l:data.Level) {
		return ( l.pxWid * adjustedZoom ) / width;
	}

	public inline function getLevelHeightRatio(l:data.Level) {
		return ( l.pxHei * adjustedZoom ) / height;
	}
}
