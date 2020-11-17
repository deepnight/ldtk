package display;

class Camera extends dn.Process {
	static var MIN_LEVEL_ZOOM = 0.4;
	static var MIN_WORLD_ZOOM = 0.03;
	static var MAX_ZOOM = 32;
	static var MAX_FOCUS_PADDING_X = 450;
	static var MAX_FOCUS_PADDING_Y = 400;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	public var worldX(default,set) : Float;
	public var worldY(default,set) : Float;

	public var levelX(get,set) : Float;
	public var levelY(get,set) : Float;

	public var adjustedZoom(get,never) : Float;
	var rawZoom : Float;

	public var pixelRatio(get,never) : Float;
		inline function get_pixelRatio() {
			return js.Browser.window.devicePixelRatio;
		}

	public var width(get,never) : Float;
		inline function get_width() return App.ME.jCanvas.outerWidth() * pixelRatio;

	public var height(get,never) : Float;
		inline function get_height() return App.ME.jCanvas.outerHeight() * pixelRatio;

	public var iWidth(get,never) : Int;
		inline function get_iWidth() return M.ceil(width);

	public var iHeight(get,never) : Int;
		inline function get_iHeight() return M.ceil(height);


	var targetWorldX: Null<Float>;
	var targetWorldY: Null<Float>;
	var targetZoom: Null<Float>;

	public function new() {
		super(Editor.ME);
		worldX = worldY = 0;
		setZoom(3);
		editor.ge.addGlobalListener(onGlobalEvent);
	}


	override function onDispose() {
		super.onDispose();
		editor.ge.removeListener(onGlobalEvent);
	}


	function onGlobalEvent(e:GlobalEvent) {
		switch e {
			case WorldMode(active):
				if( active ) {
					// Zoom out
					cancelAutoScrolling();
					targetZoom = M.fmin( 0.5, getFitZoom(editor.curLevel) * 0.5 );
				}

			case ViewportChanged:

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

	function getWorldBounds() {
		var left = Const.INFINITE;
		var right = -Const.INFINITE;
		var top = Const.INFINITE;
		var bottom = -Const.INFINITE;

		for(l in editor.project.levels) {
			left = M.imin(left, l.worldX);
			right = M.imax(right, l.worldX+l.pxWid);
			top = M.imin(top, l.worldY);
			bottom = M.imax(bottom, l.worldY+l.pxHei);
		}

		return {
			left: left,
			right: right,
			top: top,
			bottom: bottom,
		}
	}

	function getFitZoom(l:data.Level) : Float {
		if( editor.worldMode) {
			var b = getWorldBounds();
			var padX = (b.right-b.left) * 0.1;
			var padY = (b.bottom-b.top) * 0.1;
			return M.fmin(
				width / ( b.right-b.left + padX ),
				height / ( b.bottom-b.top + padY )
			);
		}
		else {
			var pad = 80 * pixelRatio;
			return M.fmin(
				width / ( l.pxWid + pad ),
				height / ( l.pxHei + pad )
			);
		}
	}

	public function fit(immediate=false) {
		cancelAutoScrolling();
		cancelAutoZoom();

		if( editor.worldMode ) {
			var b = getWorldBounds();
			targetWorldX = 0.5 * (b.left + b.right);
			targetWorldY = 0.5 * (b.top + b.bottom);
		}
		else {
			targetWorldX = editor.curLevel.worldX + editor.curLevel.pxWid*0.5;
			targetWorldY = editor.curLevel.worldY + editor.curLevel.pxHei*0.5;
		}

		targetZoom = getFitZoom(editor.curLevel);

		if( immediate ) {
			worldX = targetWorldX;
			worldY = targetWorldY;
			setZoom(targetZoom);
			cancelAutoScrolling();
			cancelAutoZoom();
		}
	}

	inline function set_worldX(v) {
		worldX = v;
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return worldX;
	}

	inline function set_worldY(v) {
		worldY = v;
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return worldY;
	}


	inline function set_levelX(v:Float) {
		if( editor.curLevelId!=null && !editor.worldMode )
			v = M.fclamp( v, -MAX_FOCUS_PADDING_X/adjustedZoom, editor.curLevel.pxWid + MAX_FOCUS_PADDING_X/adjustedZoom );

		return worldX = v + editor.curLevel.worldX;
	}

	inline function get_levelX() {
		return worldX - editor.curLevel.worldX;
	}


	inline function set_levelY(v:Float) {
		if( editor.curLevelId!=null && !editor.worldMode )
			v = M.fclamp( v, -MAX_FOCUS_PADDING_Y/adjustedZoom, editor.curLevel.pxHei+MAX_FOCUS_PADDING_Y/adjustedZoom );

		return worldY = v + editor.curLevel.worldY;
	}

	inline function get_levelY() {
		return worldY - editor.curLevel.worldY;
	}

	public inline function autoScrollToLevel(l:data.Level, zoomIn=true) {
		if( zoomIn )
			targetZoom = getFitZoom(l);
		targetWorldX = l.worldX + l.pxWid*0.5;
		targetWorldY = l.worldY + l.pxHei*0.5;
	}

	public inline function cancelAutoScrolling() {
		targetWorldX = targetWorldX = null;
	}

	public inline function cancelAutoZoom() {
		targetZoom = null;
	}

	inline function getMinZoom() {
		return editor.worldMode ? MIN_WORLD_ZOOM : MIN_LEVEL_ZOOM;
	}

	public function setZoom(v) {
		cancelAutoZoom();
		rawZoom = M.fclamp(v, getMinZoom(), MAX_ZOOM);
		editor.ge.emitAtTheEndOfFrame(ViewportChanged);
	}

	inline function get_adjustedZoom() {
		// Reduces tile flickering (issue #71)
		return
			rawZoom; // TODO fix flickering again?
			// ( rawZoom<=pixelRatio ? rawZoom : M.round(rawZoom*2)/2 )
			// * ( 1 - worldZoom*0.5 ) ;
	}

	public function deltaZoomTo(zoomFocusX:Float, zoomFocusY:Float, delta:Float) {
		var c = Coords.fromLevelCoords(zoomFocusX, zoomFocusY);

		rawZoom += delta * rawZoom;
		rawZoom = M.fclamp(rawZoom, getMinZoom(), MAX_ZOOM);

		editor.ge.emit(ViewportChanged);
	}


	override function postUpdate() {
		super.postUpdate();

		// Animated zoom
		if( targetZoom!=null ) {
			deltaZoomTo( levelX, levelY, ( targetZoom - rawZoom ) * M.fmin(1, 0.08 * tmod / rawZoom) );
			if( M.fabs(targetZoom-rawZoom) <= 0.01*rawZoom )
				cancelAutoZoom();
		}

		// Animated scrolling
		if( targetWorldX!=null ) {
			worldX += ( targetWorldX - worldX ) * M.fmin(1, 0.16*tmod);
			worldY += ( targetWorldY - worldY ) * M.fmin(1, 0.16*tmod);
			if( M.dist(targetWorldX, targetWorldY, worldX, worldY)<=4 )
				cancelAutoScrolling();
		}
	}

}
