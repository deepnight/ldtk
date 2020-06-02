package tool;

class IntGridBrush extends Tool {
	static var SELECTED_VALUES : Map<LayerDef, Int> = new Map();

	public function new() {
		super();
	}

	function selectValue(v:Int) {
		SELECTED_VALUES.set(
			curLayer.def,
			M.iclamp(v, 0, curLayer.def.intGridValues.length-1)
		);
	}
	function getSelectedValue() {
		return SELECTED_VALUES.exists(curLayer.def)
			? SELECTED_VALUES.get(curLayer.def)
			: 0;
	}

	override function updateToolBar() {
		super.updateToolBar();

		selectValue( getSelectedValue() );

		var idx = 0;
		for(c in curLayer.def.intGridValues) {
			var e = new J("<li/>");
			jToolBar.append(e);
			e.addClass("color");
			if( idx==getSelectedValue() )
				e.addClass("active");

			e.css("background-color", C.intToHex(c));
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