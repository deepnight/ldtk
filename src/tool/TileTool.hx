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

			case Move:
		}
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

	override function updatePalette() {
		super.updatePalette();
	}
}