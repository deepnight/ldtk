package tool;

class LayerTool<T> extends Tool<T> {
	public function new() {
		super();
	}

	override function onMouseMove(ev:hxd.Event, m:Coords) {
		super.onMouseMove(ev, m);

		if( isRunning() )
			ev.cancel = true;
	}
}
