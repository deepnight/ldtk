package tool.lt;

class IntGridTool extends tool.LayerTool<Int> {
	public function new() {
		super();
	}

	override function onBeforeToolActivation() {
		super.onBeforeToolActivation();

		if( !editor.curLayerDef.hasIntGridValue( getSelectedValue() ) )
			selectValue( getDefaultValue() );
	}

	override function selectValue(v:Int) {
		if( !curLayerInstance.def.hasIntGridValue(v) )
			v = getDefaultValue();
		super.selectValue(v);
	}

	override function getDefaultValue():Int {
		if( curLayerInstance==null || curLayerInstance.def.countIntGridValues()==0 )
			return -1;
		else
			return curLayerInstance.def.getAllIntGridValues()[0].value;
	}

	inline function getSelectedColor() {
		return getSelectedValue()>0 ? curLayerInstance.def.getIntGridValueDef( getSelectedValue() ).color : 0x0;
	}

	override function startUsing(ev:hxd.Event, m:Coords, ?extraParam:String) {
		super.startUsing(ev,m,extraParam);
		editor.selectionTool.clear();
	}

	override function customCursor(ev:hxd.Event, m:Coords) {
		super.customCursor(ev,m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromCoords(origin, m);
			editor.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei, getSelectedColor()) );
			ev.cancel = true;
		}
		else if( getSelectedValue()>0 && curLayerInstance.isValid(m.cx,m.cy) ) {
			editor.cursor.set( GridCell(curLayerInstance, m.cx, m.cy, getSelectedColor()) );
			ev.cancel = true;
		}
	}

	override function useAtInterpolatedGrid(cx:Int, cy:Int):Bool {
		super.useAtInterpolatedGrid(cx, cy);

		var old = curLayerInstance.getIntGrid(cx,cy);
		switch curMode {
			case null:
			case Add:
				curLayerInstance.setIntGrid(cx, cy, getSelectedValue(), true);

			case Remove:
				curLayerInstance.removeIntGrid(cx, cy, true);
		}

		if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
			editor.curLevelTimeline.markGridChange(curLayerInstance, cx, cy);
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
					curLayerInstance.setIntGrid(cx,cy, getSelectedValue(), true);

				case Remove:
					curLayerInstance.removeIntGrid(cx,cy, true);
			}

			if( old!=curLayerInstance.getIntGrid(cx,cy) ) {
				editor.curLevelTimeline.markGridChange(curLayerInstance, cx, cy);
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
						curLayerInstance.setIntGrid(cx,cy, v, true);

					case Remove:
						curLayerInstance.removeIntGrid(cx,cy, true);
				}
			}
		);
	}

	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.IntGridPalette(this);
	}
}