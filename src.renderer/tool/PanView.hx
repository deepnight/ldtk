package tool;

class PanView extends Tool<Int> {
	var panning = false;

	public function new() {
		super();
	}

	override function isRunning():Bool {
		return panning;
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		curMode = null;

		if( buttonId==2 || buttonId==0 && App.ME.isKeyDown(K.SPACE) ) {
			clickingOutsideBounds = false;
			panning = true;
		}
	}

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);

		if( panning )
			panning = false;
	}

	override function useAt(m:MouseCoords, isOnStop:Bool):Bool {
		super.useAt(m, isOnStop);

		editor.levelRender.focusLevelX -= m.levelX-lastMouse.levelX;
		editor.levelRender.focusLevelY -= m.levelY-lastMouse.levelY;
		editor.levelRender.cancelAutoScrolling();

		return false;
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);
		if( isRunning() )
			editor.cursor.set(Pan);
	}
}