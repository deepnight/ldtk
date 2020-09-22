package tool;

class PickPoint extends Tool<{ x:Int, y:Int }> {
	public function new() {
		super();
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
		editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy) );
		App.ME.debug("I'm at "+m);
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);
	}

	override function stopUsing(m:MouseCoords) {
		super.stopUsing(m);
		if( button==0 ) {
			editor.levelRender.bleepRectCase(m.cx,m.cy, 1,1, 0xffcc00);
			onPick(m);
		}
	}

	public dynamic function onPick(m:MouseCoords) {}
}