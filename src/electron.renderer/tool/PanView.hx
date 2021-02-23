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

		if( App.ME.isKeyDown(K.SPACE) || panning )  {
			editor.cursor2.set(Pan);
			ev.cancel = true;
		}
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

	override function updateCursor(ev:hxd.Event, m:Coords) {
		super.updateCursor(ev,m);
		if( isRunning() )
			editor.cursor2.set(Pan);
	}
}