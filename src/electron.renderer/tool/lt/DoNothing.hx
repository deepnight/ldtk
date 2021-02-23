package tool.lt;

class DoNothing extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev,m);

		if( editor.curLevel.inBounds(m.levelX, m.levelY) ) {
			editor.cursor2.set(Forbidden);
			ev.cancel = true;
		}
	}
}