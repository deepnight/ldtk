package tool;

class EmptyTool extends Tool<Int> {
	public function new() {
		super();
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
		editor.cursor.set(Forbidden);
	}
}