package display;

class Camera extends dn.Process {
	static var MIN_ZOOM = 0.2;
	static var MAX_ZOOM = 32;
	static var MAX_FOCUS_PADDING_X = 450;
	static var MAX_FOCUS_PADDING_Y = 400;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var settings(get,never) : AppSettings; inline function get_settings() return App.ME.settings;

	public var levelX(default,set) : Float;
	public var levelY(default,set) : Float;

	public var pixelRatio(get,never) : Float;
		inline function get_pixelRatio() {
			return js.Browser.window.devicePixelRatio;
		}

	var targetLevelX: Null<Float>;
	var targetLevelY: Null<Float>;
	var targetZoom: Null<Float>;
	public var adjustedZoom(get,never) : Float;
	var rawZoom : Float;

	public var worldX(get,never) : Float;
		inline function get_worldX() return levelX - editor.curLevel.worldX;

	public var worldY(get,never) : Float;
		inline function get_worldY() return levelY - editor.curLevel.worldY;

	public function new() {
		super(Editor.ME);
		levelX = levelY = 0;
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
		// TODO
		// levelX = x;
		// levelY = y;
	}

	function getFitZoom(l:data.Level) : Float {
		var pad = 80 * pixelRatio;
		return M.fmin(
			editor.canvasWid() / ( l.pxWid + pad ),
			editor.canvasHei() / ( l.pxHei + pad )
		);
	}

	public function fit(immediate=false) {
		cancelAutoScrolling();
		cancelAutoZoom();

		targetLevelX = editor.curLevel.pxWid*0.5;
		targetLevelY = editor.curLevel.pxHei*0.5;

		targetZoom = getFitZoom(editor.curLevel);

		if( immediate ) {
			levelX = targetLevelX;
			levelY = targetLevelY;
			setZoom(targetZoom);
			cancelAutoScrolling();
			cancelAutoZoom();
		}
	}

	inline function set_levelX(v) {
		levelX = editor.curLevelId==null || editor.worldMode
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING_X/adjustedZoom, editor.curLevel.pxWid+MAX_FOCUS_PADDING_X/adjustedZoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return levelX;
	}

	inline function set_levelY(v) {
		levelY = editor.curLevelId==null || editor.worldMode
			? v
			: M.fclamp( v, -MAX_FOCUS_PADDING_Y/adjustedZoom, editor.curLevel.pxHei+MAX_FOCUS_PADDING_Y/adjustedZoom );
		editor.ge.emitAtTheEndOfFrame( ViewportChanged );
		return levelY;
	}

	public inline function autoScrollToLevel(l:data.Level) {
		targetZoom = getFitZoom(l);
		targetLevelX = l.pxWid*0.5;
		targetLevelY = l.pxHei*0.5;
	}

	public inline function cancelAutoScrolling() {
		targetLevelX = targetLevelY = null;
	}

	public inline function cancelAutoZoom() {
		targetZoom = null;
	}

	public function setZoom(v) {
		cancelAutoZoom();
		rawZoom = M.fclamp(v, MIN_ZOOM, MAX_ZOOM);
		editor.ge.emitAtTheEndOfFrame(ViewportChanged);
	}

	inline function get_adjustedZoom() {
		// Reduces tile flickering (issue #71)
		return
			rawZoom; // TODO fix flickering again
			// ( rawZoom<=pixelRatio ? rawZoom : M.round(rawZoom*2)/2 )
			// * ( 1 - worldZoom*0.5 ) ;
	}

	public function deltaZoomTo(zoomFocusX:Float, zoomFocusY:Float, delta:Float) {
		var c = Coords.fromLevelCoords(zoomFocusX, zoomFocusY);

		rawZoom += delta * rawZoom;
		rawZoom = M.fclamp(rawZoom, MIN_ZOOM, MAX_ZOOM);

		editor.ge.emit(ViewportChanged);
	}


	override function postUpdate() {
		super.postUpdate();

		// Animated zoom
		if( targetZoom!=null ) {
			deltaZoomTo( levelX, levelY, ( targetZoom - rawZoom ) * M.fmin(1, 0.07 * tmod) );
			N.debug(tmod);
			if( M.fabs(targetZoom-rawZoom) <= 0.04/rawZoom )
				cancelAutoZoom();
		}

		// Animated scrolling
		if( targetLevelX!=null ) {
			levelX += ( targetLevelX - levelX ) * M.fmin(1, 0.16*tmod);
			levelY += ( targetLevelY - levelY ) * M.fmin(1, 0.16*tmod);
			if( M.dist(targetLevelX, targetLevelY, levelX, levelY)<=4 )
				cancelAutoScrolling();
		}

	}

}
