package tool;

class IntGridTool extends Tool<Int> {
	public function new() {
		super();
	}

	override function selectValue(v:Int) {
		v = M.iclamp(v, 0, curLayerContent.def.countIntGridValues()-1);
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		return 0;
	}

	inline function getIntGridColor() {
		return curLayerContent.def.getIntGridValueDef( getSelectedValue() ).color;
	}


	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			client.cursor.set( GridRect(curLayerContent, r.left, r.top, r.wid, r.hei) );
		}
		else if( curLayerContent.isValid(m.cx,m.cy) )
			client.cursor.set( GridCell(curLayerContent, m.cx, m.cy) );
		else
			client.cursor.set(None);
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
	}

	public function ok() {}
	override function useAt(m:MouseCoords) {
		super.useAt(m);

		dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
			switch curMode {
				case null, PanView:
				case Add:
					curLayerContent.setIntGrid(cx, cy, getSelectedValue());

				case Remove:
					curLayerContent.removeIntGrid(cx, cy);

				case Move:
			}
		});
		client.ge.emit(LayerContentChanged);
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null, PanView:
				case Add:
					curLayerContent.setIntGrid(cx,cy, getSelectedValue());

				case Remove:
					curLayerContent.removeIntGrid(cx,cy);

				case Move:
			}
		}

		client.ge.emit(LayerContentChanged);
	}



	override function updatePalette() {
		super.updatePalette();

		var idx = 0;
		for( intGridVal in curLayerContent.def.getAllIntGridValues() ) {
			var e = new J("<li/>");
			jPalette.append(e);
			e.addClass("color");
			if( idx==getSelectedValue() )
				e.addClass("active");

			if( intGridVal.name==null )
				e.text("#"+idx);
			else
				e.text("#"+idx+" - "+intGridVal.name);

			e.css("color", C.intToHex( C.autoContrast(C.toBlack(intGridVal.color,0.3)) ));
			e.css("background-color", C.intToHex(intGridVal.color));
			var curIdx = idx;
			e.click( function(_) {
				selectValue(curIdx);
				updatePalette();
			});
			idx++;
		}
	}
}