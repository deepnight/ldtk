package tool;

class PanView extends Tool<Int> {
	var panning = false;
	var zooming = false;
	var initialZoomPt : Null<Coords>;

	public function new() {
		super();
	}

	override function isRunning():Bool {
		return panning || zooming;
	}

	override function startUsing(ev:hxd.Event, m:Coords, ?extraParam:String) {
		super.startUsing(ev,m,extraParam);

		curMode = null;
		App.ME.jBody.addClass("panning");

		if( ev.button==2 || ev.button==0 && App.ME.isKeyDown(K.SPACE) ) {
			clickingOutsideBounds = false;
			panning = true;
			ev.cancel = true;
		}

		if( ev.button==1 && App.ME.isKeyDown(K.SPACE) ) {
			clickingOutsideBounds = false;
			zooming = true;
			initialZoomPt = m.clone();
			ev.cancel = true;
		}
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);
	}

	override function stopUsing(m:Coords) {
		super.stopUsing(m);

		App.ME.jBody.removeClass("panning");
		panning = false;
		zooming = false;
	}

	override function useAt(m:Coords, isOnStop:Bool):Bool {
		super.useAt(m, isOnStop);

		if( panning ) {
			editor.camera.levelX -= m.levelX-lastMouse.levelX;
			editor.camera.levelY -= m.levelY-lastMouse.levelY;
			editor.camera.cancelAutoScrolling();
		}
		else if( zooming ) {
			var dist = m.levelY-lastMouse.levelY;
			editor.deltaZoom(-dist*0.04*editor.camera.adjustedZoom, Coords.fromLevelCoords(initialZoomPt.levelX, initialZoomPt.levelY) );
		}

		return false;
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev,m);

		if( isRunning() ) {
			editor.cursor.set(Panning);
			ev.cancel = true;
		}
		else if( App.ME.isKeyDown(K.SPACE) ) {
			editor.cursor.set(Pan);
			ev.cancel = true;
		}
	}


	override function preUpdate() {
		super.preUpdate();

		// if( App.ME.focused && !App.ME.hasInputFocus() ) {
		// 	var spd = 3 / editor.camera.adjustedZoom;
		// 	if( App.ME.isKeyDown(K.LEFT) ) {
		// 		editor.camera.cancelAllAutoMovements();
		// 		editor.camera.kdx -= spd*tmod;
		// 	}
		// 	if( App.ME.isKeyDown(K.RIGHT) ) {
		// 		editor.camera.cancelAllAutoMovements();
		// 		editor.camera.kdx += spd*tmod;
		// 	}
		// 	if( App.ME.isKeyDown(K.UP) ) {
		// 		editor.camera.cancelAllAutoMovements();
		// 		editor.camera.kdy -= spd*tmod;
		// 	}
		// 	if( App.ME.isKeyDown(K.DOWN) ) {
		// 		editor.camera.cancelAllAutoMovements();
		// 		editor.camera.kdy += spd*tmod;
		// 	}
		// }
	}
}