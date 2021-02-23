package tool.lt;

class IntGridTool extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function onBeforeToolActivation() {
		super.onBeforeToolActivation();

		if( !editor.curLayerDef.hasIntGridValue(getSelectedValue()) )
			selectValue(1);
	}

	override function selectValue(v:Int) {
		v = M.iclamp(v, 1, curLayerInstance.def.countIntGridValues());
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		return 1;
	}

	inline function getSelectedColor() {
		return curLayerInstance.def.getIntGridValueDef( getSelectedValue() ).color;
	}

	override function startUsing(ev:hxd.Event, m:Coords) {
		super.startUsing(ev,m);
		editor.selectionTool.clear();
	}


	override function updateCursor(ev:hxd.Event, m:Coords) {
		super.updateCursor(ev,m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, getSelectedColor()) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) ) {
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy, getSelectedColor()) );
			ev.cancel = true;
		}
		// else
		// 	editor.cursor.set(None);
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


	override function useOnRectangle(m:Coords, left:Int, right:Int, top:Int, bottom:Int) {
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


	override function useFloodfillAt(m:Coords):Bool {
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