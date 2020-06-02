package tool;

class IntGridBrush extends Tool<Int> {
	public function new() {
		super();
	}

	override function selectValue(v:Int) {
		v = M.iclamp(v, 0, curLayer.def.intGridValues.length-1);
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		return 0;
	}

	override function updateToolBar() {
		super.updateToolBar();

		selectValue( getSelectedValue() );

		var idx = 0;
		for(val in curLayer.def.intGridValues) {
			var e = new J("<li/>");
			jToolBar.append(e);
			e.addClass("color");
			if( idx==getSelectedValue() )
				e.addClass("active");

			e.css("background-color", C.intToHex(val.color));
			var curIdx = idx;
			e.click( function(_) {
				selectValue(curIdx);
				updateToolBar();
			});
			idx++;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
			if( isAdding() )
				curLayer.setIntGrid(cx, cy, getSelectedValue());
			else if( isRemoving() )
				curLayer.removeIntGrid(cx, cy);
		});
		client.levelRender.invalidate();
	}
}