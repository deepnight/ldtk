package tool;

class IntGridBrush extends Tool {
	var curValue = 0;

	public function new() {
		super();
	}

	override function updateToolBar() {
		super.updateToolBar();

		curValue = M.iclamp(curValue, 0, curLayer.def.intGridValues.length-1);

		var idx = 0;
		for(c in curLayer.def.intGridValues) {
			var e = new J("<li/>");
			jToolBar.append(e);
			e.addClass("color");
			if( idx==curValue )
				e.addClass("active");

			e.css("background-color", C.intToHex(c));
			var curIdx = idx;
			e.click( function(_) {
				curValue = curIdx;
				updateToolBar();
			});
			idx++;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		var last = lastMouse==null ? m : lastMouse;
		dn.Bresenham.iterateThinLine(last.cx, last.cy, m.cx, m.cy, function(cx,cy) {
			curLayer.setIntGrid(cx, cy, curValue);
		});
		client.levelRender.invalidate();
	}
}