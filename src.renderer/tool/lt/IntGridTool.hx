package tool.lt;

class IntGridTool extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function selectValue(v:Int) {
		v = M.iclamp(v, 0, curLayerInstance.def.countIntGridValues()-1);
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		return 0;
	}

	inline function getSelectedColor() {
		return curLayerInstance.def.getIntGridValueDef( getSelectedValue() ).color;
	}

	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);
		editor.selectionTool.clear();
	}


	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, getSelectedColor()) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) )
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy, getSelectedColor()) );
		else
			editor.cursor.set(None);
	}

	override function onMouseMove(m:MouseCoords) {
		super.onMouseMove(m);
	}

	override function useAtInterpolatedGrid(cx:Int, cy:Int):Bool {
		super.useAtInterpolatedGrid(cx, cy);

		var old = curLayerInstance.getIntGrid(cx,cy);
		switch curMode {
			case null:
			case Add:
				curLayerInstance.setIntGrid(cx, cy, getSelectedValue());

			case Remove:
				curLayerInstance.removeIntGrid(cx, cy);
		}

		if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
			editor.curLevelHistory.markChange(cx,cy);
			return true;
		}
		else
			return false;
	}


	override function useOnRectangle(m:MouseCoords, left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(m, left, right, top, bottom);

		var anyChange = false;
		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			var old = curLayerInstance.getIntGrid(cx,cy);
			switch curMode {
				case null:
				case Add:
					curLayerInstance.setIntGrid(cx,cy, getSelectedValue());

				case Remove:
					curLayerInstance.removeIntGrid(cx,cy);
			}

			if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
				editor.curLevelHistory.markChange(cx,cy);
				anyChange = true;
			}
		}

		return anyChange;
	}


	override function useFloodfillAt(m:MouseCoords):Bool {
		var initial = curLayerInstance.getIntGrid(m.cx,m.cy);
		if( initial==getSelectedValue() && curMode==Add )
			return false;

		return _floodFillImpl(
			m,
			(cx,cy)->curLayerInstance.getIntGrid(cx,cy)!=initial,
			(cx,cy, v)->{
				switch curMode {
					case null:
					case Add:
						curLayerInstance.setIntGrid(cx,cy, v);

					case Remove:
						curLayerInstance.removeIntGrid(cx,cy);
				}
			}
		);
	}

	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.IntGridPalette(this);
	}
}