package tool;

class PanView extends Tool<Int> {
	var panning = false;

	public function new() {
		super();
	}

	override function isRunning():Bool {
		return panning;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);

		curMode = null;

		if( ev.button==2 || ev.button==0 && App.ME.isKeyDown(K.SPACE) ) {
			clickingOutsideBounds = false;
			panning = true;
			ev.cancel = true;
		}
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);
	}

	override function stopUsing(m:Coords) {
		super.stopUsing(m);

		if( panning )
			panning = false;
	}

	override function useAt(m:Coords, isOnStop:Bool):Bool {
		super.useAt(m, isOnStop);

		editor.camera.levelX -= m.levelX-lastMouse.levelX;
		editor.camera.levelY -= m.levelY-lastMouse.levelY;
		editor.camera.cancelAutoScrolling();

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


	override function postUpdate() {
		super.postUpdate();

		if( App.ME.focused && !App.ME.hasInputFocus() ) {
			var spd = 5 / editor.camera.adjustedZoom;
			if( App.ME.isKeyDown(K.LEFT) ) {
				editor.camera.cancelAllAutoMovements();
				editor.camera.kdx -= spd*tmod;
			}
			if( App.ME.isKeyDown(K.RIGHT) ) {
				editor.camera.cancelAllAutoMovements();
				editor.camera.kdx += spd*tmod;
			}
			if( App.ME.isKeyDown(K.UP) ) {
				editor.camera.cancelAllAutoMovements();
				editor.camera.kdy -= spd*tmod;
			}
			if( App.ME.isKeyDown(K.DOWN) ) {
				editor.camera.cancelAllAutoMovements();
				editor.camera.kdy += spd*tmod;
			}
		}
	}
}