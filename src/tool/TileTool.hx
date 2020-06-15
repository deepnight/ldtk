package tool;

class TileTool extends Tool<TileSelection> {
	public function new() {
		super();
	}

	// override function selectValue(v:Int) {
	// 	super.selectValue(v);
	// }

	// override function canEdit():Bool {
	// 	return super.canEdit() && getSelectedValue()>=0;
	// }

	override function getDefaultValue():TileSelection{
		return Single(0,0);
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null, PanView:
			case Add:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					drawSelectedTileAt(cx, cy);
				});
				client.ge.emit(LayerInstanceChanged);

			case Remove:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					removeSelectedTileAt(cx, cy);
				});
				client.ge.emit(LayerInstanceChanged);

			case Move:
		}
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null, PanView:
				case Add:
					drawSelectedTileAt(cx,cy);

				case Remove:
					removeSelectedTileAt(cx,cy);

				case Move:
			}
		}

		client.ge.emit(LayerInstanceChanged);
	}


	function drawSelectedTileAt(cx:Int, cy:Int) {
		switch getSelectedValue() {
			case Single(tcx, tcy):
				client.curLayerInstance.setTile(cx,cy, 0); // TODO

			case Multiple(tiles):
				for(t in tiles)
					client.curLayerInstance.setTile(cx,cy, 0); // TODO
		}
	}

	function removeSelectedTileAt(cx:Int, cy:Int) {
		switch getSelectedValue() {
			case Single(tcx, tcy):
				client.curLayerInstance.removeTile(cx,cy);

			case Multiple(tiles):
				// TODO
		}
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			client.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) )
			client.cursor.set( GridCell(curLayerInstance, m.cx, m.cy) );
		else
			client.cursor.set(None);
	}


	override function updatePalette() {
		super.updatePalette();
	}
}