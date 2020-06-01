package tool;

class IntGridBrush extends Tool {
	public function new() {
		super();
	}

	override function use() {
		super.use();
		var m = getMouse();
		curLayer.setIntGrid(m.cx, m.cy, 1);
		client.levelRender.invalidate();
	}
}