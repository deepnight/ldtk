package tool.lt;

class DoNothing extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);
		editor.cursor.set(Forbidden);
	}
}