package tool.lt;

class DoNothing extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev, m);

		if( editor.curLevel.inBounds(m.levelX, m.levelY) ) {
			editor.cursor.set(Forbidden);
			ev.cancel = true;
		}
	}
}