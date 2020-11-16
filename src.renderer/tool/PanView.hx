package tool;

class PanView extends Tool<Int> {
	var panning = false;

	public function new() {
		super();
	}

	override function isRunning():Bool {
		return panning;
	}

	override function startUsing(m:Coords, buttonId:Int) {
		super.startUsing(m, buttonId);

		curMode = null;

		if( buttonId==2 || buttonId==0 && App.ME.isKeyDown(K.SPACE) ) {
			clickingOutsideBounds = false;
			panning = true;
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

	override function updateCursor(m:Coords) {
		super.updateCursor(m);
		if( isRunning() )
			editor.cursor.set(Pan);
	}
}