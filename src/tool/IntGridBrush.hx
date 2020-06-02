package tool;

class IntGridBrush extends Tool {
	public function new() {
		super();
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		var last = lastMouse==null ? m : lastMouse;
		dn.Bresenham.iterateThinLine(last.cx, last.cy, m.cx, m.cy, function(cx,cy) {
			curLayer.setIntGrid(cx, cy, 0);
		});
		client.levelRender.invalidate();
	}
}